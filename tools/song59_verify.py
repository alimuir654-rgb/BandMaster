#!/usr/bin/env python3
"""SONG59 exact-source isolated identity proof, retaining genuine baseline songs.

Baseline must be a separately pinned source export. No Git objects, Android
export, private media download, production saves or key operations are used.
"""
import argparse, hashlib, json, os, pathlib, re, subprocess, sys
from song55_verify import ENGINE_SHA, environment, signing_guard
PROJECT='''config_version=5
[application]
config/name="BandMaster SONG59 isolated models"
config/use_custom_user_dir=true
config/custom_user_dir_name="BandMasterSONG59IsolatedQA"
[rendering]
renderer/rendering_method="gl_compatibility"
[threading]
worker_pool/max_threads=2
'''
TEST='tests/song59_cowriting.gd'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def copy(repo,dest,harness):
    pending=[TEST]; files={};dest.mkdir(parents=True)
    while pending:
        name=pending.pop()
        if name in files:continue
        if pathlib.PurePosixPath(name).is_absolute() or '..' in pathlib.PurePosixPath(name).parts:raise RuntimeError('unsafe dependency')
        source=harness if name==TEST else repo/name
        raw=source.read_bytes();target=dest/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw);files[name]=sha(target)
        if target.suffix in {'.gd','.json','.tscn','.tres'}:
            for ref in re.findall(r'res://([^\s"\'<>]+)',raw.decode()):
                if (repo/ref).is_file() and pathlib.Path(ref).suffix in {'.gd','.json','.tscn','.tres'}:pending.append(ref)
    (dest/'project.godot').write_text(PROJECT)
    return files
def main():
    p=argparse.ArgumentParser();p.add_argument('--repo',type=pathlib.Path,required=True);p.add_argument('--baseline-source',type=pathlib.Path,required=True);p.add_argument('--godot',type=pathlib.Path,required=True);p.add_argument('--work',type=pathlib.Path,required=True);a=p.parse_args()
    if sha(a.godot)!=ENGINE_SHA:raise RuntimeError('engine pin mismatch')
    a.work.mkdir();(a.work/'logs').mkdir();receipts={}
    for variant,repo in [('baseline',a.baseline_source),('candidate',a.repo)]:
        dest=a.work/variant/'project';files=copy(repo,dest,a.repo/TEST)
        cmd=[str(a.godot),'--headless','--path',str(dest),'--audio-driver','Dummy','--script','res://'+TEST,'--','--work-root='+str(a.work)]
        if variant=='baseline':cmd+=['--baseline']
        log=a.work/'logs'/f'{variant}.log'
        with log.open('x') as out:
            result=subprocess.run(cmd,env=environment(a.work,variant),stdout=out,stderr=subprocess.STDOUT,timeout=180)
        text=log.read_text();errors=[x for x in text.splitlines() if 'ERROR:' in x or 'SCRIPT ERROR' in x];lines=[x[len('SONG57_RESULT '):] for x in text.splitlines() if x.startswith('SONG57_RESULT ')]
        receipt={'exit_code':result.returncode,'errors':errors,'result':json.loads(lines[-1]) if lines else {},'files':files,'log_sha256':sha(log)};receipts[variant]=receipt
        (a.work/'RUN.json').write_text(json.dumps(receipts,indent=2)+'\n')
        if result.returncode or errors or not receipt['result'].get('ok'):raise RuntimeError('held '+variant+' '+json.dumps(receipt['result'])+' '+str(errors[:5]))
        print(variant,json.dumps(receipt['result']),flush=True)
    print('SONG59 exact-source identity proof PASS')
if __name__=='__main__':main()
