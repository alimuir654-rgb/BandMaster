#!/usr/bin/env python3
"""Verify the complete real uploaded bank and the existing release guard."""
import argparse
from array import array
import importlib.util
import json
import math
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def module(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def decoded(path):
    samples = array('f')
    samples.frombytes(subprocess.check_output(['ffmpeg', '-v', 'error', '-nostdin',
        '-i', str(path), '-ac', '1', '-ar', '24000', '-f', 'f32le', '-']))
    return samples


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--sources', type=Path, required=True)
    args = parser.parse_args()
    crowd = module('crowd40_prepare', 'tools/prepare_crowd37.py')
    build = module('crowd40_build', 'tools/build_recorded_owner.py')
    expected = {'entrance': '2479', 'song': '2486', 'courtesy': '3521', 'cheer': '35748'}
    checks = 0

    def check(value):
        global checks
        assert value
        checks += 1

    original = {p.name: crowd.sha(p) for p in args.sources.glob('*.mp3')}
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        prepared = root / 'prepared'
        manifest = crowd.prepare(args.sources, prepared)
        check(manifest['complete'] is True and manifest['missing_sources'] == [])
        check(set(manifest['effects']) == set(expected))
        check(manifest['boo_approved'] is False and manifest['derivative_mix_listening_verified'] is False)
        for cue, identity in expected.items():
            row = manifest['effects'][cue]
            check(row['source_id'] == identity)
            check(row['source_start_seconds'] == crowd.catalog()[identity].get('source_start_seconds', 0))
            check(row['source_sha256'] == original[identity + '.mp3'] == crowd.catalog()[identity]['source_sha256'])
            check(row['sha256'] == crowd.sha(prepared / (cue + '.ogg')))
            rms, peak = crowd.levels(prepared / (cue + '.ogg'), row['duration_seconds'])
            check(rms > -80 and peak <= -2.5)
            # Independently slice the complete original PCM. This catches a
            # valid-length file whose fades ran on the wrong source timeline.
            original_pcm = decoded(args.sources / (identity + '.mp3'))
            output_pcm = decoded(prepared / (cue + '.ogg'))
            start = round(row['source_start_seconds'] * 24000)
            low, high = 4800, round((row['duration_seconds'] - 0.3) * 24000)
            expected_pcm = original_pcm[start + low:start + high]
            actual_pcm = output_pcm[low:high]
            check(len(expected_pcm) == len(actual_pcm) and len(actual_pcm) > 0)
            norm = math.sqrt(sum(x*x for x in expected_pcm) * sum(x*x for x in actual_pcm))
            correlation = sum(x*y for x, y in zip(expected_pcm, actual_pcm)) / norm if norm else 0
            check(correlation > 0.9)
            check(row['license'] == ('CC-BY-4.0' if cue == 'cheer' else 'CC0-1.0'))
        check(len({r['source_sha256'] for r in manifest['effects'].values()}) == 4)
        check({p.name: crowd.sha(p) for p in args.sources.glob('*.mp3')} == original)
        registered = crowd.catalog
        for offset in [-1, float('nan'), 9999]:
            broken_rows = registered()
            broken_rows['3521']['source_start_seconds'] = offset
            crowd.catalog = lambda: broken_rows
            rejected = root / ('bad-offset-' + str(checks))
            try:
                crowd.prepare(args.sources, rejected)
                raise AssertionError('Invalid source excerpt accepted')
            except ValueError:
                check(not rejected.exists())
        crowd.catalog = registered
        bank = root / 'experiments/playable_flightcase/audio/crowd37'
        bank.parent.mkdir(parents=True)
        shutil.copytree(prepared, bank)
        shutil.copy2(ROOT / 'experiments/playable_flightcase/audio/crowd37_credits.txt', bank.parent)
        shutil.copy2(ROOT / 'experiments/playable_flightcase/gig_soundscape.gd', bank.parents[1])
        build.crowd_preflight(root, 24)
        check(True)

        def refused(version):
            try:
                build.crowd_preflight(root, version)
            except ValueError:
                return True
            return False

        check(refused(23))
        path = bank / 'manifest.json'
        for change in ['complete', 'source_id', 'sha256', 'owner_source_listening_accepted', 'attribution_sha256']:
            broken = json.loads(json.dumps(manifest))
            if change == 'complete':
                broken['complete'] = False
            else:
                broken['effects']['cheer'][change] = False if change == 'owner_source_listening_accepted' else 'invalid'
            path.write_text(json.dumps(broken))
            check(refused(24))
        check({p.name: crowd.sha(p) for p in args.sources.glob('*.mp3')} == original)
    print(json.dumps({'checks': checks, 'failures': [], 'complete_real_bank': True, 'listening': False}))
