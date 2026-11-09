#!/usr/bin/env python3
"""Owner-authorized private derivatives. Musical fit/bar grids remain provisional."""
import json,hashlib,wave,subprocess
from pathlib import Path
import numpy as np
from scipy.signal import fftconvolve,find_peaks
from prepare_recorded_rehearsal import cut,tone

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path('/workspace/indie-intake-20261109')
OUT=ROOT/'experiments/playable_flightcase/audio'
REPORT=Path('/workspace/bandmaster-audio29');REPORT.mkdir(exist_ok=True)
sha=lambda b:hashlib.sha256(b).hexdigest()
rows=json.loads((SOURCE/'manifest.json').read_text())
groups=[('guitar90','G–D–Em–C',108,'GUITAR ROOM'),('space','Rehearsion Space',112,'NIGHT COLOURS'),('dark','Rehearsal D Minor',136,'DARK CURRENT')]
manifest={'schema_version':1,'content_version':'recorded_indie29','review_only':True,'provenance':'Owner-supplied AI-generated Suno audio','commercial_game_licensing':'separate clarification','listening_verified':False,'bar_grid_verified':False,'sources':rows,'entries':{}}
folder=OUT/'recorded_indie29';folder.mkdir(exist_ok=True)
config=[];cuts={}
for key,name,target,label in groups:
    paths={role:SOURCE/'originals'/f'{name} ({role}).wav' for role in ['Guitar','Bass','Drums']}
    for path in paths.values():assert sha(path.read_bytes())==next(r['sha256'] for r in rows if r['name']==path.name)
    with wave.open(str(paths['Drums']),'rb') as w:total=w.getnframes()
    x=cut(paths['Drums'],0,total)
    env=np.sqrt(np.mean(x[:len(x)//240*240].reshape(-1,240,2)**2,axis=(1,2)))
    onset=np.maximum(0,np.diff(env,prepend=env[0]));onset-=onset.mean()
    corr=fftconvolve(onset,onset[::-1],mode='full')[len(onset)-1:]
    lags=np.arange(round(200*60/(target*1.12)),round(200*60/(target*.88))+1)
    lag=int(lags[np.argmax(corr[lags])]);tempo=round(12000/lag);frames=round(16*60/tempo*48000)
    hooks=[]
    for i,anchor in enumerate(np.linspace(18,total/48000-22,6),1):
        lo=round((anchor-.35)*200);hi=round((anchor+.35)*200)
        start=int((lo+np.argmax(onset[lo:hi]))*240)
        hook=f'indie29_{key}_{i:02d}';hooks.append(hook)
        item={'tempo':tempo,'frames':frames,'sample_rate':48000,'channels':2,'source_start_frame':start,'source_end_frame_exclusive':start+frames,'provisional_bar_grid':True,'parts':{}}
        for part in ['guitar_warm','guitar_gritty','guitar_biting','bass','kit']:
            role='Guitar' if part.startswith('guitar') else ('Bass' if part=='bass' else 'Drums')
            y=cut(paths[role],start,frames)
            if role=='Guitar':y=tone(y,part.split('_')[1])
            y[:480]*=np.linspace(0,1,480)[:,None];y[-960:]*=np.linspace(1,0,960)[:,None]
            y*=min(1,.88/max(np.abs(y).max(),1e-9));pcm=np.round(y*32768).astype('<i2').tobytes()
            path=folder/f'{hook}_{part}.wav'
            with wave.open(str(path),'wb') as w:w.setparams((2,2,48000,0,'NONE','not compressed'));w.writeframes(pcm)
            item['parts'][part]={'path':'res://'+str(path.relative_to(ROOT)),'sha256':sha(path.read_bytes()),'pcm_sha256':sha(pcm)}
            Path(str(path)+'.import').write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
        manifest['entries'][hook]=item
        cuts[(key,i)]=(paths,start,frames)
    config.append({'key':key,'label':label,'tempo':tempo,'frames':frames,'hooks':hooks,'method':'drum onset autocorrelation near requestedtempo; downbeats/musicalmeter unverified'})
(folder/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
assignments={'cast_jack':('guitar90','Guitar',1),'cast_ryan':('guitar90','Guitar',3),'cast_arjun':('space','Guitar',2),'cast_bex':('dark','Guitar',3),'cast_hannah':('guitar90','Bass',1),'cast_zoe':('space','Bass',3),'cast_ben':('guitar90','Bass',2),'cast_ellis':('guitar90','Drums',1),'cast_marcus':('space','Drums',2),'cast_casey':('dark','Drums',3)}
clips=OUT/'character_indie29';clips.mkdir(exist_ok=True);registry={'schema_version':1,'content_version':'indie29_ideas','provenance':manifest['provenance'],'listening_verified':False,'characters':{},'materials':{}}
for person,(key,role,index) in assignments.items():
    registry['characters'][person]={'role':{'Guitar':'Guitarist','Bass':'Bassist','Drums':'Drummer'}[role],'materials':[],'fit':'editorial assignment by canonical biography/instrument; not listening verified'}
    for take in range(2):
        paths,start,frames=cuts[(key,index+take)];id=f'{person}_indie29_{take+1}';path=clips/(id+'.ogg')
        subprocess.run(['ffmpeg','-v','error','-y','-ss',str(start/48000),'-i',str(paths[role]),'-t',str(frames/48000),'-af','afade=t=in:d=0.01,afade=t=out:st=%.5f:d=0.04'%(frames/48000-.04),'-c:a','libvorbis','-q:a','5',str(path)],check=True)
        registry['characters'][person]['materials'].append(id)
        registry['materials'][id]={'path':'res://'+str(path.relative_to(ROOT)),'sha256':sha(path.read_bytes()),'source_sha256':next(r['sha256'] for r in rows if r['name']==paths[role].name),'source_start_frame':start,'frames':frames,'owner_listening_accepted':False,'integration_review_accepted':True,'integration_authority':'owner_request_20261109','description':'Independent recorded idea; not an alternate response to the written exercise.'}
(clips/'manifest.json').write_text(json.dumps(registry,indent=2)+'\n')
# Title uses a restrained new six-second trio excerpt; retain old cue file intact.
paths,start,frames=cuts[('guitar90',1)];cue=OUT/'title_indie29.ogg'
cmd=['ffmpeg','-v','error','-y']
for role in ['Guitar','Bass','Drums']:cmd+=['-ss',str(start/48000),'-i',str(paths[role])]
cmd+=['-filter_complex','[0:a][1:a][2:a]amix=inputs=3:normalize=0,volume=0.25,afade=t=in:d=0.12,afade=t=out:st=4.6:d=1.4[a]','-map','[a]','-t','6','-c:a','libvorbis','-q:a','5',str(cue)];subprocess.run(cmd,check=True)
(OUT/'splash_cue.json').write_text(json.dumps({'schema_version':1,'path':'res://'+str(cue.relative_to(ROOT)),'sha256':sha(cue.read_bytes()),'owner_listening_accepted':False,'integration_review_accepted':True,'integration_authority':'owner_request_20261109','provenance':manifest['provenance'],'listening_verified':False,'source_start_frame':start,'seconds':6,'once_per_process':True},indent=2)+'\n')
(REPORT/'bank-config.json').write_text(json.dumps(config,indent=2)+'\n');print(json.dumps(config))
