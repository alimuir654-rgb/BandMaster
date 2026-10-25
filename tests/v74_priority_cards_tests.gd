extends SceneTree
var failed := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _home() -> void:")
 var b := source.find("func _gigs() -> void:",a)
 _check(a>=0 and b>a,"home function available")
 if a>=0 and b>a:
  var home := source.substr(a,b-a)
  _check(home.find("var guidance: Dictionary") < home.find("var stage := _card"),"primary next action precedes photo")
  _check(home.find("var stage := _card") < home.find("var destinations :="),"identity before navigation")
  _check(home.contains("feature.custom_minimum_size.y = 92 if CareerLayout.is_compact"),"mobile art less tall")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career loads")
 if failed==0:
  print("V74 PRIORITY CARDS PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failed+=1
  push_error("V74 PRIORITY FAILURE: "+reason)
