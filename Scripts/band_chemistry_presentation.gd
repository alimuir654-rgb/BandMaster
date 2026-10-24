extends RefCounted
# Read-only relationship presentation. Index keys match the existing simulation.
static func connections(members: Array, relationships: Dictionary) -> Array:
 var result: Array = []
 for a in range(members.size()):
  if not members[a] is Dictionary or str(members[a].get("life_status","active")) != "active":
   continue
  for b in range(a+1,members.size()):
   if not members[b] is Dictionary or str(members[b].get("life_status","active")) != "active":
    continue
   var key := "%d_%d" % [a,b]
   var value := clampi(int(relationships.get(key,50)),0,100)
   var label := "CREATIVE SPARK" if value >= 75 else ("SOLID PARTNERSHIP" if value >= 55 else ("FRICTION" if value < 35 else "STILL CONNECTING"))
   result.append({"first":str(members[a].get("name","Musician")),"second":str(members[b].get("name","Musician")),"score":value,"label":label})
 return result

static func summary(connections_list: Array) -> String:
 if connections_list.is_empty():
  return "Recruit another active musician to build a band dynamic."
 var total := 0
 for item in connections_list:
  total += int(item.get("score",50))
 var average := int(round(float(total)/float(connections_list.size())))
 if average >= 75:
  return "The lineup is clicking. Keep nurturing that chemistry."
 if average < 35:
  return "Relationships are strained. Time together could help."
 return "Your band's chemistry is still taking shape."
