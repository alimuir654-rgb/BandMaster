#!/usr/bin/env python3
"""Prepare private prototype phrase candidates; never alter the source WAVs."""
import argparse
import array
import csv
import hashlib
import json
from pathlib import Path
import sys
import wave

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--assessment-dir", type=Path, required=True)
args = parser.parse_args()
root = args.assessment_dir
out = Path(__file__).resolve().parents[1] / "Audio/Songwriting/Rehearsam"
with (root / "manifest.csv").open() as f:
    sources = {row["name"]: row for row in csv.DictReader(f)}
for name, info in sources.items():
    path = root / "originals" / name
    assert hashlib.sha256(path.read_bytes()).hexdigest() == info["sha256"], name
out.mkdir(parents=True, exist_ok=True)
frames = 455040
assets = []
for role in ["Guitar", "Bass", "Drums"]:
    name = "Rehearsam Loop (" + role + ").wav"
    source = root / "originals" / name
    for index, seconds in enumerate([12, 40.44, 68.88]):
        start = round(seconds * 48000)
        with wave.open(str(source), "rb") as w:
            assert (w.getnchannels(), w.getsampwidth(), w.getframerate()) == (2, 2, 48000)
            w.setpos(start)
            samples = array.array("h", w.readframes(frames))
        assert len(samples) == frames * 2
        if sys.byteorder != "little": samples.byteswap()
        for j in range(480):
            for channel in range(2):
                k = j * 2 + channel
                samples[k] = round(samples[k] * j / 479)
        for j in range(960):
            for channel in range(2):
                k = (frames - 960 + j) * 2 + channel
                samples[k] = round(samples[k] * (1 - j / 959))
        if sys.byteorder != "little": samples.byteswap()
        filename = role.lower() + "_" + str(index) + ".wav"
        with wave.open(str(out / filename), "wb") as w:
            w.setparams((2, 2, 48000, 0, "NONE", "not compressed"))
            w.writeframes(samples.tobytes())
        (out / (filename + ".import")).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
        assets.append({"file":filename, "start_frame":start, "frames":frames,
                       "source_sha256":sources[name]["sha256"],
                       "sha256":hashlib.sha256((out / filename).read_bytes()).hexdigest()})
(out / "derivation-manifest.json").write_text(json.dumps({"source":"AI-generated Suno Rehearsam Loop", "status":"Provisional four-bar candidates; bar phase/key and combinations require listening review", "duration":9.48, "assets":assets}, indent=2))
print("Prepared nine aligned candidates. Originals unchanged; no musical compatibility claim.")
