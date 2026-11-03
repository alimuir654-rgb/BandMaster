"""Provider-neutral, nonshipping authoring contracts. All operations are offline.

Planning never generates audio. Duration means the COMPLETE asset including tail.
Clearance labels describe evidence; changing a label cannot install a renderer.
"""
from __future__ import annotations

import copy
import hashlib
import json
import math
import os
import re
import struct
import wave
from fractions import Fraction
from pathlib import Path
from typing import BinaryIO


class AuthoringError(ValueError):
    """Invalid or unsupported authoring input; no partial operation is performed."""


USE_CASES = frozenset({"instrument_clip", "audition", "song_snippet"})
MUSICIANSHIP = frozenset({"technique", "timing", "originality", "feel", "versatility", "presence"})
REQUEST_KEYS = frozenset({"schema_version", "id", "use_case", "style", "backend", "study",
    "instruments", "duration_seconds", "tail_seconds", "arrangement", "musicianship",
    "output_format", "source_format", "source_duration_seconds", "review_mode",
    "requires_isolation", "contains_voice", "extensions"})


def seconds(value, name="seconds", *, positive=False) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (str, int, float)):
        raise AuthoringError(f"{name} must be a finite number")
    try:
        number = Fraction(str(value))
    except (ValueError, ZeroDivisionError, OverflowError):
        raise AuthoringError(f"{name} must be a finite number") from None
    try:
        finite = math.isfinite(float(number))
    except OverflowError:
        finite = False
    if not finite:
        raise AuthoringError(f"{name} exceeds the supported finite range")
    if number < 0 or (positive and number == 0):
        raise AuthoringError(f"{name} must be {'positive' if positive else 'nonnegative'}")
    return number


def integer(value, name, minimum=0):
    if type(value) is not int or value < minimum:
        raise AuthoringError(f"{name} must be an integer >= {minimum}")
    return value


def text(value, name):
    if not isinstance(value, str) or not value.strip():
        raise AuthoringError(f"{name} must be nonempty text")
    return value


def identifier(value, name):
    text(value, name)
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_.-]*", value):
        raise AuthoringError(f"{name} must be a stable identifier")
    return value


def version(document, name):
    if not isinstance(document, dict) or type(document.get("schema_version")) is not int or document["schema_version"] != 1:
        raise AuthoringError(f"Unsupported {name} schema; retain input for a compatible version")


def load_json(path):
    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result: raise AuthoringError("Duplicate JSON key: " + key)
            result[key] = value
        return result
    try:
        with Path(path).open("rb") as source:
            raw = source.read(1024 * 1024 + 1)
        if len(raw) > 1024 * 1024: raise AuthoringError("Authoring JSON exceeds the 1 MiB input limit")
        return json.loads(raw.decode("utf-8"), object_pairs_hook=unique_object,
                          parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))
    except (OSError, ValueError) as exc:
        raise AuthoringError(f"Cannot read JSON {path}: {exc}") from exc


def load_catalog(path=None):
    catalog = load_json(path or Path(__file__).with_name("catalog.json"))
    version(catalog, "catalog")
    for field in ("styles", "backends", "studies"):
        if not isinstance(catalog.get(field), dict):
            raise AuthoringError(f"catalog.{field} must be an object")
    return validate_catalog(catalog)


def pcm_format(value, name):
    if not isinstance(value, dict) or set(value) != {"sample_rate", "channels", "sample_width_bytes"}:
        raise AuthoringError(f"{name} requires sample_rate, channels, sample_width_bytes")
    integer(value["sample_rate"], name + ".sample_rate", 1)
    integer(value["channels"], name + ".channels", 1)
    if type(value["sample_width_bytes"]) is not int or value["sample_width_bytes"] not in (1, 2, 3, 4):
        raise AuthoringError(f"{name} supports integer PCM widths 1–4 bytes")
    return dict(value)


