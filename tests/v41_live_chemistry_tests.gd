extends SceneTree
const Calendar = preload("res://Scripts/gig_calendar.gd")
var failures := 0
func _initialize() -> void:
 var state := {"cash":200,"tour_day":4,"fans":30,"reputation":25,"readiness":45,"morale":80,"tension":0,"van_health":80,"songs":3,"relationships":{"0_1":95},"members":[{"name":"Jo","role":"Drummer","life_status":"active"},{"name":"Alex","role":"Guitarist","life_status":"active"}],"booked_show":{"venue_id":"local","venue":"The Lantern Room","city":"HOMETOWN","day":4,"approach":"tight","session_drummer":false}}
 var original := JSON.stringify(state)
 var strong: Dictionary = Calendar.perform(state)
 _check(bool(strong.get("ok",false)),"high-chemistry show can play")
 if bool(strong.get("ok",false)):
  _check(int(strong["state"]["gig_history"][0]["live_chemistry_bonus"])==3,"gig logs live chemistry")
  _check(int(strong["state"]["readiness"])==45,"gig restores pre-show readiness")
 var low := state.duplicate(true)
 low["relationships"]["0_1"]=15
 var weak: Dictionary = Calendar.perform(low)
 _check(bool(weak.get("ok",false)),"low-chemistry show remains playable")
 if bool(weak.get("ok",false)):
  _check(int(weak["state"]["gig_history"][0]["live_chemistry_bonus"])==0,"poor chemistry yields no bonus")
 _check(JSON.stringify(state)==original,"perform never mutates old save")
 if failures==0:
  print("V41 LIVE CHEMISTRY TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V41 LIVE CHEMISTRY FAILURE: "+detail)
