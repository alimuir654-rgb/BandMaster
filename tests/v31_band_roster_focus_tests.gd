extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("var selected_band_member := -1"),"default collapsed")
 _check(source.contains("if selected_band_member != index:"),"profile gate")
 _check(source.contains("VIEW DETAILS"),"explicit disclosure action")
 _check(source.contains("selected_band_member = -1 if selected_band_member == index else index"),"reversible toggle")
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(scene != null,"career scene valid")
 if failures == 0:
  print("V31 BAND ROSTER FOCUS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error("V31 ROSTER FAILURE: "+message)
