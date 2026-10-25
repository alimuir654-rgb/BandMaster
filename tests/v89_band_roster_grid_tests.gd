extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _band() -> void:")
 var b := source.find("func _listen(",a)
 _check(a >= 0 and b > a,"Band view")
 if a >= 0 and b > a:
  var view := source.substr(a,b-a)
  _check(view.contains("roster_grid.columns = 2 if landscape_roster else 1"),"two-column landscape, single-column mobile")
  _check(view.contains('Components.section(roster_grid,"","",_genre_id())'),"cards attach to grid")
  _check(view.contains("selected_band_member != index"),"member details retained")
  _check(view.contains("talk.pressed.connect"),"bandmate conversations retained")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene compiles")
 if failures == 0:
  print("V89 BAND ROSTER GRID PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V89 GRID FAILURE: "+reason)
