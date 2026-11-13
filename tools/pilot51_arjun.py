#!/usr/bin/env python3
"""Two real score-matching SFZ guitar responses, private listening review only.

Uses the already reviewed pinned authoring wheels. Samples are never shipped.
Records the publisher's actual royalty-free wording rather than inferring CC0.
"""
from pathlib import Path
import hashlib
import importlib.metadata
import json
import re
import subprocess
import numpy as np
import pedalboard
import pysfizz
from audio_authoring.sample_renderer import write_pcm24

WORK=Path('/workspace/bandmaster-pilot51')
REPO=WORK/'guitar-source'
PIN='b3b3249d37dc977a1a297bd2dc053e6d9b6b805c'
PITCHES={50,55,57,59,62,64,66,67}


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def instrument():
    source=WORK/'guitar-ord.sfz'
    original=source.read_text()
    regions=[]
    files=set()
    for block in re.split(r'<region>',original)[1:]:
        pitch=re.search(r'(?m)^pitch_keycenter=(\d+)',block)
        if not pitch or int(pitch[1]) not in PITCHES:
            continue
        relative=re.search(r'(?m)^sample=([^\r\n]+)',block)[1].replace('../','',1)
        path=REPO/relative
        assert path.resolve().is_relative_to(REPO.resolve()) and path.is_file()
        files.add(relative)
        block=re.sub(r'(?m)^sample=[^\r\n]+','sample='+str(path),block)
        regions.append('<region>\n'+block.strip()+'\n')
    assert len(regions)==96 and len(files)==80
    tree=subprocess.check_output(['git','-C',str(REPO),'ls-tree','-r',PIN],text=True)
    expected={line.split('\t',1)[1]:line.split()[2] for line in tree.splitlines()}
    rows=[]
    for relative in sorted(files):
        path=REPO/relative;raw=path.read_bytes()
        blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
        assert blob==expected[relative], relative
        rows.append(dict(path=relative,bytes=len(raw),sha256=sha(path),git_blob=blob))
    target=WORK/'arjun-review-v2-instrument.sfz'
    assert not target.exists()
    target.write_text('<global>\nampeg_attack=0.003\nampeg_release=0.18\nloop_mode=no_loop\n'+''.join(regions))
    receipt=dict(source_repository='sfzinstruments/karoryfer.black-and-green-guitars',pin=PIN,
        licence='Royalty-free for all commercial and non-commercial use. Copyright 2022 Karoryfer Lecolds.',
        licence_source='readme.txt at pinned Git commit',licence_text_sha256=sha(WORK/'guitar-readme.txt'),
        publisher_page='https://shop.karoryfer.com/pages/free-black-and-green-guitars',
        CC0_claim_verified=False,source_regions=96,source_files=rows,
        source_sfz_sha256=sha(source),derived_sfz_sha256=sha(target),
        transforms='Select exact sampled pitches/velocity/roundrobins, resolve sample paths; add finite pluck envelope. No single-note pitch substitution.',
        source_samples_packaged=False)
    (WORK/'arjun-source-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return target,rows


def note(at,off,pitch,velocity,voice):
    return dict(at=at,off=off,pitch=pitch,velocity=velocity,voice=voice)


def scores():
    space=[]
    for start,pitches in [(2.48,[55,59,62,64]),(7.28,[50,57,62,66])]:
        for voice,pitch in enumerate(pitches):
            space.append(note(start+voice*.027,start+1.55,pitch,61+voice*2,voice))
    own=[note(.08,.9,50,50,0),note(4.88,5.7,57,50,0)]
    for at,pitch in [(2.52,64),(2.85,66),(3.18,67),(3.51,66),(3.84,62),
                     (7.35,66),(7.72,64),(8.10,62)]:
        own.append(note(at,at+(.55 if pitch==62 else .24),pitch,68,1))
    return {'space_for_voice':space,'own_part':own}


def render(sfz,request,notes):
    rate=48000;block=256;frames=rate*12
    assert all(0<=n['at']<n['off']<=9.6 for n in notes)
    if request=='space_for_voice':
        assert all(2.4<=n['at']<4.8 or 7.2<=n['at']<9.6 for n in notes)
    synths=[pysfizz.Synth(sample_rate=rate,block_size=block) for _ in range(4)]
    for synth in synths:
        assert synth.load_sfz_file(str(sfz),quiet=False)
        assert PITCHES.issubset(set(synth.playable_keys))
    events=[]
    for n in notes:
        events += [(round(n['at']*rate),1,n['voice'],n['pitch'],n['velocity']),
                   (round(n['off']*rate),0,n['voice'],n['pitch'],0)]
    events.sort();cursor=0;mix=np.zeros((2,frames),dtype=np.float32)
    for start in range(0,frames,block):
        while cursor<len(events) and events[cursor][0]<start+block:
            at,kind,voice,pitch,velocity=events[cursor]
            synth=synths[voice]._synth
            (synth.note_on if kind else synth.note_off)(at-start,pitch,velocity)
            cursor+=1
        count=min(block,frames-start)
        for synth in synths:
            left,right=synth._synth.render_block()
            mix[0,start:start+count]+=left[:count]*.27
            mix[1,start:start+count]+=right[:count]*.27
    active=[s._synth.get_num_active_voices() for s in synths]
    assert not any(active)
    effects=pedalboard.Pedalboard([pedalboard.HighpassFilter(cutoff_frequency_hz=65),
        pedalboard.LowpassFilter(cutoff_frequency_hz=6800),
        pedalboard.Compressor(threshold_db=-22,ratio=1.8,attack_ms=12,release_ms=90),
        pedalboard.Reverb(room_size=.14,damping=.65,wet_level=.055,dry_level=.95,width=.5)])
    processed=effects(mix,rate,reset=True)*12.0
    assert np.isfinite(processed).all() and 0<float(np.max(np.abs(processed)))<1
    assert float(np.max(np.abs(processed[:,-9600:])))<.001
    output=WORK/'arjun-review-v2'/request;output.mkdir(parents=True,exist_ok=False)
    write_pcm24(output/'raw.wav',mix,rate);write_pcm24(output/'room.wav',processed,rate)
    subprocess.run(['ffmpeg','-v','error','-n','-i',str(output/'room.wav'),'-c:a','libmp3lame','-q:a','2',str(output/'review.mp3')],check=True)
    report=dict(request=request,tempo=100,bars=4,performance_seconds=9.6,tail_seconds=2.4,
        frames=frames,sample_rate=rate,notes=notes,instrument_sha256=sha(sfz),
        source_receipt_sha256=sha(WORK/'arjun-source-receipt.json'),common_review_gain=12.0,
        active_sampler_voices_at_end=active,raw_peak=float(np.max(np.abs(mix))),
        processed_peak=float(np.max(np.abs(processed))),last_200ms_peak=float(np.max(np.abs(processed[:,-9600:]))),
        outputs={p.name:sha(p) for p in output.iterdir()},
        versions={n:importlib.metadata.version(n) for n in ['pysfizz','pedalboard','numpy']},
        listening_accepted=False,game_integration=False,source='Recorded multisample guitar, authored score, not a live musician')
    (output/'receipt.json').write_text(json.dumps(report,indent=2)+'\n')
    return dict(request=request,notes=len(notes),frames=frames,peak=report['processed_peak'],review=str(output/'review.mp3'))


def main():
    sfz,rows=instrument()
    results=[render(sfz,request,notes) for request,notes in scores().items()]
    assert all(sha(REPO/r['path'])==r['sha256'] for r in rows)
    print(json.dumps(dict(results=results,complete_sources_rechecked=True,listening_accepted=False,game_integration=False)))


if __name__=='__main__':
    main()
