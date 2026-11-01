extends RefCounted
## Durable free checkpoints around ONE original paid radio settlement.
const Promotion = preload("res://experiments/playable_flightcase/promotion_rules.gd")
const Recording = preload("res://experiments/playable_flightcase/recording_rules.gd")
const KEY := "radio_visit_v1"
const PHASES := ["arrival","introduction","question1","reaction1","question2","reaction2","wrap_ready"]
const QUESTION_IDS := ["focus","invitation"]
const PRESENTER := "student_presenter_v1"

static func _whole(value: Variant, minimum: int=0) -> bool:
 return Promotion._whole(value,minimum)

static func _compatible(raw: Variant) -> bool:
 return raw is Dictionary and _whole(raw.get("version",0),1) and int(raw["version"])==1 and _whole(raw.get("seq",-1)) and raw.has("active")

static func active(state: Dictionary) -> Dictionary:
 var raw: Variant=state.get(KEY)
 if not raw is Dictionary or not raw.get("active") is Dictionary:return {}
 return (raw["active"] as Dictionary).duplicate(true)

static func locked(state: Dictionary) -> bool:
 return Promotion.visit_locked(state)

static func _result(state: Dictionary, ok: bool, message: String="", changed: bool=false, settled: bool=false, receipt: Dictionary={}) -> Dictionary:
 var visit: Dictionary=active(state)
 return {"ok":ok,"state":state.duplicate(true),"message":message,"phase":str(visit.get("phase","none")),"visit":visit,"changed":changed,"settled":settled,"receipt":receipt.duplicate(true)}

static func validate(state: Dictionary) -> Dictionary:
 var base: Dictionary=Promotion.validate(state)
 if not bool(base.get("ok",false)):return base
 if not state.has(KEY):return {"ok":true,"message":""}
 var raw: Variant=state[KEY]
 if not _compatible(raw) or not raw["active"] is Dictionary:return {"ok":false,"message":"This saved radio-visit wrapper is unsupported. It has been held without changing it."}
 var visit: Dictionary=raw["active"]
 if visit.is_empty():return {"ok":true,"message":""}
 if not _whole(raw["seq"],1):return {"ok":false,"message":"The saved visit sequence needs validation."}
 for field in ["id","phase","demo_id","source_fingerprint","presenter_id"]:
  if not visit.get(field) is String:return {"ok":false,"message":"A saved radio-visit identity needs validation."}
 for field in ["revision","demo_index","started_cash"]:
  if not _whole(visit.get(field,-1)):return {"ok":false,"message":"A saved radio-visit counter needs validation."}
 if not _whole(visit.get("started_day",0),1):return {"ok":false,"message":"The saved radio-visit day needs validation."}
 for field in ["policy_version","content_version"]:
  if not _whole(visit.get(field,0),1) or int(visit[field])!=1:return {"ok":false,"message":"This radio visit uses an unsupported question or outcome version."}
 var phase_index: int=PHASES.find(visit["phase"])
 if phase_index<0 or int(visit["revision"])!=phase_index or visit["presenter_id"]!=PRESENTER or visit.get("question_ids")!=QUESTION_IDS:return {"ok":false,"message":"The saved radio visit has an unsupported phase or presenter."}
 var fingerprint: String=visit["source_fingerprint"]
 if fingerprint.length()!=64 or visit["id"]!="radio-visit:%d:%s" % [int(raw["seq"]),fingerprint.left(12)]:return {"ok":false,"message":"The saved visit identity does not match its source."}
 if not visit.get("answers") is Dictionary:return {"ok":false,"message":"The saved interview answers need validation."}
 var answers: Dictionary=visit["answers"]
 for q in range(QUESTION_IDS.size()):
  var question: String=QUESTION_IDS[q]
  var required: bool=phase_index>=(3 if q==0 else 5)
  if required:
   if not answers.get(question) is String or not (Promotion.QUESTIONS[question]["choices"] as Dictionary).has(answers[question]):return {"ok":false,"message":"A saved interview reply is missing or unsupported."}
  elif answers.has(question):return {"ok":false,"message":"A saved interview reply appears before its question."}
 if int(state.get("tour_day",1))!=int(visit["started_day"]) or int(state.get("cash",0))!=int(visit["started_cash"]):return {"ok":false,"message":"The band's day or cash changed during this visit. Cancel the unfinished visit before another commitment."}
 var selected: Dictionary=Promotion.selection(state,visit["demo_id"],fingerprint,int(visit["demo_index"]))
 if not bool(selected.get("ok",false)) or bool(selected.get("completed",false)):return {"ok":false,"message":str(selected.get("message","The selected recording is unavailable.")) if not bool(selected.get("ok",false)) else "This recording's radio campaign has already completed."}
 return {"ok":true,"message":""}

