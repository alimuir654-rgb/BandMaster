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
 if not ["genre","recruit","name"].has(stage):
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
 if stage=="name":
  for p in view.Model.people():
   if ["alex","jo","sam"].has(str(p["id"])):
    view.roster.append(p)
  view._next()
  for i in range(4):await process_frame
 if view.step!=["genre","recruit","name"].find(stage):
  _fail("scene step contract")
  return
 var scale_x:=float(width)/maxf(view.get_viewport_rect().size.x,1.0)
 var hit_count:=0
 var touches:=view.find_children("*","TextureButton",true,false)
 for child in touches:
  var rect:Rect2=child.get_global_rect()
  if child.is_visible_in_tree() and not child.disabled and rect.position.y*scale_x<height and rect.size.y*scale_x>=44.0 and rect.end.y*scale_x<=height+3:
   hit_count+=1
 if hit_count==0:
  _fail("no visible 44 physical pixel source-textured control")
  return
 if stage=="recruit":
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
