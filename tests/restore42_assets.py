#!/usr/bin/env python3
"""Check recovered private clocks, imported-source pins and original preservation."""
import argparse
from array import array
import hashlib
import json
from pathlib import Path
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / 'experiments/playable_flightcase/audio'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--evidence', type=Path, required=True)
    args = parser.parse_args()
    checks = 0

    def check(value):
        global checks
        assert value
        checks += 1

    recovery = json.loads((args.evidence / 'restoration.json').read_text())
    intake = json.loads((args.evidence / 'intake.json').read_text())
    for row in intake:
        check(sha(Path(row['local'])) == row['sha256'])
    waves = 0
    configs = [('recorded_steady_v1', 2), ('recorded_steady_v2', 2),
               ('recorded_rehearsal_v1', 6), ('recorded_dgad_v1', 6), ('recorded_indie29', 18)]
    for bank, count in configs:
        m = json.loads((AUDIO / bank / 'manifest.json').read_text())
        check(m['content_version'] == bank and len(m['entries']) == count)
        for hook, entry in m['entries'].items():
            check(len(entry['parts']) == 5 and entry['sample_rate'] == 48000)
            check(abs(entry['frames'] / 48000 - 960 / entry['tempo']) < 0.00003)
            for part in entry['parts'].values():
                p = ROOT / part['path'].removeprefix('res://')
                check(sha(p) == part['sha256'])
                with wave.open(str(p)) as w:
                    check((w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()) == (2, 2, 48000, entry['frames']))
                    pcm = w.readframes(w.getnframes())
                check(hashlib.sha256(pcm).hexdigest() == part['pcm_sha256'])
                samples = array('h', pcm)
                check(-32768 not in samples and 32767 not in samples)
                waves += 1
    check(waves == 170)
    characters = json.loads((AUDIO / 'character_indie29/manifest.json').read_text())
    check(len(characters['characters']) == 10 and len(characters['materials']) == 20)
    formation = json.loads((AUDIO / 'formation_next32/manifest.json').read_text())
    check(set(formation['materials']) == {'guitar90', 'space', 'dark'})
    title = json.loads((AUDIO / 'splash_cue.json').read_text())
    for row in list(characters['materials'].values()) + list(formation['materials'].values()) + [title]:
        p = ROOT / row['path'].removeprefix('res://')
        check(sha(p) == row['sha256'])
        probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration:stream=codec_type', '-of', 'json', str(p)]))
        check(len(probe['streams']) == 1 and probe['streams'][0]['codec_type'] == 'audio')
        check(0 < float(probe['format']['duration']) <= 12)
    for relative, digest in recovery['approved_new_banks_unchanged'].items():
        check(sha(AUDIO / relative) == digest)
    print(json.dumps({'checks': checks, 'failures': [], 'recovered_legacy_WAVs': waves,
                      'legacy_foundations': 32, 'character_clips': 20, 'title': 1,
                      'formation_cues': 3, 'originals_and_new_banks_unchanged': True,
                      'listening': False}))