def validate_catalog(catalog):
    version(catalog, "catalog")
    for group in ("styles", "backends", "studies"):
        if not isinstance(catalog.get(group), dict):
            raise AuthoringError(f"catalog.{group} must be an object")
        for key, item in catalog[group].items():
            identifier(key, group + " ID")
            if not isinstance(item, dict):
                raise AuthoringError(f"{group}.{key} must be an object")
    for item in catalog["styles"].values():
        text(item.get("label"), "style label")
        if not isinstance(item.get("guidance"), list) or any(not isinstance(x, str) or not x.strip() for x in item["guidance"]):
            raise AuthoringError("Style guidance must be a list of nonempty text")
    for item in catalog["backends"].values():
        text(item.get("label"), "backend label")
        minimum = seconds(item.get("min_seconds", 0))
        if "max_seconds" in item and seconds(item["max_seconds"], positive=True) < minimum:
            raise AuthoringError("Backend maximum is below its minimum")
        if "runtime_available" in item and type(item["runtime_available"]) is not bool:
            raise AuthoringError("runtime_available must be boolean")
    for item in catalog["studies"].values():
        for key in ("max_files", "max_bytes"):
            if key not in item: raise AuthoringError("Study budget missing " + key)
            integer(item[key], key)
        if "max_seconds" not in item: raise AuthoringError("Study budget missing max_seconds")
        seconds(item["max_seconds"])
        if not isinstance(item.get("charged", {}), dict): raise AuthoringError("charged must be an object")
        charged = item.get("charged", {})
        integer(charged.get("files", 0), "charged.files")
        integer(charged.get("bytes", 0), "charged.bytes")
        seconds(charged.get("seconds", 0))
        for key in ("use_cases", "instruments"):
            if not isinstance(item.get(key, []), list) or any(not isinstance(x, str) for x in item.get(key, [])):
                raise AuthoringError(f"Study {key} must be a list of identifiers")
        if not isinstance(item.get("review_format", {}), dict): raise AuthoringError("review_format must be an object")
        for key, value in item.get("review_format", {}).items():
            if key not in ("max_sample_rate", "channels", "sample_width_bytes"):
                raise AuthoringError("Unknown study review format field")
            integer(value, "review_format." + key, 1)
            if key == "sample_width_bytes" and value not in (1, 2, 3, 4):
                raise AuthoringError("Invalid review PCM width")
        if type(item.get("adopted", False)) is not bool or type(item.get("voices_allowed", False)) is not bool:
            raise AuthoringError("Study adoption/voice fields must be boolean")
        integer(item.get("header_reserve_bytes_per_file", 4096), "header reserve", 44)
    return catalog


def validate_request(request, catalog=None):
    catalog = validate_catalog(catalog) if catalog is not None else load_catalog()
    version(request, "request")
    unknown = set(request) - REQUEST_KEYS
    if unknown:
        raise AuthoringError(f"Unknown request fields {sorted(unknown)}; use extensions for additional metadata")
    for key in ("id", "style", "backend", "study"):
        identifier(request.get(key), key)
    if request.get("use_case") not in USE_CASES:
        raise AuthoringError("use_case must be instrument_clip, audition or song_snippet")
    if request["style"] not in catalog["styles"]:
        raise AuthoringError("Unknown style profile; register a local data profile first")
    if request["backend"] not in catalog["backends"]:
        raise AuthoringError("Unknown backend descriptor; no provider is selected implicitly")
    total = seconds(request.get("duration_seconds"), "duration_seconds", positive=True)
    if seconds(request.get("tail_seconds", 0), "tail_seconds") > total:
        raise AuthoringError("Tail must be INSIDE the requested complete duration")
    items = request.get("instruments")
    if not isinstance(items, list) or not items:
        raise AuthoringError("At least one instrument is required")
    pairs = set()
    for item in items:
        if not isinstance(item, dict) or set(item) != {"id", "role"}:
            raise AuthoringError("Each instrument requires id and role")
        pair = (identifier(item["id"], "instrument.id"), text(item["role"], "instrument.role"))
        if pair in pairs:
            raise AuthoringError("Repeated instrument/role pair; distinguish ensemble roles")
        pairs.add(pair)
    text(request.get("arrangement"), "arrangement")
    skills = request.get("musicianship", {})
    if not isinstance(skills, dict) or set(skills) - MUSICIANSHIP:
        raise AuthoringError("Musicianship uses technique/timing/originality/feel/versatility/presence only")
    for key, value in skills.items():
        text(value, "musicianship." + key)  # authored qualitative context, never numeric grades
    pcm_format(request.get("output_format"), "output_format")
    pcm_format(request.get("source_format", request["output_format"]), "source_format")
    if "source_duration_seconds" in request:
        seconds(request["source_duration_seconds"], "source_duration_seconds", positive=True)
    if request.get("review_mode", "derived") not in ("derived", "same_asset"):
        raise AuthoringError("review_mode must be derived or same_asset")
    for key in ("requires_isolation", "contains_voice"):
        if key in request and type(request[key]) is not bool:
            raise AuthoringError(key + " must be boolean")
    if not isinstance(request.get("extensions", {}), dict):
        raise AuthoringError("extensions must be an object")
    return copy.deepcopy(request)


