#!/usr/bin/env python3
"""Reject a regression to default/flat V3 helper UI in new V4.
Never mutate files. This is a style-architecture gate, not an art-quality approval.
"""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
SCENE=ROOT/"poc/ldtd_recruitment_v4.gd"
ASSETS=ROOT/"Art/UI/RecruitmentV4"
text=SCENE.read_text(encoding="utf-8")
for name,pattern in {
    "legacy helper":r'ui_theme|WoldButton|UI\.button|_button\(',
    "flat StyleBox":r'StyleBoxFlat|ColorRect\.new|\.add_theme_stylebox_override\(',
    "unapproved scene background":r'poc/ldtd_recruitment_v3\.(?:tscn|gd)',
    "unapproved live save":r'FileAccess|user://|DirAccess|tour_save',
}.items():
    assert not re.search(pattern,text),f"V4 art contract FAIL: {name}"
for path in ["case_roadcase.svg","paper_personnel.svg"]:
    f=ASSETS/path
    assert f.is_file() and f.stat().st_size>=1000,path
for family in ["metal_tab","amber_key"]:
    for state in ["idle","hover","pressed","selected","disabled"]:
        path=ASSETS/f"{family}_{state}.svg"
        assert path.is_file() and "<svg" in path.read_text(),str(path)
assert 'bandmaster_premium_controls_lab/assets/transport_studio_' in text,"Real Lab07 required"
assert 'ldtd_recruitment_meter.gd' in text, "Six inert red/amber/green meters required"
assert 'BarlowCondensed-SemiBold.ttf' in text and 'IBMPlexSans-Variable.ttf' in text
assert 'TextureButton' in text and 'texture_normal' in text and 'texture_disabled' in text
assert 'portrait' in text and 'paper_personnel.svg' in text and 'case_roadcase.svg' in text
print("LDTD V4 ART CONTRACT LINT PASS: No flat/legacy GUI or writes, 12 source-backed design assets and hardware states.")
