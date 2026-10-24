extends RefCounted
# Presentation-only formatting for animated decisions; no save-state mutations.
const STAT_LABELS := {"cash":"CASH","tour_day":"DAY","fans":"FANS","reputation":"REPUTATION","readiness":"READINESS","morale":"MORALE","tension":"TENSION","songs":"SONGS","buzz":"BUZZ"}
static func changes(previous: Dictionary, current: Dictionary) -> Array:
 var result: Array = []
 for key in ["tour_day","cash","fans","reputation","readiness","morale","tension","songs","buzz"]:
  var before := int(previous.get(key,0))
  var after := int(current.get(key,0))
  if before != after:
   result.append({"key":key,"label":STAT_LABELS[key],"before":before,"after":after,"delta":after-before})
 return result
static func headline(source: String, successful: bool) -> String:
 if not successful:
  return "NOT THIS TIME"
 if source.begins_with("gig:"):
  return "THE NIGHT IS YOURS"
 return "A DAY IN THE LIFE"
static func delta_text(change: Dictionary) -> String:
 var delta := int(change.get("delta",0))
 return "%s  %s%d" % [str(change.get("label","")).to_upper(),"+" if delta > 0 else "",delta]
