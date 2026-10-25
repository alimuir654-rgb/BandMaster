extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _band() -> void:")
 var b := source.find("func _listen(",a)
 _check(a>=0 and b>a,"band exists")
 if a>=0 and b>a:
  var band := source.substr(a,b-a)
  _check(band.contains('briefing_panel = _card("BAND MANAGEMENT  /  LIVE BRIEFING"'),"team management panel")
  _check(band.contains('{"label":"NEED REST","value":int(pulse.get("exhausted",0))'),"rest risk")
  _check(band.contains('{"label":"GROUP LOYALTY","value":int(pulse.get("loyalty",0))'),"loyalty")
  _check(band.contains('rehearse.pressed.connect(func() -> void: _switch("ACTIONS"))'),"studio action")
  _check(band.contains('gigs.pressed.connect(func() -> void: _switch("GIGS"))'),"gig action")
  _check(band.contains('if get_viewport_rect().size.x >= 960.0 and not members.is_empty():'),"mobile clear")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene valid")
 if failures == 0:
  print("V102 BAND BRIEF PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V102 BRIEF FAILURE: "+reason)