static func begin(state: Dictionary, id: String, fingerprint: String, index: int=-1) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid.get("ok",false)):return _result(state,false,str(valid["message"]))
 var existing: Dictionary=active(state)
 if not existing.is_empty():
  if existing["demo_id"]!=id or existing["source_fingerprint"]!=fingerprint or (id.is_empty() and int(existing["demo_index"])!=index):return _result(state,false,"Another radio visit is unfinished. Resume or cancel it first.")
  return _result(state,true,"The saved radio visit is ready to resume.")
 if int(state.get("tour_day",1))>=2147483647:return _result(state,false,"The radio visit would exceed the supported career-day range.")
 var preview: Dictionary=Promotion.preview(state,id,fingerprint,index)
 if not bool(preview.get("ok",false)):return _result(state,false,str(preview.get("message","This visit cannot begin.")))
 var next: Dictionary=state.duplicate(true)
 var wrapper: Dictionary=next.get(KEY,{"version":1,"seq":0,"active":{}}).duplicate(true)
 if int(wrapper["seq"])>=2147483647:return _result(state,false,"The saved radio-visit sequence is at its supported limit.")
 wrapper["seq"]=int(wrapper["seq"])+1
 wrapper["active"]={"id":"radio-visit:%d:%s" % [int(wrapper["seq"]),fingerprint.left(12)],"revision":0,"phase":"arrival","demo_id":id,"demo_index":int(preview["session_index"]),"source_fingerprint":fingerprint,"started_day":int(state.get("tour_day",1)),"started_cash":int(state.get("cash",0)),"policy_version":1,"content_version":1,"presenter_id":PRESENTER,"question_ids":QUESTION_IDS.duplicate(),"answers":{}}
 next[KEY]=wrapper
 return _result(next,true,"The visit is saved. £20 and one day are committed only at the final wrap.",true)

static func _owned(state: Dictionary, visit_id: String, phase: String, revision: int) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid.get("ok",false)):return valid
 var visit: Dictionary=active(state)
 if visit.is_empty() or visit.get("id")!=visit_id or visit.get("phase")!=phase or int(visit.get("revision",-1))!=revision:return {"ok":false,"message":"This radio visit changed. Resume its current phase."}
 return {"ok":true,"message":""}

static func advance(state: Dictionary, visit_id: String, expected_phase: String, expected_revision: int) -> Dictionary:
 var owned: Dictionary=_owned(state,visit_id,expected_phase,expected_revision)
 if not bool(owned.get("ok",false)):return _result(state,false,str(owned["message"]))
 if expected_phase not in ["arrival","introduction","reaction1","reaction2"]:return _result(state,false,"Choose a reply or explicitly wrap up this visit.")
 var next: Dictionary=state.duplicate(true)
 var visit: Dictionary=next[KEY]["active"]
 visit["revision"]=expected_revision+1
 visit["phase"]=PHASES[expected_revision+1]
 return _result(next,true,"The next part of the visit is saved.",true)

static func answer(state: Dictionary, visit_id: String, question_id: String, answer_id: String, expected_revision: int) -> Dictionary:
 var expected_phase: String="question1" if question_id=="focus" else "question2"
 var owned: Dictionary=_owned(state,visit_id,expected_phase,expected_revision)
 if not bool(owned.get("ok",false)):return _result(state,false,str(owned["message"]))
 if not Promotion.QUESTIONS.has(question_id) or not (Promotion.QUESTIONS[question_id]["choices"] as Dictionary).has(answer_id):return _result(state,false,"Choose one of this question's saved replies.")
 var next: Dictionary=state.duplicate(true)
 var visit: Dictionary=next[KEY]["active"]
 visit["answers"][question_id]=answer_id
 visit["revision"]=expected_revision+1
 visit["phase"]=PHASES[expected_revision+1]
 return _result(next,true,"Your reply is saved. Listen to the presenter's reaction before continuing.",true)

static func cancel(state: Dictionary, visit_id: String, expected_revision: int) -> Dictionary:
 var visit: Dictionary=active(state)
 var owned: Dictionary=_owned(state,visit_id,str(visit.get("phase","")),expected_revision)
 if not bool(owned.get("ok",false)):return _result(state,false,str(owned["message"]))
 var next: Dictionary=state.duplicate(true)
 next[KEY]["active"]={}
 return _result(next,true,"The unfinished radio visit was cancelled. No money or day was spent.",true)

