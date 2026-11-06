extends RefCounted
## Informal, low-volume practice with whoever is free. No room hire, song
## settlement, live-readiness package or formal rehearsal fulfilment.
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")

static func resolve(state: Dictionary,indices: Array) -> Dictionary:
 var financial: Dictionary=preload("res://experiments/playable_flightcase/finance_policy.gd").guard(state)
 if not financial.get("ok",false):return financial
 if preload("res://experiments/playable_flightcase/radio_visit_rules.gd").locked(state):return {"ok":false,"message":"Finish or cancel the saved radio visit before another evening with the band."}
 var view: Dictionary=Core.inspect_rehearsal(state)
 if not view.get("ok",false):return view
 if not Core.exact(indices,view.attendee_indices):return {"ok":false,"message":"Availability changed. Review who is free this evening."}
 for field in ["tour_day","action_count"]:
  if not Core._integer(state.get(field),0) or int(state[field])>=Core.MAX_NUMBER:return {"ok":false,"message":"The practice date needs compatible review."}
 if not state.get("career_journal",[]) is Array or not state.get("relationships",{}) is Dictionary or not state.get("action_counters",{}) is Dictionary:return {"ok":false,"message":"The band's practice history needs review."}
 var next: Dictionary=state.duplicate(true)
 var names: Array[String]=[]
 for index in indices:
  var person: Dictionary=next.members[index]
  for field in ["skill","fatigue"]:
   if not Core._integer(person.get(field)) or int(person.get(field,0))>100:return {"ok":false,"message":"A musician's practice record needs review."}
  person["skill"]=mini(100,int(person.get("skill",0))+1)
  person["fatigue"]=mini(100,int(person.get("fatigue",0))+3)
  names.append(str(person.get("name","Bandmate")))
 var relations: Dictionary=next.get("relationships",{}).duplicate(true)
 for a in range(indices.size()):
  for b in range(a+1,indices.size()):
   var key: String="%d_%d" % [mini(indices[a],indices[b]),maxi(indices[a],indices[b])]
   if not Core._integer(relations.get(key,50)) or int(relations.get(key,50))>100:return {"ok":false,"message":"A relationship record needs compatible review."}
   relations[key]=mini(100,int(relations.get(key,50))+1)
 var counters: Dictionary=next.get("action_counters",{}).duplicate(true)
 if not Core._integer(counters.get("informal_practice",0)) or int(counters.get("informal_practice",0))>=Core.MAX_NUMBER:return {"ok":false,"message":"The informal practice history is full."}
 counters["informal_practice"]=int(counters.get("informal_practice",0))+1
 next["action_counters"]=counters;next["relationships"]=relations
 next["tour_day"]=int(state.tour_day)+1;next["action_count"]=int(state.get("action_count",0))+1
 var message: String=("A quiet evening passes. Nobody was free to practise." if indices.is_empty() else (names[0]+" spends the evening practising alone." if indices.size()==1 else ", ".join(names)+" share a low-volume jam and begin finding each other's timing."))
 if indices.size()<state.members.size() and not indices.is_empty():message+=" Only those here practised; the others can catch up together later."
 var journal: Array=next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"informal:%d" % int(next.action_count),"day":int(next.tour_day),"title":"AN EVENING WITH THE MUSIC" if not indices.is_empty() else "A QUIET EVENING","text":message,"kind":"band"})
 while journal.size()>80:journal.pop_front()
 next["career_journal"]=journal
 return {"ok":true,"state":next,"message":message,"attendee_indices":indices.duplicate()}
