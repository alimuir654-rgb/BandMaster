#!/usr/bin/env python3
"""Fail scene-sprint quality job if its documented preflight or review record is missing."""
from pathlib import Path
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--sprint", default="S01")
args = parser.parse_args()
doc = Path("docs/SCENE_SWEEP_SPRINT_LEDGER.md")
review = Path("docs/SCENE_SWEEP_LESSONS_AND_PERSONAS.md")
quality = Path("docs/LIVIN_THE_DREAM_SCENE_QUALITY_GATES_AND_SWEEP.md")
for f in (doc, review, quality):
    assert f.is_file(), f"Missing mandatory preflight reference: {f}"
ledger, lessons, gate = (f.read_text(encoding="utf-8") for f in (doc, review, quality))
assert f"PRE-FLIGHT {args.sprint}" in ledger, "Write and inspect sprint preflight before editing the scene"
assert "PRE-FLIGHT: PASS" in ledger, "No specific preflight PASS recorded"
assert "simulated" in lessons.lower() and all(x in lessons.lower() for x in (
    "player", "musician", "accessibility", "godot", "art"
)), "Five genuine simulated persona review lenses missing"
assert "Livin" in gate, "Missing owner direction / player-facing name"
assert all(s in ledger for s in ("S02", "S03", "S04", "S05", "S06", "S07")), "Scene sweep sprint plan missing"
print(f"PASS: {args.sprint} preflight, owner quality source and five persona lenses are present")
