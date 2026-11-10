#!/usr/bin/env python3
"""Prepare private CC0 crowd candidates. Never marks unheard clips accepted.

Inputs are the exact official low-quality previews documented in CROWD33.
No network, owner music, key access, or APK operations. Outputs must not exist.
Listening acceptance is a separate review, not an encoder option.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

SOURCES = {
    'applause': ('14761403bd0e967e2c5aa33a4851b0048cfc9ca1def51098278c91246b58a134',
                 'https://cdn.freesound.org/previews/858/858309_770193-lq.mp3',
                 'https://freesound.org/people/miuziqa/sounds/858309/', 'miuziqa'),
    'boo': ('8e1cac3c11ea2055fe9bea7f83c91a25e3075e60f3235092a1a1ba4a6d5a1e7f',
            'https://cdn.freesound.org/previews/504/504621_7704891-lq.mp3',
            'https://beta.freesound.org/people/NeoSpica/sounds/504621/', 'NeoSpica'),
}
# Existing runtime fade peaks for 1.5 seconds then fades away. Keep clips short;
# do not loop applause or mistake the 48-second source for a suitable one-shot.
CUES = {'entrance': ('applause', 0.0, 3.0), 'song': ('applause', 0.0, 2.8),
        'courtesy': ('applause', 0.0, 2.8), 'cheer': ('applause', 0.0, 3.2),
        'boo': ('boo', 0.0, 3.2)}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(applause, boo, output):
    inputs = {'applause': applause, 'boo': boo}
    # Validate everything before creating output; fail closed on changed CDN bytes.
    for key, path in inputs.items():
        if sha(path) != SOURCES[key][0]:
            raise ValueError('Unexpected source bytes: ' + key)
    output.mkdir(parents=True, exist_ok=False)
    manifest = {'schema_version': 1, 'content_version': 'crowd34',
                'batch': 'CROWD36', 'listening_verified': False,
                'release_status': 'HELD_PENDING_LISTENING_AND_FIT', 'effects': {}}
    for cue, (source, start, duration) in CUES.items():
        target = output / (cue + '.ogg')
        gain = -18 if source == 'boo' else -6
        # Preserve preview rate (24kHz), avoid claiming original 48kHz WAV quality.
        subprocess.run(['ffmpeg', '-v', 'error', '-nostdin', '-n', '-i', str(inputs[source]),
                        '-ss', str(start), '-t', str(duration), '-vn', '-ar', '24000',
                        '-ac', '2', '-af', f'volume={gain}dB,afade=t=in:d=0.04,afade=t=out:st={duration-0.15}:d=0.15',
                        '-c:a', 'libvorbis', '-q:a', '5', '-map_metadata', '-1', str(target)], check=True)
        digest, url, page, author = SOURCES[source]
        manifest['effects'][cue] = {
            'path': 'res://experiments/playable_flightcase/audio/crowd34/' + target.name,
            'sha256': sha(target), 'license': 'CC0-1.0',
            'license_url': 'https://creativecommons.org/publicdomain/zero/1.0/',
            'authority': 'owner_crowd_request_20261110',
            'integration_review_accepted': False, 'listening_verified': False,
            'creator': author, 'source_url': url, 'source_page': page,
            'source_sha256': digest, 'source_type': 'official lossy MP3 preview, not original master',
            'start_seconds': start, 'duration_seconds': duration,
            'sample_rate': 24000, 'channels': 2, 'gain_db': gain,
        }
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--applause', type=Path, required=True)
    parser.add_argument('--boo', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.applause, args.boo, args.output)
    print('Five genuine recording candidates prepared; listening/fit acceptance remains HELD.')
