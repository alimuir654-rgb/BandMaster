extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _home() -> void:")
 var b := source.find("func _gigs() -> void:",a)
 _check(a>=0 and b>a,"Home screen")
 if a>=0 and b>a:
  var home := source.substr(a,b-a)
  _check(home.contains("var tile := WoldButton.new()"),"destinations use WoldUI")
  _check(home.contains('tile.icon_start = {"ACTIONS":"music"'),"meaningful action icons")
  _check(home.contains('tile.icon_end = "chevron-right"'),"navigation direction")
  _check(home.contains("tile.accessibility_name"),"accessible labels")
  _check(home.contains("tile.pressed.connect(func() -> void: _switch(target))"),"existing navigation wired")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene loads")
 if failures==0:
  print("V92 ICON DESTINATIONS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,message: String) -> void:
 if not ok:
  failures+=1
  push_error("V92 HOME FAILURE: "+message)
