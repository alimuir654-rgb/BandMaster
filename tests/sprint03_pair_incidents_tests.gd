extends SceneTree
# Deterministic pair cases, persistence, guards, and legacy compatibility.
const Drama = preload("res://Scripts/band_drama.gd")
var failures := 0

func _initialize() -> void:
 var state := _fixture()
 var original := JSON.stringify(state)
 var cases: Array = Drama.pair_pending(state)
 _check(cases.size() == 1,"eligible pair offers exactly one prioritised case")
 if cases.is_empty():
  quit(1)
  return
 var incident: Dictionary = cases[0]
 _check(str(incident["kind"]) == "road_pressure","high fatigue prioritises road argument")
 _check(str(incident["intro"]).contains("Jo") and str(incident["intro"]).contains("Lee"),"real member names used")
 _check(int(incident["trust"]) == 38,"pair trust comes from existing relationship")
 _check(not bool(Drama.resolve_pair(state,str(incident["id"]),"invalid").get("ok",true)),"invalid option cannot charge day")
 var outcome: Dictionary = Drama.resolve_pair(state,str(incident["id"]),"mediate")
 _check(bool(outcome.get("ok",false)),"mediation resolves")
 if not bool(outcome.get("ok",false)):
  quit(1)
  return
 var next: Dictionary = outcome["state"]
 _check(int(next["tour_day"]) == 11,"intervention costs one day")
 _check(int(next["relationships"]["0_1"]) == 48,"only actual pair trust increases")
 _check(int(next["relationships"]["0_2"]) == 82,"unrelated trust unchanged")
 _check(int(next["members"][0]["fatigue"]) == 64 and int(next["members"][1]["fatigue"]) == 50,"specific pair recovers fatigue")
 _check(int(next["members"][2]["fatigue"]) == 15,"third member not affected")
 _check(int(next["tension"]) == 20 and int(next["readiness"]) == 58,"trade-off stats applied")
 _check(str(next["career_journal"].back()["text"]).contains("Jo & Lee"),"journal records actual pair")
 _check(JSON.stringify(state) == original,"engine does not mutate original state")
 _check(not bool(Drama.resolve_pair(next,str(incident["id"]),"mediate").get("ok",true)),"no repeated resolution payout")
 var persisted = JSON.parse_string(JSON.stringify(next))
 _check(persisted is Dictionary,"state JSON roundtrip")
 if persisted is Dictionary:
  _check(bool(persisted["band_drama_resolved"].has(str(incident["id"]))),"resolution survives reload")
  _check(not Drama.pair_pending(persisted).is_empty(),"other pending story can remain")
  _check(not bool(Drama.resolve_pair(persisted,str(incident["id"]),"push").get("ok",true)),"cannot switch decision after reload")
 var hard_choice: Dictionary = Drama.resolve_pair(state,str(incident["id"]),"push")
 _check(bool(hard_choice.get("ok",false)),"schedule-first option available")
 if bool(hard_choice.get("ok",false)):
  _check(int(hard_choice["state"]["relationships"]["0_1"]) == 30,"hard choice strains trust")
  _check(int(hard_choice["state"]["readiness"]) == 64,"hard choice gains readiness")
 var fresh := _fixture()
 fresh["tour_day"] = 7
 fresh["members"][0]["fatigue"] = 20
 fresh["members"][1]["fatigue"] = 20
 var rehearsal: Array = Drama.pair_pending(fresh)
 _check(rehearsal.size() == 1 and str(rehearsal[0]["kind"]) == "rehearsal_resentment","early rehearsal dispute triggered by real bond")
 if not rehearsal.is_empty():
  var share := Drama.resolve_pair(fresh,str(rehearsal[0]["id"]),"listen")
  _check(bool(share.get("ok",false)) and int(share["state"]["relationships"]["0_1"]) == 50,"rehearsal compromise repairs bond")
 var early := _fixture()
 early["tour_day"] = 2
 _check(Drama.pair_pending(early).is_empty(),"no premature conflict")
 var unavailable := _fixture()
 unavailable["members"][1]["life_status"] = "unavailable"
 _check(Drama.pair_pending(unavailable).is_empty(),"inactive member never enters pair dispute")
 var low_lineup := _fixture()
 low_lineup["members"] = [low_lineup["members"][0]]
 _check(Drama.pair_pending(low_lineup).is_empty(),"solo member cannot trigger pair case")
 var swapped := _fixture()
 swapped["band_drama_resolved"] = {str(incident["id"]):"mediate"}
 swapped["members"][1]["name"] = "Replacement"
 _check(not Drama.pair_pending(swapped).is_empty(),"legacy replacement does not inherit another person's case")
 var legacy := _fixture()
 legacy.erase("relationships")
 legacy.erase("band_drama_resolved")
 _check(not Drama.pair_pending(legacy).is_empty(),"missing relationship fields safely default")
 var previous: Dictionary = Drama.resolve(state,"exhausted","rest")
 _check(bool(previous.get("ok",false)),"existing generic drama still resolves")
 _check(int(previous["state"]["tour_day"]) == 11,"old event costs one day as before")
 if failures == 0:
  print("SPRINT 03 PAIR INCIDENTS PASSED")
 quit(0 if failures == 0 else 1)

func _fixture() -> Dictionary:
 return {
  "tour_day":10,"cash":90,"songs":2,"tension":26,"morale":55,"readiness":60,
  "members":[
   {"name":"Jo","role":"Guitarist","life_status":"active","fatigue":74,"loyalty":55,"morale":52},
   {"name":"Lee","role":"Drummer","life_status":"active","fatigue":60,"loyalty":55,"morale":54},
   {"name":"Kit","role":"Vocalist","life_status":"active","fatigue":15,"loyalty":70,"morale":68}
  ],
  "relationships":{"0_1":38,"0_2":82,"1_2":84},
  "band_drama_resolved":{},"career_journal":[]
 }

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("PAIR INCIDENT FAILURE: "+reason)
