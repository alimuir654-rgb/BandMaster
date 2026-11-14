#!/usr/bin/env python3
"""UX70 native proof using the existing isolated source/engine/signing guards."""
from pathlib import Path
import os
import secrets
import shutil
import subprocess
import sys
import time
import song55_verify

_environment = song55_verify.environment

def environment(work, identity):
    return dict(_environment(work, identity), XAUTHORITY=str(work / 'display.Xauthority'))

def display_start(work, env):
    """Authenticated test display inside the sandbox's permitted local TCP path.

    No privilege escalation, Unix socket or outbound connection is needed.
    The cookie stays in a 0600 scratch file and is never logged or published.
    """
    if not shutil.which('Xorg') or not shutil.which('xauth'):
        raise RuntimeError('Native proof needs the existing Xorg and xauth tools')
    number = next((n for n in range(101,130) if not Path(f'/tmp/.X{n}-lock').exists()), None)
    if number is None:
        raise RuntimeError('No bounded display number available')
    authority = work / 'display.Xauthority'
    if not authority.exists():
        authority.touch(mode=0o600)
        subprocess.run(['xauth','-f',str(authority),'add',f'127.0.0.1:{number}',
                        'MIT-MAGIC-COOKIE-1',secrets.token_hex(16)],check=True,
                       stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    os.chmod(authority,0o600)
    config = work / 'ux70-xorg.conf'
    if not config.exists():
        config.write_text('''Section "ServerFlags"
 Option "AutoAddDevices" "false"
 Option "AllowMouseOpenFail" "true"
EndSection
Section "Device"
 Identifier "UX70Dummy"
 Driver "dummy"
 VideoRam 256000
EndSection
Section "Monitor"
 Identifier "UX70Monitor"
 HorizSync 5.0-200.0
 VertRefresh 5.0-200.0
 Modeline "1920x1440" 234.0 1920 2048 2256 2600 1440 1441 1444 1500
EndSection
Section "Screen"
 Identifier "UX70Screen"
 Device "UX70Dummy"
 Monitor "UX70Monitor"
 DefaultDepth 24
 SubSection "Display"
  Depth 24
  Modes "1920x1440"
  Virtual 1920 1440
 EndSubSection
EndSection
''')
    tag=f'ux70-xorg-{number}-{time.time_ns()}'
    stream=(work/'logs'/(tag+'.stdout')).open('x')
    proc=subprocess.Popen(['Xorg',f':{number}','-noreset','-pn','-nolisten','unix',
                           '-nolisten','local','-nolisten','inet6','-listen','tcp',
                           '-auth',str(authority),'-config',str(config),
                           '-logfile',str(work/'logs'/(tag+'.log'))],
                          stdout=stream,stderr=subprocess.STDOUT,env=env)
    display=f'127.0.0.1:{number}'
    started=time.monotonic()
    try:
        while time.monotonic()-started<20:
            if proc.poll() is not None:
                raise RuntimeError('Authenticated sandbox display stopped: '+tag)
            probe=subprocess.run(['xdpyinfo','-display',display],env=env,
                                 stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=2)
            if probe.returncode==0:
                song55_verify.write_json(work/'logs'/'ux70-display-ready.json',
                    {'display':display,'authenticated':True,'sandboxed':True,
                     'unix_sockets':False,'seconds':round(time.monotonic()-started,2)})
                return proc,stream,display
            time.sleep(0.1)
        raise RuntimeError('Authenticated local display readiness timed out')
    except BaseException:
        proc.terminate()
        proc.wait(timeout=5)
        stream.close()
        raise

if __name__ == '__main__':
    song55_verify.environment=environment
    song55_verify.display_start=display_start
    if '--harness' not in sys.argv:
        sys.argv += ['--harness', str(Path(__file__).resolve().parents[1] / 'tests/ux70_native.gd')]
    if '--native-only' not in sys.argv:
        sys.argv.append('--native-only')
    song55_verify.main()
