extends SceneTree
var failures := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := s.find("func _actions() -> void:")
 var b := s.find("func _recording_studio() -> void:",a)
 _check(a>=0 and b>a,"studio present")
 if a>=0 and b>a:
  var studio := s.substr(a,b-a)
  _check(studio.contains('var phase_names := ["IDEA","SHAPE","FINISH"]'),"three clear creative phases")
  _check(studio.contains("stage_style.border_width_bottom = 3 if step == completed_sessions"),"active stage indicated")
  _check(studio.contains("OF 3 SESSIONS COMPLETE"),"progress understandable")
  _check(studio.contains("SongLab.remix"),"creative experimentation retained")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene parses")
 if failures==0:
  print("V79 WRITING STAGES TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V79 STAGE FAILURE: "+reason)
