extends SceneTree
const Handoff = preload("res://Scripts/opening_handoff.gd")
var failures := 0
func _initialize() -> void:
 var old := {"current_event":"aftershow","pending_next":"","tour_day":8,"rehearsal_number":3,"band":{"name":"The Feedback","members":[{"name":"Jo","role":"Drummer"}]},"decisions":{"rehearsal_1":"write","first_gig":"connect"},"career_extra":{"gig_history":[],"career_journal":[],"action_counters":{}}}
 var bridged: Dictionary = Handoff.migrate(old)
 var extra: Dictionary = bridged["career_extra"]
 _check(bool(extra.get("intro_handoff_complete",false)),"handoff marker")
 _check(extra["gig_history"].size() == 1,"debut added to regular gig history")
 _check(extra["gig_history"][0]["id"] == "intro:first_gig","debut has stable identity")
 _check(extra["career_journal"].size() == 1,"debut remembered")
 _check(int(extra["action_counters"].get("rehearse",0)) == 3,"intro rehearsals transferred")
 _check(int(extra["song_draft_progress"]) == 1,"writing choice credited towards future original")
 var two_writes := old.duplicate(true)
 two_writes["decisions"]["rehearsal_2"] = "write"
 var two_result: Dictionary = Handoff.migrate(two_writes)
 _check(int(two_result["career_extra"]["song_draft_progress"]) == 2,"two intro writing sessions persist as two draft stages")
 _check(bridged["band"] == old["band"],"roster unchanged")
 _check(JSON.stringify(Handoff.migrate(bridged)) == JSON.stringify(bridged),"migration idempotent")
 _check(old["career_extra"]["gig_history"].is_empty(),"original save immutable")
 var incomplete := old.duplicate(true)
 incomplete["current_event"] = "rehearsal"
 _check(JSON.stringify(Handoff.migrate(incomplete)) == JSON.stringify(incomplete),"incomplete tutorial remains playable")
 var pending := old.duplicate(true)
 pending["pending_next"] = "aftershow"
 _check(JSON.stringify(Handoff.migrate(pending)) == JSON.stringify(pending),"pending consequence preserved")
 var prior := old.duplicate(true)
 prior["career_extra"]["gig_history"] = [{"id":"intro:first_gig","day":8,"venue":"The Toadstool"}]
 prior["career_extra"]["career_journal"] = [{"id":"intro:first_show","day":8,"kind":"gig"}]
 prior["career_extra"]["action_counters"] = {"rehearse":7}
 var restored: Dictionary = Handoff.migrate(prior)
 _check(restored["career_extra"]["gig_history"].size() == 1,"existing debut not duplicated")
 _check(restored["career_extra"]["career_journal"].size() == 1,"existing story not duplicated")
 _check(int(restored["career_extra"]["action_counters"]["rehearse"]) == 7,"existing higher rehearsal count preserved")
 _check(JSON.parse_string(JSON.stringify(bridged)) is Dictionary,"save roundtrip")
 if failures == 0:
  print("V22 OPENING HANDOFF TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("OPENING HANDOFF FAILURE: "+detail)
