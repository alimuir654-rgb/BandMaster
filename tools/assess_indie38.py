#!/usr/bin/env python3
"""Offline private stem assessment. Numerical checks never confer listening approval.

Requires existing numpy/scipy/ffmpeg. No network, game/save writes, key access,
generation or public uploads. Original files remain unchanged. Output is new-only.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import subprocess
import wave
import numpy as np
from scipy.signal import fftconvolve, find_peaks

ROLES = ['Vocals', 'Keyboard', 'Guitar', 'Bass', 'Drums']
SONGS = [('Get the Good Plates Down', 'plates', 100, 'cast_maya', 'cast_freya'),
         ('Wear and Tear', 'wear', 112, 'cast_lily', 'cast_dan'),
         ('Underneath the Kitchen Stairs', 'stairs', 114, 'cast_sam', 'cast_oscar')]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def db(value):
    return round(20 * math.log10(max(float(value), 1e-12)), 3)


def pcm(path):
    with wave.open(str(path), 'rb') as w:
        if (w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getcomptype()) != (2, 2, 48000, 'NONE'):
            raise ValueError('Unsupported original encoding: ' + path.name)
        return np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').reshape(-1, 2).astype(np.float32) / 32768


def envelope(x):
    # 200Hz RMS envelopes, not a claim of musical beat/downbeat detection.
    n = len(x) // 240
    return np.sqrt(np.mean(x[:n * 240].reshape(n, 240, 2) ** 2, axis=(1, 2)))


def tempo_evidence(env, target):
    onset = np.maximum(0, np.diff(env, prepend=env[0]))
    onset -= np.mean(onset)
    corr = fftconvolve(onset, onset[::-1], mode='full')[len(onset)-1:]
    lo, hi = round(12000 / (target * 1.15)), round(12000 / (target * .85))
    lag = lo + int(np.argmax(corr[lo:hi+1]))
    peaks, _ = find_peaks(corr[75:201])
    strongest = sorted((int(i+75) for i in peaks), key=lambda i: corr[i], reverse=True)[:5]
    return {'prompt_target': target, 'candidate_near_target_bpm': round(12000/lag, 3),
            'other_autocorrelation_candidates_bpm': [round(12000/i, 3) for i in strongest],
            'tempo_meter_downbeat_and_key_verified_by_listening': False}


def write_wav(path, x):
    if np.max(np.abs(x)) >= 1:
        raise ValueError('Clipping output refused: ' + path.name)
    data = np.rint(x * 32767).astype('<i2').tobytes()
    with wave.open(str(path), 'wb') as w:
        w.setparams((2, 2, 48000, 0, 'NONE', 'not compressed')); w.writeframes(data)
    return {'path': path.name, 'sha256': sha(path), 'pcm_sha256': hashlib.sha256(data).hexdigest(),
            'frames': len(x), 'peak_dbfs': db(np.max(np.abs(x)))}


def encode(path, x):
    if np.max(np.abs(x)) >= 1:
        raise ValueError('Clipping reference mix refused')
    subprocess.run(['ffmpeg', '-v', 'error', '-nostdin', '-n', '-f', 'f32le', '-ar', '48000', '-ac', '2',
                    '-i', 'pipe:0', '-c:a', 'libvorbis', '-q:a', '5', str(path)],
                   input=x.astype('<f4').tobytes(), check=True)


def assess(root, output):
    intake = json.loads((root / 'intake.json').read_text())
    indexed = {r['name']: r for r in intake['files']}
    # Validate every supplied original, including optional reference, before output.
    for row in indexed.values():
        if sha(root / 'originals' / row['name']) != row['sha256']:
            raise ValueError('Intake changed: ' + row['name'])
    output.mkdir(parents=True, exist_ok=False)
    result = {'schema_version': 1, 'source_type': intake['source_type'], 'songs': [],
              'listening_verified': False, 'game_integration': False,
              'commercial_game_licensing': 'Separate clarification remains unresolved'}
    for title, slug, target, singer, keyboardist in SONGS:
        folder = output / slug; folder.mkdir()
        metrics = {}; features = {}; total = None; count = None
        for role in ROLES:
            path = root / 'originals' / f'{title} ({role}).wav'
            x = pcm(path)
            if count is None:
                count = len(x); total = np.zeros_like(x)
            if count != len(x):
                raise ValueError('Unequal stem frames: ' + title)
            total += x
            env = envelope(x); features[role] = env
            active = np.flatnonzero(np.max(np.abs(x), axis=1) > 1/32768)
            metrics[role] = {'file': path.name, 'source_sha256': sha(path), 'frames': len(x),
                'duration_seconds': len(x)/48000, 'sample_rate': 48000, 'channels': 2, 'bits': 16,
                'peak_dbfs': db(np.max(np.abs(x))), 'rms_dbfs': db(np.sqrt(np.mean(x*x))),
                'samples_at_full_scale': int(np.count_nonzero(np.abs(x) >= 32767/32768)),
                'first_nonzero_frame': int(active[0]) if len(active) else None,
                'last_nonzero_frame': int(active[-1]) if len(active) else None}
            del x, active
        timing = tempo_evidence(features['Drums'], target)
        bpm = timing['candidate_near_target_bpm']
        frames = round(16*60/bpm*48000)
        # One common static gain for every arrangement preserves vocal level.
        gain = min(.5, .70/max(float(np.max(np.abs(total))), 1e-9))
        encode(folder / 'reconstructed-full.ogg', total*gain)
        reference = None
        supplied = root / 'originals' / (title + '.mp3')
        if supplied.exists():
            b = np.frombuffer(subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(supplied),
                    '-t', '60', '-ar', '48000', '-ac', '2', '-f', 'f32le', '-']), dtype='<f4').reshape(-1,2)
            n = min(len(total), len(b)); a = total[:n].mean(axis=1)[::6]; b = b[:n].mean(axis=1)[::6]
            corr = fftconvolve(a, b[::-1], mode='full'); centre = len(b)-1
            lag = int(np.argmax(corr[centre-8000:centre+8001]))-8000
            av, bv = (a[lag:], b[:len(a)-lag]) if lag>=0 else (a[:len(a)+lag], b[-lag:])
            scale = float(np.dot(av,bv)/max(np.dot(av,av),1e-12))
            residual = bv-av*scale
            reference = {'file': supplied.name, 'analysis_seconds': n/48000,
                'estimated_lag_seconds': lag/8000,
                'normalized_correlation': float(np.dot(av,bv)/max(np.linalg.norm(av)*np.linalg.norm(bv),1e-12)),
                'best_linear_gain': scale,
                'residual_relative_db': db(np.linalg.norm(residual)/max(np.linalg.norm(bv),1e-12)),
                'note': 'Waveform comparison only. Mastering, omitted stems or separation artifacts can differ; not a listening test.'}
        del total
        windows = []
        voice = features['Vocals']; keys = features['Keyboard']
        score = voice/(np.max(voice)+1e-9) + .35*keys/(np.max(keys)+1e-9)
        for number, fraction in enumerate([.25,.50,.75], 1):
            anchor = round(count/48000*fraction*200)
            lo = max(2000, anchor-1600); hi = min(len(score)-round(frames/240)-400, anchor+1600)
            if hi <= lo:
                raise ValueError('No safe excerpt range')
            width = round(frames/240)
            averaged = np.convolve(score[lo:hi+width], np.ones(width)/width, 'valid')
            start = (lo + int(np.argmax(averaged[:hi-lo]))) * 240
            parts = {}; assets = {}; excerpt = folder / f'candidate-{number}'; excerpt.mkdir()
            for role in ROLES:
                path = root / 'originals' / f'{title} ({role}).wav'
                with wave.open(str(path),'rb') as w:
                    w.setpos(start); data = w.readframes(frames)
                x = np.frombuffer(data,dtype='<i2').reshape(-1,2).astype(np.float32)/32768
                assert len(x)==frames
                # Shared minimal boundary fade; phrase/word boundaries remain unverified.
                x[:480] *= np.linspace(0,1,480,dtype=np.float32)[:,None]
                x[-960:] *= np.linspace(1,0,960,dtype=np.float32)[:,None]
                parts[role] = x
                assets[role] = write_wav(excerpt / (role.lower()+'.wav'), x)
            recipes = {'sparse':['Vocals','Keyboard'], 'groove':['Vocals','Guitar','Bass','Drums'], 'full':ROLES}
            variants = {}
            for name, roles in recipes.items():
                mixed = sum((parts[role] for role in roles), np.zeros((frames,2),dtype=np.float32))*gain
                asset = write_wav(excerpt/(name+'.wav'), mixed)
                encode(excerpt/(name+'.ogg'),mixed)
                variants[name] = asset | {'roles':roles, 'vocal_asset':'vocals.wav',
                    'vocal_pcm_sha256':assets['Vocals']['pcm_sha256'], 'common_gain':gain}
            assert len({v['vocal_pcm_sha256'] for v in variants.values()})==1
            windows.append({'candidate':number,'source_start_frame':start,'frames':frames,
                'source_start_seconds':start/48000,'duration_seconds':frames/48000,
                'bar_grid_and_lyric_boundary_verified':False,'parts':assets,'arrangements':variants})
        result['songs'].append({'title':title,'suggested_singer':singer,'suggested_keyboardist':keyboardist,
            'character_fit_listening_verified':False,'stems':metrics,'equal_frames_and_format':True,
            'alignment_limit':'Common frame counts/export origin, no per-stem shift applied. Original phase/offset and musical alignment still require listening.',
            'timing_evidence':timing,'reconstructed_mix':'reconstructed-full.ogg','common_mix_gain':gain,
            'original_Suno_mix_recreated':False,'supplied_reference_comparison':reference,'candidates':windows})
        (output/'assessment.json').write_text(json.dumps(result,indent=2)+'\n')
    for row in indexed.values():
        assert sha(root/'originals'/row['name'])==row['sha256']
    result['original_hashes_unchanged'] = True
    (output/'assessment.json').write_text(json.dumps(result,indent=2)+'\n')
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,required=True); parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args(); report=assess(args.root,args.output)
    print(json.dumps({'songs':len(report['songs']),'candidates':sum(len(s['candidates']) for s in report['songs']),
        'original_hashes_unchanged':True,'listening':False}))
