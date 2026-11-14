#!/usr/bin/env python3
"""Validate a pinned public request; sign only in the original-key environment.

The APK stays in its build environment. No key generation/export, APK signing,
network access or private-key loading occurs in this Python process.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

import detached_apk_v2 as v2


def unique_object(pairs):
    result = {}
    for name, value in pairs:
        v2.require(name not in result, 'duplicate JSON field: ' + name)
        result[name] = value
    return result


def read_request(path, expected_sha256):
    v2.require(re.fullmatch('[0-9a-f]{64}', expected_sha256) is not None,
               'supply the independently reviewed exact request SHA-256')
    v2.require(path.stat().st_size <= 65536, 'request exceeds 64 KiB')
    raw = path.read_bytes()
    v2.require(hashlib.sha256(raw).hexdigest() == expected_sha256,
               'request file differs from the reviewed SHA-256')
    value = json.loads(raw, object_pairs_hook=unique_object)
    validate_public(value)
    return value


def validate_public(value):
    v2.require(type(value.get('schema_version')) is int and value['schema_version'] == 1
               and value.get('request_type') == 'android-apk-v2-detached-rsa-sha256',
               'unsupported request schema')
    v2.require(value.get('request_id') == v2.request_id(value), 'request ID changed')
    apk, source, signing = value['unsigned_apk'], value['source_identity'], value['signing']
    v2.require(apk['application_id'] == v2.APP and apk['minimum_sdk'] == 24
               and type(apk['version_code']) is int and apk['version_code'] >= 17
               and type(apk['size']) is int and 0 < apk['size'] < 1024**3
               and re.fullmatch('[0-9a-f]{64}', apk['sha256']) is not None,
               'unexpected app/version/SDK/APK identity')
    v2.require(source['repository'] == 'alimuir654-rgb/BandMaster'
               and source['entry_scene'] == 'experiments/playable_flightcase/opening.tscn'
               and source['save_directory'] == 'BandMasterOwnerPlaytestS40'
               and all(re.fullmatch('[0-9a-f]{40}', source[k]) is not None for k in
                       ['integrated_source_commit', 'packaged_game_source_commit']),
               'unexpected repository/source/entry/save identity')
    expected = {'scheme': 'APK Signature Scheme v2', 'signature_algorithm_id': '0x0103',
                'java_signature_algorithm': 'SHA256withRSA', 'padding': 'RSASSA-PKCS1-v1_5',
                'hash_algorithm': 'SHA-256', 'content_digest_algorithm': 'APK-v2 chunked SHA-256',
                'additional_attributes_base64': '', 'sdk_fourth_empty_field_base64': '',
                'chunk_size_bytes': v2.CHUNK, 'certificate_sha256': v2.CERT_SHA}
    v2.require(all(signing.get(k) == want for k, want in expected.items()),
               'signing algorithm or original certificate pin changed')
    cert = v2.unb64(signing['public_certificate_der_base64'])
    message = v2.unb64(signing['signed_data_base64'])
    digest = bytes.fromhex(signing['content_digest_hex'])
    v2.require(v2.sha(cert) == v2.CERT_SHA and len(digest) == 32,
               'original certificate or content digest mismatch')
    v2.require(v2.unb64(signing['public_key_spki_der_base64']) == v2.spki(cert)
               and signing['public_key_spki_sha256'] == v2.sha(v2.spki(cert))
               and signing['rsa_key_bits'] == v2.public_key(cert).key_size,
               'public RSA key mismatch')
    v2.require(0 < len(message) <= 16384 and message == v2.signed_data(digest, cert)
               and len(message) == signing['signed_data_size']
               and v2.sha(message) == signing['signed_data_sha256'],
               'exact APK-v2 signed-data bytes mismatch')
    audit = value['package_audit']
    v2.require(all(audit.get(k) is True for k in ['zip_crc_all_entries', 'zip32_single_disk',
               'no_preexisting_signing_block', 'alignment_16kb', 'forbidden_permissions_absent',
               'test_harness_excluded']) and audit['abis'] == ['arm64-v8a']
               and audit['permissions'] == [], 'retained package audit is held')
    original = value['original_certificate_audit']
    if original.get('reference_mode') == v2.PUBLIC_REFERENCE_MODE:
        reference_cert, reference_audit = v2.public_reference_certificate()
        v2.require(original == reference_audit and cert == reference_cert,
                   'pinned original public-reference proof changed')
        return cert, message
    v2.require(original['original_certificate_sha256'] == v2.CERT_SHA
               and original.get('official_apksigner') is True
               and original.get('original_rsa_signature_verified') is True,
               'original public-certificate audit is held')
    return cert, message


def make_response(value, signature):
    cert, message = validate_public(value)
    response = dict(schema_version=1, request_id=value['request_id'],
                    signed_data_sha256=v2.sha(message), certificate_sha256=v2.CERT_SHA,
                    signature_base64=v2.b64(signature))
    v2.validate_response(value, response, cert, message)
    return response


def sign_original(value, keystore, alias, output, password_env=None):
    cert, message = validate_public(value)
    v2.require(keystore.is_file(), 'original keystore missing; do not create a replacement')
    v2.require(not output.exists(), 'response output already exists')
    environment = os.environ.copy() if password_env is None else password_env
    v2.require(all(environment.get(k) for k in ['BM_STORE_PASSWORD', 'BM_KEY_PASSWORD']),
               'original environment must supply BM_STORE_PASSWORD and BM_KEY_PASSWORD securely')
    helper = Path(__file__).with_name('BandMasterDetachedSigner.java')
    # Only public material and the returned signature are written to temporary files.
    with tempfile.TemporaryDirectory(prefix='bm-public-sign-request-') as directory:
        work = Path(directory)
        (work / 'certificate.der').write_bytes(cert)
        (work / 'message.bin').write_bytes(message)
        result = subprocess.run(['java', str(helper), str(keystore.resolve()), alias,
                                 str(work / 'message.bin'), str(work / 'certificate.der'),
                                 str(work / 'signature.bin')], capture_output=True, text=True, timeout=90, env=environment)
        v2.require(result.returncode == 0, 'original-key helper refused: ' + result.stderr.strip())
        response = make_response(value, (work / 'signature.bin').read_bytes())
    # Exclusive create; never overwrite a previous signature or request.
    with output.open('x') as file:
        file.write(json.dumps(response, indent=2) + '\n')
    return response


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['check', 'sign', 'recover-sign'])
    parser.add_argument('--request', type=Path, required=True)
    parser.add_argument('--request-sha256', required=True,
                        help='Copy the separately reviewed exact file hash, not a hash calculated blindly')
    parser.add_argument('--keystore', type=Path, default=os.environ.get('BM_SIGNING_KEYSTORE_FILE'))
    parser.add_argument('--backup', type=Path, default=os.environ.get('BM_SIGNING_BACKUP_FILE'))
    parser.add_argument('--recovery-key-file', type=Path, default=os.environ.get('BM_SIGNING_RECOVERY_KEY_FILE'))
    parser.add_argument('--alias', default=os.environ.get('BM_SIGNING_ALIAS', 'androiddebugkey'))
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    try:
        value = read_request(args.request, args.request_sha256)
        if args.action == 'recover-sign':
            v2.require(args.backup and args.recovery_key_file and args.output,
                       'recover-sign requires encrypted backup, secure recovery-key file and output')
            v2.require(not args.output.exists(), 'response output already exists')
            from signing_backup import recovered_store
            with recovered_store(args.backup, args.recovery_key_file) as (store, alias, environment):
                sign_original(value, store, alias, args.output, environment)
        elif args.action == 'sign':
            v2.require(args.keystore and args.alias and args.output, 'sign requires original keystore, alias and output')
            sign_original(value, args.keystore, args.alias, args.output)
        print(json.dumps(dict(public_request_valid=True, request_id=value['request_id'],
                              request_sha256=args.request_sha256, action=args.action,
                              apk_independently_verified_here=False,
                              response_written=str(args.output) if args.action in {'sign', 'recover-sign'} else None)))
    except Exception as error:
        raise SystemExit('STOP: ' + type(error).__name__ + ': ' + str(error)) from error


if __name__ == '__main__':
    main()
