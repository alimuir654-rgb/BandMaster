"""U09: Lab07-sourced warm enamel DAY controls; NIGHT originals remain unchanged.
Original source relief, real physical bezel and LED state are retained.
All labels, focus and input remain native Godot. Owner art approval: false.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageOps
import argparse, hashlib, json, os

ROOT=Path(os.environ["ROOT"])
OUT=ROOT/"assets/material"
FAMILIES=("action","tab","browse")
STATES=("idle","hover","pressed","active","disabled","focus")
PALETTE={
 "idle":((168,151,127),(247,239,216)),
 "hover":((188,172,147),(255,249,230)),
 "pressed":((124,108,88),(213,195,158)),
 "active":((176,125,56),(251,219,142)),
 "disabled":((143,140,129),(219,211,195)),
 "focus":((176,158,128),(248,240,221))}
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def once(text,a,b):
    assert text.count(a)==1,("U09 source changed",a,text.count(a))
    return text.replace(a,b,1)
def enamel(image,state):
    original=image.convert("RGBA")
    w,h=original.size
    mask=Image.new("L",(w,h),0)
    bbox=(round(w*.061),round(h*.18),round(w*.925),round(h*.82))
    ImageDraw.Draw(mask).rounded_rectangle(bbox,radius=max(6,round(h*.14)),fill=255)
    mask=mask.filter(ImageFilter.GaussianBlur(max(2,round(h*.03))))
    tone=ImageOps.grayscale(original).point(lambda v:max(0,min(255,round((v-22)*3.4))))
    lo,hi=PALETTE[state]
    face=ImageOps.colorize(tone,black=lo,white=hi).convert("RGBA")
    changed=Image.composite(face,original,mask)
    changed.putalpha(original.getchannel("A"))
    return changed
def install():
    p=ROOT/"DIRECT_CONTROL_MANIFEST.json"; m=json.loads(p.read_text())
    night={str(x):sha(x) for x in OUT.glob("control_*_flightcase_*.png")}
    records=[]
    for family in FAMILIES:
        for state in STATES:
            path=OUT/f"control_{family}_notepaper_{state}.png"
            assert path.exists(),path
            before=sha(path)
            image=enamel(Image.open(path),state)
            image.save(path,optimize=True)
            after=sha(path)
            assert before!=after,(family,state)
            center=image.convert("RGB").getpixel((image.width//2,image.height//2))
            assert min(center)>=55,(family,state,center)
            record={"path":str(path.relative_to(ROOT)),"family":family,"state":state,
                    "dimensions":list(image.size),"sha256_before":before,"sha256_after":after,
                    "source":"Owner image-generated Lab07 U03 source sprites, not real hardware photography",
                    "conversion":"Source luminance -> warm enamel inside central face; physical chrome perimeter retained"}
            records.append(record)
            for asset in m["assets"]:
                if asset["path"]==record["path"]:
                    assert asset["sha256"]==before
                    asset["sha256"]=after
                    asset["U09_day_enamel"]=True
                    asset["original_U03_sha256"]=before
    assert len(records)==18
    assert night=={str(x):sha(x) for x in OUT.glob("control_*_flightcase_*.png")}
    m["owner_approved"]=False
    m["U09_day_material"]="Warm photographed-source enamel instead of black floating DAY hardware; night originals unchanged"
    p.write_text(json.dumps(m,indent=2)+"\n")
    p=ROOT/"scene/frame_demo.gd"; s=p.read_text()
    s=once(s,'        button.add_theme_color_override(state, Color("f5ead3"))',
        '        button.add_theme_color_override(state, Color("332719") if frame_material_kind == "notepaper" else Color("f5ead3"))')
    s=once(s,'    button.add_theme_color_override("font_disabled_color", Color("b8afa3"))',
        '    button.add_theme_color_override("font_disabled_color", Color("696359") if frame_material_kind == "notepaper" else Color("b8afa3"))')
    s=once(s,'    recruit_button.add_theme_color_override("font_color", Color("f5ecda"))',
        '    recruit_button.add_theme_color_override("font_color", Color("332719") if frame_material_kind == "notepaper" else Color("f5ecda"))')
    # Native mobile tab names have to clear actual Lab07 metal side rails:
    # shortened glyphs at 390px, original role strings remain tooltips and IDs.
    s=once(s,'    for tab in tabs:\n        tab.add_theme_font_size_override("font_size", 12 if narrow else 16)',
        '    for i in tabs.size():\n        tabs[i].text = ["VOX", "GTR", "BASS", "DRMS", "KEYS"][i] if size.x < 500 else ROLES[i]\n        tabs[i].tooltip_text = ROLES[i]\n        tabs[i].add_theme_font_size_override("font_size", 13 if size.x < 500 else (14 if narrow else 16))')
    s=once(s,'    roster_button.custom_minimum_size.x = 80 if narrow else 135',
        '    roster_button.custom_minimum_size.x = 105 if size.x < 500 else (110 if narrow else 135)')
    p.write_text(s)
    (ROOT/"U09_DAY_ENAMEL_MANIFEST.json").write_text(json.dumps({
       "kit":"U09 lab07-sourced DAY six-state enamel","owner_approved":False,
       "visual_verdict":"requires native pixel review; no approved independent high-res characters",
       "native_text":"dark DAY ink, cream NIGHT; selected/hover/pressed/disabled/focus distinct",
       "rights_basis":"Owner-provided image-generated Lab07, not authentic photographed gear",
       "changed":len(records),"assets":records},indent=2)+"\n")
    atlas=Image.new("RGB",(1220,1050),"#e8dfcc")
    d=ImageDraw.Draw(atlas);y=16
    for family in FAMILIES:
        for theme in ("notepaper","flightcase"):
            d.text((20,y),f"{family.upper()} / {theme.upper()} / 6 independently addressable states",fill="#35291d")
            y+=30
            for i,state in enumerate(STATES):
                img=Image.open(OUT/f"control_{family}_{theme}_{state}.png").convert("RGBA")
                img.thumbnail((185,100),Image.Resampling.LANCZOS)
                x=16+i*200;atlas.paste(img,(x,y),img)
                d.text((x+3,y+104),state,fill="#30251b")
            y+=135
    atlas.save(OUT/"u09_day_enamel_atlas.png",optimize=True)
    print("U09_PRODUCED",len(records),"warm enamel variants; no night source changes")
def patch_test():
    p=ROOT/"tests/native_proof.gd";s=p.read_text()
    a='check(scene.recruit_button.get_meta("source_kit", "") == "U03_Lab07_Tactile", "Direct control skin not bound " + prefix)'
    b=a+"""
            var ink: Color = scene.tabs[0].get_theme_color("font_color")
            check(ink.r < 0.35 if kind == "notepaper" else ink.r > 0.70, "U09 theme text contrast " + prefix)
            var action_ink: Color = scene.recruit_button.get_theme_color("font_color")
            check(action_ink.r < 0.35 if kind == "notepaper" else action_ink.r > 0.70, "U09 action text contrast " + prefix)"""
    p.write_text(once(s,a,b))
    print("U09_NATIVE_CONTRAST_TEST_READY")
if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--phase",required=True,choices=("install","patch-test"))
    args=parser.parse_args()
    install() if args.phase=="install" else patch_test()
