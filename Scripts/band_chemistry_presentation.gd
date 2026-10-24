extends RefCounted
# Read-only presentation of the established index_pair relationship schema.
static func connections(members: Array, relationships: Dictionary) -> Array:
 var result: Array = []
 for i in range(members.size()):
  if not members[i] is Dictionary:
   continue
  for j in range(i + 1, members.size()):
   if not members[j] is Dictionary:
    continue
   if str(members[i].get("life_status","active")) != "active" or str(members[j].get("life_status","active")) != "active":
    continue
   var key := "%d_%d" % [i,j]
   var reverse := "%d_%d" % [j,i]
   if not relationships.has(key) and not relationships.has(reverse):
    continue
   var value := clampi(int(relationships.get(key,relationships.get(reverse,50))),0,100)
   var mood := "CLOSE" if value >= 75 else ("STEADY" if value >= 45 else "STRAINED")
   result.append({"first":str(members[i].get("name","Musician")),"second":str(members[j].get("name","Musician")),"value":value,"mood":mood})
 return result
