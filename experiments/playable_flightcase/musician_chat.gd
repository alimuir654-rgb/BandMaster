extends RefCounted
## Authored, contextual conversation memory. No IO, clocks, payments or AI service.
const KEY := "musician_chat_v1"
const Situations=preload("res://experiments/playable_flightcase/musician_situations.gd")
const TOPICS := ["direction","time","pressure"]
const CHOICES := {
 "direction":["write_together","prepare_set","listen"],
 "time":["agree_evening","leave_room","hold_off"],
 "pressure":["make_space","work_it_out","push_on"]
}
const LABELS := {
 "write_together":"LET'S WORK ON A SONG TOGETHER",
 "prepare_set":"LET'S GET OUR SET READY",
 "listen":"TELL ME WHAT YOU WANT FROM THIS",
 "agree_evening":"LET'S AGREE AN EVENING",
 "leave_room":"LET'S LEAVE SOME BREATHING ROOM",
 "hold_off":"LET'S HOLD OFF ON ANOTHER PROMISE",
 "make_space":"TAKE A BREATHER BEFORE WE PUSH",
 "work_it_out":"LET'S PLAY AND LISTEN TO EACH OTHER",
 "push_on":"LET'S PUSH THROUGH THE NEXT SESSION"
}
## Authored from the existing cast's musical strengths/friction, not appearance.
const VOICES={
 "cast_jack":"I like a part you can remember before the second chorus.",
 "cast_maya":"I've got a few lines in my notebook. They still sound different when I try them out loud.",
 "cast_ellis":"Before we add anything, can we agree where the count-in lands?",
 "cast_zoe":"Leave me a little space and I can give the song somewhere to lean.",
 "cast_dan":"I keep hearing something underneath the guitar. It doesn't have to fill the whole room.",
 "cast_ryan":"A rough take tells me more than another half-hour talking about it.",
 "cast_lily":"Let's do a proper take. We'll hear what's missing.",
 "cast_marcus":"The quiet bits count as part of the groove too.",
 "cast_ben":"I can put the time in. Just play me the change once before we go again.",
 "cast_freya":"There are a few notes I'd take out before I added another layer.",
 "cast_arjun":"I don't need to play over the vocal. I want the chord underneath it to say something.",
 "cast_nina":"Let me find the harmony quietly first. I can bring it up once I've got it.",
 "cast_tom":"Play it once without me. I want to hear where my part belongs.",
 "cast_casey":"I know I rush when I get carried away. Give me the look before the quiet bit.",
 "cast_hannah":"If we know the ending, the rest of it has somewhere to go.",
 "cast_oscar":"I'd rather find one texture that belongs than five that don't.",
 "cast_bex":"Tell me what you actually want to change. I'm not sanding off every rough edge.",
 "cast_sam":"The song needs to feel like somebody means it. I can work with rough."
}
const REPLY_LEADS={
 "cast_jack":"I can get behind that.","cast_maya":"Alright. It helps to know we're trying it together.",
 "cast_ellis":"Right. A plan we can actually count in.","cast_zoe":"That leaves us something to build on.",
 "cast_dan":"I can hear a way into that.","cast_ryan":"Good. Let's make it something we do.",
 "cast_lily":"Alright — but let's give it a proper go.","cast_marcus":"Good. No point rushing what needs room.",
 "cast_ben":"That gives me something I can prepare for.","cast_freya":"Yes. Let's make the room for it.",
 "cast_arjun":"I can work around that.","cast_nina":"That sounds like somewhere I can start.",
 "cast_tom":"I can do that. I'll come in prepared.","cast_casey":"Alright. I'll try to hear you before I charge in.",
 "cast_hannah":"Good. Let's mean it this time.","cast_oscar":"Then let's make something of it.",
 "cast_bex":"Alright. I'll hear it out.","cast_sam":"If we're doing it, let's mean it."
}

static func whole(v: Variant,low: int=0,high: int=2147483647) -> bool:
 return typeof(v) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(v)) and float(v)==floorf(float(v)) and v>=low and v<=high

