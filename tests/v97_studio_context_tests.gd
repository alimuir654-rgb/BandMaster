extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _actions() -> void:")
 var b := source.find("func _recording_studio() -> void:",a)
 _check(a>=0 and b>a,"Studio section")
 if a>=0 and b>a:
  var studio := source.substr(a,b-a)
  _check(studio.contains("if not wide_workspace or not upcoming.is_empty():"),"desktop hides duplicated snapshot without a gig")
  _check(studio.contains('else "UPCOMING LIVE COMMITMENT"'),"gig-only desktop briefing")
  _check(studio.contains('if countdown > 0:'),"upcoming gig warning")
  _check(studio.contains('elif countdown == 0:'),"show day CTA")
  _check(studio.contains('var dashboard := _card("SESSION CONTROL"'),"primary context dashboard remains")
 _check(load("res://Scenes/CareerHub.tscn") != null,"CareerHub imports")
 if failures==0:
  print("V97 STUDIO CONTEXT PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V97 CONTEXT FAILURE: "+detail)
