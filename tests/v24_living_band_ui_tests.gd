extends SceneTree
const Pulse = preload("res://Scripts/band_pulse_presentation.gd")
var failures := 0
func _initialize() -> void:
 var empty: Dictionary = Pulse.overview([])
 _check(int(empty["active"]) == 0 and str(empty["mood"]) == "NO ACTIVE MEMBERS","empty band")
 var roster := [{"name":"A","morale":80,"loyalty":80,"fatigue":10},{"name":"B","morale":60,"loyalty":60,"fatigue":71},{"name":"C","life_status":"away","morale":0,"loyalty":0}]
 var snapshot := JSON.stringify(roster)
 var report: Dictionary = Pulse.overview(roster)
 _check(int(report["active"]) == 2,"away members excluded")
 _check(int(report["morale"]) == 70 and int(report["loyalty"]) == 70,"active averages")
 _check(int(report["exhausted"]) == 1 and str(report["mood"]) == "RUNNING ON EMPTY","fatigue warning")
 _check(JSON.stringify(roster) == snapshot,"pure presentation")
 _check(Pulse.member_note({"fatigue":75}) == "NEEDS A BREAK","fatigue note")
 _check(Pulse.member_note({"life_status":"away"}) == "AWAY FROM THE BAND","unavailable note")
 _check(Pulse.overview([{"morale":20,"loyalty":20}])["mood"] == "ON EDGE","low morale")
 if failures == 0:
  print("V24 LIVING BAND UI TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 LIVING BAND FAILURE: "+detail)
