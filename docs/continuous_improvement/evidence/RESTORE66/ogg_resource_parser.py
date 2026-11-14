"""Strict, bounded V24 Vorbis recovery inspection and lossless Ogg rewrapping.

The module only returns bytes/reports. It never writes audio, modifies a manifest,
or treats a new Ogg container hash as the original container identity. The parent
implementation writer owns materialization and truthful provenance receipts.

Supported input is the observed uncompressed Godot 4.7 binary-resource format 6,
with one OggPacketSequence and one AudioStreamOggVorbis, no external resources or
scripts. Every saved packet group must fit one complete Ogg page (255 laces).
Anything outside this deliberately narrow recovery profile is rejected.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import subprocess
from typing import Any


class RecoveryError(ValueError):
    """The evidence is outside the strict recovery profile or is malformed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RecoveryError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class Reader:
    def __init__(self, data: bytes) -> None:
        self.data = data
        self.pos = 0

    def take(self, count: int) -> bytes:
        require(0 <= count <= len(self.data) - self.pos,
                f"Truncated resource at offset {self.pos}: need {count} bytes")
        value = self.data[self.pos:self.pos + count]
        self.pos += count
        return value

    def u32(self) -> int:
        return struct.unpack("<I", self.take(4))[0]

    def u64(self) -> int:
        return struct.unpack("<Q", self.take(8))[0]

    def count(self, minimum_bytes: int = 4) -> int:
        count = self.u32()
        require(count <= (len(self.data) - self.pos) // minimum_bytes,
                f"Impossible/typed count {count} at offset {self.pos - 4}")
        return count

    def string(self) -> str:
        length = self.u32()
        require(length > 0, "Expected null-terminated resource string")
        data = self.take(length)
        require(data[-1:] == b"\0" and b"\0" not in data[:-1],
                "Malformed null-terminated resource string")
        return data[:-1].decode("utf-8", errors="strict")

    def variant(self, depth: int = 0) -> Any:
        require(depth <= 3, "Variant nesting beyond supported resource profile")
        kind = self.u32()
        if kind == 1:  # NIL
            return None
        if kind == 2:  # BOOL
            value = self.u32()
            require(value in (0, 1), "Invalid boolean")
            return bool(value)
        if kind == 3:  # INT (32-bit resource representation)
            return struct.unpack("<i", self.take(4))[0]
        if kind == 4:  # FLOAT (32-bit resource representation)
            value = struct.unpack("<f", self.take(4))[0]
            require(math.isfinite(value), "Non-finite float")
            return value
        if kind == 5:  # STRING
            return self.string()
        if kind == 24:  # OBJECT / INTERNAL_RESOURCE
            object_kind, index = self.u32(), self.u32()
            require((object_kind, index) == (2, 0),
                    "Unexpected object reference")
            return ("internal_resource", index)
        if kind == 26:  # DICTIONARY, only simple string metadata supported
            result = {}
            for _ in range(self.count(8)):
                key = self.variant(depth + 1)
                value = self.variant(depth + 1)
                require(isinstance(key, str) and isinstance(value, str),
                        "Only string-to-string metadata dictionary supported")
                require(key not in result, "Duplicate metadata key")
                result[key] = value
            return result
        if kind == 30:  # ARRAY, no typed/shared array flag
            return [self.variant(depth + 1) for _ in range(self.count())]
        if kind == 31:  # PACKED_BYTE_ARRAY
            length = self.u32()
            value = self.take(length)
            require(self.take((-length) % 4) == b"\0" * ((-length) % 4),
                    "Nonzero packed-byte padding")
            return value
        if kind == 48:  # PACKED_INT64_ARRAY
            return [struct.unpack("<q", self.take(8))[0]
                    for _ in range(self.count(8))]
        raise RecoveryError(f"Unsupported variant {kind} at offset {self.pos - 4}")


STRING_TABLE = [
    "resource_local_to_scene", "resource_name", "packet_data",
    "granule_positions", "sampling_rate", "script", "packet_sequence",
    "bpm", "beat_count", "bar_beats", "tags", "loop", "loop_offset",
]


