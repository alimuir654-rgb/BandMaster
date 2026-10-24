extends SceneTree
const Brief = preload("res://Scripts/live_night_briefing.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
var failures := 0
func _initialize() -> void:
 var state := {"cash":120,"tour_day":1,"reputation":20,"fans":20,"morale":75,"tension":10,"readiness":80,"songs":3,"van_health":80,"gig_history":[],"members":[{"role":"Drummer"},{"role":"Guitarist"}]}
 _check(not bool(Brief.briefing(state)["active"]),"no booking")
 var result: Dictionary = Promoter.book(state,"local","guarantee")
 _check(bool(result.get("ok",false)),"booking available")
 if bool(result.get("ok",false)):
  var booked: Dictionary = result["state"]
  var original := JSON.stringify(booked)
  var early: Dictionary = Brief.briefing(booked)
  _check(early["days_left"]==3 and early["deal"]=="ASK FOR A GUARANTEE","countdown and contract")
  _check(JSON.stringify(booked)==original,"read-only view")
  booked["tour_day"]=4
  _check(Brief.briefing(booked)["phase"]=="arrival","arrival on show date")
  _check(Brief.stage_index("soundcheck")==1 and Brief.stage_index("stage")==2,"progressive phases")
  booked["gig_night_phase"]="soundcheck"
  _check(Brief.briefing(booked)["phase"]=="soundcheck","saved phase")
  var performed: Dictionary = Calendar.perform(booked)
  _check(bool(performed.get("ok",false)),"real gig resolver")
  if bool(performed.get("ok",false)):
   var settled: Dictionary = Promoter.settle(performed["state"],booked)
   var last: Dictionary = Brief.last_show(settled)
   _check(int(last["fee"])>=0 and last["terms"]=="guarantee","settlement recap")
   _check(JSON.parse_string(JSON.stringify(settled)) is Dictionary,"save roundtrip")
 var risky := state.duplicate(true)
 risky["songs"]=0
 risky["readiness"]=20
 risky["morale"]=20
 risky["tension"]=90
 risky["booked_show"]={"venue":"The Toadstool","city":"Bristol","day":2}
 _check(Brief.briefing(risky)["tips"].size()==4,"pre-show guidance")
 if failures==0:
  print("V26 LIVE NIGHT BRIEFING PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V26 LIVE NIGHT FAILURE: "+detail)
