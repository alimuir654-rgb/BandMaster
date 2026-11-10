#!/usr/bin/env python3
"""Restore private legacy banks from verified original intake, using existing preparers.

No acquisition, generation, signing, original edits or old source patches.
The title Ogg is re-encoded; its tracked hash receipt is renewed truthfully.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / 'experiments/playable_flightcase/audio'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def protected():
    return {str(p.relative_to(AUDIO)): sha(p)
            for name in ['recorded_indie39', 'crowd37']
            for p in (AUDIO / name).rglob('*') if p.is_file()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--intake', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--steady-reference', type=Path, required=True)
    args = parser.parse_args()
    rows = json.loads(args.intake.read_text())
    originals = {row['name']: row for row in rows}
    assert len(rows) == len(originals) == 25
    for row in rows:
        assert Path(row['name']).name == row['name']
        assert sha(Path(row['local'])) == row['sha256']
    before = protected()
    assert before, 'Approved new source banks required'
    banks = ['recorded_steady_v1', 'recorded_steady_v2', 'recorded_rehearsal_v1',
             'recorded_dgad_v1', 'recorded_indie29', 'character_indie29', 'formation_next32']
    assert all(not (AUDIO / name).exists() for name in banks), 'Never replace a private bank'
    legacy_intake = Path('/workspace/indie-intake-20261109')
    assert not legacy_intake.exists(), 'Never replace historical source intake'
    with zipfile.ZipFile(args.steady_reference) as reference:
        old = json.loads(reference.read('source/experiments/playable_flightcase/audio/recorded_steady_v1/manifest.json'))
        for source in old['sources']:
            assert originals[source['name']]['sha256'] == source['sha256']

    def assessment(slug, title, roles):
        target = args.evidence / slug
        (target / 'originals').mkdir(parents=True, exist_ok=False)
        files = []
        for role in roles:
            name = title + ('' if role == 'Mix' else ' (' + role + ')') + '.wav'
            row = dict(originals[name], role=role)
            os.link(row['local'], target / 'originals' / name)
            files.append(row)
        (target / 'measurements.json').write_text(json.dumps({'files': files}, indent=2) + '\n')
        return target

    steady = assessment('steady', 'Steady Hundred', ['Mix', 'Guitar', 'Bass', 'Drums', 'Percussion'])
    rehearsal = assessment('rehearsal', 'Rehearsam Loop', ['Mix', 'Guitar', 'Bass', 'Drums'])
    dgad = assessment('dgad', 'D–G–A–D', ['Mix', 'Guitar', 'Bass', 'Drums'])
    (legacy_intake / 'originals').mkdir(parents=True)
    indie_rows = []
    for row in rows:
        if row['name'].startswith(('G–D–Em–C', 'Rehearsion Space', 'Rehearsal D Minor')):
            os.link(row['local'], legacy_intake / 'originals' / row['name'])
            indie_rows.append(row)
    assert len(indie_rows) == 12
    (legacy_intake / 'manifest.json').write_text(json.dumps(indie_rows, indent=2) + '\n')

    def run(name, script, *options):
        with (args.evidence / (name + '.log')).open('x') as log:
            subprocess.run([sys.executable, str(ROOT / 'tools' / script), *map(str, options)],
                           cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, check=True)
        print(name + ' complete', flush=True)

    for version in ['v1', 'v2']:
        run('steady-' + version, 'prepare_recorded_steady.py', '--assessment-dir', steady,
            '--output', AUDIO / ('recorded_steady_' + version), '--tone-profile', version)
    run('rehearsal', 'prepare_recorded_rehearsal.py', '--assessment-dir', rehearsal,
        '--output', AUDIO / 'recorded_rehearsal_v1')
    run('dgad', 'prepare_recorded_dgad.py', '--assessment-dir', dgad,
        '--output', AUDIO / 'recorded_dgad_v1', '--audition-output', args.evidence / 'unused-dgad-review')
    run('indie29', 'prepare_indie29.py')
    run('formation', 'prepare_next32_audio.py')
    with zipfile.ZipFile(args.steady_reference) as reference:
        for path in (AUDIO / 'recorded_steady_v1').glob('*.wav'):
            assert path.read_bytes() == reference.read('source/' + path.relative_to(ROOT).as_posix())
    assert protected() == before, 'Approved new vocals/crowd must stay byte-identical'
    for row in rows:
        assert sha(Path(row['local'])) == row['sha256']
    (args.evidence / 'restoration.json').write_text(json.dumps({
        'intake_sha256': sha(args.intake), 'originals_unchanged': True,
        'historical_steady_v1_WAVs_byte_identical': 10,
        'approved_new_banks_unchanged': before,
        'restored_banks': banks,
        'title_receipt': json.loads((AUDIO / 'splash_cue.json').read_text()),
        'source_scripts': {name: sha(ROOT / 'tools' / name) for name in [
            'prepare_recorded_steady.py', 'prepare_recorded_rehearsal.py',
            'prepare_recorded_dgad.py', 'prepare_indie29.py', 'prepare_next32_audio.py']}
    }, indent=2) + '\n')


if __name__ == '__main__':
    main()
