extends SceneTree
var failures := 0
func _initialize() -> void:
 var text_source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := text_source.find("func _band() -> void:")
 var b := text_source.find("func _listen(",a)
 _check(a >= 0 and b > a,"band scene exists")
 if a >= 0 and b > a:
  var band := text_source.substr(a,b-a)
  _check(not band.contains("HEAR WHAT THEY HAVE TO SAY"),"duplicate dialogue removed")
  _check(band.contains("talk.pressed.connect(func() -> void: _listen(index))"),"primary talk action remains")
  _check(band.contains("UI.themed_progress(meter,_genre_id()"),"genre metric styling")
  _check(band.contains("preserve_roster_scroll = true"),"detail continuity")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene valid")
 if failures == 0:
  print("V69 MEMBER PROFILE TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V69 MEMBER FAILURE: "+reason)