static func canonical(v: Variant) -> Variant:
 if v is Dictionary:
  var keys: Array=v.keys();keys.sort_custom(func(a: Variant,b: Variant) -> bool:return str(a)<str(b))
  var rows: Array=[]
  for k in keys:rows.append([str(k),canonical(v[k])])
  return [TYPE_DICTIONARY,rows]
 if v is Array:
  var rows: Array=[]
  for item in v:rows.append(canonical(item))
  return [TYPE_ARRAY,rows]
 return [typeof(v),v]

static func fingerprint(v: Variant) -> String:
 return var_to_bytes(canonical(v)).hex_encode().sha256_text()

static func empty() -> Dictionary:
 return {"version":1,"records":{}}

static func validate(state: Dictionary) -> Dictionary:
 if not state.has(KEY):return {"ok":true}
 var raw: Variant=state[KEY]
 if not raw is Dictionary or not whole(raw.get("version"),1,1) or not raw.get("records") is Dictionary or raw.records.size()>64:return bad("The saved musician conversations need a compatible version. They have been retained.")
 for id in raw.records:
  var row: Variant=raw.records[id]
  if not id is String or id.is_empty() or not row is Dictionary or row.get("candidate_id")!=id or not whole(row.get("last_day"),1) or not whole(row.get("rapport"),-20,20) or not row.get("turns") is Array or row.turns.is_empty() or row.turns.size()>12 or not row.get("plan") is Dictionary:return bad("A saved musician conversation cannot be read safely.")
  for turn in row.turns:
   if not turn is Dictionary or not whole(turn.get("day"),1) or turn.get("topic") not in TOPICS or turn.get("choice") not in CHOICES[turn.topic] or not turn.get("opening") is String or not turn.get("reply") is String:return bad("A saved conversation turn needs validation.")
   if turn.has("revision_kind") and (turn.get("revised")!=true or turn.revision_kind not in ["write","rehearse","rest"]):return bad("The saved revised conversation needs validation.")
  if int(row.turns.back().day)!=int(row.last_day):return bad("A saved conversation date has changed.")
  if row.has("plan_sequence") and not whole(row.plan_sequence,1):return bad("The saved promise sequence needs validation.")
  if row.has("plan_history_v1"):
   var history: Variant=row.plan_history_v1
   if not history is Dictionary or not whole(history.get("version"),1,1) or not history.get("records") is Array or history.records.size()>24:return bad("The saved promise history needs a compatible version.")
   var seen: Dictionary={}
   for entry in history.records:
    if not entry is Dictionary or not entry.get("identity") is String or entry.identity.is_empty() or seen.has(entry.identity) or entry.get("closed_as") not in ["revised","completed"] or not whole(entry.get("day"),1) or not entry.get("plan") is Dictionary:return bad("A previous promise cannot be read safely.")
    seen[entry.identity]=true
    var prior: Dictionary=entry.plan.duplicate(true)
    if prior.get("identity",entry.identity)!=entry.identity:return bad("A previous promise identity has changed.")
    prior.erase("identity");prior.erase("revision_count")
    var trial: Dictionary={KEY:{"version":1,"records":{id:{"candidate_id":id,"last_day":row.last_day,"rapport":row.rapport,"turns":row.turns,"plan":prior}}}}
    if not validate(trial).ok:return bad("A previous promise needs validation.")
  var p: Dictionary=row.plan
  if not p.is_empty():
   if p.get("kind") not in ["write","rehearse","rest"] or p.get("status") not in ["pending","kept","missed","strained"] or not whole(p.get("day"),1) or not whole(p.get("due_day"),1) or int(p.due_day)!=int(p.day)+4 or not whole(p.get("fatigue"),0,100) or not p.get("source_report") is String or not p.get("note") is String:return bad("The saved bandmate agreement needs validation.")
   if p.source_report.length()!=64 or not p.source_report.is_valid_hex_number(false) or (p.has("push") and typeof(p.push)!=TYPE_BOOL):return bad("The saved agreement's source or intent needs validation.")
   if p.has("identity") and (not p.identity is String or p.identity!="musician-plan:%s:%d" % [id,int(row.get("plan_sequence",0))] or not whole(p.get("revision_count"),0,1)):return bad("The saved promise identity needs validation.")
   if p.get("status")!="pending" and (not whole(p.get("resolved_day"),1) or not p.get("evidence") is String):return bad("The saved agreement result has no recorded source.")
 return {"ok":true}

