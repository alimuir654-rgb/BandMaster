#!/usr/bin/env python3
"""Register unchanged imagegen atlases by canonical ID; no identity-data edits."""
import json,hashlib,shutil
from pathlib import Path
from PIL import Image
import numpy as np
from scipy.ndimage import label,find_objects
root=Path(__file__).resolve().parents[1]
out=root/'experiments/playable_flightcase/art/identity'
groups=[('exec-10f1ec61-5ad6-402a-b8b8-967c4cecf3bf.png',['jack','zoe','casey']),('exec-d99b537e-686e-4064-8f1c-0e162d2c8b7c.png',['ryan','arjun','tom']),('exec-d78f03d1-9ebe-484c-a12b-0cd57e8bc769.png',['bex','ben','hannah']),('exec-49d6e5d9-9e9f-4992-bb17-2e088f2dbd62.png',['ellis','marcus','maya']),('exec-aad4d52f-8b85-4d98-941b-17a6fd4015f2.png',['lily','nina','sam']),('exec-c69999bc-b781-4af5-967d-feae380cdd9a.png',['dan','freya','oscar'])]
registry={'schema_version':1,'content_version':'next32_camera_poses','owner_art_acceptance':False,'integration_review_accepted':True,'authority':'owner_approved_LOOK31_direction','provenance':'AI-generated reference-based shared-origin triptych atlases; not human photos or independent portrait masters. Canonical audition identity data untouched.','people':{}}
for i,(filename,names) in enumerate(groups,1):
 src=Path('/workspace/generated_images')/filename;dest=out/f'next32_cast_{i:02d}.png'
 shutil.copy2(src,dest);im=Image.open(dest);a=np.array(im.getchannel('A'));assert im.size==(1536,1024) and (a==0).mean()>.3
 labels,n=label(a>=128);sizes=np.bincount(labels.ravel())
 figures=sorted([sl for component,sl in enumerate(find_objects(labels),1) if sizes[component]>10000],key=lambda sl:sl[1].start)
 assert len(figures)==3
 for name,sl in zip(names,figures):
  # Measure opaque silhouette, preserve original antialias pixels and4px bleed.
  # Very low alpha specks reach source edges; they are not missing footwear.
  y,x=sl;x0=max(0,x.start-4);x1=min(1536,x.stop+4);y0=max(0,y.start-4);y1=min(1024,y.stop+4)
  assert x0>0 and x1<1536 and y0>0 and y.stop<=1020,(name,x0,x1,y0,y1)
  ref=root/f'Art/References/ApprovedCast20261029/previews/cast_{name}.png'
  registry['people']['cast_'+name]={'texture':'res://'+str(dest.relative_to(root)),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'region':[x0,y0,x1-x0,y1-y0],'pose_height_ratio':1.0,'reference':'res://'+str(ref.relative_to(root)),'reference_sha256':hashlib.sha256(ref.read_bytes()).hexdigest(),'generated_original':str(src),'gaze_review':'direct_camera','expression_review':'closed_mouth_no_smile','source_dimensions':[1536,1024],'region_method':'opaque connected silhouette alpha>=128 plus4px original-source bleed; low-alpha speckle ignored; pixels unchanged'}
(out/'next32_portraits.json').write_text(json.dumps(registry,indent=2)+'\n')
print('registered',len(registry['people']),'unchanged atlases',len(groups))
