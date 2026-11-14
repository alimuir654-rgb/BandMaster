import base64
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import signing_backup as backup
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='bm-backup-unit-')
        self.root = Path(self.tmp.name)
        self.key = self.root/'secret'
        backup.exclusive_private(self.key, AESGCM.generate_key(bit_length=256))
        self.file = self.root/'encrypted.bmk'
        self.payload = dict(format=backup.FORMAT, alias=backup.ALIAS, certificate_sha256=backup.CERT,
                            application_id=backup.APP, keystore_base64=base64.b64encode(b'QA-NOT-A-KEY').decode(),
                            store_password='QA_ONLY', key_password='QA_ONLY')
        self.write_blob(self.payload)
    def tearDown(self):
        self.tmp.cleanup()
    def write_blob(self, payload):
        nonce=os.urandom(12);cipher=AESGCM(self.key.read_bytes()).encrypt(nonce,json.dumps(payload).encode(),backup.AAD)
        self.file.write_text(json.dumps(dict(format=backup.FORMAT,nonce_base64=base64.b64encode(nonce).decode(),ciphertext_base64=base64.b64encode(cipher).decode())))
    def test_roundtrip_exact_bytes_and_passwords(self):
        value, raw=backup.decrypt_backup(self.file,self.key)
        self.assertEqual(value,self.payload);self.assertEqual(raw,b'QA-NOT-A-KEY')
    def test_tampered_ciphertext_refuses(self):
        value=json.loads(self.file.read_text());data=bytearray(base64.b64decode(value['ciphertext_base64']));data[-1]^=1;value['ciphertext_base64']=base64.b64encode(data).decode();self.file.write_text(json.dumps(value))
        with self.assertRaisesRegex(ValueError,'authentication failed'):backup.decrypt_backup(self.file,self.key)
    def test_wrong_secret_refuses(self):
        other=self.root/'other';backup.exclusive_private(other,AESGCM.generate_key(bit_length=256))
        with self.assertRaisesRegex(ValueError,'authentication failed'):backup.decrypt_backup(self.file,other)
    def test_recovered_identity_refuses(self):
        for field in ['format','alias','certificate_sha256','application_id']:
            value=dict(self.payload);value[field]='different';self.write_blob(value)
            with self.subTest(field=field),self.assertRaisesRegex(ValueError,'identity mismatch'):backup.decrypt_backup(self.file,self.key)
    def test_unknown_recovered_fields_refuse(self):
        self.write_blob(dict(self.payload,extra=True))
        with self.assertRaisesRegex(ValueError,'fields'):backup.decrypt_backup(self.file,self.key)
    def test_secret_permissions_size_and_symlink_refuse(self):
        self.key.chmod(0o644)
        with self.assertRaisesRegex(ValueError,'owner-only'):backup.read_recovery_secret(self.key)
        self.key.chmod(0o600);link=self.root/'link';link.symlink_to(self.key)
        with self.assertRaisesRegex(ValueError,'regular file'):backup.read_recovery_secret(link)
        self.key.write_bytes(b'short')
        with self.assertRaisesRegex(ValueError,'32 raw bytes'):backup.read_recovery_secret(self.key)
    def test_recovery_is_private_and_removed_even_on_failure(self):
        recovered=None
        with patch.object(backup,'original_certificate',return_value=backup.CERT):
            with self.assertRaisesRegex(RuntimeError,'QA stop'):
                with backup.recovered_store(self.file,self.key) as (store,alias,env):
                    recovered=store;self.assertEqual(store.stat().st_mode & 0o777,0o600);self.assertEqual(store.parent.stat().st_mode & 0o777,0o700);self.assertEqual(env['BM_KEY_PASSWORD'],'QA_ONLY');raise RuntimeError('QA stop')
        self.assertFalse(recovered.parent.exists())
    def test_backup_never_overwrites_original_or_outputs(self):
        original=self.root/'original.jks';original.write_bytes(b'QA-NOT-A-KEY');out=self.root/'new.bmk';secret=self.root/'new.secret';env=dict(os.environ,BM_STORE_PASSWORD='QA_ONLY',BM_KEY_PASSWORD='QA_ONLY')
        with patch.object(backup,'original_certificate',return_value=backup.CERT):
            backup.create_backup(original,backup.ALIAS,out,secret,env)
            self.assertEqual(backup.decrypt_backup(out,secret)[1],original.read_bytes())
            with self.assertRaisesRegex(ValueError,'already exists'):backup.create_backup(original,backup.ALIAS,out,secret,env)
        self.assertEqual(original.read_bytes(),b'QA-NOT-A-KEY')
    def test_writer_refuses_unrecoverable_oversize_envelope(self):
        original=self.root/'qa.jks';original.write_bytes(b'QA-NOT-A-KEY');out=self.root/'oversize.bmk'
        env=dict(os.environ,BM_STORE_PASSWORD='Q'*70000,BM_KEY_PASSWORD='QA_ONLY')
        with patch.object(backup,'original_certificate',return_value=backup.CERT):
            with self.assertRaisesRegex(ValueError,'recovery size limit'):
                backup.create_backup(original,backup.ALIAS,out,self.key,env)
        self.assertFalse(out.exists());self.assertEqual(original.read_bytes(),b'QA-NOT-A-KEY')
    def test_oversize_envelope_refuses_before_decryption(self):
        self.file.write_bytes(b'x'*(backup.LIMIT+1))
        with self.assertRaisesRegex(ValueError,'size'):backup.decrypt_backup(self.file,self.key)

if __name__=='__main__':unittest.main(verbosity=2)
