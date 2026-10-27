"""Source-gate regression; synthetic PNGs are created in memory, NEVER shipped as art."""
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools/validate_premium_fader_source.py"
spec = importlib.util.spec_from_file_location("fader_gate", MODULE_PATH)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

def png_pixel(alpha: int = 0) -> bytes:
    # 16x16 RGBA test-only PNG, no external dependencies.
    w = h = 16
    raw = b"".join(b"\x00" + bytes([100, 120, 140, alpha]) * w for _ in range(h))
    def chunk(name, payload):
        return struct.pack(">I", len(payload)) + name + payload + struct.pack(">I", zlib.crc32(name + payload) & 0xffffffff)
    return (gate.PNG_SIG + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) +
            chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))

class FaderSourceGateTests(unittest.TestCase):
    def test_blocked_manifest_is_explicit(self):
        status, detail = gate.validate()
        self.assertEqual(status, "BLOCKED")
        self.assertIn("flattened", detail)

    def test_png_alpha_off_and_on_decodes(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "test.png"
            path.write_bytes(png_pixel(0))
            w, h, a = gate.png_rgba(path)
            self.assertEqual((w, h), (16, 16))
            self.assertEqual(max(a), 0)
            path.write_bytes(png_pixel(190))
            self.assertEqual(min(gate.png_rgba(path)[2]), 190)

    def test_crc_tamper_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "tampered.png"
            data = bytearray(png_pixel(255))
            data[22] ^= 1
            path.write_bytes(data)
            with self.assertRaises(gate.InvalidSource):
                gate.png_rgba(path)

    def test_cannot_claim_ready_with_no_files(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "manifest.json"
            path.write_text(json.dumps({"family":"precision_linear_faders","status":"READY_FOR_REVIEW","source_files":[]}))
            with self.assertRaises(gate.InvalidSource):
                gate.validate(path)

    def test_blocked_cannot_fake_verified_file(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "manifest.json"
            path.write_text(json.dumps({"family":"precision_linear_faders","status":"BLOCKED","source_files":[{"path":"fake.png"}]}))
            with self.assertRaises(gate.InvalidSource):
                gate.validate(path)

if __name__ == "__main__":
    unittest.main()
