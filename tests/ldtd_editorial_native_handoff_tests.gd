extends SceneTree
const Scene=preload("res://poc/ldtd_editorial_native_handoff.tscn")
const Model=preload("res://Scripts/recruitment_catalogue_v3.gd")
var errors:=0
func _meters(root: Node) -> Array:
 var found: Array=[]
 for child in root.get_children():
  if str(child.name).begins_with("Meter_") and child is Control:
   found.append(child)
  found.append_array(_meters(child))
 return found
func _initialize() -> void:
 call_deferred("_run")
func _check(v: bool,msg: String) -> void:
 if not v:
  errors+=1
  push_error("EDITORIAL NATIVE TEST FAILURE: "+msg)
func _run() -> void:
 # Use a real 1280x720 X display, not the 1x1 headless display stub.
 get_root().size=Vector2i(1280,720)
 DisplayServer.window_set_size(Vector2i(1280,720))
 var view:Control=Scene.instantiate()
 get_root().add_child(view)
 for i in range(5):await process_frame
 _check(view._person()["id"]=="alex","Alex original identity matches authored Alex portrait")
 _check(view._remaining()==200,"empty roster begins with exact 200 points")
 _check(view.roster.is_empty(),"no fictitious signed members")
 var alex:Dictionary=view._person()
 _check(Model.cost(alex)==51,"Alex cost is 51 from authoritative model, not design-artboard fiction of 40")
 view._recruit()
 _check(view.roster.size()==1 and Model.contains(view.roster,"alex"),"recruit action updates local roster")
 _check(view._remaining()==149,"51-point recruitment leaves exactly 149/200")
 view._recruit()
 _check(view.roster.is_empty() and view._remaining()==200,"remove reverses recruitment without saves")
 view._choose_role(1)
 _check(view.role=="Guitarist" and view.candidate_index==0,"native role switch uses real model")
 view._browse(1)
 _check(view.candidate_index==1,"candidate browse changes actual selection")
 _check(view._person().has("id"),"candidate selection remains authoritative")
 var found_meters: Array=_meters(view)
 print("EDITORIAL NATIVE METER COUNT:",found_meters.size())
 for c in found_meters:
  _check(c.focus_mode==Control.FOCUS_NONE and c.mouse_filter==Control.MOUSE_FILTER_IGNORE,"meter never captures focus/input")
 _check(found_meters.size()==6,"six native, non-interactive stat bars")
 _check(not view.has_method("_style"),"legacy V3 flat helper quarantined")
 view.queue_free()
 if errors==0:print("EDITORIAL NATIVE HANDOFF TEST PASS: real model, local interaction, six inert meters, no saves")
 quit(0 if errors==0 else 1)
