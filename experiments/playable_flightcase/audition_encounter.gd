extends RefCounted
## Optional opening metadata. No owner/UI/save/Finance dependency.
const Connections=preload("res://experiments/playable_flightcase/character_connections.gd")
const Content = preload("res://experiments/playable_flightcase/audition_content.gd")
const Profiles = preload("res://experiments/playable_flightcase/audition_profiles.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Pricing=preload("res://experiments/playable_flightcase/recruitment_pricing.gd")
const KEY := "audition_encounter_v1"
const PHASES := ["arrival","tryout","response","decision"]
const LIMIT := 1000000000

static func _fail(message: String) -> Dictionary:
 return {"ok":false,"message":message,"changed":false}

static func _whole(value: Variant, minimum: int = 0, maximum: int = LIMIT) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=minimum and float(value)<=maximum

static func _canon(value: Variant) -> Variant:
 if value==null:return ["null"]
 if value is bool:return ["bool",value]
 if value is int:
  if value>9007199254740991 or value< -9007199254740991:return null
  if value>=1000000000 or value<= -1000000000:return ["float",var_to_bytes(float(value)).hex_encode()]
  return ["int",str(value)]
 if value is float:
  if not is_finite(value):return null
  if absf(value)<1000000000.0 and value==floor(value):return ["int",str(int(value))]
  return ["float",var_to_bytes(value).hex_encode()]
 if value is String or value is StringName:return ["string",str(value)]
 if value is Array:
  var entries: Array=[]
  for item in value:
   var entry: Variant=_canon(item)
   if entry==null:return null
   entries.append(entry)
  return ["array",entries]
 if value is Dictionary:
  var keys: Array=[]
  for key in value:
   if not (key is String or key is StringName) or keys.has(str(key)):return null
   keys.append(str(key))
  keys.sort()
  var entries: Array=[]
  for key in keys:
   var entry: Variant=_canon(value[key])
   if entry==null:return null
   entries.append([key,entry])
  return ["dictionary",entries]
 return null

static func _same(a: Variant,b: Variant) -> bool:
 var first: Variant=_canon(a)
 return first!=null and first==_canon(b)

static func _freeze_candidate(value: Variant) -> Variant:
 # Freeze new persisted candidate numbers through the established schema1
 # codec; leave the original Game/roster and its typed values untouched.
 if value is Dictionary:
  var result: Dictionary={}
  for key in value:result[str(key)]=_freeze_candidate(value[key])
  return result
 if value is Array:
  var result: Array=[]
  for item in value:result.append(_freeze_candidate(item))
  return result
 if value is float and is_finite(value) and absf(value)<1000000000.0 and value==floor(value):return int(value)
 return value

static func fingerprint(snapshot: Dictionary) -> String:
 var source:=snapshot.duplicate(true)
 source.erase(KEY)
 var canonical: Variant=_canon(source)
 return "" if canonical==null else JSON.stringify(canonical).sha256_text()

static func _budget_ok(snapshot: Dictionary) -> bool:
 if not snapshot.get("game") is Dictionary:return false
 var game: Dictionary=snapshot["game"]
 if not Pricing.valid(game.get(Pricing.KEY,"")):return false
 if not game.get("roster") is Array or game["roster"].size()>6:return false
 for person in game["roster"]:
  if not person is Dictionary or not person.get("id") is String or not person.get("roles") is Array:return false
  for key in ["vocal","instrument"]:
   if not person.get(key) is Array:return false
   for score in person[key]:
    if not _whole(score,0,100):return false
 var available:=_available(snapshot)
 return available>=0 and available<=Base.MAX_TALENT

static func _source_ok(snapshot: Dictionary) -> bool:
 if snapshot.get("screen")!="recruit" or not _budget_ok(snapshot):return false
 var game: Dictionary=snapshot["game"]
 return game.get("phase")=="recruit" and game.get("career") is Dictionary and Base.genres().has(game.get("genre")) and _whole(snapshot.get("change_counter")) and not fingerprint(snapshot).is_empty()

static func _available(snapshot: Dictionary) -> int:
 var roster: Array=snapshot["game"]["roster"]
 var extra:=0
 for person in roster:
  if str(person.get("id",""))==str(snapshot.get("lead_vocal_id","")) and not person["roles"].has("Singer"):extra=5
 return Base.MAX_TALENT-Pricing.spent(roster,str(snapshot["game"].get(Pricing.KEY,"")))-extra

static func _receipt_valid(receipt: Dictionary,sequence: int) -> bool:
 if receipt.is_empty():return true
 if receipt.has(Connections.TALK) and not Connections.conversation_valid(receipt[Connections.TALK]):return false
 var content: Script=Profiles.content(str(receipt.get("candidate_id","")))
 if content==null:return false
 if receipt.get("candidate_id")!=content.PERSON_ID or receipt.get("role")!=content.ROLE:return false
 if not receipt.get("id") is String or not _whole(receipt.get("revision"),0,3):return false
 var parts: PackedStringArray=str(receipt["id"]).split(":")
 if parts.size()!=3 or not parts[1].is_valid_int():return false
 var number:=int(parts[1])
 if number<1 or number>sequence or receipt["id"]!="audition:%d:%s" % [number,content.PERSON_ID]:return false
 if receipt.get("result") not in ["invited","passed","aborted"]:return false
 if receipt.get("request") not in ["","space_for_voice","own_part"]:return false
 for key in ["available_before","charged","available_after"]:
  if not _whole(receipt.get(key),0,Base.MAX_TALENT):return false
 if int(receipt["available_before"])-int(receipt["available_after"])!=int(receipt["charged"]):return false
 if receipt["result"]!="invited" and int(receipt["charged"])!=0:return false
 for key in ["catalogue_sha256","content_version","content_sha256","first_material_id","adjusted_material_id","response_id"]:
  if not receipt.get(key) is String:return false
 for key in ["catalogue_sha256","content_sha256"]:
  if str(receipt[key]).length()!=64 or not str(receipt[key]).is_valid_hex_number(false):return false
 if str(receipt["content_version"]).is_empty():return false
 var before_request: bool=int(receipt["revision"])<2
 if receipt["result"] in ["invited","passed"] and int(receipt["revision"])!=3:return false
 if (before_request and receipt["request"]!="") or (not before_request and receipt["request"] not in content.REQUESTS):return false
 if not _material_prefix_valid(receipt,before_request):return false
 if receipt["result"]=="aborted" and receipt.get("reason") not in ["closed_by_player","source_changed"]:return false
 return _canon(receipt)!=null

static func _material_prefix_valid(record: Dictionary,before_request: bool) -> bool:
 var id: String=str(record.get("candidate_id",""))
 if not Profiles.supports(id):return false
 var first: String=str(record.get("first_material_id",""))
 var stem: String=id.trim_prefix("cast_")
 var prefix: String=stem+"_four_bars_original_v"
 if not first.begins_with(prefix):return false
 var suffix:=first.trim_prefix(prefix)
 if not suffix.is_valid_int() or not _whole(int(suffix),1) or suffix!=str(int(suffix)):return false
 var version: String="v"+suffix
 return record.get("adjusted_material_id")==("" if before_request else stem+"_four_bars_"+str(record.get("request",""))+"_"+version) and record.get("response_id")==("" if before_request else stem+"_response_"+str(record.get("request",""))+"_"+version)

static func validate(snapshot: Dictionary) -> Dictionary:
 if not snapshot.has(KEY):return {"ok":true,"exists":false,"active":false,"held":false,"message":""}
 var raw: Variant=snapshot[KEY]
 if not raw is Dictionary:return _held("The saved audition format is not supported.")
 if not _whole(raw.get("version"),1,1) or not _whole(raw.get("sequence")) or not raw.get("active") is Dictionary or not raw.get("last_result") is Dictionary:return _held("The saved audition format needs review.")
 if not _receipt_valid(raw["last_result"],int(raw["sequence"])) or not _history_valid(raw) or _canon(raw)==null:return _held("The saved audition history needs review.")
 if not raw["last_result"].is_empty() and raw["last_result"].get("result") in ["invited","passed"] and not _completed_current(raw["last_result"]):return _held("The saved audition history needs compatible content.")
 var active: Dictionary=raw["active"]
 if active.has(Connections.TALK) and not Connections.conversation_valid(active[Connections.TALK]):return _held("The saved audition conversation needs a compatible version.")
 if active.is_empty():return {"ok":true,"exists":true,"active":false,"held":false,"message":""}
 var content: Script=Profiles.content(str(active.get("candidate_id","")))
 if content==null:return _held("The saved audition identity needs review.")
 if active.get("candidate_id")!=content.PERSON_ID or active.get("role")!=content.ROLE or not active.get("candidate_snapshot") is Dictionary:return _held("The saved audition identity needs review.")
 if active.get("phase") not in PHASES or not _whole(active.get("revision"),0,3) or int(active["revision"])!=PHASES.find(active["phase"]):return _held("The saved audition phase needs review.")
 if active.get("id")!="audition:%d:%s" % [int(raw["sequence"]),content.PERSON_ID] or int(raw["sequence"])<1:return _held("The saved audition identity needs review.")
 for key in ["catalogue_sha256","content_version","content_sha256","exercise_version","first_material_id","adjusted_material_id","response_id","source_fingerprint","request"]:
  if not active.get(key) is String:return _held("The saved audition content needs review.")
 if str(active["source_fingerprint"]).length()!=64 or not str(active["source_fingerprint"]).is_valid_hex_number(false):return _held("The saved audition source pin needs review.")
 var before_request: bool=active["phase"] in ["arrival","tryout"]
 if (before_request and active["request"]!="") or (not before_request and active["request"] not in content.REQUESTS):return _held("The saved audition request is out of order.")
 if not _material_prefix_valid(active,before_request):return _held("The saved request and response do not match.")
 var stale: bool=not _source_ok(snapshot) or active["source_fingerprint"]!=fingerprint(snapshot) or active["catalogue_sha256"]!=content.catalogue_sha() or active["content_version"]!=content.VERSION or active["content_sha256"]!=content.fingerprint() or active["exercise_version"]!=content.VERSION or active["first_material_id"]!=content.FIRST_ID or not _same(active["candidate_snapshot"],content.candidate())
 return {"ok":true,"exists":true,"active":true,"held":stale,"message":"The opening changed. Close this saved audition before another choice." if stale else ""}

static func _held(message: String) -> Dictionary:
 return {"ok":false,"exists":true,"active":false,"held":true,"message":message}

static func locked(snapshot: Dictionary) -> bool:
 var status:=validate(snapshot)
 return bool(status["active"]) or bool(status["held"])

static func expected(snapshot: Dictionary) -> Dictionary:
 var status:=validate(snapshot)
 if not status["ok"] or not status["active"]:return {}
 var active: Dictionary=snapshot[KEY]["active"]
 var token: Dictionary={"id":active["id"],"phase":active["phase"],"revision":active["revision"],"source_fingerprint":active["source_fingerprint"]}
 if active.has(Connections.TALK):token["conversation_revision"]=int(active[Connections.TALK].revision)
 return token

static func _token(snapshot: Dictionary,token: Dictionary,allow_stale: bool=false) -> bool:
 var status:=validate(snapshot)
 return status["ok"] and status["active"] and (allow_stale or not status["held"]) and token.size()==expected(snapshot).size() and _same(expected(snapshot),token)

static func _wrapper(snapshot: Dictionary) -> Dictionary:
 var wrapper: Dictionary=snapshot[KEY].duplicate(true) if snapshot.has(KEY) else {"version":1,"sequence":0,"active":{},"last_result":{}}
 if not wrapper.has("heard_by_candidate"):
  wrapper["heard_by_candidate"]={}
  _remember(wrapper)
 return wrapper

static func _remember(wrapper: Dictionary) -> void:
 var receipt: Dictionary=wrapper["last_result"]
 if not receipt.is_empty() and receipt.get("result") in ["invited","passed"]:
  wrapper["heard_by_candidate"][str(receipt["candidate_id"])]=receipt.duplicate(true)

static func _completed_current(receipt: Dictionary) -> bool:
 var content: Script=Profiles.content(str(receipt.get("candidate_id","")))
 if content==null:return false
 var request: String=str(receipt.get("request",""))
 return request in content.REQUESTS and receipt.get("content_version")==content.VERSION and receipt.get("content_sha256")==content.fingerprint() and receipt.get("catalogue_sha256")==content.catalogue_sha() and receipt.get("first_material_id")==content.FIRST_ID and receipt.get("adjusted_material_id")==content.material_id(request) and receipt.get("response_id")==content.response_id(request)

static func _history_valid(wrapper: Dictionary) -> bool:
 if not wrapper.has("heard_by_candidate"):return true
 var history: Variant=wrapper["heard_by_candidate"]
 if not history is Dictionary or history.size()>18:return false
 var seen: Array=[]
 var sequence: int=int(wrapper["sequence"])
 var active: Dictionary=wrapper["active"]
 for id in history:
  if not id is String or not Profiles.supports(id) or not history[id] is Dictionary:return false
  var receipt: Dictionary=history[id]
  if receipt.is_empty() or receipt.get("candidate_id")!=id or receipt.get("result") not in ["invited","passed"] or not _receipt_valid(receipt,sequence):return false
  if not _completed_current(receipt):return false
  var number: int=int(str(receipt["id"]).split(":")[1])
  if seen.has(number) or (not active.is_empty() and number>=sequence):return false
  seen.append(number)
 var latest: Dictionary=wrapper["last_result"]
 if not latest.is_empty() and latest.get("result") in ["invited","passed"]:
  if not history.has(latest["candidate_id"]) or not _same(latest,history[latest["candidate_id"]]):return false
 return true

static func _receipt_for(snapshot: Dictionary,candidate_id: String) -> Dictionary:
 if not snapshot.has(KEY):return {}
 var wrapper: Dictionary=snapshot[KEY]
 if wrapper.has("heard_by_candidate"):
  return wrapper["heard_by_candidate"].get(candidate_id,{}).duplicate(true)
 var latest: Dictionary=wrapper["last_result"]
 return latest.duplicate(true) if latest.get("candidate_id")==candidate_id else {}

static func begin(snapshot: Dictionary,candidate_id: String,role: String) -> Dictionary:
 var content: Script=Profiles.content(candidate_id)
 if content==null:return _fail("This musician has no supported saved audition.")
 var status:=validate(snapshot)
 if not status["ok"] or status["held"] or status["active"]:return _fail("Resume or close the saved audition first.")
 if not _source_ok(snapshot) or candidate_id!=content.PERSON_ID or role!=content.ROLE:return _fail("This audition is not available here.")
 if Base.contains(snapshot["game"]["roster"],candidate_id):return _fail(str(content.candidate().get("name","This musician"))+" is already in the band.")
 var wrapper:=_wrapper(snapshot)
 if int(wrapper["sequence"])>=LIMIT:return _fail("The audition history has reached its limit.")
 wrapper["sequence"]=int(wrapper["sequence"])+1
 wrapper["active"]={"id":"audition:%d:%s" % [int(wrapper["sequence"]),candidate_id],"revision":0,"phase":"arrival",
  "candidate_id":candidate_id,"role":role,"candidate_snapshot":_freeze_candidate(content.candidate()),"catalogue_sha256":content.catalogue_sha(),
  "content_version":content.VERSION,"content_sha256":content.fingerprint(),"exercise_version":content.VERSION,
  "first_material_id":content.FIRST_ID,"adjusted_material_id":"","response_id":"","source_fingerprint":fingerprint(snapshot),"request":""}
 return {"ok":true,"wrapper":wrapper,"message":"Meet "+str(content.candidate().get("name","the musician"))+".","changed":true}

static func _receipt(active: Dictionary,result: String,before: int,charged: int,after: int) -> Dictionary:
 var receipt: Dictionary={}
 var known_active: Array=["id","revision","phase","candidate_id","role","candidate_snapshot","catalogue_sha256","content_version","content_sha256","exercise_version","first_material_id","adjusted_material_id","response_id","source_fingerprint","request"]
 for key in active:
  if not known_active.has(key):receipt[key]=active[key].duplicate(true) if active[key] is Dictionary or active[key] is Array else active[key]
 for key in ["id","revision","candidate_id","role","request","catalogue_sha256","content_version","content_sha256","first_material_id","adjusted_material_id","response_id"]:receipt[key]=active[key]
 receipt["result"]=result
 receipt["available_before"]=before
 receipt["charged"]=charged
 receipt["available_after"]=after
 return receipt

static func checkpoint(snapshot: Dictionary,action: String,token: Dictionary,request: String="") -> Dictionary:
 if not _token(snapshot,token,action=="abort"):return _fail("This audition choice is stale or unavailable.")
 var wrapper:=_wrapper(snapshot)
 var active: Dictionary=wrapper["active"]
 var content: Script=Profiles.content(str(active["candidate_id"]))
 if action=="abort":
  if not _budget_ok(snapshot):return _fail("The current talent budget needs review before this audition can close.")
  # Latest event changes; prior completed hearings remain in their own map.
  wrapper["last_result"]=_receipt(active,"aborted",_available(snapshot),0,_available(snapshot))
  wrapper["last_result"]["reason"]="source_changed" if validate(snapshot)["held"] else "closed_by_player"
  wrapper["active"]={}
  return {"ok":true,"wrapper":wrapper,"message":"Audition closed. Your lineup is unchanged.","changed":true}
 if action=="talk" and active["phase"] in ["tryout","response","decision"]:
  var parts: PackedStringArray=request.split(":")
  if parts.size()!=2 or not Connections.QUESTIONS.has(parts[0]) or parts[1] not in Connections.QUESTIONS[parts[0]]:return _fail("Choose one of the conversation replies.")
  var talk: Dictionary=active.get(Connections.TALK,{"version":1,"revision":0,"answers":{}}).duplicate(true)
  if talk.answers.has(parts[0]):return _fail("That answer is already part of this audition.")
  talk.answers[str(parts[0])]=str(parts[1]);talk["revision"]=int(talk.revision)+1;active[Connections.TALK]=talk
  return {"ok":true,"wrapper":wrapper,"message":Connections.reply(str(active.candidate_id),parts[0],parts[1]),"changed":true}
 if action=="start_tryout" and active["phase"]=="arrival":active["phase"]="tryout"
 elif action=="request" and active["phase"]=="tryout" and request in content.REQUESTS:
  active["phase"]="response"
  if not active.has(Connections.TALK):active[Connections.TALK]={"version":1,"revision":0,"answers":{}}
  active["request"]=request
  active["adjusted_material_id"]=content.material_id(request)
  active["response_id"]=content.response_id(request)
 elif action=="review" and active["phase"]=="response":active["phase"]="decision"
 elif action=="pass" and active["phase"]=="decision":
  wrapper["last_result"]=_receipt(active,"passed",_available(snapshot),0,_available(snapshot))
  _remember(wrapper)
  wrapper["active"]={}
  return {"ok":true,"wrapper":wrapper,"message":"You leave the invitation open. No talent spent.","changed":true}
 else:return _fail("That action does not belong to this audition moment.")
 active["revision"]=PHASES.find(active["phase"])
 return {"ok":true,"wrapper":wrapper,"message":"","changed":true}

static func prepare_invite(snapshot: Dictionary,token: Dictionary) -> Dictionary:
 if not _token(snapshot,token) or snapshot[KEY]["active"]["phase"]!="decision":return _fail("Finish this audition before inviting the musician.")
 var content: Script=Profiles.content(str(snapshot[KEY]["active"]["candidate_id"]))
 var person: Dictionary=content.candidate()
 var roster: Array=snapshot["game"]["roster"]
 if not Pricing.can_add(roster,person,str(snapshot["game"].get(Pricing.KEY,""))) or _available(snapshot)<Pricing.incremental(roster,person,str(snapshot["game"].get(Pricing.KEY,""))):return _fail("There is not enough talent available for this lineup.")
 return {"ok":true,"active":snapshot[KEY]["active"].duplicate(true),"candidate_id":content.PERSON_ID,"message":""}

static func complete_invite(before: Dictionary,after: Dictionary,token: Dictionary,original_result: Dictionary,available_before: int,available_after: int) -> Dictionary:
 var ready:=prepare_invite(before,token)
 if not ready["ok"] or not original_result.get("ok",false):return _fail("The original invitation was not committed.")
 var content: Script=Profiles.content(str(ready["candidate_id"]))
 var price:=Pricing.incremental(before["game"]["roster"],content.candidate(),str(before["game"].get(Pricing.KEY,"")))
 if original_result.get("charged")!=price or available_before!=_available(before) or available_after!=available_before-price:return _fail("The invitation result does not match the original talent cost.")
 var planned:=before.duplicate(true)
 planned["game"]["roster"].append(content.candidate())
 planned["change_counter"]=int(planned["change_counter"])+1
 planned.erase(KEY)
 var observed:=after.duplicate(true)
 observed.erase(KEY)
 if not _same(planned,observed):return _fail("The invitation changed more than the original lineup.")
 var wrapper:=_wrapper(before)
 wrapper["last_result"]=_receipt(ready["active"],"invited",available_before,price,available_after)
 _remember(wrapper)
 wrapper["active"]={}
 return {"ok":true,"wrapper":wrapper,"message":"%s joins the band. %d talent used." % [str(content.candidate().get("name","The musician")),price],"changed":true}

static func heard(snapshot: Dictionary,candidate_id: String="cast_jack") -> bool:
 var content: Script=Profiles.content(candidate_id)
 if content==null:return false
 var status:=validate(snapshot)
 if not status["ok"] or status["active"] or status["held"] or not status["exists"]:return false
 var receipt: Dictionary=_receipt_for(snapshot,candidate_id)
 return not receipt.is_empty() and receipt["result"] in ["invited","passed"] and receipt["request"] in content.REQUESTS and receipt["content_version"]==content.VERSION and receipt["content_sha256"]==content.fingerprint() and receipt["catalogue_sha256"]==content.catalogue_sha() and receipt["first_material_id"]==content.FIRST_ID and receipt["adjusted_material_id"]==content.material_id(receipt["request"]) and receipt["response_id"]==content.response_id(receipt["request"])

static func view(snapshot: Dictionary,candidate_id: String="cast_jack") -> Dictionary:
 if not Profiles.supports(candidate_id):return _held("This musician has no supported saved audition.")
 var status:=validate(snapshot)
 var result:=status.duplicate(true)
 var id: String=str(snapshot[KEY]["active"]["candidate_id"]) if status["ok"] and status["active"] else candidate_id
 var content: Script=Profiles.content(id)
 result["candidate_id"]=id
 result["phase"]=""
 result["heard"]=heard(snapshot,id)
 result["receipt"]={}
 if status["ok"] and status["exists"]:
  var receipt: Dictionary=_receipt_for(snapshot,id)
  for key in ["id","candidate_id","role","request","result","reason","available_before","charged","available_after"]:
   if receipt.has(key):result["receipt"][key]=receipt[key]
 result["person"]=content.public_person()
 result["room"]=content.ROOM
 result["portrait"]=content.PORTRAIT
 if status["ok"] and status["active"]:
  var active: Dictionary=snapshot[KEY]["active"]
  for key in ["id","revision","phase","request"]:result[key]=active[key]
  result["voice"]=content.voice(active["phase"],active["request"])
  result["bars"]=content.bars(active["request"])
  result["before_bars"]=content.bars()
  result["conversation"]=active.get(Connections.TALK,{}).duplicate(true)
 return result
