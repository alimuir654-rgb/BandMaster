extends SceneTree
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Story = preload("res://Scripts/career_story.gd")
var failures := 0
func _initialize() -> void:
 var initial := {"cash":180,"tour_day":1,"readiness":32,"morale":60,"tension":12,"reputation":5,"fans":0,"van_health":80,"gig_history":[],"career_journal":[],"members":[{"name":"Jo","role":"Drummer","life_status":"active","trait":"Reliable"},{"name":"Ash","role":"Guitarist","life_status":"active","trait":"Creative"}]}
 var booking: Dictionary = Calendar.book(initial,"local","tight")
 _check(booking.get("ok",false),"hometown gig can book")
 var state: Dictionary = booking.get("state",{})
 _check(int(Calendar.pending(state).get("day",0)) == 4,"bookings require three preparation days")
 _check(not Calendar.book(state,"local").get("ok",true),"double bookings blocked")
 _check(not Calendar.perform(state).get("ok",true),"gig cannot be performed early")
 _check(initial.get("booked_show",{}).is_empty(),"booking resolver does not mutate old state")
 var prep: Dictionary = Actions.resolve(state,"songwrite")
 _check(prep.get("ok",false),"preparation action works")
 if prep.get("ok",false):
  state = Calendar.expire(prep["state"])
 var practise: Dictionary = Actions.resolve(state,"rehearse")
 _check(practise.get("ok",false),"rehearsal before gig works")
 if practise.get("ok",false):
  state = Calendar.expire(practise["state"])
 var rest: Dictionary = Actions.resolve(state,"rest")
 _check(rest.get("ok",false),"last preparation day advances")
 if rest.get("ok",false):
  state = Calendar.expire(rest["state"])
 _check(int(state.get("tour_day",0)) == 4,"performance day reached")
 var performance: Dictionary = Calendar.perform(state)
 _check(performance.get("ok",false),"scheduled gig performs on correct day")
 if performance.get("ok",false):
  var result: Dictionary = performance["state"]
  _check(Calendar.pending(result).is_empty(),"playing clears booking")
  _check(result.get("gig_history",[]).size() == 1,"real gig history written")
  _check(JSON.parse_string(JSON.stringify(result)) is Dictionary,"saved career remains JSON compatible")
 var missed: Dictionary = Actions.resolve(state,"rest")
 _check(missed.get("ok",false),"can accidentally skip gig")
 if missed.get("ok",false):
  var after: Dictionary = Calendar.expire(missed["state"])
  _check(Calendar.pending(after).is_empty(),"overdue gig is removed")
  _check(int(after.get("reputation",0)) == 0,"missed gig reputation penalty applies")
  _check(after["career_journal"].back()["title"] == "MISSED SHOW","missed gig becomes story")
  _check(Calendar.expire(after)["career_journal"].size() == after["career_journal"].size(),"missed gig penalty not repeated")
 var cancelled: Dictionary = Calendar.cancel(booking.get("state",{}))
 _check(cancelled.get("ok",false),"gig can be cancelled")
 if cancelled.get("ok",false):
  _check(Calendar.pending(cancelled["state"]).is_empty(),"cancel clears booking")
  _check(int(cancelled["state"].get("cash",0)) == 165,"cancel penalty charged")
 _check(not Calendar.cancel(initial).get("ok",true),"cannot cancel absent booking")
 _check(not Calendar.book(initial,"unknown").get("ok",true),"invalid venue rejected")
 _check(not Calendar.book(initial,"bristol").get("ok",true),"locked venue rejected")
 if failures == 0:
  print("GIG CALENDAR V22 TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(condition: bool, detail: String) -> void:
 if not condition:
  failures += 1
  push_error("GIG CALENDAR FAILURE: "+detail)
