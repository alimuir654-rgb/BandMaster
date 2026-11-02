extends RefCounted
## Saved, zero-turn checkpoints for one managed local night. Pure; no LiveBridge,
## Finance transaction, IO, clocks, tween or scene dependency.
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Policy = preload("res://experiments/playable_flightcase/gig_performance_policy.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Radio = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")
const KEY := "gig_journey_v1"
const VERSION := 1
const PHASES := ["set_out","travel","arrival","load_in","soundcheck","backstage","stage_entrance","performing","choice","reaction","after_set","pack_up","wrap_ready"]
const LOCKED_PHASES := ["backstage","stage_entrance","performing","choice","reaction","after_set","pack_up","wrap_ready"]

static func _bad(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func fingerprint(state: Dictionary) -> String:
 var source: Dictionary=state.duplicate(true)
 source.erase(KEY)
 return Policy.fingerprint(source)

static func active(state: Dictionary) -> Dictionary:
 var raw: Variant=state.get(KEY)
 if not raw is Dictionary or not raw.get("active") is Dictionary:return {}
 return raw["active"].duplicate(true)

static func locked(state: Dictionary) -> bool:
 if not state.has(KEY):return false
 var raw: Variant=state[KEY]
 return not raw is Dictionary or raw.get("version") not in [1,2] or not Policy.whole(raw.get("sequence"),0) or not raw.get("active") is Dictionary or not raw["active"].is_empty()

static func expected(state: Dictionary) -> Dictionary:
 var visit: Dictionary=active(state)
 return {"journey_id":str(visit.get("id","")),"phase":str(visit.get("phase","")),"revision":int(visit.get("revision",-1))}

static func _wrapper(state: Dictionary) -> Dictionary:
 return state[KEY].duplicate(true) if state.has(KEY) and state[KEY] is Dictionary else {"version":VERSION,"sequence":0,"active":{}}

static func _result(state: Dictionary, message: String = "", changed: bool = false) -> Dictionary:
 return {"ok":true,"state":state.duplicate(true),"message":message,"changed":changed,"noop":not changed,"active":active(state)}

static func eligible(state: Dictionary) -> bool:
 return Flow.managed(state) and (Flow.version_of(state)==2 or str(Calendar.pending(state).get("venue_id",""))=="local") and int(Calendar.pending(state).get("day",-1))==int(state.get("tour_day",0))

static func _source_guard(state: Dictionary) -> Dictionary:
 var valid: Dictionary=Finance.guard(state)
 if not bool(valid.get("ok",false)):return valid
 if Radio.locked(state):return _bad("Finish the radio visit before tonight's booking.")
 valid=Flow.validate(state)
 if not bool(valid.get("ok",false)):return valid
 valid=Core.validate(state)
 if not bool(valid.get("ok",false)):return valid
 if not eligible(state):return _bad("This journey belongs to the managed local booking on its due day.")
 return {"ok":true}

static func validate(state: Dictionary) -> Dictionary:
 if not state.has(KEY):return {"ok":true,"exists":false,"active":{}}
 var raw: Variant=state[KEY]
 if not raw is Dictionary or raw.get("version") not in [1,2] or not Policy.whole(raw.get("sequence"),0) or not raw.get("active") is Dictionary:return _bad("This saved gig journey needs a compatible version. Its data has been retained.")
 var visit: Dictionary=raw["active"]
 if visit.is_empty():return {"ok":true,"exists":true,"active":{}}
 var guarded: Dictionary=_source_guard(state)
 if not bool(guarded.get("ok",false)):return guarded
 if not Policy.whole(raw["sequence"],1) or not Policy.whole(visit.get("revision"),0) or visit.get("version")!=raw["version"] or visit.get("policy_version")!=1 or visit.get("content_version")!=1:return _bad("The saved gig checkpoint is incomplete.")
 for key in ["id","booking_id","phase","source_hash","intent"]:
  if not visit.get(key) is String:return _bad("The saved gig checkpoint has unreadable text.")
 var booking: Dictionary=Calendar.pending(state)
 if int(raw["version"])!=Flow.version_of(state):return _bad("The saved gig and booking versions disagree.")
 if int(raw["version"])==2:
  var agreement: Dictionary=Booking.validate(state)
  if not bool(agreement.get("ok",false)):return agreement
  var t: Dictionary=Booking.terms(state)
  if visit.get("commitment_id")!=t.get("commitment_id") or not visit.get("departure_committed") is bool or not Booking.whole(visit.get("departure_liability")):return _bad("The saved trip is missing its agreed commitment.")
  var departed: bool=str(visit["phase"])!="set_out"
  var liability: int=int(t["tariff"]["travel"])+int(t["tariff"]["accommodation"])
  if booking["venue_id"]=="local":liability=mini(liability,int(state.get("cash",0)))
  if visit["departure_committed"]!=departed or int(visit["departure_liability"])!=(liability if departed else 0):return _bad("The saved departure liability does not match the actual trip.")
 var booking_id: String=Flow.booking_id(booking)
 if visit["booking_id"]!=booking_id or visit["id"]!="gig-journey:%d:%s" % [int(raw["sequence"]),booking_id] or not PHASES.has(visit["phase"]):return _bad("This checkpoint no longer matches tonight's booking.")
 if visit["source_hash"]!=fingerprint(state):return _bad("The band or booking changed after this checkpoint. The saved night has been held.")
 if not visit.get("participants") is Array or visit["participants"]!=state.get("members",[]) or not Policy.whole(visit.get("started_day"),1) or int(visit["started_day"])!=int(booking.get("day",0)) or not Policy.whole(visit.get("started_cash"),0) or int(visit["started_cash"])!=int(state.get("cash",0)):return _bad("The night's pinned band, day or cash changed.")
 var stage: String=Flow.phase(state)
 var phase: String=visit["phase"]
 var original: String="travel" if phase=="set_out" else ("arrival" if phase in ["travel","arrival","load_in"] else ("soundcheck" if phase=="soundcheck" else "stage"))
 if stage!=original:return _bad("The original booking stage and saved journey disagree.")
 if not Policy.whole(visit.get("cursor"),0,3) or not Policy.whole(visit.get("vibe"),0,100) or not visit.get("completed_ids") is Array or not visit.get("feedback") is Array or not visit.get("plan") is Dictionary or not visit.get("context") is Dictionary:return _bad("The saved set cursor is incomplete.")
 var cursor: int=int(visit["cursor"])
 if not LOCKED_PHASES.has(phase):
  if cursor!=0 or not visit["completed_ids"].is_empty() or not visit["plan"].is_empty() or not visit["context"].is_empty() or not visit["feedback"].is_empty() or int(visit["vibe"])!=40 or visit["intent"]!="":return _bad("An unfinished soundcheck contains premature performance facts.")
 else:
  var plan: Dictionary=booking[Flow.FLOW_KEY]["plan"]
  if visit["plan"]!=plan:return _bad("The exact saved set changed after soundcheck.")
  var captured: Dictionary=Policy.capture(state,plan)
  if not bool(captured.get("ok",false)):return captured
  if visit["context"]!=captured["context"] or not Policy.context_valid(visit["context"]):return _bad("The frozen live context does not match the saved band.")
  var ids: Array=plan.get("song_ids",[])
  var count: int=ids.size()
  if cursor>count or visit["completed_ids"]!=ids.slice(0,cursor):return _bad("Only the actual saved completed-song prefix can be crossed out.")
  var intent: String=visit["intent"]
  if not intent.is_empty() and (count<2 or cursor<1 or not Policy.INTENTS.has(intent)):return _bad("This saved live intent does not belong to the set.")
  if phase in ["backstage","stage_entrance"] and (cursor!=0 or not intent.is_empty()):return _bad("Songs cannot be completed before taking the stage.")
  if phase=="choice" and (cursor!=1 or count<2 or not intent.is_empty()):return _bad("The room-reading choice is not at its saved boundary.")
  if phase=="reaction" and (cursor!=1 or count<2 or intent.is_empty()):return _bad("The saved live response has no locked intent.")
  if phase=="performing" and (cursor>=count and count>0 or (cursor>=1 and count>=2 and intent.is_empty())):return _bad("The saved performance is at an unresolved boundary.")
  if phase in ["after_set","pack_up","wrap_ready"] and (cursor!=count or (count>=2 and intent.is_empty())):return _bad("Finish the saved set and its one live interaction before leaving.")
  var modeled: Dictionary=Policy.feedback(plan,visit["context"],cursor,intent)
  if visit["feedback"]!=modeled["records"] or int(visit["vibe"])!=int(modeled["vibe"]):return _bad("The saved room feedback does not match the completed songs.")
 return {"ok":true,"exists":true,"active":visit.duplicate(true)}

static func _refresh(state: Dictionary, visit: Dictionary) -> Dictionary:
 var after: Dictionary=state.duplicate(true)
 visit["source_hash"]=fingerprint(after)
 visit["participants"]=after.get("members",[]).duplicate(true)
 var wrapper: Dictionary=_wrapper(after)
 wrapper["active"]=visit.duplicate(true)
 after[KEY]=wrapper
 return after

static func _freeze(state: Dictionary, visit: Dictionary) -> Dictionary:
 var plan: Dictionary=state["booked_show"][Flow.FLOW_KEY]["plan"].duplicate(true)
 var captured: Dictionary=Policy.capture(state,plan)
 if not bool(captured.get("ok",false)):return captured
 visit["plan"]=plan
 visit["context"]=captured["context"]
 return {"ok":true,"visit":visit}

static func begin(state: Dictionary, expected_booking_id: String = "") -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid.get("ok",false)):return valid
 if locked(state):return _result(state,"Resume the saved night.")
 valid=_source_guard(state)
 if not bool(valid.get("ok",false)):return valid
 var booking: Dictionary=Calendar.pending(state)
 var id: String=Flow.booking_id(booking)
 if not expected_booking_id.is_empty() and id!=expected_booking_id:return _bad("That booking changed. Reopen the current night.")
 var stage: String=Flow.phase(state)
 var mapped: Dictionary={"travel":"set_out","arrival":"arrival","soundcheck":"soundcheck","stage":"backstage"}
 if not mapped.has(stage):return _bad("This booking cannot start a live journey here.")
 var wrapper: Dictionary=_wrapper(state)
 if int(wrapper["sequence"])>=2147483646:return _bad("The saved night sequence has reached its supported limit.")
 wrapper["sequence"]=int(wrapper["sequence"])+1
 var visit: Dictionary={"version":Flow.version_of(state),"id":"gig-journey:%d:%s" % [int(wrapper["sequence"]),id],"booking_id":id,"phase":str(mapped[stage]),"revision":0,"policy_version":1,"content_version":1,"art_version":"existing_s53_plates","source_hash":"","started_day":int(state.get("tour_day",1)),"started_cash":int(state.get("cash",0)),"participants":state.get("members",[]).duplicate(true),"plan":{},"context":{},"cursor":0,"completed_ids":[],"feedback":[],"vibe":40,"intent":"","last_input":""}
 if Flow.version_of(state)==2:
  wrapper["version"]=2
  var t: Dictionary=Booking.terms(state)
  visit["commitment_id"]=t["commitment_id"]
  visit["departure_committed"]=stage!="travel"
  var liability: int=int(t["tariff"]["travel"])+int(t["tariff"]["accommodation"])
  visit["departure_liability"]=(mini(liability,int(state["cash"])) if booking["venue_id"]=="local" else liability) if stage!="travel" else 0
 elif wrapper["version"]!=1:return _bad("A legacy night cannot be placed in a newer journey wrapper.")
 if stage=="stage":
  var frozen: Dictionary=_freeze(state,visit)
  if not bool(frozen.get("ok",false)):return frozen
  visit=frozen["visit"]
 var after: Dictionary=state.duplicate(true)
 after[KEY]=wrapper
 after=_refresh(after,visit)
 valid=validate(after)
 if not bool(valid.get("ok",false)):return valid
 return _result(after,"Tonight's journey is saved.",true)

