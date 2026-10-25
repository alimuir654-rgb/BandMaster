extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("func _reveal_destination() -> void:"),"shared navigation reveal exists")
 _check(source.contains('veil.mouse_filter = Control.MOUSE_FILTER_IGNORE'),"transition never blocks input")
 _check(source.contains('tween.tween_property(veil,"modulate:a",0.0,0.22)'),"short transition duration")
 _check(source.contains("tween.tween_callback(veil.queue_free)"),"veil cleaned up")
 _check(source.contains("if tab == next_tab:\n  return"),"repeat tab does not flicker")
 _check(source.contains("tab = next_tab\n _render()\n _reveal_destination()"),"screen rendered before reveal")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene loads")
 if failures == 0:
  print("V122 NAVIGATION MOTION PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("V122 MOTION FAILURE: "+why)
