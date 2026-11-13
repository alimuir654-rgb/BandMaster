#!/usr/bin/env python3
"""Bounded native journeys with one explicitly owned Xorg child; no APK/key use."""
from pathlib import Path
import argparse
import os
import re
import shutil
import subprocess
import time
import pilot51_build as build_guard
from pilot51_build import ENGINE

ROOT=Path(__file__).resolve().parents[1]
WORK=Path('/workspace/bandmaster-engage52')
build_guard.WORK=WORK
environment=build_guard.environment


def copy_test(relative,project,seen=None):
    seen=seen if seen is not None else set()
    if relative in seen:return
    seen.add(relative);source=ROOT/relative;assert source.is_file(),relative
    target=project/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target)
    for ref in re.findall(r'res://(tests/[^"\s]+\.gd)',source.read_text()):copy_test(ref,project,seen)


def main():
    p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--tag',required=True);p.add_argument('--baseline',action='store_true');p.add_argument('--profiles',nargs='+',default=['phone','short','tall','wide']);args=p.parse_args()
    copy_test('tests/engage52_native.gd',args.project)
    env=environment();env['DISPLAY']=':100';env['LIBGL_ALWAYS_SOFTWARE']='1'
    with (WORK/(args.tag+'-Xorg.stdout')).open('x') as log:
        display=subprocess.Popen(['/usr/lib/xorg/Xorg',':100','-noreset','-nolisten','tcp','-config','/workspace/bandmaster-crowd37/xorg.conf','-logfile',str(WORK/(args.tag+'-Xorg.log'))],stdout=log,stderr=subprocess.STDOUT)
        try:
            for i in range(50):
                if subprocess.run(['xdpyinfo'],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0:break
                assert display.poll() is None;time.sleep(.2)
            else:raise RuntimeError('Display readiness timeout')
            for name in args.profiles:
                width,height={'phone':(390,844),'short':(1280,720),'tall':(720,1280),'wide':(1600,900)}[name]
                env.update(XDG_DATA_HOME=str(WORK/(args.tag+'-'+name+'-user')))
                command=[str(ENGINE),'--path',str(args.project),'--resolution',f'{width}x{height}','--rendering-method','gl_compatibility','--audio-driver','Dummy','--script','res://tests/engage52_native.gd','--','--out='+str(WORK/(args.tag+'-'+name))]
                if args.baseline:command.append('--baseline')
                logfile=WORK/(args.tag+'-'+name+'.log')
                with logfile.open('x') as output:result=subprocess.run(command,env=env,cwd=WORK,stdout=output,stderr=subprocess.STDOUT,timeout=180)
                text=logfile.read_text();errors=[s for s in text.splitlines() if 'ERROR:' in s or 'SCRIPT ERROR' in s]
                assert result.returncode==0 and not errors,(name,result.returncode,errors)
                print(args.tag+' '+name+' PASS',flush=True)
        finally:
            display.terminate();display.wait(timeout=10)


if __name__=='__main__':main()
