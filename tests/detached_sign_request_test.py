#!/usr/bin/env python3
"""Public known-answer and tamper tests. Never generates or loads a private key."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import detached_apk_v2 as v2
import detached_sign_request as signer
from cryptography.exceptions import InvalidSignature


class SignRequestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.path = ROOT / 'docs/signing/BandMaster-V23-APK-v2-signing-request.json'
        cls.pin = '7ebd68fbbc5baaac8aa50afcb3fc884733a686394de36f96df04ccab95be6741'
        cls.v23 = signer.read_request(cls.path, cls.pin)
        cls.v22 = json.loads((ROOT / 'docs/signing/fixtures/v22-request.json').read_text())
        cls.response = json.loads((ROOT / 'docs/signing/fixtures/v22-response.json').read_text())
        cls.signature = v2.unb64(cls.response['signature_base64'])

    def mutated(self, edit):
        value = copy.deepcopy(self.v23)
        edit(value)
        value['request_id'] = v2.request_id(value)
        return value

    def test_v23_exact_frozen_public_request(self):
        self.assertEqual(self.v23['request_id'], '93f51ed3b0d1cd0df531c10b2ffc00bb556a75147f452f9a54b87abafebf3c8b')
        cert, message = signer.validate_public(self.v23)
        self.assertEqual(len(message), 884)
        self.assertEqual(v2.sha(cert), v2.CERT_SHA)

    def test_actual_original_v22_signature_known_answer(self):
        self.assertEqual(signer.make_response(self.v22, self.signature), self.response)

    def test_old_signature_cannot_sign_v23(self):
        with self.assertRaises(InvalidSignature):
            signer.make_response(self.v23, self.signature)

    def test_changed_pinned_request_file_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'request.json'
            path.write_bytes(self.path.read_bytes() + b'\n')
            with self.assertRaisesRegex(ValueError, 'reviewed SHA'):
                signer.read_request(path, self.pin)

    def test_changed_digest_cannot_reuse_signed_data(self):
        value = self.mutated(lambda d: d['signing'].update(content_digest_hex='00' * 32))
        with self.assertRaisesRegex(ValueError, 'signed-data'):
            signer.validate_public(value)

    def test_changed_app_rejected(self):
        value = self.mutated(lambda d: d['unsigned_apk'].update(application_id='different.app'))
        with self.assertRaisesRegex(ValueError, 'app/version'):
            signer.validate_public(value)

    def test_pss_is_not_pkcs1_v15(self):
        value = self.mutated(lambda d: d['signing'].update(signature_algorithm_id='0x0101'))
        with self.assertRaisesRegex(ValueError, 'algorithm'):
            signer.validate_public(value)

    def test_certificate_pin_cannot_be_replaced(self):
        value = self.mutated(lambda d: d['signing'].update(certificate_sha256='00' * 32))
        with self.assertRaisesRegex(ValueError, 'certificate'):
            signer.validate_public(value)

    def test_held_audit_cannot_sign(self):
        value = self.mutated(lambda d: d['package_audit'].update(alignment_16kb=False))
        with self.assertRaisesRegex(ValueError, 'audit'):
            signer.validate_public(value)

    def test_duplicate_json_fields_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'duplicate.json'
            raw = b'{"schema_version":1,"schema_version":1}'
            path.write_bytes(raw)
            with self.assertRaisesRegex(ValueError, 'duplicate'):
                signer.read_request(path, v2.sha(raw))

    def test_no_key_fails_without_creating_response(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            with self.assertRaisesRegex(ValueError, 'original keystore missing'):
                signer.sign_original(self.v23, path / 'missing.jks', 'original', path / 'response.json')
            self.assertEqual(list(path.iterdir()), [])

    def test_java_compiles_and_missing_original_refuses_without_output(self):
        cert, message = signer.validate_public(self.v23)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / 'cert.der').write_bytes(cert)
            (path / 'message.bin').write_bytes(message)
            result = subprocess.run(['java', str(ROOT / 'tools/BandMasterDetachedSigner.java'),
                                     str(path / 'missing.jks'), 'original', str(path / 'message.bin'),
                                     str(path / 'cert.der'), str(path / 'signature.bin')],
                                    text=True, capture_output=True, timeout=45)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Original keystore missing', result.stderr)
            self.assertFalse((path / 'signature.bin').exists())
            self.assertFalse((path / 'missing.jks').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
