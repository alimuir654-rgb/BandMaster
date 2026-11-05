extends RefCounted
## Proposed state only, sealed by the original paid writing owner and its rollback.
const KEY := "co_writer_memory_v1"

static func valid(value: Variant) -> bool:
 if not value is Dictionary or value.size()!=2 or not value.get("version") is int or value.version!=1 or not value.get("members") is Dictionary or value.members.size()>18:return false
 for id in value.members:
  var row: Variant=value.members[id]
  if not id is String or not row is Dictionary or row.size()!=2 or not row.get("dismissals") is int or int(row.dismissals)<0 or int(row.dismissals)>1000000000 or not row.get("history") is Array or row.history.size()>12:return false
  for item in row.history:
   if not item is Dictionary or item.size()!=4 or not item.get("id") is String or not item.get("offer_id") is String or not item.get("response") is String or item.response not in ["considered","dismissed"] or not item.get("loyalty_delta") is int or int(item.loyalty_delta) not in [-1,0]:return false
 return true

static func apply(state: Dictionary,project: Dictionary,stage: int) -> Dictionary:
 var fail: Dictionary={"ok":false,"state":state,"message":"The saved co-writing history needs review."}
 var memory: Dictionary=state.get(KEY,{"version":1,"members":{}}).duplicate(true) if state.get(KEY,{}) is Dictionary else {}
 if not valid(memory):return fail
 var trial: Dictionary=project.last_trial
 var ref: Dictionary=trial.target.respondent_ref
 if ref.is_empty():return {"ok":true,"state":state.duplicate(true),"message":""}
 var slot: int=int(ref.slot)
 if slot<0 or slot>=state.members.size():return fail
 var member: Dictionary=state.members[slot]
 if str(member.get("name",""))!=str(ref.name) or str(member.get("candidate_id",""))!=str(ref.candidate_id):return fail
 var id: String=str(ref.candidate_id) if not str(ref.candidate_id).is_empty() else "%s:%s" % [str(ref.member_id),ref.name]
 if not memory.members.has(id) and memory.members.size()>=18:return fail
 var row: Dictionary=memory.members.get(id,{"dismissals":0,"history":[]}).duplicate(true)
 var receipt: String="%s:stage:%d" % [project.id,stage]
 for item in row.history:
  if item.id==receipt:return fail
 var decision: Dictionary=project.get("producer_decision",{})
 var considered: bool=decision.get("choice") in ["try","keep"] and decision.get("stage")==stage and decision.get("member")==ref and decision.get("chosen_recipe")==project.fragment.producer_recipe
 var count: int=0 if considered else int(row.dismissals)+1
 if count>1000000000:return fail
 var delta: int=-1 if count>=2 else 0
 var next: Dictionary=state.duplicate(true)
 if delta!=0:
  var loyalty: Variant=member.get("loyalty")
  if not (loyalty is int or loyalty is float) or not is_finite(float(loyalty)) or float(loyalty)!=floor(float(loyalty)) or float(loyalty)<0 or float(loyalty)>100:return fail
  var actual: int=maxi(0,int(loyalty)-1)-int(loyalty)
  next.members[slot].loyalty=int(loyalty)+actual
  delta=actual
 row.dismissals=count
 row.history.append({"id":receipt,"offer_id":str(decision.get("offer_id",trial.note.request.get("offer_id",""))),"response":"considered" if considered else "dismissed","loyalty_delta":delta})
 while row.history.size()>12:row.history.pop_front()
 memory.members[id]=row
 next[KEY]=memory
 return {"ok":true,"state":next,"message":("%s feels repeatedly brushed aside during writing." % ref.name) if delta<0 else ("%s’s idea was considered; keeping your own direction is a legitimate choice." % ref.name if considered else "%s’s suggestion was left unanswered in this session." % ref.name)}
