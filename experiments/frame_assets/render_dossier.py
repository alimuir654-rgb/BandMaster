"""Own offline dossier layers from reviewed CC0 meshes. No native UI baked in."""
import bpy,bmesh,json,math,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path('c24-sources').resolve();OUT=Path('c24-art').resolve();OUT.mkdir(exist_ok=True)
def bounds(objects):
    bpy.context.view_layer.update()
    pts=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    return Vector([min(p[i] for p in pts) for i in range(3)]),Vector([max(p[i] for p in pts) for i in range(3)])
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def import_model(name):
    before=set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/name/(name+'_2k.gltf')))
    result=[o for o in bpy.context.scene.objects if o not in before and o.type=='MESH']
    bpy.context.view_layer.update()
    for o in result:
        world=o.matrix_world.copy();o.data=o.data.copy();o.data.transform(world)
        o.parent=None;o.matrix_world=Matrix.Identity(4);o.data.update()
    bpy.context.view_layer.update()
    return result
bpy.ops.wm.read_factory_settings(use_empty=True)
original=import_model('clipboard')[0]
bm=bmesh.new();bm.from_mesh(original.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
islands=[];pending=set(bm.verts)
while pending:
    todo=[pending.pop()];part=set(todo)
    while todo:
        for edge in todo.pop().link_edges:
            for v in edge.verts:
                if v in pending:pending.remove(v);part.add(v);todo.append(v)
    islands.append(part)
assert len(islands)==5,('unexpected clipboard construction',len(islands))
def area(part):return (max(v.co.x for v in part)-min(v.co.x for v in part))*(max(v.co.y for v in part)-min(v.co.y for v in part))
board_part=max(islands,key=area);bm.verts.index_update();board_indices={v.index for v in board_part};parts={}
for role in ['board','clip']:
    copy=bm.copy();copy.verts.ensure_lookup_table();copy.verts.index_update()
    remove=[v for v in copy.verts if (v.index not in board_indices if role=='board' else v.index in board_indices)]
    bmesh.ops.delete(copy,geom=remove,context='VERTS')
    mesh=bpy.data.meshes.new('C24_'+role);copy.to_mesh(mesh);copy.free();mesh.materials.append(original.data.materials[0])
    ob=bpy.data.objects.new('C24_'+role,mesh);bpy.context.scene.collection.objects.link(ob);parts[role]=ob
bm.free();bpy.data.objects.remove(original,do_unlink=True)
board=parts['board'];clip=parts['clip'];lo,hi=bounds([clip]);c=(lo+hi)/2
for v in clip.data.vertices:v.co=(v.co-Vector((c.x,c.y,lo.z)))*.46+Vector((0,.141,.0033))
clip.data.update()
clip_mat=clip.data.materials[0].copy();clip_mat.name='C24 worn clip without stamped normal lettering'
for node in clip_mat.node_tree.nodes:
    if node.type=='BSDF_PRINCIPLED':
        for link in list(node.inputs['Normal'].links):clip_mat.node_tree.links.remove(link)
clip.data.materials.clear();clip.data.materials.append(clip_mat)
cork_path=Path('/tmp/c24-source/cork.png');assert cork_path.exists()
mat=bpy.data.materials.new('C24 inherited photographed cork finish');mat.use_nodes=True
nodes=mat.node_tree.nodes;links=mat.node_tree.links;p=nodes.get('Principled BSDF')
tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(cork_path));tex.extension='REPEAT'
uvnode=nodes.new('ShaderNodeUVMap');uvnode.uv_map='C24_Planar';links.new(uvnode.outputs['UV'],tex.inputs['Vector']);links.new(tex.outputs['Color'],p.inputs['Base Color']);p.inputs['Roughness'].default_value=.84
board.data.materials.clear();board.data.materials.append(mat)
uv=board.data.uv_layers.new(name='C24_Planar');lo,hi=bounds([board])
for poly in board.data.polygons:
    for li in poly.loop_indices:
        co=board.data.vertices[board.data.loops[li].vertex_index].co
        uv.data[li].uv=((co.x-lo.x)/(hi.x-lo.x)*2.8,(co.y-lo.y)/(hi.y-lo.y)*3.6)
