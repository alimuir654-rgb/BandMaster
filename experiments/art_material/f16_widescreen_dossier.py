"""F16: 12:00 freeze-gate correction, reuse existing material, no new families.

The 1600x900 native C15 day screen showed a very tall mostly blank paper
dossier, and the night dossier clustered high against an empty lower bay.
Keep the C15 portraits, all six read-only meters, native controls and smaller
layouts unchanged. Only centre/cap the existing wide dossier as a deliberate
physical note card alongside the existing portrait stage.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
from PIL import Image

ROOT = Path(os.environ["ROOT"])
SCENE = ROOT / "scene/frame_demo.gd"
MANIFEST = ROOT / "F16_WIDE_DOSSIER_MANIFEST.json"


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def replace_once(s, old, new):
    assert s.count(old) == 1, ("F16 unique source anchor missing", old[:110], s.count(old))
    return s.replace(old, new, 1)


def install():
    mat = ROOT / "assets/material"
    meters_before = {p.name: sha(p) for p in mat.glob("passive_meter_*.png")}
    assert len(meters_before) >= 22, "Owner-liked passive meter kit missing"
    source_panels = []
    for theme in ("notepaper", "flightcase"):
        for family in ("dossier_shell", "portrait_stage"):
            path = mat / (family + "_" + theme + ".png")
            assert path.is_file(), path
            with Image.open(path) as im:
                dims = list(im.size)
            margin = 65 if family == "dossier_shell" else (36 if theme == "notepaper" else 42)
            source_panels.append({
                "path": str(path.relative_to(ROOT)),
                "sha256": sha(path),
                "dimensions": dims,
                "alpha": True,
                "nine_slice_margins_px": [margin] * 4,
                "safe_content_rect_px": [margin + 10, margin + 10, dims[0] - margin - 10, dims[1] - margin - 10],
                "states": "passive non-focus visual panel; input comes from separate native buttons",
                "source_rights_basis": "Existing F07 dossier and C08 portrait stage, source-backed owner-supplied image-generated Lab07 flightcase hardware / ambientCG CC0 Paper001; source manifests retained.",
                "owner_approved": False,
            })
    s = SCENE.read_text()
    anchor = '    heading.add_theme_font_size_override("font_size", 20 if narrow else 28)\n'
    change = '''    # F16: the wide desk now has one compact, vertically balanced native
    # paper/metal dossier beside the portrait. No new image or control family.
    # At smaller widths retain exactly the verified C15 placement.
    if size.x >= 1500:
        dossier_shell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        dossier_shell.custom_minimum_size.y = 468
    else:
        dossier_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
        dossier_shell.custom_minimum_size.y = 0
'''
    s = replace_once(s, anchor, change + anchor)
    SCENE.write_text(s)
    assert meters_before == {p.name: sha(p) for p in mat.glob("passive_meter_*.png")}, "Passive meter source mutation"
    MANIFEST.write_text(json.dumps({
        "kit": "F16 compact wide native dossier; no new asset family",
        "status": "native proof pending; not owner-approved",
        "owner_approved": False,
        "source_scene": "scene/frame_demo.gd",
        "source_art_change": False,
        "component_improvement": "1600x900 source-backed dossier shrinks to its 468px minimum and vertically centres; unchanged at 390x844, 720x1280 and 1280x720",
        "source_art_sources": source_panels,
        "read_only_meter_sha256": meters_before,
        "read_only_meter_semantics": "Six RAG bars retain mouse IGNORE and focus NONE, no regeneration",
        "canonical_portraits": "C15 512x690 original-size paired-origin previews remain provisional; no independently generated >=1024 masters",
        "target_viewports": [[390,844], [720,1280], [1280,720], [1600,900]],
    }, indent=2) + "\n")
    print("F16 installed 1600x900 compact dossier; panels reused; 23 meters unchanged")


def patch_test():
    path = ROOT / "tests/native_proof.gd"
    s = path.read_text()
    anchor = '            check(scene.portrait_stage.visible == (sz.x >= 900), "Portrait stage visibility " + prefix)\n'
    extra = '''            check(scene.dossier_shell.size_flags_vertical == Control.SIZE_SHRINK_CENTER if sz.x >= 1500 else scene.dossier_shell.size_flags_vertical == Control.SIZE_EXPAND_FILL, "F16 adaptive wide dossier sizing " + prefix)
            check(scene.dossier_shell.get_global_rect().size.y <= 555 if sz.x >= 1500 else true, "F16 too much empty widescreen dossier " + prefix)
            check(abs(scene.dossier_shell.get_global_rect().get_center().y - scene.portrait.get_global_rect().get_center().y) <= 145 if sz.x >= 1500 else true, "F16 dossier and portrait not balanced " + prefix)
            check(scene.dossier_shell.get_global_rect().end.y < scene.actions_bar.get_global_rect().position.y if sz.x >= 1500 else true, "F16 dossier collides with action rail " + prefix)
'''
    s = replace_once(s, anchor, anchor + extra)
    path.write_text(s)
    print("F16 native width, vertical balance, action separation assertions installed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", choices=("install", "patch-test"), required=True)
    options = parser.parse_args()
    install() if options.phase == "install" else patch_test()
