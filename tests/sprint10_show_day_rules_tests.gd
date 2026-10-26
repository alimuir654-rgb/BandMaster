extends SceneTree
const Journey = preload("res://Scripts/show_day_journey.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
var failures := 0

func _initialize() -> void:
 var base := {
  "tour_day":7,"cash":140,"morale":70,"readiness":70,
  "booked_show":{"venue_id":"local","venue":"The Lantern Room","day":7,"approach":"tight"},
  "gig_night_phase":"arrival",
  "members":[{"name":"Sam","role":"Bassist","life_status":"active","fatigue":70,"morale":55}]
 }
 _check(Journey.current_step({}) == -1,"no booking has no journey")
 _check(not bool(Journey.advance({}).get("ok",false)),"cannot advance without booking")
 var early: Dictionary = base.duplicate(true)
 early["tour_day"] = 6
 _check(not bool(Journey.advance(early).get("ok",false)),"cannot start show-day journey early")
 var stale: Dictionary = base.duplicate(true)
 stale["show_journey_progress"] = {"booking_key":"another-venue:7","step":4}
 _check(Journey.current_step(stale) == 0,"old booking progress cannot unlock next show")
 var next: Dictionary = base.duplicate(true)
 for step in range(4):
  var outcome: Dictionary = Journey.advance(next)
  _check(bool(outcome.get("ok",false)),"step %d can advance" % step)
  if not bool(outcome.get("ok",false)):
   break
  next = outcome["state"]
  _check(Journey.current_step(next) == step+1,"stage advances exactly one step")
  _check(int(next.get("cash",0)) == 140 and int(next.get("tour_day",0)) == 7,"no free-scene economy mutation")
 _check(Journey.ready_to_perform(next),"stage 4 allows existing show engine")
 _check(not bool(Journey.advance(next).get("ok",false)),"cannot advance beyond stage 4")
 var legacy: Dictionary = base.duplicate(true)
 legacy["gig_night_phase"] = "soundcheck"
 _check(Journey.current_step(legacy) == 3,"old save resumes at soundcheck")
 legacy["gig_night_phase"] = "stage"
 _check(Journey.current_step(legacy) == 4,"old save resumes at showtime")
 var illness: Dictionary = base.duplicate(true)
 illness["gig_night_phase"] = "soundcheck"
 illness["illness_resolved_booking"] = "local:7.0"
 _check(Backstage.incident(illness).is_empty(),"legacy JSON float booking ID prevents repeated illness")
 illness["illness_resolved_booking"] = "local:7"
 _check(Backstage.incident(illness).is_empty(),"canonical booking ID prevents repeated illness")
 if failures == 0:
  print("SPRINT B SHOW DAY RULES PASSED")
 quit(0 if failures == 0 else 1)

func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT B RULES FAILURE: "+why)
