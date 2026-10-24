extends RefCounted
# Deterministic, save-compatible band situations and meaningful choices.
const EVENTS := {
 "creative_clash":{"title":"WHO WROTE THE CHORUS?","intro":"Two bandmates disagree over who deserves credit for the new song.","choices":[
  {"id":"share","label":"SHARE THE CREDIT","morale":5,"tension":-8,"loyalty":4},
  {"id":"pick","label":"BACK THE LEAD WRITER","readiness":4,"tension":10,"loyalty":-7}]},
 "exhausted":{"title":"RUNNING ON EMPTY","intro":"Someone is visibly exhausted and the band wants a decision.","choices":[
  {"id":"rest","label":"TAKE A DAY OFF","morale":9,"fatigue":-18,"readiness":-3},
  {"id":"push","label":"PUSH THROUGH","readiness":6,"morale":-8,"fatigue":12}]},
 "money_argument":{"title":"WHO PAYS FOR THIS?","intro":"A bandmate questions another expense from the shared cash box.","choices":[
  {"id":"budget","label":"AGREE A BUDGET","tension":-9,"loyalty":4},
  {"id":"spend","label":"TRUST THE PLAN","tension":8,"readiness":3,"loyalty":-4}]}
}
static func pending(state: Dictionary) -> Array:
 var result: Array = []
 var seen: Dictionary = state.get("band_drama_resolved",{})
 var day := int(state.get("tour_day",1))
 var members: Array = state.get("members",[])
 if members.size() < 2:
  return result
 if day >= 6 and int(state.get("songs",0)) >= 2 and not seen.has("creative_clash"):
  result.append("creative_clash")
 if day >= 10 and _maximum_fatigue(members) >= 60 and not seen.has("exhausted"):
  result.append("exhausted")
 if day >= 14 and int(state.get("cash",0)) <= 40 and not seen.has("money_argument"):
  result.append("money_argument")
 return result

static func resolve(state: Dictionary, event_id: String, choice_id: String) -> Dictionary:
 if not pending(state).has(event_id):
  return {"ok":false,"message":"This band situation is not available."}
 var definition: Dictionary = EVENTS[event_id]
 var selected: Dictionary = {}
 for option in definition["choices"]:
  if option["id"] == choice_id:
   selected = option
   break
 if selected.is_empty():
  return {"ok":false,"message":"Invalid decision."}
 var next := state.duplicate(true)
 var roster: Array = next.get("members",[])
 for member in roster:
  if not member is Dictionary:
   continue
  for key in ["loyalty","morale","fatigue"]:
   if selected.has(key):
    member[key] = clampi(int(member.get(key,50))+int(selected[key]),0,100)
 for key in ["tension","morale","readiness"]:
  if selected.has(key):
   next[key] = clampi(int(next.get(key,50))+int(selected[key]),0,100)
 next["tour_day"] = int(next.get("tour_day",1))+1
 var seen: Dictionary = next.get("band_drama_resolved",{}).duplicate(true)
 seen[event_id] = choice_id
 next["band_drama_resolved"] = seen
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"drama:"+event_id,"day":next["tour_day"],"title":definition["title"],"text":selected["label"],"kind":"band"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":definition["title"]+" — "+selected["label"]+"."}

static func _maximum_fatigue(members: Array) -> int:
 var maximum := 0
 for member in members:
  if member is Dictionary:
   maximum = maxi(maximum,int(member.get("fatigue",0)))
 return maximum
