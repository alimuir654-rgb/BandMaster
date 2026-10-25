extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _home() -> void:")
 var b := source.find("func _gigs() -> void:",a)
 _check(a>=0 and b>a,"Home screen exists")
 if a>=0 and b>a:
  var h := source.substr(a,b-a)
  _check(h.find('var pulse := _card("BAND PULSE"') < h.find('var momentum := _card("CAREER MOMENTUM"'),"status shown before secondary signals")
  _check(h.contains('if not landscape_dashboard:\n  var quick := _card("SHORTCUTS"'),"mobile shortcuts preserved, desktop duplicate avoided")
  _check(h.contains('content = full_content'),"root content restored")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene compiles")
 if failures==0:
  print("V93 HOME STATUS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V93 HOME FAILURE: "+reason)