static func _owned(state: Dictionary, token: Dictionary) -> Dictionary:
 var checked: Dictionary=validate(state)
 if not bool(checked.get("ok",false)):return checked
 var visit: Dictionary=active(state)
 if visit.is_empty():return _bad("There is no unfinished gig journey.")
 if token.get("journey_id")!=visit["id"] or token.get("phase")!=visit["phase"] or token.get("revision")!=visit["revision"]:return _bad("This moment has already changed. Use the current saved scene.")
 return {"ok":true,"active":visit}

static func checkpoint(state: Dictionary, action: String, token: Dictionary, payload: Dictionary = {}) -> Dictionary:
 var checked: Dictionary=validate(state)
 if not bool(checked.get("ok",false)):return checked
 var visit: Dictionary=active(state)
 var command: String=Policy.fingerprint({"action":action,"expected":token,"payload":payload})
 if not visit.is_empty() and visit.get("last_input","")==command:return _result(state,"This checkpoint is already saved.")
 checked=_owned(state,token)
 if not bool(checked.get("ok",false)):return checked
 visit=checked["active"]
 var after: Dictionary=state.duplicate(true)
 var phase: String=visit["phase"]
 var next: String=""
 if action=="advance":
  var edges: Dictionary={"travel":"arrival","arrival":"load_in","backstage":"stage_entrance","stage_entrance":"performing","after_set":"pack_up","pack_up":"wrap_ready"}
  if phase=="set_out":
   var departed: Dictionary=Flow.depart(after)
   if not bool(departed.get("ok",false)):return departed
   after=departed["state"]
   if visit["version"]==2:
    var t: Dictionary=Booking.terms(after)
    var liability: int=int(t["tariff"]["travel"])+int(t["tariff"]["accommodation"])
    visit["departure_committed"]=true
    visit["departure_liability"]=mini(liability,int(after["cash"])) if after["booked_show"]["venue_id"]=="local" else liability
   next="travel"
  elif phase=="load_in":
   var entered: Dictionary=Night.advance(after)
   if not bool(entered.get("ok",false)):return entered
   after=entered["state"]
   next="soundcheck"
  elif phase=="reaction":next="performing"
  elif edges.has(phase):next=str(edges[phase])
  else:return _bad("This scene needs its own explicit action.")
 elif action=="soundcheck":
  if phase!="soundcheck":return _bad("The soundcheck is not open.")
  var committed: Dictionary=Flow.soundcheck(after,payload)
  if not bool(committed.get("ok",false)):return committed
  after=committed["state"]
  var frozen: Dictionary=_freeze(after,visit)
  if not bool(frozen.get("ok",false)):return frozen
  visit=frozen["visit"]
  next="backstage"
 elif action=="finish_song":
  if phase!="performing":return _bad("The set is not waiting for a song to finish.")
  var ids: Array=visit["plan"]["song_ids"]
  var cursor: int=int(visit["cursor"])
  if cursor>=ids.size() or payload.get("song_id")!=ids[cursor] or payload.get("cursor")!=cursor:return _bad("Finish the current saved original, once, in its agreed order.")
  cursor+=1
  visit["cursor"]=cursor
  visit["completed_ids"]=ids.slice(0,cursor)
  next="choice" if cursor==1 and ids.size()>=2 else ("after_set" if cursor==ids.size() else "performing")
 elif action=="end_short_set":
  if phase!="performing" or not visit["plan"]["song_ids"].is_empty():return _bad("This action is only for a set with no selected originals.")
  next="after_set"
 elif action=="choice":
  if phase!="choice" or not Policy.INTENTS.has(payload.get("intent")):return _bad("Read the room before choosing a live intent.")
  visit["intent"]=str(payload["intent"])
  next="reaction"
 else:return _bad("Unknown live journey action.")
 visit["phase"]=next
 visit["revision"]=int(visit["revision"])+1
 visit["last_input"]=command
 if LOCKED_PHASES.has(next):
  var modeled: Dictionary=Policy.feedback(visit["plan"],visit["context"],int(visit["cursor"]),str(visit["intent"]))
  visit["feedback"]=modeled["records"]
  visit["vibe"]=int(modeled["vibe"])
 after=_refresh(after,visit)
 checked=validate(after)
 if not bool(checked.get("ok",false)):return checked
 return _result(after,"The next moment is saved.",true)

