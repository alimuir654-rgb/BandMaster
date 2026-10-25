extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("var readable_size := size + 2 if get_viewport_rect().size.x >= 960.0 and size <= 17 else size"),"desktop readability without mobile change")
 _check(source.contains('button.add_theme_font_size_override("font_size",15 if get_viewport_rect().size.x >= 960.0 else 12)'),"desktop activity controls")
 _check(source.contains('experiment_button.add_theme_font_size_override("font_size",14 if get_viewport_rect().size.x >= 960.0 else 12)'),"desktop creative controls")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career imports")
 if failures==0:
  print("V88 DESKTOP READABILITY PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V88 READABILITY FAILURE: "+reason)
