#!/usr/bin/env python3
"""Generate bespoke raster stationery surfaces for Livin' The Dream.
Original deterministic authored artwork, 100% standard Pillow/NumPy; NOT photography.
Runtime uses only generated PNGs, native Godot text and player input controls.
"""
from pathlib import Path
from hashlib import sha256
from PIL import Image, ImageDraw, ImageFilter
import json
import numpy as np

ROOT = Path("Art/UI/FormationCraft")
ROOT.mkdir(parents=True, exist_ok=True)
KINDS = ("candidate", "activity", "tab", "commit")
STATES = ("idle", "hover", "pressed", "chosen", "disabled")
DIMS = {"candidate":(960,174), "activity":(960,158),"tab":(390,140),"commit":(1120,188)}
FONTS = None
record = {}

def rng(key):
    return np.random.default_rng(int.from_bytes(sha256(key.encode()).digest()[:8],"big"))

def noise(w,h,key,base,scale=4.0):
    r = rng(key)
    # Warm paper microscopic pigmentation, not flat vector fill.
    rough = r.normal(0,scale,(h,w,1)).astype(np.float32)
    cloudy = r.normal(0,4,(max(1,h//32),max(1,w//32))).astype(np.float32)
    cloud = Image.fromarray(np.clip(127+cloudy*9,0,255).astype("uint8"),"L").resize((w,h),Image.Resampling.BICUBIC)
    cloud = (np.asarray(cloud,dtype=np.float32)-127)[:,:,None] * 0.14
    y,x=np.mgrid[:h,:w]
    fall=(np.maximum(np.abs(x-w*.5)/(w*.5),np.abs(y-h*.5)/(h*.5)))[:,:,None]
    raw=np.clip(np.array(base,dtype=np.float32)[None,None,:]+rough+cloud-11*fall,0,255).astype("uint8")
    return Image.fromarray(raw,"RGB").convert("RGBA")

def paper_piece(kind,state):
    w,h = DIMS[kind]
    r = rng(kind+":"+state)
    base={"candidate":(240,227,196),"activity":(225,210,175),
          "tab":(239,231,210),"commit":(210,185,140)}[kind]
    if state=="hover": base=tuple(min(255,z+11) for z in base)
    if state=="chosen": base=tuple(min(255,z+5) for z in base)
    if state=="pressed": base=tuple(max(0,z-18) for z in base)
    if state=="disabled": base=tuple(int(z*.72+58) for z in base)
    pad=12 if kind!="tab" else 9
    canvas = Image.new("RGBA",(w,h),(0,0,0,0))
    shadow=Image.new("RGBA",(w,h),(0,0,0,0))
    sd=ImageDraw.Draw(shadow)
    # Multiple paper ply shadow and realistic side-lit curled edge.
    sd.rounded_rectangle((pad+4,pad+8,w-pad+3,h-pad+4),radius=13,
                         fill=(23,18,13,90))
    shadow=shadow.filter(ImageFilter.GaussianBlur(9))
    canvas.alpha_composite(shadow)
    texture=noise(w,h,kind+state,base,4.1)
    mask=Image.new("L",(w,h),0)
    d=ImageDraw.Draw(mask)
    wobble=np.array([int(r.integers(-3,4)) for _ in range(13)])
    top=[(pad,15)]+[(int(pad+(w-2*pad)*i/12),pad+int(wobble[i])) for i in range(13)]+[(w-pad,15)]
    bottom=[(int(pad+(w-2*pad)*i/12),h-pad+int(r.integers(-3,4))) for i in range(12,-1,-1)]
    d.polygon(top+bottom,fill=255)
    texture.putalpha(mask)
    canvas.alpha_composite(texture)
    draw=ImageDraw.Draw(canvas,"RGBA")
    # Grain fibres/ink flea specks are part of the paper itself.
    for _ in range(700 if kind in ("candidate","commit") else 350):
        x=int(r.integers(pad+8,w-pad-8));y=int(r.integers(pad+6,h-pad-6))
        length=int(r.integers(2,19))
        draw.line((x,y,x+length,y+int(r.integers(-3,4))),
                  fill=(95,75,54,int(r.integers(13,40))),width=1)
    # Fold emboss and deckled sheet edge.
    draw.line((pad+11,pad+16,w-pad-11,pad+16),fill=(255,253,229,100),width=2)
    draw.line((pad+11,h-pad-7,w-pad-11,h-pad-7),fill=(84,55,35,42),width=2)
    if kind=="candidate":
        # Hand-numbered archival audition slip: border, punch holes, paper tape.
        draw.line((91,pad+21,91,h-pad-20),fill=(167,62,57,121),width=4)
        for yc in (58,117):
            draw.ellipse((36,yc-13,60,yc+11),fill=(48,40,31,100))
            draw.arc((36,yc-13,60,yc+11),30,240,fill=(255,251,229,120),width=2)
        # thin pencilled rule doublet, long native label sits on top
        draw.line((114,h-47,w-130,h-47),fill=(86,106,114,49),width=2)
        draw.line((114,h-30,w-130,h-30),fill=(86,106,114,34),width=1)
        # Pale linen tape fold, top edge, with drawn fibers and shadow.
        draw.polygon([(161,9),(294,14),(289,35),(158,34)],fill=(218,196,143,143))
        draw.line((160,33,288,35),fill=(89,73,55,53),width=2)
        # Stamped tick target at far-right, distinct selected mark.
        edge=(52,113,89,220) if state=="chosen" else (130,110,80,140)
        draw.rounded_rectangle((w-105,48,w-42,110),radius=6,outline=edge,width=4)
        if state=="chosen":
            draw.line((w-90,79,w-76,94,w-53,61),fill=(33,113,74,255),width=9,joint="curve")
    elif kind=="activity":
        # A venue/outing ticket. Perforation and a safety-stapled strip.
        draw.line((w-162,24,w-162,h-26),fill=(104,85,58,140),width=3)
        for yc in range(34,h-22,14):
            draw.ellipse((w-166,yc-1,w-159,yc+5),fill=(110,97,71,120))
        draw.rounded_rectangle((26,37,72,h-36),radius=4,outline=(109,91,61,120),width=2)
        draw.line((98,h-49,w-185,h-49),fill=(94,84,68,67),width=2)
        for cx in (42,w-61):
            draw.ellipse((cx-11,21,cx+11,43),fill=(53,48,42,110))
            draw.arc((cx-10,19,cx+9,41),90,290,fill=(216,198,163,190),width=3)
    elif kind=="tab":
        draw.rectangle((25,25,37,h-26),fill=(154,100,63,90))
        draw.line((45,42,w-60,42),fill=(114,86,58,75),width=2)
        draw.ellipse((w-71,55,w-43,83),fill=(184,149,91,165))
        draw.ellipse((w-65,62,w-49,78),fill=(79,72,55,102))
    else:
        # Heavy letterpress decision / embossed stamp band with two grommets.
        draw.rounded_rectangle((36,35,w-36,h-30),radius=12,fill=(87,53,30,47),
                               outline=(105,70,42,122),width=4)
        for x in (63,w-63):
            draw.ellipse((x-17,h//2-17,x+17,h//2+17),fill=(68,60,44,190))
            draw.ellipse((x-15,h//2-17,x+15,h//2+13),fill=(203,164,84,244))
            draw.ellipse((x-9,h//2-9,x+9,h//2+8),fill=(55,50,42,228))
        draw.line((122,h-42,w-122,h-42),fill=(250,233,181,62),width=2)
    if state=="chosen":
        draw.line((pad+15,23,w-pad-15,23),fill=(42,121,89,196),width=5)
        draw.ellipse((w-132,18,w-97,53),outline=(42,121,89,195),width=4)
    if state=="hover":
        draw.rounded_rectangle((pad+4,pad+4,w-pad-4,h-pad-3),radius=10,outline=(188,134,54,185),width=4)
    if state=="pressed":
        glaze=Image.new("RGBA",(w,h),(51,29,12,18))
        canvas=Image.alpha_composite(canvas,glaze)
    if state=="disabled":
        glaze=Image.new("RGBA",(w,h),(215,207,193,100))
        canvas=Image.alpha_composite(canvas,glaze)
    return canvas

def material_surface(name,width,height):
    r=rng(name)
    if name=="desk":
        # Sunlit cork-and-wood production desk, with pencil scoring, grain.
        base=(190,154,102)
    else:
        base=(249,239,214)
    img=noise(width,height,name,base,5.5)
    d=ImageDraw.Draw(img,"RGBA")
    if name=="desk":
        # Organic tactile cork flecks, not straight vector scratch lines.
        # Clusters vary in opacity/scale: believable granular board from a distance.
        for _ in range(16500):
            x=int(r.integers(0,width));y=int(r.integers(0,height))
            fw=int(r.integers(2,14));fh=int(r.integers(1,6))
            palette=((92,67,39),(228,197,145),(153,110,68),(248,224,181))
            colour=palette[int(r.integers(0,len(palette)))]
            d.ellipse((x,y,x+fw,y+fh),fill=(*colour,int(r.integers(14,72))))
        # Faint pinpricks and natural compressed-cork texture.
        for _ in range(3200):
            x=int(r.integers(0,width));y=int(r.integers(0,height))
            d.ellipse((x,y,x+int(r.integers(1,4)),y+int(r.integers(1,4))),
                      fill=(49,38,26,int(r.integers(10,30))))
        # Light entering window left, with natural sepia sun wash.
        wash=Image.new("RGBA",(width,height))
        a=np.asarray(wash).copy()
        yy,xx=np.mgrid[:height,:width]
        light=np.clip(1.0-xx/float(width),0,1)**1.5
        a[:,:,:3]=np.array([255,244,214],dtype=np.uint8)
        a[:,:,3]=np.minimum(62,(light*52)).astype(np.uint8)
        wash=Image.fromarray(a,"RGBA")
        img=Image.alpha_composite(img,wash)
        d=ImageDraw.Draw(img,"RGBA")
        # Slightly darkened lip at the edge of a real pin-board frame.
        d.line((0,5,width,5),fill=(75,51,31,88),width=8)
        d.line((0,15,width,15),fill=(253,229,183,36),width=3)
    else:
        # Notebook fibers, left stitching, dog-eared top and faded ink rules.
        for y in range(96,height-60,41):
            d.line((49,y,width-45,y),fill=(85,120,137,18),width=2)
        d.line((23,25,23,height-25),fill=(165,52,54,37),width=2)
        for y in range(78,height-45,128):
            d.ellipse((4,y-11,20,y+11),fill=(100,87,70,80))
            d.arc((3,y-12,20,y+11),120,340,fill=(251,248,225,140),width=2)
        d.polygon([(width-125,17),(width-19,17),(width-21,120)],fill=(218,202,170,199))
        d.line((width-125,17,width-21,120),fill=(124,106,80,76),width=3)
        # Washi tape translucent strips at the top of the physical sheet.
        d.polygon([(220,7),(445,4),(448,37),(216,41)],fill=(205,178,120,117))
        d.polygon([(width-479,3),(width-292,13),(width-298,43),(width-486,31)],fill=(191,173,125,104))
    return img

def save(image,name):
    dest=ROOT/name
    image.save(dest,optimize=True)
    record[str(dest)]=sha256(dest.read_bytes()).hexdigest()

for kind in KINDS:
    for state in STATES:
        save(paper_piece(kind,state),f"{kind}_{state}.png")
save(material_surface("desk",1600,1200),"rehearsal_desk.png")
save(material_surface("notebook",1120,1440),"rehearsal_notebook.png")
manifest=ROOT/"SOURCE_SHA256.json"
manifest.write_text(json.dumps({"generator":"tools/build_formation_craft.py",
                                "source_type":"authored procedural original, NOT photographs",
                                "state_count":20,"files":record},indent=2,sort_keys=True)+"\n",encoding="utf-8")
print(f"FORMATION CRAFT GENERATED: {len(record)} PNGs, 4 control types x 5 states, 2 materials")