static func bad(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func member(state: Dictionary,id: String) -> Dictionary:
 var found: Dictionary={}
 for p in state.get("members",[]):
  if p is Dictionary and p.get("candidate_id")==id:
   if not found.is_empty():return {}
   found=p.duplicate(true)
 return found

static func record(state: Dictionary,id: String) -> Dictionary:
 if not validate(state).ok:return {}
 return state.get(KEY,{}).get("records",{}).get(id,{}).duplicate(true)

static func opening(state: Dictionary,id: String,topic: String) -> String:
 var context: String=_situation_opening(state,id,topic)
 if topic=="direction" and VOICES.has(id):return str(VOICES[id])+"\n\n"+context
 return context

static func _situation_opening(state: Dictionary,id: String,topic: String) -> String:
 var p: Dictionary=member(state,id)
 var plan: Dictionary=record(state,id).get("plan",{})
 if plan.get("status")=="missed":return "We said we'd make time, but that evening never happened. What are we actually doing next?"
 if plan.get("status")=="strained":return "We got through it, but pushing on wasn't the same as listening. Can we talk about the next one?"
 if plan.get("status")=="kept" and topic=="time":return "We did what we said we'd do. Let's agree the next evening before we fill it with something else."
 if plan.get("status")=="pending":return Situations.checkin(id,topic,str(plan.kind),int(plan.due_day),int(p.get("fatigue",0))>=55)
 if Situations.OPENINGS.has(id):return Situations.opening(id,topic,"")
 if topic=="time":return "I've got life outside this band as well. Tell me the evening before you promise us to anyone."
 if topic=="pressure":
  if int(p.get("fatigue",0))>=50:return "I'm running low. I want this to work, but another hard push isn't always the answer."
  if int(state.get("tension",0))>=45:return "We keep talking past each other. What do you want the next session to be?"
  return "How do we keep this feeling like our band when things start moving?"
 if not state.get("booked_show",{}).is_empty():return "We've got a room waiting for us. Do we trust the songs, or do we need another evening on the set?"
 if not state.get("current_song_draft",{}).is_empty():return "There's an idea on the desk. I want to know where you think I fit into it."
 return "What do we want to sound like when someone hears us for the first time? I've got ideas too."

static func options(state: Dictionary,id: String,topic: String) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not valid.ok:return valid
 var p: Dictionary=member(state,id)
 if p.is_empty() or p.get("life_status","active")!="active" or topic not in TOPICS or not whole(state.get("tour_day"),1,2147483643):return bad("Choose a current bandmate and conversation.")
 var row: Dictionary=record(state,id)
 var reason: String=""
 if int(row.get("last_day",0))>=int(state.tour_day):reason="You've already had a proper conversation today. Their words are saved below."
 if row.get("plan",{}).get("status")=="pending":reason="There's still an agreement between you. Follow it through or come back after its agreed window."
 var choices: Array=CHOICES[topic].duplicate()
 var words: String=opening(state,id,topic)
 if int(row.get("rapport",0))<=-4:
  words+=" I need to see one plan through before we talk about another big push."
  choices.erase("push_on")
 return {"ok":true,"available":reason.is_empty(),"message":reason,"opening":words,"choices":choices,"can_revise":row.get("plan",{}).get("status")=="pending" and int(row.plan.get("revision_count",0))<1 and int(state.tour_day)<=int(row.plan.get("due_day",0))}

static func turn_label(turn: Dictionary) -> String:
 if turn.get("revised",false)==true:return {"write":"LET'S MAKE TIME FOR A SONG","rehearse":"LET'S AGREE A REHEARSAL","rest":"LET'S LEAVE ROOM TO RECOVER"}.get(turn.get("revision_kind",""),"LET'S CHANGE OUR PLAN")
 return str(LABELS.get(turn.get("choice",""),"OUR CONVERSATION"))

static func _archive(row: Dictionary,today: int,why: String) -> void:
 if row.get("plan",{}).is_empty():return
 var history: Dictionary=row.get("plan_history_v1",{"version":1,"records":[]}).duplicate(true)
 var old: Dictionary=row.plan.duplicate(true)
 var identity: String=str(old.get("identity","legacy-plan:"+fingerprint(old)))
 history.records.append({"identity":identity,"plan":old,"closed_as":why,"day":today})
 while history.records.size()>24:history.records.pop_front()
 row["plan_history_v1"]=history

static func _plan(row: Dictionary,state: Dictionary,p: Dictionary,kind: String,note: String,push: bool,revisions: int=0) -> Dictionary:
 row["plan_sequence"]=int(row.get("plan_sequence",0))+1
 return {"identity":"musician-plan:%s:%d" % [str(p.candidate_id),int(row.plan_sequence)],"revision_count":revisions,"kind":kind,"status":"pending","day":int(state.tour_day),"due_day":int(state.tour_day)+4,"fatigue":int(p.get("fatigue",0)),"source_report":fingerprint(state.get("last_rehearsal_outcome",{})),"note":note,"push":push}

static func revise(state: Dictionary,id: String,kind: String,expected: String) -> Dictionary:
 if expected!=fingerprint(state):return bad("The band changed. Read the current agreement before revising it.")
 var view: Dictionary=options(state,id,"time")
 if not view.get("ok",false) or not view.get("can_revise",false) or kind not in ["write","rehearse","rest"]:return bad("That agreement cannot be revised again. Its history is retained.")
 var after: Dictionary=state.duplicate(true);var data: Dictionary=after[KEY].duplicate(true);var row: Dictionary=data.records[id]
 var p: Dictionary=member(state,id)
 _archive(row,int(state.tour_day),"revised")
 var note: String="We changed the plan together. Let's %s within the next four days." % {"write":"work on the song","rehearse":"rehearse","rest":"leave room to recover"}[kind]
 row.plan=_plan(row,state,p,kind,note,false,1)
 row.turns.append({"day":int(state.tour_day),"topic":"time","choice":"agree_evening","opening":str(view.opening),"reply":note,"revised":true,"revision_kind":kind})
 while row.turns.size()>12:row.turns.pop_front()
 row.last_day=int(state.tour_day);data.records[id]=row;after[KEY]=data
 return {"ok":true,"state":after,"message":str(p.get("name","Bandmate"))+": "+note}

static func answer(state: Dictionary,id: String,topic: String,choice: String,expected: String) -> Dictionary:
 if expected!=fingerprint(state):return bad("The band changed. Read the current conversation before answering.")
 var view: Dictionary=options(state,id,topic)
 if not view.get("ok",false) or not view.get("available",false):return bad(str(view.get("message","This conversation is held.")))
 if choice not in view.choices:return bad("Choose one of this conversation's replies.")
 var p: Dictionary=member(state,id)
 var after: Dictionary=state.duplicate(true)
 var data: Dictionary=after.get(KEY,empty()).duplicate(true)
 var row: Dictionary=data.records.get(id,{"candidate_id":id,"last_day":0,"rapport":0,"turns":[],"plan":{}}).duplicate(true)
 var kind: String="write" if choice=="write_together" else ("rest" if choice in ["leave_room","make_space"] else ("rehearse" if choice in ["prepare_set","agree_evening","work_it_out","push_on"] else ""))
 var reply: String="I want room to bring an idea in, and a band that listens when I do." if p.get("trait") in ["Creative","Restless","Perfectionist"] else "I want us to mean it when we say we'll show up. A clear plan matters to me."
 if kind=="write":reply="Bring that idea in. Let's work on a song within the next four days, with both of us there."
 elif kind=="rest":reply="Leave me a little room to recover over the next four days. Then we can decide what comes next."
 elif kind=="rehearse":reply="Let's agree an evening and rehearse within the next four days. Check that I'm actually free before you book it."
 if choice=="push_on" and int(p.get("fatigue",0))>=50:reply="I'll try, but I'm tired. Being in the room won't mean that pushing was the right call."
 if choice=="hold_off":reply="Fair. I'd rather hear that now than be promised an evening that never comes."
 if REPLY_LEADS.has(id):reply=str(REPLY_LEADS[id])+" "+reply
 row.turns.append({"day":int(state.tour_day),"topic":topic,"choice":choice,"opening":str(view.opening),"reply":reply})
 while row.turns.size()>12:row.turns.pop_front()
 row.last_day=int(state.tour_day)
 if not kind.is_empty():
  _archive(row,int(state.tour_day),"completed")
  row.plan=_plan(row,state,p,kind,reply,choice=="push_on")
 data.records[id]=row;after[KEY]=data
 return {"ok":true,"state":after,"message":str(p.get("name","Bandmate"))+": "+reply}

static func reconcile(state: Dictionary) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not valid.ok:return valid
 var after: Dictionary=state.duplicate(true)
 if not state.has(KEY):return {"ok":true,"state":after}
 # A live checkpoint owns a hash of the entire surrounding career. Keep its
 # promises frozen until that existing journey is explicitly wrapped/cancelled.
 var night: Variant=state.get("gig_journey_v1",{})
 if night is Dictionary and night.get("active",{}) is Dictionary and not night.get("active",{}).is_empty():return {"ok":true,"state":after}
 var data: Dictionary=after[KEY].duplicate(true)
 if not state.get("last_rehearsal_outcome",{}) is Dictionary:return bad("The saved session report needs validation before remembering this agreement.")
 var report: Dictionary=state.get("last_rehearsal_outcome",{})
 if not report.get("member_changes",[]) is Array or not whole(report.get("day",0)):return bad("The saved session attendance or date cannot be read safely.")
 for id in data.records:
  var row: Dictionary=data.records[id]
  var plan: Dictionary=row.plan
  if plan.get("status")!="pending":continue
  var p: Dictionary=member(state,id)
  var attended: bool=false
  for change in report.get("member_changes",[]):
   if change is Dictionary and change.get("candidate_id")==id:attended=true
  var actual: bool=not report.is_empty() and fingerprint(report)!=plan.source_report and int(report.get("day",0))>int(plan.day) and int(report.get("day",0))<=int(plan.due_day)+1 and attended
  var kept: bool=(actual and ((plan.kind=="write" and report.get("focus")=="create") or (plan.kind=="rehearse" and report.get("focus")=="tighten"))) or (plan.kind=="rest" and not p.is_empty() and int(state.tour_day)>int(plan.day) and int(state.tour_day)<=int(plan.due_day)+1 and int(p.get("fatigue",0))<int(plan.fatigue))
  if kept:
   var effort: Dictionary=session_effort(report,id) if actual and plan.kind=="rehearse" else {"kind":"unknown","worn":false}
   var strained: bool=effort.kind=="push" and bool(effort.worn)
   plan.status="strained" if strained else "kept";plan.evidence=fingerprint(report) if actual else "observed-recovery"
   plan["effort_evidence"]=str(effort.kind)
   var direction: Variant=report.get("direction",{})
   plan.note=Situations.result(id,str(plan.kind),str(plan.status),str(direction.get("focus","")) if direction is Dictionary else "")
   if actual and plan.kind=="rehearse" and effort.kind=="unknown":plan.note+=" The pace of that session wasn't recorded."
   row.rapport=clampi(int(row.rapport)+(-2 if strained else 2),-20,20)
  elif int(state.tour_day)>int(plan.due_day):
   plan.status="missed";plan.evidence="deadline-passed";plan.note=Situations.result(id,str(plan.kind),"missed","");row.rapport=maxi(-20,int(row.rapport)-2)
  else:continue
  plan.resolved_day=int(state.tour_day)
  row.plan=plan;data.records[id]=row
 after[KEY]=data
 return {"ok":true,"state":after}

static func session_effort(report: Dictionary,id: String) -> Dictionary:
 var direction: Variant=report.get("direction",{})
 if not direction is Dictionary or direction.get("effort") not in ["steady","push"]:return {"kind":"unknown","worn":false}
 var notes: Variant=report.get("direction_notes",[])
 if not notes is Array:return {"kind":"unknown","worn":false}
 for note in notes:
  if note is Dictionary and note.get("candidate_id")==id and typeof(note.get("worn"))==TYPE_BOOL:return {"kind":str(direction.effort),"worn":note.worn}
 for change in report.get("member_changes",[]):
  if change is Dictionary and change.get("candidate_id")==id:
   var changes: Variant=change.get("changes",{})
   if not changes is Dictionary:return {"kind":"unknown","worn":false}
   var fatigue: Variant=changes.get("fatigue",{})
   if not fatigue is Dictionary:return {"kind":"unknown","worn":false}
   var before: Variant=fatigue.get("before")
   if whole(before,0,100):return {"kind":str(direction.effort),"worn":int(before)>=55}
 return {"kind":"unknown","worn":false}
