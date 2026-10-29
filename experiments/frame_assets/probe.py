"""Render own source inspection images from unmodified CC0 geometry/materials."""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path('c24-sources').resolve();OUT=Path('c24-probe').resolve();OUT.mkdir(exist_ok=True)
manifest=json.loads((ROOT/'SOURCE_MANIFEST.json').read_text());report={'blender':bpy.app.version_string,'assets':[]}
def bounds(objects):
    points=[o.matrix_world@Vector(p) for o in objects for p in o.bound_box]
    lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    return lo,hi
for item in manifest['assets']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path=Path(item['model']).resolve();bpy.ops.import_scene.gltf(filepath=str(path))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert meshes
    lo,hi=bounds(meshes);centre=(lo+hi)/2;size=hi-lo;extent=max(size)
    inventory=[]
    for o in meshes:
        a,b=bounds([o]);inventory.append({'name':o.name,'bounds':[list(a),list(b)],'size':list(b-a),'vertices':len(o.data.vertices),'materials':[m.name if m else None for m in o.data.materials]})
    report['assets'].append({'id':item['id'],'bounds':[list(lo),list(hi)],'objects':inventory,'images':[{'name':im.name,'size':list(im.size),'filepath':im.filepath} for im in bpy.data.images]})
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=20;scene.cycles.use_denoising=True
    scene.render.resolution_x=1024;scene.render.resolution_y=1024;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
    scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
    scene.world=bpy.data.worlds.new('Soft studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(0.5,0.5,0.5,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
    thin=min(range(3),key=lambda i:size[i]);normal=Vector((0,0,0));normal[thin]=1
    up=Vector((0,1,0)) if thin!=1 else Vector((0,0,1));right=up.cross(normal)
    for name,offset,energy,scale in [('Key',normal*3-right*1.7+up*1.8,300,2),('Fill',normal*2+right*2-up*.5,110,2.5)]:
        lamp=bpy.data.lights.new(name,'AREA');lamp.energy=energy*extent*extent;lamp.shape='DISK';lamp.size=scale*extent
        ob=bpy.data.objects.new(name,lamp);scene.collection.objects.link(ob);ob.location=centre+offset*extent;ob.rotation_euler=(centre-ob.location).to_track_quat('-Z','Y').to_euler()
    cam=bpy.data.cameras.new('Ortho');cam.type='ORTHO';cam.ortho_scale=extent*1.12
    camera=bpy.data.objects.new('Ortho',cam);scene.collection.objects.link(camera);scene.camera=camera
    for suffix,direction in [('top',normal),('reverse',-normal)]:
        camera.location=centre+direction*extent*3;camera.rotation_euler=(-direction).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(OUT/(item['id']+'-'+suffix+'.png'));bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(item['id']+'-inspection.blend')))
(OUT/'GEOMETRY_REPORT.json').write_text(json.dumps(report,indent=2)+'\n')
