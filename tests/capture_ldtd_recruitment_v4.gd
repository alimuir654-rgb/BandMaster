extends SceneTree
const Scene = preload("res://poc/ldtd_recruitment_v4.tscn")
func _initialize() -> void: call_deferred("_run")
func _fail(reason: String) -> void:
 push_error("V4 CAPTURE FAILURE: "+reason)
 quit(1)
func _run() -> void:
 var width:=390
 var height:=844
 var stage:="recruit"
 var output:="screenshots/v4-recruit-390x844.png"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--width="):width=int(arg.trim_prefix("--width="))
  if arg.begins_with("--height="):height=int(arg.trim_prefix("--height="))
  if arg.begins_with("--stage="):stage=arg.trim_prefix("--stage=")
  if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
 if not ["genre","recruit","name","bio","ready","missing"].has(stage):
  _fail("unknown stage")
  return
 get_root().size=Vector2i(width,height)
 DisplayServer.window_set_size(Vector2i(width,height))
 var view:Control=Scene.instantiate()
 get_root().add_child(view)
 for i in range(8):await process_frame
 if stage!="genre":
  view._next()
  for i in range(4):await process_frame
 if stage=="missing":
  view._move(1)
  for i in range(2):await process_frame
  if str(view._current()["id"])!="josh_bennett" or ResourceLoader.exists("res://Art/Portraits/indie/josh_bennett.webp"):
   _fail("unsourced portrait proof must use Josh without an existing photo")
   return
 if stage=="name" or stage=="ready":
  for p in view.Model.people():
   if ["alex","jo","sam"].has(str(p["id"])):
    view.roster.append(p)
  if stage=="name":
   view._next()
  else:
   view._render()
  for i in range(4):await process_frame
 if stage=="bio":
  view._show_dossier()
  for i in range(4):await process_frame
 var expected_step:int=1 if ["bio","ready","missing"].has(stage) else ["genre","recruit","name"].find(stage)
 if view.step!=expected_step or (stage=="bio" and not view._bio_open) or (stage=="ready" and not view.Model.viable(view.roster)):
  _fail("scene step contract")
  return
 if width<=450 and (stage=="recruit" or stage=="ready" or stage=="missing"):
  var captions:Array=[]
  for label in view.find_children("*","Label",true,false):
   captions.append(str(label.text))
  for role_caption in ["SING","GUITAR","BASS","KEYS","DRUMS"]:
   if not captions.has(role_caption):
    _fail("phone cannot directly reach "+role_caption)
    return
  if stage=="ready" and not captions.has("NAME BAND ›"):
   _fail("viable phone roster cannot reach name-last stage")
   return
 var scale_x:=float(width)/maxf(view.get_viewport_rect().size.x,1.0)
 if stage=="ready":
  var name_key:TextureButton=null
  var recruit_key:TextureButton=null
  for key in view.find_children("*","TextureButton",true,false):
   for child in key.get_children():
    if child is Label:
     if str(child.text).begins_with("NAME BAND"):name_key=key
     if str(child.text)=="REMOVE" or str(child.text).begins_with("ADD TO BAND") or str(child.text).begins_with("ADD  /"):recruit_key=key
  if name_key==null or recruit_key==null:
   _fail("viable roster needs both recruitment and name-stage actions")
   return
  if name_key.get_global_rect().intersects(recruit_key.get_global_rect()):
   _fail("name-stage key overlaps recruit key")
   return
  if name_key.get_global_rect().size.y*scale_x<44.0:
   _fail("name-stage key below 44 physical pixels")
   return
 # Desktop 11:00 real-material pilot: the recruitment stage must show three
 # independent 8-piece photographed Lab07 metal perimeters. Their AtlasTexture
 # regions must reference the unchanged 966x426 owner-supplied PNG. No centre
 # text can be baked into a simulated source frame or obscure the live UI.
 if width==1280 and stage=="recruit":
  for frame_name in ["RecruitmentCandidateMetalFrame","RecruitmentDossierMetalFrame","RecruitmentHeroMetalFrame"]:
   var frame:Control=view.find_child(frame_name,true,false) as Control
   if frame==null or frame.get_child_count()!=8:
    _fail("missing independently assembled photographed desktop frame "+frame_name)
    return
   for piece in frame.get_children():
    if not (piece is TextureRect):
     _fail("desktop metal frame has non-image piece "+frame_name)
     return
    var rect:TextureRect=piece as TextureRect
    var atlas:AtlasTexture=rect.texture as AtlasTexture
    if atlas==null or atlas.atlas==null or atlas.atlas.resource_path!="res://bandmaster_premium_controls_lab/assets/channel_studio_idle.png":
     _fail("bezel piece lacks source-verified Lab07 photograph "+frame_name)
     return
    if rect.mouse_filter!=Control.MOUSE_FILTER_IGNORE or rect.focus_mode!=Control.FOCUS_NONE:
     _fail("decorative photographed frame intercepts focus/touch "+frame_name)
     return
    var crop:Rect2=atlas.region
    var source_w:float=float(atlas.atlas.get_width())
    var source_h:float=float(atlas.atlas.get_height())
    if crop.position.x>70.0 and crop.position.x+crop.size.x<source_w-70.0 and crop.position.y>65.0 and crop.position.y+crop.size.y<source_h-65.0:
     _fail("cropped centre of source contains baked GUITAR/CHANNEL text "+frame_name)
     return
 # Real visual defect regression at 09:07: the 160x160 Alex photo was
 # severely cropped in both wide hero frames. Preserve the entire source
 # until the rights-traced portrait masters replace the legacy thumbnails.
 if stage=="recruit" and (width==390 or width==1280):
  var hero_source:TextureRect=view.find_child("RecruitmentPortrait",true,false) as TextureRect
  if hero_source==null or hero_source.texture==null:
   _fail("missing sourced Alex hero for crop-policy check")
   return
  var source_dims:Vector2=hero_source.texture.get_size()
  var is_legacy:bool=minf(source_dims.x,source_dims.y)<512.0
  var ratio_source:float=source_dims.x/maxf(source_dims.y,1.0)
  var ratio_frame:float=hero_source.size.x/maxf(hero_source.size.y,1.0)
  var fraction_visible:float=minf(ratio_source/ratio_frame,ratio_frame/ratio_source)
  if is_legacy and fraction_visible<0.84 and hero_source.stretch_mode!=TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
   _fail("wide hero cropped legacy identity portrait instead of preserving full face")
   return
 var hit_count:=0
 var touches:=view.find_children("*","TextureButton",true,false)
 for child in touches:
  var rect:Rect2=child.get_global_rect()
  if child.is_visible_in_tree() and not child.disabled and rect.position.y*scale_x<height and rect.size.y*scale_x>=44.0 and rect.end.y*scale_x<=height+3:
   hit_count+=1
 if hit_count==0:
  _fail("no visible 44 physical pixel source-textured control")
  return
 # Physical-size visual hierarchy regression: the 390px phone must show
 # a dominant portrait AND six inert stats immediately below it. These are
 # measurable geometry checks, not an art-direction acceptance.
 if width==390 and stage=="recruit":
  var hero:Control=view.find_child("RecruitmentPortrait",true,false) as Control
  if hero==null:
   _fail("phone missing named hero portrait source node")
   return
  var hero_rect:Rect2=hero.get_global_rect()
  if hero_rect.size.x*scale_x<330.0 or hero_rect.size.y*scale_x<220.0:
   _fail("phone portrait not visually dominant at physical pixels")
   return
  var first_meter_y:float=1000000.0
  for meter_node in view.find_children("*","Control",true,false):
   if meter_node.get_script()==load("res://poc/ldtd_recruitment_meter.gd"):
    first_meter_y=minf(first_meter_y,meter_node.get_global_rect().position.y*scale_x)
  if first_meter_y<hero_rect.end.y*scale_x-1.0 or first_meter_y>hero_rect.end.y*scale_x+75.0:
   _fail("phone six-meter bank not directly below hero portrait")
   return
 if stage=="recruit" or stage=="missing":
  var count:=0
  for child in view.find_children("*","Control",true,false):
   if child.get_script()==load("res://poc/ldtd_recruitment_meter.gd"):
    count+=1
    if child.focus_mode!=Control.FOCUS_NONE or child.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
     _fail("editable stat meter")
     return
  if count!=6:
   _fail("need six inert attribute meters")
   return
 var img:Image=get_root().get_texture().get_image()
 if img.get_width()<width or img.get_height()<height:
  _fail("render target too small")
  return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
 if img.save_png(ProjectSettings.globalize_path(output))!=OK:
  _fail("save failed")
  return
 print("LDTD V4 NATIVE SCREENSHOT PASS: "+output)
 view.queue_free()
 quit(0)
