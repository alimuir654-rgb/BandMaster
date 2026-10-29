"""U04: retain original Lab08.4 photographic layers; correct zero-level fader glow.
All emitted 0/25/50/75/100 composites are REVIEW ONLY, not interactive skins.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import os,shutil,json,hashlib
root=Path(os.environ["ROOT"])
source=Path("art-sources/bandmaster_premium_dashboard_poc")
target=root/"bandmaster_premium_dashboard_poc"
shutil.copytree(source,target,dirs_exist_ok=True)
assets=target/"assets"
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
manifest=dict(schema_version=1,kit="U04 Lab08.4 layered controls",owner_approved=False,source_type="Owner-supplied IMAGE-GENERATED photographed-style Lab08.4 assets, NOT real hardware photography",native_script=str(script.relative_to(root)),zero_fader_ghost_fix=True,review_atlas_sha256=digest(p),asset_records=records,interactive_proof="Godot studio_control.gd; source layers live, preview composites not used as controls")
(root/"U04_CONTROL_MANIFEST.json").write_text(json.dumps(manifest,indent=2)+"\n")
print("U04",len(records),"distinct value studies; two zero-ghost fader paths repaired")
