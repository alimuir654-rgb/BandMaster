#!/usr/bin/env python3
"""Derive local, ignored review excerpts from hash-verified owner originals."""
import argparse
import array
import csv
import hashlib
import json
from pathlib import Path
import sys
import wave

START = 3_393_600
END = 4_320_000
RATE = 48_000
FADE_IN = 480
FADE_OUT = 960
SOURCES = {
    "guitar": "Last Bus Gone (Guitar).wav",
    "bass": "Last Bus Gone (Bass).wav",
    "drums": "Last Bus Gone (Drums).wav",
    "vocals": "Last Bus Gone (Vocals).wav",
    "reference": "Last Bus Gone.wav",
}


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while block := source.read(4 * 1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def prepare(assessment, project):
    with (assessment / "manifest.csv").open(newline="") as source:
        records = {row["name"]: row for row in csv.DictReader(source)}
    # Verify all six files before writing any derived assets.
    for name, record in records.items():
        path = assessment / "originals" / name
        if path.stat().st_size != int(record["size"]) or sha256(path) != record["sha256"]:
            raise ValueError("Original size/hash mismatch: " + name)
    for name in SOURCES.values():
        if name not in records:
            raise ValueError("Missing original identity: " + name)
    output = project / "Audio/Review/LastBusGone"
    output.mkdir(parents=True, exist_ok=True)
    assets = []
    for role, name in SOURCES.items():
        with wave.open(str(assessment / "originals" / name), "rb") as source:
            if (source.getnchannels(), source.getsampwidth(), source.getframerate(), source.getnframes()) != (2, 2, RATE, 8_503_680):
                raise ValueError("Unexpected source encoding/length: " + name)
            source.setpos(START)
            samples = array.array("h", source.readframes(END - START))
        if sys.byteorder != "little":
            samples.byteswap()
        for frame in range(FADE_IN):
            gain = frame / (FADE_IN - 1)
            for channel in range(2):
                offset = frame * 2 + channel
                samples[offset] = round(samples[offset] * gain)
        for offset in range(FADE_OUT):
            frame = END - START - FADE_OUT + offset
            gain = 1.0 - offset / (FADE_OUT - 1)
            for channel in range(2):
                index = frame * 2 + channel
                samples[index] = round(samples[index] * gain)
        assert samples[:2] == array.array("h", [0, 0])
        assert samples[-2:] == array.array("h", [0, 0])
        if sys.byteorder != "little":
            samples.byteswap()
        path = output / (role + ".wav")
        with wave.open(str(path), "wb") as target:
            target.setnchannels(2)
            target.setsampwidth(2)
            target.setframerate(RATE)
            target.writeframes(samples.tobytes())
        assets.append({"role": role, "file": path.name, "sha256": sha256(path),
                       "original_name": name, "original_sha256": records[name]["sha256"],
                       "dropbox_id": records[name]["id"], "dropbox_revision": records[name]["rev"]})
        # Preserve every aligned frame and its source rate on Godot import.
        (output / (role + ".wav.import")).write_text(
            '[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n\n[params]\n'
            'force/8_bit=false\nforce/mono=false\nforce/max_rate=false\n'
            'edit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n'
        )
    manifest = {"title": "Last Bus Gone", "usage": "Private owner review, not shipping authorization",
                "provenance": "AI-generated Suno audio; owner reports exact version generated/downloaded on paid plan",
                "start_frame": START, "end_frame_exclusive": END, "frame_count": END - START,
                "sample_rate_hz": RATE, "channels": 2, "bits_per_sample": 16,
                "fade_in_frames": FADE_IN, "fade_out_frames": FADE_OUT,
                "fade_curve": "linear amplitude, exact zero endpoints", "loop": False, "assets": assets}
    (output / "derivation-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Prepared five aligned, faded 19.3-second review WAVs in " + str(output))
    print("Originals unchanged. Review audio is ignored by Git and excluded from the normal Android export.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assessment-dir", type=Path, required=True)
    parser.add_argument("--project-dir", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    prepare(args.assessment_dir.resolve(), args.project_dir.resolve())
