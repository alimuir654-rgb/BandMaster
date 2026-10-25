extends SceneTree
const Chapters = preload("res://Scripts/career_chapters.gd")
var failures := 0
func _initialize() -> void:
 var state := {"tour_day":8,"songs":1,"action_counters":{"rehearse":2},"cash":100,"reputation":10}
 var progress := Chapters.progress(state)
 _check(bool(progress.get("ready",false)),"earned chapter ready")
 var first := Chapters.claim(state,str(progress["id"]))
 _check(bool(first.get("ok",false)),"claim succeeds")
 if bool(first.get("ok",false)):
  var after: Dictionary = first["state"]
  _check(after["cash"]==120,"cash credited")
  _check(after["reputation"]==12,"reputation credited")
  _check(not bool(Chapters.claim(after,str(progress["id"])).get("ok",true)),"double claim rejected")
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains("CHAPTER COMPLETE  /  REWARD CLAIMED"),"reward confirmation visible")
 _check(src.contains('"chapter:"+chapter_id'),"claim action identifies chapter")
 _check(src.contains("OF %d OBJECTIVES COMPLETE"),"progress shown")
 _check(src.contains("REWARD  /  £%d  +%d REPUTATION"),"reward complete")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene compiles")
 if failures==0:
  print("V123 CHAPTER REWARDS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V123 FAILURE: "+reason)
