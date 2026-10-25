extends SceneTree
var failures := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := s.find("func _actions() -> void:")
 var b := s.find("func _scene() -> void:",a)
 _check(a >= 0 and b > a,"studio source")
 if a >= 0 and b > a:
  var studio := s.substr(a,b-a)
  _check(studio.contains("TODAY IN THE STUDIO"),"compact status")
  _check(not studio.contains("BEFORE YOU PLAY"),"redundant preamble removed")
  _check(not studio.contains("_progress(heading"),"no oversized top meters")
  _check(studio.find("var switches :=") < studio.find("if action_view == \"JAM\":"),"activity choices before studio")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures == 0:
  print("V61 STUDIO FIRST TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("V61 STUDIO FAILURE: "+why)
