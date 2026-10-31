#!/usr/bin/env python3
"""Build an isolated, test-key-signed Android APK from a verified checkpoint ZIP."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import os
import re
import subprocess
import zipfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--checkpoint', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--engine', required=True, type=Path)
    parser.add_argument('--template', required=True, type=Path)
    parser.add_argument('--sdk', required=True, type=Path)
    parser.add_argument('--java', required=True, type=Path)
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    logs = out / 'logs'
    logs.mkdir()
    packaging = json.loads((args.checkpoint / 'packages/packaging.json').read_text())
    archive = Path(packaging['archives'][0]['path'])
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == packaging['archives'][0]['sha256']
    project = out / 'project'
    project.mkdir()
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert all(not Path(n).is_absolute() and '..' not in Path(n).parts for n in z.namelist())
        z.extractall(project)
    manifest = json.loads((project / 'SOURCE_MANIFEST.json').read_text())
    assert manifest['source_sha'] == packaging['source_sha']
    for row in manifest['source_files']:
        assert hashlib.sha256((project / row['path']).read_bytes()).hexdigest() == row['sha256'], row['path']
    env = os.environ.copy()
    env.update(XDG_DATA_HOME=str(out / 'userdata'), XDG_CONFIG_HOME=str(out / 'editor-config'),
               XDG_CACHE_HOME=str(out / 'cache'), JAVA_HOME=str(args.java),
               ANDROID_SDK_ROOT=str(args.sdk), BM_ANDROID_DEBUG_PASSWORD='android')
    steps = []
    receipt = {'game_source_sha': manifest['source_sha'], 'project_source_files': len(manifest['source_files']),
               'started_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
               'application_id': 'com.bandmaster.ownerplaytest.s40', 'steps': steps,
               'android_device_tested': False, 'owner_approved': False}

    def save():
        (out / 'build.json').write_text(json.dumps(receipt, indent=2) + '\n')

    def run(name, cmd, timeout=180):
        save()
        result = subprocess.run([str(x) for x in cmd], env=env, capture_output=True, text=True, timeout=timeout)
        text = result.stdout + result.stderr
        log = logs / (name + '.log')
        log.write_text(text)
        fatal = [line for line in text.splitlines() if re.search(r'SCRIPT ERROR|Parse Error|Failed to load', line)]
        step = {'step': name, 'exit_code': result.returncode, 'log': str(log),
                'error_lines': [line for line in text.splitlines() if 'ERROR:' in line],
                'fatal_script_errors': fatal, 'pass': result.returncode == 0 and not fatal}
        steps.append(step)
        save()
        print(json.dumps(step), flush=True)
        if not step['pass']:
            raise RuntimeError('STOP: failure preserved; no correction attempted: ' + name)
        return text

    keys = out / 'signing'
    keys.mkdir(mode=0o700)
    keystore = keys / 'owner-playtest.keystore'
    run('test-key', [args.java / 'bin/keytool', '-genkeypair', '-keystore', keystore,
                     '-storetype', 'JKS', '-alias', 'androiddebugkey', '-keyalg', 'RSA',
                     '-keysize', '2048', '-validity', '3650', '-dname',
                     'CN=BandMaster Owner Playtest,O=BandMaster,C=GB',
                     '-storepass:env', 'BM_ANDROID_DEBUG_PASSWORD',
                     '-keypass:env', 'BM_ANDROID_DEBUG_PASSWORD'])
    keystore.chmod(0o600)
    (project / 'project.godot').write_text('''config_version=5
[application]
config/name="BandMaster Playtest"
run/main_scene="res://experiments/playable_flightcase/opening.tscn"
config/use_custom_user_dir=true
config/custom_user_dir_name="BandMasterOwnerPlaytestS40"
[display]
window/size/viewport_width=390
window/size/viewport_height=844
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=1
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
[input_devices]
pointing/emulate_mouse_from_touch=true
pointing/emulate_touch_from_mouse=false
''')
    preset = '''[preset.0]
name="Owner Android"
platform="Android"
runnable=true
export_filter="all_resources"
include_filter="*.json,*.csv,*.txt"
exclude_filter="SOURCE_MANIFEST.json,REVIEW_README.txt"
script_export_mode=2
[preset.0.options]
custom_template/debug=TEMPLATE
gradle_build/use_gradle_build=false
architectures/armeabi-v7a=true
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
version/code=1
version/name="0.40.0-playtest"
package/unique_name="com.bandmaster.ownerplaytest.s40"
package/name="BandMaster Playtest"
package/signed=true
package/show_as_launcher_app=true
package/retain_data_on_uninstall=false
screen/immersive_mode=true
screen/edge_to_edge=false
user_data_backup/allow=false
permissions/internet=false
permissions/read_external_storage=false
permissions/write_external_storage=false
permissions/record_audio=false
permissions/camera=false
'''
    (project / 'export_presets.cfg').write_text(preset.replace('TEMPLATE', json.dumps(str(args.template))))
    config = out / 'editor-config/godot'
    config.mkdir(parents=True)
    settings = {'export/android/android_sdk_path': str(args.sdk),
                'export/android/java_sdk_path': str(args.java),
                'export/android/debug_keystore': str(keystore),
                'export/android/debug_keystore_user': 'androiddebugkey',
                'export/android/debug_keystore_pass': 'android'}
    (config / 'editor_settings-4.7.tres').write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' +
                                                  '\n'.join(k + '=' + json.dumps(v) for k, v in settings.items()) + '\n')
    receipt['android_project_sha256'] = hashlib.sha256((project / 'project.godot').read_bytes()).hexdigest()
    receipt['export_preset_sha256'] = hashlib.sha256((project / 'export_presets.cfg').read_bytes()).hexdigest()
    receipt['template_sha256'] = hashlib.sha256(args.template.read_bytes()).hexdigest()
    run('import', [args.engine, '--headless', '--path', project, '--editor', '--import'], 240)
    raw = out / 'exported.apk'
    run('export', [args.engine, '--headless', '--path', project, '--export-debug', 'Owner Android', raw], 300)
    tools = args.sdk / 'build-tools/36.0.0'
    aligned = out / 'aligned.apk'
    run('align', [tools / 'zipalign', '-P', '16', '-f', '4', raw, aligned])
    apk = out / 'BandMaster-Playtest.apk'
    run('sign', [tools / 'apksigner', 'sign', '--ks', keystore, '--ks-key-alias', 'androiddebugkey',
                 '--ks-pass', 'env:BM_ANDROID_DEBUG_PASSWORD', '--key-pass', 'env:BM_ANDROID_DEBUG_PASSWORD',
                 '--out', apk, aligned])
    cert = run('verify-signature', [tools / 'apksigner', 'verify', '--verbose', '--print-certs', apk])
    run('verify-alignment', [tools / 'zipalign', '-c', '-P', '16', '4', apk])
    badging = run('manifest', [tools / 'aapt', 'dump', 'badging', apk])
    permissions = run('permissions', [tools / 'aapt', 'dump', 'permissions', apk])
    with zipfile.ZipFile(apk) as z:
        assert z.testzip() is None
        names = z.namelist()
        abis = sorted({n.split('/')[1] for n in names if n.startswith('lib/') and n.endswith('.so')})
        assert abis == ['arm64-v8a', 'armeabi-v7a'], abis
        assert 'assets/Data/CharacterCast/approved_cast_2026-10-29.json' in names
        assert z.read('assets/Data/CharacterCast/approved_cast_2026-10-29.json') == (project / 'Data/CharacterCast/approved_cast_2026-10-29.json').read_bytes()
        assert 'classes.dex' in names and 'AndroidManifest.xml' in names
        assert any('project.binary' in n for n in names)
        (out / 'apk-entries.json').write_text(json.dumps(names, indent=2) + '\n')
    assert "name='com.bandmaster.ownerplaytest.s40'" in badging
    assert "application-label:'BandMaster Playtest'" in badging
    for permission in ['android.permission.INTERNET', 'android.permission.READ_EXTERNAL_STORAGE',
                       'android.permission.WRITE_EXTERNAL_STORAGE', 'android.permission.CAMERA',
                       'android.permission.RECORD_AUDIO']:
        assert permission not in permissions, permission
    for row in manifest['source_files']:
        if row['path'] != 'project.godot':
            assert hashlib.sha256((project / row['path']).read_bytes()).hexdigest() == row['sha256'], row['path']
    receipt.update(apk=str(apk), bytes=apk.stat().st_size, sha256=hashlib.sha256(apk.read_bytes()).hexdigest(),
                   abis=abis, apk_crc='PASS', signature='PASS', alignment_16kb='PASS',
                   cast_json_byte_identical=True, original_source_files_unchanged=True,
                   certificate_summary=cert.splitlines(), completed_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   pass_apk_checks=True, physical_phone_tested=False)
    save()
    print('OWNER_ANDROID_APK ' + json.dumps({k: receipt[k] for k in ['apk', 'bytes', 'sha256', 'abis', 'pass_apk_checks']}), flush=True)


if __name__ == '__main__':
    main()