static func discard(state: Dictionary, confirmed: bool) -> Dictionary:
 var raw: Variant=state.get(KEY)
 if not confirmed:return _result(state,false,"Confirm that this unfinished radio visit should be discarded.")
 if not _compatible(raw):return _result(state,false,"The radio-visit wrapper is unsupported and remains held without reinterpretation.")
 if raw["active"] is Dictionary and (raw["active"] as Dictionary).is_empty():return _result(state,false,"There is no unfinished radio visit to discard.")
 var next: Dictionary=state.duplicate(true)
 next[KEY]["active"]={}
 return _result(next,true,"The unfinished radio-visit data was discarded. No campaign, money or day changed.",true)

static func preview_finish(state: Dictionary, visit_id: String, expected_revision: int) -> Dictionary:
 return finish(state,visit_id,expected_revision)

static func finish(state: Dictionary, visit_id: String, expected_revision: int) -> Dictionary:
 var owned: Dictionary=_owned(state,visit_id,"wrap_ready",expected_revision)
 if not bool(owned.get("ok",false)):return _result(state,false,str(owned["message"]))
 var visit: Dictionary=active(state)
 var paid: Dictionary=Promotion.launch(state,visit["demo_id"],visit["source_fingerprint"],int(visit["demo_index"]),{"visit_id":visit_id,"expected_revision":expected_revision})
 if not bool(paid.get("ok",false)):return _result(state,false,str(paid.get("message","The visit could not be wrapped up.")))
 var next: Dictionary=paid["state"]
 next[KEY]["active"]={}
 var result: Dictionary=_result(next,true,str(paid["message"]),true,true,paid["receipt"])
 for field in ["session","demo_id","session_index","closing_balances","finance_action"]:result[field]=paid[field]
 result["phase"]="completed"
 result["visit"]=visit.duplicate(true)
 return result

static func view(state: Dictionary) -> Dictionary:
 var valid: Dictionary=validate(state)
 var visit: Dictionary=active(state)
 var can_discard: bool=false
 if state.has(KEY) and _compatible(state[KEY]):
  var payload: Variant=state[KEY]["active"]
  can_discard=not (payload is Dictionary and (payload as Dictionary).is_empty())
 var result: Dictionary={"ok":bool(valid.get("ok",false)),"held":not bool(valid.get("ok",false)),"visit":visit,"phase":str(visit.get("phase","none")),"heading":"STUDENT RADIO","speaker":"STUDENT PRESENTER","text":"Choose a released demo for the student-radio visit.","choices":[],"can_continue":false,"can_finish":false,"can_cancel":bool(valid.get("ok",false)) and not visit.is_empty(),"can_discard":can_discard,"question_id":"","progress":int(visit.get("revision",0)) if _whole(visit.get("revision",0)) else 0,"message":str(valid.get("message",""))}
 if not bool(result["ok"]):
  result["text"]=result["message"]
  return result
 if visit.is_empty():return result
 match visit["phase"]:
  "arrival":result["text"]="You arrive at a small student-radio room with your released demo. Nothing is charged until you choose the final wrap."
  "introduction":result["text"]="Welcome in. Let's give new listeners a reason to get to know your band. We'll talk about this record, then how you'd like people to hear it."
  "question1","question2":
   var q: String="focus" if visit["phase"]=="question1" else "invitation"
   result["question_id"]=q
   result["text"]=Promotion.QUESTIONS[q]["text"]
   for answer_id in (["craft","live_energy"] if q=="focus" else ["invite","critical_craft"]):
    var choice: Dictionary=Promotion.QUESTIONS[q]["choices"][answer_id]
    result["choices"].append({"id":answer_id,"text":choice["text"],"hint":choice["hint"]})
  "reaction1":result["text"]="We'll give listeners something in the songwriting to listen for. The details can carry the story of the record." if visit["answers"]["focus"]=="craft" else "We'll put the band's energy at the centre of the conversation. That gives listeners a feeling to connect with."
  "reaction2":result["text"]="An invitation to bring a friend: a simple next step for somebody hearing your band for the first time." if visit["answers"]["invitation"]=="invite" else "You're asking people to listen closely. We'll make the craft of this recording the point of the visit."
  "wrap_ready":result["text"]="Both replies are saved. Review the projected response, then choose whether to wrap up the visit for £20 and one day."
 result["can_continue"]=visit["phase"] in ["arrival","introduction","reaction1","reaction2"]
 result["can_finish"]=visit["phase"]=="wrap_ready"
 return result
