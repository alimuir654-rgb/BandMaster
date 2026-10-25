extends RefCounted
# Deterministic, bounded songwriting chemistry. Only active bandmates take part.
static func calculate(state: Dictionary) -> Dictionary:
 var roster: Array = state.get("members",[])
 var relationships: Dictionary = state.get("relationships",{})
 var active: Array = []
 for i in range(roster.size()):
  if roster[i] is Dictionary and str(roster[i].get("life_status","active")) == "active":
   active.append(i)
 if active.size() < 2:
  return {"bonus":0,"score":0,"label":"NOT ENOUGH ACTIVE MUSICIANS"}
 var total := 0
 var pairs := 0
 for a in range(active.size()):
  for b in range(a+1,active.size()):
   var left: int = int(active[a])
   var right: int = int(active[b])
   var key := "%d_%d" % [mini(left,right),maxi(left,right)]
   total += clampi(int(relationships.get(key,50)),0,100)
   pairs += 1
 var average := int(round(float(total)/float(maxi(1,pairs))))
 var tension := clampi(int(state.get("tension",0)),0,100)
 var effective := clampi(average - int(tension / 4.0),0,100)
 var bonus := 3 if effective >= 75 else (1 if effective >= 55 else 0)
 return {"bonus":bonus,"score":effective,"label":"IN SYNC" if bonus == 3 else ("FINDING THEIR SOUND" if bonus == 1 else "CREATIVE FRICTION")}
