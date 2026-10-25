extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains('if get_viewport_rect().size.x >= 960.0:\n  var command := UI.themed_button("SAVE & MENU"'),"landscape header action")
 _check(source.contains('command.icon_start = "menu"'),"WoldUI menu icon")
 _check(source.contains("command.pressed.connect(_menu)"),"menu action functional")
 _check(source.contains('if get_viewport_rect().size.x < 960.0:\n  var menu := UI.button("SAVE & MAIN MENU")'),"mobile action retained")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene loads")
 if failures==0:
  print("WOLDUI HEADER COMMANDS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("HEADER COMMANDS FAILURE: "+detail)
