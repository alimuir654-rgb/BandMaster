"""Negative-first tests: all gates should fail honestly when evidence is missing."""
import copy
import importlib.util
import json
import sys
import tempfile
import struct
import zlib
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1] / 'tools' / 'recruitment_quality_gate.py'
spec = importlib.util.spec_from_file_location('recruitment_quality_gate', TOOLS)
gate = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = gate
spec.loader.exec_module(gate)

class RecoveryGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[1]
        cls.state, cls.assets = gate.check_basic(cls.root, package_only=True)

    def test_valid_pack_prep(self):
        gate.verify_stage(self.root, 'prep', self.state, self.assets)

    def test_no_art_pass_without_real_sources(self):
        with self.assertRaisesRegex(gate.GateError, 'Art gate BLOCKED'):
            gate.verify_stage(self.root, 'art', self.state, self.assets)

    def test_no_native_pass_without_real_sources(self):
        with self.assertRaises(gate.GateError):
            gate.verify_stage(self.root, 'native', self.state, self.assets)

    def test_owner_cannot_auto_pass(self):
        with self.assertRaises(gate.GateError):
            gate.verify_stage(self.root, 'owner', self.state, self.assets)

    def test_path_traversal_is_rejected(self):
        with self.assertRaises(gate.GateError):
            gate.resolve_safe(self.root, '../../outside.png')

    def test_absolute_path_is_rejected(self):
        with self.assertRaises(gate.GateError):
            gate.resolve_safe(self.root, '/tmp/false-photo.png')

    def test_planned_asset_with_fake_hash_is_rejected(self):
        asset = copy.deepcopy(self.assets['portrait_featured'])
        asset['status'] = 'ready'
        asset['path'] = 'does_not_exist.png'
        asset['sha256'] = '0' * 64
        asset['origin_kind'] = 'generated_original'
        asset['rights_basis'] = 'claimed original'
        with self.assertRaisesRegex(gate.GateError, 'source file missing'):
            gate.verify_source(self.root, asset)

    def test_canonical_portrait_slots_remain_unique(self):
        self.assertEqual(self.assets['portrait_featured']['candidate_id'], 'alex')
        self.assertEqual(self.assets['portrait_contrast']['candidate_id'], 'nia_griffiths')
        fake_assets = copy.deepcopy(self.assets)
        fake_assets['portrait_contrast']['candidate_id'] = 'nia_carter'
        with self.assertRaisesRegex(gate.GateError, 'canonical candidate ID'):
            gate.verify_portrait_pair(fake_assets)

    def test_duplicate_face_source_hash_cannot_fill_two_slots(self):
        fake_assets = copy.deepcopy(self.assets)
        for aid in ('portrait_featured', 'portrait_contrast'):
            fake_assets[aid]['sha256'] = 'a' * 64
        with self.assertRaisesRegex(gate.GateError, 'cannot share source bytes'):
            gate.verify_portrait_pair(fake_assets)

    def test_valid_but_tiny_portrait_png_cannot_pass_as_master(self):
        def chunk(tag, payload):
            return struct.pack('>I', len(payload)) + tag + payload + struct.pack('>I', zlib.crc32(tag + payload) & 0xffffffff)
        ihdr = struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0)
        png = b'\\x89PNG\\r\\n\\x1a\\n' + chunk(b'IHDR', ihdr)
        png += chunk(b'IDAT', zlib.compress(b'\\x00\\xff\\x11\\x22\\xff')) + chunk(b'IEND', b'')
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            (root / 'mini.png').write_bytes(png)
            asset = {
                'id': 'portrait_featured', 'type': 'portrait', 'candidate_id': 'alex',
                'path': 'mini.png', 'sha256': gate.actual_sha256(root / 'mini.png'),
                'origin_kind': 'generated_original', 'rights_basis': 'Original image source',
                'width': 1, 'height': 1,
            }
            with self.assertRaisesRegex(gate.GateError, 'full-resolution portrait master'):
                gate.verify_source(root, asset)

    def test_empty_png_is_not_a_render(self):
        with tempfile.TemporaryDirectory() as t:
            path = Path(t) / 'fake.png'
            path.write_bytes(b'PNG logo')
            with self.assertRaisesRegex(gate.GateError, 'Expected actual PNG'):
                gate.png_size(path)

    def test_real_png_header_and_pixel_stream_are_verified(self):
        def chunk(tag, payload):
            return struct.pack('>I', len(payload)) + tag + payload + struct.pack('>I', zlib.crc32(tag + payload) & 0xffffffff)
        # Tiny valid 1x1 RGBA PNG encoded entirely with stdlib.
        ihdr = struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0)
        data = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr)
        data += chunk(b'IDAT', zlib.compress(b'\x00\xff\x11\x22\xff')) + chunk(b'IEND', b'')
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / 'real.png'
            p.write_bytes(data)
            self.assertEqual(gate.png_size(p), (1, 1))
            corrupted = bytearray(data)
            corrupted[42] ^= 1
            p.write_bytes(corrupted)
            with self.assertRaisesRegex(gate.GateError, 'CRC mismatch'):
                gate.png_size(p)

    def test_fake_owner_signoff_fails_at_schema(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            for rel in gate.REQUIRED_PACK:
                target = root / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes((self.root / rel).read_bytes())
            p = root / 'docs/recruitment_recovery/RECOVERY_STATE.json'
            state = json.loads(p.read_text())
            state['owner_approved'] = True
            state['owner_approval_evidence'] = None
            p.write_text(json.dumps(state), encoding='utf-8')
            with self.assertRaisesRegex(gate.GateError, 'No owner approval evidence'):
                gate.check_basic(root, package_only=True)

if __name__ == '__main__':
    unittest.main()
