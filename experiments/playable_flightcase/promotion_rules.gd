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

static func launch(state: Dictionary, id: String, expected_fingerprint: String, expected_index: int=-1) -> Dictionary:
 var selected: Dictionary=selection(state,id,expected_fingerprint,expected_index)
 if not bool(selected.get("ok",false)):return _fail(state,str(selected.get("message","Choose a demo.")))
 if bool(selected["completed"]):return _fail(state,"This demo's local-radio campaign is already complete. Read its saved notes freely.")
 var guard: Dictionary=Finance.guard(state)
 if not bool(guard.get("ok",false)):return _fail(state,str(guard.get("message","The band cannot commit another day.")))
 var booking: Dictionary=Calendar.pending(state)
 if not booking.is_empty() and int(booking["day"])==int(state.get("tour_day",1)):return _fail(state,"Tonight's show comes first. Finish or cancel it before pitching radio.")
 var index: int=int(selected["index"])
 var original: Dictionary=Original.launch(state,index,"radio")
 if not bool(original.get("ok",false)):return _fail(state,str(original.get("message","This radio pitch is unavailable.")))
 var after: Dictionary=Life.refresh(Calendar.expire(Story.observe(state,original["state"],"campaign")))
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
 var message: String=str(original.get("message","Local-radio campaign complete."))
 for change in postchain:message+="\n"+str(change["text"])
 var receipt: Dictionary={"version":1,"demo_id":str(selected["id"]),"session_index":index,"source_fingerprint":expected_fingerprint,"message":message,"before":_metrics(state),"after":_metrics(after),"postchain_changes":postchain.duplicate(true)}
 var session: Dictionary=after["recordings"][index]
 var campaigns: Dictionary=session["campaigns"]
 var radio: Dictionary=campaigns["radio"]
 radio[RECEIPT_KEY]=receipt.duplicate(true)
 return {"ok":true,"state":after,"message":message,"session":session.duplicate(true),"demo_id":str(selected["id"]),"session_index":index,"closing_balances":[int(after["cash"])],"finance_action":"promotion:radio","receipt":receipt.duplicate(true)}
