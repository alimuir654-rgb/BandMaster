extends SceneTree
## Genuine viewport pixels from isolated native Godot 4.7.2 Control tree.
const Scene=preload("res://poc/ldtd_editorial_native_handoff.tscn")
const Model=preload("res://Scripts/recruitment_catalogue_v3.gd")
func _initialize() -> void:
 call_deferred("_run")
func _meters(root: Node) -> Array:
 var found: Array=[]
 for child in root.get_children():
  if str(child.name).begins_with("Meter_") and child is Control:
   found.append(child)
  found.append_array(_meters(child))
 return found
func _die(s: String) -> void:
 push_error("EDITORIAL NATIVE CAPTURE FAILURE: "+s)
 quit(1)
func _run() -> void:
 var w:=390
 var h:=844
 var output:="screenshots/editorial-native-390x844.png"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--width="):w=int(arg.trim_prefix("--width="))
  if arg.begins_with("--height="):h=int(arg.trim_prefix("--height="))
  if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
 if not [(390),(1280)].has(w) or not [(844),(720)].has(h):
  _die("unsupported physical benchmark resolution")
  return
 get_root().size=Vector2i(w,h)
 DisplayServer.window_set_size(Vector2i(w,h))
 var view:Control=Scene.instantiate()
 get_root().add_child(view)
 for i in range(10):await process_frame
 if str(view._person().get("id",""))!="alex":
  _die("Alex ID not tied to original Alex portrait")
  return
 if view._remaining()!=200 or not view.roster.is_empty():
  _die("initial talent and roster must be honest, 200/200 and empty")
  return
 var keys:=view.find_children("*","TextureButton",true,false)
 var role_count:=0
 var recruit:TextureButton=null
 for key in keys:
  if key.name.begins_with("Role_"):
   role_count+=1
   if key.size.y<44 or key.focus_mode!=Control.FOCUS_ALL or key.texture_normal==null:
    _die("role key not physically tappable and source-textured")
    return
  if key.name=="RecruitCTA":
   recruit=key
 if role_count!=5 or recruit==null or recruit.size.y<60 or recruit.texture_pressed==null:
  _die("five native role keys and primary native recruit action required")
  return
 var meters: Array=_meters(view)
 for node in meters:
  if node.focus_mode!=Control.FOCUS_NONE or node.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   _die("meter is interactive")
   return
 if meters.size()!=6:
  _die("exactly six inert native stat meters required, found "+str(meters.size()))
  return
 var captions: Array=[]
 for l in view.find_children("*","Label",true,false):
  captions.append(str(l.text))
 if not captions.has("200 / 200") and not captions.has("TALENT 200 / 200  •  01 OF 06"):
  _die("live native label must show actual 200-point initial pool")
  return
 # This is a screenshot of the engine's real scene, not a flattened artboard.
 var img:Image=get_root().get_texture().get_image()
 if img.get_width()<w or img.get_height()<h:
  _die("physical viewport smaller than target")
  return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
 if img.save_png(ProjectSettings.globalize_path(output))!=OK:
  _die("native PNG save failed")
  return
 print("EDITORIAL NATIVE GODOT SCREENSHOT PASS: "+output+" ("+str(w)+"x"+str(h)+")")
 view.queue_free()
 quit(0)
