"""U04: retain original Lab08.4 photographic layers; correct zero-level fader glow.
All emitted 0/25/50/75/100 composites are REVIEW ONLY, not interactive skins.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import colorsys
import os,shutil,json,hashlib
root=Path(os.environ["ROOT"])
source=Path("art-sources/bandmaster_premium_dashboard_poc")
target=root/"bandmaster_premium_dashboard_poc"
shutil.copytree(source,target,dirs_exist_ok=True)
assets=target/"assets"
# The supplied Lab08 export omitted rotary_pointer.png referenced by the live GDScript.
# Derive it from the ORIGINAL amber focus rotor; never invent a procedural arrow.
rotor=Image.open(assets/"focus_rotor.png").convert("RGBA")
mask=Image.new("L",rotor.size,0)
pixels=rotor.load()
alpha=mask.load()
for y in range(rotor.height):
 for x in range(rotor.width):
  r,g,b,a=pixels[x,y]
  hue,sat,val=colorsys.rgb_to_hsv(r/255,g/255,b/255)
  if 0.065<hue<0.160 and sat>0.40 and val>0.33 and r-g>25 and g-b>25:
   alpha[x,y]=a
assert mask.getbbox() is not None and mask.getbbox()[2]-mask.getbbox()[0]>30
pointer=rotor.copy()
pointer.putalpha(mask.filter(ImageFilter.GaussianBlur(0.45)))
pointer=pointer.rotate(45,resample=Image.Resampling.BICUBIC,expand=False)
pointer.save(assets/"rotary_pointer.png",optimize=True)
out=root/"assets/material"
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
script=target/"studio_control.gd"
s=script.read_text()
for needle in (
 "draw_line(Vector2(130.0 * sx, pos_y), Vector2(glow_end * sx, pos_y), Color(highlight, 0.32), 8.0 * sy, true)",
 "draw_line(Vector2(130.0 * sx, pos_y), Vector2(glow_end * sx, pos_y), highlight, 3.5 * sy, true)",
 "draw_line(Vector2(195.0 * sx, (cap_top + 122.0) * sy), Vector2(195.0 * sx, 630.0 * sy), Color(highlight, 0.32), 9.0 * sx, true)",
 "draw_line(Vector2(195.0 * sx, (cap_top + 122.0) * sy), Vector2(195.0 * sx, 630.0 * sy), highlight, 4.0 * sx, true)"
):
 assert s.count("\t\t"+needle)==1,needle
 s=s.replace("\t\t"+needle,"\t\tif level > 0.0:\n\t\t\t"+needle,1)
script.write_text(s)
records=[]
for kind,count in (("focus",27),("buzz",23)):
 off=Image.open(assets/f"{kind}_ring_off.png").convert("RGBA")
 originals=[assets/f"{kind}_led_{i:02d}.png" for i in range(count)]
 assert all(p.is_file() for p in originals)
 for level in (0,25,50,75,100):
  image=off.copy()
  lit=round(count*level/100)
  for p in originals[:lit]:
   overlay=Image.open(p).convert("RGBA")
   assert overlay.size==off.size
   image.alpha_composite(overlay)
  path=out/f"u04_{kind}_{level:03d}_review.png"
  image.save(path,optimize=True)
  if level==0: assert list(image.getdata())==list(off.getdata())
  if level==100: assert image.tobytes()!=off.tobytes()
  records.append(dict(kind=kind,value=level,lit_segments=lit,segments=count,path=str(path.relative_to(root)),size=list(image.size),sha256=digest(path),role="REVIEW COMPOSITE ONLY"))
atlas=Image.new("RGB",(1200,930),"#141a1f")
draw=ImageDraw.Draw(atlas)
for i,r in enumerate(records):
 im=Image.open(root/r["path"]).convert("RGBA"); im.thumbnail((210,365),Image.Resampling.LANCZOS)
 x=10+(i%5)*240; y=25+(i//5)*465
 atlas.paste(im,(x,y),im)
 draw.text((x+10,y+385),f"{r['kind'].upper()} {r['value']}% / {r['lit_segments']} LEDs",fill="white")
p=out/"u04_control_value_atlas.png";atlas.save(p,optimize=True)
manifest=dict(schema_version=1,kit="U04 Lab08.4 layered controls",owner_approved=False,source_type="Owner-supplied IMAGE-GENERATED photographed-style Lab08.4 assets, NOT real hardware photography",native_script=str(script.relative_to(root)),zero_fader_ghost_fix=True,derived_pointer_source="Original focus_rotor.png hue-isolated, rotated 45deg; no new synthetic art",derived_pointer_sha256=digest(assets/"rotary_pointer.png"),review_atlas_sha256=digest(p),asset_records=records,interactive_proof="Godot studio_control.gd; source layers live, preview composites not used as controls")
(root/"U04_CONTROL_MANIFEST.json").write_text(json.dumps(manifest,indent=2)+"\n")
print("U04",len(records),"distinct value studies; two zero-ghost fader paths repaired")
