extends SceneTree
var failures := 0
func _initialize() -> void:
 var path: String = ProjectSettings.get_setting("woldui/tokens","")
 _check(path=="res://Art/UI/bandmaster_tokens.tres","project selects owned tokens")
 var tokens := load(path) as WoldTokens
 _check(tokens != null,"token resource loads")
 if tokens != null:
  _check(not tokens.hover_sound,"hover remains silent")
  _check(tokens.feedback_sounds,"press sounds remain enabled")
  _check(tokens.auto_feedback,"visual feedback remains active")
  _check(tokens.press_effect != null,"press effects remain available")
 if failures==0:
  print("V122 QUIET HOVER PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V122 AUDIO FAILURE: "+reason)
