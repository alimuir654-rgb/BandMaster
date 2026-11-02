extends RefCounted
## Narrow attendance-aware tighten adapter. It retains every member, index,
## role and life_status; only the explicit attendees enter the practice loops.
## All-attending careers use the unchanged Session.rehearse control instead.
const Actions = preload("res://Scripts/career_actions.gd")
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")

static func resolve(state: Dictionary, attendee_indices: Array) -> Dictionary:
 var checked: Dictionary=Core.validate(state)
 if not checked.ok:return checked
 for field in ["cash","tour_day","action_count","readiness","morale","tension"]:
  if not Core._integer(state.get(field,0)):return {"ok":false,"message":"The rehearsal's saved values are not readable."}
 if int(state.tour_day)>=Core.MAX_NUMBER or int(state.get("action_count",0))>=Core.MAX_NUMBER:return {"ok":false,"message":"The rehearsal has reached the supported career limit."}
 if int(state.get("cash",0))<15:return {"ok":false,"message":"Not enough cash for rehearsal (£15)."}
 var seen: Dictionary={}
 for index in attendee_indices:
  if not index is int or index<0 or index>=state.members.size() or seen.has(index) or str(state.members[index].get("life_status","active"))!="active":return {"ok":false,"message":"Review the actual rehearsal attendance again."}
  seen[index]=true
 if attendee_indices.size()<2:return {"ok":false,"message":"A rehearsal needs at least two available musicians. Reschedule or return later."}
 var next: Dictionary=state.duplicate(true)
 next.cash=int(state.cash)-15
 next.tour_day=int(state.tour_day)+1
 for key in Actions.KEYS:
  var upper: int=100 if key in ["readiness","morale","tension","buzz","press"] else 100000
  next[key]=clampi(int(next.get(key,0))+int(Actions.ACTIONS.rehearse.get(key,0)),0,upper)
 next.action_count=int(state.get("action_count",0))+1
 var counters: Dictionary=next.get("action_counters",{}).duplicate(true)
 counters.rehearse=int(counters.get("rehearse",0))+1
 next.action_counters=counters
 var extra_readiness: int=0
 var stress: int=0
 var missed: int=0
 var traits: Dictionary={"reliable":[2,-1],"ambitious":[2,2],"creative":[0,0],"laid-back":[0,-2],"perfectionist":[3,3],"restless":[-1,3]}
 for index in attendee_indices:
  var person: Dictionary=next.members[index]
  for field in ["fatigue","skill","morale","loyalty"]:
   if not Core._integer(person.get(field,50 if field!="fatigue" else 0)):return {"ok":false,"message":"A musician's rehearsal values are not readable."}
  var risk: Variant=person.get("rehearsal_risk",{})
  if not risk is Dictionary or not Core._integer(risk.get("missed_preparation",0)):return {"ok":false,"message":"A musician's preparation record is not readable."}
  var trait: String=str(person.get("trait","")).to_lower()
  var effect: Array=traits.get(trait,[0,0])
  extra_readiness+=int(effect[0])
  stress+=int(effect[1])
  person.fatigue=clampi(int(person.get("fatigue",0))+6,0,100)
  person.skill=clampi(int(person.get("skill",50))+2,0,100)
  person.morale=clampi(int(person.get("morale",50))-1,0,100)
  var mood: int=0
  if trait in ["perfectionist","control freak","reliable"]:mood=3
  elif trait in ["restless","chaos","unreliable"]:mood=-3
  person.morale=clampi(int(person.get("morale",55))+mood,0,100)
  missed+=int(risk.get("missed_preparation",0))
 next.readiness=clampi(int(next.readiness)+extra_readiness,0,100)
 next.tension=clampi(int(next.tension)+int(float(stress)/float(attendee_indices.size())),0,100)
 next.readiness=clampi(int(next.readiness)-missed,0,100)
 var work: Dictionary=next.get("band_work_counters",{}).duplicate(true)
 work.rehearse=int(work.get("rehearse",0))+1
 next.band_work_counters=work
 var journal: Array=next.get("career_journal",[]).duplicate(true)
 if int(work.rehearse)==1:journal.append({"id":"work:rehearse","day":int(next.tour_day),"title":"IN THE REHEARSAL ROOM","text":"The attending musicians begin finding their sound together.","kind":"band"})
 var message: String="The available musicians work through the live set. The missing players have not practised."
 journal.append({"id":"room:tighten:%d" % int(next.tour_day),"day":int(next.tour_day),"title":"DRILL THE LIVE SET","text":message,"kind":"band"})
 while journal.size()>80:journal.pop_front()
 next.career_journal=journal
 # Preserve genuine opportunity selection without crediting absent musicians.
 Actions._opportunity(next)
 return {"ok":true,"state":next,"message":message,"attendee_indices":attendee_indices.duplicate()}
