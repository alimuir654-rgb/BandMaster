extends SceneTree
const Life = preload("res://Scripts/member_life.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
var failures := 0
func _initialize() -> void:
 var state := {"tour_day":24,"cash":100,"members":[{"name":"Jo","role":"Guitarist","skill":55,"life_status":"active"},{"name":"Rob","role":"Drummer","skill":40,"life_status":"leave","available_day":37}],"readiness":76,"morale":65,"tension":8,"fans":30,"reputation":22,"van_health":80}
 var candidates := Life.candidates(state)
 _check(candidates.size() == 3,"three audition choices")
 _check(candidates[0]["skill"] < candidates[2]["skill"],"talent differences")
 _check(candidates[0]["loyalty"] > candidates[2]["loyalty"],"loyalty tradeoff")
 _check(not Gigs.play(state,"local").get("ok",true),"drummer absence blocks gig")
 _check(Gigs.play(state,"local","tight",true).get("ok",false),"session player rescues gig")
 var show: Dictionary = Gigs.play(state,"local","tight",true)
 if show.get("ok",false):
  _check(show["state"]["gig_history"][0]["session_drummer"] == true,"session credit saved")
  _check(show["state"]["gig_history"][0]["session_fee"] == 25,"session fee recorded")
  _check(JSON.parse_string(JSON.stringify(show["state"])) is Dictionary,"session save roundtrip")
 var poor := state.duplicate(true)
 poor["cash"] = 0
 _check(not Gigs.play(poor,"local","tight",true).get("ok",true),"session requires cash")
 var no_one := state.duplicate(true)
 no_one["members"] = []
 _check(not Gigs.play(no_one,"local","tight",true).get("ok",true),"session drummer cannot play solo")
 var signed := Life.recruit(state,2)
 _check(signed.get("ok",false),"candidate can join")
 if signed.get("ok",false):
  _check(int(signed["state"]["cash"]) == 70,"signing fee charged")
  _check(int(signed["state"]["members"][2]["skill"]) == int(candidates[2]["skill"]),"chosen skill preserved")
  _check(Gigs.play(signed["state"],"local").get("ok",false),"replacement drummer allows gig")
 _check(state["members"].size() == 2 and int(state["cash"]) == 100,"input immutable")
 _check(not Life.recruit(state,99).get("ok",true),"invalid audition rejected")
 var broke := state.duplicate(true)
 broke["cash"] = 0
 _check(not Life.recruit(broke,2).get("ok",true),"expensive audition rejected")
 if failures == 0:
  print("SESSION AND AUDITION TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, description: String) -> void:
 if not ok:
  failures += 1
  push_error("SESSION TEST FAILURE: "+description)
