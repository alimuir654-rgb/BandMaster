extends RefCounted
## Authored, contextual conversation memory. No IO, clocks, payments or AI service.
const KEY := "musician_chat_v1"
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
  if int(row.turns.back().day)!=int(row.last_day):return bad("A saved conversation date has changed.")
  var p: Dictionary=row.plan
  if not p.is_empty():
   if p.get("kind") not in ["write","rehearse","rest"] or p.get("status") not in ["pending","kept","missed","strained"] or not whole(p.get("day"),1) or not whole(p.get("due_day"),1) or int(p.due_day)!=int(p.day)+4 or not whole(p.get("fatigue"),0,100) or not p.get("source_report") is String or not p.get("note") is String:return bad("The saved bandmate agreement needs validation.")
   if p.source_report.length()!=64 or not p.source_report.is_valid_hex_number(false) or (p.has("push") and typeof(p.push)!=TYPE_BOOL):return bad("The saved agreement's source or intent needs validation.")
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
 var p: Dictionary=member(state,id)
 var plan: Dictionary=record(state,id).get("plan",{})
 if plan.get("status")=="missed":return "We said we'd make time, but that evening never happened. What are we actually doing next?"
 if plan.get("status")=="strained":return "We got through it, but pushing on wasn't the same as listening. Can we talk about the next one?"
 if plan.get("status")=="kept" and topic=="time":return "We did what we said we'd do. Let's agree the next evening before we fill it with something else."
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
 return {"ok":true,"available":reason.is_empty(),"message":reason,"opening":words,"choices":choices}

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
 row.turns.append({"day":int(state.tour_day),"topic":topic,"choice":choice,"opening":str(view.opening),"reply":reply})
 while row.turns.size()>12:row.turns.pop_front()
 row.last_day=int(state.tour_day)
 if not kind.is_empty():row.plan={"kind":kind,"status":"pending","day":int(state.tour_day),"due_day":int(state.tour_day)+4,"fatigue":int(p.get("fatigue",0)),"source_report":fingerprint(state.get("last_rehearsal_outcome",{})),"note":reply,"push":choice=="push_on"}
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
   var strained: bool=bool(plan.get("push",false)) and int(plan.fatigue)>=50
   plan.status="strained" if strained else "kept";plan.evidence=fingerprint(report) if actual else "observed-recovery"
   plan.note="You followed the plan, but they remember being pushed while exhausted." if strained else "You made time and followed the agreement."
   row.rapport=clampi(int(row.rapport)+(-2 if strained else 2),-20,20)
  elif int(state.tour_day)>int(plan.due_day):
   plan.status="missed";plan.evidence="deadline-passed";plan.note="The agreed window passed without that evening together.";row.rapport=maxi(-20,int(row.rapport)-2)
  else:continue
  plan.resolved_day=int(state.tour_day)
  row.plan=plan;data.records[id]=row
 after[KEY]=data
 return {"ok":true,"state":after}
