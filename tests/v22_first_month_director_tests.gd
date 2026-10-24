extends SceneTree
const Director = preload("res://Scripts/first_month_director.gd")
const Chapters = preload("res://Scripts/career_chapters.gd")
var failures := 0
func _initialize() -> void:
 var base := {"tour_day":1,"songs":0,"song_draft_progress":1,"gig_history":[],"fans":0,"readiness":40,"action_counters":{"rehearse":0},"career_chapters_claimed":{}}
 _expect(base,"ACTIONS","FIND YOUR SOUND")
 var drafting := base.duplicate(true)
 drafting["songs"] = 1
 _expect(drafting,"ACTIONS","TIGHTEN THE SET")
 var rehearsed := drafting.duplicate(true)
 rehearsed["action_counters"]["rehearse"] = 2
 _expect(rehearsed,"HOME","CHAPTER COMPLETE")
 var first_claim: Dictionary = Chapters.claim(rehearsed,"find_sound")
 _check(bool(first_claim.get("ok",false)),"first chapter can be claimed")
 if first_claim.get("ok",false):
  var next: Dictionary = first_claim["state"]
  _expect(next,"GIGS","PLAY TO STRANGERS")
  next["booked_show"] = {"day":4,"venue":"The Lantern Room"}
  _expect(next,"ACTIONS","PREPARE FOR THE SHOW")
  next["tour_day"] = 4
  _expect(next,"GIGS","SHOW NIGHT")
  next["booked_show"] = {}
  next["gig_history"] = [{"venue":"The Toadstool","day":4}]
  _expect(next,"SCENE","BUILD A FOLLOWING")
  next["fans"] = 15
  _expect(next,"HOME","CHAPTER COMPLETE")
 _check(JSON.stringify(base) == JSON.stringify({"tour_day":1,"songs":0,"song_draft_progress":1,"gig_history":[],"fans":0,"readiness":40,"action_counters":{"rehearse":0},"career_chapters_claimed":{}}),"guidance never mutates state")
 var all_done := base.duplicate(true)
 all_done["career_chapters_claimed"] = {"find_sound":1,"first_crowd":2,"local_noise":10,"earn_stripes":20,"first_month":30}
 _expect(all_done,"GIGS","BUILD YOUR CAREER")
 if failures == 0:
  print("V22 FIRST MONTH DIRECTOR TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _expect(state: Dictionary, tab: String, title: String) -> void:
 var result: Dictionary = Director.next_move(state)
 _check(str(result.get("tab","")) == tab,"tab "+title)
 _check(str(result.get("title","")) == title,"guidance "+title)
 _check(not str(result.get("detail","")).is_empty(),"nonempty description")
func _check(ok: bool, description: String) -> void:
 if not ok:
  failures += 1
  push_error("V22 DIRECTOR FAILURE: "+description)
