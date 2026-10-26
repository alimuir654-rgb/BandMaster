extends SceneTree
# Acceptance assertions updated for the owner-approved photo-led Band House.
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := src.find("func _home() -> void:")
 var b := src.find("func _editorial_banner(",a)
 _check(a>=0 and b>a,"home scene source available")
 if a>=0 and b>a:
  var home := src.substr(a,b-a)
  _check(src.contains("func _home_header() -> void:"),"compact home status exists")
  _check(src.contains("\"CASH\"") and src.contains("\"FANS\"") and src.contains("\"REP\""),"core economy metrics visible")
  _check(src.contains("if tab == \"HOME\":\n  _home_header()"),"home uses compact status")
  _check(not home.contains("var pulse := _card("),"old status button farm removed")
  _check(home.contains("Calendar.pending(_state())"),"gig context preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V93 STATUS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V93 STATUS FAILURE: "+reason)
