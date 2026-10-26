#!/usr/bin/env python3
"""Hard gate: real, unique owner-uploaded images must be present in the build."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = ROOT / "Art/Photography/SCENE_ASSIGNMENTS.json"
if not manifest.exists():
    raise SystemExit("Scene manifest missing")
data = json.loads(manifest.read_text(encoding="utf-8"))
scenes = data["scenes"]
required = {"spark","vibe","jam","songsheet","load_van","on_road","venue_arrival","soundcheck","backstage"}
assert required <= {scene["scene"] for scene in scenes}, "Journey photo coverage incomplete"
assert len(scenes) >= 14, "Whole-world photo coverage incomplete"
seen = set()
for item in scenes:
    original = ROOT / item["original"]
    assert original.is_file(), f"Missing original: {original}"
    assert hashlib.sha256(original.read_bytes()).hexdigest() == item["sha256"], f"Source changed: {original}"
    for ratio in ("wide","portrait"):
        target = ROOT / item["runtime"][ratio]
        assert target.is_file(), f"Missing runtime photo: {target}"
        content = target.read_bytes()
        assert len(content) > 20_000, f"Suspiciously small photo: {target}"
        assert content[:4] == b"RIFF" and content[8:12] == b"WEBP", f"Invalid WebP: {target}"
        digest = hashlib.sha256(content).hexdigest()
        assert digest not in seen, f"Duplicate scene photo: {target}"
        seen.add(digest)
assert all(isinstance(item.get("release_approved"), bool) for item in scenes), "Every scene needs explicit review status"
print(f"PASS: {len(scenes)} unique scenes, {len(seen)} real WebP variants, original hashes verified.")
if any(not item["release_approved"] for item in scenes):
    print("RELEASE HOLD: Visual crop and licensing/recognisable-person review still pending.")
