"""C15: return to the more credible gritty portrait studies for the isolated proof.

The two 512x690 character images are distinct files derived from ONE
in-chat, portrait-only generated plate. They are NOT independently generated
1024px masters. Never enlarge person pixels, invent provenance or alter meters.
The independently sourced C11/C13 CC0 corporate originals remain archived.
"""
from pathlib import Path
from PIL import Image, ImageEnhance, ImageChops
import argparse, hashlib, json, math, os, random

ROOT = Path(os.environ["ROOT"])
DEST = ROOT / "assets/characters"
CAST = ("alex", "nia_griffiths")
SOURCE_SHA = {
    "alex": "ce229cb5033aca0f1333c9930c24661874ab4b1be77962fd2ac41117c4cde17b",
    "nia_griffiths": "dd44205c4225e8ec4b0f8782237a15277fc7b1372549bd9b5d80581277b2ef12",
}
SIZE = (512, 690)

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def once(text, old, new):
    count = text.count(old)
    assert count == 1, ("C15 expected one known source anchor", old[:100], count)
    return text.replace(old, new, 1)

def wash(size, color, side, strength):
    small = Image.new("L", (32, 44))
    px = small.load()
    for y in range(44):
        for x in range(32):
            dx = (x / 31.0 - (0.08 if side == "left" else 0.92)) / .68
            dy = (y / 43.0 - .16) / .75
            px[x, y] = round(strength * math.exp(-2.6 * (dx * dx + dy * dy)))
    layer = Image.new("RGBA", size, color + (0,))
    layer.putalpha(small.resize(size, Image.Resampling.BICUBIC))
    return layer

def finish(photo, person, kind):
    assert photo.size == SIZE, "Person pixels must remain at original 512x690"
    src = photo.convert("RGB")
    if kind == "night":
        src = ImageEnhance.Color(src).enhance(.68 if person == "alex" else .77)
        src = ImageEnhance.Contrast(src).enhance(1.11)
        src = ImageEnhance.Brightness(src).enhance(.90 if person == "alex" else .76)
        src = Image.blend(src, Image.new("RGB", SIZE, (15, 25, 34)), .10)
        warm, cool = (228, 127, 67, 39), (40, 104, 139, 27)
        edge_strength = 74
    else:
        src = ImageEnhance.Color(src).enhance(.91)
        src = ImageEnhance.Contrast(src).enhance(1.045)
        src = ImageEnhance.Brightness(src).enhance(1.045 if person == "alex" else .98)
        src = Image.blend(src, Image.new("RGB", SIZE, (235, 213, 178)), .055)
        warm, cool = (250, 198, 132, 26), (79, 116, 136, 15)
        edge_strength = 38
    result = src.convert("RGBA")
    result = Image.alpha_composite(result, wash(SIZE, warm[:3],
        "left" if person == "alex" else "right", warm[3]))
    result = Image.alpha_composite(result, wash(SIZE, cool[:3],
        "right" if person == "alex" else "left", cool[3]))
    shade = Image.new("L", (48, 64))
    px = shade.load()
    for y in range(64):
        for x in range(48):
            d = ((x / 47 - .5) / .68) ** 2 + ((y / 63 - .47) / .74) ** 2
            px[x, y] = round(min(1, max(0, (d - .20) * .85)) * edge_strength)
    overlay = Image.new("RGBA", SIZE, (9, 13, 17, 0))
    overlay.putalpha(shade.resize(SIZE, Image.Resampling.BICUBIC))
    result = Image.alpha_composite(result, overlay).convert("RGB")
    rng = random.Random((203 if person == "alex" else 719) +
                        (1000 if kind == "night" else 0))
    noise = Image.frombytes("L", SIZE, bytes(min(255, max(0, round(
        rng.gauss(127, 15)))) for _ in range(SIZE[0] * SIZE[1])))
    grain = Image.merge("RGB", (noise, noise, noise))
    return Image.blend(result, ImageChops.soft_light(result, grain), .11)

