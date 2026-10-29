"""C11: high-resolution, independently sourced CC0 synthetic audition portraits.
No identifiable real photographed people, no generated UI/collage, no false
claim that a free headshot is a finished premium rock-musician character.
Sources from Visualize Value 18 independent 1024px synthetic CC0 headshots.
"""
import argparse, hashlib, io, json, os, time, urllib.request
from pathlib import Path
from PIL import Image, ImageOps, ImageChops, ImageEnhance, ImageFilter, ImageDraw

ROOT=Path(os.environ["ROOT"])
SRC=Path("art-sources")
OUT=ROOT/"assets/characters"
BASE="https://raw.githubusercontent.com/visualizevalue/headshots/21f916173b6c844c52ccb3ac76e7d7b44de87c3e/"
SOURCE={
 "alex":{"file":"03.png","git_blob_sha1":"5635df9c240c96ba370d10b612086b6bb0e9527a"},
 "nia_griffiths":{"file":"16.png","git_blob_sha1":"569c06f724cec75fd527ef744ffce4fd7c9c1040"}
}
def sha(data):return hashlib.sha256(data).hexdigest()
def git_sha(data):return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
def fetch(path,required_blob=None):
    req=urllib.request.Request(BASE+path,headers={"User-Agent":"BandMaster-Source-Provenance/1.0"})
    exc=None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req,timeout=30) as response:data=response.read()
            if required_blob is not None:
                assert git_sha(data)==required_blob,("Source git SHA changed",path)
            return data
        except Exception as e:
            exc=e
            time.sleep(attempt+1)
    raise RuntimeError("CC0 original source inaccessible: "+path) from exc
def matte_white(src):
    """Use white seamless background to preserve dark shirt and synthetic hair."""
    bg=Image.new("RGB",src.size,(255,255,255))
    delta=ImageOps.grayscale(ImageChops.difference(src,bg))
    alpha=delta.point(lambda v:max(0,min(255,int((v-8)*16.0))))
    # Preserve bright skin (not just dark clothes), else light forehead/cheek
    # becomes semi-transparent over the dark room: a visibly unacceptable face.
    # Original Alex 1024x1024 forehead (500,250) differs from white by >20.
    assert alpha.getpixel((500,250)) >= 240, "Skin alpha matte still transparent"
    return alpha.filter(ImageFilter.GaussianBlur(.65))
def assemble(src,room,center):
    source=src.convert("RGB")
    assert source.size==(1024,1024),source.size
    background=ImageOps.fit(room.convert("RGB"),(1024,1024),method=Image.Resampling.LANCZOS,centering=center)
    background=background.filter(ImageFilter.GaussianBlur(14))
    background=ImageEnhance.Color(background).enhance(.70)
    background=ImageEnhance.Contrast(background).enhance(1.10)
    background=ImageEnhance.Brightness(background).enhance(.56)
    background=Image.blend(background,Image.new("RGB",(1024,1024),(91,70,57)),.10).convert("RGBA")
    alpha=matte_white(source)
    # Shadow ties head/shoulders to the existing actual photographed rehearsal room.
    silhouette=Image.new("RGBA",(1024,1024),(12,10,9,0))
    silhouette.putalpha(alpha.filter(ImageFilter.GaussianBlur(18)).point(lambda v:round(v*.38)))
    background.alpha_composite(silhouette,(0,0))
    subject=ImageEnhance.Color(source).enhance(.90)
    subject=ImageEnhance.Contrast(subject).enhance(1.06)
    subject=Image.blend(subject,Image.new("RGB",subject.size,(196,167,133)),.045)
    subject=subject.convert("RGBA")
    subject.putalpha(alpha)
    background.alpha_composite(subject)
    # Subtle original camera/room vignette; no baked labels, gameplay, UI or faces.
    vignette=Image.new("L",(1024,1024),95)
    ImageDraw.Draw(vignette).ellipse((-110,-110,1134,1134),fill=0)
    vignette=vignette.filter(ImageFilter.GaussianBlur(135))
    dark=Image.new("RGBA",(1024,1024),(7,9,11,0))
    dark.putalpha(vignette)
    background.alpha_composite(dark)
    return background.convert("RGB")
def once(s,a,b):
    assert s.count(a)==1,(a,s.count(a))
    return s.replace(a,b,1)
