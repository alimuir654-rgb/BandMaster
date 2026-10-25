extends SceneTree
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var home_start := src.find("func _home() -> void:")
 var gigs_start := src.find("func _gigs() -> void:")
 var gear_start := src.find("func _gear() -> void:")
 var home := src.substr(home_start,gigs_start-home_start)
 var gigs := src.substr(gigs_start,gear_start-gigs_start)
 _check(home.find("var focus := _card") >= 0,"home next action exists")
 _check(home.find("var focus := _card") < home.find("_home_spotlight()"),"home next action before photo")
 _check(home.find("var focus := _card") < home.find("_environment_dashboard()",home.find("func _home()")),"home next action before decoration")
 _check(gigs.find("var booked: Dictionary = Calendar.pending(_state())") < gigs.find("var briefing_card := _card"),"booked action before briefing")
 _check(gigs.find("var booked: Dictionary = Calendar.pending(_state())") < gigs.find("var report := _card"),"gig action before previous show")
 _check(gigs.find("var calendar_box := _card") < gigs.find("_editorial_banner("),"night control before photo")
 _check(gigs.contains("BackstageIncident.incident(_state())"),"soundcheck decision retained")
 _check(gigs.contains("TAKE THE STAGE"),"performance action retained")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career hub imports")
 if failures == 0:
  print("V125 TASK FIRST PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V125 FAILURE: "+reason)
