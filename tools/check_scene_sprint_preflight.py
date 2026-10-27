#!/usr/bin/env python3
"""Verify sprint-specific preflight evidence; not merely existence of a generic log."""
import argparse
from pathlib import Path
import re

parser = argparse.ArgumentParser()
parser.add_argument("--sprint", default="S01")
args = parser.parse_args()
sprint = args.sprint.upper()
allowed = [f"S{i:02d}" for i in range(1, 8)] + ["S02B"]
assert sprint in allowed, f"Specify one of {allowed}"

paths = {
    "ledger": Path("docs/SCENE_SWEEP_SPRINT_LEDGER.md"),
    "review": Path("docs/SCENE_SWEEP_LESSONS_AND_PERSONAS.md"),
    "quality": Path("docs/LIVIN_THE_DREAM_SCENE_QUALITY_GATES_AND_SWEEP.md"),
    "protocol": Path("docs/SCENE_SWEEP_SPRINT_OPERATING_PROTOCOL.md"),
}
for label, path in paths.items():
    assert path.is_file(), f"Missing mandatory {label}: {path}"
docs = {name: path.read_text(encoding="utf-8") for name, path in paths.items()}
ledger = docs["ledger"]
review = docs["review"]
assert "Livin" in docs["quality"], "Missing player-facing branding contract"
assert all(word in review.lower() for word in ("player", "musician", "art", "accessibility", "godot", "simulated")), (
    "Five simulated persona lenses must remain available")
assert "before" in docs["protocol"].lower() and "POST-RUN" in docs["protocol"], (
    "Latest owner sprint operating protocol must be present")

matches = list(re.finditer(
    rf"(?im)^#{{2,4}}\s+PRE-FLIGHT\s+{re.escape(sprint)}\b[^\n]*\n",
    ledger,
))
assert matches, f"No sprint-specific PRE-FLIGHT {sprint}; inspect prior findings and record it before coding"
start = matches[-1].end()
after = ledger[start:]
next_section = re.search(r"(?m)^#{2,4}\s+\S", after)
section = after[:next_section.start()] if next_section else after
assert len(section.strip()) >= 240, f"PRE-FLIGHT {sprint} lacks substantive observed evidence"
assert "PRE-FLIGHT: PASS" in section, f"PRE-FLIGHT {sprint} not explicitly approved to implement"

if sprint != "S01":
    # New sprints must provide concrete evidence and personae in their OWN preflight section.
    required = ["Evidence inspected:", "Lessons carried:", "Persona warnings:", "Planned slice:"]
    for item in required:
        assert item.lower() in section.lower(), (
            f"PRE-FLIGHT {sprint} missing '{item}' — use the documented sprint template")
    for persona in ("player", "musician", "art", "accessibility", "godot"):
        assert persona in section.lower(), (
            f"PRE-FLIGHT {sprint} omitted actionable {persona} concerns")
    assert any(token in section.lower() for token in ("ci", "workflow", "artifact", "test")), (
        f"PRE-FLIGHT {sprint} missing concrete prior test/CI evidence")
    previous = "S02" if sprint == "S02B" else f"S{int(sprint[1:])-1:02d}"
    assert f"POST-RUN {previous}" in ledger, (
        f"Cannot start {sprint} without previous {previous} post-run handoff")
    assert f"POST-RUN {previous}" in review, (
        f"Cannot start {sprint} without prior persona findings in review log")

print(f"PASS: {sprint} inspected preflight evidence, prior lessons, owner quality contract and persona protocol")
