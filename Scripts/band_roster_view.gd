extends RefCounted
# Display ordering only: never mutate the canonical members array or game indices.
const MODES := ["LINEUP","SKILL","FATIGUE","LOYALTY"]

static func sorted_indices(members: Array, mode: String) -> Array[int]:
 var indices: Array[int] = []
 for i in range(members.size()):
  if members[i] is Dictionary:
   indices.append(i)
 if not MODES.has(mode) or mode == "LINEUP":
  return indices
 var key := mode.to_lower()
 indices.sort_custom(func(left: int,right: int) -> bool:
  var a: int = int(members[left].get(key,0))
  var b: int = int(members[right].get(key,0))
  if a == b:
   return left < right
  return a > b
 )
 return indices
