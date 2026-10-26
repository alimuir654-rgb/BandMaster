#!/usr/bin/env python3
"""Fetch reviewed Unsplash Free photo pages into real, cropped Godot-ready WebP assets.

Fails closed: no fallback illustrations, AI images or 'success' on absent binaries.
"""
import argparse
import hashlib
import html
import json
import re
from io import BytesIO
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Art" / "Photography" / "approved"
CATALOGUE = ROOT / "Art" / "Photography" / "photo_sources.json"
UA = "Mozilla/5.0 (compatible; LivingTheDreamAssetIntake/1.0)"


def download(url, limit=18_000_000):
    req = Request(url, headers={"User-Agent": UA, "Accept": "text/html,image/*"})
    with urlopen(req, timeout=30) as response:
        content = response.read(limit + 1)
    if not content or len(content) > limit:
        raise ValueError("Asset empty or exceeds download limit")
    return content


def resolve_image(page_url):
    parts = urlparse(page_url)
    if parts.scheme != "https" or parts.netloc != "unsplash.com" or not parts.path.startswith("/photos/"):
        raise ValueError("Expected HTTPS individual Unsplash photo page")
    page = download(page_url, 2_000_000).decode("utf-8", "replace")
    # Photo pages distinguish Free / Unsplash+; never silently import paid content.
    if "Unsplash+ License" in page and "Free to use under the Unsplash License" not in page:
        raise ValueError("Paid or unclear Unsplash+ license")
    if "unsplash license" not in page.lower():
        raise ValueError("No detectable license text on photo page; manual review required")
    tags = re.findall(r"<meta\\b[^>]*>", page, flags=re.IGNORECASE)
    image_url = None
    for tag in tags:
        if not re.search(r"property=[\\\"']og:image[\\\"']", tag, flags=re.IGNORECASE):
            continue
        found = re.search(r"content=[\\\"']([^\\\"']+)", tag, flags=re.IGNORECASE)
        if found:
            image_url = html.unescape(found.group(1))
            break
    if not image_url:
        raise ValueError("Photo page lacks og:image; no fallback to unknown asset")
    if urlparse(image_url).netloc not in ("images.unsplash.com", "plus.unsplash.com"):
        raise ValueError("Unexpected image source host")
    return image_url


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    from PIL import Image, ImageOps, ImageEnhance
    entries = json.loads(CATALOGUE.read_text(encoding="utf-8"))
    audit = []
    for item in entries:
        if item.get("approval") != "curated_free_candidate":
            continue
        slug = item["id"]
        if not re.fullmatch(r"[a-z0-9_-]+", slug):
            raise ValueError("Invalid asset ID")
        image_url = resolve_image(item["photo_page"])
        data = download(image_url)
        image = Image.open(BytesIO(data))
        image.verify()
        image = Image.open(BytesIO(data)).convert("RGB")
        if min(image.size) < 700:
            raise ValueError(slug + " has insufficient resolution")
        produced = []
        for label, size in (("wide", (1600, 900)), ("portrait", (900, 1400))):
            target = ASSETS / (slug + "_" + label + ".webp")
            if not args.verify_only:
                ASSETS.mkdir(parents=True, exist_ok=True)
                crop = ImageOps.fit(image, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
                crop.save(target, format="WEBP", quality=83, method=5)
            if not args.verify_only:
                with Image.open(target) as check:
                    assert check.size == size and check.format == "WEBP"
                produced.append({"path": str(target.relative_to(ROOT)), "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})
        audit.append({"id": slug, "photographer": item["photographer"], "photo_page": item["photo_page"], "source_sha256": hashlib.sha256(data).hexdigest(), "outputs": produced, "manual_visual_clearance": False})
        print("VERIFIED", slug, image.size, len(data))
    if not args.verify_only:
        (ASSETS / "intake_audit.json").write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
    if not audit:
        raise RuntimeError("No free photo candidates processed")
    print("PHOTO INTAKE PASSED", len(audit), "manual visual/legal clearance still required")


if __name__ == "__main__":
    main()
