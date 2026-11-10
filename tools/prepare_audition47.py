#!/usr/bin/env python3
"""Bounded private cuts: Tom's two unused guitar phrases; Nina review candidates.

Never imports Nina into the game or claims listening acceptance. Existing clips
are retained. Source hashes and frame offsets come from the original intake.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / 'experiments/playable_flightcase/audio'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def excerpt(source, target, start, frames):
    if target.exists():
        raise FileExistsError(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    seconds = frames / 48000
    subprocess.run(['ffmpeg', '-v', 'error', '-n', '-i', str(source),
                    '-af', f'atrim=start_sample={start}:end_sample={start+frames},'
                    f'asetpts=PTS-STARTPTS,afade=t=in:d=0.015,'
                    f'afade=t=out:st={seconds-.06:.6f}:d=0.06',
                    '-c:a', 'libvorbis' if target.suffix == '.ogg' else 'libmp3lame',
                    '-q:a', '5' if target.suffix == '.ogg' else '2', str(target)], check=True)
    return {'path': str(target), 'sha256': digest(target),
            'source_sha256': digest(source), 'source_start_frame': start,
            'frames': frames, 'sample_rate': 48000, 'listening_verified': False,
            'owner_listening_accepted': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--guitar', type=Path, required=True)
    parser.add_argument('--vocals', type=Path, required=True)
    parser.add_argument('--backing', type=Path, required=True)
    parser.add_argument('--review-output', type=Path, required=True)
    parser.add_argument('--apply-tom', action='store_true')
    args = parser.parse_args()
    registry_path = AUDIO / 'character_indie29/manifest.json'
    registry = json.loads(registry_path.read_text())
    foundations = json.loads((AUDIO / 'recorded_indie29/manifest.json').read_text())
    source_hash = digest(args.guitar)
    assert any(row['name'] == args.guitar.name and row['sha256'] == source_hash
               for row in foundations['sources']), 'Guitar must match original source receipt'
    assert digest(args.vocals) == '1892ece982dcc23b33abccfaf5acf9b734d041ff851a6883675734d845931ea6'
    assert digest(args.backing) == 'a9f4fc53ca671dbcc117c99a4085cb9e9c76347f7faff5a9d96a81fba4a45193'
    assert 'cast_tom' not in registry['characters'], 'Retain an already prepared bank'
    args.review_output.mkdir(parents=True, exist_ok=True)
    receipt = {'schema_version': 1, 'provenance': 'Owner-supplied AI-generated Suno stems',
               'listening_verified': False, 'Nina_integrated': False, 'clips': []}
    material_ids = []
    for index, hook in enumerate(['indie29_guitar90_05', 'indie29_guitar90_06'], 1):
        phrase = foundations['entries'][hook]
        material = f'cast_tom_audition47_{index}'
        target = AUDIO / 'character_indie29' / (material + '.ogg')
        row = excerpt(args.guitar, target, phrase['source_start_frame'], phrase['frames'])
        row.update({'path': 'res://' + str(target.relative_to(ROOT)),
                    'integration_review_accepted': True,
                    'integration_authority': 'owner_request_20261109',
                    'description': 'Independent recorded idea, not a response to the written exercise.',
                    'source_hook': hook})
        registry['materials'][material] = row
        material_ids.append(material)
        receipt['clips'].append(row)
    registry['characters']['cast_tom'] = {
        'role': 'Guitarist', 'materials': material_ids,
        'fit': 'Thoughtful supporting guitar: two unused phrases from the retained guitar source. Editorial assignment; listening fit unverified.'}
    for name, source, start, end in [
        ('Last-Bus-Gone-quiet-verse', args.vocals, 9.0, 17.1),
        ('Last-Bus-Gone-later-verse', args.vocals, 61.1, 67.1),
        ('Last-Bus-Gone-chorus-comparison', args.vocals, 30.3, 39.0),
        ('Last-Bus-Gone-harmony', args.backing, 62.3, 69.5),
    ]:
        row = excerpt(source, args.review_output / (name + '.mp3'), round(start*48000), round((end-start)*48000))
        row['candidate_for'] = 'Nina review only; no character identity or fit inferred from waveform'
        receipt['clips'].append(row)
    if args.apply_tom:
        registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    (args.review_output / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps({'Tom_applied': args.apply_tom, 'Nina_integrated': False,
                      'clips': len(receipt['clips']), 'listening_verified': False}))


if __name__ == '__main__':
    main()
