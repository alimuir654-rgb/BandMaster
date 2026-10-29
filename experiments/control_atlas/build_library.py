#!/usr/bin/env python3
"""Assemble native reusable controls from verified sources; no background/character edits."""
from __future__ import annotations
import argparse, hashlib, json, shutil
from pathlib import Path
from PIL import Image, ImageEnhance

def digest(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()
def nine(source: Image.Image, dimensions: tuple[int, int], margin: int) -> Image.Image:
    source=source.convert('RGBA'); w,h=source.size; ow,oh=dimensions
    if min(ow,oh,w,h)<=2*margin: raise ValueError('Nine slice too small')
    out=Image.new('RGBA',dimensions)
    xs=[0,margin,w-margin,w];ys=[0,margin,h-margin,h];dx=[0,margin,ow-margin,ow];dy=[0,margin,oh-margin,oh]
    for y in range(3):
        for x in range(3):
            tile=source.crop((xs[x],ys[y],xs[x+1],ys[y+1]));size=(dx[x+1]-dx[x],dy[y+1]-dy[y])
            if tile.size!=size:tile=tile.resize(size,Image.Resampling.LANCZOS)
            out.paste(tile,(dx[x],dy[y]))
    return out

def main() -> None:
    ap=argparse.ArgumentParser();ap.add_argument('--root',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--templates',type=Path,required=True)
    a=ap.parse_args();source=a.root/'assets/material';out=a.out;out.mkdir(parents=True,exist_ok=True);art=out/'art';art.mkdir(exist_ok=True);records=[]
    def record(p:Path,origin:str,method:str,source_sha:str,**extra):
        with Image.open(p) as im: row={'path':str(p.relative_to(out)),'size':list(im.size),'mode':im.mode,'sha256':digest(p),'source':origin,'source_sha256':source_sha,'method':method,'owner_approved':False}
        row.update(extra);records.append(row)
    for pattern in ['control_*.png','passive_meter_*.png','paper_surface.png','case_surface.png']:
        for p in sorted(source.glob(pattern)):
            if p.name.endswith('_atlas.png'):continue
            dest=art/p.name;shutil.copy2(p,dest);assert digest(dest)==digest(p)
            record(dest,'verified U18 '+str(p.relative_to(a.root)),'unchanged copy',digest(p),passive=p.name.startswith('passive_meter_'))
    for look in ['flightcase','notepaper']:
        parent=source/f'portrait_mount_{look}.png';original=Image.open(parent).convert('RGBA');panel=nine(original,(256,256),32)
        texture=Image.open(source/('paper_surface.png' if look=='notepaper' else 'case_surface.png')).convert('RGBA')
        if look=='notepaper':texture=ImageEnhance.Contrast(texture).enhance(1.6)
        panel.paste(texture.crop((24,24,216,216)),(32,32));dest=art/f'frame_{look}_panel.png';panel.save(dest)
        record(dest,str(parent.relative_to(a.root)),'fixed source corners; independent source-material centre',digest(parent),nine_slice=[40]*4,safe_insets=[30]*4,corner_source_pixels_preserved=True)
        small=Image.open(source/'metal_key.png').convert('RGBA') if look=='flightcase' else original
        inset=nine(small,(192,96),12 if look=='flightcase' else 20);dest=art/f'frame_{look}_inset.png';inset.save(dest)
        parent2=parent if look=='notepaper' else source/'metal_key.png'
        record(dest,str(parent2.relative_to(a.root)),'quiet source-backed inset; no baked text/icons',digest(parent2),nine_slice=[28 if look=='notepaper' else 20]*4,safe_insets=[32 if look=='notepaper' else 24]*4)
        shutil.copy2(parent,art/f'frame_{look}_previous.png')
    vendor=a.root/'bandmaster_premium_dashboard_poc';dest=out/'bandmaster_premium_dashboard_poc';dest.mkdir(exist_ok=True);shutil.copy2(vendor/'studio_control.gd',dest/'studio_control.gd');(dest/'assets').mkdir(exist_ok=True)
    selected=['horizontal_base.png','horizontal_cap.png','vertical_base.png','vertical_cap.png','focus_ring_off.png','buzz_ring_off.png','rotary_pointer.png','meter_base.png']
    selected += [p.name for p in sorted((vendor/'assets').glob('focus_led_*.png'))]
    selected += [p.name for p in sorted((vendor/'assets').glob('buzz_led_*.png'))]
    for name in selected:shutil.copy2(vendor/'assets'/name,dest/'assets'/name)
    vendor_hashes={str(p.relative_to(out)):digest(p) for p in dest.rglob('*') if p.is_file()}
    for p in a.templates.iterdir():
        if p.is_file():shutil.copy2(p,out/p.name)
    (out/'scenes').mkdir(exist_ok=True)
    for kind in ['toggle','stepper','choices','browse','pagination','meter','action','panel','ticket']:
        (out/'scenes'/f'{kind}.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://component.gd" id="1"]\n[node name="'+kind.capitalize()+'" type="MarginContainer"]\nscript = ExtResource("1")\nkind = "'+kind+'"\n')
    provenance=out/'provenance';provenance.mkdir(exist_ok=True)
    for name in ['DIRECT_CONTROL_MANIFEST.json','PASSIVE_METER_MANIFEST.json','MATERIAL_MANIFEST.json','FRAME_KIT_MANIFEST.json','U04_CONTROL_MANIFEST.json']:
        if (a.root/name).exists():shutil.copy2(a.root/name,provenance/name)
    manifest={'schema_version':1,'owner_approved':False,'source_version':'0c041e326098a2c9c8a613368b5eac9dd94e1dc8 (U18)','rights':'Inherited owner-supplied image-generated Lab07/Lab08 sources; CC0 Paper001 per retained source manifest. Not claimed real hardware photography.','unchanged_meter_files':sum(r.get('passive',False) for r in records),'records':records,'vendor_hashes':vendor_hashes,'frame_presets':['panel','inset','portrait','ticket','header','modal'],'background_or_character_changes':False,'button_rendering':'Original images retained byte-for-byte; proportionally downsampled to48px height at runtime before nine-slice.'}
    (out/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n');assert manifest['unchanged_meter_files']==22
    (out/'.gitignore').write_text('.godot/\n*.import\n*.uid\nproof/\n')
    print(f'Built {out}: {len(records)} raster records and {len(vendor_hashes)} unchanged vendor files')
if __name__=='__main__':main()
