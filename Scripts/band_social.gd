extends RefCounted
# Social activities consume real career days and money, affect people and history.
const ACTIVITIES := {
 "dinner":{"label":"DINNER TOGETHER","cost_per_member":8,"morale":5,"tension":-4,"trust":5,"buzz":0,"text":"A meal away from the rehearsal room helps everyone talk honestly."},
 "drinks":{"label":"DRINKS AFTER PRACTICE","cost_per_member":6,"morale":7,"tension":-2,"trust":3,"buzz":0,"text":"An evening at the pub brings laughter, loose plans and a few stories."},
 "watch_gig":{"label":"WATCH ANOTHER BAND","cost_per_member":5,"morale":3,"tension":-1,"trust":2,"buzz":3,"text":"Seeing another local act gives the band fresh ideas and something to aim for."}
}
static func attend(state: Dictionary, activity_id: String) -> Dictionary:
 if not ACTIVITIES.has(activity_id):
  return {"ok":false,"message":"Unknown band outing."}
 var roster: Array = state.get("members",[])
 var present: Array = []
 for i in range(roster.size()):
  if roster[i] is Dictionary and str(roster[i].get("life_status","active")) == "active":
   present.append(i)
 if present.size() < 2:
  return {"ok":false,"message":"At least two available bandmates must join the outing."}
 var rule: Dictionary = ACTIVITIES[activity_id]
 var total_cost := int(rule["cost_per_member"]) * present.size()
 if int(state.get("cash",0)) < total_cost:
  return {"ok":false,"message":"The band needs £%d to cover everyone." % total_cost}
 var next := state.duplicate(true)
 next["cash"] = int(next.get("cash",0)) - total_cost
 next["tour_day"] = int(next.get("tour_day",1)) + 1
 next["morale"] = clampi(int(next.get("morale",50))+int(rule["morale"]),0,100)
 next["tension"] = clampi(int(next.get("tension",0))+int(rule["tension"]),0,100)
 next["buzz"] = clampi(int(next.get("buzz",0))+int(rule["buzz"]),0,100)
 var members: Array = next.get("members",[])
 for index in present:
  var person: Dictionary = members[int(index)]
  person["morale"] = clampi(int(person.get("morale",55))+int(rule["morale"]),0,100)
  person["loyalty"] = clampi(int(person.get("loyalty",60))+2,0,100)
  person["fatigue"] = clampi(int(person.get("fatigue",0))+(5 if activity_id == "drinks" else -3),0,100)
 var relationships: Dictionary = next.get("relationships",{}).duplicate(true)
 for a in range(present.size()):
  for b in range(a+1,present.size()):
   var x: int = int(present[a])
   var y: int = int(present[b])
   var key := "%d_%d" % [mini(x,y),maxi(x,y)]
   relationships[key] = clampi(int(relationships.get(key,50))+int(rule["trust"]),0,100)
 next["relationships"] = relationships
 if activity_id == "watch_gig":
  next["readiness"] = clampi(int(next.get("readiness",0))+2,0,100)
 var counts: Dictionary = next.get("social_counters",{}).duplicate(true)
 counts[activity_id] = int(counts.get(activity_id,0))+1
 next["social_counters"] = counts
 var history: Array = next.get("career_journal",[]).duplicate(true)
 history.append({"id":"outing:%s:%d" % [activity_id,int(next["tour_day"])],"day":int(next["tour_day"]),"title":str(rule["label"]),"text":str(rule["text"]),"kind":"band"})
 while history.size()>80:
  history.pop_front()
 next["career_journal"] = history
 return {"ok":true,"state":next,"message":str(rule["text"])+" £%d spent; one day passes." % total_cost}
