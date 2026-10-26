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
  _check(home.contains("places.columns = 3"),"three curated destinations")
  _check(home.contains("\"STUDIO\"") and home.contains("\"GIGS\"") and home.contains("\"BAND\""),"core places available")
  _check(home.contains("button.accessibility_name"),"destination names exposed to accessibility")
  _check(home.contains("button.pressed.connect(func() -> void: _switch(tab_target))"),"destination navigation wired")
  _check(home.contains("UI.themed_button"),"destinations use shared control states")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V92 DESTINATIONS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V92 DESTINATIONS FAILURE: "+reason)
