extends SceneTree
const Momentum = preload("res://Scripts/career_momentum_presentation.gd")
var failures := 0
func _initialize() -> void:
 var empty := {"cash":120,"tour_day":1,"members":[]}
 var before := JSON.stringify(empty)
 _check(Momentum.signals(empty).size() == 1,"idle guidance")
 var busy := {"cash":8,"tour_day":4,"song_draft_progress":2,"current_song_draft":{"title":"TEST"},"booked_show":{"day":6},"members":[{"life_status":"resting"}]}
 var signals: Array = Momentum.signals(busy)
 _check(signals.size() == 4,"four simultaneous priorities")
 _check(str(signals[0]["tab"]) == "ACTIONS","song link")
 _check(str(signals[1]["tab"]) == "GIGS","gig link")
 _check(str(signals[2]["tab"]) == "BAND","lineup link")
 _check(str(signals[3]["tab"]) == "SCENE","cash link")
 _check(JSON.stringify(empty) == before,"presentation never mutates save")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("Director.next_move(_state())") and source.contains("BandHousePrimaryAction"),"home displays one state-driven progression action")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures == 0:
  print("V36 CAREER MOMENTUM TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V36 MOMENTUM FAILURE: "+detail)