def budget_totals(assets, policy):
    """Exact rational comparisons. Source, intermediates and derived outputs all count."""
    charged = policy.get("charged", {})
    files = integer(charged.get("files", 0), "charged.files") + len(assets)
    duration = seconds(charged.get("seconds", 0))
    byte_count = integer(charged.get("bytes", 0), "charged.bytes")
    for asset in assets:
        duration += Fraction(integer(asset["frames"], "frames"), integer(asset["sample_rate"], "sample_rate", 1)) if "frames" in asset else seconds(asset["duration_seconds"])
        byte_count += integer(asset["bytes"], "asset.bytes")
    limits = {"files": integer(policy["max_files"], "max_files"),
              "seconds": seconds(policy["max_seconds"]), "bytes": integer(policy["max_bytes"], "max_bytes")}
    exceeded = [name for name, value in (("files", files), ("seconds", duration), ("bytes", byte_count)) if value > limits[name]]
    return {"files": files, "seconds": float(duration), "seconds_exact": str(duration), "bytes": byte_count,
            "limits": {"files": limits["files"], "seconds": float(limits["seconds"]), "bytes": limits["bytes"]},
            "exceeded": exceeded, "within_budget": not exceeded}


def plan_request(request, catalog=None):
    catalog = validate_catalog(catalog) if catalog is not None else load_catalog()
    req = validate_request(request, catalog)
    backend = catalog["backends"][req["backend"]]
    policy = catalog["studies"].get(req["study"])
    complete = seconds(req["duration_seconds"])
    minimum = seconds(backend.get("min_seconds", 0))
    raw_duration = seconds(req["source_duration_seconds"]) if "source_duration_seconds" in req else max(complete, minimum)
    raw_format = req.get("source_format", req["output_format"])
    holds = ["no_executable_renderer_configured"]  # this package never performs inference
    for key in ("capability_clearance", "rights_clearance", "cost_clearance"):
        if backend.get(key) != "cleared": holds.append("backend_" + key + "_required")
    if backend.get("runtime_available") is not True: holds.append("backend_runtime_unavailable")
    if raw_duration < minimum: holds.append("source_below_backend_minimum")
    if raw_duration < complete: holds.append("source_shorter_than_review_requires_separate_transformation_contract")
    if "max_seconds" in backend and raw_duration > seconds(backend["max_seconds"]): holds.append("source_above_backend_maximum")
    if req.get("requires_isolation", len(req["instruments"]) == 1) and backend.get("isolation") != "verified":
        holds.append("isolated_instrument_capability_unverified")
    same = req.get("review_mode", "derived") == "same_asset"
    if same and (raw_duration != complete or raw_format != req["output_format"]):
        holds.append("same_asset_requires_identical_complete_duration_and_format")
        same = False  # the requested review would require another complete asset
    reserve = integer((policy or {}).get("header_reserve_bytes_per_file", 4096), "header reserve")
    def estimated(role, duration, fmt):
        frames = math.ceil(duration * fmt["sample_rate"])
        return {"id": role, "role": role, "duration_seconds": float(duration), "frames": frames,
                **fmt, "bytes": frames * fmt["channels"] * fmt["sample_width_bytes"] + reserve,
                "measurement": "estimate_including_header_reserve; actual output must be inspected"}
    assets = [estimated("source_and_review" if same else "source", raw_duration, raw_format)]
    if not same: assets.append(estimated("review", complete, req["output_format"]))
    totals = None
    if policy is None or policy.get("adopted") is not True:
        holds.append("study_contract_not_adopted")
    if policy is not None:
        totals = budget_totals(assets, policy)
        if not totals["within_budget"]: holds.append("study_budget_exceeded")
        if req["use_case"] not in policy.get("use_cases", []): holds.append("use_case_outside_study_scope")
        if req.get("contains_voice", False) and policy.get("voices_allowed") is not True:
            holds.append("voices_outside_study_scope")
        if any(i["id"] not in policy.get("instruments", []) for i in req["instruments"]): holds.append("instrument_outside_study_scope")
        required = policy.get("review_format", {})
        fmt = req["output_format"]
        if (fmt["sample_rate"] > required.get("max_sample_rate", fmt["sample_rate"]) or
            any(fmt[key] != required.get(key, fmt[key]) for key in ("channels", "sample_width_bytes"))):
            holds.append("review_format_outside_study_scope")
    return {"schema_version": 1, "request": req, "audience": "private_authoring",
            "style_profile": catalog["styles"][req["style"]], "backend": backend,
            "planned_assets": assets, "budget": totals, "holds": holds,
            "generation_allowed": False, "status": "hold", "musical_seconds_before_tail": float(complete - seconds(req.get("tail_seconds", 0))),
            "notes": ["Durations include tails. Cropping does not erase source/intermediate files.",
                      "Format/size estimates are requested planning assumptions, not verified provider output.",
                      "A larger study needs a prospective adopted contract; this tool does not grant authority.",
                      "No musical credibility, individual-output rights, listening or game integration acceptance is inferred."]}


