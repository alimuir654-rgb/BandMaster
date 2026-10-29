"""C05 character-source adapter: provisional paired-studio portrait plates only.

This deliberately does not call itself an individual-portrait generation master.
It can stage independently addressable fictional character textures into an isolated
Godot project from a *supplied* portrait-only plate; it does not source artwork
from screen mockups, real identifiable stock models, or legacy 160px portraits.
Requires Pillow (already in the established art CI environment).
No production saves, no production scene edits, no network or paid dependency.
"""
from pathlib import Path
import argparse, hashlib, json

from PIL import Image, ImageFilter


CROPS = {
    "alex": (0, 0, 760, 1024),
    "nia_griffiths": (775, 0, 1536, 1024),
}
SOURCE_BOUND = (1536, 1024)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stage(source: Path, project: Path) -> dict:
    if not source.is_file():
        raise FileNotFoundError(f"C05 original portrait-only plate absent: {source}")
    if not (project / "scene/frame_demo.gd").is_file():
        raise FileNotFoundError("Expected isolated frame_demo.gd project; no production-project patching")
    photo = Image.open(source).convert("RGB")
    if photo.size != SOURCE_BOUND:
        raise ValueError(f"Expected {SOURCE_BOUND} portrait-only plate, got {photo.size}")
    out = project / "assets/characters"
    out.mkdir(parents=True, exist_ok=True)
    records = []
    for identity, bounds in CROPS.items():
        cropped = photo.crop(bounds)
        # Extend background only; original subject pixels stay unscaled.
        padded = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
        padded = padded.filter(ImageFilter.GaussianBlur(75))
        left = (1024 - cropped.width) // 2
        padded.paste(cropped, (left, 0))
        portrait_path = out / f"{identity}_portrait_provisional_1024.webp"
        padded.save(portrait_path, "WEBP", quality=92, method=6)
        crop_path = out / f"{identity}_subject_original_{cropped.width}x1024.webp"
        cropped.save(crop_path, "WEBP", quality=94, method=6)
        source_square = cropped.crop((0, 130, cropped.width, cropped.width + 130))
        thumb_path = out / f"{identity}_thumb_384.webp"
        source_square.resize((384, 384), Image.Resampling.LANCZOS).save(thumb_path, "WEBP", quality=88, method=6)
        records.append({
            "id": identity,
            "status": "PROVISIONAL_NOT_INDEPENDENT_SOURCE_MASTER",
            "source_bounds": list(bounds),
            "original_source_detail": [cropped.width, cropped.height],
            "portrait_canvas": [1024, 1024],
            "background_extended_without_subject_upscaling": True,
            "full": str(portrait_path.relative_to(project)),
            "full_sha256": sha256(portrait_path),
            "source_crop": str(crop_path.relative_to(project)),
            "source_crop_sha256": sha256(crop_path),
            "thumbnail": str(thumb_path.relative_to(project)),
            "thumbnail_sha256": sha256(thumb_path),
        })
    assert records[0]["full_sha256"] != records[1]["full_sha256"]

    gd = project / "scene/frame_demo.gd"
    text = gd.read_text()
    if "var character_photo: TextureRect" not in text:
        expected = '    var room := TextureRect.new()\n    room.texture = load("res://assets/material/audition_room_%s.webp" % frame_material_kind)\n    room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n    room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED\n    room.mouse_filter = Control.MOUSE_FILTER_IGNORE\n    portrait.add_child(room)'
        replacement = '    character_photo = TextureRect.new()\n    character_photo.texture = load("res://assets/characters/alex_portrait_provisional_1024.webp")\n    character_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n    character_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED\n    character_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE\n    portrait.add_child(character_photo)'
        assert text.count(expected) == 1, "Portrait scene insertion point drifted; review native source"
        text = text.replace("var portrait: PanelContainer", "var portrait: PanelContainer\nvar character_photo: TextureRect\nvar photo_caption: Label", 1)
        text = text.replace(expected, replacement, 1)
        cap = '    var caption := Label.new()\n    caption.text = "AUDITION ROOM / ENVIRONMENT STUDY"'
        assert text.count(cap) == 1
        text = text.replace(cap, '    photo_caption = Label.new()\n    var caption := photo_caption\n    caption.text = "PROVISIONAL FICTIONAL CHARACTER ART"', 1)
        select = '    var candidate: Dictionary = CANDIDATES[index]\n    bio.text ='
        assert text.count(select) == 1
        text = text.replace(select, '    var candidate: Dictionary = CANDIDATES[index]\n    character_photo.texture = load("res://assets/characters/%s_portrait_provisional_1024.webp" % candidate.id)\n    photo_caption.text = "%s / PROVISIONAL GENERATED ART" % candidate.name\n    bio.text =', 1)
        text = text.replace('status.text = "STUDY ONLY · NO MUSICIAN PORTRAIT"', 'status.text = "PROVISIONAL CHARACTER ART · NOT OWNER-APPROVED"')
        gd.write_text(text)
    assert 'character_photo.texture = load("res://assets/characters/%s_portrait_provisional_1024.webp" % candidate.id)' in gd.read_text()
    manifest = {
        "schema_version": 1,
        "source": str(source.name),
        "source_sha256": sha256(source),
        "source_type": "in-chat AI-generated TWO-subject studio portrait-only plate; NOT UI composite",
        "source_dimensions": list(photo.size),
        "characters": records,
        "owner_approved": False,
        "art_status": "PARTIAL, NOT MASTER",
        "limitations": [
            "One subject per original generation was requested; the tool produced two people. Do not call these independently generated source masters.",
            "No musician identity inference: both are fictional role studies, not representations of identified real people.",
            "Native Godot screenshots required after actual bytes have been imported by CI."
        ],
    }
    (project / "C05_PORTRAIT_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()
    result = stage(args.source, args.project)
    print("C05_SOURCE_STAGED:", ", ".join(x["id"] for x in result["characters"]), "owner_approved=false")
