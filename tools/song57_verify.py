#!/usr/bin/env python3
"""Exact-source craft/legacy proof in isolated Godot; no export or owner saves.

The baseline exports genuine old receipts. The candidate must accept those exact
receipts and satisfy skill monotonicity. Neither image nor listening proof is claimed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

from song55_verify import ENGINE_SHA, environment, signing_guard, write_json

TEST = 'tests/song57_craft_fairness.gd'
PROJECT = '''config_version=5
[application]
config/name="BandMaster SONG57 isolated models"
config/use_custom_user_dir=true
config/custom_user_dir_name="BandMasterSONG57IsolatedQA"
[rendering]
renderer/rendering_method="gl_compatibility"
[threading]
worker_pool/max_threads=2
'''


def git(repo: Path, *args: str) -> bytes:
    return subprocess.check_output(['git', *args], cwd=repo)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def materialize(repo: Path, dest: Path, ref: str, candidate: bool) -> dict:
    inventory = set(git(repo, 'ls-tree', '-r', '--name-only', ref).decode().splitlines())
    inventory.add(TEST)
    queue = [TEST]
    files = {}
    dest.mkdir(parents=True)
    while queue:
        path = queue.pop()
        if path in files:
            continue
        if Path(path).is_absolute() or '..' in Path(path).parts:
            raise RuntimeError('Unsafe resource path: ' + path)
        local = repo / path
        raw = local.read_bytes() if path == TEST or (candidate and local.is_file()) else git(repo, 'show', ref + ':' + path)
        target = dest / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        files[path] = digest(raw)
        if Path(path).suffix in {'.gd', '.tscn', '.tres', '.json'}:
            source = raw.decode()
            preloads = set(re.findall(r'preload\(["\']res://([^"\']+)["\']\)', source))
            for resource in re.findall(r'res://([^\s\"\'<>]+)', source):
                required = Path(resource).suffix in {'.gd', '.json', '.tscn', '.tres'} or resource in preloads
                if required and resource in inventory and resource not in files:
                    if Path(resource).suffix.lower() in {'.apk', '.jks', '.keystore', '.zip'}:
                        raise RuntimeError('Forbidden proof dependency: ' + resource)
                    queue.append(resource)
    (dest / 'project.godot').write_text(PROJECT)
    return {'ref': ref, 'candidate_working_source': candidate, 'files': files,
            'project_sha256': digest(PROJECT.encode()), 'no_export_preset': True}


def invoke(work: Path, engine: Path, variant: str, label: str, args: list[str], expected: int = 0) -> dict:
    project = work / variant / 'project'
    command = [str(engine), '--headless', '--path', str(project), '--audio-driver', 'Dummy',
               '--script', 'res://' + TEST, '--', '--work-root=' + str(work), *args]
    log = work / 'logs' / (label + '.log')
    with log.open('x') as stream:
        proc = subprocess.run(command, cwd=work, env=environment(work, variant),
                              stdout=stream, stderr=subprocess.STDOUT, timeout=180)
    text = log.read_text()
    errors = [line for line in text.splitlines() if 'SCRIPT ERROR' in line or 'ERROR:' in line]
    lines = [line.removeprefix('SONG57_RESULT ') for line in text.splitlines() if line.startswith('SONG57_RESULT ')]
    result = json.loads(lines[-1]) if lines else {}
    receipt = {'exit_code': proc.returncode, 'expected_exit_code': expected, 'errors': errors,
               'result': result, 'log': str(log), 'log_sha256': digest(log.read_bytes())}
    write_json(work / 'logs' / (label + '.json'), receipt)
    if proc.returncode != expected or errors or not result:
        raise RuntimeError('Model command failed: ' + json.dumps(receipt))
    if expected == 0 and not result.get('ok'):
        raise RuntimeError('Model assertions failed: ' + json.dumps(receipt))
    if expected == 1 and (result.get('ok') or result.get('monotonic_failures', 0) <= 0):
        raise RuntimeError('Old-source negative control did not detect the actual unfairness')
    print(label + ' verified', flush=True)
    return receipt


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path.cwd())
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--baseline', required=True)
    parser.add_argument('--work', type=Path, required=True)
    args = parser.parse_args()
    repo, engine, work = args.repo.resolve(), args.godot.resolve(), args.work.resolve()
    if work.exists() or work == repo or work.is_relative_to(repo):
        raise RuntimeError('Use a fresh proof directory outside the repository')
    if digest(engine.read_bytes()) != ENGINE_SHA:
        raise RuntimeError('Godot executable differs from pinned 4.7.2')
    head = git(repo, 'rev-parse', 'HEAD').decode().strip()
    baseline = git(repo, 'rev-parse', args.baseline + '^{commit}').decode().strip()
    work.mkdir(parents=True)
    (work / 'logs').mkdir()
    (work / 'results').mkdir()
    report = {'head': head, 'baseline': baseline, 'engine_sha256': ENGINE_SHA,
              'projects': {}, 'runs': {}, 'claims': {'native_pixels': False,
              'listening': False, 'APK': False, 'production_save_writes': False}}
    for variant, ref in [('baseline', baseline), ('candidate', head)]:
        report['projects'][variant] = materialize(repo, work / variant / 'project', ref, variant == 'candidate')
    write_json(work / 'RUN.json', report)
    fixtures = work / 'results' / 'legacy_receipts.json'
    report['runs']['legacy_export'] = invoke(work, engine, 'baseline', 'legacy-export', ['--export-legacy=' + str(fixtures)])
    report['legacy_fixture_sha256'] = digest(fixtures.read_bytes())
    write_json(work / 'RUN.json', report)
    report['runs']['negative_control'] = invoke(work, engine, 'baseline', 'old-source-negative', ['--fairness-only'], expected=1)
    write_json(work / 'RUN.json', report)
    report['runs']['candidate'] = invoke(work, engine, 'candidate', 'candidate', ['--legacy=' + str(fixtures)])
    report['signing_guard'] = signing_guard(work, 'final')
    write_json(work / 'RUN.json', report)
    print(json.dumps({'work': str(work), 'head': head, 'baseline': baseline,
                      'candidate': report['runs']['candidate']['result'],
                      'old_source_fairness_failures': report['runs']['negative_control']['result']['monotonic_failures'],
                      'legacy_fixture_sha256': report['legacy_fixture_sha256']}))


if __name__ == '__main__':
    main()
