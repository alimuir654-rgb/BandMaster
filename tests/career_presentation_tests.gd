extends SceneTree
const Presentation = preload("res://Scripts/career_presentation.gd")
var failures := 0
func _initialize() -> void:
 var source := {"tour_day":12,"members":[{"name":"Jo","trait":"Creative","loyalty":65,"fatigue":10},{"name":"Alex","trait":"Reliable","loyalty":55,"fatigue":75}]}
 var jo: Dictionary = Presentation.line(source,0)
 _check(bool(jo.get("ok",false)),"member dialogue available")
 _check(str(jo.get("speaker","")) == "Jo","speaker consistent")
 var exhausted: Dictionary = Presentation.line(source,1)
 _check(str(exhausted.get("text","")).contains("running on empty"),"exhaustion affects dialogue")
 _check(not Presentation.line(source,7).get("ok",true),"invalid index rejected")
 var moment := {"day":8,"title":"First show","text":"The Lantern Room","kind":"gig"}
 var clip: Dictionary = Presentation.clipping(moment)
 _check(clip["rubric"] == "LIVE REVIEW","gig clipping is classified")
 _check(clip["day"] == 8,"day retained")
 _check(JSON.parse_string(JSON.stringify(jo)) is Dictionary,"dialogue is save compatible")
 _check(source["members"][0]["fatigue"] == 10,"source untouched")
 if failures == 0:
  print("PRESENTATION TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("PRESENTATION FAILURE: "+detail)
