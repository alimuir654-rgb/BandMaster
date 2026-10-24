#!/usr/bin/env python3
"""Dependency-free structural checks; does not claim to compile GDScript."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
required = [
    "project.godot",
    "band_builder.tscn",
    "main_menu.tscn",
    "tour_intro.tscn",
    "Scripts/band_builder.gd",
    "Scripts/main_menu.gd",
    "Scripts/tour_intro.gd",
]
errors = []
for name in required:
    if not (ROOT / name).is_file():
        errors.append(f"Missing required file: {name}")

scene_uid = re.compile(r'run/main_scene\s*=\s*"uid://([^"]+)"')
scene_header_uid = re.compile(r'\[gd_scene[^\n]*\buid="uid://([^"]+)"')
resource_paths = re.compile(r'path="res://([^"]+)"')

project = ROOT / "project.godot"
if project.is_file():
    match = scene_uid.search(project.read_text(encoding="utf-8"))
    if match:
        found = any(
            scene_header_uid.search(scene.read_text(encoding="utf-8"))
            and scene_header_uid.search(scene.read_text(encoding="utf-8")).group(1) == match.group(1)
            for scene in ROOT.rglob("*.tscn")
        )
        if not found:
            errors.append(f"Main scene UID uid://{match.group(1)} not declared in any .tscn")
    elif "run/main_scene" not in project.read_text(encoding="utf-8"):
        errors.append("project.godot does not define run/main_scene")

for scene in ROOT.rglob("*.tscn"):
    for resource in resource_paths.findall(scene.read_text(encoding="utf-8")):
        if not (ROOT / resource).is_file():
            errors.append(f"{scene.relative_to(ROOT)} references missing res://{resource}")

if errors:
    for issue in errors:
        print(f"ERROR: {issue}", file=sys.stderr)
    sys.exit(1)

print("PASS: required files, main scene UID and scene resource paths are valid.")
print("NOTE: This is not a Godot parse, import or gameplay regression test.")
