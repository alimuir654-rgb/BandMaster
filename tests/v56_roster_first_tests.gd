extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _band() -> void:")
 var end := source.find("func _listen(",start)
 _check(start >= 0 and end > start,"band view exists")
 if start >= 0 and end > start:
  var band_view := source.substr(start,end-start)
  var roster := band_view.find("for i in range(members.size()):")
  var summary := band_view.find("var chemistry := _card(\"BAND PULSE\"")
  _check(roster >= 0 and summary > roster,"musicians displayed before metrics")
  _check(band_view.contains("MEET "),"member interaction CTA")
  _check(band_view.contains("THE LINEUP"),"concise opening overview")
  _check(band_view.contains("BAND CHEMISTRY"),"relationship data preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures == 0:
  print("V56 ROSTER FIRST TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,description: String) -> void:
 if not ok:
  failures += 1
  push_error("V56 ROSTER FAILURE: "+description)
