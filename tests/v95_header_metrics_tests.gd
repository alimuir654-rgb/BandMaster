extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _header() -> void:")
 var b := source.find("func _hero() -> void:",a)
 _check(a>=0 and b>a,"header function exists")
 if a>=0 and b>a:
  var header := source.substr(a,b-a)
  _check(header.contains('{"title":"CASH"'),"cash metric")
  _check(header.contains('{"title":"FANS"'),"audience metric")
  _check(header.contains('{"title":"REPUTATION"'),"reputation metric")
  _check(header.contains('var metric_icon := _label(metric_row'),"desktop icons")
  _check(header.contains('if get_viewport_rect().size.x >= 960.0'),"responsive display")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene imports")
 if failures==0:
  print("V95 HEADER METRICS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V95 HEADER FAILURE: "+reason)
