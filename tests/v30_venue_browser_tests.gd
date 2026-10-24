extends SceneTree
const Browser = preload("res://Scripts/venue_browser.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
var failures := 0
func _initialize() -> void:
 var state := {"fans":0,"reputation":0}
 var before := JSON.stringify(state)
 var available: Array = Browser.entries(state)
 var locked: Array = Browser.entries(state,true)
 _check(available.size()==1 and locked.size()==Gigs.VENUES.size()-1,"venue groups partition")
 _check(str(available[0]["id"])=="local","hometown available first")
 _check(Browser.pick(available,"invalid")=="local","stale selection safe")
 _check(Browser.pick(available,"local")=="local","valid selection retained")
 _check(Browser.pick([],"old").is_empty(),"empty list safe")
 _check(int(locked[0]["missing_fans"])>=0 and int(locked[0]["missing_rep"])>=0,"unlock requirements")
 var high := {"fans":1000,"reputation":100}
 _check(Browser.entries(high).size()==Gigs.VENUES.size(),"full tour unlocked")
 _check(Browser.entries(high,true).is_empty(),"no locked venues when established")
 _check(JSON.stringify(state)==before,"view never mutates save")
 if failures==0:
  print("V30 VENUE BROWSER TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V30 VENUE BROWSER FAILURE: "+detail)
