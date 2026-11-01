extends RefCounted
## ONE original local-radio campaign. Pure copied state: no files or UI.
const Recording = preload("res://experiments/playable_flightcase/recording_rules.gd")
const Original = preload("res://Scripts/release_campaigns.gd")
const Story = preload("res://Scripts/career_story.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Life = preload("res://Scripts/member_life.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const RECEIPT_KEY := "receipt_v1"
const METRICS := ["cash","tour_day","fans","press","buzz","reputation","morale"]
const VISIT_KEY := "radio_visit_v1"
const QUESTIONS := {
 "focus":{"text":"What should listeners remember about this record?","choices":{"craft":{"text":"The songwriting and the details in our songs.","hint":"Emphasise craft: more press, less buzz.","fans":0,"press":3,"buzz":-2},"live_energy":{"text":"The energy we want our band to carry.","hint":"Emphasise energy: more buzz, less press.","fans":0,"press":-2,"buzz":3}}},
 "invitation":{"text":"What would you ask a new listener to do next?","choices":{"invite":{"text":"Bring a friend and give our band a listen.","hint":"A wider invitation: more fans, less press.","fans":2,"press":-2,"buzz":0},"critical_craft":{"text":"Listen closely and judge the craft of the record.","hint":"A closer listen: more press, fewer fans.","fans":-1,"press":2,"buzz":0}}}
}

static func visit_locked(state: Dictionary) -> bool:
 if not state.has(VISIT_KEY):return false
 var wrapper: Variant=state[VISIT_KEY]
 if not wrapper is Dictionary or not _whole(wrapper.get("version",0),1) or int(wrapper["version"])!=1 or not _whole(wrapper.get("seq",-1)) or not wrapper.get("active") is Dictionary:return true
 return not (wrapper["active"] as Dictionary).is_empty()

static func _interview(state: Dictionary, id: String, fingerprint: String, index: int, context: Dictionary) -> Dictionary:
 if not visit_locked(state) or context.is_empty():return _bad("Resume or cancel the active radio visit before another commitment.")
 var wrapper: Variant=state.get(VISIT_KEY)
 if not wrapper is Dictionary or not _whole(wrapper.get("version",0),1) or int(wrapper["version"])!=1 or not _whole(wrapper.get("seq",-1),1):return _bad("The saved radio visit needs validation.")
 var visit: Variant=wrapper.get("active")
 if not visit is Dictionary:return _bad("The saved radio visit needs validation.")
 if visit.get("id")!=context.get("visit_id") or visit.get("phase")!="wrap_ready" or not _whole(visit.get("revision",-1)) or int(visit["revision"])!=6 or visit["revision"]!=context.get("expected_revision"):return _bad("This radio visit changed. Resume its current phase.")
 if visit.get("id")!="radio-visit:%d:%s" % [int(wrapper["seq"]),fingerprint.left(12)] or visit.get("demo_id")!=id or visit.get("source_fingerprint")!=fingerprint or visit.get("demo_index")!=index:return _bad("The radio visit no longer identifies this exact demo.")
 for key in ["policy_version","content_version"]:
  if not _whole(visit.get(key,0),1) or int(visit[key])!=1:return _bad("This radio visit uses an unsupported policy or question version.")
 if visit.get("presenter_id")!="student_presenter_v1" or visit.get("question_ids")!=["focus","invitation"]:return _bad("This radio visit's questions need validation.")
 if not _whole(visit.get("started_day",0),1) or not _whole(visit.get("started_cash",-1)) or int(visit["started_day"])!=int(state.get("tour_day",1)) or int(visit["started_cash"])!=int(state.get("cash",0)):return _bad("The band's day or cash changed during this visit. Cancel it before making another commitment.")
 var answers: Variant=visit.get("answers")
 if not answers is Dictionary:return _bad("The saved interview answers need validation.")
 var vector: Dictionary={"fans":0,"press":0,"buzz":0}
 var transcript: Array=[]
 for question_id in ["focus","invitation"]:
  var choices: Dictionary=QUESTIONS[question_id]["choices"]
  var answer_id: Variant=answers.get(question_id)
  if not answer_id is String or not choices.has(answer_id):return _bad("Finish both radio questions before wrapping up.")
  var choice: Dictionary=choices[answer_id]
  for field in vector:vector[field]+=int(choice[field])
  transcript.append({"question_id":question_id,"question":QUESTIONS[question_id]["text"],"answer_id":answer_id,"answer":choice["text"],"hint":choice["hint"]})
 return {"ok":true,"vector":vector,"transcript":{"version":1,"visit_id":visit["id"],"presenter_id":visit["presenter_id"],"policy_version":1,"content_version":1,"source_fingerprint":fingerprint,"questions":transcript,"combined_vector":vector.duplicate(true)}}

static func _whole(value: Variant, minimum: int=0) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=float(minimum) and float(value)<=2147483647.0

static func _bad(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func _fail(state: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"state":state.duplicate(true),"message":message,"session":{},"demo_id":"","session_index":-1,"closing_balances":[],"finance_action":"","receipt":{}}

static func validate(state: Dictionary) -> Dictionary:
 var valid: Dictionary=Recording.validate(state)
 if not bool(valid.get("ok",false)):return valid
 if state.has(Finance.KEY):
  var finance: Variant=state[Finance.KEY]
  if not finance is Dictionary:return _bad("The saved finance metadata needs validation.")
  for field in ["version","opening_balance","opening_day","accounted_day","broke_days","seq","closing_balance","ended_day"]:
   if finance.has(field) and not _whole(finance[field]):return _bad("A saved finance counter needs validation before a radio pitch.")
  var totals: Variant=finance.get("totals",{})
  if totals is Dictionary:
   var outgoing: Variant=totals.get("outgoing",{})
   if outgoing is Dictionary and outgoing.has("Other") and not _whole(outgoing["Other"]):return _bad("The saved outgoing accounts need validation before a radio pitch.")
 for field in ["songs","van_health","tension","reputation","morale"]:
  if state.has(field) and not _whole(state[field]):return _bad("The saved "+field+" value needs validation before a radio pitch.")
 if state.has("members"):
  if not state["members"] is Array:return _bad("The saved band members cannot be read safely.")
  for person in state["members"]:
   if not person is Dictionary:return _bad("A saved band member cannot be read safely.")
   if person.has("life_status") and not person["life_status"] is String:return _bad("A saved member availability needs validation.")
   if person.has("available_day") and not _whole(person["available_day"]):return _bad("A saved member return date needs validation.")
 if state.has("booked_show"):
  if not state["booked_show"] is Dictionary:return _bad("The saved show booking cannot be read safely.")
  var booking: Dictionary=state["booked_show"]
  if not booking.is_empty() and not _whole(booking.get("day",null),1):return _bad("The pending show date needs validation before a radio pitch.")
 for session in state.get("recordings",[]):
  if session.has("campaigns") and not session["campaigns"] is Dictionary:return _bad("The saved demo campaigns cannot be read safely.")
 return {"ok":true,"message":""}

static func _saved_response(session: Dictionary) -> Dictionary:
 var campaigns: Dictionary=session.get("campaigns",{})
 var radio: Variant=campaigns.get("radio")
 if not radio is Dictionary:return {}
 var saved: Variant=radio.get(RECEIPT_KEY)
 if not saved is Dictionary or not _whole(saved.get("version",0),1) or int(saved["version"])!=1:return {}
 if not saved.get("demo_id") is String or saved["demo_id"]!=str(session.get("id","")) or not saved.get("message") is String or not saved.get("source_fingerprint") is String:return {}
 if str(saved["source_fingerprint"]).length()!=64 or not _whole(saved.get("session_index",-1)):return {}
 for side in ["before","after"]:
  if not saved.get(side) is Dictionary:return {}
  for metric in METRICS:
   if not _whole(saved[side].get(metric,null),1 if metric=="tour_day" else 0):return {}
 if not saved.get("postchain_changes") is Array:return {}
 for row in saved["postchain_changes"]:
  if not row is Dictionary or not row.get("field") is String or not row.get("text") is String:return {}
 return saved.duplicate(true)

static func selection(state: Dictionary, id: String, expected_fingerprint: String, expected_index: int=-1) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid.get("ok",false)):return valid
 if expected_fingerprint.is_empty():return _bad("Choose the exact saved demo again before a radio pitch.")
 var archive: Array=state.get("recordings",[])
 var index: int=-1
 if id.is_empty():
  if expected_index<0 or expected_index>=archive.size() or not str(archive[expected_index].get("id","")).is_empty():return _bad("Choose the exact unlinked legacy demo again.")
  index=expected_index
 else:
  for candidate in range(archive.size()):
   if str(archive[candidate].get("id",""))==id:
    if index>=0:return _bad("The selected demo identifier is ambiguous.")
    index=candidate
 if index<0:return _bad("Choose a saved released demo for local radio.")
 var session: Dictionary=archive[index]
 if Recording.fingerprint(session)!=expected_fingerprint:return _bad("This demo changed after selection. Review its saved details again.")
 if not bool(session.get("released",false)):return _bad("Release this recorded demo before pitching local radio.")
 var campaigns: Dictionary=session.get("campaigns",{})
 return {"ok":true,"message":"","session":session.duplicate(true),"index":index,"id":id,"completed":campaigns.has("radio"),"saved_response":_saved_response(session)}

static func _metrics(state: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for metric in METRICS:result[metric]=int(state.get(metric,1 if metric=="tour_day" else 0))
 return result

static func preview(state: Dictionary, id: String, expected_fingerprint: String, expected_index: int=-1) -> Dictionary:
 return launch(state,id,expected_fingerprint,expected_index)

static func launch(state: Dictionary, id: String, expected_fingerprint: String, expected_index: int=-1, interview: Dictionary={}) -> Dictionary:
 var safe: Dictionary=validate(state)
 if not bool(safe.get("ok",false)):return _fail(state,str(safe.get("message","The saved campaign state needs validation.")))
 if not interview.is_empty() and int(state.get("tour_day",1))>=2147483647:return _fail(state,"The radio visit would exceed the supported career-day range.")
 var interview_policy: Dictionary={}
 if visit_locked(state) or not interview.is_empty():
  interview_policy=_interview(state,id,expected_fingerprint,expected_index,interview)
  if not bool(interview_policy.get("ok",false)):return _fail(state,str(interview_policy.get("message","Resume the radio visit.")))
 var selected: Dictionary=selection(state,id,expected_fingerprint,expected_index)
 if not bool(selected.get("ok",false)):return _fail(state,str(selected.get("message","Choose a demo.")))
 if not interview_policy.is_empty() and int(selected["index"])!=expected_index:return _fail(state,"The recording moved within the archive during this visit. Cancel the unfinished visit before selecting it again.")
 if bool(selected["completed"]):return _fail(state,"This demo's local-radio campaign is already complete. Read its saved notes freely.")
 var guard: Dictionary=Finance.guard(state)
 if not bool(guard.get("ok",false)):return _fail(state,str(guard.get("message","The band cannot commit another day.")))
 var booking: Dictionary=Calendar.pending(state)
 if not booking.is_empty() and int(booking["day"])==int(state.get("tour_day",1)):return _fail(state,"Tonight's show comes first. Finish or cancel it before pitching radio.")
 var index: int=int(selected["index"])
 var original: Dictionary=Original.launch(state,index,"radio")
 if not bool(original.get("ok",false)):return _fail(state,str(original.get("message","This radio pitch is unavailable.")))
 var raw: Dictionary=original["state"]
 if not interview_policy.is_empty():
  var vector: Dictionary=interview_policy["vector"]
  var fans: int=int(raw.get("fans",0))+int(vector["fans"])
  if fans<0 or fans>2147483647:return _fail(state,"The interview outcome exceeds the supported audience range.")
  raw["fans"]=fans
  raw["press"]=clampi(int(raw.get("press",0))+int(vector["press"]),0,100)
  raw["buzz"]=clampi(int(raw.get("buzz",0))+int(vector["buzz"]),0,100)
  raw["recordings"][index]["campaigns"]["radio"]["fans"]=fans-int(state.get("fans",0))
  var journal: Array=raw.get("career_journal",[])
  if not journal.is_empty():
   var fresh: Dictionary=journal[journal.size()-1]
   fresh["text"]="The band discussed its released demo with the student-radio presenter. %d new listeners found the band." % (fans-int(state.get("fans",0)))
 var after: Dictionary=Life.refresh(Calendar.expire(Story.observe(state,raw,"campaign")))
 var postchain: Array=[]
 for field in ["reputation","morale"]:
  if int(state.get(field,0))!=int(after.get(field,0)):
   postchain.append({"field":field,"before":int(state.get(field,0)),"after":int(after.get(field,0)),"text":"%s %d → %d" % [field.to_upper(),int(state.get(field,0)),int(after.get(field,0))]})
 if not booking.is_empty() and Calendar.pending(after).is_empty():
  postchain.append({"field":"booking","text":"The overdue show expired under the existing calendar rules."})
 var before_members: Array=state.get("members",[])
 var after_members: Array=after.get("members",[])
 for member in range(mini(before_members.size(),after_members.size())):
  if str(before_members[member].get("life_status","active"))!=str(after_members[member].get("life_status","active")):
   postchain.append({"field":"member_availability","text":str(after_members[member].get("name","A bandmate"))+" returned to active availability."})
 var accounted: Dictionary=Finance.apply(state,after,"promotion:radio",[{"direction":"outgoing","category":"Other","amount":20}],[int(after["cash"])])
 if not bool(accounted.get("ok",false)):return _fail(state,str(accounted.get("message","The radio accounts could not be reconciled.")))
 after=accounted["state"]
 var message: String="The local-radio campaign brought %d new listeners to the band. Press +%d; buzz +%d." % [int(after.get("fans",0))-int(state.get("fans",0)),int(after.get("press",0))-int(state.get("press",0)),int(after.get("buzz",0))-int(state.get("buzz",0))]
 if not interview_policy.is_empty():message="The student-radio visit brought %d new listeners to the band. Press %+d; buzz %+d." % [int(after.get("fans",0))-int(state.get("fans",0)),int(after.get("press",0))-int(state.get("press",0)),int(after.get("buzz",0))-int(state.get("buzz",0))]
 for change in postchain:message+="\n"+str(change["text"])
 var receipt: Dictionary={"version":1,"demo_id":str(selected["id"]),"session_index":index,"source_fingerprint":expected_fingerprint,"message":message,"before":_metrics(state),"after":_metrics(after),"postchain_changes":postchain.duplicate(true)}
 if not interview_policy.is_empty():receipt["interview_v1"]=interview_policy["transcript"].duplicate(true)
 var session: Dictionary=after["recordings"][index]
 var campaigns: Dictionary=session["campaigns"]
 var radio: Dictionary=campaigns["radio"]
 radio[RECEIPT_KEY]=receipt.duplicate(true)
 return {"ok":true,"state":after,"message":message,"session":session.duplicate(true),"demo_id":str(selected["id"]),"session_index":index,"closing_balances":[int(after["cash"])],"finance_action":"promotion:radio","receipt":receipt.duplicate(true)}
