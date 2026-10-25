extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _home() -> void:")
 var finish := source.find("func _gigs() -> void:",start)
 _check(start >= 0 and finish > start,"home screen exists")
 if start >= 0 and finish > start:
  var home := source.substr(start,finish-start)
  _check(home.contains("YOUR WORLD"),"destinations exist")
  _check(not home.contains("var art := TextureRect.new()"),"no placeholder SVG destination art")
  _check(home.contains("var target: String = str(data[\"tab\"])"),"navigation still wired")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career compiles")
 if failures == 0:
  print("V53 CLEAN NAV TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V53 NAV FAILURE: "+detail)
