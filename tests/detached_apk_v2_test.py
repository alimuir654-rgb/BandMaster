#!/usr/bin/env python3
"""Known-answer/public-fixture and fail-closed detached APK tests. Never creates keys/APKs."""
import argparse
import base64
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

from cryptography.exceptions import InvalidSignature

SPEC = importlib.util.spec_from_file_location('detached_apk_v2', Path(__file__).resolve().parents[1] / 'tools/detached_apk_v2.py')
V2 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(V2)


class DetachedTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.request = json.loads(ARGS.request.read_text())
        cls.apk_data, cls.layout, cls.certificate, cls.message = V2.validate_request(cls.request, ARGS.apk, ARGS.v16, ARGS.sdk)
        raw = ARGS.v16.read_bytes()
        layout = V2.zip_sections(raw)
        cls.reference_block = V2.signing_block(raw, layout)
        cls.reference_value = dict(cls.reference_block['pairs'])[V2.V2_ID]
        cls.reference = V2.parse_v2(cls.reference_value)
        cls.signature = dict(cls.reference['signatures'])[V2.RSA_SHA256]

    def reference_response(self):
        return dict(schema_version=1, request_id='original-v16-known-answer',
            signed_data_sha256=V2.sha(self.reference['data']), certificate_sha256=V2.CERT_SHA,
            signature_base64=V2.b64(self.signature))

    def test_original_signature_positive_known_answer(self):
        self.assertEqual(V2.validate_response({'request_id': 'original-v16-known-answer'}, self.reference_response(),
            self.certificate, self.reference['data']), self.signature)

    def test_original_signed_data_exact_sdk_encoding(self):
        self.assertEqual(len(self.reference['data']), 896)
        digest = dict(self.reference['digests'])[V2.RSA_SHA256]
        self.assertEqual(V2.signed_data(digest, self.certificate, self.reference['attributes']), self.reference['data'])
        self.assertEqual(self.reference['reserved'], b'')

    def test_original_signer_value_exact_roundtrip(self):
        self.assertEqual(V2.encode_v2_value(self.reference['data'], self.certificate, self.signature), self.reference_value)

    def test_reject_length_prefixed_message_instead_of_exact_bytes(self):
        with self.assertRaises(InvalidSignature):
            V2.verify_rsa(self.certificate, V2.lp(self.reference['data']), self.signature)

    def test_reject_signing_hash_text_instead_of_exact_bytes(self):
        with self.assertRaises(InvalidSignature):
            V2.verify_rsa(self.certificate, V2.sha(self.reference['data']).encode(), self.signature)

    def test_reject_missing_fourth_field(self):
        with self.assertRaises(InvalidSignature):
            V2.verify_rsa(self.certificate, self.reference['data'][:-4], self.signature)

    def test_original_signature_does_not_authorise_v17(self):
        with self.assertRaises(InvalidSignature):
            V2.verify_rsa(self.certificate, self.message, self.signature)

    def test_response_wrong_request_rejected(self):
        value = self.reference_response();value['request_id'] = 'wrong'
        with self.assertRaises(ValueError):
            V2.validate_response({'request_id': 'original-v16-known-answer'}, value, self.certificate, self.reference['data'])

    def test_response_wrong_certificate_rejected(self):
        value = self.reference_response();value['certificate_sha256'] = '00' * 32
        with self.assertRaises(ValueError):
            V2.validate_response({'request_id': 'original-v16-known-answer'}, value, self.certificate, self.reference['data'])

    def test_response_wrong_signed_data_hash_rejected(self):
        value = self.reference_response();value['signed_data_sha256'] = '00' * 32
        with self.assertRaises(ValueError):
            V2.validate_response({'request_id': 'original-v16-known-answer'}, value, self.certificate, self.reference['data'])

    def test_response_wrong_length_rejected(self):
        value = self.reference_response();value['signature_base64'] = V2.b64(self.signature[:-1])
        with self.assertRaises(ValueError):
            V2.validate_response({'request_id': 'original-v16-known-answer'}, value, self.certificate, self.reference['data'])

    def test_reject_request_metadata_change_before_io(self):
        value = copy.deepcopy(self.request);value['unsigned_apk']['version_code'] = 18
        with self.assertRaisesRegex(ValueError, 'request ID'):
            V2.validate_request(value, Path('/not-accessed.apk'), Path('/not-accessed-v16.apk'), ARGS.sdk)

    def test_request_signed_data_exact(self):
        fields = self.request['signing']
        self.assertEqual(base64.b64decode(fields['signed_data_base64'], validate=True), self.message)
        self.assertEqual(V2.sha(self.message), fields['signed_data_sha256'])
        self.assertEqual(len(self.message), fields['signed_data_size'])
        self.assertEqual(V2.sha(self.certificate), V2.CERT_SHA)

    def test_invalid_signature_creates_no_candidate_or_final(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            response = copy.deepcopy(self.request['response_template'])
            response.update(request_id=self.request['request_id'], signature_base64=V2.b64(bytes(256)))
            response_path = root / 'response.json';response_path.write_text(json.dumps(response))
            arguments = argparse.Namespace(apk=ARGS.apk, v16=ARGS.v16, sdk=ARGS.sdk, request=ARGS.request,
                response=response_path, output=root / 'not-created.apk')
            with self.assertRaises(InvalidSignature):
                V2.assemble(arguments)
            self.assertFalse(arguments.output.exists())
            self.assertFalse(arguments.output.with_name(arguments.output.name + '.pending-audit').exists())
            self.assertFalse(arguments.output.with_suffix('.audit.json').exists())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['request', 'apk', 'v16', 'sdk']:
        parser.add_argument('--' + name, type=Path, required=True)
    ARGS = parser.parse_args()
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(DetachedTests))
    raise SystemExit(0 if result.wasSuccessful() else 1)