static func rebase_owned_action(before: Dictionary, after: Dictionary, token: Dictionary) -> Dictionary:
 var checked: Dictionary=_owned(before,token)
 if not bool(checked.get("ok",false)):return checked
 var visit: Dictionary=checked["active"]
 if visit["phase"]!="soundcheck" or int(before.get("cash",0))!=int(after.get("cash",0)) or int(before.get("tour_day",0))!=int(after.get("tour_day",0)) or Flow.booking_id(Calendar.pending(before))!=Flow.booking_id(Calendar.pending(after)):return _bad("The original soundcheck response no longer belongs to this night.")
 visit["revision"]=int(visit["revision"])+1
 visit["last_input"]=""
 var rebased: Dictionary=_refresh(after,visit)
 checked=validate(rebased)
 if not bool(checked.get("ok",false)):return checked
 return _result(rebased,"The band's soundcheck response is saved.",true)

static func prepare_wrap(state: Dictionary, token: Dictionary) -> Dictionary:
 var checked: Dictionary=_owned(state,token)
 if not bool(checked.get("ok",false)):return checked
 if checked["active"]["phase"]!="wrap_ready":return _bad("Pack up the completed set before wrapping the night.")
 var prepared: Dictionary=Flow.prepare_performance(state)
 if not bool(prepared.get("ok",false)):return prepared
 return {"ok":true,"active":checked["active"],"projection":prepared["projection"],"plan":prepared["plan"]}

