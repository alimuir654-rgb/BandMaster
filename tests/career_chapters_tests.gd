extends SceneTree
const Chapters = preload("res://Scripts/career_chapters.gd")
var failures := 0
func _initialize() -> void:
 var base := {"tour_day":3,"cash":100,"reputation":12,"songs":0,"fans":0,"readiness":45,"action_counters":{},"gig_history":[]}
 _check(Chapters.progress(base)["id"] == "find_sound","first chapter is clear")
 _check(not Chapters.claim(base,"find_sound").get("ok",true),"locked chapter cannot claim")
 var ready := base.duplicate(true)
 ready["songs"] = 1
 ready["action_counters"] = {"rehearse":2}
 _check(bool(Chapters.progress(ready)["ready"]),"first chapter unlocks through play")
 var completed: Dictionary = Chapters.claim(ready,"find_sound")
 _check(completed.get("ok",false),"first chapter claims")
 if completed.get("ok",false):
  var after: Dictionary = completed["state"]
  _check(int(after["cash"]) == 120 and int(after["reputation"]) == 14,"reward granted")
  _check(after["career_journal"].size() == 1,"chapter added to career history")
  _check(Chapters.progress(after)["id"] == "first_crowd","second chapter opens")
  _check(not Chapters.claim(after,"find_sound").get("ok",true),"cannot claim twice")
  _check(JSON.parse_string(JSON.stringify(after)) is Dictionary,"JSON save compatible")
 _check(int(ready["cash"]) == 100 and not ready.has("career_chapters_claimed"),"source immutable")
 var full := base.duplicate(true)
 full["tour_day"] = 31
 full["songs"] = 4
 full["fans"] = 60
 full["readiness"] = 80
 full["action_counters"] = {"rehearse":4}
 full["gig_history"] = [{},{},{},{},{}]
 for entry in Chapters.CHAPTERS:
  var id: String = str(entry["id"])
  var result: Dictionary = Chapters.claim(full,id)
  _check(result.get("ok",false),"chapter claims in order: "+id)
  if result.get("ok",false):
   full = result["state"]
 _check(bool(Chapters.progress(full)["done"]),"all opening chapters complete")
 _check(full["career_journal"].size() == 5,"all chapter memories retained")
 if failures == 0:
  print("FIRST MONTH CHAPTER TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(condition: bool, detail: String) -> void:
 if not condition:
  failures += 1
  push_error("CHAPTER FAILURE: "+detail)
