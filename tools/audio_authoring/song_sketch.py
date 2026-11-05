"""S129 offline verse/chorus comparison. No Game import or network access.

One authored hook, two rhythm-section grooves and two chorus treatments.
Reuses the pinned CC0 sampled instruments; guitar-only drive precedes mixing.
Run with the existing S93 isolated Python, from the repository root.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import math

from .sample_renderer import (validate_score, verify_sources, events_for_track,
                              write_pcm24, sha)

D = Path('/workspace/work/s129-song-sketch-prototype-20261105')
R = Path('/tmp/bandmaster-s129-song-sketch-prototype-20261105')
RATE = 48000
BPM = 112
BEAT = 60 / BPM
MUSIC = 64 * BEAT
TAIL = 2.4
FRAMES = round((MUSIC + TAIL) * RATE)
CHORDS = {'D': [(2,50),(3,57),(4,62),(5,66)],
          'G': [(0,43),(1,47),(2,50),(3,55),(4,59),(5,67)],
          'A': [(1,45),(2,52),(3,57),(4,61),(5,64)]}
HARMONY = ['D','D','G','G','D','D','A','A',
           'G','D','A','D','G','D','A','D']
ROOTS = {'D':38,'G':43,'A':45}
OPENINGS = {'D': [(0,66,.65),(.75,64,.28),(1.5,62,.55),(2.5,57,.3),(3.25,62,.5)],
            'G': [(0,67,.65),(.75,66,.28),(1.5,64,.35),(2,62,.65),(3,59,.35),(3.5,57,.25)],
            'A': [(0,64,.65),(.75,61,.28),(1.5,62,.35),(2,64,.65),(3.25,61,.5)]}


def save(path, value):
    Path(path).write_text(json.dumps(value, separators=(',',':')) + '\n')


def add(track, beat, length, pitch, velocity, voice=0, delay=0):
    at = beat * BEAT + delay
    off = min(at + length * BEAT, MUSIC)
    assert 0 <= at < off <= MUSIC
    track['notes'].append({'at':round(at,7),'off':round(off,7),
                           'pitch':pitch,'velocity':velocity,'voice':voice})


def base_tracks():
    g = json.loads(Path('/workspace/work/s113-offline-band-audio-20261104/punk-guitar-score.json').read_text())['tracks'][0]
    b = json.loads(Path('/workspace/work/s127-jack-backing-context-20261105/backing-score-v1.json').read_text())['tracks']
    tracks = [copy.deepcopy(g), copy.deepcopy(g), *copy.deepcopy(b)]
    for t, name, voices, role in zip(tracks,
            ['rhythm','hook','bass','kit'], [6,1,1,3],
            ['strummed_chords','melodic_hook','bass_groove','drum_groove']):
        t.update(id=name, voices=voices, role=role, gain=1.0, notes=[])
    return tracks


def score(groove, chorus):
    rhythm, hook, bass, kit = base_tracks()
    for bar, chord in enumerate(HARMONY):
        start = bar * 4
        is_chorus = bar >= 8
        # String order reverses on upstrokes. Short gates are authored staccato,
        # not a claim that the source bank contains recorded palm-muted notes.
        if not is_chorus:
            pattern = [(0,.56,88),(.75,.20,63),(1.5,.32,80),
                       (2.5,.28,74),(3.25,.17,61),(3.5,.29,81)]
        elif chorus == 'open':
            pattern = [(0,1.15,105),(1.5,.65,84),(2.5,.65,99),(3.5,.35,80)]
        else:
            pattern = [(0,.28,102),(.75,.18,75),(1.5,.27,95),
                       (2.25,.18,71),(2.75,.18,84),(3.5,.30,99)]
        if bar == 7:
            pattern = [(0,.56,88),(.75,.20,63),(1.5,.28,80),(2.5,.25,79)]
        if bar == 15:
            pattern = [(0,2.7,104)]
        for hit, (offset, gate, velocity) in enumerate(pattern):
            strings = CHORDS[chord]
            # Verse high strings leave room for the lead; chorus opens voicing.
            if not is_chorus and hit % 2: strings = strings[-3:]
            if hit % 2: strings = list(reversed(strings))
            for index, (string, pitch) in enumerate(strings):
                add(rhythm, start+offset, gate, pitch,
                    velocity - (index % 3)*3, string, index * .007)
        if is_chorus:
            phrase = OPENINGS[chord]
            if bar in (11,):
                phrase = [(0,66,.5),(.75,64,.25),(1.25,62,1.1),(3,57,.28)]
            if bar == 15: phrase = [(0,62,2.7)]
            for offset, pitch, gate in phrase:
                add(hook, start+offset, gate if chorus == 'open' else min(gate,.30),
                    pitch, 96 if offset == 0 else 82)
        elif bar % 2 == 0:
            # Two-bar call and answer, with genuine rests between phrases.
            phrase = [(.5,57,.28),(1.25,62,.4),(2,66,.6),(3,64,.25),(3.5,62,.28)]
            if chord == 'G': phrase = [(.5,59,.28),(1.25,62,.4),(2,67,.6),(3,66,.25),(3.5,64,.28)]
            if chord == 'A': phrase = [(.5,57,.28),(1.25,61,.4),(2,64,.6),(3,62,.25),(3.5,61,.28)]
            for offset,pitch,gate in phrase: add(hook,start+offset,gate,pitch,87 if offset==2 else 74)
        elif bar != 7:
            for offset,pitch,gate in [(0,59,.5),(1,57,.42),(2.5,62,.8)]:
                add(hook,start+offset,gate,pitch,75)
        else:
            for offset,pitch,gate in [(0,64,.5),(1,61,.42),(2.5,57,.42),(3.5,62,.25)]:
                add(hook,start+offset,gate,pitch,82)
        # All four have the same harmony and tempo. Rhythm section changes only
        # with groove; the chorus switch cannot alter these events.
        if groove == 'driving':
            bass_hits = [(0,.6,99),(.75,.35,76),(1.5,.33,86),
                         (2,.55,92),(2.75,.32,77),(3.5,.37,87)]
            kicks = [0,1.5,2,2.75] if bar % 2 == 0 else [0,.75,2,3.5]
            snares = [(1,103),(3,108)]
            hats = [(x*.5,83 if x % 2 == 0 else 58) for x in range(8)]
        else:
            bass_hits = [(0,1.1,101),(1.5,.30,73),(2.5,.65,89),(3.5,.35,78)]
            kicks = [0,1.5,3.25] if bar % 2 == 0 else [0,.75,2.75]
            snares = [(2,111), (3.5,42)]
            hats = [(0,77),(.5,52),(1,66),(1.75,54),(2,82),(2.5,52),(3,65),(3.75,57)]
        if bar == 7:
            snares += [(3.25,63),(3.75,83)]
            # Remove any same-voice collision from the deliberately late fill.
            snares = sorted(dict(snares).items())
        if bar == 15:
            bass_hits = [(0,2.7,101)]; kicks=[0]; snares=[]; hats=[(0,84)]
        for offset,gate,velocity in bass_hits:
            add(bass,start+offset,gate,ROOTS[chord],velocity)
        for offset in kicks: add(kit,start+offset,.09,36,106 if offset==0 else 90,0)
        for offset,velocity in snares: add(kit,start+offset,.10,38,velocity,1)
        for offset,velocity in hats: add(kit,start+offset,.07,42,velocity,2)
    s = {'schema_version':1,'id':f's129-{groove}-{chorus}', 'style':'indie-rock',
         'sample_rate':RATE,'duration_seconds':FRAMES/RATE,'tail_seconds':TAIL,
         'tracks':[rhythm,hook,bass,kit],'rights_receipt':str(D/'rights.json'),
         'authoring_authority':'Direct owner Go ahead 5Nov2026: four verse/chorus prototypes; no Game integration.'}
    return validate_score(s)


def plan():
    out = R/'scores-v3'; out.mkdir()
    variants = {}
    for groove in ['driving','half-time']:
        for chorus in ['open','tight']:
            s = score(groove,chorus)
            for t in s['tracks']: verify_sources(t)
            save(out/(s['id']+'.json'),s); variants[s['id']]=s
    # Counterfactual checks compare literal independent component event data.
    for groove in ['driving','half-time']:
        a,b=[variants[f's129-{groove}-{c}'] for c in ['open','tight']]
        for index in (2,3): assert a['tracks'][index] == b['tracks'][index]
        for index in (0,1):
            for s in (a,b):
                boundary = round(32*BEAT*RATE)
                assert [n for n in s['tracks'][index]['notes'] if round(n['at']*RATE)<boundary] == [n for n in a['tracks'][index]['notes'] if round(n['at']*RATE)<boundary]
        assert [n['pitch'] for n in a['tracks'][1]['notes']] == [n['pitch'] for n in b['tracks'][1]['notes']]
    for chorus in ['open','tight']:
        a,b=[variants[f's129-{g}-{chorus}'] for g in ['driving','half-time']]
        for index in (0,1): assert a['tracks'][index] == b['tracks'][index]
        for index in (2,3): assert a['tracks'][index]['notes'] != b['tracks'][index]['notes']
    report={'variants':{k:{'sha256':sha(out/(k+'.json')),
            'notes':{t['id']:len(t['notes']) for t in s['tracks']}} for k,s in variants.items()},
            'tempo':BPM,'bars':16,'verse_seconds':[0,32*BEAT],
            'chorus_seconds':[32*BEAT,MUSIC],'tail_seconds':TAIL,
            'duration_seconds':FRAMES/RATE,'paired_component_checks':'pass',
            'same_hook_pitch_sequence_all_four':True,'human_listening':False}
    save(D/'score-contract.json',report)
    return report


def render(score_path, output):
    import numpy as np
    import pysfizz
    import pedalboard
    import importlib.metadata
    s=validate_score(json.loads(Path(score_path).read_text()))
    before=[verify_sources(t) for t in s['tracks']]
    rights_sha=sha(s['rights_receipt'])
    output=Path(output); output.mkdir()
    mix=np.zeros((2,FRAMES),np.float32)
    results=[]
    for track in s['tracks']:
        synths=[pysfizz.Synth(sample_rate=RATE,block_size=256) for _ in range(track['voices'])]
        for synth in synths:
            assert synth.load_sfz_file(track['sfz'],quiet=False)
            assert all(n['pitch'] in synth.playable_keys for n in track['notes'])
        raw=np.zeros_like(mix); events=events_for_track(track,RATE);cursor=0
        for start in range(0,FRAMES,256):
            while cursor<len(events) and events[cursor][0]<start+256:
                at,kind,voice,pitch,velocity=events[cursor]
                native=synths[voice]._synth
                (native.note_on if kind else native.note_off)(at-start,pitch,velocity)
                cursor+=1
            count=min(256,FRAMES-start)
            for synth in synths:
                left,right=synth._synth.render_block()
                raw[0,start:start+count]+=left[:count]
                raw[1,start:start+count]+=right[:count]
        active=[x._synth.get_num_active_voices() for x in synths]
        assert max(active)==0 and cursor==len(events)
        guitar=track['instrument']=='electric_guitar'
        # Fixed per-role treatment and gain across all combinations. No
        # per-variant loudness/tempo trick masquerading as a musical choice.
        if guitar:
            processed=pedalboard.Pedalboard([
                pedalboard.HighpassFilter(cutoff_frequency_hz=110),
                pedalboard.Distortion(drive_db=9 if track['id']=='rhythm' else 7),
                pedalboard.LowpassFilter(cutoff_frequency_hz=5200),
            ])(raw,RATE,reset=True)
        else: processed=raw
        gains={'rhythm':.13,'hook':.18,'bass':.18,'kit':.16}
        pan={'rhythm':-.38,'hook':.38,'bass':0,'kit':0}[track['id']]
        if guitar:
            mono=processed.mean(axis=0)
            processed=np.stack([mono*math.sqrt((1-pan)/2),mono*math.sqrt((1+pan)/2)])
        processed*=gains[track['id']]
        mix+=processed
        stem=output/(track['id']+'.wav');write_pcm24(stem,processed,RATE)
        results.append({'id':track['id'],'stem_sha256':sha(stem),'notes':len(track['notes']),
            'active_voices_at_end':active,'gain':gains[track['id']],'pan':pan,
            'peak':float(np.max(np.abs(processed))),
            'music_rms':float(np.sqrt(np.mean(processed[:,:round(MUSIC*RATE)]**2)))})
    room=pedalboard.Pedalboard([pedalboard.Reverb(room_size=.12,damping=.72,
                wet_level=.035,dry_level=.97,width=.8)])(mix,RATE,reset=True)
    assert np.isfinite(room).all()
    tail_peak=float(np.max(np.abs(room[:,-round(.2*RATE):])))
    assert tail_peak<.001
    write_pcm24(output/'raw.wav',mix,RATE);write_pcm24(output/'room.wav',room,RATE)
    assert before==[verify_sources(t) for t in s['tracks']]
    assert rights_sha==sha(s['rights_receipt'])
    result={'id':s['id'],'score_sha256':sha(score_path),'tool_sha256':sha(__file__),
            'sources':before,'rights_sha256':rights_sha,'frames':FRAMES,'rate':RATE,
            'seconds':FRAMES/RATE,'stems':results,'tail_last_200ms_peak':tail_peak,
            'mix_peak':float(np.max(np.abs(mix))),'room_peak':float(np.max(np.abs(room))),
            'outputs':{name:sha(output/name) for name in ['raw.wav','room.wav']},
            'versions':{n:importlib.metadata.version(n) for n in ['pysfizz','pedalboard','numpy']},
            'human_listening_accepted':False,'game_integrated':False}
    save(output/'render.json',result)
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('command',choices=['plan','render'])
    p.add_argument('--score');p.add_argument('--output');args=p.parse_args()
    result=plan() if args.command=='plan' else render(args.score,args.output)
    print(json.dumps(result))
