#!/usr/bin/env python3
"""License-sourced REAL photographic formation materials (never procedural/fake photo).
Inputs downloaded from their documented Pexels photo pages by guarded GitHub workflow.
The original JPEG remains only in temporary runner; resized quality WebP, manifest and
photographer provenance are committed under Art/Photography/Formation.
"""
from PIL import Image,ImageOps,ImageEnhance,ImageStat
from pathlib import Path
from hashlib import sha256
import json,sys

if len(sys.argv) != 3:
    raise SystemExit("Use: build_formation_photo_materials.py /tmp/cork.jpg /tmp/room.jpg")
output=Path("Art/Photography/Formation")
output.mkdir(parents=True,exist_ok=True)
sources=[
 ("corkboard_day_pexels.webp",Path(sys.argv[1]),"5988421","Eva Bronzini",
  "https://www.pexels.com/photo/a-close-up-shot-of-a-cork-board-5988421/","landscape"),
 ("daylight_music_room_pexels.webp",Path(sys.argv[2]),"20863659","Monica Escalera",
  "https://www.pexels.com/photo/a-room-with-musical-instruments-20863659/","room"),
]
records=[]
for name,src,pid,author,url,role in sources:
    assert src.is_file() and src.stat().st_size > 20000, "Photo download unavailable: "+str(src)
    with Image.open(src) as opened:
        raw=opened.convert("RGB")
    assert min(raw.size)>500, "Insufficient photographic source resolution"
    if role=="landscape":
        image=ImageOps.fit(raw,(1600,1200),method=Image.Resampling.LANCZOS,centering=(.5,.5))
        # Quiet photographic substrate: strong black charcoal-looking cork fissures
        # competed with player content. Restrained contrast and warm paper-toned
        # light bring actual fibre texture forward without synthetic speckle noise.
        image=ImageEnhance.Contrast(image).enhance(0.43)
        image=ImageEnhance.Brightness(image).enhance(1.12)
        image=ImageEnhance.Color(image).enhance(.72)
    else:
        # Daytime photo shows instruments and an actual window, not a dim orange room
        image=ImageOps.fit(raw,(1400,820),method=Image.Resampling.LANCZOS,centering=(.60,.53))
        image=ImageEnhance.Brightness(image).enhance(1.045)
    assert ImageStat.Stat(image).stddev[0]>12, "Photo lacks natural tonal variation"
    path=output/name
    image.save(path,format="WEBP",quality=88,method=6)
    records.append({
        "asset":str(path), "source_photo_id":pid, "photographer":author,
        "source_page":url, "license":"Pexels Free License - subject to source terms",
        "downloaded_jpeg_sha256":sha256(src.read_bytes()).hexdigest(),
        "committed_webp_sha256":sha256(path.read_bytes()).hexdigest(),
        "source_original_dimensions":raw.size, "asset_dimensions":image.size,
        "alterations":"ImageOps.fit and restrained exposure/colour treatment; native gameplay text layered separately"
    })
manifest=output/"SOURCE_PHOTO_MANIFEST.json"
manifest.write_text(json.dumps({"source_type":"real photographs, not AI/generated",
"license_page":"https://www.pexels.com/license/","records":records},indent=2)+"\n",encoding="utf-8")
print("PASS: Two real licensed material WebPs prepared with photographers and SHA provenance")
