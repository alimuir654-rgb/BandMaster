#!/usr/bin/env python3
"""Add private passage candidates without replacing any source or existing bank.

These are passages from one Suno source, not six alternate performances of one
phrase. Tempo/bar starts and loop joins remain provisional until listening.
"""
import argparse
import hashlib
import json
import wave
from pathlib import Path

import numpy as np
from scipy.signal import lfilter

RATE = 48000
TEMPO = 102
FRAMES = round(16 * 60 / TEMPO * RATE)
ANCHORS = [9.6, 28.8, 48.0, 67.2, 86.4, 100.8]
VERSION = 'recorded_rehearsal_v1'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def cut(path, start, frames):
    with wave.open(str(path), 'rb') as wav:
        assert (wav.getframerate(), wav.getnchannels(), wav.getsampwidth()) == (RATE, 2, 2)
        assert 0 <= start and start + frames <= wav.getnframes()
        wav.setpos(start)
        return np.frombuffer(wav.readframes(frames), '<i2').reshape(-1, 2).astype(np.float64) / 32768


def tone(x, colour):
    rms = float(np.sqrt(np.mean(x*x)))
    drive = {'warm': 1, 'gritty': 5, 'biting': 18}[colour]
    y = np.tanh(x * drive) / drive
    alpha = 1 - np.exp(-2 * np.pi * {'warm': 650, 'gritty': 2800, 'biting': 6500}[colour] / RATE)
    y, _ = lfilter([alpha], [1, -(1-alpha)], y, axis=0, zi=((1-alpha)*y[0])[None, :])
    y *= min(rms / max(float(np.sqrt(np.mean(y*y))), 1e-12), .9/max(float(np.abs(y).max()), 1e-12))
    return y


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assessment-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    assert not args.output.exists(), 'Never replace a bank or source'
    data = json.loads((args.assessment_dir/'measurements.json').read_text())
    sources = []
    paths = {}
    for row in data['files']:
        path = args.assessment_dir/'originals'/row['name']
        assert sha(path.read_bytes()) == row['sha256'], row['name']
        paths[row['role']] = path
        sources.append({key: row[key] for key in ['name','id','rev','sha256','dropbox_content_hash']})
    args.output.mkdir(parents=True)
    result = dict(schema_version=1, content_version=VERSION, review_only=True,
                  provenance='Owner-supplied AI-generated Suno audio', commercial_game_licensing='unresolved',
                  listening_verified=False, loop_verified=False, bar_grid_verified=False,
                  tempo_estimated=True, no_time_stretch=True, sources=sources,
                  distinct_passages=6, alternate_performances_claimed=0,
                  fade_in_frames=480, fade_out_frames=960, entries={})
    for index, anchor in enumerate(ANCHORS, 1):
        # Prefer a nearby drum transient; this is not a verified bar/downbeat.
        search = round((anchor-.25)*RATE)
        preview = cut(paths['Drums'], search, 24000)
        envelope = np.sqrt(np.mean(preview.reshape(-1, 240, 2)**2, axis=(1, 2)))
        onset = np.maximum(0, np.diff(envelope, prepend=envelope[0]))
        start = search + int(np.argmax(onset))*240
        entry = dict(tempo=TEMPO, frames=FRAMES, sample_rate=RATE, channels=2,
                     source_start_frame=start, source_end_frame_exclusive=start+FRAMES,
                     provisional_bar_grid=True, parts={})
        for part in ['guitar_warm','guitar_gritty','guitar_biting','bass','kit']:
            role = 'Guitar' if part.startswith('guitar') else ('Bass' if part=='bass' else 'Drums')
            x = cut(paths[role], start, FRAMES)
            if part.startswith('guitar'):
                x = tone(x, part.removeprefix('guitar_'))
            x *= min(1, .9/max(float(np.abs(x).max()), 1e-12))
            x[:480] *= np.linspace(0, 1, 480)[:, None]
            x[-960:] *= np.linspace(1, 0, 960)[:, None]
            pcm = np.round(x*32768).astype('<i2').tobytes()
            name = f'rehearsal_{index:02d}_{part}.wav'
            path = args.output/name
            with wave.open(str(path), 'wb') as wav:
                wav.setparams((2, 2, RATE, 0, 'NONE', 'not compressed'))
                wav.writeframes(pcm)
            (args.output/(name+'.import')).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
            entry['parts'][part] = dict(path=f'res://experiments/playable_flightcase/audio/{VERSION}/{name}',
                                       sha256=sha(path.read_bytes()), pcm_sha256=sha(pcm))
        result['entries'][f'rehearsal_{index:02d}_v1'] = entry
    (args.output/'manifest.json').write_text(json.dumps(result, indent=2)+'\n')
    assert sum(p.stat().st_size for p in args.output.iterdir()) < 64*1024*1024
    assert all(sha((args.assessment_dir/'originals'/s['name']).read_bytes()) == s['sha256'] for s in sources)
    print(json.dumps(dict(candidates=6, frames=FRAMES, seconds=FRAMES/RATE, tempo_estimate=TEMPO,
                          original_hashes_unchanged=True, listening_verified=False)))


if __name__ == '__main__':
    main()
