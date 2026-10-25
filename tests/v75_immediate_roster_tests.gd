extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _band() -> void:")
 var b := source.find("func _listen(",a)
 _check(a>=0 and b>a,"band screen")
 if a>=0 and b>a:
  var view := source.substr(a,b-a)
  var roster := view.find("for i in RosterView.sorted_indices(members,roster_sort):")
  _check(roster>=0,"member cards")
  _check(view.find("var overview := _card")>roster,"overview after roster")
  _check(view.find("var alumni: Array")>roster,"alumni after roster")
  _check(view.find("var chemistry := _card")>roster,"group stats after roster")
  _check(view.contains("talk.pressed.connect"),"direct conversation retained")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene compiles")
 if failures==0:
  print("V75 IMMEDIATE ROSTER PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V75 ROSTER FAILURE: "+detail)
