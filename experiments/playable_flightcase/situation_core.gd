extends RefCounted
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
## Owned, optional career facts. No personal money or canonical biographies are inferred.
const KEY := "situation_core_v1"
const Starting = preload("res://experiments/playable_flightcase/member_commitments.gd")
const KINDS := ["unknown","day_job","family_supported","flexible"]
const MAX_NUMBER := 2147483647
const WEEK_SOURCE := "agreed_band_week_20261105"
const WEEKDAYS := ["MON","TUE","WED","THU","FRI","SAT","SUN"]

static func exact(first: Variant, second: Variant) -> bool:
 # Iterative typed equality: Dictionary order is immaterial, key/scalar types
 # and exact binary float values are not. No recursive Array equality.
 var pending: Array=[[first,second]]
 var visited: int=0
 while not pending.is_empty():
  visited+=1
  if visited>2000000:return false
  var pair: Array=pending.pop_back()
  var a: Variant=pair[0];var b: Variant=pair[1]
  if typeof(a)!=typeof(b):return false
  if a is Dictionary:
   if a.size()!=b.size():return false
   var keys: Dictionary={}
   for key in b:keys[var_to_bytes(key).hex_encode()]=key
   for key in a:
    var code: String=var_to_bytes(key).hex_encode()
    if not keys.has(code):return false
    pending.append([a[key],b[keys[code]]])
  elif a is Array:
   if a.size()!=b.size():return false
   for index in range(a.size()):pending.append([a[index],b[index]])
  elif typeof(a) not in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING,TYPE_STRING_NAME] or var_to_bytes(a)!=var_to_bytes(b):return false
 return true

static func _weekly_ok(value: Variant) -> bool:
 if not value is Dictionary or typeof(value.get("version"))!=TYPE_INT or value.version!=1:return false
 if typeof(value.get("anchor_day"))!=TYPE_INT or value.anchor_day!=1 or value.get("window")!="EVENING" or value.get("source") not in [WEEK_SOURCE,Starting.SOURCE]:return false
 if typeof(value.get("window"))!=TYPE_STRING or typeof(value.get("source"))!=TYPE_STRING or not value.get("unavailable_days") is Array:return false
 if value.unavailable_days.is_empty() or value.unavailable_days.size()>7:return false
 var previous: int=-1
 for day in value.unavailable_days:
  if typeof(day)!=TYPE_INT or day<0 or day>6 or day<=previous:return false
  previous=day
 return true

static func weekday_words(days: Array) -> String:
 var words: PackedStringArray=[]
 for day in days:words.append(WEEKDAYS[int(day)])
 return ", ".join(words)

