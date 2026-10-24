extends SceneTree
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
var failures := 0
func _initialize() -> void:
 var base := {"cash":120,"tour_day":1,"reputation":20,"fans":20,"morale":70,"readiness":82,"tension":10,"songs":3,"van_health":80,"gig_history":[],"members":[{"name":"Jo","role":"Drummer"},{"name":"Alex","role":"Guitarist"}]}
 var standard := Promoter.book(base,"local","standard")
 _check(bool(standard.get("ok",false)),"promoter books standard deal")
 var guaranteed := Promoter.book(base,"local","guarantee")
 _check(bool(guaranteed.get("ok",false)),"promoter books guarantee")
 _check(not Promoter.book(base,"local","unknown").get("ok",true),"invalid offer rejected")
 _check(base.get("promoter_offer",{}).is_empty(),"negotiations do not mutate old state")
 if bool(standard.get("ok",false)) and bool(guaranteed.get("ok",false)):
  var normal: Dictionary = standard["state"]
  var premium: Dictionary = guaranteed["state"]
  _check(not Promoter.book(premium,"local","guestlist").get("ok",true),"cannot negotiate second booked show")
  normal["tour_day"] = 4
  premium["tour_day"] = 4
  var a: Dictionary = Calendar.perform(normal)
  var b: Dictionary = Calendar.perform(premium)
  _check(bool(a.get("ok",false)) and bool(b.get("ok",false)),"both contract shows can perform")
  if bool(a.get("ok",false)) and bool(b.get("ok",false)):
   var a_result: Dictionary = Promoter.settle(a["state"],normal)
   var b_result: Dictionary = Promoter.settle(b["state"],premium)
   _check(int(b_result.get("cash",0)) == int(a_result.get("cash",0))+15,"guarantee adds 15 fee")
   _check(b_result.get("promoter_offer",{}).is_empty(),"contract clears after settlement")
   _check(b_result["gig_history"].back().get("promoter_terms","") == "guarantee","contract recorded in history")
   _check(JSON.parse_string(JSON.stringify(b_result)) is Dictionary,"contract saves as JSON")
  var cancelled: Dictionary = Calendar.cancel(premium)
  _check(cancelled.get("state",{}).get("promoter_offer",{}).is_empty(),"cancellation clears contract")
  var missed: Dictionary = premium.duplicate(true)
  missed["tour_day"] = 5
  var expired: Dictionary = Calendar.expire(missed)
  _check(expired.get("promoter_offer",{}).is_empty(),"missed show clears contract")
 if failures == 0:
  print("V24 PROMOTER CONTRACT TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 PROMOTER FAILURE: "+detail)
