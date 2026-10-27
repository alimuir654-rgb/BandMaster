extends SceneTree
## Actual Godot renderer proof, not a mockup screenshot.
const Scene = preload("res://poc/ldtd_recruitment_v3.tscn")
const Model = preload("res://Scripts/recruitment_catalogue_v3.gd")
func _initialize() -> void:
 call_deferred("_capture")

func _fail(why: String) -> void:
 push_error("V3 SCREENSHOT FAILURE: "+why)
 quit(1)

func _capture() -> void:
 var width := 390
 var height := 844
 var stage := "recruit"
 var output := "screenshots/v3-recruit-390x844.png"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--width="):
   width=int(arg.trim_prefix("--width="))
  elif arg.begins_with("--height="):
   height=int(arg.trim_prefix("--height="))
  elif arg.begins_with("--stage="):
   stage=arg.trim_prefix("--stage=")
  elif arg.begins_with("--output="):
   output=arg.trim_prefix("--output=")
 if not ["genre","recruit","name"].has(stage):
  _fail("unknown stage")
  return
 get_root().size=Vector2i(width,height)
 DisplayServer.window_set_size(Vector2i(width,height))
 var view: Control=Scene.instantiate()
 get_root().add_child(view)
 for i in range(10):
  await process_frame
 if stage!="genre":
  view._continue()
  for i in range(5):
   await process_frame
 if stage=="name":
  var required: Array=[]
  for p in Model.people():
   if ["alex","sam","jo"].has(str(p["id"])):
    required.append(p)
  view.roster=required
  view._continue()
  for i in range(5):
   await process_frame
 if stage=="genre" and view.step!=0 or stage=="recruit" and view.step!=1 or stage=="name" and view.step!=2:
  _fail("incorrect journey step")
  return
 var real_width := view.get_viewport_rect().size.x
 var multiplier := float(width)/maxf(real_width,1.0)
 var actions: Array=view.find_children("*","Button",true,false)
 var eligible := 0
 for button in actions:
  if button is Button and button.is_visible_in_tree() and not button.disabled and button.get_global_rect().size.y*multiplier>=44.0 and button.get_global_rect().end.y*multiplier <= float(height)+2.0:
   eligible+=1
 if eligible==0:
  _fail("no first-fold physical >=44px actionable button")
  return
 if stage=="recruit":
  var source_meters: Array=view.find_children("*","Control",true,false)
  var real_meters := 0
  for node in source_meters:
   if node.get_script()==load("res://poc/ldtd_recruitment_meter.gd"):
    real_meters+=1
    if node.focus_mode!=Control.FOCUS_NONE or node.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
     _fail("read-only attribute meter is interactive")
     return
  if real_meters!=6:
   _fail("portrait must have six actual attribute meters underneath")
   return
 var image: Image=get_root().get_texture().get_image()
 if image.get_width()<width or image.get_height()<height:
  _fail("native dimensions too small")
  return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
 if image.save_png(ProjectSettings.globalize_path(output))!=OK:
  _fail("save native screenshot failed")
  return
 print("LDTD RECRUITMENT V3 ACTUAL GODOT SCREENSHOT PASSED "+output)
 view.queue_free()
 quit(0)
