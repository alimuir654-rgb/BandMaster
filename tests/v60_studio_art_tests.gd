extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _actions() -> void:")
 var end := source.find("func _scene() -> void:",start)
 _check(start >= 0 and end > start,"studio exists")
 if start >= 0 and end > start:
  var studio := source.substr(start,end-start)
  _check(not studio.contains("uk_actions_banner.svg"),"retired SVG in studio")
  _check(studio.contains("Art/Backgrounds/%s/studio.webp"),"genre-specific studio artwork")
  _check(studio.contains("if ResourceLoader.exists(image_path):"),"no empty art panel")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene compiles")
 if failures == 0:
  print("V60 STUDIO ART TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V60 STUDIO FAILURE: "+reason)
