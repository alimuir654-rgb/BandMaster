#!/usr/bin/env python3
"""Current owner Suno performances, never the rejected sampled-guitar method."""
from pathlib import Path
import hashlib
import json
import subprocess
import wave
import numpy as np
from prepare_audition47 import excerpt

ROOT=Path(__file__).resolve().parents[1]
WORK=Path('/workspace/bandmaster-engage52')
AUDIO=ROOT/'experiments/playable_flightcase/audio'


def main():
    catalogue=json.loads(Path('/workspace/bandmaster-flac49/verified-source-plan.json').read_text())
    registry_path=AUDIO/'character_indie29/manifest.json'
    registry=json.loads(registry_path.read_text())
    old=registry_path.read_bytes();(WORK/'character-registry-before.json').write_bytes(old)
    specifications=[('cast_arjun','arjun-recorded-A','D–G–A–D (Guitar).wav',2764800,460800),
        ('cast_arjun','arjun-recorded-B','D–G–A–D (Guitar).wav',3686400,460800),
        ('cast_casey','casey-first-groove','Rehearsal D Minor (Drums).wav',5100240,338824)]
    report=[];new_ids={}
    review=WORK/'audio-review';review.mkdir(exist_ok=False)
    for person,label,name,start,frames in specifications:
        row=next(r for r in catalogue if r['name']==name);source=Path(row['local_path'])
        assert hashlib.sha256(source.read_bytes()).hexdigest()==row['sha256']
        material=person+'_engage52_'+str(len(new_ids.get(person,[]))+1)
        target=AUDIO/'character_indie29'/(material+'.ogg')
        entry=excerpt(source,target,start,frames)
        entry.update(path='res://'+target.relative_to(ROOT).as_posix(),
            integration_authority='owner_requested_audio_revision_20261111',integration_review_accepted=True,
            source_type='Owner-supplied AI-generated Suno stem, existing approved source',
            description='Independent recorded sketch. Not a performed response to the written four-bar exercise.',
            owner_listening_accepted=False,old_generation_sampler=False)
        registry['materials'][material]=entry;new_ids.setdefault(person,[]).append(material)
        preview=excerpt(source,review/(label+'.mp3'),start,frames)
        with wave.open(str(source)) as wav:
            wav.setpos(start);pcm=np.frombuffer(wav.readframes(frames),dtype='<i2').reshape(-1,2).astype(np.float32)/32768
        e=np.sqrt(np.mean(pcm[:len(pcm)//480*480].reshape(-1,480,2)**2,axis=(1,2)))
        report.append(dict(person=person,material=material,review=str(review/(label+'.mp3')),
            source_sha256=row['sha256'],source_start_frame=start,frames=frames,
            rms=float(np.sqrt(np.mean(pcm**2))),active_10ms_blocks_above_minus38dB=float(np.mean(e>.012)),
            onset_envelope_changes=int(np.sum(np.diff(e)>.014)),musical_quality_listening_verified=False,
            source_container_unchanged=hashlib.sha256(source.read_bytes()).hexdigest()==row['sha256']))
    registry['characters']['cast_arjun']['materials']=new_ids['cast_arjun']
    registry['characters']['cast_arjun']['fit']='Current recorded D-G-A-D guitar sketches; replaces old-generation audition route. Not a scored response.'
    registry['characters']['cast_casey']['materials'][0]=new_ids['cast_casey'][0]
    registry_path.write_text(json.dumps(registry,indent=2)+'\n')
    (review/'receipt.json').write_text(json.dumps(dict(revisions=report,source='Existing owner-approved Suno masters',
        listening_verified=False,old_audio_deleted=False,written_response_match_claimed=False),indent=2)+'\n')
    print(json.dumps(report))


if __name__=='__main__':main()