def install():
    OUT.mkdir(parents=True,exist_ok=True)
    original_dir=OUT/"source_cc0"; original_dir.mkdir(exist_ok=True)
    license_data=fetch("LICENSE")
    assert b"CC0 1.0 Universal" in license_data and b"commercial" in license_data
    (original_dir/"LICENSE.txt").write_bytes(license_data)
    roomfile=SRC/"Art/Photography/Formation/daylight_music_room_pexels.webp"
    assert roomfile.exists(),roomfile
    room=Image.open(roomfile)
    records=[]
    for cid,meta in SOURCE.items():
        blob=fetch("full/"+meta["file"],meta["git_blob_sha1"])
        src=Image.open(io.BytesIO(blob)).convert("RGB")
        assert src.size==(1024,1024),src.size
        original=original_dir/(cid+"_cc0_original_1024.png")
        original.write_bytes(blob)
        edited=assemble(src,room,(.34,.50) if cid=="alex" else (.66,.50))
        dest=OUT/(cid+"_portrait_cc0_audition_1024.webp")
        edited.save(dest,format="WEBP",quality=94,method=6)
        assert Image.open(dest).size==(1024,1024)
        records.append({"character_id":cid,"source_url":BASE+"full/"+meta["file"],
            "source_git_commit":"21f916173b6c844c52ccb3ac76e7d7b44de87c3e",
            "source_git_blob_sha1":meta["git_blob_sha1"],"source_sha256":sha(blob),
            "source_copy":str(original.relative_to(ROOT)),"source_dimensions":[1024,1024],
            "derived_path":str(dest.relative_to(ROOT)),"derived_sha256":sha(dest.read_bytes()),
            "derived_dimensions":[1024,1024],
            "background_source":str(roomfile),"background_sha256":sha(roomfile.read_bytes()),
            "transform":"Source white-background matte, source photo out-of-focus rehearsal room, restrained tonal grade; no enlargement",
            "license":"CC0-1.0 independently generated synthetic face from Visualize Value; Pexels room separately source-manifested",
            "real_person_model_release":"Source publisher declares synthetic people; no real-person model release; coincidental resemblance cannot be excluded",
            "owner_approved":False})
    gd=ROOT/"scene/frame_demo.gd";s=gd.read_text()
    s=once(s,'var path := "res://assets/characters/%s_portrait_provisional_512.webp" % id',
           'var path := "res://assets/characters/%s_portrait_cc0_audition_1024.webp" % id')
    gd.write_text(s)
    manifest={"kit":"C11 independently authored licensed CC0 1024px fictional candidate study",
       "art_verdict":"PROVISIONAL. Source rights and resolution verified; white-background professional headshot origin remains stylistically imperfect for authentic British indie musicians",
       "owner_approved":False,"source_license_url":BASE+"LICENSE",
       "source_license_sha256":sha(license_data),
       "no_character_is_a_real_identified_person":True,
       "publisher_rights_basis":"Visualize Value headshots README and CC0 LICENSE",
       "characters":records}
    (ROOT/"C11_CC0_CAST_MANIFEST.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("C11_TWO_STANDALONE_CC0_PORTRAITS",[(a["character_id"],a["derived_sha256"][:12]) for a in records])
def patch_test():
    p=ROOT/"tests/native_proof.gd";s=p.read_text()
    for old,new in [("alex_portrait_provisional","alex_portrait_cc0_audition"),
                    ("nia_griffiths_portrait_provisional","nia_griffiths_portrait_cc0_audition"),
                    ("portrait_provisional","portrait_cc0_audition")]:
        assert old in s,("missing native assertion",old)
        s=s.replace(old,new)
    anchor='check(scene.candidate_strip.visible == (sz.x >= 900), "C10 candidate strip visibility " + prefix)'
    s=once(s,anchor,anchor+'''
            check(scene.character_photo.texture.get_width() >= 1024, "C11 portrait below source quality floor " + prefix)''')
    p.write_text(s)
    print("C11 native texture identity and resolution checks installed")
if __name__=="__main__":
    args=argparse.ArgumentParser()
    args.add_argument("--phase",required=True,choices=("install","patch-test"))
    phase=args.parse_args().phase
    install() if phase=="install" else patch_test()
