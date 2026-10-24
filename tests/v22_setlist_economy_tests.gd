extends SceneTree
const Calendar = preload("res://Scripts/gig_calendar.gd")
var failures := 0
func _initialize() -> void:
 var base := {"cash":120,"tour_day":4,"readiness":65,"morale":60,"tension":10,"fans":15,"reputation":20,"van_health":90,"gig_history":[],"members":[{"name":"Jo","role":"Drummer"},{"name":"Ash","role":"Guitarist"}],"booked_show":{"venue_id":"local","venue":"The Lantern Room","city":"HOMETOWN","day":4,"approach":"tight","session_drummer":false}}
 var weak := base.duplicate(true)
 weak["songs"] = 0
 var strong := base.duplicate(true)
 strong["songs"] = 3
 var zero: Dictionary = Calendar.perform(weak)
 var three: Dictionary = Calendar.perform(strong)
 _check(zero.get("ok",false) and three.get("ok",false),"both shows resolve")
 if zero.get("ok",false) and three.get("ok",false):
  var a: Dictionary = zero["state"]
  var b: Dictionary = three["state"]
  _check(int(a["gig_history"][0]["fee"]) < int(b["gig_history"][0]["fee"]),"original setlist earns more")
  _check(int(a.get("fans",0)) <= int(b.get("fans",0)),"original setlist improves crowd")
  _check(int(a["readiness"]) == 65 and int(b["readiness"]) == 65,"setlist modifier does not leak into permanent readiness")
  _check(int(a["gig_history"][0]["originals_played"]) == 0,"history records setlist")
  var repeat: Dictionary = strong.duplicate(true)
  repeat["gig_history"] = [{"venue_id":"local","venue":"The Lantern Room","day":1,"fee":30,"success":true}]
  var again: Dictionary = Calendar.perform(repeat)
  _check(again.get("ok",false),"repeat show resolves")
  if again.get("ok",false):
   _check(bool(again["state"]["gig_history"].back()["return_visit"]),"repeat is recognized")
   _check(int(again["state"]["gig_history"].back()["fee"]) < int(b["gig_history"].back()["fee"]),"repeat has reduced fee")
 _check(weak["gig_history"].is_empty() and strong["gig_history"].is_empty(),"original career snapshots remain unchanged")
 if failures == 0:
  print("V22 SETLIST ECONOMY TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("SETLIST FAILURE: "+detail)