static func _fail(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func _integer(value: Variant, minimum: int = 0) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=minimum and float(value)<=MAX_NUMBER

static func _empty() -> Dictionary:
 return {"version":1,"revision":0,"sequence":0,"member_contexts":{},"plans":[],"attendance_history":[],"agreements":{},"processed":{}}

static func _identity(person: Dictionary) -> String:
 return str(person.get("candidate_id","")) if person.get("candidate_id","") is String else ""

static func validate(state: Dictionary) -> Dictionary:
 if not _integer(state.get("tour_day",null),1):return _fail("The career day is not readable. No situation was changed.")
 if not state.get("members",null) is Array:return _fail("The current line-up is not readable.")
 var identities: Dictionary={}
 for person in state["members"]:
  if not person is Dictionary:return _fail("A current musician is not readable.")
  var id: String=_identity(person)
  if not id.is_empty():
   if identities.has(id):return _fail("The current line-up contains a repeated identity.")
   identities[id]=true
 if not state.has(KEY):return {"ok":true,"exists":false,"core":_empty()}
 var raw: Variant=state[KEY]
 if not raw is Dictionary or not _integer(raw.get("version",null),1) or int(raw.version)!=1:return _fail("This saved situation format needs a compatible version. It has been retained.")
 for field in ["revision","sequence"]:
  if not _integer(raw.get(field,null)):return _fail("The situation history is incomplete. It has been retained.")
 for field in ["member_contexts","agreements","processed"]:
  if not raw.get(field,null) is Dictionary:return _fail("The situation history is incomplete. It has been retained.")
 for field in ["plans","attendance_history"]:
  if not raw.get(field,null) is Array:return _fail("The situation history is incomplete. It has been retained.")
 for id in raw.member_contexts:
  var context: Variant=raw.member_contexts[id]
  if not id is String or id.is_empty() or not context is Dictionary or not context.get("kind",null) in KINDS:return _fail("A recorded outside-band context is not readable.")
  if not _integer(context.get("recorded_day",null),1):return _fail("A context date is not readable.")
  if context.kind=="day_job" and (not _integer(context.get("shift_anchor",null),1) or context.get("shift_period",0)!=2 or context.get("window","")!="EVENING"):return _fail("A recorded shift schedule is not readable.")
  if context.has("weekly_v1") and (context.kind!="day_job" or not _weekly_ok(context.weekly_v1)):return _fail("This saved weekly availability needs a compatible version. Its original work pattern is retained.")
  if context.has("family_weekly_v1") and (not _weekly_ok(context.family_weekly_v1) or context.family_weekly_v1.source!=Starting.SOURCE):return _fail("The saved family commitment needs a compatible version. It is retained.")
  if context.has("family_weekly_v1") and not context.has("starting_context_v1"):return _fail("The saved family commitment has no known source. It is retained.")
  if context.has("starting_context_v1"):
   var start: Variant=context.starting_context_v1
   if not start is Dictionary or typeof(start.get("version"))!=TYPE_INT or start.version!=1 or start.get("source")!=Starting.SOURCE or start.get("candidate_id")!=id or not Starting.ROWS.has(id) or start.get("job_title")!=Starting.ROWS[id].job_title:return _fail("The known starting circumstances need a compatible version. They are retained.")
   if context.kind not in ["day_job","flexible"]:return _fail("The known work commitment has an unsupported status.")
   if context.kind=="day_job" and (not context.has("weekly_v1") or context.weekly_v1.source!=Starting.SOURCE or not exact(context.weekly_v1.unavailable_days,Starting.ROWS[id].work_evenings)):return _fail("The starting work rota is incomplete. It is retained.")
   var has_family: bool=not Starting.ROWS[id].family_evenings.is_empty()
   if has_family!=context.has("family_weekly_v1"):return _fail("The known family commitment is incomplete. It is retained.")
   if has_family and not exact(context.family_weekly_v1.unavailable_days,Starting.ROWS[id].family_evenings):return _fail("The known family evenings changed. They are retained for review.")
   if context.kind=="flexible" and not context.has("job_change_v1"):return _fail("The saved work change is incomplete. No free evenings have been assumed.")
   if context.get("family_note","")!=Starting.ROWS[id].family_note:return _fail("The saved family context changed. It is retained for review.")
  if context.has("job_change_v1"):
   var change: Variant=context.job_change_v1
   if not context.has("starting_context_v1") or not change is Dictionary or typeof(change.get("version"))!=TYPE_INT or change.version!=1 or change.get("source")!=Starting.SOURCE or change.get("kind")!="left_job" or context.kind!="flexible" or not _integer(change.get("day"),1) or int(change.day)>int(state.tour_day) or change.get("job_title")!=context.starting_context_v1.job_title or not change.get("completed_show_ids") is Array or change.completed_show_ids.size()!=3:return _fail("The saved job-change history needs a compatible version. It is retained.")
   var receipts: Dictionary={}
   for receipt_id in change.completed_show_ids:
    if typeof(receipt_id)!=TYPE_STRING or receipt_id.is_empty() or receipts.has(receipt_id):return _fail("The saved job-change evidence is incomplete.")
    receipts[receipt_id]=true

 for id in raw.agreements:
  var agreement: Variant=raw.agreements[id]
  if not id is String or not agreement is Dictionary:return _fail("The agreement history is not readable.")
  for field in ["excluded","kept","broken"]:
   if not _integer(agreement.get(field,null)):return _fail("The agreement history is not readable.")
 var plan_ids: Dictionary={}
 for plan in raw.plans:
  if not plan is Dictionary or not plan.get("id",null) is String or str(plan.id).is_empty() or plan_ids.has(plan.id):return _fail("A saved rehearsal plan is not readable.")
  plan_ids[plan.id]=true
  if not _integer(plan.get("day",null),1) or not _integer(plan.get("source_day",null),1) or plan.get("window","")!="EVENING" or not plan.get("status","") in ["planned","fulfilled","missed"] or not plan.get("participant_ids",null) is Array:return _fail("A saved rehearsal plan is not readable.")
  var seen: Dictionary={}
  for id in plan.participant_ids:
   if not id is String or id.is_empty() or seen.has(id):return _fail("A saved rehearsal agreement has an invalid identity.")
   seen[id]=true
 for item in raw.attendance_history:
  if not item is Dictionary or not item.get("id",null) is String or not _integer(item.get("day",null),1) or not item.get("attendee_ids",null) is Array or not item.get("absent_ids",null) is Array:return _fail("A saved attendance record is not readable.")
 return {"ok":true,"exists":true,"core":raw.duplicate(true)}

static func members(state: Dictionary) -> Array:
 var checked: Dictionary=validate(state)
 if not checked.ok:return []
 var rows: Array=[]
 var contexts: Dictionary=checked.core.member_contexts
 for index in range(state.members.size()):
  var person: Dictionary=state.members[index]
  var id: String=_identity(person)
  var context: Dictionary=contexts.get(id,{"kind":"unknown"}).duplicate(true)
  rows.append({"id":id,"index":index,"name":str(person.get("name","")),"kind":str(context.get("kind","unknown")),"context":context,"editable":not id.is_empty(),"active":str(person.get("life_status","active"))=="active"})
 return rows

static func starting_context(context: Dictionary) -> bool:
 return context.get("starting_context_v1") is Dictionary and context.starting_context_v1.get("source")==Starting.SOURCE

static func context_text(row: Dictionary, today: int) -> String:
 var context: Dictionary=row.get("context",{})
 if starting_context(context):
  var result: String=str(context.starting_context_v1.job_title)+". "
  if context.has("job_change_v1"):result="Left the "+str(context.starting_context_v1.job_title).to_lower()+" job on DAY %d. Work evenings are now available." % int(context.job_change_v1.day)
  else:result+="Known work evenings: "+weekday_words(context.weekly_v1.unavailable_days)+"."
  if context.has("family_weekly_v1"):result+=" Family: "+weekday_words(context.family_weekly_v1.unavailable_days)+". "+str(context.family_note)
  return result+" Personal income is separate from the band fund."
 match str(row.get("kind","unknown")):
  "day_job":
   if context.has("weekly_v1"):
    return "Agreed work evenings: "+weekday_words(context.weekly_v1.unavailable_days)+". Writing and rehearsal must work around these evenings. Personal wages are not simulated."
   var anchor: int=int(context.get("shift_anchor",today))
   var next: int=today if (today-anchor)%2==0 else today+1
   return "Player-recorded day job. Evening shift every other day: DAY %d, %d, %d. Personal wages are not simulated." % [next,next+2,next+4]
  "family_supported":return "Player-recorded family support. Evenings are flexible; no personal income or family contribution is simulated."
  "flexible":return "Player-recorded flexible evenings. No personal income or employment history is assumed."
 return "Outside-band circumstances not recorded. No job, family support or missed wages are assumed."

static func _compare(state: Dictionary, expected: Dictionary) -> bool:
 return expected.is_empty() or exact(state,expected)

static func _put(state: Dictionary, core: Dictionary, message: String) -> Dictionary:
 if int(core.revision)>=MAX_NUMBER:return _fail("The situation history has reached its supported limit.")
 var next: Dictionary=state.duplicate(true)
 core.revision=int(core.revision)+1
 next[KEY]=core.duplicate(true)
 return {"ok":true,"changed":true,"state":next,"message":message}

static func set_context(state: Dictionary, id: String, kind: String, expected: Dictionary = {}) -> Dictionary:
 var commitment: Dictionary=Booking.guard_commitment(state,"recorded_context",0)
 if not bool(commitment.get("ok",false)):return _fail(str(commitment["message"]))
 var checked: Dictionary=validate(state)
 if not checked.ok:return checked
 if not _compare(state,expected):return _fail("The band changed. Reopen this musician's context before saving.")
 if not kind in KINDS:return _fail("Choose one of the recorded context options.")
 var found: bool=false
 for row in members(state):
  if row.id==id and row.editable:found=true
 if not found:return _fail("That current musician has no usable stable identity.")
 var core: Dictionary=checked.core
 var old: Dictionary=core.member_contexts.get(id,{"kind":"unknown"})
 if old.get("kind","unknown")==kind:return {"ok":true,"changed":false,"state":state.duplicate(true),"message":"This context is already recorded."}
 if starting_context(old):
  if old.kind!="day_job" or kind!="flexible":return _fail("These known commitments cannot be erased as an unrecorded context. Talk about a work change instead.")
  var offer: Dictionary=job_change_offer(state,id)
  if not offer.get("eligible",false):return _fail(str(offer.get("message","The band is still establishing itself. Keep the known commitments for now.")))

 var context: Dictionary=old.duplicate(true)
 context["kind"]=kind
 context["recorded_day"]=int(state.tour_day)
 if kind=="day_job":
  context["shift_anchor"]=int(state.tour_day)
  context["shift_period"]=2
  context["window"]="EVENING"
 else:
  for field in ["shift_anchor","shift_period","window","weekly_v1"]:context.erase(field)
 if starting_context(old):
  context["job_change_v1"]={"version":1,"source":Starting.SOURCE,"kind":"left_job","day":int(state.tour_day),"job_title":old.starting_context_v1.job_title,"completed_show_ids":job_change_offer(state,id).completed_show_ids.duplicate()}
 core.member_contexts[id]=context
 return _put(state,core,"The work change is saved. Family commitments remain; no day or band money was used." if starting_context(old) else "Outside-band context saved. The original biography is unchanged.")

static func commitment_reasons(context: Dictionary, day: int) -> Array:
 var result: Array=[]
 if day<1:return result
 var working: bool=false
 if context.get("kind")=="day_job":
  if context.has("weekly_v1"):working=_weekly_ok(context.weekly_v1) and context.weekly_v1.unavailable_days.has((day-1)%7)
  else:working=day>=int(context.get("shift_anchor",day+1)) and (day-int(context.get("shift_anchor",day+1)))%2==0
 if working:result.append({"kind":"work","label":"work shift"})
 if context.has("family_weekly_v1") and _weekly_ok(context.family_weekly_v1) and context.family_weekly_v1.unavailable_days.has((day-1)%7):result.append({"kind":"family","label":"family commitment"})
 return result

static func _shift(context: Dictionary, day: int) -> bool:
 return not commitment_reasons(context,day).is_empty()

static func seed_starting(state: Dictionary) -> Dictionary:
 var checked: Dictionary=validate(state)
 if not checked.ok:return checked
 if checked.exists:return {"ok":true,"changed":false,"state":state.duplicate(true),"message":"Existing recorded circumstances are retained."}
 if int(state.tour_day)!=1:return _fail("Starting commitments belong only to a new band. Existing history is retained.")
 var core: Dictionary=checked.core
 for row in members(state):
  var known: Dictionary=Starting.for_candidate(str(row.id))
  if not row.active or known.is_empty():continue
  var context: Dictionary={"kind":"day_job","recorded_day":1,"shift_anchor":1,"shift_period":2,"window":"EVENING","weekly_v1":{"version":1,"anchor_day":1,"unavailable_days":known.work_evenings.duplicate(),"window":"EVENING","source":Starting.SOURCE},"starting_context_v1":{"version":1,"source":Starting.SOURCE,"candidate_id":row.id,"job_title":known.job_title},"family_note":known.family_note}
  if not known.family_evenings.is_empty():context["family_weekly_v1"]={"version":1,"anchor_day":1,"unavailable_days":known.family_evenings.duplicate(),"window":"EVENING","source":Starting.SOURCE}
  core.member_contexts[row.id]=context
 var result: Dictionary=_put(state,core,"The band's known starting commitments are recorded.")
 if not result.ok or not validate(result.state).ok:return _fail("The new starting commitments could not be validated.")
 return result

static func job_change_offer(state: Dictionary, id: String) -> Dictionary:
 var result: Dictionary={"eligible":false,"completed_show_ids":[],"message":"The band is still establishing itself. Keep the known commitments for now."}
 var checked: Dictionary=validate(state)
 if not checked.ok:result.message=checked.message;return result
 var person: Dictionary={}
 for row in members(state):
  if row.id==id:person=row;break
 if person.is_empty() or not person.active or not starting_context(person.context) or person.kind!="day_job" or person.context.has("job_change_v1"):return result
 if int(state.tour_day)<15:return result
 if not Booking.validate(state).ok:return result
 var ids: Array=[]
 for receipt in Booking.memory(state).records:
  if receipt.kind=="completed" and int(receipt.day)<=int(state.tour_day) and not ids.has(receipt.commitment_id):ids.append(receipt.commitment_id)
 if ids.size()<3:return result
 result.eligible=true;result.completed_show_ids=ids.slice(ids.size()-3);result.message="There has been sustained live work. You can discuss making more room for the band; leaving a job is still their life outside it."
 return result

static func agree_weekly(state: Dictionary, proposals: Dictionary) -> Dictionary:
 var checked: Dictionary=validate(state)
 if not checked.ok:return checked
 var core: Dictionary=checked.core
 var actual: Dictionary={}
 for row in members(state):
  if row.active and row.editable:actual[row.id]=row
 var changed: bool=false
 for id in proposals:
  if typeof(id)!=TYPE_STRING or not actual.has(id) or actual[id].kind!="unknown":return _fail("The proposed musicians changed. Reopen the working week.")
  var weekly: Dictionary={"version":1,"anchor_day":1,"unavailable_days":proposals[id],"window":"EVENING","source":WEEK_SOURCE}
  if not _weekly_ok(weekly):return _fail("The proposed work evenings are not readable.")
  var context: Dictionary=core.member_contexts.get(id,{"kind":"unknown"}).duplicate(true)
  context["kind"]="day_job";context["recorded_day"]=int(state.tour_day)
  context["shift_anchor"]=1;context["shift_period"]=2;context["window"]="EVENING"
  context["weekly_v1"]=weekly.duplicate(true)
  core.member_contexts[id]=context
  changed=true
 if not changed:return {"ok":true,"changed":false,"state":state.duplicate(true),"message":"Existing recorded circumstances are retained."}
 return _put(state,core,"The proposed work evenings have been agreed.")

static func inspect_writing(state: Dictionary) -> Dictionary:
 var view: Dictionary=inspect_rehearsal(state)
 if not view.ok:return view
 var names: PackedStringArray=[]
 for row in view.absent:names.append(str(row.name))
 view["can_write"]=names.is_empty()
 view["work_names"]=", ".join(names)
 var reasons: PackedStringArray=[]
 for row in view.absent:reasons.append(str(row.name)+" · "+str(row.reason))
 view["unavailable_summary"]="; ".join(reasons)
 view["message"]="Unavailable this evening: "+str(view.unavailable_summary)+". The whole band is needed for this writing session; no day or money has been used." if not names.is_empty() else ""
 view["next_full_day"]=0
 for offset in range(15):
  if int(state.tour_day)>MAX_NUMBER-offset:break
  var target: int=int(state.tour_day)+offset
  var free: bool=true
  for row in members(state):
   if row.active and _shift(row.context,target):free=false
  if free:view.next_full_day=target;break
 return view

static func guard_writing(state: Dictionary) -> Dictionary:
 var view: Dictionary=inspect_writing(state)
 if not view.ok:return view
 if not view.can_write:return _fail(str(view.message))
 return {"ok":true,"message":""}

static func inspect_rehearsal(state: Dictionary) -> Dictionary:
 var checked: Dictionary=validate(state)
 if not checked.ok:return checked
 var day: int=int(state.tour_day)
 var attendees: Array=[]
 var absent: Array=[]
 for row in members(state):
  if not row.active:continue
  if _shift(row.context,day):
   var words: PackedStringArray=[]
   for reason in commitment_reasons(row.context,day):words.append(reason.label)
   absent.append({"id":row.id,"index":row.index,"name":row.name,"reason":" + ".join(words)})
  else:attendees.append(row.index)
 var plan: Dictionary={}
 for item in checked.core.plans:
  if item.status=="planned":
   if plan.is_empty() or int(item.day)<int(plan.day):plan=item.duplicate(true)
 var status: String="none" if plan.is_empty() else ("missed" if int(plan.day)<day else ("due" if int(plan.day)==day else "future"))
 return {"ok":true,"day":day,"conflict":not absent.is_empty(),"attendee_indices":attendees,"absent":absent,"plan":plan,"plan_status":status,"fingerprint":JSON.stringify(state).sha256_text(),"core_revision":int(checked.core.revision)}

static func reschedule(state: Dictionary, expected: Dictionary = {}) -> Dictionary:
 var commitment: Dictionary=Booking.guard_commitment(state,"recorded_context",0)
 if not bool(commitment.get("ok",false)):return _fail(str(commitment["message"]))
 var inspected: Dictionary=inspect_rehearsal(state)
 if not inspected.ok:return inspected
 if not _compare(state,expected):return _fail("The band changed. Review this rehearsal again.")
 if not inspected.conflict:return _fail("There is no recorded work clash to reschedule.")
 if inspected.plan_status in ["future","due"]:return _fail("There is already a saved rehearsal plan. Keep or miss that agreement before making another.")
 var day: int=int(state.tour_day)
 var target: int=0
 for offset in range(1,15):
  if day>MAX_NUMBER-offset:break
  var candidate: int=day+offset
  var possible: bool=true
  for row in members(state):
   if row.active and _shift(row.context,candidate):possible=false
  if possible:target=candidate;break
 if target==0:return _fail("No common free evening was found in the next fortnight. Review the recorded schedules.")
 var core: Dictionary=validate(state).core
 _mark_missed(core,day)
 if int(core.sequence)>=MAX_NUMBER:return _fail("The situation history has reached its supported limit.")
 core.sequence=int(core.sequence)+1
 var ids: Array=[]
 for row in members(state):
  if row.active and not row.id.is_empty():ids.append(row.id)
 var plan: Dictionary={"id":"rehearsal-plan:%d" % int(core.sequence),"day":target,"window":"EVENING","source_day":day,"participant_ids":ids,"status":"planned"}
 core.plans.append(plan)
 var result: Dictionary=_put(state,core,"Rehearsal agreed for DAY %d EVENING. No day or room fee has been used." % target)
 if result.ok:result["plan"]=plan.duplicate(true)
 return result

static func _agreement(core: Dictionary, id: String) -> Dictionary:
 return core.agreements.get(id,{"excluded":0,"kept":0,"broken":0}).duplicate(true)

static func _mark_missed(core: Dictionary, day: int) -> void:
 for plan in core.plans:
  if plan.status=="planned" and int(plan.day)<day:
   plan.status="missed"
   for id in plan.participant_ids:
    var item: Dictionary=_agreement(core,id)
    item.broken=mini(MAX_NUMBER,int(item.broken)+1)
    core.agreements[id]=item

static func after_action(before: Dictionary, after: Dictionary, attendance: Array = [], rehearsal: bool = false) -> Dictionary:
 var checked: Dictionary=validate(before)
 if not checked.ok:return checked
 if not checked.exists:return {"ok":true,"state":after.duplicate(true),"message":""}
 var core: Dictionary=checked.core
 var next: Dictionary=after.duplicate(true)
 var previous_core: Dictionary=core.duplicate(true)
 if not rehearsal:
  _mark_missed(core,int(next.get("tour_day",before.tour_day)))
  if exact(core,previous_core):return {"ok":true,"state":next,"message":""}
  return _put(next,core,"")
 var key: String="practice:tighten:%d" % int(next.get("action_count",0))
 if core.processed.has(key):return _fail("That rehearsal has already been recorded.")
 var attending_ids: Array=[]
 var absent_ids: Array=[]
 var names: Array=[]
 var emotional: Array=[]
 var kept_plan: String=""
 var old_day: int=int(before.tour_day)
 var actual_ids: Array=[]
 for index in attendance:
  actual_ids.append(_identity(before.members[index]))
 for plan in core.plans:
  var everyone: bool=true
  for id in plan.participant_ids:
   if not actual_ids.has(id):everyone=false
  if int(plan.day)==old_day and plan.status=="planned" and everyone:
   plan.status="fulfilled"
   kept_plan=str(plan.id)
   for id in plan.participant_ids:
    var item: Dictionary=_agreement(core,id)
    item.kept=mini(MAX_NUMBER,int(item.kept)+1)
    core.agreements[id]=item
 _mark_missed(core,int(next.tour_day))
 var booking: Variant=before.get("booked_show",{})
 var near: bool=booking is Dictionary and _integer(booking.get("day",null),1) and int(booking.day)>old_day and int(booking.day)<=old_day+2
 var active_count: int=0
 for row in members(before):
  if not row.active:continue
  active_count+=1
  if attendance.has(row.index):attending_ids.append(row.id);names.append(row.name)
  else:
   absent_ids.append(row.id)
   var history: Dictionary=_agreement(core,row.id)
   var repetitions: int=int(history.excluded)
   history.excluded=mini(MAX_NUMBER,repetitions+1)
   core.agreements[row.id]=history
   # Exclusion pressure follows recorded repeated exclusions/broken agreements;
   # a first understood work shift is not an automatic punishment.
   var pressure: int=mini(5,repetitions+int(history.broken))
   if pressure>0:
    var person: Dictionary=next.members[row.index]
    person["morale"]=clampi(int(person.get("morale",50))-pressure,0,100)
    person["loyalty"]=clampi(int(person.get("loyalty",60))-mini(2,pressure),0,100)
    emotional.append(row.name+" is feeling left out after earlier exclusions or missed agreements.")
 var message: String=""
 if not absent_ids.is_empty():
  if near and int(before.get("readiness",0))<60:
   next["tension"]=clampi(int(next.get("tension",0))+maxi(1,active_count-attendance.size()),0,100)
   emotional.append("The approaching show leaves little time to bring the missing players into the set.")
  message="Attended: "+", ".join(names)+". Recorded work or family commitments kept the other musicians away."
 elif not kept_plan.is_empty():message="The band kept its agreed evening rehearsal."
 if not emotional.is_empty():message+=" "+" ".join(emotional)
 var record: Dictionary={"id":key,"day":old_day,"completed_day":int(next.tour_day),"window":"EVENING","attendee_ids":attending_ids,"absent_ids":absent_ids,"plan_id":kept_plan,"message":message,"policy_version":1}
 core.attendance_history.append(record)
 core.processed[key]=true
 var result: Dictionary=_put(next,core,message)
 if result.ok:result["attendance"]=record.duplicate(true)
 return result
