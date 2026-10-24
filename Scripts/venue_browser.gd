extends RefCounted
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")

static func entries(state: Dictionary, show_locked: bool = false) -> Array:
 var result: Array = []
 var fans := int(state.get("fans",0))
 var rep := int(state.get("reputation",0))
 for venue in Gigs.VENUES:
  var missing_fans := maxi(0,int(venue["min_fans"])-fans)
  var missing_rep := maxi(0,int(venue["min_rep"])-rep)
  var locked := missing_fans>0 or missing_rep>0
  if locked != show_locked:
   continue
  result.append({"id":str(venue["id"]),"title":str(venue["venue"]),"city":str(venue["city"]),"locked":locked,"fee":int(venue["fee"]),"travel":int(venue["travel"]),"missing_fans":missing_fans,"missing_rep":missing_rep})
 return result

static func pick(entries_list: Array, selected: String) -> String:
 for item in entries_list:
  if str(item.get("id",""))==selected:
   return selected
 return str(entries_list[0].get("id","")) if not entries_list.is_empty() else ""
