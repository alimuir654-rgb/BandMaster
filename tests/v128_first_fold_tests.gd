extends SceneTree
var failed := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var render := src.substr(src.find("func _render() -> void:"),src.find("\nfunc _header()",src.find("func _render() -> void:"))-src.find("func _render() -> void:"))
 _check(render.find('match tab:') < render.find('if not message.is_empty():'),"screen action precedes previous result")
 _check(not render.contains('_card("LATEST ACTIVITY"'),"blocking activity card removed")
 var scene := src.substr(src.find("func _scene() -> void:"),src.find("\nfunc _scene_scrapbook()")-src.find("func _scene() -> void:"))
 _check(scene.find('var box := _card("GET THE WORD OUT"') < scene.find("_recording_studio()"),"marketing controls before recording")
 _check(scene.contains('promo.pressed.connect'),"promotion action preserved")
 _check(scene.contains('press.pressed.connect'),"press action preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failed == 0: print("V128 FIRST FOLD PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failed += 1
  push_error("V128 FAILURE: "+reason)
