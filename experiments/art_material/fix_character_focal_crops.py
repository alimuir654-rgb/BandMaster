"""C06 aspect-safe provisional portraits; not independently generated art masters.

Derives landscape aspect plates from C05's two distinct candidate previews.
Subject pixels stay at their original 512-pixel resolution; only the blurred
surrounding material is resized. The paired-source origin remains provisional.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(os.environ["ROOT"])
IDS = ("alex", "nia_griffiths")
SIZE = (1536, 430)
ORIGINAL = (512, 690)

def checksum(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def landscape(src):
    with Image.open(src) as inp:
        photo = inp.convert("RGB")
    assert photo.size == ORIGINAL, f"Source resolution drift: {photo.size}"
    bg = ImageOps.fit(photo, SIZE, Image.Resampling.LANCZOS,
                      centering=(0.5, 0.30)).filter(ImageFilter.GaussianBlur(65))
    bg = ImageEnhance.Brightness(bg).enhance(0.57)
    person = photo.crop((0, 0, 512, 430))  # NO RESAMPLING OF THE PERSON
    mask = Image.new("L", person.size, 255)
    for x in range(512):
        strength = min(255, x * 255 // 28, (511-x) * 255 // 28)
        if strength < 255:
            mask.paste(strength, (x, 0, x+1, 430))
    bg.paste(person, (512, 0), mask)
    return bg

def install():
    dest = ROOT / "assets/characters"
    assert dest.is_dir(), "C05 source preview directory not found"
    previous = json.loads((ROOT / "C05_PREVIEW_MANIFEST.json").read_text())
    originals = {entry["candidate_id"]: entry["sha256"] for entry in previous["assets"]}
    records = []
    for identity in IDS:
        src = dest / f"{identity}_portrait_provisional_512.webp"
        assert src.is_file() and checksum(src) == originals[identity]
        dst = dest / f"{identity}_portrait_landscape_focalsafe_1536x430.webp"
        landscape(src).save(dst, "WEBP", quality=93, method=6)
        records.append({
            "candidate_id": identity, "source": str(src.relative_to(ROOT)),
            "source_sha256": checksum(src), "source_dimensions": list(ORIGINAL),
            "landscape": str(dst.relative_to(ROOT)), "landscape_sha256": checksum(dst),
            "landscape_dimensions": list(SIZE),
            "person_original_resolution_retained": True,
            "face_safe_region": [512, 0, 1024, 430],
            "origin": "Two-person generated portrait-only plate, cropped/downscaled as C05 PREVIEW; NOT independently generated 1024px master."
        })
    script = ROOT / "scene/frame_demo.gd"
    text = script.read_text()
    old = '    character_photo.texture = load("res://assets/characters/%s_portrait_provisional_512.webp" % candidate.id)'
    assert text.count(old) == 1, "Unexpected C05 candidate binding"
    text = text.replace(old, '    _choose_character_texture()', 1)
    old = '    _apply_meter_sizes()\n\nfunc _select_role'
    assert text.count(old) == 1, "Unexpected responsive layout"
    text = text.replace(old, '    _apply_meter_sizes()\n    _choose_character_texture()\n\nfunc _select_role', 1)
    text += '''

# C06: aspect-aware focal-safe portrait selection; source remains provisional.
func _choose_character_texture() -> void:
    if character_photo == null or CANDIDATES.is_empty():
        return
    var id: String = CANDIDATES[selected].id
    var path := "res://assets/characters/%s_portrait_provisional_512.webp" % id
    if size.x >= 900:
        path = "res://assets/characters/%s_portrait_landscape_focalsafe_1536x430.webp" % id
    character_photo.texture = load(path)
    character_photo.set_meta("focalsafe_source", path)
'''
    script.write_text(text)
    (ROOT / "C06_FOCALSAFE_MANIFEST.json").write_text(json.dumps({
        "schema_version": 1, "owner_approved": False, "art_gate": "PARTIAL",
        "technique": "Person pixels never upsampled; blurred background extended for >=900px native layouts",
        "source_criteria": previous["source_criteria"],
        "not_a_master": "Originals are 512px-wide previews of one generated two-subject plate; this changes crop/composition, not portrait source quality.",
        "assets": records
    }, indent=2) + "\n")
    print("C06_FACE_SAFE_ASSETS", [(r["candidate_id"],r["landscape_sha256"][:12]) for r in records])

def patch_test():
    script = ROOT / "tests/native_proof.gd"
    text = script.read_text()
    for name in IDS:
        old = f'scene.character_photo.texture.resource_path.contains("{name}_portrait_provisional")'
        new = f'(scene.character_photo.texture.resource_path.contains("{name}_portrait_landscape_focalsafe") if sz.x >= 900 else scene.character_photo.texture.resource_path.contains("{name}_portrait_provisional"))'
        assert text.count(old) == 1, f"Missing existing C05 test: {name}"
        text = text.replace(old, new, 1)
    anchor = 'check(scene.body.vertical == (window.size.x < 900), "Live resize " + prefix)'
    assert text.count(anchor) == 1
    text = text.replace(anchor, anchor+'\n            check(scene.character_photo.texture.resource_path.contains("portrait_landscape_focalsafe") == (window.size.x >= 900), "Wrong portrait source after live resize " + prefix)', 1)
    script.write_text(text)
    print("C06_PROOF_ASSERTIONS_INSTALLED")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", choices=("install", "patch-test"), required=True)
    args = parser.parse_args()
    install() if args.phase == "install" else patch_test()
