extends SceneTree
var failures := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := s.find("func _actions() -> void:")
 var b := s.find("func _recording_studio() -> void:",a)
 _check(a>=0 and b>a,"studio section exists")
 if a>=0 and b>a:
  var studio := s.substr(a,b-a)
  var action := studio.find("var jam := UI.themed_button")
  var history := studio.find("var sessions_card := _card")
  _check(action>=0 and history>action,"commit action is before previous sessions")
  _check(studio.contains("COMMIT TO THIS SONG  /  1 DAY"),"decision costs a day")
  _check(studio.contains("Practice.compose(_state()"),"composition gameplay preserved")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene imports")
 if failures==0:
  print("V73 SONGWRITING UX TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V73 SONGWRITING FAILURE: "+reason)
