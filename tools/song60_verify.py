#!/usr/bin/env python3
"""Fresh isolated native SONG60 proof. Existing normal Xorg wrapper/config only."""
import argparse,fcntl,hashlib,json,os,pathlib,subprocess,time,sys
import song55_verify as common
ROOT=pathlib.Path
ENGINE=ROOT('/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 p=argparse.ArgumentParser();p.add_argument('--repo',type=ROOT,required=True);p.add_argument('--work',type=ROOT,required=True);p.add_argument('--variant',choices=['baseline','candidate'],required=True);p.add_argument('--profiles',nargs='+',choices=list(common.PROFILES),required=True);a=p.parse_args()
 if digest(ENGINE)!=common.ENGINE_SHA:raise RuntimeError('engine pin')
 a.work.mkdir(exist_ok=True);(a.work/'logs').mkdir(exist_ok=True)
 lock=open('/workspace/work/unify/native-gl.lock','a');fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
 project=a.work/a.variant/'project'
 if not project.exists():
  common.NATIVE='tests/song60_native.gd';source=common.copy_project(a.repo,project,None,a.repo/common.NATIVE,a.work,False)
  (a.work/f'{a.variant}-SOURCE.json').write_text(json.dumps(source,indent=2)+'\n');print('CURATED '+a.variant,flush=True)
  common.run(a.work,a.variant+'-import',[str(ENGINE),'--headless','--editor','--path',str(project),'--import'],common.environment(a.work,a.variant+'-import'),240)
 else:
  source=json.loads((a.work/f'{a.variant}-SOURCE.json').read_text())
  for name,h in source['source_files'].items():
   if digest(a.repo/name)!=h:raise RuntimeError('source changed; fresh variant required '+name)
 pins={'/usr/bin/Xorg':'bca1ceb412614f4e0cb13a68b5d78e86b32ac25f7f2f66b40de73517c8f239eb','/etc/X11/xorg.conf':'76b290e6680ec6bf706f2940347c56dbe8ac893be448e4af6e120d0d9bd7196a','/usr/lib/xorg/modules/drivers/dummy_drv.so':'608370525f3c6ecf96c1eab4908a2b22c5a676836c81dfd48a8377e268a384f8'}
 if any(digest(ROOT(n))!=h for n,h in pins.items()):raise RuntimeError('existing wrapper/config pins changed')
 number=next(n for n in range(101,130) if not ROOT(f'/tmp/.X{n}-lock').exists() and not ROOT(f'/tmp/.X11-unix/X{n}').exists())
 env=common.environment(a.work,a.variant+'-display');env['DISPLAY']=f':{number}'
 log=(a.work/'logs'/f'{a.variant}-Xorg-{number}.stdout').open('x');proc=subprocess.Popen(['/usr/bin/Xorg',f':{number}','-noreset','-nolisten','tcp','-logfile',str(a.work/'logs'/f'{a.variant}-Xorg-{number}.log')],env=env,stdout=log,stderr=subprocess.STDOUT)
 try:
  ready=False
  for _ in range(100):
   if proc.poll() is not None:raise RuntimeError('normal Xorg stopped')
   if subprocess.run(['xdpyinfo'],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0:ready=True;break
   time.sleep(.1)
  if not ready:raise RuntimeError('display readiness')
  for profile in a.profiles:
   out=a.work/a.variant/profile;out.mkdir();width,height=common.PROFILES[profile];tag=a.variant+'-'+profile
   args=[str(ENGINE),'--path',str(project),'--audio-driver','Dummy','--resolution',f'{width}x{height}','--max-fps','60','--script','res://tests/song60_native.gd','--','--work-root='+str(a.work),'--out='+str(out)]
   if a.variant=='baseline':args+=['--baseline']
   receipt=common.run(a.work,tag,args,dict(common.environment(a.work,tag),DISPLAY=env['DISPLAY']),150)
   text=ROOT(receipt['log']).read_text();rows=[json.loads(x[len('SONG60_NATIVE '):]) for x in text.splitlines() if x.startswith('SONG60_NATIVE ')];receipt['result']=rows[-1] if rows else {};common.write_json(out/'RESULT.json',receipt)
   if not receipt['result'].get('ok'):raise RuntimeError('native assertions '+str(receipt['result']))
   print('NATIVE '+tag+' '+str(receipt['result']['checks']),flush=True)
 finally:
  proc.terminate();proc.wait(timeout=10);log.close();common.signing_guard(a.work,a.variant+'-final');fcntl.flock(lock,fcntl.LOCK_UN)
if __name__=='__main__':
 if '--models' in sys.argv:
  sys.argv.remove('--models')
  import song59_verify
  song59_verify.TEST='tests/song60_models.gd'
  song59_verify.main()
 else:main()
