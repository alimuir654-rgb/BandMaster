extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _band() -> void:")
 var b := source.find("func _listen(",a)
 _check(a>=0 and b>a,"band screen exists")
 if a>=0 and b>a:
  var band := source.substr(a,b-a)
  _check(band.contains("var box := Components.section(roster_grid,\"\",\"\",_genre_id())"),"no duplicated identity headings")
  _check(band.contains("SKILL %d  /  MORALE %d"),"overview stats visible without drilldown")
  _check(band.contains("selected_band_member != index"),"profile drilldown preserved")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene compiles")
 if failures==0:
  print("V66 ROSTER CARDS TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V66 ROSTER FAILURE: "+detail)
