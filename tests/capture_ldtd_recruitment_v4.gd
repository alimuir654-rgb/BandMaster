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
 if not ["genre","recruit","name","bio","ready","missing","nia","focus","nia_focus"].has(stage):
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
 if stage=="nia" or stage=="nia_focus":
  var nia_index:int=-1
  var singer_pool:Array=view.Model.pool(view.genre,"Singer")
  for i in range(singer_pool.size()):
   if str(singer_pool[i]["id"])=="nia_griffiths":nia_index=i
  if nia_index<0:
   _fail("Nia Griffiths missing from source catalogue pool")
   return
  view._choose_candidate(nia_index)
  for i in range(3):await process_frame
  if str(view._current()["id"])!="nia_griffiths" or str(view.selected.get("id",""))!="nia_griffiths":
   _fail("native Nia selection lost canonical person")
   return
  var portrait:TextureRect=view.find_child("RecruitmentPortrait",true,false) as TextureRect
  var source_notice:Label=view.find_child("RecruitmentPortraitStatus",true,false) as Label
  if portrait==null or portrait.texture==null or str(portrait.get_meta("candidate_id",""))!="nia_griffiths" or str(portrait.get_meta("art_status",""))!="missing":
   _fail("unsourced Nia must never reuse Alex source photo")
   return
  if not str(portrait.texture.resource_path).ends_with("/photo_pending_contact.svg") or source_notice==null or not source_notice.text.contains("NIA GRIFFITHS"):
   _fail("Nia source portrait/status not honest and named")
   return
  var captions:Array=[]
  for label in view.find_children("*","Label",true,false):captions.append(str(label.text))
  if not captions.has("NIA GRIFFITHS") or not (captions.has("ADD  /  45 PTS") or captions.has("ADD TO BAND  /  45 POINTS")):
   _fail("Nia name or model-backed 45-point price not visible")
   return
  if view.Model.MAX_TALENT-view.Model.spent(view.roster)!=200:
   _fail("candidate browse mutated initial 200-point talent")
   return
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
 var expected_step:int=1 if ["bio","ready","missing","nia","focus","nia_focus"].has(stage) else ["genre","recruit","name"].find(stage)
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
 # Actual 390px first-fold readability/roster clearance regression (12:00).
 if width==390 and stage=="recruit":
  var expected_labels:Array=view.Model.labels_for(view.role)
  var drawn_labels:Array=view.find_children("*","Label",true,false)
  # The viewport may scale X and Y independently. Earlier QA incorrectly
  # measured vertical glyph/target geometry with scale_x (not scale_y).
  var scale_y:float=float(height)/maxf(view.get_viewport_rect().size.y,1.0)
  for attribute in expected_labels:
   var found:bool=false
   for visible_label in drawn_labels:
    if str(visible_label.text)==str(attribute):
     var actual_size:int=visible_label.get_theme_font_size("font_size")
     var physical_h:float=visible_label.get_global_rect().size.y*scale_y
     print("PHONE STAT PIXELS: ",attribute," font=",actual_size," row=",snappedf(physical_h,0.1))
     if actual_size<16 or physical_h<28.0:
      _fail("phone stat "+str(attribute)+" too small: font="+str(actual_size)+" height="+str(physical_h))
      return
     found=true
   if not found:
    _fail("phone missing readable stat "+str(attribute))
    return
  var action_count:=0
  for button in view.find_children("*","TextureButton",true,false):
   for label in button.get_children():
    if label is Label and (str(label.text).begins_with("ADD  /") or str(label.text)=="REMOVE" or str(label.text)=="PERSON FILE"):
     var rb:Rect2=button.get_global_rect()
     if rb.size.y*scale_y<50.0 or rb.end.y*scale_y>float(height)-135.0:
      _fail("phone decision action must be 52px and clear the roster")
      return
     action_count+=1
  if action_count!=2:
   _fail("phone needs recruit and dossier actions both above dock")
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
 if ["recruit","missing","nia","focus","nia_focus"].has(stage):
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
 # 14:00 native source/focus audit: exact six catalogue values and no
 # keyboard/touch access to passive bar controls for both canonical candidates.
 if ["recruit","nia","focus","nia_focus"].has(stage) and (width==390 or width==1280):
  var current:Dictionary=view._current()
  var labels:Array=view.Model.labels_for(view.role)
  var values:Array=view.Model.stats_for(current,view.role)
  var count:=0
  for m in view.find_children("*","Control",true,false):
   if m.get_script()!=load("res://poc/ldtd_recruitment_meter.gd"):continue
   var i:int=int(str(m.name).trim_prefix("RecruitmentMeter"))-1
   if i<0 or i>=6 or str(m.name)!="RecruitmentMeter"+str(i+1):
    _fail("passive attribute has no stable catalogue index")
    return
   if str(m.get_meta("candidate_id",""))!=str(current["id"]) or str(m.get_meta("attribute_label",""))!=str(labels[i]) or int(m.value)!=int(values[i]):
    _fail("wrong person/role/stat value in readonly meter "+str(i))
    return
   if not bool(m.get_meta("read_only",false)) or m.mouse_filter!=Control.MOUSE_FILTER_IGNORE or m.focus_mode!=Control.FOCUS_NONE:
    _fail("attribute is an interactive control")
    return
   count+=1
  if count!=6:
   _fail("not six independent passive meters")
   return
  print("SIX CANONICAL METER VALUES: ",str(current["id"])," = ",values)
  var scale_y:float=float(height)/maxf(view.get_viewport_rect().size.y,1.0)
  var checked:=0
  for key in view.find_children("*","TextureButton",true,false):
   if key.disabled:
    if key.focus_mode!=Control.FOCUS_NONE:
     _fail("disabled source key can receive focus")
     return
    continue
   if key.focus_mode!=Control.FOCUS_ALL or key.texture_normal==null or key.texture_hover==null or key.texture_pressed==null or key.texture_disabled==null or key.texture_focused==null:
    _fail("missing textured visual state or keyboard focus: "+str(key.get_meta("control_caption","?")))
    return
   var rb:Rect2=key.get_global_rect()
   var px:Rect2=Rect2(rb.position.x*scale_x,rb.position.y*scale_y,rb.size.x*scale_x,rb.size.y*scale_y)
   if px.position.x>=-0.5 and px.position.y>=-0.5 and px.end.x<=float(width)+0.5 and px.end.y<=float(height)+0.5:
    if px.size.x<44.0 or px.size.y<44.0:
     _fail("textured control smaller than 44px: "+str(key.get_meta("control_caption","?"))+" "+str(px.size))
     return
    checked+=1
  if checked<8:
   _fail("not enough visible accessible physical controls")
   return
  print("FIVE-STATE TEXTURED CONTROL AUDIT: ",checked," 44px+ native buttons")
 if stage=="focus" or stage=="nia_focus":
  var action:TextureButton=null
  for key in view.find_children("*","TextureButton",true,false):
   if str(key.get_meta("control_caption","")).begins_with("ADD"):action=key
  if action==null or action.disabled:
   _fail("no enabled recruit action to audit focus")
   return
  var spent:int=view.Model.spent(view.roster)
  action.grab_focus()
  for i in range(4):await process_frame
  if not action.has_focus() or action.texture_focused==null:
   _fail("recruit keyboard focus is not visibly textured")
   return
  if view.Model.spent(view.roster)!=spent:
   _fail("keyboard focus changed talent budget")
   return
 var img:Image=get_root().get_texture().get_image()
 if img.get_width()<width or img.get_height()<height:
  _fail("render target too small")
  return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
 if img.save_png(ProjectSettings.globalize_path(output))!=OK:
  _fail("save failed")
  return
 # Same-dimension JPEG is a review/log transport preview only; the original
 # full-resolution lossless PNG stays in the uploaded native artifact.
 if width==1280 and stage=="recruit":
  var preview:String=output.get_basename()+"-review.jpg"
  if img.save_jpg(ProjectSettings.globalize_path(preview),0.72)!=OK:
   _fail("save independent native-size visual preview failed")
   return
 print("LDTD V4 NATIVE SCREENSHOT PASS: "+output)
 view.queue_free()
 quit(0)
