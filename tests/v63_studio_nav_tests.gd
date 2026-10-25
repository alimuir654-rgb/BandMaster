extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _actions() -> void:")
 var end := source.find("func _scene() -> void:",start)
 _check(start >= 0 and end > start,"studio source")
 if start >= 0 and end > start:
  var studio := source.substr(start,end-start)
  var selector := studio.find("var switches := _card")
  var art := studio.find("var scene_card := _card")
  _check(selector >= 0 and art > selector,"mode controls before visual card")
  _check(studio.contains("button.pressed.connect"),"navigation actions preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene loads")
 if failures == 0:
  print("V63 STUDIO NAV TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,message: String) -> void:
 if not ok:
  failures += 1
  push_error("V63 STUDIO NAV FAILURE: "+message)
