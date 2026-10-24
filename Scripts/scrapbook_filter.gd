extends RefCounted
# Pure scrapbook selectors; never changes save data.
const FILTERS := ["ALL","BAND","GIGS","MILESTONES"]
static func select(entries: Array, filter_name: String = "ALL", limit: int = 20) -> Array:
 var selected: Array = []
 if not FILTERS.has(filter_name):
  return selected
 for i in range(entries.size()-1,-1,-1):
  if not entries[i] is Dictionary:
   continue
  var item: Dictionary = entries[i]
  var kind := str(item.get("kind","career"))
  var include := filter_name == "ALL" or (filter_name == "BAND" and kind == "band") or (filter_name == "GIGS" and kind == "gig") or (filter_name == "MILESTONES" and kind == "milestone")
  if include:
   selected.append(item.duplicate(true))
   if selected.size() >= maxi(1,limit):
    break
 return selected
