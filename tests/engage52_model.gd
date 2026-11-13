extends SceneTree
const Chat=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Cast=preload("res://experiments/character_cast/catalogue.gd")
const Promoter=preload("res://experiments/playable_flightcase/promoter_encounter.gd")
const Radio=preload("res://experiments/playable_flightcase/conversation_radio.gd")
var checks:=0
var failures: Array=[]
func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok:failures.append(label);push_error(label)
 return ok
func run() -> void:
 var unique: Dictionary={}
 for person in Cast.people():
  var member: Dictionary={"candidate_id":person.id,"name":person.name,"role":person.roles[0],"fatigue":10,"life_status":"active"}
  var state: Dictionary={"tour_day":5,"cash":250,"members":[member],"last_rehearsal_outcome":{},"tension":0}
  var before: String=Chat.fingerprint(state)
  for choice in ["listen","write_together","prepare_set"]:
   var result: Dictionary=Chat.answer(state,str(person.id),"direction",choice,before)
   if not check(result.get("ok",false),"real character reply "+str(person.id)+"/"+choice):continue
   var record: Dictionary=Chat.record(result.state,str(person.id))
   check(record.turns.size()==1 and record.turns[0].choice==choice,"saved actual intent and one turn")
   check(result.state.tour_day==5 and result.state.cash==250 and Chat.fingerprint(state)==before,"conversation never spends or mutates input")
   if choice=="listen":
    check(not unique.has(record.turns[0].reply),"individual want rather than a shared stock reply");unique[record.turns[0].reply]=true
   else:
    check(record.plan.kind==("write" if choice=="write_together" else "rehearse") and record.plan.due_day==9,"existing commitment meaning/deadline retained")
   check(Chat.validate(result.state).ok,"saved response remains schema compatible")
   check(not Chat.options(result.state,str(person.id),"direction").get("available",true),"no repeated daily promise farming")
 var fatigued: Dictionary={"tour_day":5,"cash":250,"members":[{"candidate_id":"cast_jack","name":"Jack","fatigue":70,"life_status":"active"}],"last_rehearsal_outcome":{},"tension":0}
 var pushed: Dictionary=Chat.answer(fatigued,"cast_jack","pressure","push_on",Chat.fingerprint(fatigued))
 check(pushed.ok and Chat.record(pushed.state,"cast_jack").turns[0].reply.contains("tired"),"tired musician retains actual pushback")
 var wants: Array=[]
 for venue in ["local","cardiff","manchester"]:wants.append(Promoter.concern(venue))
 check(wants[0]!=wants[1] and wants[1]!=wants[2] and wants[0]!=wants[2],"three promoters have distinct immediate concerns")
 var question: Dictionary={"text":"What would you ask a new listener to do next?","visit":{"phase":"question2","answers":{"focus":"craft"}}}
 var first: String=Radio.line(question,"THE LAST TRAIN")
 question.visit.answers.focus="live_energy"
 check(first!=Radio.line(question,"THE LAST TRAIN"),"radio follow-up responds to actual previous answer")
 question.visit.phase="wrap_ready";question.visit.answers.invitation="invite"
 check(Radio.line(question,"THE LAST TRAIN").contains("THE LAST TRAIN"),"radio closing carries actual selected track")
 check(Radio.next_line("reaction1")!="CONTINUE","conversation continues through a meaningful player line")
 print("ENGAGE52_MODEL "+JSON.stringify({"checks":checks,"failures":failures,"distinct_musicians":unique.size(),"physical_Android":false,"listening":false}))
 quit(0 if failures.is_empty() else 1)
