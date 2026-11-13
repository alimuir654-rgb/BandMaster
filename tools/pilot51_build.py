#!/usr/bin/env python3
"""Isolated, original-identity V25 unsigned export; never invokes signing tools."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
WORK = Path('/workspace/bandmaster-pilot51')
ENGINE = Path('/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64')
PRIOR = Path('/workspace/bandmaster-build43')
SDK = PRIOR / 'android-sdk/build-tools/35.0.0'
PROJECT = WORK / 'candidate/project'


def sha(p):
    with Path(p).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def environment():
    java = WORK / 'java-unsigned'
    if not java.exists():
        java.mkdir()
        original = Path('/usr/lib/jvm/java-21-openjdk-amd64')
        for child in original.iterdir():
            if child.name != 'bin':
                (java/child.name).symlink_to(child, target_is_directory=child.is_dir())
        (java/'bin').mkdir()
        for child in (original/'bin').iterdir():
            target = java/'bin'/child.name
            if child.name in ['keytool', 'jarsigner']:
                target.write_text('#!/bin/sh\necho "Signing and key generation disabled" >&2\nexit 97\n')
                target.chmod(0o755)
            else:
                target.symlink_to(child)
    config = WORK/'guarded-config/godot'
    config.mkdir(parents=True, exist_ok=True)
    settings = {'export/android/android_sdk_path': str(PRIOR/'android-sdk'),
        'export/android/java_sdk_path': str(java),
        'export/android/debug_keystore': str(ROOT/'docs/signing/fixtures/v22-request.json'),
        'export/android/debug_keystore_user': 'UNSIGNED_ONLY',
        'export/android/debug_keystore_pass': 'UNSIGNED_ONLY'}
    (config/'editor_settings-4.7.tres').write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'+
        '\n'.join(k+'='+json.dumps(v) for k,v in settings.items())+'\n')
    keydir = WORK/'guarded-data/godot/keystores'
    keydir.mkdir(parents=True, exist_ok=True)
    keydir.chmod(0o555)
    assert not list(WORK.rglob('*.keystore')) and not list(WORK.rglob('*.jks'))
    return dict(os.environ, XDG_CONFIG_HOME=str(config.parent), XDG_DATA_HOME=str(WORK/'guarded-data'),
        XDG_CACHE_HOME=str(WORK/'guarded-cache'), JAVA_HOME=str(java),
        PATH=str(java/'bin')+os.pathsep+os.environ.get('PATH',''), ANDROID_SDK_ROOT=str(PRIOR/'android-sdk'))


def run(name, args, env=None, timeout=240):
    log=WORK/(name+'.log')
    with log.open('x') as out:
        result=subprocess.run(list(map(str,args)), cwd=ROOT, env=env or environment(),
            stdout=out,stderr=subprocess.STDOUT,timeout=timeout)
    text=log.read_text()
    errors=[s for s in text.splitlines() if 'ERROR:' in s or 'SCRIPT ERROR' in s]
    assert result.returncode==0 and not errors, (name,result.returncode,errors)
    assert not list(WORK.rglob('*.keystore')) and not list(WORK.rglob('*.jks'))
    print(name+' PASS',flush=True)


def export():
    env=environment()
    previous=json.loads((PRIOR/'toolchain/toolchain.json').read_text())
    assert sha(ENGINE)==previous['engine_sha256']
    template=PRIOR/'toolchain/android_release.apk'
    assert sha(template)==previous['android_release_template_sha256']
    preset=PROJECT/'export_presets.cfg'
    text=preset.read_text()
    if 'custom_template/release=' not in text:
        text=text.replace('gradle_build/use_gradle_build=false','custom_template/release='+json.dumps(str(template))+'\ngradle_build/use_gradle_build=false')
        preset.write_text(text)
    assert 'package/signed=false' in text and 'version/code=25' in text
    run('guarded-import',[ENGINE,'--headless','--editor','--path',PROJECT,'--import'],env)
    run('export',[ENGINE,'--headless','--path',PROJECT,'--export-release','Owner Android Unsigned',WORK/'exported-UNSIGNED.apk'],env)
    apk=WORK/'BandMaster-Playtest-v25-UNSIGNED.apk'
    run('align',[SDK/'zipalign','-P','16','-f','4',WORK/'exported-UNSIGNED.apk',apk],env)
    run('alignment',[SDK/'zipalign','-c','-P','16','4',apk],env)
    source=json.loads((WORK/'candidate/SOURCE_MANIFEST.json').read_text())['source_sha']
    policy=dict(apk_sha256=sha(apk),apk_size=apk.stat().st_size,version_code=25,
        integrated_source_commit=source,game_source_commit=source,branch='feature/playtest-polish-v20')
    (WORK/'v25-policy.json').write_text(json.dumps(policy,indent=2)+'\n')
    import detached_apk_v2 as v2
    v2.load_policy(WORK/'v25-policy.json')
    _data,_sections,fields,_digest,audit=v2.unsigned_audit(apk,SDK)
    (WORK/'package-audit.json').write_text(json.dumps(dict(sha256=sha(apk),bytes=apk.stat().st_size,
        signed=False,installable_update=False,source_commit=source,**fields,**audit),indent=2)+'\n')
    # Godot's ZIP pack format is the assets directory with the assets prefix removed.
    with zipfile.ZipFile(apk) as original,zipfile.ZipFile(WORK/'compiled-payload.zip','x',compression=zipfile.ZIP_STORED) as pack:
        for entry in original.infolist():
            if entry.filename.startswith('assets/') and not entry.is_dir():
                pack.writestr(entry.filename[len('assets/'):],original.read(entry))
    print(json.dumps(policy),flush=True)


if __name__=='__main__':
    export()
