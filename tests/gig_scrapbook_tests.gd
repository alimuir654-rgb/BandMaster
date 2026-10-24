extends SceneTree
const Story = preload("res://Scripts/career_story.gd")
const Scrapbook = preload("res://Scripts/scrapbook_filter.gd")
var failures := 0
func _initialize() -> void:
 var base := {"tour_day":2,"gig_history":[],"career_journal":[],"fans":0,"songs":0}
 var first := base.duplicate(true)
 first["tour_day"] = 3
 first["gig_history"] = [{"venue":"Lantern Room","city":"Hometown","day":3,"success":true}]
 var after: Dictionary = Story.observe(base,first,"gig:local")
 _check(Scrapbook.select(after.get("career_journal",[]),"GIGS").size() == 2,"opening show and gig clipping")
 _check(str(after["career_journal"].back().get("title","")).contains("Lantern Room"),"venue visible")
 var second := after.duplicate(true)
 second["tour_day"] = 5
 second["gig_history"].append({"venue":"Copper Fox","city":"Bristol","day":5,"success":false,"session_drummer":true})
 var next: Dictionary = Story.observe(after,second,"gig:bristol")
 var gigs: Array = Scrapbook.select(next.get("career_journal",[]),"GIGS")
 _check(gigs.size() == 3,"later show added without replacing history")
 _check(str(gigs[0].get("text","")).contains("session drummer"),"session details retained")
 _check(int(gigs[0].get("day",0)) == 5,"correct show day")
 _check(Story.observe(next,next,"gig:bristol")["career_journal"].size() == next["career_journal"].size(),"repeat observation does not duplicate")
 _check(first["career_journal"].is_empty(),"previous state is not mutated")
 _check(JSON.parse_string(JSON.stringify(next)) is Dictionary,"save compatibility")
 if failures == 0:
  print("GIG SCRAPBOOK TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error("GIG SCRAPBOOK FAILURE: "+label)
