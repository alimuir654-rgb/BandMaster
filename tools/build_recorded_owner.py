#!/usr/bin/env python3
"""Prepare the existing Playtest entry and dependency closure in an isolated directory.

Never generates a signing key. The prepared project exports an UNSIGNED APK.
Sign only with the retained original owner key in the original build environment.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

ENTRY = 'experiments/playable_flightcase/opening.tscn'
APP = 'com.bandmaster.ownerplaytest.s40'
CERT = '83c797fe8db043b49ebdc705a3ca7a0326db19d0b9bf613c8cb1db1ea0c3cbf2'
PROJECT = '''config_version=5
[application]
config/name="BandMaster Playtest"
config/icon="res://icon.svg"
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
[threading]
worker_pool/max_threads=2
[input_devices]
pointing/emulate_mouse_from_touch=true
pointing/emulate_touch_from_mouse=false
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--version-code', type=int, default=17)
    parser.add_argument('--version-name', default='0.147.0-playtest-audio')
    parser.add_argument('--baseline', help='Optional Git source for controlled legacy comparison')
    args = parser.parse_args()
    assert args.version_code > 16
    repo = Path(__file__).resolve().parents[1]
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    project = out / 'project'
    project.mkdir()
    files, queue = {}, [ENTRY, 'icon.svg']
    # Dynamic asset paths (cast portraits, atlases and manifests) remain unchanged.
    for folder in ['experiments/playable_flightcase', 'experiments/character_cast', 'components', 'Data', 'Art']:
        for path in (repo / folder).rglob('*'):
            if path.is_file() and path.suffix not in ['.gd', '.tscn', '.tres', '.uid', '.import', '.md'] and '.godot' not in path.parts:
                queue.append(path.relative_to(repo).as_posix())
    if not args.baseline:
        queue += [p.relative_to(repo).as_posix() for p in (repo / 'tests').glob('recorded_steady*.gd')]
        queue += [p.relative_to(repo).as_posix() for p in (repo / 'tests').glob('audio_creation*.gd')]
        queue.append('tests/poster_feedback_visual.gd')
    while queue:
        relative = queue.pop()
        if relative in files:
            continue
        path = repo / relative
        if not path.is_file():
            continue  # Prefix literals are not dependency filenames.
        data = path.read_bytes()
        if args.baseline and path.suffix in ['.gd', '.tscn']:
            old = subprocess.run(['git', 'show', args.baseline + ':' + relative], cwd=repo, capture_output=True)
            if old.returncode == 0:
                data = old.stdout
        files[relative] = hashlib.sha256(data).hexdigest()
        target = project / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        if path.suffix in ['.gd', '.tscn', '.tres', '.json']:
            for ref in re.findall(r'res://([^\s"\'<>]+)', data.decode('utf-8')):
                if (repo / ref).is_file():
                    queue.append(ref)
        if path.suffix == '.wav':
            # Keep every source frame; import must not trim, normalize, loop or compress.
            (target.parent / (target.name + '.import')).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
    project_text = PROJECT.replace('config/name="BandMaster Playtest"',
                                   'config/name="BandMaster Playtest"\nconfig/version=' + json.dumps(args.version_name) +
                                   '\nconfig/build_number=' + str(args.version_code))
    (project / 'project.godot').write_text(project_text)
    (project / 'export_presets.cfg').write_text('''[preset.0]
name="Owner Android Unsigned"
platform="Android"
runnable=true
export_filter="all_resources"
include_filter="*.json,*.csv,*.txt"
exclude_filter="tests/*,SOURCE_MANIFEST.json"
script_export_mode=2
[preset.0.options]
gradle_build/use_gradle_build=false
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
version/code=VERSION
version/name=VERSION_NAME
package/unique_name="com.bandmaster.ownerplaytest.s40"
package/name="BandMaster Playtest"
package/signed=false
package/show_as_launcher_app=true
screen/immersive_mode=true
screen/edge_to_edge=false
user_data_backup/allow=false
permissions/internet=false
permissions/read_external_storage=false
permissions/write_external_storage=false
permissions/record_audio=false
permissions/camera=false
'''.replace('VERSION_NAME', json.dumps(args.version_name)).replace('VERSION', str(args.version_code)))
    manifest = dict(source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip(),
                    baseline=args.baseline, application_id=APP, version_code=args.version_code, version_name=args.version_name,
                    save_directory='BandMasterOwnerPlaytestS40', entry=ENTRY, original_certificate_sha256=CERT,
                    signing='UNSIGNED; original key required; never use a replacement key',
                    files=[dict(path=p, sha256=h) for p, h in sorted(files.items())])
    (out / 'SOURCE_MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(dict(project=str(project), files=len(files), source_bytes=sum((project / f).stat().st_size for f in files), signing=manifest['signing'])))


if __name__ == '__main__':
    main()