def _stream_hash(stream, expected_bytes):
    stream.seek(0)
    digest = hashlib.sha256()
    remaining = expected_bytes
    while remaining:
        chunk = stream.read(min(65536, remaining))
        if not chunk: raise AuthoringError("Input length changed during inspection")
        remaining -= len(chunk)
        digest.update(chunk)
    if stream.read(1): raise AuthoringError("Input length changed during inspection")
    return digest.hexdigest()


def _file_stamp(stream):
    try:
        stat = os.fstat(stream.fileno())
        return stat.st_dev, stat.st_ino, stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns
    except (AttributeError, OSError, ValueError):
        return None  # in-memory structural fixtures have no filesystem metadata


def _riff_structure(stream, container_bytes):
    """Validate declared container/chunk/fmt arithmetic that wave.open ignores."""
    stream.seek(0)
    header = stream.read(12)
    if len(header) != 12 or header[:4] != b"RIFF" or header[8:] != b"WAVE":
        raise AuthoringError("Expected a RIFF/WAVE container")
    end = struct.unpack("<I", header[4:8])[0] + 8
    if end != container_bytes:
        raise AuthoringError("RIFF declared size disagrees with complete container bytes")
    offset, fmt, data_bytes = 12, None, None
    while offset < end:
        stream.seek(offset)
        chunk = stream.read(8)
        if len(chunk) != 8: raise AuthoringError("Incomplete RIFF chunk header")
        kind, size = chunk[:4], struct.unpack("<I", chunk[4:])[0]
        chunk_end = offset + 8 + size
        if chunk_end > end: raise AuthoringError("RIFF chunk exceeds its container")
        if kind == b"fmt ":
            if fmt is not None or size < 16: raise AuthoringError("Missing or ambiguous PCM format chunk")
            raw = stream.read(min(size, 40))
            if len(raw) < 16: raise AuthoringError("Truncated PCM format")
            tag, channels, rate, byte_rate, align, bits = struct.unpack("<HHIIHH", raw[:16])
            if tag == 65534:
                pcm_guid = b"\x01\x00\x00\x00\x00\x00\x10\x00\x80\x00\x00\xaa\x00\x38\x9b\x71"
                extension_bytes = struct.unpack("<H", raw[16:18])[0] if len(raw) >= 18 else 0
                if len(raw) < 40 or extension_bytes < 22 or extension_bytes + 18 > size or raw[24:40] != pcm_guid:
                    raise AuthoringError("Unsupported extensible WAV subformat")
                valid_bits = struct.unpack("<H", raw[18:20])[0]
                if not 0 < valid_bits <= bits: raise AuthoringError("Invalid extensible PCM precision")
            elif tag != 1:
                raise AuthoringError("Only uncompressed integer PCM WAV is supported")
            if channels <= 0 or rate <= 0 or bits not in (8, 16, 24, 32):
                raise AuthoringError("Invalid PCM format fields")
            expected_align = channels * (bits // 8)
            if align != expected_align or byte_rate != rate * expected_align:
                raise AuthoringError("PCM block alignment or byte rate disagrees with format")
            fmt = align
        elif kind == b"data":
            if data_bytes is not None or fmt is None: raise AuthoringError("Missing, reordered or ambiguous PCM data")
            data_bytes = size
        # A terminal odd-sized data chunk may omit its pad, as stdlib wave writes.
        offset = chunk_end + (size % 2 if chunk_end < end else 0)
    if offset != end or fmt is None or data_bytes is None or data_bytes % fmt:
        raise AuthoringError("Incomplete PCM container or partial frame")


def inspect_wav_stream(stream: BinaryIO):
    """Inspect integer PCM WAV in chunks; does not edit, render or play audio."""
    before_stamp = _file_stamp(stream)
    stream.seek(0, 2)
    container_bytes = stream.tell()
    digest = _stream_hash(stream, container_bytes)
    _riff_structure(stream, container_bytes)
    stream.seek(0)
    try:
        with wave.open(stream, "rb") as wav:
            rate, channels, width, frames = wav.getframerate(), wav.getnchannels(), wav.getsampwidth(), wav.getnframes()
            if rate <= 0 or frames <= 0 or wav.getcomptype() != "NONE" or width not in (1, 2, 3, 4):
                raise AuthoringError("Expected nonempty uncompressed integer PCM WAV")
            samples = 0
            decoded = 0
            peak = 0
            squares = 0
            while block := wav.readframes(4096):
                if len(block) % (channels * width): raise AuthoringError("Partial PCM frame")
                decoded += len(block) // (channels * width)
                for offset in range(0, len(block), width):
                    value = block[offset] - 128 if width == 1 else int.from_bytes(block[offset:offset + width], "little", signed=True)
                    peak = max(peak, abs(value))
                    squares += value * value
                    samples += 1
            if decoded != frames: raise AuthoringError("Truncated PCM data disagrees with declared frame count")
    except (wave.Error, EOFError, ValueError, ZeroDivisionError) as exc:
        raise AuthoringError(f"Invalid/unsupported WAV: {exc}") from exc
    if _stream_hash(stream, container_bytes) != digest or _file_stamp(stream) != before_stamp:
        raise AuthoringError("Input WAV changed during inspection; hash and measurements are not bound")
    full_scale = 1 << (width * 8 - 1)
    return {"container_bytes": container_bytes, "sha256": digest, "frames": frames,
            "sample_rate": rate, "channels": channels, "sample_width_bytes": width,
            "duration_seconds": float(Fraction(frames, rate)), "duration_exact": str(Fraction(frames, rate)),
            "sample_peak_dbfs": 20 * math.log10(peak / full_scale) if peak else None,
            "rms_dbfs": 10 * math.log10(squares / samples / (full_scale * full_scale)) if squares else None,
            "silent": peak == 0, "true_peak_measured": False, "LUFS_measured": False,
            "rights_assessed": False, "listening_acceptance": False, "source_stability_checked": True}


def inspect_wav(path):
    try:
        with Path(path).open("rb") as stream: return {"path": str(path), **inspect_wav_stream(stream)}
    except OSError as exc:
        raise AuthoringError(f"Cannot inspect WAV {path}: {exc}") from exc


def audit_bundle(manifest, catalog=None):
    """Audit actual source/intermediate/review containers and explicit provenance graph."""
    catalog = validate_catalog(catalog) if catalog is not None else load_catalog()
    version(manifest, "bundle")
    policy = catalog["studies"].get(manifest.get("study"))
    if policy is None: raise AuthoringError("Unknown study contract")
    assets = manifest.get("assets")
    if not isinstance(assets, list) or not assets: raise AuthoringError("Bundle requires assets")
    ids, paths = set(), set()
    for item in assets:
        if not isinstance(item, dict): raise AuthoringError("Bundle asset must be an object")
        aid = identifier(item.get("id"), "asset.id")
        path = Path(text(item.get("path"), "asset.path")).resolve()
        if aid in ids or path in paths: raise AuthoringError("Repeated asset ID or path")
        ids.add(aid); paths.add(path)
        if item.get("role") not in ("source", "intermediate", "review", "source_and_review"):
            raise AuthoringError("Unknown asset role")
        if not isinstance(item.get("parents", []), list): raise AuthoringError("parents must be an ID list")
    graph = {item["id"]: item.get("parents", []) for item in assets}
    active, complete = set(), set()
    def visit(aid):
        if aid not in ids: raise AuthoringError("Missing source/intermediate parent; cropping cannot erase provenance")
        if aid in active: raise AuthoringError("Cyclic asset provenance")
        if aid in complete: return
        active.add(aid)
        for parent in graph[aid]: visit(identifier(parent, "parent ID"))
        active.remove(aid); complete.add(aid)
    for aid in ids: visit(aid)
    actual = []
    holds = []
    for item in assets:
        info = inspect_wav(item["path"])
        actual.append({**item, **info, "bytes": info["container_bytes"]})
        if item.get("rights_clearance") != "cleared" or not item.get("rights_evidence"):
            holds.append("output_rights_evidence_required:" + item["id"])
        if item["role"] in ("review", "source_and_review"):
            required = policy.get("review_format", {})
            if info["sample_rate"] > required.get("max_sample_rate", info["sample_rate"]) or any(info[k] != required.get(k, info[k]) for k in ("channels", "sample_width_bytes")):
                holds.append("review_format_outside_study_scope:" + item["id"])
        if item["role"] == "review" and not item.get("parents"):
            holds.append("derived_review_requires_source_parent:" + item["id"])
    budget = budget_totals(actual, policy)
    if not budget["within_budget"]: holds.append("study_budget_exceeded")
    if policy.get("adopted") is not True: holds.append("study_contract_not_adopted")
    return {"schema_version": 1, "assets": actual, "budget": budget, "holds": holds,
            "technical_audit_pass": not holds, "listening_acceptance": False, "integration_allowed": False}
