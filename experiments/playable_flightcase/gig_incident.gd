extends RefCounted
## New, optional visit metadata. Legacy journeys without it retain their path.
## A situation is pinned before display; choices resolve before soundcheck freezes.
const KEY="gig_incident_v1"
const Booking=preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
const KINDS=["rushed_check","tired_member","monitor_balance"]
const CHOICES={"rushed_check":["check","go"],"tired_member":["space","rally"],"monitor_balance":["voice","instruments"]}
static func make(state: Dictionary) -> Dictionary:
 var people: Array=state.get("members",[])
 var person: Dictionary={};var fatigue: int=-1
 for m in people:
  if str(m.get("life_status","active"))=="active" and int(m.get("fatigue",0))>fatigue:person=m;fatigue=int(m.get("fatigue",0))
 var slot: String=str(Booking.terms(state).get(Circuit.BILL,{}).get("slot","opening"))
 var kind: String="tired_member" if fatigue>=55 else ("rushed_check" if state.get("gig_history",[]).is_empty() and slot=="opening" else "monitor_balance")
 var result: Dictionary={"version":1,"kind":kind,"context":{"readiness":clampi(int(state.get("readiness",0)),0,100),"morale":clampi(int(state.get("morale",55)),0,100),"tension":clampi(int(state.get("tension",0)),0,100),"fatigue":maxi(0,fatigue),"actor_id":str(person.get("candidate_id","")),"actor_name":str(person.get("name","A bandmate")),"bill_slot":slot,"show_count":state.get("gig_history",[]).size()},"choice":"","outcome":{}}
 result["context_hash"]=seal(result)
 return result
static func seal(incident: Dictionary) -> String:
 var c: Dictionary=incident.context
 return JSON.stringify([incident.kind,c.actor_id,c.actor_name,c.bill_slot,int(c.show_count),int(c.fatigue),int(c.readiness),int(c.morale),int(c.tension)]).sha256_text()
static func valid_for(raw: Variant,state: Dictionary) -> bool:
 if not valid(raw):return false
 var c: Dictionary=raw.context
 if c.bill_slot!=str(Booking.terms(state).get(Circuit.BILL,{}).get("slot","opening")) or int(c.show_count)!=state.get("gig_history",[]).size():return false
 for member in state.get("members",[]):
  if member.get("candidate_id")==c.actor_id and member.get("name")==c.actor_name:return true
 return false
static func rebase_pending(visit: Dictionary,state: Dictionary) -> Dictionary:
 var result: Dictionary=visit.duplicate(true)
 if pending(result):
  for key in ["readiness","morale","tension"]:result[KEY].context[key]=clampi(int(state.get(key,0)),0,100)
  result[KEY].context_hash=seal(result[KEY])
 return result
static func _whole(v: Variant,lo: int=0,hi: int=100) -> bool:
 return typeof(v) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(v)) and float(v)==floorf(float(v)) and float(v)>=lo and float(v)<=hi
static func outcome(incident: Dictionary,choice: String) -> Dictionary:
 var c: Dictionary=incident.context;var ready: int=0;var morale: int=0;var tension: int=0;var text: String=""
 match incident.kind:
  "rushed_check":
   if choice=="check":
    ready=3 if c.readiness<45 else 1;tension=1
    text="You hold the count-in while the line check is finished. The promoter hurries the changeover, but the band can hear where to start."
   else:
    ready=1 if c.readiness>=45 else -3;morale=1 if c.readiness>=45 else -1;tension=0 if c.readiness>=45 else 3
    text="The band trusts its preparation and makes the rushed changeover work." if c.readiness>=45 else "You take the slot immediately. Without a clear check, the first count-in feels uncertain."
  "tired_member":
   if choice=="space":
    ready=1;morale=2;tension=-2
    text=str(c.actor_name)+" gets a quiet minute while the others finish setting up. You bring them back into the count-in together."
   else:
    ready=2 if c.fatigue<75 else -2;morale=1 if c.fatigue<75 else -2;tension=1 if c.fatigue<75 else 3
    text=str(c.actor_name)+(" responds to the encouragement. The band finds a little momentum together." if c.fatigue<75 else " tries to rise to it, but looks worn out. The pressure follows you towards the stage.")
  "monitor_balance":
   if choice=="voice":
    ready=2 if c.readiness<50 else 0;morale=1;tension=-1
    text="You pull the stage volume back and check the vocal cues. Everyone knows which voice to follow."
   else:
    ready=2 if c.readiness>=50 else -1;morale=1;tension=1
    text="You keep the instruments forward. The band leans on the rehearsed cues." if c.readiness>=50 else "You keep the instruments forward. Finding each other through the stage sound takes concentration."
 return {"readiness":clampi(int(c.readiness)+ready,0,100)-int(c.readiness),"morale":clampi(int(c.morale)+morale,0,100)-int(c.morale),"tension":clampi(int(c.tension)+tension,0,100)-int(c.tension),"text":text}
