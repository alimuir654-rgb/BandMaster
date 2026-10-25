extends SceneTree
var failures := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(s.contains("if get_viewport_rect().size.x < 720.0:\n  return\n var identity := _scene_identity()"),"phone suppresses redundant environment dashboard")
 _check(s.contains("if get_viewport_rect().size.x >= 720.0:\n  _label(copy,caption,12,UI.MUTED)"),"phone avoids redundant caption")
 _check(s.contains('indicator.custom_minimum_size.x = 150 if get_viewport_rect().size.x >= 720.0 else 94'),"compact contextual indicator")
 _check(s.contains('indicator.autowrap_mode = TextServer.AUTOWRAP_OFF'),"no vertical character wrapping")
 _check(s.contains('func _scene_instrument_strip() -> void:'),"scene identity still shown")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures == 0:
  print("V124 MOBILE TASK FIRST PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V124 FAILURE: "+reason)
