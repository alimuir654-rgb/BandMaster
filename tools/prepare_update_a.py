#!/usr/bin/env python3
"""Stage a private unsigned Update A candidate. No key generation/signing/network.

Requires existing verified private media and an existing debug-keystore path only
to prevent Godot's automatic editor-setup fallback. That key is never used to sign.
A guarded JDK refuses keytool/jarsigner and Java signing/generation invocations.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--media-source', type=Path, required=True)
    parser.add_argument('--existing-debug-path', type=Path, required=True)
    parser.add_argument('--version-code', type=int, default=21)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    out = args.output.resolve()
    assert not out.exists() and args.version_code > 20
    assert args.existing_debug_path.is_file(), 'STOP: editor fallback must not generate a key'
    assert shutil.disk_usage(out.parent).free > 2 * 1024**3
    bank_root = Path('experiments/playable_flightcase/audio')
    media = {}
    for manifest in sorted((repo / bank_root).glob('*/manifest.json')):
        source_manifest = args.media_source / manifest.relative_to(repo)
        assert digest(manifest) == digest(source_manifest), 'private media manifest differs from source'
        data = json.loads(manifest.read_text())
        for entry in data['entries'].values():
            for part in entry['parts'].values():
                relative = part['path'].removeprefix('res://')
                assert relative.endswith('.wav') and Path(relative).is_relative_to(bank_root)
                source = args.media_source / relative
                assert digest(source) == part['sha256'], relative
                media[relative] = part['sha256']
    assert len(media) == 80, 'STOP: original80 verified assets required'
    subprocess.run([sys.executable, str(repo / 'tools/build_recorded_owner.py'), '--output', str(out),
                    '--version-code', str(args.version_code), '--version-name', '0.151.0-playtest-bandlife'], check=True)
    project = out / 'project'
    manifest_path = out / 'SOURCE_MANIFEST.json'
    manifest = json.loads(manifest_path.read_text())
    assert manifest['version_code'] == args.version_code
    for relative, sha in media.items():
        target = project / relative
        assert not target.exists()
        shutil.copy2(args.media_source / relative, target)
        target.with_name(target.name + '.import').write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
        assert digest(target) == sha
        manifest['files'].append(dict(path=relative, sha256=sha))
    manifest['files'].sort(key=lambda row: row['path'])
    manifest['private_media'] = dict(count=80, existing_review_only=True, originals_modified=False,
        provenance='AI-generated Suno; owner reports paid-plan generation', commercial_game_licensing='unresolved')
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    config = out / 'config/godot';config.mkdir(parents=True)
    data = out / 'data/godot';data.mkdir(parents=True)
    templates = Path('/workspace/.local/share/godot/export_templates')
    assert templates.is_dir()
    (data / 'export_templates').symlink_to(templates, target_is_directory=True)
    jdk = out / 'guarded-jdk/bin';jdk.mkdir(parents=True)
    real_java = Path('/usr/lib/jvm/java-21-openjdk-amd64/bin/java');assert real_java.is_file()
    deny = '#!/bin/sh\nprintf "%s\\n" "STOP: key/signing operation forbidden in unsigned export" >&2\nexit 97\n'
    for name in ['keytool', 'jarsigner']:
        script = jdk / name;script.write_text(deny);script.chmod(0o755)
    script = jdk / 'java'
    script.write_text('#!/usr/bin/env python3\nimport os,sys\nargs=sys.argv[1:]\nif any(x in args for x in ["-genkey","-genkeypair","-genseckey","sign"]):\n print("STOP: signing/generation forbidden",file=sys.stderr);sys.exit(97)\nos.execv('+repr(str(real_java))+',["java"]+args)\n')
    script.chmod(0o755)
    # No private key bytes or passwords are read. This is an existing debug path
    # solely to suppress automatic setup; package/signed=false is authoritative.
    (config / 'editor_settings-4.7.tres').write_text('[gd_resource type="EditorSettings" format=3]\n[resource]\nexport/android/android_sdk_path = "/workspace/tools/android-sdk"\nexport/android/java_sdk_path = '+json.dumps(str(jdk.parent))+'\nexport/android/debug_keystore = '+json.dumps(str(args.existing_debug_path.resolve()))+'\n')
    assert 'package/signed=false' in (project / 'export_presets.cfg').read_text()
    print(json.dumps(dict(project=str(project), source=manifest['source_sha'], private_media_hashes_verified=80,
                         editor_existing_debug_path_verified=True, signing=False, key_generation_guard=True)))


if __name__ == '__main__':
    main()