notepads=import_model('office_notepads');paper=[]
for name,offset,angle,height in [('office_notepads_a4_b',(-.0015,-.003),-.7,.0031),('office_notepads_a4_c',(.0014,-.005),.45,.0035),('office_notepads_a4_a',(0,-.004),0,.0040)]:
    o=next(x for x in notepads if x.name==name)
    # Mesh coordinates are already in world space. Do not use cached object boxes.
    points=[v.co.copy() for v in o.data.vertices]
    mid=Vector([(min(p[i] for p in points)+max(p[i] for p in points))/2 for i in range(3)])
    for v in o.data.vertices:
        x=v.co.x-mid.x;y=v.co.y-mid.y
        curl=.00075*(abs(x)/.105)**7*(abs(y)/.145)**5
        v.co=Vector((x,y,height+curl))
    o.rotation_euler.z=math.radians(angle);o.location=Vector((offset[0],offset[1],0));o.data.update();paper.append(o)
for o in notepads:
    if o not in paper:bpy.data.objects.remove(o,do_unlink=True)
geometry=[]
for o in paper:
    lo,hi=bounds([o]);assert lo.x>-.113 and hi.x<.113 and lo.y>-.158 and hi.y<.158,(o.name,list(lo),list(hi))
    assert abs((lo.x+hi.x)/2)<.004 and abs((lo.y+hi.y)/2)<.008
    geometry.append({'name':o.name,'bounds':[list(lo),list(hi)]})
mat=paper[0].data.materials[0].copy();mat.name='C24 source-paper warm stock'
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');inp=bsdf.inputs['Base Color'];source=inp.links[0].from_socket
mix=mat.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(1,.95,.83,1)
mat.node_tree.links.new(source,mix.inputs[1]);mat.node_tree.links.new(mix.outputs[0],inp)
for o in paper:o.data.materials.clear();o.data.materials.append(mat)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=64;scene.cycles.use_denoising=False
scene.cycles.max_bounces=5;scene.render.resolution_x=1024;scene.render.resolution_y=1365;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.film_transparent=True
scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=-.5
scene.world=bpy.data.worlds.new('Neutral studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.5,.5,.5,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.3
for name,pos,energy,sz in [('Key',(-.3,.42,.65),18,.28),('Fill',(.35,-.12,.6),5,.4)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=energy;light.shape='DISK';light.size=sz
    o=bpy.data.objects.new(name,light);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
cam=bpy.data.cameras.new('Source ortho');cam.type='ORTHO';cam.ortho_scale=.365
camera=bpy.data.objects.new('Source ortho',cam);scene.collection.objects.link(camera);camera.location=(0,0,.8);camera.rotation_euler=(0,0,0);scene.camera=camera
roles={'board':[board],'paper':paper,'clip':[clip]};all_objects=[board,*paper,clip]
record={'schema_version':1,'owner_approved':False,'source_type':'Own orthographic offline renders of CC0 Poly Haven Clipboard and Office Notepads meshes, with inherited source cork finish. Not new photography, website examples or final approved art.','sources':json.loads((ROOT/'SOURCE_MANIFEST.json').read_text()),'construction':{'clipboard_islands':len(islands),'sheets':geometry,'clip_uniform_scale':.46,'board_finish':'Inherited photographed cork, planar repeat 2.8x3.6','camera':'Orthographic +Z, identical for all layers','clip_material_change':'Original colour/roughness retained; stamped normal detail disconnected','cork_source_record':json.loads(Path('/tmp/c24-source/CORK_SOURCE.json').read_text()),'lighting':'Fixed neutral world and two soft area lights','paper_transform':'Preserved source UV/grain, tiny corner lift, three centred offset sheets, warm tint'},'layers':[]}
for role,visible in [('full',all_objects),*roles.items()]:
    for o in all_objects:o.visible_camera=o in visible
    dest=OUT/('dossier_'+role+'.png');scene.render.filepath=str(dest);bpy.ops.render.render(write_still=True)
    record['layers'].append({'role':role,'file':dest.name,'sha256':sha(dest),'dimensions':[1024,1365],'alpha':'RGBA','labels':'none','safe_area_normalized':[.16,.17,.84,.89]})
for o in all_objects:o.visible_camera=True
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'dossier_source.blend'))
(OUT/'SOURCE_RENDER_MANIFEST.json').write_text(json.dumps(record,indent=2)+'\n')
print('C24 source layers complete; sheet extents verified')
