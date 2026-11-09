#!/usr/bin/env python3
"""Private same-family formation cues; no cross-song/tempo combinations."""
import hashlib,json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1];audio=root/'experiments/playable_flightcase/audio'
manifest=json.loads((audio/'recorded_indie29/manifest.json').read_text())
out=audio/'formation_next32';out.mkdir(exist_ok=True)
result={'schema_version':1,'content_version':'formation_next32','provenance':'Owner-supplied AI-generated Suno audio; paid-plan provenance reported by owner','licensing':'Commercial interactive-game licensing separate; review build only','listening_verified':False,'materials':{}}
for family,tone in [('guitar90','gritty'),('space','warm'),('dark','biting')]:
 hook=f'indie29_{family}_01';entry=manifest['entries'][hook];cmd=['ffmpeg','-v','error','-y'];sources=[]
 for part in ['guitar_'+tone,'bass','kit']:
  source=entry['parts'][part];p=root/source['path'].removeprefix('res://');assert hashlib.sha256(p.read_bytes()).hexdigest()==source['sha256'];cmd+=['-i',str(p)];sources.append(source)
 dest=out/f'{family}.ogg'
 cmd+=['-filter_complex','[0:a][1:a][2:a]amix=inputs=3:normalize=0,volume=0.42,alimiter=limit=0.92:level=false,afade=t=in:d=0.03,afade=t=out:st=4.8:d=1.2[a]','-map','[a]','-t','6','-c:a','libvorbis','-q:a','5',str(dest)]
 subprocess.run(cmd,check=True)
 result['materials'][family]={'path':'res://'+str(dest.relative_to(root)),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'family':family,'source_hook':hook,'sources':sources,'seconds':6,'owner_listening_accepted':False,'integration_review_accepted':True,'integration_authority':'owner_approved_LOOK31_direction','same_family_only':True}
(out/'manifest.json').write_text(json.dumps(result,indent=2)+'\n');print('3 same-family cues')
