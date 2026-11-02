extends RefCounted
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
## Pure social/business adapter. Original models resolve all money/day/stat rules.
const Social = preload("res://Scripts/band_social.gd")
const Story = preload("res://Scripts/career_story.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Life = preload("res://Scripts/member_life.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const KEY := "social_contacts_v1"
const PROMOTER := "s48:promoter_intro"
const SCOUT := "s48:scout_intro"
const ORDER := ["watch_gig","drinks","dinner"]

static func view(state: Dictionary) -> Dictionary:
 var raw: Variant = state.get(KEY,{})
 var data: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
 if not data.has("version"):data["version"]=1
 if not data.get("events") is Dictionary:data["events"]={}
 if not data.get("contacts") is Dictionary:data["contacts"]={}
 return data

static func _failure(state: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"state":state.duplicate(true),"message":message,"title":"OFFSTAGE","return_page":"offstage","finance_action":""}

static func _guard(state: Dictionary) -> Dictionary:
 var commitment: Dictionary=Booking.guard_commitment(state,"offstage",0)
 if not bool(commitment.get("ok",false)):return commitment
 var finance: Dictionary = Finance.guard(state)
 if not bool(finance.get("ok",false)):return finance
 if Live.show_day(state):
  return {"ok":false,"message":"Tonight's show comes first. Finish the booking before another activity or introduction."}
 if state.has(KEY):
  var raw: Variant = state[KEY]
  if not raw is Dictionary or not (raw.get("version") is int or raw.get("version") is float) or float(raw.get("version",0))!=1.0 or not raw.get("events") is Dictionary or not raw.get("contacts") is Dictionary:
   return {"ok":false,"message":"The saved social contact metadata needs validation before another action."}
  for section in ["events","contacts"]:
   for id in [PROMOTER,SCOUT]:
    if raw[section].has(id) and not raw[section][id] is Dictionary:
     return {"ok":false,"message":"The saved introduction record needs validation before another action."}
 return {"ok":true,"message":""}

static func _active(state: Dictionary) -> int:
 var count := 0
 for person in state.get("members",[]):
  if person is Dictionary and str(person.get("life_status","active"))=="active":count+=1
 return count

static func activities(state: Dictionary) -> Array:
 var rows: Array = []
 var active: int = _active(state)
 var permitted: Dictionary = _guard(state)
 for id in ORDER:
  var rule: Dictionary = Social.ACTIVITIES[id]
  var cost: int = int(rule["cost_per_member"])*active
  var reason: String = str(permitted.get("message",""))
  if reason.is_empty() and active<2:reason="At least two available bandmates must join the outing."
  if reason.is_empty() and int(state.get("cash",0))<cost:reason="The band needs £%d to cover everyone." % cost
  var effects: String = "MORALE %+d • TENSION %+d • TRUST %+d • BUZZ %+d" % [int(rule["morale"]),int(rule["tension"]),int(rule["trust"]),int(rule["buzz"])]
  if id=="watch_gig":effects+=" • READINESS +2"
  var fatigue: int = 5 if id=="drinks" else -3
  rows.append({"id":id,"title":str(rule["label"]),"description":str(rule["text"])+" Active participants gain 2 loyalty; fatigue %+d." % fatigue,"cost":cost,"days":1,"effects":effects,"active":active,"enabled":reason.is_empty(),"reason":reason})
 return rows

static func pending(state: Dictionary) -> Array:
 var data: Dictionary = view(state)
 var events: Dictionary = data["events"]
 var rows: Array = []
 for id in [PROMOTER,SCOUT]:
  if events.get(id) is Dictionary and str(events[id].get("status",""))=="pending":rows.append(events[id].duplicate(true))
 return rows

static func response_options(state: Dictionary, id: String) -> Array:
 var events: Dictionary = view(state)["events"]
 if not events.get(id) is Dictionary or str(events[id].get("status",""))!="pending":return []
 var permitted: Dictionary = _guard(state)
 var reason: String = str(permitted.get("message",""))
 var rows: Array = []
 if id==PROMOTER:
  var eligibility: Dictionary = Live.booking_eligibility(state,false)
  var booking_reason: String = reason if not reason.is_empty() else str(eligibility.get("message",""))
  rows.append({"id":"accept","label":"REVIEW THE LOCAL SHOW","description":"Choose the date and trip in the shared booking form. Opening it or going back costs nothing and leaves this introduction pending.","cost":0,"days":0,"enabled":reason.is_empty() and bool(eligibility.get("ok",false)),"reason":booking_reason})
 elif id==SCOUT:
  var completed: Variant = state.get("opportunities_resolved",{})
  var resolved: bool = completed is Dictionary and completed.has("first_feature")
  var event: Dictionary = Opportunities.get_event("first_feature")
  for raw in event.get("choices",[]):
   var rule: Dictionary = raw
   var choice_reason: String = reason
   if choice_reason.is_empty() and resolved:choice_reason="This local feature was already resolved. It cannot pay a second reward."
   var effects: String = "BUZZ %+d • FANS %+d • TENSION %+d • MORALE %+d" % [int(rule.get("buzz",0)),int(rule.get("fans",0)),int(rule.get("tension",0)),int(rule.get("morale",0))]
   rows.append({"id":str(rule["id"]),"label":str(rule["label"]),"description":str(rule["text"])+" "+effects,"cost":int(rule.get("cost",0)),"days":int(rule.get("days",0)),"enabled":choice_reason.is_empty(),"reason":choice_reason})
 else:
  return []
 rows.append({"id":"decline","label":"DECLINE THE INTRODUCTION","description":"Close this introduction once. No money or day is spent; ordinary career routes remain available.","cost":0,"days":0,"enabled":reason.is_empty(),"reason":reason})
 return rows

static func _journal(state: Dictionary, id: String, title: String, text: String) -> void:
 var history: Array = state.get("career_journal",[]).duplicate(true)
 for raw in history:
  if raw is Dictionary and str(raw.get("id",""))==id:return
 history.append({"id":id,"day":int(state.get("tour_day",1)),"title":title,"text":text,"kind":"scene"})
 while history.size()>80:history.pop_front()
 state["career_journal"]=history

static func _post(before: Dictionary, after: Dictionary) -> Dictionary:
 return Life.refresh(Calendar.expire(Story.observe(before,after)))

static func _encounter(data: Dictionary, state: Dictionary, id: String, activity: String) -> void:
 var promoter: bool = id==PROMOTER
 var title: String = "A LOCAL PROMOTER" if promoter else "A MUSIC SCOUT"
 var role: String = "Local promoter" if promoter else "Music scout"
 var description: String = "A local promoter offers an introduction to the Lantern Room's standard booking." if promoter else "Your local following attracts a music scout who can introduce the band to a local feature."
 var counter: int = int(state.get("social_counters",{}).get(activity,0))
 var day: int = int(state.get("tour_day",1))
 var source: String = "s48:outing:%s:%d:%d" % [activity,day,counter]
 var contact: Dictionary = data["contacts"].get(id,{}).duplicate(true)
 contact.merge({"id":id,"title":title,"role":role,"description":description,"met_day":day,"source_id":source,"source_day":day,"source_action":activity,"source_counter":counter},true)
 data["contacts"][id]=contact
 var event: Dictionary = {"id":id,"contact_id":id,"title":title,"role":role,"description":description,"status":"pending","source_id":source,"source_day":day,"source_action":activity,"source_counter":counter}
 var resolved: Variant = state.get("opportunities_resolved",{})
 if not promoter and resolved is Dictionary and resolved.has("first_feature"):
  event["status"]="already_resolved"
  event["description"]="The scout meets the band, but its local music feature has already been resolved. No second interview or reward is offered."
  contact["description"]=event["description"]
  data["contacts"][id]=contact
 data["events"][id]=event
 _journal(state,"s48:met:"+id,title,str(event["description"]))

static func outing(state: Dictionary, activity: String) -> Dictionary:
 var commitment: Dictionary=Booking.guard_commitment(state,"offstage",1)
 if not bool(commitment.get("ok",false)):return _failure(state,str(commitment["message"]))
 var permitted: Dictionary = _guard(state)
 if not bool(permitted.get("ok",false)):return _failure(state,str(permitted["message"]))
 var original: Dictionary = Social.attend(state,activity)
 if not bool(original.get("ok",false)):return _failure(state,str(original.get("message","Outing unavailable.")))
 var after: Dictionary = _post(state,original["state"])
 var data: Dictionary = view(after)
 if activity=="watch_gig" and not data["events"].has(PROMOTER):
  _encounter(data,after,PROMOTER,activity)
 var promoter: Variant = data["events"].get(PROMOTER,{})
 if promoter is Dictionary and str(promoter.get("status",""))=="accepted" and not data["events"].has(SCOUT) and int(after.get("fans",0))>=25 and int(after.get("reputation",0))>=10:
  _encounter(data,after,SCOUT,activity)
 after[KEY]=data
 var message: String = str(original.get("message",""))
 var old_events: Dictionary = view(state)["events"]
 for id in [PROMOTER,SCOUT]:
  if not old_events.has(id) and data["events"].has(id):message+="\n\n"+str(data["events"][id].get("description",""))
 return {"ok":true,"state":after,"message":message,"title":str(Social.ACTIVITIES[activity]["label"]),"return_page":"offstage","finance_action":"social:"+activity}

static func respond(state: Dictionary, id: String, choice: String) -> Dictionary:
 var permitted: Dictionary = _guard(state)
 if not bool(permitted.get("ok",false)):return _failure(state,str(permitted["message"]))
 var data: Dictionary = view(state)
 var raw: Variant = data["events"].get(id,{})
 if id not in [PROMOTER,SCOUT] or not raw is Dictionary or str(raw.get("status",""))!="pending":
  return _failure(state,"This introduction is no longer pending.")
 var event: Dictionary = raw.duplicate(true)
 var after: Dictionary = state.duplicate(true)
 var message := "Introduction declined. No money or day was spent."
 var return_page := "offstage"
 var finance_action := "social:decline"
 if choice=="decline":
  event["status"]="declined"
 elif id==PROMOTER and choice=="accept":
  var booked: Dictionary = Live.resolve(state,"book","standard",false)
  if not bool(booked.get("ok",false)):return _failure(state,str(booked.get("message","The show could not be booked.")))
  after=booked["state"].duplicate(true)
  event["status"]="accepted"
  event["accepted_day"]=int(after.get("tour_day",1))
  event["accepted_booking"]=Calendar.pending(after)
  event["booking_day"]=int(event["accepted_booking"].get("day",0))
  message=str(booked.get("message","Show booked."))
  return_page="gigs"
  finance_action="social:promoter_accept"
 elif id==SCOUT and choice in ["open","careful"]:
  var resolved: Variant = state.get("opportunities_resolved",{})
  if resolved is Dictionary and resolved.has("first_feature"):
   return _failure(state,"The local music feature was already resolved. No second reward is available.")
  var prepared: Dictionary = state.duplicate(true)
  var seen: Dictionary = prepared.get("opportunities_seen",{}).duplicate(true)
  seen["first_feature"]=true
  prepared["opportunities_seen"]=seen
  var result: Dictionary = Opportunities.resolve(prepared,"first_feature",choice)
  if not bool(result.get("ok",false)):return _failure(state,str(result.get("message","The feature is unavailable.")))
  after=_post(state,result["state"])
  event["status"]="accepted"
  message=str(result.get("message","Feature completed."))
  finance_action="social:scout_"+choice
 else:
  return _failure(state,"Unknown introduction response.")
 event["choice"]=choice
 event["resolved_day"]=int(after.get("tour_day",1))
 data["events"][id]=event
 after[KEY]=data
 _journal(after,"s48:response:"+id,str(event["title"]),message)
 return {"ok":true,"state":after,"message":message,"title":str(event["title"]),"return_page":return_page,"finance_action":finance_action}


static func booking_handoff(state: Dictionary, event_id: String = PROMOTER) -> Dictionary:
 var guard: Dictionary=Booking.guard_commitment(state,"promoter_introduction",0)
 if not bool(guard.get("ok",false)):return guard
 var raw: Variant=state.get(KEY)
 if not raw is Dictionary or raw.get("version")!=1 or not raw.get("events") is Dictionary or not raw.get("contacts") is Dictionary:return _failure(state,"The saved introduction needs a compatible version.")
 var event: Variant=raw["events"].get(event_id)
 if event_id!=PROMOTER or not event is Dictionary or event.get("id")!=event_id or event.get("status")!="pending" or not event.get("source_id") is String or str(event["source_id"]).is_empty() or not Booking.whole(event.get("source_day"),1) or not Booking.whole(event.get("source_counter")) or not event.get("source_action") is String:return _failure(state,"This promoter introduction is no longer current.")
 return {"ok":true,"origin":{"event_id":event_id,"source_hash":Booking.fingerprint(state),"event":event.duplicate(true),"social_snapshot":raw.duplicate(true)},"request":{"venue_id":"local","offer_id":"standard","session_drummer":false,"travel_plan":"drive_home","day":int(state.get("tour_day",1))+3}}

static func attach_booking_acceptance(before: Dictionary, candidate: Dictionary, origin: Dictionary) -> Dictionary:
 var current: Dictionary=booking_handoff(before,str(origin.get("event_id","")))
 if not bool(current.get("ok",false)):return current
 if Booking.fingerprint(origin)!=Booking.fingerprint(current["origin"]) or Booking.fingerprint(candidate.get(KEY))!=Booking.fingerprint(before.get(KEY)):return _failure(before,"The promoter introduction changed. Review it again.")
 var checked: Dictionary=Booking.validate(candidate)
 if not bool(checked.get("ok",false)) or not Booking.modern(candidate):return _failure(before,"The introduction needs a valid newly saved agreement.")
 if not Calendar.pending(before).is_empty() or int(Booking.memory(candidate)["sequence"])!=int(Booking.memory(before)["sequence"])+1:return _failure(before,"This introduction requires one newly created booking.")
 var t: Dictionary=Booking.terms(candidate)
 if t["venue_snapshot"]["id"]!="local" or t["offer_id"]!="standard":return _failure(before,"This introduction belongs only to the Lantern Room's standard offer.")
 var after: Dictionary=candidate.duplicate(true)
 var data: Dictionary=after[KEY].duplicate(true)
 var event: Dictionary=data["events"][origin["event_id"]].duplicate(true)
 event["status"]="accepted"
 event["choice"]="accept"
 event["accepted_day"]=int(after.get("tour_day",1))
 event["resolved_day"]=int(after.get("tour_day",1))
 event["accepted_booking"]=Calendar.pending(after)
 event["booking_day"]=int(t["day"])
 event["commitment_id"]=t["commitment_id"]
 data["events"][origin["event_id"]]=event
 after[KEY]=data
 _journal(after,"s82:promoter-accept:"+str(t["commitment_id"]),str(event.get("title","A LOCAL PROMOTER")),"Accepted the Lantern Room introduction for DAY %d. The actual booking and trip are saved together." % int(t["day"]))
 return {"ok":true,"state":after,"message":"Promoter introduction accepted with the saved booking.","finance_action":"social:promoter_accept"}
