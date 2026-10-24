extends SceneTree
const Flow = preload("res://Scripts/gig_night_flow.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
var failures := 0
func _initialize() -> void:
 var base := {"cash":160,"tour_day":4,"readiness":70,"morale":60,"tension":10,"reputation":20,"fans":20,"songs":3,"van_health":80,"gig_history":[],"members":[{"name":"Jo","role":"Drummer"},{"name":"Sam","role":"Guitarist"}],"booked_show":{"venue_id":"local","venue":"The Lantern Room","city":"HOMETOWN","day":4,"approach":"tight","session_drummer":false}}
 _check(Flow.stage(base)["phase"] == "arrival","show begins outside venue")
 _check(not bool(Flow.stage(base)["can_play"]),"cannot play immediately")
 var arrived := Flow.advance(base)
 _check(bool(arrived.get("ok",false)),"arrival advances")
 var at_check: Dictionary = arrived.get("state",{})
 _check(Flow.stage(at_check)["phase"] == "soundcheck","next stage soundcheck")
 var switched: Dictionary = Flow.choose_set(at_check,"crowd")
 _check(bool(switched.get("ok",false)),"soundcheck allows strategy change")
 if bool(switched.get("ok",false)):
  at_check = switched["state"]
  _check(at_check["booked_show"]["approach"] == "crowd","chosen strategy persists")
 _check(not Flow.choose_set(base,"wild").get("ok",true),"strategy cannot be changed before soundcheck")
 _check(not Flow.choose_set(at_check,"nonsense").get("ok",true),"invalid strategy rejected")
 var ready := Flow.advance(at_check)
 _check(bool(ready.get("ok",false)),"soundcheck advances")
 var onstage: Dictionary = ready.get("state",{})
 _check(bool(Flow.stage(onstage)["can_play"]),"stage is unlocked")
 _check(not Flow.advance(onstage).get("ok",true),"stage cannot advance repeatedly")
 var result := Calendar.perform(onstage)
 _check(bool(result.get("ok",false)),"existing gig engine still resolves")
 if bool(result.get("ok",false)):
  var finished: Dictionary = Flow.reset_after_show(result["state"])
  _check(finished.get("gig_history",[]).size() == 1,"one show recorded")
  _check(finished.get("booked_show",{}).is_empty(),"booking cleared")
  _check(str(finished["gig_night_phase"]) == "arrival","next gig starts fresh")
  _check(JSON.parse_string(JSON.stringify(finished)) is Dictionary,"stage save roundtrip")
 _check(base.get("gig_night_phase","") == "","source state unchanged")
 var early := base.duplicate(true)
 early["tour_day"] = 3
 _check(Flow.stage(early)["phase"] == "preparation","early dates remain in preparation")
 _check(not Flow.advance(early).get("ok",true),"cannot skip booking date")
 var late := base.duplicate(true)
 late["tour_day"] = 5
 _check(Flow.stage(late)["phase"] == "overdue","overdue date recognised")
 if failures == 0:
  print("V24 GIG NIGHT FLOW TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,label: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 NIGHT FAILURE: "+label)
