extends SceneTree
const Life = preload("res://Scripts/member_life.gd")
var failed := 0
func _initialize() -> void:
 var base := {"tour_day":85,"cash":80,"members":[{"name":"Alex","role":"Drummer","loyalty":20,"morale":60,"fatigue":5},{"name":"Sam","role":"Bassist","loyalty":75,"morale":60,"fatigue":85},{"name":"Robin","role":"Guitarist","loyalty":50,"morale":15,"fatigue":10}],"career_journal":[]}
 var events := Life.pending(base)
 _check(events.size() == 3,"three life events discovered")
 var departure := Life.resolve(base,0,"career","depart")
 _check(departure.get("ok",false),"career departure accepted")
 if departure.get("ok",false):
  var next: Dictionary = departure["state"]
  _check(next["members"].size() == 2,"member leaves roster")
  _check(next["former_members"].size() == 1,"former member archived")
  _check(next["former_members"][0]["reason"] == "left for a full-time career","reason preserved")
  _check(JSON.parse_string(JSON.stringify(next)) is Dictionary,"save roundtrip")
  _check(base["members"].size() == 3,"source immutable")
  var recruit := Life.recruit(next)
  _check(recruit.get("ok",false),"replacement recruited")
  if recruit.get("ok",false):
   _check(recruit["state"]["members"].size() == 3,"lineup restored")
 var leave := Life.resolve(base,1,"injury","recover")
 _check(leave.get("ok",false),"injured musician gets leave")
 if leave.get("ok",false):
  var before: Dictionary = leave["state"]
  _check(before["members"][1]["life_status"] == "leave","member is on leave")
  var passed: Dictionary = before.duplicate(true)
  passed["tour_day"] = int(before["members"][1]["available_day"])
  var back := Life.refresh(passed)
  _check(back["members"][1]["life_status"] == "active","member returns after recovery")
  _check(before["members"][1]["life_status"] == "leave","refresh does not mutate input")
 var poor := base.duplicate(true)
 poor["cash"] = 0
 _check(not Life.resolve(poor,1,"injury","specialist").get("ok",true),"unaffordable option rejected")
 _check(not Life.resolve(base,0,"career","invalid").get("ok",true),"invalid option rejected")
 _check(not Life.resolve(base,1,"career","depart").get("ok",true),"invalid event/member combination rejected")
 var no_band := base.duplicate(true)
 no_band["members"] = []
 _check(Life.pending(no_band).is_empty(),"empty band safe")
 var capped := base.duplicate(true)
 var capped_roster: Array = capped["members"]
 while capped_roster.size() < 6:
  capped_roster.append({"name":"Extra","role":"Guitarist"})
 _check(not Life.recruit(capped).get("ok",true),"maximum line-up enforced")
 if failed == 0:
  print("MEMBER LIFE TESTS PASSED")
 quit(0 if failed == 0 else 1)
func _check(condition: bool, detail: String) -> void:
 if not condition:
  failed += 1
  push_error("MEMBER LIFE FAILURE: "+detail)
