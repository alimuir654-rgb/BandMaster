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
  _check(home.contains("places.columns = 3"),"three primary locations rather than dense five-card grid")
  _check(home.contains("GO SOMEWHERE"),"navigation section labelled")
  _check(home.contains("button.accessibility_name"),"meaningful accessibility label")
  _check(home.contains("button.pressed.connect(func() -> void: _switch(tab_target))"),"navigation remains wired")
  _check(home.contains("GEAR & REPAIRS") and home.contains("SCENE & SCRAPBOOK"),"secondary worlds still reachable")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V107 DESTINATION HUB PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V107 DESTINATION HUB FAILURE: "+reason)