static func complete(after: Dictionary, visit: Dictionary, actual_effects: Dictionary = {}) -> Dictionary:
 var state: Dictionary=after.duplicate(true)
 if active(state)!=visit:return _bad("The journey checkpoint changed during show settlement.")
 var receipt: Dictionary=Flow.last_receipt(state)
 if receipt.is_empty() or receipt.get("booking_id")!=visit["booking_id"]:return _bad("The original show receipt is missing after settlement.")
 var extension: Dictionary={"version":int(visit["version"]),"journey_id":visit["id"],"content_version":1,"policy_version":1,"completed_ids":visit["completed_ids"].duplicate(),"plan":visit["plan"].duplicate(true),"feedback":visit["feedback"].duplicate(true),"vibe":int(visit["vibe"]),"intent":str(visit["intent"]),"context":visit["context"].duplicate(true),"actual_policy_effects":actual_effects.duplicate(true),"kind":"modelled_live_journey"}
 var records: Dictionary=state[Flow.RECORDS_KEY].duplicate(true)
 var rows: Array=records["records"].duplicate(true)
 rows[-1]["journey_v1"]=extension
 records["records"]=rows
 state[Flow.RECORDS_KEY]=records
 var wrapper: Dictionary=_wrapper(state)
 wrapper["active"]={}
 state[KEY]=wrapper
 return {"ok":true,"state":state,"receipt":rows[-1].duplicate(true)}

static func clear_cancelled(after: Dictionary) -> Dictionary:
 var state: Dictionary=after.duplicate(true)
 var wrapper: Dictionary=_wrapper(state)
 wrapper["active"]={}
 state[KEY]=wrapper
 return state

static func view(state: Dictionary) -> Dictionary:
 var checked: Dictionary=validate(state)
 if not bool(checked.get("ok",false)):return {"ok":false,"blocked":true,"phase":"held","message":str(checked.get("message","The saved night is held.")),"active":{}}
 var visit: Dictionary=active(state)
 return {"ok":true,"blocked":false,"phase":str(visit.get("phase","begin")),"active":visit,"eligible":eligible(state),"expected":expected(state),"message":""}