static func valid(raw: Variant) -> bool:
 if not raw is Dictionary or raw.get("version")!=1 or raw.get("kind") not in KINDS or not raw.get("context") is Dictionary or not raw.get("choice") is String or not raw.get("outcome") is Dictionary:return false
 var c: Dictionary=raw.context
 for k in ["readiness","morale","tension","fatigue"]:
  if not _whole(c.get(k)):return false
 for k in ["actor_id","actor_name","bill_slot"]:
  if not c.get(k) is String:return false
 if c.bill_slot not in ["opening","main_support","headline"] or not _whole(c.get("show_count"),0,2147483647):return false
 var expected_kind: String="tired_member" if int(c.fatigue)>=55 else ("rushed_check" if int(c.show_count)==0 and c.bill_slot=="opening" else "monitor_balance")
 if raw.kind!=expected_kind or raw.get("context_hash")!=seal(raw):return false
 if raw.choice=="":return raw.outcome.is_empty()
 return raw.choice in CHOICES[raw.kind] and raw.outcome==outcome(raw,raw.choice)
static func pending(visit: Dictionary) -> bool:
 return visit.has(KEY) and valid(visit[KEY]) and visit[KEY].choice==""
static func resolve(state: Dictionary,visit: Dictionary,choice: String) -> Dictionary:
 if not pending(visit) or choice not in CHOICES[visit[KEY].kind]:return {"ok":false,"message":"That soundcheck answer is no longer open."}
 var incident: Dictionary=visit[KEY].duplicate(true)
 # Original pre-soundcheck source guard already pins the complete career.
 # Reject context drift rather than applying a stale response to a changed band.
 for key in ["readiness","morale","tension"]:
  if int(state.get(key,0))!=int(incident.context[key]):return {"ok":false,"message":"The band changed before the soundcheck answer."}
 incident.choice=choice;incident.outcome=outcome(incident,choice)
 var after: Dictionary=state.duplicate(true)
 for key in ["readiness","morale","tension"]:after[key]=int(incident.context[key])+int(incident.outcome[key])
 var updated: Dictionary=visit.duplicate(true);updated[KEY]=incident
 return {"ok":true,"state":after,"visit":updated}
static func copy(visit: Dictionary) -> Dictionary:
 if not valid(visit.get(KEY)):return {}
 var i: Dictionary=visit[KEY]
 if i.choice!="":return {"speaker":"THE BAND","title":"YOUR ANSWER, SAVED","text":i.outcome.text,"choices":[]}
 match i.kind:
  "rushed_check":return {"speaker":"PROMOTER","title":"THE CHANGEOVER IS RUNNING LATE","text":"We're running late. You're opening: straight on, or a line check first? Your set and fee stand.","choices":[["check","WE NEED TO HEAR THE COUNT-IN"],["go","WE'LL TAKE THE SLOT NOW"]]}
  "tired_member":return {"speaker":str(i.context.actor_name).to_upper(),"title":"BEFORE WE GO ON","text":"I can play, but I'm worn out. Give me a minute before we count in? The others are waiting beside the stage.","choices":[["space","GIVE THEM A QUIET MINUTE"],["rally","BRING EVERYONE INTO A QUICK HUDDLE"]]}
  "monitor_balance":return {"speaker":"SOUND ENGINEER","title":"WHAT DO YOU NEED TO HEAR?","text":"The instruments are covering the vocal cues. Bring the voice forward, or keep this stage sound and follow each other's playing?","choices":[["voice","MAKE ROOM FOR THE VOICE"],["instruments","KEEP THE INSTRUMENTS FORWARD"]]}
 return {}
