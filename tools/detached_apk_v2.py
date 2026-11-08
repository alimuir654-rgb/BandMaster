#!/usr/bin/env python3
"""Prepare/complete APK-v2 detached signing. Public certificates only; no key operations.

The private-key holder signs the exact decoded signed_data_base64 using
SHA256withRSA (RSASSA-PKCS1-v1_5, APK algorithm 0x0103). Assembly requires the
returned signature, then official Android apksigner/zipalign and payload checks.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import zipfile

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

APP = 'com.bandmaster.ownerplaytest.s40'
CERT_SHA = '83c797fe8db043b49ebdc705a3ca7a0326db19d0b9bf613c8cb1db1ea0c3cbf2'
V16_SHA = 'a6be215d95b9d47c5a8b661ea5b503a623a0ceccd584c29d6ffe002c9d0f9f90'
V17_SHA = 'dc4eb92cc022eb2e93c867264fd9ae2f00db20ebb5f0690472fb6f67270003aa'
V17_SIZE = 188672220
EXPECTED_VERSION = 17
EXPECTED_INTEGRATED_SOURCE = '65fd1b7db90ce255bea04084d030e5b0055b92b2'
EXPECTED_GAME_SOURCE = 'a0f5bc331ff2e0884bf69c2417c5555eadec26fc'
V2_ID = 0x7109871A
RSA_SHA256 = 0x0103
MAGIC = b'APK Sig Block 42'
CHUNK = 1024 * 1024


def require(ok, message):
    if not ok:
        raise ValueError('STOP: ' + message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def b64(data):
    return base64.b64encode(data).decode('ascii')


def unb64(text):
    require(isinstance(text, str), 'Base64 must be text')
    return base64.b64decode(text, validate=True)


def u32(value):
    return struct.pack('<I', value)


def lp(value):
    return u32(len(value)) + value


def take_lp(data, offset=0):
    require(offset + 4 <= len(data), 'truncated length prefix')
    length = struct.unpack_from('<I', data, offset)[0]
    end = offset + 4 + length
    require(end <= len(data), 'length prefix exceeds container')
    return bytes(data[offset + 4:end]), end


def sequence(data):
    result, offset = [], 0
    while offset < len(data):
        item, offset = take_lp(data, offset)
        result.append(item)
    require(offset == len(data), 'sequence trailing bytes')
    return result


def zip_sections(data):
    # Strict ZIP32, one disk, no bytes after the declared EOCD comment.
    eocd = None
    for pos in range(len(data) - 22, max(-1, len(data) - 65557), -1):
        if data[pos:pos + 4] == b'PK\x05\x06' and pos + 22 + struct.unpack_from('<H', data, pos + 20)[0] == len(data):
            eocd = pos
            break
    require(eocd is not None, 'valid ZIP EOCD not found')
    disk, cd_disk, disk_count, count, size, cd, _comment = struct.unpack_from('<4H2IH', data, eocd + 4)
    require(disk == cd_disk == 0 and disk_count == count and count < 65535, 'multi-disk/ZIP64 unsupported')
    require(cd != 0xFFFFFFFF and size != 0xFFFFFFFF and cd + size == eocd, 'ZIP central directory boundaries')
    require(data[cd:cd + 4] == b'PK\x01\x02', 'central directory magic')
    return dict(cd=cd, eocd=eocd, cd_size=size, entries=count)


def signing_block(data, sections):
    end = sections['cd']
    if data[end - 16:end] != MAGIC:
        return None
    size = struct.unpack_from('<Q', data, end - 24)[0]
    start = end - size - 8
    require(size >= 24 and start >= 0 and struct.unpack_from('<Q', data, start)[0] == size, 'APK signing block sizes')
    pairs, cursor, seen = [], start + 8, set()
    while cursor < end - 24:
        require(cursor + 8 <= end - 24, 'truncated signing-block pair')
        length = struct.unpack_from('<Q', data, cursor)[0]
        cursor += 8
        require(length >= 4 and cursor + length <= end - 24, 'bad signing-block pair length')
        identity = struct.unpack_from('<I', data, cursor)[0]
        require(identity not in seen, 'duplicate signing-block ID')
        seen.add(identity)
        pairs.append((identity, bytes(data[cursor + 4:cursor + length])))
        cursor += length
    require(cursor == end - 24, 'signing block trailing bytes')
    return dict(start=start, end=end, pairs=pairs)


def chunked_digest(data, sections, block_start):
    eocd = bytearray(data[sections['eocd']:])
    struct.pack_into('<I', eocd, 16, block_start)
    parts = [memoryview(data)[:block_start], memoryview(data)[sections['cd']:sections['eocd']], memoryview(eocd)]
    count = sum((len(part) + CHUNK - 1) // CHUNK for part in parts)
    digest = hashlib.sha256(b'\x5a' + u32(count))
    for part in parts:
        for offset in range(0, len(part), CHUNK):
            chunk = part[offset:offset + CHUNK]
            item = hashlib.sha256(b'\xa5' + u32(len(chunk)))
            item.update(chunk)
            digest.update(item.digest())
    return digest.digest(), count


def signed_data(digest, certificate, attributes=b''):
    # Official SDK V2SchemeSigner emits four LP elements; the fourth is empty.
    return lp(lp(u32(RSA_SHA256) + lp(digest))) + lp(lp(certificate)) + lp(attributes) + lp(b'')


def encode_block(pairs):
    items = b''.join(struct.pack('<Q', 4 + len(value)) + u32(identity) + value for identity, value in pairs)
    size = len(items) + 24
    return struct.pack('<Q', size) + items + struct.pack('<Q', size) + MAGIC


def encode_v2_value(message, certificate, signature):
    signer = lp(message) + lp(lp(u32(RSA_SHA256) + lp(signature))) + lp(spki(certificate))
    return lp(lp(signer))


def parse_records(data):
    result = []
    for record in sequence(data):
        require(len(record) >= 8, 'short algorithm record')
        algorithm = struct.unpack_from('<I', record)[0]
        value, end = take_lp(record, 4)
        require(end == len(record), 'algorithm record trailing bytes')
        result.append((algorithm, value))
    return result


def parse_v2(value):
    signers, end = take_lp(value)
    require(end == len(value), 'v2 trailing bytes')
    records = sequence(signers)
    require(len(records) == 1, 'exactly one original signer required')
    record = records[0]
    data, pos = take_lp(record)
    signatures, pos = take_lp(record, pos)
    public_key, pos = take_lp(record, pos)
    require(pos == len(record), 'signer trailing bytes')
    digests, pos = take_lp(data)
    certificates, pos = take_lp(data, pos)
    attributes, pos = take_lp(data, pos)
    reserved, pos = take_lp(data, pos)
    require(reserved == b'', 'SDK fourth signed-data field must be empty')
    require(pos == len(data), 'signed-data trailing bytes')
    certs = sequence(certificates)
    require(len(certs) == 1, 'one original certificate required')
    return dict(data=data, signatures=parse_records(signatures), public_key=public_key,
                digests=parse_records(digests), certificate=certs[0], attributes=attributes, reserved=reserved)


def public_key(certificate):
    cert = x509.load_der_x509_certificate(certificate)
    key = cert.public_key()
    require(isinstance(key, rsa.RSAPublicKey) and key.key_size >= 2048, 'original RSA certificate required')
    return key


def spki(certificate):
    return public_key(certificate).public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)


def verify_rsa(certificate, data, signature, algorithm=RSA_SHA256):
    require(algorithm in (RSA_SHA256, 0x0101), 'unsupported reference signature algorithm')
    scheme = padding.PKCS1v15() if algorithm == RSA_SHA256 else padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=32)
    public_key(certificate).verify(signature, data, scheme, hashes.SHA256())


def run(command):
    result = subprocess.run([str(x) for x in command], capture_output=True, text=True, timeout=90)
    require(result.returncode == 0, 'official tool failed: ' + ' '.join(str(x) for x in command[:2]) + '\n' + result.stdout + result.stderr)
    return result.stdout + result.stderr


def reference_certificate(v16, sdk):
    verified = run([sdk / 'apksigner', 'verify', '--verbose', '--print-certs', v16])
    require('Verified using v2 scheme (APK Signature Scheme v2): true' in verified and
            'Number of signers: 1' in verified and 'Signer #1 certificate SHA-256 digest: ' + CERT_SHA in verified,
            'V16 official signer/certificate verification')
    data = v16.read_bytes()
    require(sha(data) == V16_SHA, 'V16 exact APK SHA256')
    sections = zip_sections(data)
    block = signing_block(data, sections)
    require(block is not None and V2_ID in dict(block['pairs']), 'V16 v2 block required')
    signer = parse_v2(dict(block['pairs'])[V2_ID])
    require(sha(signer['certificate']) == CERT_SHA and signer['public_key'] == spki(signer['certificate']), 'V16 public certificate/SPKI')
    digest, chunks = chunked_digest(data, sections, block['start'])
    require([a for a, _ in signer['digests']] == [a for a, _ in signer['signatures']], 'V16 digest/signature algorithms')
    for algorithm, value in signer['digests']:
        require(algorithm in (RSA_SHA256, 0x0101) and value == digest, 'V16 known-answer content digest')
    for algorithm, signature in signer['signatures']:
        verify_rsa(signer['certificate'], signer['data'], signature, algorithm)
    require(signer['data'] == lp(b''.join(lp(u32(a) + lp(d)) for a, d in signer['digests'])) +
            lp(lp(signer['certificate'])) + lp(signer['attributes']) + lp(signer['reserved']), 'V16 exact signed-data re-encoding')
    require(encode_block(block['pairs']) == data[block['start']:block['end']], 'V16 signing-block byte-exact roundtrip')
    return signer['certificate'], dict(official_apksigner=True, original_certificate_sha256=CERT_SHA,
        reference_apk_sha256=V16_SHA, content_digest_known_answer=True, original_rsa_signature_verified=True,
        signed_data_reencoding_byte_exact=True, signing_block_roundtrip_byte_exact=True, chunks=chunks)


def metadata(apk, sdk):
    badging = run([sdk / 'aapt', 'dump', 'badging', apk])
    package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']*)'", badging)
    minimum = re.search(r"sdkVersion:'(\d+)'", badging)
    target = re.search(r"targetSdkVersion:'(\d+)'", badging)
    require(package is not None and minimum is not None and target is not None, 'APK manifest fields')
    return dict(application_id=package[1], version_code=int(package[2]), version_name=package[3],
                minimum_sdk=int(minimum[1]), target_sdk=int(target[1]))


def payload_manifest(apk):
    records = []
    with zipfile.ZipFile(apk) as archive:
        require(len(archive.namelist()) == len(set(archive.namelist())), 'duplicate ZIP entry')
        for info in archive.infolist():
            require(not info.filename.startswith('/') and '..' not in Path(info.filename).parts and not info.flag_bits & 1,
                    'unsafe/encrypted ZIP entry')
            digest = hashlib.sha256()
            with archive.open(info) as file:
                while chunk := file.read(CHUNK):
                    digest.update(chunk)
            records.append(dict(path=info.filename, bytes=info.file_size, compressed_bytes=info.compress_size,
                compression=info.compress_type, crc32=info.CRC, local_header_offset=info.header_offset, sha256=digest.hexdigest()))
    return records


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode('ascii')


def unsigned_audit(apk, sdk):
    data = apk.read_bytes()
    require(len(data) == V17_SIZE and sha(data) == V17_SHA, 'unsigned V17 exact SHA256/size')
    sections = zip_sections(data)
    require(signing_block(data, sections) is None, 'V17 must have no pre-existing signing block')
    fields = metadata(apk, sdk)
    require(fields['application_id'] == APP and fields['version_code'] == EXPECTED_VERSION and fields['minimum_sdk'] == 24,
            'V17 application ID/version/minimum SDK')
    run([sdk / 'zipalign', '-c', '-P', '16', '4', apk])
    records = payload_manifest(apk)
    require(len(records) == sections['entries'], 'ZIP manifest entry count')
    with zipfile.ZipFile(apk) as archive:
        abis = sorted({name.split('/')[1] for name in archive.namelist() if name.startswith('lib/') and name.endswith('.so')})
        require(abis == ['arm64-v8a'], 'ARM64 payload required')
        require(not any(name.startswith('assets/tests/') for name in archive.namelist()), 'test harness excluded from APK')
    permission_output = run([sdk / 'aapt', 'dump', 'permissions', apk])
    permissions = re.findall(r"uses-permission: name='([^']+)'", permission_output)
    forbidden = ['INTERNET', 'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE', 'RECORD_AUDIO', 'CAMERA']
    require(not any('android.permission.' + p in permissions for p in forbidden), 'unexpected permission')
    digest, chunks = chunked_digest(data, sections, sections['cd'])
    return data, sections, fields, digest, dict(zip_crc_all_entries=True, zip32_single_disk=True,
        no_preexisting_signing_block=True, alignment_16kb=True, abis=abis, permissions=permissions,
        forbidden_permissions_absent=True, test_harness_excluded=True, payload_entries=len(records),
        payload_manifest_sha256=sha(canonical(records)), content_digest_chunks=chunks, physical_device_tested=False)


def request_id(value):
    return sha(canonical({k: v for k, v in value.items() if k != 'request_id'}))


def prepare(args):
    require(not args.output.exists(), 'request output already exists')
    certificate, reference = reference_certificate(args.v16, args.sdk)
    data, sections, fields, digest, audit = unsigned_audit(args.apk, args.sdk)
    message = signed_data(digest, certificate)
    require(signed_data(digest, certificate) == message, 'signed-data determinism')
    prior = json.loads(args.package_audit.read_text())
    require(prior['sha256'] == V17_SHA and prior['bytes'] == V17_SIZE and prior['application_id'] == APP and
            prior['version_code'] == EXPECTED_VERSION and prior['signed'] is False, 'retained package audit binding')
    verification = json.loads(args.verification.read_text())
    require(verification['compiled_apk_model']['checks'] >= 91 and not verification['compiled_apk_model']['failures'],
            'retained compiled-payload test audit')
    audit['previous_compiled_payload_tests'] = dict(checks=verification['compiled_apk_model']['checks'], failures=0, reused_for_exact_unsigned_apk_sha256=V17_SHA,
        verification_record_sha256=sha(args.verification.read_bytes()), package_audit_record_sha256=sha(args.package_audit.read_bytes()))
    value = dict(schema_version=1, request_type='android-apk-v2-detached-rsa-sha256',
        unsigned_apk=dict(filename=args.apk.name, sha256=sha(data), size=len(data), **fields),
        source_identity=dict(repository='alimuir654-rgb/BandMaster', branch='feature/recorded-song-main-app',
            integrated_source_commit=EXPECTED_INTEGRATED_SOURCE,
            owner_base_commit='19df671f2946a9a3c675bc879aa4c8a854544e57',
            packaged_game_source_commit=verification['tested_sha'], entry_scene='experiments/playable_flightcase/opening.tscn',
            save_directory='BandMasterOwnerPlaytestS40', source_archive_sha256='33d96e02a9601f1c994e211cbd5cbe6aa6f4e1473176aacab42cf3e332ee167d' if EXPECTED_VERSION==17 else None),
        signing=dict(scheme='APK Signature Scheme v2', signature_algorithm_id='0x0103',
            java_signature_algorithm='SHA256withRSA', padding='RSASSA-PKCS1-v1_5', hash_algorithm='SHA-256',
            signed_data_base64=b64(message), signed_data_sha256=sha(message), signed_data_size=len(message),
            public_certificate_der_base64=b64(certificate), certificate_sha256=sha(certificate),
            public_key_spki_der_base64=b64(spki(certificate)), public_key_spki_sha256=sha(spki(certificate)),
            rsa_key_bits=public_key(certificate).key_size, content_digest_algorithm='APK-v2 chunked SHA-256',
            content_digest_hex=digest.hex(), chunk_size_bytes=CHUNK, additional_attributes_base64='',
            sdk_fourth_empty_field_base64='',
            minimum_android_signature_scheme='v2; minSdk24; no v1/v3 block requested'),
        zip_layout=dict(central_directory_offset=sections['cd'], central_directory_size=sections['cd_size'],
            eocd_offset=sections['eocd'], eocd_size=len(data) - sections['eocd']),
        package_audit=audit, original_certificate_audit=reference,
        signer_instructions=[
            'Validate the APK/source/audit identity and certificate fingerprint before signing.',
            'Base64-decode signing.signed_data_base64. Sign those exact bytes using SHA256withRSA / PKCS#1 v1.5 and the retained original private key.',
            'Do not sign the JSON, a length prefix, the APK digest, or the hexadecimal signed-data hash. SHA256withRSA performs its one SHA-256 internally.',
            'Do not export or send the private key. Return only the detached signature and request-binding fields.',
            'The current environment will verify the RSA signature before constructing the APK block, then require official Android apksigner verification and unchanged payload checks.'],
        response_template=dict(schema_version=1, request_id='<copy top-level request_id>',
            signed_data_sha256=sha(message), certificate_sha256=CERT_SHA, signature_base64='<base64 of the 256-byte RSA signature>'),
        status='awaiting_original_private_key_holder_signature; no APK assembled or signed here')
    value['request_id'] = request_id(value)
    require(len(message) < 16384, 'unexpected signed-data size')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(value, indent=2) + '\n')
    require(sha(args.apk.read_bytes()) == V17_SHA, 'unsigned APK changed during prepare')
    print(json.dumps(dict(request_id=value['request_id'], request_bytes=args.output.stat().st_size,
        signed_data_sha256=sha(message), signed_data_bytes=len(message), content_digest=digest.hex(),
        original_certificate_sha256=CERT_SHA, apk_untouched=True)))


def validate_request(value, apk, v16, sdk):
    require(value.get('schema_version') == 1 and value.get('request_type') == 'android-apk-v2-detached-rsa-sha256', 'request schema')
    require(value.get('request_id') == request_id(value), 'request ID/canonical JSON changed')
    require(value['source_identity']['integrated_source_commit'] == EXPECTED_INTEGRATED_SOURCE and
            value['source_identity']['repository'] == 'alimuir654-rgb/BandMaster' and
            value['source_identity']['packaged_game_source_commit'] == EXPECTED_GAME_SOURCE,
            'request source identity changed')
    certificate, _audit = reference_certificate(v16, sdk)
    data, sections, fields, digest, audit = unsigned_audit(apk, sdk)
    signing = value['signing']
    require(value['unsigned_apk'] == dict(filename=apk.name, sha256=sha(data), size=len(data), **fields), 'request APK identity')
    require(signing['signature_algorithm_id'] == '0x0103' and signing['java_signature_algorithm'] == 'SHA256withRSA' and
            signing['padding'] == 'RSASSA-PKCS1-v1_5' and signing['hash_algorithm'] == 'SHA-256', 'request signing algorithm')
    require(unb64(signing['public_certificate_der_base64']) == certificate and signing['certificate_sha256'] == CERT_SHA,
            'request original certificate changed')
    require(unb64(signing['public_key_spki_der_base64']) == spki(certificate) and signing['public_key_spki_sha256'] == sha(spki(certificate)), 'request SPKI changed')
    message = signed_data(digest, certificate)
    require(unb64(signing['signed_data_base64']) == message and signing['signed_data_sha256'] == sha(message) and
            signing['signed_data_size'] == len(message) and signing['content_digest_hex'] == digest.hex(), 'request signed-data/content digest mismatch')
    require(signing['additional_attributes_base64'] == '' and signing['sdk_fourth_empty_field_base64'] == '' and
            signing['chunk_size_bytes'] == CHUNK, 'request digest/attribute parameters')
    require(value['package_audit']['payload_manifest_sha256'] == audit['payload_manifest_sha256'], 'request payload manifest changed')
    require(value['zip_layout'] == dict(central_directory_offset=sections['cd'], central_directory_size=sections['cd_size'],
            eocd_offset=sections['eocd'], eocd_size=len(data) - sections['eocd']), 'request ZIP layout changed')
    return data, sections, certificate, message


def validate_response(value, response, certificate, message):
    require(set(response) == {'schema_version', 'request_id', 'signed_data_sha256', 'certificate_sha256', 'signature_base64'}, 'response exact fields')
    require(response['schema_version'] == 1 and response['request_id'] == value['request_id'] and
            response['signed_data_sha256'] == sha(message) and response['certificate_sha256'] == CERT_SHA,
            'response request/certificate binding')
    signature = unb64(response['signature_base64'])
    require(len(signature) == public_key(certificate).key_size // 8, 'RSA signature byte length')
    verify_rsa(certificate, message, signature)
    return signature


def assemble(args):
    require(not args.output.exists(), 'final output already exists')
    require(not args.output.with_suffix('.audit.json').exists(), 'final audit output already exists')
    request = json.loads(args.request.read_text())
    response = json.loads(args.response.read_text())
    data, sections, certificate, message = validate_request(request, args.apk, args.v16, args.sdk)
    signature = validate_response(request, response, certificate, message)
    block = encode_block([(V2_ID, encode_v2_value(message, certificate, signature))])
    eocd = bytearray(data[sections['eocd']:])
    struct.pack_into('<I', eocd, 16, sections['cd'] + len(block))
    # A held candidate is never promoted unless every following gate passes.
    candidate = args.output.with_name(args.output.name + '.pending-audit')
    require(not candidate.exists(), 'pending-audit artifact already exists')
    with candidate.open('xb') as file:
        file.write(memoryview(data)[:sections['cd']]);file.write(block)
        file.write(memoryview(data)[sections['cd']:sections['eocd']]);file.write(eocd)
    final = candidate.read_bytes();layout = zip_sections(final);parsed = signing_block(final, layout)
    require(parsed is not None and parsed['start'] == sections['cd'], 'assembled signing-block position')
    require(final[:parsed['start']] == data[:sections['cd']] and
            final[layout['cd']:layout['eocd']] == data[sections['cd']:sections['eocd']] and final[layout['eocd']:] == eocd,
            'unexpected byte changes outside signing block/EOCD CD offset')
    require(payload_manifest(candidate) == payload_manifest(args.apk), 'payload/ZIP-entry changes')
    require(metadata(candidate, args.sdk) == metadata(args.apk, args.sdk), 'final app/version/SDK changed')
    official = run([args.sdk / 'apksigner', 'verify', '--verbose', '--print-certs', '--min-sdk-version', '24', candidate])
    require('Verified using v2 scheme (APK Signature Scheme v2): true' in official and
            'Number of signers: 1' in official and 'Signer #1 certificate SHA-256 digest: ' + CERT_SHA in official,
            'official final certificate/v2 verification')
    run([args.sdk / 'zipalign', '-c', '-P', '16', '4', candidate])
    require(sha(args.apk.read_bytes()) == V17_SHA, 'retained unsigned APK changed')
    audit = dict(request_id=request['request_id'], signed_apk_sha256=sha(final), signed_apk_size=len(final),
        original_certificate_sha256=CERT_SHA, application_id=APP, version_code=EXPECTED_VERSION, minimum_sdk=24,
        official_apksigner_verified=True, alignment_16kb=True, payload_unchanged=True,
        unsigned_original_unchanged=True, private_key_used_here=False, physical_device_tested=False,
        official_verifier_output=official)
    with args.output.with_suffix('.audit.json').open('x') as file:
        file.write(json.dumps(audit, indent=2) + '\n')
    os.link(candidate, args.output)  # atomic no-overwrite promotion, same directory/filesystem
    candidate.unlink()
    print(json.dumps(audit))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    for name in ['prepare', 'assemble']:
        child = sub.add_parser(name)
        child.add_argument('--apk', type=Path, required=True)
        child.add_argument('--v16', type=Path, required=True)
        child.add_argument('--sdk', type=Path, required=True, help='Existing Android build-tools directory')
        child.add_argument('--output', type=Path, required=True)
        child.add_argument('--policy', type=Path, help='Locally audited public APK hash/version/source pin for a later build; certificate/app/minSDK cannot change')
        if name == 'prepare':
            child.add_argument('--package-audit', type=Path, required=True)
            child.add_argument('--verification', type=Path, required=True)
        else:
            child.add_argument('--request', type=Path, required=True)
            child.add_argument('--response', type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.policy:
            load_policy(args.policy)
        (prepare if args.action == 'prepare' else assemble)(args)
    except Exception as error:
        raise SystemExit('STOP: detached workflow failed; do not retry or publish without resolving: ' + str(error)) from error


def load_policy(path):
    global V17_SHA, V17_SIZE, EXPECTED_VERSION, EXPECTED_INTEGRATED_SOURCE, EXPECTED_GAME_SOURCE
    policy = json.loads(path.read_text())
    require(set(policy) == {'apk_sha256','apk_size','version_code','integrated_source_commit','game_source_commit'}, 'public APK policy fields')
    for name in ['apk_sha256','integrated_source_commit','game_source_commit']:
        require(isinstance(policy[name], str) and re.fullmatch('[0-9a-f]{' + ('64' if name == 'apk_sha256' else '40') + '}', policy[name]) is not None, 'policy digest/commit format')
    require(type(policy['version_code']) is int and policy['version_code'] >= 18 and
            type(policy['apk_size']) is int and 0 < policy['apk_size'] < 1024*1024*1024, 'policy version/size')
    V17_SHA=policy['apk_sha256'];V17_SIZE=policy['apk_size'];EXPECTED_VERSION=policy['version_code']
    EXPECTED_INTEGRATED_SOURCE=policy['integrated_source_commit'];EXPECTED_GAME_SOURCE=policy['game_source_commit']


if __name__ == '__main__':
    main()
