#!/usr/bin/env python3
"""Prepare the existing app's unsigned V24 candidate. No signing/key operations."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ENGINE = Path('/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64')
JAVA = Path('/usr/lib/jvm/java-21-openjdk-amd64')
VERSION_NAME = '0.154.0-playtest-crowd-vocals'


def digest(path, algorithm='sha256'):
    h = hashlib.new(algorithm)
    with path.open('rb') as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest()


def download(url, path, checksum, algorithm, size=None):
    if not path.exists():
        pending = path.with_suffix(path.suffix + '.download')
        with urllib.request.urlopen(url, timeout=60) as response, pending.open('xb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
        assert digest(pending, algorithm) == checksum, path.name
        if size is not None:
            assert pending.stat().st_size == size
        pending.rename(path)
    assert digest(path, algorithm) == checksum
    if size is not None:
        assert path.stat().st_size == size
    return {'name': path.name, 'url': url, 'bytes': path.stat().st_size,
            'provider_algorithm': algorithm, 'provider_digest': checksum, 'sha256': digest(path)}


def extract(archive, target):
    target.mkdir(parents=True, exist_ok=False)
    with zipfile.ZipFile(archive) as z:
        for info in z.infolist():
            p = Path(info.filename)
            assert not p.is_absolute() and '..' not in p.parts
            z.extract(info, target)
            if not info.is_dir():
                (target / info.filename).chmod((info.external_attr >> 16) & 0o777 or 0o644)


def toolchain(work):
    folder = work / 'toolchain'
    folder.mkdir(parents=True, exist_ok=True)
    sums = (folder / 'godot-SHA512-SUMS.txt').read_text().splitlines()
    name = 'Godot_v4.7.2-stable_export_templates.tpz'
    checksum = next(line.split()[0] for line in sums if line.split()[-1] == name)
    rows = [download('https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/' + name,
                     folder / name, checksum, 'sha512')]
    print('Official Godot template archive verified', flush=True)
    with zipfile.ZipFile(folder / name) as z:
        for basename in ['android_release.apk', 'android_debug.apk']:
            key = 'templates/' + basename
            target = folder / basename
            assert not target.exists()
            target.write_bytes(z.read(key))
    root = ET.fromstring((folder / 'google-repository.xml').read_text())
    sdk = work / 'android-sdk'
    sdk.mkdir(exist_ok=False)
    for package in ['build-tools;35.0.0', 'platform-tools']:
        candidates = [p for p in root.findall('remotePackage')
                      if p.get('path') == package and p.find('channelRef').get('ref') == 'channel-0']
        assert len(candidates) == 1, package
        row = next(a.find('complete') for a in candidates[0].findall('archives/archive')
                   if a.findtext('host-os') == 'linux')
        name = row.findtext('url')
        assert Path(name).name == name
        rows.append(download('https://dl.google.com/android/repository/' + name, folder / name,
                             row.findtext('checksum'), 'sha1', int(row.findtext('size'))))
        expanded = folder / ('expanded-' + package.replace(';', '-'))
        extract(folder / name, expanded)
        if package.startswith('build-tools'):
            properties = list(expanded.rglob('source.properties'))
            assert len(properties) == 1 and 'Pkg.Revision=35.0.0' in properties[0].read_text().replace(' ', '')
            target = sdk / 'build-tools/35.0.0'
            target.parent.mkdir(parents=True)
            shutil.move(str(properties[0].parent), target)
        else:
            shutil.move(str(expanded / 'platform-tools'), sdk / 'platform-tools')
        print(package + ' archive verified and unpacked', flush=True)
    for p in [sdk / 'build-tools/35.0.0/apksigner', sdk / 'build-tools/35.0.0/aapt',
              sdk / 'build-tools/35.0.0/zipalign', sdk / 'platform-tools/adb']:
        assert p.is_file()
        p.chmod(p.stat().st_mode | 0o100)
    (folder / 'toolchain.json').write_text(json.dumps({'archives': rows,
        'engine': str(ENGINE), 'engine_sha256': digest(ENGINE), 'java': str(JAVA),
        'android_release_template_sha256': digest(folder / 'android_release.apk'),
        'sdk': str(sdk)}, indent=2) + '\n')


def build(work):
    # A missing configured debug-key path makes the editor create a default key,
    # even during import. An existing public JSON is an intentionally unusable
    # signing placeholder. Deny key tooling as well; unsigned exports need none.
    java = work / 'java-unsigned'
    java.mkdir()
    for child in JAVA.iterdir():
        if child.name != 'bin':
            (java / child.name).symlink_to(child, target_is_directory=child.is_dir())
    (java / 'bin').mkdir()
    for child in (JAVA / 'bin').iterdir():
        target = java / 'bin' / child.name
        if child.name in ['keytool', 'jarsigner']:
            target.write_text('#!/bin/sh\nprintf "Signing and key generation are disabled for this unsigned build\\n" >&2\nexit 97\n')
            target.chmod(0o755)
        else:
            target.symlink_to(child)
    keys = work / 'data/godot/keystores'
    keys.mkdir(parents=True)
    keys.chmod(0o555)
    candidate = work / 'candidate'
    subprocess.run([sys.executable, str(ROOT / 'tools/build_recorded_owner.py'), '--output', str(candidate),
                    '--version-code', '24', '--version-name', VERSION_NAME], cwd=ROOT, check=True)
    project = candidate / 'project'
    receipt = json.loads((candidate / 'SOURCE_MANIFEST.json').read_text())
    assert receipt['version_code'] == 24 and receipt['application_id'] == 'com.bandmaster.ownerplaytest.s40'
    preset = project / 'export_presets.cfg'
    text = preset.read_text().replace('gradle_build/use_gradle_build=false',
        'custom_template/release=' + json.dumps(str(work / 'toolchain/android_release.apk')) +
        '\ngradle_build/use_gradle_build=false')
    assert 'package/signed=false' in text
    preset.write_text(text)
    config = work / 'config/godot'
    config.mkdir(parents=True)
    # Explicit unsigned export; no fallback signing identity is supplied.
    settings = {'export/android/android_sdk_path': str(work / 'android-sdk'),
                'export/android/java_sdk_path': str(java),
                'export/android/debug_keystore': str(ROOT / 'docs/signing/fixtures/v22-request.json'),
                'export/android/debug_keystore_user': 'UNSIGNED_ONLY',
                'export/android/debug_keystore_pass': 'UNSIGNED_ONLY'}
    (config / 'editor_settings-4.7.tres').write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' +
        '\n'.join(k + '=' + json.dumps(v) for k, v in settings.items()) + '\n')
    env = dict(os.environ, XDG_DATA_HOME=str(work / 'data'), XDG_CONFIG_HOME=str(work / 'config'),
               XDG_CACHE_HOME=str(work / 'cache'), JAVA_HOME=str(java),
               PATH=str(java / 'bin') + os.pathsep + os.environ.get('PATH', ''),
               ANDROID_SDK_ROOT=str(work / 'android-sdk'))
    (work / 'logs').mkdir()
    steps = []

    def run(name, command, timeout=300):
        with (work / 'logs' / (name + '.log')).open('x') as log:
            result = subprocess.run(list(map(str, command)), env=env, cwd=ROOT,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
        text = (work / 'logs' / (name + '.log')).read_text()
        errors = [line for line in text.splitlines() if 'ERROR:' in line or 'SCRIPT ERROR' in line]
        steps.append({'name': name, 'exit_code': result.returncode, 'errors': errors,
                      'log_sha256': digest(work / 'logs' / (name + '.log'))})
        (work / 'build-steps.json').write_text(json.dumps(steps, indent=2) + '\n')
        assert result.returncode == 0 and not errors, name
        assert not list(work.rglob('*.keystore')) and not list(work.rglob('*.jks')), 'Unexpected key file'
        print(name + ' passed', flush=True)

    run('import', [ENGINE, '--headless', '--editor', '--path', project, '--import'])
    for row in receipt['files']:
        assert digest(project / row['path']) == row['sha256'], row['path']
    raw = work / 'exported-UNSIGNED.apk'
    run('export', [ENGINE, '--headless', '--path', project, '--export-release', 'Owner Android Unsigned', raw])
    apk = work / 'BandMaster-Playtest-v24-UNSIGNED.apk'
    sdk = work / 'android-sdk/build-tools/35.0.0'
    run('align', [sdk / 'zipalign', '-P', '16', '-f', '4', raw, apk])
    run('alignment', [sdk / 'zipalign', '-c', '-P', '16', '4', apk])
    policy = {'apk_sha256': digest(apk), 'apk_size': apk.stat().st_size, 'version_code': 24,
              'integrated_source_commit': receipt['source_sha'], 'game_source_commit': receipt['source_sha'],
              'branch': 'feature/playtest-polish-v20'}
    (work / 'v24-policy.json').write_text(json.dumps(policy, indent=2) + '\n')
    import detached_apk_v2 as v2
    v2.load_policy(work / 'v24-policy.json')
    _data, _layout, fields, _digest, audit = v2.unsigned_audit(apk, sdk)
    (work / 'package-audit.json').write_text(json.dumps(dict(sha256=policy['apk_sha256'],
        bytes=policy['apk_size'], signed=False, installable_update=False,
        source_commit=receipt['source_sha'], **fields, **audit), indent=2) + '\n')
    print(json.dumps({'unsigned_apk': str(apk), 'sha256': policy['apk_sha256'],
                      'bytes': policy['apk_size'], 'version': 24, 'signing': False}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('step', choices=['toolchain', 'build'])
    parser.add_argument('--work', type=Path, required=True)
    args = parser.parse_args()
    (toolchain if args.step == 'toolchain' else build)(args.work.resolve())
