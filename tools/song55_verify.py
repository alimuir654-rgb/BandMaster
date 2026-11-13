#!/usr/bin/env python3
"""Isolated SONG55 verification runner; no export, signing, download or production save.

Early baseline example (the work directory MUST NOT already exist):
  python3 tools/song55_verify.py --repo /path/to/repo --godot /path/to/Godot \
      --work /new/qa-directory --baseline 8f222c8 --only baseline --profiles phone short

After inspecting early originals, use a new work directory for a changed candidate.
For unchanged source, --resume adds only missing profiles to this exact run.
The runner never claims that writing PNGs constitutes visual acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ENGINE_SHA = '8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e'
ENTRY = 'experiments/playable_flightcase/opening.tscn'
NATIVE = 'tests/song55_native.gd'
PURE = 'tests/song55_summary.gd'
RECORDING = 'experiments/playable_flightcase/recording_flow_test.gd'
PROFILES = {'phone': (390, 844), 'short': (1280, 720), 'tall': (720, 1280), 'wide': (1600, 900)}
ASSET_ROOTS = ('experiments/playable_flightcase', 'experiments/character_cast', 'components', 'Data', 'Art')
CODE = {'.gd', '.tscn', '.tres'}
IGNORE = {'.uid', '.import', '.md', '.py', '.pyc'}
AVAILABILITY_FIXTURE = '''
func _song55_prepare_writing() -> Dictionary:
 var situation = preload("res://experiments/playable_flightcase/situation_core.gd")
 var initial: Dictionary=situation.inspect_writing(model.game.career)
 if not initial.get("ok",false):return initial
 var start: int=int(model.game.career.tour_day)
 var deadline: int=int(initial.get("next_full_day",0))
 if deadline<start or deadline>start+14:return {"ok":false,"message":"No bounded full-band writing evening."}
 for _attempt in range(15):
  var view: Dictionary=situation.inspect_writing(model.game.career)
  if not view.get("ok",false):return view
  if view.get("can_write",false):return {"ok":true}
  var day: int=int(model.game.career.tour_day)
  if day>=deadline:return {"ok":false,"message":"Advertised full-band evening remained unavailable."}
  var attendance: Dictionary=situation.inspect_rehearsal(model.game.career)
  if not attendance.get("ok",false):return attendance
  var result: Dictionary=model.game.informal_practice(attendance.attendee_indices)
  if not result.get("ok",false):return result
  if int(model.game.career.tour_day)!=day+1:return {"ok":false,"message":"Original informal practice did not advance exactly one day."}
 return {"ok":false,"message":"Bounded QA availability preparation exhausted."}
'''
PROJECT = '''config_version=5
[application]
config/name="BandMaster SONG55 Isolated QA"
run/main_scene="res://experiments/playable_flightcase/opening.tscn"
config/icon="res://icon.svg"
config/use_custom_user_dir=true
config/custom_user_dir_name="BandMasterSONG55IsolatedQA"
[display]
window/size/viewport_width=390
window/size/viewport_height=844
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
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


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_json(path: Path, value) -> None:
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def git(repo: Path, *args: str) -> bytes:
    return subprocess.check_output(['git', *args], cwd=repo)


def copy_project(repo: Path, destination: Path, baseline: str | None, harness: Path, work: Path, models: bool) -> dict:
    """Opening closure plus existing dynamic art/data; no full checkout or APK files."""
    inventory = {p.relative_to(repo).as_posix() for root in ASSET_ROOTS
                 for p in (repo / root).rglob('*')
                 if p.is_file() and '.godot' not in p.parts and '.git' not in p.parts}
    baseline_paths = set(git(repo, 'ls-tree', '-r', '--name-only', baseline).decode().splitlines()) if baseline else set()
    queue = [ENTRY, 'icon.svg', NATIVE]
    queue.extend(p for p in inventory if Path(p).suffix not in CODE | IGNORE
                 and Path(p).name != 'export_presets.cfg'
                 and Path(p).suffix.lower() not in {'.apk', '.zip', '.jks', '.keystore'})
    if models:
        queue += [PURE, RECORDING]
    files, source_files, missing, transforms = {}, {}, set(), []
    destination.mkdir(parents=True, exist_ok=False)
    while queue:
        relative = queue.pop()
        if relative in files:
            continue
        path = repo / relative
        if relative == NATIVE:
            raw = harness.read_bytes()
        elif baseline and Path(relative).suffix in CODE:
            if relative not in baseline_paths:
                raise RuntimeError('Baseline dependency absent at pinned commit: ' + relative)
            raw = git(repo, 'show', baseline + ':' + relative)
        elif path.is_file():
            raw = path.read_bytes()
        else:
            raise RuntimeError('Required source absent: ' + relative)
        source_files[relative] = digest(raw)
        data = raw
        if relative == RECORDING:
            old = b'const SAFE := "/workspace/work/overnight-20261101/s54/"'
            if data.count(old) != 1:
                raise RuntimeError('Recording regression isolation guard changed; inspect before adapting')
            replacement = ('const SAFE := ' + json.dumps(str(work) + '/')).encode()
            data = data.replace(old, replacement, 1)
            transforms.append({'path': relative, 'change': 'scratch-only SAFE root replacement; all assertions unchanged'})
            marker = b'   if not step(model.game.write_session('
            if data.count(marker) != 1:
                raise RuntimeError('Legacy recording fixture changed; inspect before adapting availability')
            data = data.replace(marker, b'   if not step(_song55_prepare_writing(),"current-source writing availability"):return false\n' + marker, 1)
            data += AVAILABILITY_FIXTURE.encode()
            diagnostic = b'func step(result: Variant, label: String) -> bool:\n'
            data = data.replace(diagnostic, diagnostic + b' if result is Dictionary and not bool(result.get("ok",false)):print("SONG55_QA_SETUP_REJECTION "+JSON.stringify(result))\n', 1)
            transforms.append({'path': relative, 'change': 'scratch-only fixture preparation through original inspect_writing/informal_practice APIs, bounded by next_full_day and 14 days; returned-message diagnostics; protected models and all original recording assertions unchanged'})
        files[relative] = digest(data)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        if Path(relative).suffix in CODE | {'.json'}:
            source = data.decode('utf-8')
            for ref in re.findall(r'res://([^\s"\'<>]+)', source):
                # Prefix literals and formatted paths are not complete filenames.
                available = ref == NATIVE or (repo / ref).is_file() or (baseline and ref in baseline_paths)
                if available:
                    queue.append(ref)
                elif Path(ref).suffix in CODE and not any(c in ref for c in '%{}'):
                    missing.add(ref)
        if Path(relative).suffix.lower() == '.wav':
            target.with_name(target.name + '.import').write_text(
                '[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\n'
                'edit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
    (destination / 'project.godot').write_text(PROJECT)
    result = {'baseline': baseline, 'files': files, 'source_files': source_files,
              'project_sha256': digest(PROJECT.encode()), 'test_only_transforms': transforms,
              'unresolved_code_literals': sorted(missing),
              'source_bytes': sum((destination / p).stat().st_size for p in files),
              'no_export_preset': not (destination / 'export_presets.cfg').exists()}
    write_json(destination.parent / 'SOURCE_MANIFEST.json', result)
    return result


def environment(work: Path, identity: str) -> dict:
    base = work / 'environment' / identity
    for name in ('data', 'config/godot', 'cache', 'tmp', 'blocked-bin'):
        (base / name).mkdir(parents=True, exist_ok=True)
    for name in ('keytool', 'jarsigner'):
        tool = base / 'blocked-bin' / name
        tool.write_text('#!/bin/sh\necho "SONG55: signing and key generation are disabled" >&2\nexit 97\n')
        tool.chmod(0o755)
    # No Android export preset is copied. Guard external signing commands as well.
    return dict(os.environ, XDG_DATA_HOME=str(base / 'data'), XDG_CONFIG_HOME=str(base / 'config'),
                XDG_CACHE_HOME=str(base / 'cache'), TMPDIR=str(base / 'tmp'),
                PATH=str(base / 'blocked-bin') + os.pathsep + os.environ.get('PATH', ''),
                LIBGL_ALWAYS_SOFTWARE='1', GODOT_SILENCE_ROOT_WARNING='1')


def run(work: Path, name: str, command: list[str], env: dict, timeout: int = 180) -> dict:
    logfile = work / 'logs' / (name + '.log')
    logfile.parent.mkdir(exist_ok=True)
    if logfile.exists():
        raise RuntimeError('Refusing to overwrite evidence: ' + str(logfile))
    started = time.time()
    with logfile.open('x') as stream:
        process = subprocess.run(command, cwd=work, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
    lines = logfile.read_text(errors='replace').splitlines()
    errors = [line for line in lines if 'SCRIPT ERROR' in line or 'ERROR:' in line]
    result = {'name': name, 'exit_code': process.returncode, 'seconds': round(time.time() - started, 2),
              'log': str(logfile), 'errors': errors, 'pass': process.returncode == 0 and not errors}
    write_json(logfile.with_suffix('.result.json'), result)
    if not result['pass']:
        raise RuntimeError(json.dumps(result))
    print(name + ' PASS', flush=True)
    return result


def display_start(work: Path, env: dict):
    executable = shutil.which('Xorg')
    if not executable or not shutil.which('xdpyinfo'):
        raise RuntimeError('Native proof needs Xorg + dummy driver + xdpyinfo; none will be installed automatically')
    number = next((n for n in range(101, 130) if not Path(f'/tmp/.X{n}-lock').exists()
                   and not Path(f'/tmp/.X11-unix/X{n}').exists()), None)
    if number is None:
        raise RuntimeError('No free bounded QA display number')
    config = work / 'xorg.conf'
    if not config.exists():
        config.write_text('''Section "ServerFlags"
 Option "AutoAddDevices" "false"
 Option "AllowMouseOpenFail" "true"
EndSection
Section "Device"
 Identifier "SONG55Dummy"
 Driver "dummy"
 VideoRam 256000
EndSection
Section "Monitor"
 Identifier "SONG55Monitor"
 HorizSync 5.0-200.0
 VertRefresh 5.0-200.0
 Modeline "1920x1440" 234.0 1920 2048 2256 2600 1440 1441 1444 1500
EndSection
Section "Screen"
 Identifier "SONG55Screen"
 Device "SONG55Dummy"
 Monitor "SONG55Monitor"
 DefaultDepth 24
 SubSection "Display"
  Depth 24
  Modes "1920x1440"
  Virtual 1920 1440
 EndSubSection
EndSection
''')
    tag = f'xorg-{number}-{time.time_ns()}'
    stream = (work / 'logs' / (tag + '.stdout')).open('x')
    proc = subprocess.Popen([executable, f':{number}', '-noreset', '-nolisten', 'tcp',
                             '-config', str(config), '-logfile', str(work / 'logs' / (tag + '.log'))],
                            stdout=stream, stderr=subprocess.STDOUT, env=env)
    env = dict(env, DISPLAY=f':{number}')
    for _ in range(50):
        if proc.poll() is not None:
            stream.close()
            raise RuntimeError('Owned Xorg stopped before readiness: ' + tag)
        probe = subprocess.run(['xdpyinfo'], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3)
        if probe.returncode == 0:
            return proc, stream, env['DISPLAY']
        time.sleep(0.1)
    proc.terminate()
    proc.wait(timeout=10)
    stream.close()
    raise RuntimeError('Owned Xorg readiness deadline exceeded')


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    p.add_argument('--godot', type=Path, required=True)
    p.add_argument('--work', type=Path, required=True)
    p.add_argument('--baseline', required=True)
    p.add_argument('--only', choices=['baseline', 'candidate', 'both'], default='both')
    p.add_argument('--profiles', nargs='+', choices=list(PROFILES), default=['phone', 'short'])
    p.add_argument('--resume', action='store_true', help='Add missing profiles only when source and engine are unchanged')
    p.add_argument('--native-only', action='store_true', help='Run native proof only; report model checks as not run')
    p.add_argument('--models-only', action='store_true', help='Run import, native-script parse and model checks; do not start a display or claim native proof')
    p.add_argument('--prepare-only', action='store_true', help='Curate and bind sources without invoking Godot or Xorg')
    p.add_argument('--harness', type=Path, default=Path(__file__).resolve().parents[1] / NATIVE)
    a = p.parse_args()
    if a.models_only and (a.native_only or a.only == 'baseline'):
        p.error('--models-only requires the candidate and cannot be combined with --native-only')
    repo, work, engine = a.repo.resolve(), a.work.resolve(), a.godot.resolve()
    if work == repo or repo in work.parents or str(work) in ('/', '/tmp', '/workspace'):
        raise RuntimeError('Work must be a dedicated directory outside the Git checkout')
    if digest(engine.read_bytes()) != ENGINE_SHA:
        raise RuntimeError('Engine bytes differ from verified official Godot 4.7.2; no execution performed')
    baseline = git(repo, 'rev-parse', '--verify', a.baseline + '^{commit}').decode().strip()
    head = git(repo, 'rev-parse', 'HEAD').decode().strip()
    variants = ['baseline', 'candidate'] if a.only == 'both' else [a.only]
    models = 'candidate' in variants and not a.native_only
    if a.resume:
        manifest = json.loads((work / 'RUN.json').read_text())
        if manifest['repo'] != str(repo) or manifest['head'] != head or manifest['baseline'] != baseline or manifest['engine_sha256'] != ENGINE_SHA:
            raise RuntimeError('Resume requires exact original repo/head/baseline/engine')
        for variant in variants:
            prior = manifest['projects'][variant]
            for relative, expected in prior['source_files'].items():
                if variant == 'baseline' and Path(relative).suffix in CODE and relative != NATIVE:
                    data = git(repo, 'show', baseline + ':' + relative)
                else:
                    data = a.harness.read_bytes() if relative == NATIVE else (repo / relative).read_bytes()
                if digest(data) != expected:
                    raise RuntimeError('Source changed since this run; use fresh --work: ' + relative)
    else:
        work.mkdir(parents=True, exist_ok=False)
        (work / 'logs').mkdir()
        manifest = {'schema': 1, 'repo': str(repo), 'head': head, 'baseline': baseline,
                    'engine': str(engine), 'engine_sha256': ENGINE_SHA, 'projects': {}, 'runs': {},
                    'claims': {'APK': False, 'audio_listening': False, 'physical_phone': False,
                               'visual_acceptance': False, 'fixture_is_explicit_QA_setup': True}}
        for variant in variants:
            manifest['projects'][variant] = copy_project(repo, work / variant / 'project',
                baseline if variant == 'baseline' else None, a.harness, work, models and variant == 'candidate')
        write_json(work / 'RUN.json', manifest)
    if a.prepare_only:
        print(json.dumps({'prepared': str(work), 'variants': variants, 'engine_invoked': False}))
        return
    for variant in variants:
        project = work / variant / 'project'
        tag = variant + '-import'
        if tag not in manifest['runs']:
            manifest['runs'][tag] = run(work, tag, [str(engine), '--headless', '--editor', '--path', str(project), '--import'], environment(work, tag), 240)
            write_json(work / 'RUN.json', manifest)
    if models:
        for label, script in [('native-parse', NATIVE), ('summary', PURE), ('recording', RECORDING)]:
            tag = 'model-' + label
            if tag in manifest['runs']:
                continue
            out = work / 'results' / tag
            out.mkdir(parents=True)
            command = [str(engine), '--headless', '--path', str(work / 'candidate/project'),
                '--audio-driver', 'Dummy', '--script', 'res://' + script]
            if label == 'native-parse':
                command.append('--check-only')
            command += ['--', '--out=' + str(out), '--work-root=' + str(work)]
            manifest['runs'][tag] = run(work, tag, command, environment(work, tag))
            write_json(work / 'RUN.json', manifest)
    if a.models_only:
        if any(work.rglob('*.keystore')) or any(work.rglob('*.jks')):
            raise RuntimeError('Unexpected signing material in isolated proof; retain evidence and inspect')
        print(json.dumps({'work': str(work), 'receipt': str(work / 'RUN.json'),
                          'completed': sorted(manifest['runs']), 'native_not_run': True}))
        return
    proc, stream, display = display_start(work, environment(work, 'display'))
    try:
        # Both early profiles precede tall/wide, irrespective of caller ordering.
        profiles = [name for name in PROFILES if name in a.profiles]
        for variant in variants:
            for profile in profiles:
                tag = variant + '-' + profile
                if tag in manifest['runs']:
                    continue
                width, height = PROFILES[profile]
                out = work / 'results' / tag
                out.mkdir(parents=True)
                env = dict(environment(work, tag), DISPLAY=display)
                command = [str(engine), '--path', str(work / variant / 'project'), '--resolution', f'{width}x{height}',
                    '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--script', 'res://' + NATIVE,
                    '--', '--out=' + str(out), '--work-root=' + str(work)]
                if variant == 'baseline':
                    command.append('--baseline')
                result = run(work, tag, command, env)
                receipt = json.loads((out / 'result.json').read_text())
                if not receipt.get('pass') or receipt.get('viewport') != [width, height]:
                    raise RuntimeError('Native receipt failure/dimensions: ' + tag)
                for item in receipt['images']:
                    path = Path(item['path'])
                    if not path.is_file() or path.stat().st_size < 1000:
                        raise RuntimeError('Missing or implausibly empty original image: ' + str(path))
                    item['sha256'] = digest(path.read_bytes())
                result['receipt'] = receipt
                manifest['runs'][tag] = result
                write_json(work / 'RUN.json', manifest)
    finally:
        proc.terminate()
        proc.wait(timeout=10)
        stream.close()
    if any(work.rglob('*.keystore')) or any(work.rglob('*.jks')):
        raise RuntimeError('Unexpected signing material in isolated proof; retain evidence and inspect')
    print(json.dumps({'work': str(work), 'receipt': str(work / 'RUN.json'),
                      'completed': sorted(manifest['runs']), 'visual_review_required': True}))


if __name__ == '__main__':
    main()
