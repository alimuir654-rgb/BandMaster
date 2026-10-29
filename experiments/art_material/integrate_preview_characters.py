"""C05 source-preview import into the *isolated* verified dual-material Godot proof.

The 512x690 WebP files are derived from a two-person, portrait-only AI study.
They are distinct candidate preview inputs, NOT independently generated
>=1024px artist-approved masters. Source hashes and this limitation are retained.
No network, third-party licensed stock, production save or main-scene writes.
"""
from pathlib import Path
import argparse, hashlib, json, os, shutil

SOURCES = {
    "alex": "ce229cb5033aca0f1333c9930c24661874ab4b1be77962fd2ac41117c4cde17b",
    "nia_griffiths": "dd44205c4225e8ec4b0f8782237a15277fc7b1372549bd9b5d80581277b2ef12",
}

ROOT = Path(os.environ["ROOT"])
SRC = Path("experiments/art_material/portrait_preview")
DEST = ROOT / "assets/characters"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def install() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    records = []
    for person, expected in SOURCES.items():
        src = SRC / f"{person}_512x690.webp"
        assert src.is_file() and sha(src) == expected, f"Source missing/hash mismatch: {src}"
        dst = DEST / f"{person}_portrait_provisional_512.webp"
        shutil.copy2(src, dst)
        assert sha(dst) == expected
        records.append({
            "candidate_id": person, "path": str(dst.relative_to(ROOT)),
            "width": 512, "height": 690, "sha256": expected,
            "origin": "AI-generated paired portrait-only studio plate, split, downscaled for technical proof",
            "compliance": "PROVISIONAL. Not an independent one-subject high-resolution master.",
        })
    gd = ROOT / "scene/frame_demo.gd"
    s = gd.read_text()
    assert s.count("var portrait: PanelContainer") == 1
    s = s.replace("var portrait: PanelContainer", "var portrait: PanelContainer\nvar character_photo: TextureRect", 1)
    old = '    var room := TextureRect.new()\n    room.texture = load("res://assets/material/audition_room_%s.webp" % frame_material_kind)\n    room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n    room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED\n    room.mouse_filter = Control.MOUSE_FILTER_IGNORE\n    portrait.add_child(room)'
    new = '    character_photo = TextureRect.new()\n    character_photo.texture = load("res://assets/characters/alex_portrait_provisional_512.webp")\n    character_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n    character_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED\n    character_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE\n    portrait.add_child(character_photo)'
    assert s.count(old) == 1, "Room code changed; review source before installing portraits"
    s = s.replace(old, new, 1)
    choose = '    var candidate: Dictionary = CANDIDATES[index]\n    bio.text ='
    assert s.count(choose) == 1, "Candidate binding site changed"
    s = s.replace(choose,'    var candidate: Dictionary = CANDIDATES[index]\n    character_photo.texture = load("res://assets/characters/%s_portrait_provisional_512.webp" % candidate.id)\n    bio.text =',1)
    s = s.replace('caption.text = "AUDITION ROOM / ENVIRONMENT STUDY"',
                  'caption.text = "PROVISIONAL CHARACTER / PORTRAIT STUDY"')
    s = s.replace('status.text = "STUDY ONLY · NO MUSICIAN PORTRAIT"',
                  'status.text = "PORTRAIT STUDY · NOT OWNER-APPROVED"')
    gd.write_text(s)
    manifest = {
        "schema_version": 1,
        "kit": "C05 isolated candidate portrait PREVIEW integration",
        "source_criteria": "Two separate preview textures from a two-person portrait-only AI plate; source is NOT independent 1024px portrait generation",
        "generated_in_chat": "2026-10-29",
        "owner_approved": False,
        "visual_acceptance": "not_passed",
        "assets": records,
        "note": "These PREVIEWS measure native source-to-scene fidelity only. Full-resolution unscaled subject studies are preserved in conversation source pack, not these blobs."
    }
    (ROOT / "C05_PREVIEW_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("C05_STAGE", len(records), "distinct photo-preview assets; native binding installed")


def patch_test() -> None:
    p=ROOT / "tests/native_proof.gd"
    s=p.read_text()
    anchor='check(scene.CANDIDATES[0].id == "alex" and scene.CANDIDATES[1].id == "nia_griffiths", "Canonical identities")'
    assert s.count(anchor) == 1
    s=s.replace(anchor, anchor+'\n            check(scene.character_photo.texture.resource_path.contains("alex_portrait_provisional"), "Alex portrait binding "+prefix)\n            check(scene.character_photo.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Portrait receives mouse input "+prefix)',1)
    anchor='check(scene.details.text.contains("Nia Griffiths"), "Candidate signal " + prefix)'
    assert s.count(anchor) == 1
    s=s.replace(anchor,anchor+'\n            check(scene.character_photo.texture.resource_path.contains("nia_griffiths_portrait_provisional"), "Nia portrait binding "+prefix)',1)
    p.write_text(s)
    print("C05_TEST_PATCHED source-dependent candidate portrait-switch assertions")


if __name__ == "__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--phase", choices=["install","patch-test"], default="install")
    args=parser.parse_args()
    install() if args.phase=="install" else patch_test()
