extends SceneTree
var failed := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _bottom_nav() -> void:")
 var b := source.find("func _switch(",a)
 _check(a>=0 and b>a,"navigation section")
 if a>=0 and b>a:
  var nav := source.substr(a,b-a)
  _check(nav.contains("button.icon_only = true"),"no cramped button labels in landscape")
  _check(nav.contains("button.button_size = WoldButton.Size.LG"),"large rail target")
  _check(nav.contains("if not landscape:\n   var caption"),"mobile tab captions retained")
  _check(nav.contains("button.accessibility_name"),"labels remain accessible")
  _check(nav.contains("button.tooltip_text"),"full nav labels on hover")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"CareerHub loads")
 if failed==0:
  print("WOLDUI ICON RAIL POLISH PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failed+=1
  push_error("ICON RAIL FAILURE: "+detail)
