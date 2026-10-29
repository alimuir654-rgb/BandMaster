#!/usr/bin/env python3
"""Export a self-contained path-scoped library; never overwrite a game's project settings."""
from __future__ import annotations
import argparse, hashlib, json, shutil, zipfile
from pathlib import Path
PREFIX='components/control_atlas'
def sha(path:Path)->str:return hashlib.sha256(path.read_bytes()).hexdigest()
def main()->None:
    p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--target',type=Path,required=True);a=p.parse_args()
    dest=a.target/PREFIX
    if dest.exists():shutil.rmtree(dest)
    dest.mkdir(parents=True)
    transformations=[]
    for source in a.source.rglob('*'):
        rel=source.relative_to(a.source)
        if not source.is_file() or any(x in rel.parts for x in ['.godot','proof','__pycache__']) or source.suffix in ['.uid','.import','.ttf','.otf'] or rel.as_posix()=='project.godot':continue
        target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True)
        if source.suffix in ['.gd','.tscn']:
            text=source.read_text();rebased=text.replace('"res://','"res://'+PREFIX+'/')
            target.write_text(rebased)
            transformations.append({'file':str(rel),'source_sha256':sha(source),'module_sha256':sha(target),'change':'Resource prefix only; no control/state/lighting logic modified'})
        else:shutil.copy2(source,target)
    manifest=json.loads((dest/'MANIFEST.json').read_text());manifest['installation_root']='res://'+PREFIX+'/';manifest['module_path_rebases']=transformations
    (dest/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
    config=(a.source/'project.godot').read_text().replace('"res://','"res://'+PREFIX+'/')
    (a.target/'project.godot').write_text(config)
    (dest/'proof').mkdir()
    with zipfile.ZipFile('BandMaster_C20_Drop_In_Library.zip','w',zipfile.ZIP_DEFLATED) as z:
        for f in dest.rglob('*'):
            if f.is_file():z.write(f,f.relative_to(a.target))
    print(f'Exported path-scoped library: {dest}; {len(transformations)} source resource-path rebases')
if __name__=='__main__':main()
