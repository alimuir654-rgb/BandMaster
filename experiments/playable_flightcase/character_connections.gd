extends RefCounted
## Optional player-to-musician memory. Does not change authored cast or pair bonds.
const KEY="character_connections_v1"
const TALK="band_conversation_v1"
const QUESTIONS={"working_style":["shared","direct"],"commitment":["dates","regular"]}
const TITLES={"working_style":"WHAT SORT OF BAND ARE WE BUILDING?","commitment":"HOW WILL WE MAKE TIME FOR IT?"}
const LABELS={"shared":"BUILD IT TOGETHER","direct":"I'LL SET THE DIRECTION","dates":"AGREE DATES TOGETHER","regular":"MAKE IT A REGULAR THING"}
const IDS=["cast_jack","cast_arjun","cast_zoe","cast_marcus"]

static func whole(value: Variant,minimum: int=0,maximum: int=1000000000) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=minimum and value<=maximum
static func conversation_valid(raw: Variant) -> bool:
 if not raw is Dictionary or not whole(raw.get("version"),1,1) or not raw.get("answers") is Dictionary or not whole(raw.get("revision"),0,2):return false
 if raw.answers.size()!=int(raw.revision):return false
 for key in raw.answers:
  if not key is String or not QUESTIONS.has(key) or raw.answers[key] not in QUESTIONS[key]:return false
 return true
static func valid(state: Dictionary) -> bool:
 if not state.has(KEY):return true
 var raw: Variant=state[KEY]
 if not raw is Dictionary or not whole(raw.get("version"),1,1) or not raw.get("records") is Dictionary or raw.records.size()>IDS.size():return false
 for id in raw.records:
  var row: Variant=raw.records[id]
  if id not in IDS or not row is Dictionary or row.get("candidate_id")!=id or not row.get("audition_id") is String:return false
  var source: PackedStringArray=str(row.audition_id).split(":")
  if source.size()!=3 or source[0]!="audition" or not source[1].is_valid_int() or not whole(int(source[1]),1) or source[2]!=id:return false
  if not whole(row.get("rapport"),-20,20) or not whole(row.get("practices")):return false
  if not conversation_valid(row.get("conversation")) or row.get("request") not in ["space_for_voice","own_part"]:return false
 return true
static func reply(id: String,question: String,choice: String) -> String:
 var own: bool=id in ["cast_arjun","cast_marcus"]
 if question=="working_style":
  if choice=="shared":return "Let me bring something in, then. We can see what fits together." if own else "Good. I want to hear what everyone else is doing before I fill the gaps."
  return "Give me a clear starting point. I'll still need room to try an idea." if own else "I can work with a clear direction. Tell me when something isn't sitting right."
 if choice=="dates":return "Let's agree the evenings before we commit. I want to be there when we say we will."
 return "I'd like a rhythm to it. Let's agree an evening we can actually keep."
static func project(snapshot: Dictionary,state: Dictionary) -> Dictionary:
 if not valid(state):return {"ok":false,"message":"The saved musician connections need a compatible version."}
 var next: Dictionary=state.duplicate(true)
 var records: Dictionary=next.get(KEY,{}).get("records",{}).duplicate(true)
 var wrapper: Dictionary=snapshot.get("audition_encounter_v1",{})
 var history: Dictionary=wrapper.get("heard_by_candidate",{})
 for member in next.get("members",[]):
  var id: String=str(member.get("candidate_id",""))
  var receipt: Dictionary=history.get(id,{})
  if receipt.get("result")!="invited" or not receipt.has(TALK):continue
  if not conversation_valid(receipt[TALK]):return {"ok":false,"message":"The saved audition conversation needs review."}
  if records.has(id):continue
  records[id]={"candidate_id":id,"audition_id":str(receipt.id),"conversation":receipt[TALK].duplicate(true),"request":str(receipt.request),"rapport":0,"practices":0}
 if not records.is_empty():
  var wrapper_copy: Dictionary=next.get(KEY,{"version":1,"records":{}}).duplicate(true)
  wrapper_copy["records"]=records;next[KEY]=wrapper_copy
 return {"ok":true,"state":next}
static func memories(state: Dictionary) -> Array:
 var rows: Array=[]
 if not valid(state):return rows
 for member in state.get("members",[]):
  var id: String=str(member.get("candidate_id",""))
  var record: Dictionary=state.get(KEY,{}).get("records",{}).get(id,{})
  if record.is_empty():continue
  var answers: Dictionary=record.conversation.answers
  var text: String=""
  if answers.get("working_style")=="shared":text="You said we'd build this together. Leave room for us to listen."
  elif answers.get("working_style")=="direct":text="You said you'd set the direction. Tell us what we're working on."
  if answers.get("commitment")=="dates":text+=" Let's agree our next evening before we leave."
  elif answers.get("commitment")=="regular":text+=" Let's keep the rehearsal habit going."
  if not text.is_empty():rows.append({"candidate_id":id,"name":str(member.get("name","Bandmate")),"text":text})
 return rows
