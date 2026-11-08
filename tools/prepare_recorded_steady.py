#!/usr/bin/env python3
"""Prepare private owner-review cuts, preserving and verifying exact Suno originals."""
import argparse
import hashlib
import json
import wave
from pathlib import Path

import numpy as np


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assessment-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    metadata = json.loads((args.assessment_dir / 'measurements.json').read_text())
    audio, sources = {}, []
    for row in metadata['files']:
        path = args.assessment_dir / 'originals' / row['name']
        assert digest(path.read_bytes()) == row['sha256'], row['name']
        sources.append({key: row[key] for key in ['name', 'id', 'rev', 'sha256', 'dropbox_content_hash']})
        with wave.open(str(path), 'rb') as wav:
            assert (wav.getframerate(), wav.getnchannels(), wav.getsampwidth()) == (48000, 2, 2)
            audio[row['role']] = np.frombuffer(wav.readframes(wav.getnframes()), '<i2').reshape(-1, 2) / 32768.0
    kit = audio['Drums'] + audio['Percussion']
    kit_gain = min(1.0, .95 / max(float(np.abs(kit).max()), 1e-12))
    manifest = dict(schema_version=1, content_version='recorded_steady_v1',
                    provenance='AI-generated Suno audio; owner reports paid-plan generation of this version',
                    review_only=True, commercial_game_licensing='unresolved', listening_verified=False,
                    loop_verified=False, sources=sources, drum_kit_gain=kit_gain,
                    fade_in_frames=480, fade_out_frames=960, entries={})
    for family, start in [('early', 230400), ('later', 921600)]:
        entry = dict(tempo=100, frames=460800, sample_rate=48000, channels=2,
                     source_start_frame=start, source_end_frame_exclusive=start + 460800, parts={})
        for part in ['guitar_warm', 'guitar_gritty', 'guitar_biting', 'bass', 'kit']:
            raw = (kit * kit_gain if part == 'kit' else audio['Guitar' if part.startswith('guitar') else 'Bass'])
            x = raw[start:start + 460800].copy()
            # Deterministic one-pole EQ; no time stretch, new notes or alternate performances.
            if part in ['guitar_warm', 'guitar_biting']:
                if part.endswith('biting'):
                    x = np.tanh(x * 1.5) / 1.5
                cutoff = 1800 if part.endswith('warm') else 5200
                alpha = 1 - np.exp(-2 * np.pi * cutoff / 48000)
                for frame in range(1, len(x)):
                    x[frame] = alpha * x[frame] + (1 - alpha) * x[frame - 1]
            x[:480] *= np.linspace(0, 1, 480)[:, None]
            x[-960:] *= np.linspace(1, 0, 960)[:, None]
            assert np.max(np.abs(x)) < 1
            pcm = np.round(x * 32768).astype('<i2').tobytes()
            name = family + '_' + part + '.wav'
            with wave.open(str(args.output / name), 'wb') as wav:
                wav.setparams((2, 2, 48000, 0, 'NONE', 'not compressed'))
                wav.writeframes(pcm)
            (args.output / (name + '.import')).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
            entry['parts'][part] = dict(path='res://experiments/playable_flightcase/audio/recorded_steady_v1/' + name,
                                       sha256=digest((args.output / name).read_bytes()), pcm_sha256=digest(pcm))
        manifest['entries']['steady_' + family + '_v1'] = entry
    (args.output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    assert sum(p.stat().st_size for p in args.output.iterdir()) < 32 * 1024 * 1024
    print('Prepared two matched 9.6-second families; original hashes verified; no original modified.')


if __name__ == '__main__':
    main()