def install():
    originals = json.loads((ROOT / "C05_PREVIEW_MANIFEST.json").read_text())
    mapped = {x["candidate_id"]: x for x in originals["assets"]}
    records = []
    for cid in CAST:
        src = DEST / (cid + "_portrait_provisional_512.webp")
        assert src.exists() and sha(src) == SOURCE_SHA[cid] == mapped[cid]["sha256"], cid
        image = Image.open(src).convert("RGB")
        assert image.size == SIZE
        for kind in ("day", "night"):
            out = DEST / (cid + "_portrait_indie_" + kind + "_source512.webp")
            finish(image, cid, kind).save(out, "WEBP", quality=95, method=6)
            assert Image.open(out).size == SIZE
            records.append({
                "canonical_id": cid, "material": kind,
                "source": str(src.relative_to(ROOT)), "source_sha256": sha(src),
                "source_dimensions": list(SIZE), "output": str(out.relative_to(ROOT)),
                "output_sha256": sha(out), "dimensions": list(SIZE),
                "alpha": False, "crop_safe_px": [40, 28, 472, 648],
                "nine_slice_margins": None, "state": "passive portrait / not input",
                "no_subject_upscale": True,
                "transform": "Original-size photographic colour/exposure, directional ambient wash, vignette and subtle grain; no newly generated subject.",
                "source_basis": "C05 in-chat fictional paired-origin portrait-only plate, split into separately addressable 512x690 previews; NOT independent 1024px masters.",
                "rights": "Owner-authorised generated synthetic fictional-person study; no independently verified identity/model-release guarantee.",
                "owner_approved": False,
            })
    assert len({r["output_sha256"] for r in records}) == 4
    scene = ROOT / "scene/frame_demo.gd"
    s = scene.read_text()
    s = once(s,
        'var path := "res://assets/characters/%s_portrait_doc_%s_1024.webp" % [id, "day" if frame_material_kind == "notepaper" else "night"]',
        'var path := "res://assets/characters/%s_portrait_indie_%s_source512.webp" % [id, "day" if frame_material_kind == "notepaper" else "night"]')
    s = once(s, 'caption.text = "PROVISIONAL CHARACTER / PORTRAIT STUDY"',
        'caption.text = "FICTIONAL INDIE PHOTO STUDY / UNAPPROVED"')
    scene.write_text(s)
    meters = {p.name: sha(p) for p in
        (ROOT / "assets/material").glob("passive_meter_*.png")}
    assert len(meters) >= 22
    (ROOT / "C15_INDIE_SOURCE_MANIFEST.json").write_text(json.dumps({
        "kit": "C15: artistically stronger musician-looking original-size photos in two native scenes",
        "owner_approved": False,
        "art_verdict": "PARTIAL. Different indie-credible 512px images replace disliked 1024px corporate headshots; neither is an independent high-resolution master.",
        "actor_source_type": "synthetic paired-origin in-chat generated plate; NOT independent single-character photography",
        "archived_c11_c13": "Their independent 1024px synthetic CC0 source/license remains in original provenance manifests, not claimed as good indie art.",
        "passive_meter_baseline_sha256": meters,
        "passive_meter_semantics": "Six RAG read-only: mouse IGNORE, focus NONE; no changes.",
        "no_baked_ui_or_names": True, "no_character_pixels_enlarged": True,
        "viewport_targets": [[390, 844], [720, 1280], [1280, 720], [1600, 900]],
        "assets": records,
    }, indent=2) + "\n")
    assert meters == {p.name: sha(p) for p in
        (ROOT / "assets/material").glob("passive_meter_*.png")}
    print("C15_INSTALL", [(x["canonical_id"], x["material"],
        x["output_sha256"][:12]) for x in records])

def patch_test():
    p = ROOT / "tests/native_proof.gd"
    s = p.read_text()
    for cid in CAST:
        s = once(s, 'contains("' + cid + '_portrait_doc_")',
            'contains("' + cid + '_portrait_indie_")')
    s = once(s,
        'check(scene.character_photo.texture.get_width() >= 1024, "C11 portrait below source quality floor " + prefix)',
        'check(scene.character_photo.texture.get_width() == 512 and scene.character_photo.texture.get_height() == 690, "C15 original source pixel dimensions drift " + prefix)')
    s = once(s,
        'contains("_doc_day_1024") if kind == "notepaper" else scene.character_photo.texture.resource_path.contains("_doc_night_1024")',
        'contains("_indie_day_source512") if kind == "notepaper" else scene.character_photo.texture.resource_path.contains("_indie_night_source512")')
    s = once(s, '"C13 character grade mismatched material " + prefix',
                 '"C15 per-material indie preview mismatched " + prefix')
    p.write_text(s)
    print("C15_NATIVE_TEST source-specific Alex/Nia, 512x690 and day/night, unchanged interaction/meter checks")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", choices=("install", "patch-test"), required=True)
    a = parser.parse_args()
    install() if a.phase == "install" else patch_test()
