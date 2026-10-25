extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _home() -> void:")
 var b := source.find("func _gigs() -> void:",a)
 _check(a>=0 and b>a,"home screen")
 if a>=0 and b>a:
  var home := source.substr(a,b-a)
  var photo := home.find("var feature_path :=")
  var focus := home.find("var guidance: Dictionary")
  _check(photo>=0 and focus>photo,"band identity artwork precedes decision")
  _check(home.contains("if ResourceLoader.exists(feature_path)"),"art optional")
  _check(home.contains("CareerLayout.is_compact"),"responsive image")
  _check(home.contains("var destination := str(guidance.get"),"decision preserved")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene loads")
 if failures==0:
  print("V65 HOME ART TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V65 HOME FAILURE: "+detail)
