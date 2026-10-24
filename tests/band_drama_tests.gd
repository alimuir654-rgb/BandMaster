extends SceneTree
const Drama = preload("res://Scripts/band_drama.gd")
var failures := 0
func _initialize() -> void:
 var base := {"tour_day":15,"songs":3,"cash":20,"tension":30,"morale":55,"readiness":50,"members":[{"name":"Alex","morale":55,"loyalty":60,"fatigue":70},{"name":"Mick","morale":45,"loyalty":55,"fatigue":20}],"career_journal":[]}
 var pending: Array = Drama.pending(base)
 _check(pending.size() == 3,"all three conflicts are available")
 for event_id in pending:
  var definition: Dictionary = Drama.EVENTS[event_id]
  for option in definition["choices"]:
   var choice: String = str(option["id"])
   var result: Dictionary = Drama.resolve(base,str(event_id),choice)
   _check(bool(result.get("ok",false)),"valid option resolves")
   if not result.get("ok",false):
    continue
   var next: Dictionary = result["state"]
   _check(next["tour_day"] == 16,"event consumes one day")
   _check(not Drama.pending(next).has(event_id),"event cannot repeat")
   _check(next["career_journal"].size() == 1,"story memory recorded")
   _check(JSON.parse_string(JSON.stringify(next)) is Dictionary,"save JSON round-trip")
   _check(base["career_journal"].is_empty(),"original state stays immutable")
   _check(int(next["cash"]) >= 0,"no negative cash")
   for member in next["members"]:
    _check(int(member["loyalty"]) >= 0 and int(member["loyalty"]) <= 100,"loyalty bounded")
 _check(not Drama.resolve(base,"creative_clash","bogus").get("ok",true),"invalid choice rejected")
 _check(not Drama.resolve(base,"bogus","share").get("ok",true),"invalid event rejected")
 var no_band := base.duplicate(true)
 no_band["members"] = []
 _check(Drama.pending(no_band).is_empty(),"no events without a band")
 if failures == 0:
  print("BAND DRAMA TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("BAND DRAMA FAILURE: "+detail)