def packet_sequence_sha256(pages: list[list[bytes]], granules: list[int]) -> str:
    """Unambiguous digest binds page order, granules, packet order and bytes."""
    digest = hashlib.sha256(b"BandMaster RESTORE66 packet sequence v1\0")
    digest.update(struct.pack("<I", len(pages)))
    for page, granule in zip(pages, granules, strict=True):
        digest.update(struct.pack("<qI", granule, len(page)))
        for packet in page:
            digest.update(struct.pack("<I", len(packet)))
            digest.update(packet)
    return digest.hexdigest()


def validate_vorbis_pages(pages: list[list[bytes]], granules: list[int]) -> dict:
    require(len(pages) == len(granules) and len(pages) >= 3,
            "Missing or inconsistent packet groups/granules")
    require(all(isinstance(page, list) and page for page in pages),
            "Empty/invalid group: continuation-only pages are unsupported")
    require(all(isinstance(packet, bytes) and packet for page in pages
                for packet in page), "Empty or non-byte packet")
    require([len(pages[0]), len(pages[1])] == [1, 2],
            "Expected identification page then comment/setup page")
    headers = pages[0] + pages[1]
    require([p[:7] for p in headers] ==
            [b"\x01vorbis", b"\x03vorbis", b"\x05vorbis"],
            "Invalid or misplaced three Vorbis headers")
    identification = headers[0]
    require(len(identification) == 30, "Invalid identification header length")
    require(struct.unpack_from("<I", identification, 7)[0] == 0,
            "Unsupported Vorbis version")
    channels = identification[11]
    rate = struct.unpack_from("<I", identification, 12)[0]
    require(channels in (1, 2), "Only mono/stereo recovery supported")
    require(rate in (24000, 44100, 48000), "Unsupported sample rate")
    small, large = identification[28] & 15, identification[28] >> 4
    require(6 <= small <= large <= 13 and identification[29] == 1,
            "Invalid Vorbis block sizes or identification framing")
    require(all(packet[0] & 1 == 0 for page in pages[2:] for packet in page),
            "Non-audio packet after Vorbis headers")
    require(granules[:2] == [0, 0] and granules[-1] > 0,
            "Invalid header/final granule position")
    require(all(type(g) is int and g >= 0 for g in granules),
            "Negative/invalid granule: continuation-only page unsupported")
    require(all(a <= b for a, b in zip(granules, granules[1:])),
            "Granules must be monotonic")
    laces = [sum(len(packet) // 255 + 1 for packet in page) for page in pages]
    require(max(laces) <= 255,
            "Packet group needs over 255 laces; cannot preserve page grouping")
    return {"channels": channels, "sample_rate": rate,
            "frames": granules[-1], "seconds": granules[-1] / rate,
            "pages": len(pages), "packets": sum(map(len, pages)),
            "packet_bytes": sum(len(p) for page in pages for p in page),
            "max_page_laces": max(laces),
            "packet_sequence_sha256": packet_sequence_sha256(pages, granules)}


def parse_ogg_resource_bytes(data: bytes) -> dict:
    require(len(data) <= 64 * 1024 * 1024, "Resource exceeds bounded profile")
    reader = Reader(data)
    require(reader.take(4) == b"RSRC", "Expected uncompressed RSRC resource")
    require(tuple(reader.u32() for _ in range(5)) == (0, 0, 4, 7, 6),
            "Expected little-endian Godot 4.7 resource format 6 (32-bit real)")
    require(reader.string() == "AudioStreamOggVorbis", "Wrong root type")
    require(reader.u64() == 0, "Unexpected import metadata")
    require(reader.u32() == 3, "Unexpected resource flags")
    resource_uid = reader.u64()
    require(reader.take(44) == b"\0" * 44, "Nonzero reserved header")
    strings = [reader.string() for _ in range(reader.count())]
    require(strings == STRING_TABLE, "Unexpected resource property table")
    require(reader.u32() == 0, "External resource dependencies forbidden")
    internal = [(reader.string(), reader.u64()) for _ in range(reader.count())]
    require(len(internal) == 2, "Expected precisely two internal resources")
    objects = []
    for index, (resource_path, offset) in enumerate(internal):
        expected_type = ("OggPacketSequence", "AudioStreamOggVorbis")[index]
        require(resource_path.startswith("local://" + expected_type + "_"),
                "Unexpected internal resource path/type")
        require(offset == reader.pos, "Gaps/overlaps in internal resource table")
        require(reader.string() == expected_type, "Wrong internal resource type")
        properties = {}
        for _ in range(reader.count(8)):
            name_index = reader.u32()
            require(name_index < len(strings), "Invalid property-name index")
            key = strings[name_index]
            require(key not in properties, "Duplicate resource property")
            properties[key] = reader.variant()
        objects.append(properties)
    require(reader.take(4) == b"RSRC" and reader.pos == len(data),
            "Invalid resource trailer or trailing bytes")
    sequence, stream = objects
    require(set(sequence) == {"packet_data", "granule_positions",
                              "sampling_rate", "script"},
            "Unexpected OggPacketSequence properties")
    require(sequence["script"] is None, "Resource script forbidden")
    require(set(stream) <= {"packet_sequence", "tags", "script", "bpm",
                            "beat_count", "bar_beats", "loop", "loop_offset"},
            "Unexpected AudioStreamOggVorbis properties")
    require(stream.get("packet_sequence") == ("internal_resource", 0),
            "Wrong packet sequence reference")
    require(stream.get("script", None) is None, "Stream script forbidden")
    require(type(stream.get("tags", {})) is dict, "Invalid stream tags")
    require(stream.get("loop", False) is False and
            stream.get("loop_offset", 0.0) == 0.0 and
            stream.get("bpm", 0.0) == 0.0 and
            stream.get("beat_count", 0) == 0 and
            stream.get("bar_beats", 4) == 4,
            "Non-default playback metadata requires separate restoration")
    pages, granules = sequence["packet_data"], sequence["granule_positions"]
    require(isinstance(pages, list) and isinstance(granules, list),
            "Invalid sequence properties")
    summary = validate_vorbis_pages(pages, granules)
    require(sequence["sampling_rate"] == float(summary["sample_rate"]),
            "Resource sampling rate differs from Vorbis header")
    return {"packet_data": pages, "granule_positions": granules,
            "sampling_rate": sequence["sampling_rate"], "stream": stream,
            "resource_uid": resource_uid, "resource_sha256": sha256(data),
            "resource_bytes": len(data), **summary}


def parse_ogg_resource(path: Path) -> dict:
    return parse_ogg_resource_bytes(Path(path).read_bytes())


def _crc_table() -> tuple[int, ...]:
    table = []
    for value in range(256):
        crc = value << 24
        for _ in range(8):
            crc = ((crc << 1) ^ (0x04C11DB7 if crc & 0x80000000 else 0)) & 0xFFFFFFFF
        table.append(crc)
    return tuple(table)


CRC_TABLE = _crc_table()


def ogg_crc(data: bytes) -> int:
    """Ogg's direct CRC-32; not zlib.crc32 (which uses other conventions)."""
    crc = 0
    for value in data:
        crc = ((crc << 8) & 0xFFFFFFFF) ^ CRC_TABLE[((crc >> 24) ^ value) & 255]
    return crc


def reconstruct_ogg(resource: dict | Path, serial: int | None = None) -> bytes:
    """Rewrap complete packet groups; return bytes without writing any file."""
    if not isinstance(resource, dict):
        resource = parse_ogg_resource(resource)
    pages, granules = resource["packet_data"], resource["granule_positions"]
    summary = validate_vorbis_pages(pages, granules)
    if serial is None:
        serial = int.from_bytes(hashlib.sha256(
            b"BandMaster RESTORE66 Ogg serial v1\0" +
            bytes.fromhex(summary["packet_sequence_sha256"])).digest()[:4], "little")
    require(type(serial) is int and 0 <= serial < 2**32, "Invalid Ogg serial")
    result = bytearray()
    for index, (packets, granule) in enumerate(zip(pages, granules, strict=True)):
        lacing = bytearray()
        for packet in packets:
            lacing.extend([255] * (len(packet) // 255))
            lacing.append(len(packet) % 255)  # includes required zero terminator
        flags = (2 if index == 0 else 0) | (4 if index == len(pages) - 1 else 0)
        header = struct.pack("<4sBBqIIIB", b"OggS", 0, flags, granule,
                             serial, index, 0, len(lacing))
        page = bytearray(header) + lacing + b"".join(packets)
        struct.pack_into("<I", page, 22, ogg_crc(page))
        result.extend(page)
    output = bytes(result)
    reparsed = parse_ogg_bytes(output)
    require(reparsed["packet_data"] == pages and
            reparsed["granule_positions"] == granules,
            "Internal remux round-trip changed packets or granules")
    return output


def parse_ogg_bytes(data: bytes) -> dict:
    """Validate strict single-stream Ogg and extract completion-page packets.

    Continued packet pages are parsed correctly but may be rejected by the
    narrow resource/remux profile during comparison. Chaining, multiplexing,
    sequence gaps, CRC errors, incomplete packets and trailing bytes fail.
    """
    require(len(data) <= 64 * 1024 * 1024, "Container exceeds bounded profile")
    pos, serial, sequence = 0, None, 0
    pending = bytearray()
    pending_open = False
    pages, granules, page_metadata = [], [], []
    saw_eos = False
    while pos < len(data):
        require(not saw_eos, "Bytes after EOS/chained stream")
        require(len(data) - pos >= 27, "Truncated Ogg page header")
        magic, version, flags, granule, page_serial, page_seq, crc, count = (
            struct.unpack_from("<4sBBqIIIB", data, pos))
        require(magic == b"OggS" and version == 0, "Invalid Ogg page/version")
        require(flags & ~7 == 0, "Reserved Ogg header flags")
        require(bool(flags & 1) == pending_open, "Incorrect continuation flag")
        require(bool(flags & 2) == (sequence == 0), "Incorrect BOS flag")
        require(page_seq == sequence, "Ogg page sequence gap")
        if serial is None:
            serial = page_serial
        require(page_serial == serial, "Multiplexed/chained Ogg stream")
        require(count > 0 and pos + 27 + count <= len(data), "Empty/truncated lacing")
        laces = data[pos + 27:pos + 27 + count]
        end = pos + 27 + count + sum(laces)
        require(end <= len(data), "Truncated Ogg page body")
        page = bytearray(data[pos:end])
        page[22:26] = b"\0" * 4
        require(ogg_crc(page) == crc, f"Ogg CRC mismatch on page {sequence}")
        body_pos = pos + 27 + count
        packets = []
        for lace in laces:
            pending.extend(data[body_pos:body_pos + lace])
            body_pos += lace
            if lace < 255:
                packets.append(bytes(pending))
                pending.clear()
                pending_open = False
            else:
                pending_open = True
        require((granule >= 0) if packets else (granule == -1),
                "Invalid granule for page packet-completion state")
        saw_eos = bool(flags & 4)
        require(not (saw_eos and pending_open), "EOS before packet completion")
        pages.append(packets)
        granules.append(granule)
        page_metadata.append({"flags": flags, "laces": list(laces),
                              "bytes": end - pos, "crc": crc})
        pos, sequence = end, sequence + 1
    require(saw_eos and not pending_open and pages, "Missing EOS/incomplete Ogg")
    return {"packet_data": pages, "granule_positions": granules,
            "serial": serial, "page_metadata": page_metadata,
            "container_sha256": sha256(data), "container_bytes": len(data)}


def compare_ogg_to_resource(ogg: bytes | Path, resource: dict | Path) -> dict:
    if not isinstance(resource, dict):
        resource = parse_ogg_resource(resource)
    data = ogg if isinstance(ogg, bytes) else Path(ogg).read_bytes()
    container = parse_ogg_bytes(data)
    require(container["packet_data"] == resource["packet_data"],
            "Ogg packet bytes/order/page grouping differ from recovered resource")
    require(container["granule_positions"] == resource["granule_positions"],
            "Ogg page granules differ from recovered resource")
    # If original paging was complete, use its serial as a stronger control:
    # our generated container must be byte-for-byte equal, not just audio equal.
    original_reproduction = reconstruct_ogg(resource, container["serial"])
    exact_reproduction = original_reproduction == data
    require(exact_reproduction, "Original container not exactly reproduced with original serial")
    return {"container_sha256": container["container_sha256"],
            "container_bytes": container["container_bytes"],
            "resource_sha256": resource["resource_sha256"],
            "packet_sequence_sha256": resource["packet_sequence_sha256"],
            "packets_and_granules_equal": True,
            "original_serial": container["serial"],
            "original_bytes_reproduced_with_original_serial": exact_reproduction}


def recovered_bindings(recovery_root: Path) -> list[dict]:
    result = []
    root = Path(recovery_root).resolve()
    for remap in sorted(root.rglob("*.ogg.import")):
        text = remap.read_text(encoding="utf-8")
        matches = re.findall(r'^path="res://([^"\r\n]+)"$', text, re.M)
        require(len(matches) == 1, f"Ambiguous import path in {remap}")
        resource = (root / matches[0]).resolve()
        require(resource.is_relative_to(root / ".godot/imported") and
                resource.suffix == ".oggvorbisstr", "Import path outside recovered cache")
        relative = remap.relative_to(root).as_posix()[:-7]
        result.append({"path": relative, "resource": resource,
                       "resource_relative": matches[0], "remap": remap})
    require(result, "No recovered Ogg bindings found")
    require(len({row["path"] for row in result}) == len(result), "Duplicate source path")
    return result


def verify_all(recovery_root: Path, tracked_root: Path | None = None,
               decode_controls: int = 0) -> dict:
    rows = []
    tracked = set()
    if tracked_root is not None:
        output = subprocess.check_output(["git", "-C", str(tracked_root),
                                          "ls-files", "-z", "--", "*.ogg"])
        tracked = {p.decode("utf-8") for p in output.split(b"\0") if p}
    decoded = 0
    for binding in recovered_bindings(recovery_root):
        resource = parse_ogg_resource(binding["resource"])
        remux = reconstruct_ogg(resource)
        row = {"path": binding["path"], "resource": binding["resource_relative"],
               **{key: resource[key] for key in (
                   "resource_sha256", "resource_bytes", "sample_rate", "channels",
                   "frames", "seconds", "pages", "packets", "packet_bytes",
                   "max_page_laces", "packet_sequence_sha256")},
               "remux_sha256": sha256(remux), "remux_bytes": len(remux),
               "remux_serial": parse_ogg_bytes(remux)["serial"]}
        if binding["path"] in tracked:
            original_path = Path(tracked_root) / binding["path"]
            require(original_path.is_file(), f"Tracked Ogg absent on disk: {original_path}")
            original = original_path.read_bytes()
            row["tracked_control"] = compare_ogg_to_resource(original, resource)
            if decoded < decode_controls:
                hashes = []
                lengths = []
                for content in (original, remux):
                    proc = subprocess.run([
                        "ffmpeg", "-v", "error", "-nostdin", "-i", "pipe:0",
                        "-map", "0:a:0", "-c:a", "pcm_f32le", "-f", "f32le", "pipe:1"
                    ], input=content, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       check=True, timeout=60)
                    require(not proc.stderr, "Decoder emitted an error")
                    hashes.append(sha256(proc.stdout))
                    lengths.append(len(proc.stdout))
                require(hashes[0] == hashes[1] and lengths[0] == lengths[1],
                        "Decoded PCM control differs")
                row["tracked_control"].update({"decoded_pcm_f32le_sha256": hashes[0],
                                               "decoded_pcm_bytes": lengths[0]})
                decoded += 1
        rows.append(row)
    covered = {row["path"] for row in rows if "tracked_control" in row}
    if tracked_root is not None:
        require(covered == tracked, f"Tracked import coverage mismatch: {sorted(tracked - covered)}")
    require(decoded == decode_controls, "Insufficient tracked controls to decode")
    return {"recovered_ogg_resources": len(rows), "remux_roundtrips": len(rows),
            "tracked_packet_granule_matches": len(covered),
            "tracked_exact_container_reproductions_with_original_serial": len(covered),
            "tracked_decoded_pcm_controls": decoded,
            "private_resources": len(rows) - len(covered), "written_audio_files": 0,
            "max_page_laces": max(row["max_page_laces"] for row in rows), "files": rows}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("recovery_root", type=Path)
    parser.add_argument("--tracked-root", type=Path)
    parser.add_argument("--decode-controls", type=int, default=0)
    parser.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    require(args.decode_controls >= 0, "Decode control count cannot be negative")
    report = verify_all(args.recovery_root, args.tracked_root, args.decode_controls)
    if args.summary:
        report.pop("files")
    print(json.dumps(report, indent=2))
