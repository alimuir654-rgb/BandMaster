#!/usr/bin/env python3
"""Validate real prepared assets against untouched source intake and recipes."""
import argparse
import hashlib
import json
from pathlib import Path
import wave
import numpy as np


def read(path):
    with wave.open(str(path), 'rb') as w:
        assert (w.getnchannels(), w.getsampwidth(), w.getframerate()) == (2,2,48000)
        return np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').reshape(-1,2).astype(np.float32)/32768


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,required=True);args=p.parse_args()
    root=args.root; intake=json.loads((root/'intake.json').read_text());report=json.loads((root/'candidates/assessment.json').read_text())
    checks=0
    for row in intake['files']:
        assert hashlib.sha256((root/'originals'/row['name']).read_bytes()).hexdigest()==row['sha256'];checks+=1
    for song, slug in zip(report['songs'],['plates','wear','stairs']):
        assert len({s['frames'] for s in song['stems'].values()})==1;checks+=1
        for clip in song['candidates']:
            folder=root/'candidates'/slug/f"candidate-{clip['candidate']}"
            stems={role:read(folder/asset['path']) for role,asset in clip['parts'].items()}
            assert all(len(x)==clip['frames'] for x in stems.values());checks+=1
            # Recompute the vocal directly from the original timeline, not a
            # different selection for each arrangement or an EQ substitute.
            with wave.open(str(root/'originals'/song['stems']['Vocals']['file']),'rb') as w:
                w.setpos(clip['source_start_frame']);raw=w.readframes(clip['frames'])
            voice=np.frombuffer(raw,dtype='<i2').reshape(-1,2).astype(np.float32)/32768
            voice[:480]*=np.linspace(0,1,480,dtype=np.float32)[:,None]
            voice[-960:]*=np.linspace(1,0,960,dtype=np.float32)[:,None]
            assert np.max(np.abs(voice-stems['Vocals']))<=2/32768;checks+=1
            assert len({v['vocal_pcm_sha256'] for v in clip['arrangements'].values()})==1;checks+=1
            for name,variant in clip['arrangements'].items():
                mixed=read(folder/variant['path'])
                expected=sum((stems[role] for role in variant['roles']),np.zeros_like(mixed))*variant['common_gain']
                assert np.max(np.abs(mixed-expected))<8/32768;checks+=1
                assert len(mixed)==clip['frames'] and np.max(np.abs(mixed))<1;checks+=1
                with wave.open(str(folder/variant['vocal_asset']),'rb') as w:payload=w.readframes(w.getnframes())
                assert hashlib.sha256(payload).hexdigest()==variant['vocal_pcm_sha256'];checks+=1
    print(json.dumps({'checks':checks,'failures':[],'real_originals_unchanged':True,
        'same_vocal_across_three_arrangements':True,'listening':False}))
