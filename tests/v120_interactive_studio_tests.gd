extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains('channels.columns = 3 if get_viewport_rect().size.x >= 760.0 else 1'),"studio responds to small displays")
 _check(source.contains('channel_panel.tooltip_text = str(channel["hint"])'),"each channel explains its purpose")
 _check(source.contains('meter.max_value = 100'),"actual simulation scale")
 _check(source.contains('"%d / 100" % int(channel["amount"])'),"meter has truthful units")
 _check(not source.contains('"%d dB / 100"'),"no invented decibel reading")
 _check(source.contains('action_view = select_mode'),"console controls affect studio mode")
 _check(source.contains('if _num("tension") >= 65:'),"tension advice based on real state")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failures==0:
  print("V120 INTERACTIVE STUDIO PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V120 STUDIO FAILURE: "+reason)
