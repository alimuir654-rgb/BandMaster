"""Assemble isolated C24 native proof from reviewed source layers and unchanged kit."""
from pathlib import Path
import argparse,hashlib,json,shutil
from PIL import Image,ImageFilter
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
p=argparse.ArgumentParser();p.add_argument('--layers',type=Path,required=True);p.add_argument('--source',type=Path,default=Path('components/control_atlas'));p.add_argument('--out',type=Path,default=Path('frame-proof-c24'));p.add_argument('--templates',type=Path,default=Path('experiments/frame_assets/runtime'));a=p.parse_args()
assert a.out.resolve()!=a.source.resolve()
if a.out.exists():shutil.rmtree(a.out)
shutil.copytree(a.source,a.out,ignore=shutil.ignore_patterns('.godot','proof','*.import','*.uid','*.ttf','*.otf','__pycache__'))
for f in a.out.rglob('*'):
    if f.suffix in ['.gd','.tscn']:f.write_text(f.read_text().replace('res://components/control_atlas/','res://'))
protected={str(f.relative_to(a.out)):sha(f) for f in a.out.rglob('*') if f.is_file()}
record=json.loads((a.layers/'SOURCE_RENDER_MANIFEST.json').read_text())
for item in record['layers']:assert sha(a.layers/item['file'])==item['sha256']
full=Image.open(a.layers/'dossier_full.png').convert('RGBA')
box=full.getchannel('A').point(lambda v:255 if v>8 else 0).getbbox();assert box
x,y,X,Y=box;box=(max(0,x-16),max(0,y-16),min(full.width,X+16),min(full.height,Y+16))
art=a.out/'art/c24';art.mkdir(parents=True,exist_ok=True);outputs=[]
for role in ['board','paper','clip','full']:
    dest=art/('dossier_'+role+'.png');im=Image.open(a.layers/dest.name).convert('RGBA').crop(box);im.save(dest)
    outputs.append({'role':role,'file':'art/c24/'+dest.name,'dimensions':list(im.size),'sha256':sha(dest)})
board=Image.open(art/'dossier_board.png').convert('RGBA')
shadow=Image.new('RGBA',board.size,(34,27,19,0));alpha=board.getchannel('A').point(lambda v:round(v*.20)).filter(ImageFilter.GaussianBlur(5))
shadow.putalpha(alpha);shift=Image.new('RGBA',board.size);shift.alpha_composite(shadow,(0,4));dest=art/'dossier_shadow.png';shift.save(dest)
outputs.append({'role':'ground_contact_shadow','file':'art/c24/'+dest.name,'dimensions':list(board.size),'sha256':sha(dest),'method':'Rendered board alpha, 5px blur, .20 opacity, 4px offset; not painted frame structure'})
for f in a.templates.glob('*.gd.in'):shutil.copy2(f,a.out/f.name.removesuffix('.in'))
(a.out/'dossier_demo.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://dossier_demo.gd" id="1"]\n\n[node name="DossierProof" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nscript = ExtResource("1")\n')
(a.out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="BandMaster C24 dossier source proof"\nrun/main_scene="res://dossier_demo.tscn"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
(a.out/'proof').mkdir(exist_ok=True)
assert all(sha(a.out/f)==digest for f,digest in protected.items()),'Existing kit changed'
manifest={'schema_version':1,'owner_approved':False,'status':'isolated_candidate_not_default_library','source_run_id':40950171890,'source_code_sha':'d2ede86460ced375232f0b77df236c6747dfddc9','source_manifest':record,'crop_same_for_all_layers':list(box),'resizing':'Proportional portrait-ratio assembly. Not an arbitrary-aspect nine-slice board. Clip never stretched independently.','content_safe_normalized':[.11,.17,.89,.90],'native_data':'Live labels, existing button and passive meter; no text baked into source art','outputs':outputs,'protected_originals':protected}
(a.out/'C24_DOSSIER_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
(a.out/'C24_README.md').write_text('# C24 isolated dossier candidate\n\nOpen project.godot in Godot 4.7.2 and run. C20/C21/C24 switch only frame art; Review notes is live. Resize the window. C24 uses three own offline-rendered CC0 source layers and a derived contact shadow, not a generated UI screenshot. Original controls and dialog logic are retained. Source provenance and modifications are in C24_DOSSIER_MANIFEST.json. No production saves are touched. This candidate is not owner-approved and does not replace the published control library.\n')
print('Built isolated C24 proof; preserved',len(protected),'existing files')
