extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var h := source.find("func _home() -> void:")
 var g := source.find("func _gigs() -> void:",h)
 var a := source.find("func _actions() -> void:")
 var e := source.find("func _scene() -> void:",a)
 _check(h>=0 and g>h and a>=0 and e>a,"screen boundaries")
 if h>=0 and g>h:
  var home := source.substr(h,g-h)
  _check(home.find("var destinations :=") < home.find("var momentum :="),"destinations before secondary signals")
  _check(home.find("var guidance: Dictionary") < home.find("var destinations :="),"next decision before destinations")
 if a>=0 and e>a:
  var studio := source.substr(a,e-a)
  _check(studio.find("var switches :=") < studio.find("var snapshot: VBoxContainer"),"activity selector before status details")
  _check(studio.find("var snapshot: VBoxContainer") < studio.find("if action_view == \"JAM\":"),"status prior to interaction")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene loads")
 if failures==0:
  print("V72 UX HIERARCHY TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures+=1
  push_error("V72 UX FAILURE: "+why)
