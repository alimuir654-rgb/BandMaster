"""Calibrate the inspected source scene, never paint over clipped detail."""
from pathlib import Path
import bpy,json,hashlib
from PIL import Image,ImageStat
SRC=Path('c24-reviewed-source/c24-art').resolve();OUT=Path('c24-art').resolve();OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SRC/'dossier_source.blend'))
for im in bpy.data.images:
    if im.source=='FILE':
        if not Path(bpy.path.abspath(im.filepath)).exists():
            match=list(Path('c24-sources').resolve().rglob(Path(im.filepath).name))
            if match:im.filepath=str(match[0]);im.reload()
        assert Path(bpy.path.abspath(im.filepath)).is_file(),im.filepath
scene=bpy.context.scene
board=bpy.data.objects['C24_board'];clip=bpy.data.objects['C24_clip']
paper=[bpy.data.objects[n] for n in ['office_notepads_a4_a','office_notepads_a4_b','office_notepads_a4_c']]
all_objects=[board,*paper,clip]
scene.cycles.samples=16;scene.cycles.use_denoising=False;scene.render.resolution_percentage=25
probes=[]
for exposure in [-1.0,-1.5,-2.0,-2.5,-3.0]:
    scene.view_settings.exposure=exposure
    for o in all_objects:o.visible_camera=True
    dest=OUT/('exposure_'+str(exposure)+'.png');scene.render.filepath=str(dest);bpy.ops.render.render(write_still=True)
    im=Image.open(dest).convert('RGB');centre=im.crop((int(im.width*.3),int(im.height*.3),int(im.width*.7),int(im.height*.7)))
    median=sum(ImageStat.Stat(centre).median)/3
    clipped=sum(1 for r,g,b in centre.getdata() if min(r,g,b)>=254)/(centre.width*centre.height)
    probes.append({'exposure':exposure,'median':median,'clipped_fraction':clipped,'file':dest.name})
choice=min(probes,key=lambda r:abs(r['median']-230)+1000*r['clipped_fraction'])
assert 170<choice['median']<247 and choice['clipped_fraction']<.03,probes
scene.view_settings.exposure=choice['exposure'];scene.render.resolution_percentage=100;scene.cycles.samples=48
record=json.loads((SRC/'SOURCE_RENDER_MANIFEST.json').read_text());record['layers']=[]
record['exposure_calibration']={'probes':probes,'chosen':choice,'method':'Small renders of the same source geometry and materials, fixed lighting; only exposure changes. No source-texture substitution.'}
roles={'full':all_objects,'board':[board],'paper':paper,'clip':[clip]}
for role,visible in roles.items():
    for o in all_objects:o.visible_camera=o in visible
    dest=OUT/('dossier_'+role+'.png');scene.render.filepath=str(dest);bpy.ops.render.render(write_still=True)
    record['layers'].append({'role':role,'file':dest.name,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'dimensions':[1024,1365],'alpha':'RGBA','labels':'none','safe_area_normalized':[.16,.17,.84,.89]})
(OUT/'SOURCE_RENDER_MANIFEST.json').write_text(json.dumps(record,indent=2)+'\n')
print('Calibrated source:',choice)
