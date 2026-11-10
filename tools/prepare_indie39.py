#!/usr/bin/env python3
"""Promote only owner-approved candidate1 audio; private output, originals untouched."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path('/workspace/bandmaster-indie38/candidates')
OUT=ROOT/'experiments/playable_flightcase/audio/recorded_indie39'
SETS=[('plates','cast_maya','cast_freya'),('wear','cast_lily','cast_dan'),('stairs','cast_sam','cast_oscar')]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    assessment=json.loads((SOURCE/'assessment.json').read_text())
    selected=[]
    for song,(slug,singer,keys) in zip(assessment['songs'],SETS):
        window=song['candidates'][0]
        assert window['candidate']==1
        for asset in window['parts'].values():
            assert sha(SOURCE/slug/'candidate-1'/asset['path'])==asset['sha256']
        selected.append((song,slug,singer,keys,window))
    OUT.mkdir(exist_ok=False)
    manifest={'schema_version':1,'content_version':'recorded_indie39','owner_listening_accepted':True,'authority':'owner_approved_first_excerpt_pairs_20261110','provenance':'Owner-supplied AI-generated Suno audio','commercial_game_license':'Separate clarification; private review only','entries':{}}
    characters={'schema_version':1,'characters':{},'materials':{}}
    for song,slug,singer,keys,window in selected:
        hook='indie39_'+slug+'_01';parts={}
        for role,part in [('Vocals','vocals'),('Keyboard','keys'),('Guitar','guitar'),('Bass','bass'),('Drums','kit')]:
            asset=window['parts'][role];target=OUT/(hook+'_'+part+'.wav')
            shutil.copy2(SOURCE/slug/'candidate-1'/asset['path'],target)
            Path(str(target)+'.import').write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
            parts[part]=dict(asset,path='res://'+target.relative_to(ROOT).as_posix())
        manifest['entries'][hook]={'frames':window['frames'],'sample_rate':48000,'channels':2,'tempo':song['timing_evidence']['candidate_near_target_bpm'],'singer':singer,'keyboardist':keys,'common_gain':song['common_mix_gain'],'parts':parts,'source_start_frame':window['source_start_frame'],'source_title':song['title'],'bar_grid_verified':False,'fingerprint':hashlib.sha256('|'.join(parts[p]['pcm_sha256'] for p in ['vocals','keys','guitar','bass','kit']).encode()).hexdigest()}
        for id,role,part in [(singer,'Singer','vocals'),(keys,'Keyboardist','keys')]:
            material=id+'_indie39_01'
            characters['characters'][id]={'role':role,'materials':[material]}
            characters['materials'][material]=dict(parts[part],integration_authority='owner_approved_first_excerpt_pairs_20261110',integration_review_accepted=True)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (OUT/'characters.json').write_text(json.dumps(characters,indent=2)+'\n')
    print('Three approved five-part entries and six character sources prepared privately')

if __name__=='__main__':main()
