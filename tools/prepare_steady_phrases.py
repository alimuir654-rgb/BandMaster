#!/usr/bin/env python3
"""Derive two matched, private songwriting families; preserve all source WAVs."""
import argparse
import hashlib
import json
from pathlib import Path
import wave
import numpy as np

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--assessment-dir", type=Path, required=True)
args = parser.parse_args()
root = args.assessment_dir
data = json.loads((root / "measurements.json").read_text())
audio = {}
identities = {}
for f in data["files"]:
    path = root / "originals" / f["name"]
    assert hashlib.sha256(path.read_bytes()).hexdigest() == f["sha256"]
    identities[f["role"]] = {k: f[k] for k in ["id", "rev", "sha256"]}
    with wave.open(str(path), "rb") as w:
        assert (w.getframerate(), w.getnchannels(), w.getsampwidth()) == (48000, 2, 2)
        audio[f["role"]] = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").reshape(-1, 2).astype(np.float64) / 32768
kit = audio["Drums"] + audio["Percussion"]
kit_gain = min(1.0, 0.95 / max(float(np.abs(kit).max()), 1e-12))
base = Path(__file__).resolve().parents[1] / "Audio/Songwriting/SteadyHundred"
outputs = []
for family, start in [("Early", 230400), ("Later", 921600)]:
    out = base / family
    out.mkdir(parents=True, exist_ok=True)
    for role in ["guitar", "bass", "drums"]:
        raw = kit * kit_gain if role == "drums" else audio[role.title()]
        x = raw[start:start + 460800].copy()
        assert x.shape == (460800, 2)
        x[:480] *= np.linspace(0, 1, 480)[:, None]
        x[-960:] *= np.linspace(1, 0, 960)[:, None]
        assert np.max(np.abs(x)) < 1
        pcm = np.round(x * 32768).astype("<i2")
        name = role + "_0.wav"
        with wave.open(str(out / name), "wb") as w:
            w.setparams((2, 2, 48000, 0, "NONE", "not compressed"))
            w.writeframes(pcm.tobytes())
        (out / (name + ".import")).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
        outputs.append({"family":family, "role":role, "start_frame":start, "frame_count":460800,
                        "sha256":hashlib.sha256((out / name).read_bytes()).hexdigest()})
(base / "derivation-manifest.json").write_text(json.dumps({"source":"AI-generated Suno Steady Hundred",
    "status":"Two owner-reported styles; candidate cuts/combinations not listening-verified by assistant",
    "drums_include_matching_percussion":True, "drum_kit_gain":kit_gain,
    "fade_in_frames":480, "fade_out_frames":960, "source_identities":identities, "assets":outputs}, indent=2))
print("Prepared two matched 9.6-second families; originals unchanged. Drum kit gain:", kit_gain)
