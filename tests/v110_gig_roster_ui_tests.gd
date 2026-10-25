extends SceneTree
var failures := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 for token in ["var phase_order := [\"arrive\",\"soundcheck\",\"stage\"]","var active_phase := phase_index == current_phase","var finished_phase := phase_index < current_phase","[\"ARRIVAL\",\"SOUNDCHECK\",\"ON STAGE\"]","if landscape_roster:","var status_label := _label(member_header,","BAND PERSONNEL  /  %02d"]:
  _check(s.contains(token),token)
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures == 0:
  print("V110 GIG & ROSTER UI PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V110 UI FAILURE: "+reason)
