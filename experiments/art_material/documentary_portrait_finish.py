"""C13: separate CC0 synthetic 1024px faces, two in-world photographic darkroom finishes.
An editorial treatment of existing images, NOT new musician portraits or a collage.
"""
import argparse, hashlib, json, math, os, random
from pathlib import Path
from PIL import Image, ImageOps, ImageEnhance, ImageChops
ROOT=Path(os.environ["ROOT"])
CAST=("alex","nia_griffiths")
SIZE=(1024,1024)
def sha(data): return hashlib.sha256(data).hexdigest()
def radial(cx,cy,rx,ry,strength):
    small=Image.new("L",(48,48));p=small.load()
    for y in range(48):
        for x in range(48):
            d=((x/47-cx)/rx)**2+((y/47-cy)/ry)**2
            p[x,y]=max(0,min(255,int(strength*math.exp(-2.7*d))))
    return small.resize(SIZE,Image.Resampling.BICUBIC)
def grade(photo,cid,kind):
    assert photo.size==SIZE
    gray=ImageOps.grayscale(photo.convert("RGB"))
    if kind=="night":
        gray=ImageEnhance.Contrast(gray).enhance(1.24)
        toned=ImageOps.colorize(gray,black=(6,11,17),white=(228,218,199))
        result=Image.blend(photo.convert("RGB"),toned,.80)
        result=ImageEnhance.Brightness(result).enhance(.93)
        glow=(242,115,43);beam=49
    else:
        gray=ImageEnhance.Contrast(gray).enhance(1.14)
        toned=ImageOps.colorize(gray,black=(27,27,25),white=(232,212,180))
        result=Image.blend(photo.convert("RGB"),toned,.52)
        result=ImageEnhance.Brightness(result).enhance(.97)
        glow=(230,170,94);beam=27
    result=result.convert("RGBA")
    warm=Image.new("RGBA",SIZE,glow+(0,))
    warm.putalpha(radial(.12 if cid=="alex" else .90,.22,.46,.45,beam))
    result=Image.alpha_composite(result,warm)
    cool=Image.new("RGBA",SIZE,(33,81,120,0))
    cool.putalpha(radial(.90 if cid=="alex" else .12,.65,.46,.70,25 if kind=="night" else 13))
    result=Image.alpha_composite(result,cool)
    edge=Image.new("L",(48,48));p=edge.load()
    for y in range(48):
        for x in range(48):
            r=math.sqrt(((x/47-.5)/.74)**2+((y/47-.48)/.78)**2)
            p[x,y]=max(0,min(255,int(88*max(0,r-.38)**1.3)))
    sh=Image.new("RGBA",SIZE,(2,7,11,0))
    sh.putalpha(edge.resize(SIZE,Image.Resampling.BICUBIC))
    result=Image.alpha_composite(result,sh).convert("RGB")
    rng=random.Random((41 if cid=="alex" else 79)+(100 if kind=="night" else 0))
    pixels=bytes(min(255,max(0,int(rng.gauss(128,19)))) for _ in range(1024*1024))
    grain=Image.frombytes("L",SIZE,pixels)
    texture=Image.merge("RGB",(grain,grain,grain))
    return Image.blend(result,ImageChops.soft_light(result,texture),.17)
def once(s,a,b):
    assert s.count(a)==1,(a,s.count(a))
    return s.replace(a,b,1)
def install():
    out=ROOT/"assets/characters";out.mkdir(parents=True,exist_ok=True)
    c11=json.loads((ROOT/"C11_CC0_CAST_MANIFEST.json").read_text())
    assets=[]
    for cid in CAST:
        src=out/(cid+"_portrait_cc0_audition_1024.webp")
        assert src.exists()
        source_entry=next(a for a in c11["characters"] if a["character_id"]==cid)
        assert sha(src.read_bytes())==source_entry["derived_sha256"],("altered C11",cid)
        photo=Image.open(src).convert("RGB");assert photo.size==SIZE
        for kind in ("day","night"):
            dst=out/(cid+"_portrait_doc_"+kind+"_1024.webp")
            grade(photo,cid,kind).save(dst,format="WEBP",quality=94,method=6)
            assert Image.open(dst).size==SIZE
            assets.append({"character_id":cid,"material":kind,
                "source":str(src.relative_to(ROOT)),"source_sha256":sha(src.read_bytes()),
                "output":str(dst.relative_to(ROOT)),"output_sha256":sha(dst.read_bytes()),
                "dimensions":[1024,1024],"transform":"theme-specific contact-print tonal grade, vignette, reflected tungsten and deterministic grain; no person upscaling",
                "rights_basis":"C11 original independent 1024px synthetic-face CC0 sources; Pexels rehearsal room separately manifested",
                "owner_approved":False})
    scene=ROOT/"scene/frame_demo.gd";s=scene.read_text()
    s=once(s,'var path := "res://assets/characters/%s_portrait_cc0_audition_1024.webp" % id',
        'var path := "res://assets/characters/%s_portrait_doc_%s_1024.webp" % [id, "day" if frame_material_kind == "notepaper" else "night"]')
    scene.write_text(s)
    manifest={"kit":"C13 independent CC0 character photo/contact-print theme variants",
        "owner_approved":False,"status":"PROVISIONAL visual study; headshot wardrobe/smile still studio-corporate, not genuine indie musician provenance",
        "rights_basis":"C11 synthetic publisher CC0 source plus separately licensed Pexels background, checked against C11 hashes",
        "theme_treatments":{"day":"warm print","night":"contrast monochrome"},
        "assets":assets}
    (ROOT/"C13_DOCUMENTARY_PORTRAITS_MANIFEST.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("C13 source-backed individual theme variants",[(a["character_id"],a["material"],a["output_sha256"][:12]) for a in assets])
def patch_test():
    p=ROOT/"tests/native_proof.gd";s=p.read_text()
    for cid in CAST:
        s=s.replace(cid+"_portrait_cc0_audition",cid+"_portrait_doc_")
    s=s.replace('"portrait_cc0_audition"','"portrait_doc_"')
    assert "portrait_cc0_audition" not in s
    marker='check(scene.character_photo.texture.get_width() >= 1024, "C11 portrait below source quality floor " + prefix)'
    s=once(s,marker,marker+'''
            check(scene.character_photo.texture.resource_path.contains("_doc_day_1024") if kind == "notepaper" else scene.character_photo.texture.resource_path.contains("_doc_night_1024"), "C13 character grade mismatched material " + prefix)''')
    p.write_text(s)
    print("C13 source path, 1024 and per-material native test assertions patched")
if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--phase",choices=("install","patch-test"),required=True)
    args=p.parse_args()
    install() if args.phase=="install" else patch_test()
