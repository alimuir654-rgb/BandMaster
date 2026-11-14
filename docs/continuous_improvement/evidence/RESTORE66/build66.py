"""Fresh V26 unsigned export and compiled-payload proof. Never signs an APK."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parent
REPO = ROOT / 'repo'
WORK = ROOT / 'unsigned-build'
ENGINE = ROOT / 'toolchain/Godot_v4.7.2-stable_linux.x86_64'
SDK = ROOT / 'android-sdk/build-tools/35.0.0'
SOURCE = 'e887c35147b39fc3d12ef11ce2f8d322553991e1'
sys.path.insert(0, str(REPO / 'tools'))
import pilot51_build as prior
import detached_apk_v2 as v2


def sha(path):
    with Path(path).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def save(path, data):
    path.write_text(json.dumps(data, indent=2) + '\n')


def main():
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip() == SOURCE
    assert sha(ENGINE) == '8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e'
    template = ROOT / 'toolchain/android_release.apk'
    assert sha(template) == '6d1bb2cfa126a1b1c87e064a35b3cbd181bef0ec784dec1efd1d64dffa8be6cb'
    WORK.mkdir(exist_ok=False)
    prior.ROOT, prior.WORK, prior.PRIOR, prior.ENGINE, prior.SDK = REPO, WORK, ROOT, ENGINE, SDK
    env = prior.environment()
    subprocess.run([sys.executable, str(REPO / 'tools/build_recorded_owner.py'), '--output', str(WORK / 'candidate'),
                    '--version-code', '26', '--version-name', '0.166.0-playtest-restored', '--pack-pcm'],
                   cwd=REPO, env=env, check=True)
    project = WORK / 'candidate/project'
    receipt_path = WORK / 'candidate/SOURCE_MANIFEST.json'
    receipt = json.loads(receipt_path.read_text())
    assert receipt['source_sha'] == SOURCE and receipt['version_code'] == 26
    assert receipt['application_id'] == 'com.bandmaster.ownerplaytest.s40'
    assert receipt['save_directory'] == 'BandMasterOwnerPlaytestS40'
    preset = project / 'export_presets.cfg'
    text = preset.read_text()
    assert 'package/signed=false' in text and 'version/code=26' in text
    text = text.replace('gradle_build/use_gradle_build=false', 'custom_template/release=' + json.dumps(str(template)) + '\ngradle_build/use_gradle_build=false')
    preset.write_text(text)
    prior.run('guarded-import', [ENGINE, '--headless', '--editor', '--path', project, '--import'], env, timeout=300)
    for row in receipt['files']:
        assert sha(project / row['path']) == row['sha256'], row['path']
    prior.run('export', [ENGINE, '--headless', '--path', project, '--export-release', 'Owner Android Unsigned', WORK / 'exported-UNSIGNED.apk'], env, timeout=300)
    apk = WORK / 'BandMaster-Playtest-v26-UNSIGNED.apk'
    prior.run('align', [SDK / 'zipalign', '-P', '16', '-f', '4', WORK / 'exported-UNSIGNED.apk', apk], env)
    prior.run('alignment', [SDK / 'zipalign', '-c', '-P', '16', '4', apk], env)
    policy = {'apk_sha256': sha(apk), 'apk_size': apk.stat().st_size, 'version_code': 26,
              'integrated_source_commit': SOURCE, 'game_source_commit': SOURCE, 'branch': 'feature/playtest-polish-v20'}
    save(WORK / 'v26-policy.json', policy)
    v2.load_policy(WORK / 'v26-policy.json')
    _data, _layout, fields, _digest, audit = v2.unsigned_audit(apk, SDK)
    package_audit = {'sha256': policy['apk_sha256'], 'bytes': policy['apk_size'], 'signed': False,
                     'installable_update': False, 'source_commit': SOURCE, **fields, **audit}
    save(WORK / 'package-audit.json', package_audit)
    del _data
    payload = WORK / 'compiled-payload.zip'
    with zipfile.ZipFile(apk) as original, zipfile.ZipFile(payload, 'x', compression=zipfile.ZIP_STORED) as pack:
        for entry in original.infolist():
            if entry.filename.startswith('assets/') and not entry.is_dir():
                pack.writestr(entry.filename[len('assets/'):], original.read(entry))
    host = WORK / 'empty-compiled-host'
    host.mkdir()
    log = WORK / 'compiled-model.log'
    harness = REPO / 'tests/build43_compiled.gd'
    command = [str(ENGINE), '--headless', '--audio-driver', 'Dummy', '--path', str(host),
               '--main-pack', str(payload), '--script', str(harness)]
    with log.open('x') as output:
        run = subprocess.run(command, cwd=host, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=300)
    text = log.read_text()
    errors = [line for line in text.splitlines() if 'ERROR:' in line or 'SCRIPT ERROR' in line]
    markers = [line.removeprefix('BUILD43_COMPILED_MODEL ') for line in text.splitlines() if line.startswith('BUILD43_COMPILED_MODEL ')]
    model = json.loads(markers[0]) if len(markers) == 1 else {}
    verification = {'tested_sha': SOURCE, 'compiled_apk_model': model, 'exit_code': run.returncode,
        'errors': errors, 'apk_sha256': sha(apk), 'compiled_payload_sha256': sha(payload),
        'harness_sha256': sha(harness), 'log_sha256': sha(log), 'cwd_is_empty_host': True,
        'engine_sha256': sha(ENGINE), 'physical_Android': False, 'listening_verified': False,
        'signing_performed': False, 'installable_update': False}
    save(WORK / 'verification.json', verification)
    assert run.returncode == 0 and not errors and model.get('compiled_payload') is True and not model.get('failures') and model.get('checks', 0) >= 91, verification
    assert not list(WORK.rglob('*.keystore')) and not list(WORK.rglob('*.jks'))
    print(json.dumps({'unsigned_APK': apk.name, 'bytes': apk.stat().st_size, 'sha256': sha(apk),
                      'compiled_checks': model['checks'], 'installable_update': False}), flush=True)


if __name__ == '__main__':
    main()
