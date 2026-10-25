extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains('{"JAM":"WRITE & REHEARSE"'),"task-led navigation")
 _check(source.contains('button.icon_start = {"JAM":"music"'),"icon-led modes")
 _check(source.contains('button.size_flags_horizontal = Control.SIZE_EXPAND_FILL'),"responsive mode widths")
 _check(source.contains('var session_strip := HBoxContainer.new()'),"session timeline")
 _check(source.contains('for session_index in range(3):'),"three sessions")
 _check(source.contains('var is_done := session_index < int(studio.get("completed",0))'),"live completion")
 _check(source.contains('["FIND THE IDEA","SHAPE THE SONG","RECORD A FINISH"]'),"clear stage names")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures == 0:
  print("V109 SONGWRITING SESSION UX PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V109 SONGWRITING FAILURE: "+reason)
