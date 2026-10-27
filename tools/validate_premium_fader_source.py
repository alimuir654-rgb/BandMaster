#!/usr/bin/env python3
"""Strict source gate for approved image-backed precision faders.
No source sprites are manufactured, extracted from screenshots, or substituted.
Exit 0 = genuine source PASS; exit 2 = known source BLOCKED; exit 1 = invalid.
--expect-blocked exits 0 only when the audited source is still BLOCKED.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys
import zlib

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "Art/UI/PremiumHardware/Faders/source_manifest.json"
LAYERS = {"base", "rail", "cap_normal", "cap_pressed", "cap_disabled", "level_on", "glow_off", "glow_on"}
PALETTES = {"day", "dusk", "night"}
PNG_SIG = b"\x89PNG\r\n\x1a\n"

class InvalidSource(ValueError):
    pass

def png_rgba(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIG):
        raise InvalidSource(f"{path}: invalid PNG signature")
    pos, width, height, idat, color_type, bit_depth, interlace = 8, 0, 0, bytearray(), None, None, None
    while pos + 12 <= len(data):
        size = struct.unpack_from(">I", data, pos)[0]
        tag = data[pos + 4:pos + 8]
        end = pos + 12 + size
        if end > len(data):
            raise InvalidSource(f"{path}: truncated chunk")
        payload = data[pos + 8:pos + 8 + size]
        expected_crc = struct.unpack_from(">I", data, pos + 8 + size)[0]
        if zlib.crc32(tag + payload) & 0xFFFFFFFF != expected_crc:
            raise InvalidSource(f"{path}: CRC mismatch in {tag!r}")
        if tag == b"IHDR":
            width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", payload)
            if bit_depth != 8 or color_type != 6 or compression or filtering or interlace:
                raise InvalidSource(f"{path}: require noninterlaced 8-bit RGBA PNG")
            if not (16 <= width <= 4096 and 16 <= height <= 4096):
                raise InvalidSource(f"{path}: invalid source dimensions {width}x{height}")
        elif tag == b"IDAT":
            idat.extend(payload)
        elif tag == b"IEND":
            break
        pos = end
    if not idat or not width:
        raise InvalidSource(f"{path}: missing IHDR/IDAT")
    try:
        raw = zlib.decompress(bytes(idat))
    except zlib.error as exc:
        raise InvalidSource(f"{path}: bad IDAT: {exc}") from exc
    stride = width * 4
    if len(raw) != (stride + 1) * height:
        raise InvalidSource(f"{path}: unexpected pixel data length")
    alpha = bytearray()
    previous = bytearray(stride)
    pos = 0
    for _row in range(height):
        filter_type = raw[pos]
        pos += 1
        line = bytearray(raw[pos:pos + stride])
        pos += stride
        if filter_type > 4:
            raise InvalidSource(f"{path}: unsupported PNG filter {filter_type}")
        for i in range(stride):
            left = line[i - 4] if i >= 4 else 0
            up = previous[i]
            ul = previous[i - 4] if i >= 4 else 0
            if filter_type == 1:
                line[i] = (line[i] + left) & 255
            elif filter_type == 2:
                line[i] = (line[i] + up) & 255
            elif filter_type == 3:
                line[i] = (line[i] + (left + up) // 2) & 255
            elif filter_type == 4:
                p = left + up - ul
                a, b, c = abs(p - left), abs(p - up), abs(p - ul)
                predictor = left if a <= b and a <= c else (up if b <= c else ul)
                line[i] = (line[i] + predictor) & 255
        alpha.extend(line[3::4])
        previous = line
    return width, height, bytes(alpha)

def validate(manifest_path: Path = MANIFEST) -> tuple[str, str]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("family") != "precision_linear_faders":
        raise InvalidSource("wrong control family")
    status = manifest.get("status")
    if status == "BLOCKED":
        if manifest.get("source_files"):
            raise InvalidSource("BLOCKED manifest cannot claim unverified source files")
        return "BLOCKED", "Lab05 has flattened reference images only; isolated cap/rail/glow sprites not imported"
    if status != "READY_FOR_REVIEW":
        raise InvalidSource("manifest must say BLOCKED or READY_FOR_REVIEW; never APPROVED automatically")
    entries = manifest.get("source_files", [])
    if len(entries) != len(LAYERS) * len(PALETTES):
        raise InvalidSource(f"expected {len(LAYERS)*len(PALETTES)} exact source layers; found {len(entries)}")
    seen = set()
    dims = {}
    for entry in entries:
        palette, layer = entry.get("palette"), entry.get("layer")
        if palette not in PALETTES or layer not in LAYERS or (palette, layer) in seen:
            raise InvalidSource(f"invalid/duplicate layer {palette}/{layer}")
        seen.add((palette, layer))
        rel = entry.get("path", "")
        p = (ROOT / rel).resolve()
        safe = (ROOT / "Art/UI/PremiumHardware/Faders").resolve()
        if not p.is_relative_to(safe) or p.suffix.lower() != ".png" or not p.is_file():
            raise InvalidSource(f"missing or unsafe source file: {rel}")
        expected = entry.get("sha256", "")
        if len(expected) != 64 or hashlib.sha256(p.read_bytes()).hexdigest() != expected:
            raise InvalidSource(f"SHA-256 mismatch or absent: {rel}")
        w, h, alpha = png_rgba(p)
        if entry.get("width") != w or entry.get("height") != h:
            raise InvalidSource(f"dimension mismatch: {rel}")
        dims[(palette, layer)] = (w, h)
        if layer == "glow_off" and any(alpha):
            raise InvalidSource(f"OFF GLOW LEAK: {rel} has nontransparent pixels")
        if layer != "glow_off" and not any(alpha):
            raise InvalidSource(f"empty source layer: {rel}")
    for palette in PALETTES:
        if len({dims[(palette, layer)] for layer in ("cap_normal", "cap_pressed", "cap_disabled")}) != 1:
            raise InvalidSource(f"{palette}: cap state geometry differs")
        if dims[(palette, "glow_off")] != dims[(palette, "glow_on")]:
            raise InvalidSource(f"{palette}: glow geometry differs")
    if not manifest.get("rights") or not manifest.get("provenance"):
        raise InvalidSource("missing rights/provenance")
    return "READY_FOR_REVIEW", "All 24 source layers, SHA-256, RGBA, alpha and geometry verified; visual approval still OPEN"

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--expect-blocked", action="store_true")
    args = parser.parse_args()
    try:
        status, reason = validate(args.manifest)
    except (InvalidSource, OSError, ValueError, KeyError) as exc:
        print(f"FADER SOURCE INVALID: {exc}", file=sys.stderr)
        return 1
    print(f"FADER SOURCE {status}: {reason}")
    if args.expect_blocked:
        return 0 if status == "BLOCKED" else 1
    return 0 if status == "READY_FOR_REVIEW" else 2

if __name__ == "__main__":
    raise SystemExit(main())
