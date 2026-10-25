extends SceneTree
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains('func _show_stage_entry() -> void:'),"stage confirmation exists")
 _check(src.contains('"StageEntry"'),"stage view named")
 _check(src.contains('start.disabled = true'),"confirm guards repeat")
 _check(src.contains('_action(stack,"BACK TO SOUNDCHECK"'),"cancel has action")
 _check(src.contains('func _is_show_day() -> bool:'),"show day grounded in booked date")
 _check(src.contains('if _is_show_day() and next_tab != "GIGS":'),"navigating away on show day blocked")
 _check(src.contains('if _is_show_day() and not source.begins_with("gig:")'),"transactions guarded")
 _check(src.contains('if _is_show_day():\n  tab = "GIGS"'),"show-day opens Gigs")
 _check(src.contains('func _perform_gig() -> void:'),"authoritative performance preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene parses")
 if failures==0: print("V133 SHOW DAY PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V133 FAILURE: "+reason)
