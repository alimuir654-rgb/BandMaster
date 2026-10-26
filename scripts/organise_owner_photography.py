#!/usr/bin/env python3
"""Convert owner-uploaded photography without claiming visual/legal approval."""
import hashlib
import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps
try:
    import pillow_avif  # noqa: F401
except ImportError:
    pass

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Art/Photography/source/review_inbox"
OUTPUT = ROOT / "Art/Photography/processed/review_inbox"
AUDIT = ROOT / "Art/Photography/owner_upload_audit.json"
SHEET = ROOT / "Art/Photography/owner_contact_sheet.jpg"
FORMATS = {".jpg", ".jpeg", ".png", ".webp", ".avif"}

def slugify(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")

def process():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    files = sorted(p for p in SOURCE.iterdir() if p.is_file() and p.suffix.lower() in FORMATS) if SOURCE.exists() else []
    if not files:
        raise SystemExit("No uploaded source images found: " + str(SOURCE))
    records = []
    thumbs = []
    for index, path in enumerate(files, 1):
        raw = path.read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        with Image.open(path) as original:
            original.load()
            image = ImageOps.exif_transpose(original).convert("RGB")
        if image.width < 640 or image.height < 360:
            raise ValueError("Image too small: " + str(path))
        label = slugify(path.stem)
        outputs = {}
        for variant, size in (("landscape", (1600, 900)), ("portrait", (900, 1400))):
            out = OUTPUT / (label + "_" + digest[:8] + "_" + variant + ".webp")
            if not out.exists():
                ImageOps.fit(image, size, method=Image.Resampling.LANCZOS).save(out, "WEBP", quality=82, method=5)
            with Image.open(out) as check:
                check.verify()
            outputs[variant] = str(out.relative_to(ROOT))
        thumb = ImageOps.fit(image, (290, 150), method=Image.Resampling.LANCZOS)
        thumbs.append((index, path.name, thumb))
        match = re.search(r"^(.*)-([A-Za-z0-9_-]{11})-unsplash", path.stem)
        source_url = "https://unsplash.com/photos/" + match.group(2) if match else ""
        photographer = match.group(1).replace("-", " ").title() if match else ""
        records.append({
            "index": index, "source": str(path.relative_to(ROOT)), "sha256": digest,
            "width": image.width, "height": image.height, "photographer_from_filename": photographer,
            "source_page_unverified": source_url,
            "scene_assignment": "unreviewed", "visual_review": "pending",
            "rights_review": "pending", "processed": outputs
        })
    columns = 5
    rows = (len(thumbs) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * 320, rows * 205), "#e7e7e7")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for i, name, thumb in thumbs:
        col = (i - 1) % columns
        row = (i - 1) // columns
        x, y = col * 320 + 15, row * 205 + 8
        sheet.paste(thumb, (x, y))
        draw.text((x, y + 155), f"{i:02d}  {name[:33]}", fill="#151515", font=font)
    sheet.save(SHEET, "JPEG", quality=67, optimize=True)
    AUDIT.write_text(json.dumps({"count": len(records), "note": "Not approved for shipping until visual and rights review; filenames are not scene evidence.", "assets": records}, indent=2) + "\n", encoding="utf-8")
    print("Processed", len(records), "owner images; contact sheet", SHEET.stat().st_size, "bytes")
    for r in records:
        print(f"{r['index']:02d} {r['source']} => {r['processed']['landscape']}")
    if SHEET.stat().st_size > 1_000_000:
        raise ValueError("Contact sheet exceeds GitHub image-inspection limit")

if __name__ == "__main__":
    process()
