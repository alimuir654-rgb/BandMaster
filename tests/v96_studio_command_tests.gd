extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _actions() -> void:")
 var b := source.find("func _recording_studio() -> void:",a)
 _check(a>=0 and b>a,"studio exists")
 if a>=0 and b>a:
  var studio := source.substr(a,b-a)
  _check(studio.contains('var dashboard := _card("SESSION CONTROL"'),"context control dashboard")
  _check(studio.contains('{"label":"READINESS","key":"readiness"}'),"readiness meter")
  _check(studio.contains('{"label":"TENSION","key":"tension"}'),"tension meter")
  _check(studio.contains('var progress: Dictionary = SongStudio.view(_state())'),"live song data")
  _check(studio.contains('phase_bar.max_value = 3'),"three-session tracker")
  _check(studio.contains('"VIEW BAND RELATIONSHIPS"'),"social route")
  _check(studio.contains('"VIEW CAREER PROGRESS"'),"promotion route")
  _check(studio.contains("content = full_content"),"render parent restored")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene loads")
 if failures==0:
  print("V96 STUDIO COMMAND TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V96 SESSION FAILURE: "+detail)
