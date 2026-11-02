extends RefCounted
## One original pair case, with pure accounting and saved factual presentation.
const Drama = preload("res://Scripts/band_drama.gd")
const Story = preload("res://Scripts/career_story.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Life = preload("res://Scripts/member_life.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Radio = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const KEY := "band_moment_receipt_v1"
const KIND := "rehearsal_resentment"
const MAXIMUM := 2147483647
const GLOBALS := ["morale","tension","readiness","reputation"]
const MEMBER_VALUES := ["loyalty","morale","fatigue"]

static func _whole(value: Variant, low: int=0, high: int=MAXIMUM) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=float(low) and float(value)<=float(high)

static func _bad(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func validate(state: Dictionary) -> Dictionary:
 for field in ["cash","songs","fans"]:
  if state.has(field) and not _whole(state[field]):return _bad("The saved "+field+" value needs validation before this conversation.")
 if state.has("tour_day") and not _whole(state["tour_day"],1):return _bad("The saved career day needs validation.")
 for field in ["morale","tension","readiness","reputation","press","van_health"]:
  if state.has(field) and not _whole(state[field],0,100):return _bad("The saved "+field+" value needs validation.")
 for field in ["relationships","band_drama_resolved"]:
  if state.has(field) and not state[field] is Dictionary:return _bad("The saved band relationships need validation.")
 for field in ["members","song_catalogue","career_journal"]:
  if state.has(field) and not state[field] is Array:return _bad("The saved "+field.replace("_"," ")+" cannot be read safely.")
 var members: Array=state.get("members",[])
 for person in members:
  if not person is Dictionary:continue
  for field in ["candidate_id","name","role"]:
   if person.has(field) and not person[field] is String:return _bad("A saved bandmate identity needs validation.")
  if person.has("id") and not person["id"] is String and not _whole(person["id"],-MAXIMUM,MAXIMUM):return _bad("A saved bandmate identifier needs validation.")
  for field in ["fatigue","loyalty","morale"]:
   if person.has(field) and not _whole(person[field],0,100):return _bad("A saved bandmate's "+field+" needs validation.")
  if person.has("available_day") and not _whole(person["available_day"]):return _bad("A saved member return date needs validation.")
 var relationships: Dictionary=state.get("relationships",{})
 var active_identities: Dictionary={}
 for index in range(members.size()):
  if not members[index] is Dictionary or str(members[index].get("life_status","active"))!="active":continue
  var identity: String=Drama._identity(members[index],index)
  if active_identities.has(identity):return _bad("Two active bandmates share the same identity. This conversation has been held.")
  active_identities[identity]=true
 for i in range(members.size()):
  if not members[i] is Dictionary or str(members[i].get("life_status","active"))!="active":continue
  for j in range(i+1,members.size()):
   if not members[j] is Dictionary or str(members[j].get("life_status","active"))!="active":continue
   var value: Variant=relationships.get("%d_%d" % [i,j],relationships.get("%d_%d" % [j,i],50))
   if not _whole(value,-MAXIMUM,MAXIMUM):return _bad("A saved relationship needs validation.")
 if state.has("booked_show"):
  if not state["booked_show"] is Dictionary:return _bad("The saved show booking needs validation.")
  if not state["booked_show"].is_empty() and not _whole(state["booked_show"].get("day"),1):return _bad("The saved show date needs validation.")
 if state.has(Finance.KEY):
  var finance: Variant=state[Finance.KEY]
  if not finance is Dictionary:return _bad("The saved finance checkpoint needs validation.")
  for field in ["version","opening_balance","opening_day","accounted_day","closing_balance","seq","broke_days","ended_day"]:
   if finance.has(field) and not _whole(finance[field]):return _bad("A saved finance counter needs validation.")
 return {"ok":true,"message":""}

static func _typed(value: Variant) -> Variant:
 if value is Dictionary:
  var keys: Array=value.keys()
  keys.sort()
  var rows: Array=[]
  for key in keys:rows.append([_typed(key),_typed(value[key])])
  return [TYPE_DICTIONARY,rows]
 if value is Array:
  var rows: Array=[]
  for item in value:rows.append(_typed(item))
  return [TYPE_ARRAY,rows]
 return [typeof(value),value]

static func _person(person: Dictionary, index: int) -> Dictionary:
 var source: Dictionary={}
 for field in ["candidate_id","id","name","role"]:
  if person.has(field):source[field]=person[field]
 return {"index":index,"identity_key":Drama._identity(person,index),"identity_source":source,"candidate_id":str(person.get("candidate_id","")),"name":str(person.get("name","Musician")),"role":str(person.get("role",""))}

static func current(state: Dictionary) -> Dictionary:
 var result: Dictionary={"ok":true,"available":false,"message":"No rehearsal conversation is waiting right now.","case":{},"fingerprint":"","participants":[]}
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):
  result["ok"]=false
  result["message"]=valid["message"]
  return result
 var pending: Array=Drama.pair_pending(state)
 if pending.is_empty() or str(pending[0].get("kind",""))!=KIND:return result
 var incident: Dictionary=pending[0].duplicate(true)
 var members: Array=state.get("members",[])
 var people: Array=[]
 for field in ["first_index","second_index"]:
  var index: int=int(incident[field])
  if not members[index].get("name") is String or str(members[index]["name"]).strip_edges().is_empty():
   result["ok"]=false
   result["message"]="A selected bandmate's actual name is missing. This conversation has been held."
   return result
  people.append(_person(members[index],index))
 result["available"]=true
 result["message"]=""
 result["case"]=incident
 result["participants"]=people
 result["fingerprint"]=JSON.stringify(_typed({"case":incident,"participants":people})).sha256_text()
 return result

static func _fail(state: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"state":state.duplicate(true),"message":message,"case":{},"receipt":{},"moment":{},"journal_index":-1,"settled":false}

static func _global_values(state: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for field in GLOBALS:result[field]=int(state.get(field,0 if field=="reputation" else 50))
 return result

static func preview(state: Dictionary, case_id: String, choice_id: String, expected_fingerprint: String) -> Dictionary:
 return resolve(state,case_id,choice_id,expected_fingerprint)

static func resolve(state: Dictionary, case_id: String, choice_id: String, expected_fingerprint: String) -> Dictionary:
 var selected: Dictionary=current(state)
 if not bool(selected["ok"]):return _fail(state,str(selected["message"]))
 if not bool(selected["available"]) or str(selected["case"]["id"])!=case_id or expected_fingerprint.is_empty() or selected["fingerprint"]!=expected_fingerprint:return _fail(state,"This band conversation changed. Open the current case again.")
 var guard: Dictionary=Finance.guard(state)
 if not bool(guard.get("ok",false)):return _fail(state,str(guard.get("message","The band has closed.")))
 if Radio.locked(state):return _fail(state,"Resume or cancel the unfinished radio visit first.")
 var booking: Dictionary=Calendar.pending(state)
 if not booking.is_empty() and int(booking["day"])<=int(state.get("tour_day",1)):return _fail(state,"The booked show comes first. Open the live desk before this conversation.")
 if int(state.get("tour_day",1))>=MAXIMUM:return _fail(state,"This conversation would exceed the supported career-day range.")
 var original: Dictionary=Drama.resolve_pair(state,case_id,choice_id)
 if not bool(original.get("ok",false)):return _fail(state,str(original.get("message","This intervention is unavailable.")))
 var after: Dictionary=Life.refresh(Calendar.expire(Story.observe(state,original["state"],"band:pair")))
 var accounted: Dictionary=Finance.apply(state,after,"band:pair",[],[int(after.get("cash",0))])
 if not bool(accounted.get("ok",false)):return _fail(state,str(accounted.get("message","The day's accounts could not be reconciled.")))
 after=accounted["state"]
 var journal: Array=after.get("career_journal",[])
 var index: int=-1
 for i in range(journal.size()-1,-1,-1):
  if journal[i] is Dictionary and str(journal[i].get("id",""))==case_id and journal[i].get("choice_id")==choice_id and int(journal[i].get("day",0))==int(after.get("tour_day",1)):
   index=i
   break
 if index<0:return _fail(state,"The new saved conversation could not be identified safely.")
 var moment: Dictionary=journal[index]
 var people: Array=[]
 var before_members: Array=state.get("members",[])
 var after_members: Array=after.get("members",[])
 for binding in selected["participants"]:
  var row: Dictionary=binding.duplicate(true)
  var member_index: int=int(row["index"])
  row["before"]={}
  row["after"]={}
  row["recorded_before"]={}
  for field in MEMBER_VALUES:
   row["before"][field]=int(before_members[member_index].get(field,0 if field=="fatigue" else 50))
   row["after"][field]=int(after_members[member_index].get(field,0 if field=="fatigue" else 50))
   row["recorded_before"][field]=before_members[member_index].has(field)
  people.append(row)
 var pair: Dictionary=selected["case"]
 var i: int=int(pair["first_index"])
 var j: int=int(pair["second_index"])
 var relationships: Dictionary=state.get("relationships",{})
 var saved: Dictionary={"version":1,"content_version":1,"case_id":case_id,"case_kind":KIND,"choice_id":choice_id,"case_fingerprint":expected_fingerprint,"day_before":int(state.get("tour_day",1)),"day_after":int(after.get("tour_day",1)),"cash_before":int(state.get("cash",0)),"cash_after":int(after.get("cash",0)),"global_before":_global_values(state),"global_after":_global_values(after),"participants":people,"trust_before":int(moment["trust_before"]),"trust_after":int(moment["trust_after"]),"trust_recorded_before":relationships.has("%d_%d" % [i,j]) or relationships.has("%d_%d" % [j,i]),"message":str(original.get("message","Saved."))}
 moment[KEY]=saved.duplicate(true)
 var checked: Dictionary=receipt(moment)
 if not bool(checked["ok"]):return _fail(state,"The new conversation receipt could not be validated. The band is unchanged.")
 return {"ok":true,"state":after,"message":saved["message"],"case":pair.duplicate(true),"receipt":saved.duplicate(true),"moment":moment.duplicate(true),"journal_index":index,"settled":true}

static func receipt(entry: Variant) -> Dictionary:
 var held: Dictionary={"ok":false,"legacy":false,"message":"This saved conversation needs validation.","receipt":{},"moment":entry.duplicate(true) if entry is Dictionary else {}}
 if not entry is Dictionary or not entry.get("id") is String or not str(entry["id"]).begins_with("pair:"+KIND+":") or entry.get("kind")!="band":return held
 for field in ["title","text","choice_id","decision_label","first_line","second_line"]:
  if entry.has(field) and not entry[field] is String:return held
 if entry.has("pair_names"):
  var names: Variant=entry["pair_names"]
  if not names is Array or names.size()!=2:return held
  for name in names:
   if not name is String or str(name).strip_edges().is_empty():return held
 for field in ["day","trust_before","trust_after"]:
  if entry.has(field) and not _whole(entry[field],1 if field=="day" else 0,MAXIMUM if field=="day" else 100):return held
 if not entry.has(KEY):return {"ok":true,"legacy":true,"message":"Only the original saved conversation facts are available.","receipt":{},"moment":entry.duplicate(true)}
 var saved: Variant=entry[KEY]
 if not saved is Dictionary:return held
 for field in ["version","content_version"]:
  if not _whole(saved.get(field),1,1):return held
 if saved.get("case_id")!=entry["id"] or saved.get("case_kind")!=KIND or saved.get("choice_id")!=entry.get("choice_id") or saved.get("choice_id") not in ["listen","keep"]:return held
 if not saved.get("case_fingerprint") is String or str(saved["case_fingerprint"]).length()!=64 or not saved.get("message") is String:return held
 for field in ["day_before","day_after","cash_before","cash_after","trust_before","trust_after"]:
  if not _whole(saved.get(field),1 if field.begins_with("day") else 0):return held
 if int(saved["day_after"])!=int(saved["day_before"])+1 or saved["cash_before"]!=saved["cash_after"] or saved["day_after"]!=entry.get("day") or saved["trust_before"]!=entry.get("trust_before") or saved["trust_after"]!=entry.get("trust_after") or not saved.get("trust_recorded_before") is bool:return held
 for side in ["global_before","global_after"]:
  if not saved.get(side) is Dictionary:return held
  for field in GLOBALS:
   if not _whole(saved[side].get(field),0,100):return held
 var people: Variant=saved.get("participants")
 if not people is Array or people.size()!=2:return held
 var identities: Array=[]
 var indices: Array=[]
 for person in people:
  if not person is Dictionary or not _whole(person.get("index")) or not person.get("identity_key") is String or str(person["identity_key"]).is_empty():return held
  for field in ["candidate_id","name","role"]:
   if not person.get(field) is String:return held
  if str(person["name"]).strip_edges().is_empty():return held
  var source: Variant=person.get("identity_source")
  if not source is Dictionary:return held
  for field in ["candidate_id","name","role"]:
   if source.has(field) and not source[field] is String:return held
  if source.has("id") and not source["id"] is String and not _whole(source["id"],-MAXIMUM,MAXIMUM):return held
  if str(source.get("candidate_id",""))!=person["candidate_id"] or str(source.get("name","Musician"))!=person["name"] or str(source.get("role",""))!=person["role"] or Drama._identity(source,int(person["index"]))!=person["identity_key"]:return held
  if not source.get("name") is String or str(source["name"]).strip_edges().is_empty():return held
  if identities.has(person["identity_key"]) or indices.has(person["index"]):return held
  identities.append(person["identity_key"])
  indices.append(person["index"])
  for side in ["before","after","recorded_before"]:
   if not person.get(side) is Dictionary:return held
   for field in MEMBER_VALUES:
    if side=="recorded_before":
     if not person[side].get(field) is bool:return held
    elif not _whole(person[side].get(field),0,100):return held
 identities.sort()
 if saved["case_id"]!="pair:"+KIND+":"+str(identities[0])+"|"+str(identities[1]):return held
 if entry.get("pair_names")!=[people[0]["name"],people[1]["name"]] or entry.get("pair")!="%d_%d" % [mini(int(indices[0]),int(indices[1])),maxi(int(indices[0]),int(indices[1]))]:return held
 return {"ok":true,"legacy":false,"message":"","receipt":saved.duplicate(true),"moment":entry.duplicate(true)}

static func latest(state: Dictionary) -> Dictionary:
 var history: Variant=state.get("career_journal",[])
 if not history is Array:return {"ok":false,"legacy":false,"message":"The saved band journal needs validation.","receipt":{},"moment":{}}
 for index in range(history.size()-1,-1,-1):
  if history[index] is Dictionary and str(history[index].get("id","")).begins_with("pair:"+KIND+":"):return receipt(history[index])
 return {"ok":true,"legacy":false,"message":"No saved rehearsal conversation yet.","receipt":{},"moment":{}}
