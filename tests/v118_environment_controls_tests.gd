extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 for label in ["ON THE NOTICEBOARD","DAY PLANNER","CONTROL DESK","FRONT OF HOUSE","func _environment_dashboard() -> void:"]:
  _check(source.contains(label),label)
 for tab in ["_actions"]:
  _check(source.contains("func "+tab+"() -> void:\n _scene_instrument_strip()\n _environment_dashboard()"),tab+" displays custom environment")
 _check(source.contains("func _home() -> void:\n _scene_instrument_strip()"),"home context strip preserved")
 _check(source.contains("func _gigs() -> void:\n _scene_instrument_strip()"),"gig context strip preserved")
 _check(source.contains("Calendar.pending(_state())"),"home diary uses booked gig")
 _check(source.contains('UI.themed_progress(meter,_genre_id()'),"studio channels use real levels")
 _check(source.contains('control.pressed.connect(func() -> void: _switch(target))'),"home shortcuts work")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures==0:
  print("V118 ENVIRONMENT CONTROLS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V118 CONTROL FAILURE: "+reason)
