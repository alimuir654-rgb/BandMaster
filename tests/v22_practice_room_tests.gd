extends SceneTree
const Practice = preload("res://Scripts/practice_room.gd")
var failures := 0
func _initialize() -> void:
 var initial := {"cash":120,"tour_day":1,"morale":60,"tension":35,"readiness":25,"songs":0,"career_journal":[],"relationships":{"0_1":40},"members":[{"name":"Jo","role":"Drummer","trait":"Perfectionist","morale":50,"loyalty":65,"fatigue":10,"skill":40,"life_status":"active"},{"name":"Alex","role":"Guitarist","trait":"Creative","morale":50,"loyalty":60,"fatigue":10,"skill":50,"life_status":"active"}]}
 var drill: Dictionary = Practice.resolve(initial,"tighten")
 _check(drill.get("ok",false),"set drill resolves")
 if drill.get("ok",false):
  _check(int(drill["state"]["readiness"]) > 25,"drill builds show readiness")
  _check(int(drill["state"]["cash"]) == 105,"rehearsal fee paid once")
  _check(int(drill["state"]["members"][0]["morale"]) > int(drill["state"]["members"][1]["morale"]),"personalities react differently")
 var writing: Dictionary = Practice.resolve(initial,"create")
 _check(writing.get("ok",false),"first songwriting session works")
 if writing.get("ok",false):
  _check(int(writing["state"]["songs"]) == 0,"one session cannot instantly create a song")
  _check(int(writing["state"]["song_draft_progress"]) == 1,"draft remembers progress")
  var second: Dictionary = Practice.resolve(writing["state"],"create")
  _check(second.get("ok",false),"second session advances draft")
  if second.get("ok",false):
   _check(int(second["state"]["song_draft_progress"]) == 2,"second stage tracked")
   var third: Dictionary = Practice.resolve(second["state"],"create")
   _check(third.get("ok",false),"third session finishes the original")
   if third.get("ok",false):
    _check(int(third["state"]["songs"]) == 1,"completed draft produces an original")
    _check(third["state"]["song_catalogue"].size() == 1,"finished song retains credits")
    _check(int(third["state"]["song_draft_progress"]) == 0,"finished song clears draft")
 var bonding: Dictionary = Practice.resolve(initial,"connect")
 _check(bonding.get("ok",false),"bonding works")
 if bonding.get("ok",false):
  _check(int(bonding["state"]["relationships"]["0_1"]) == 46,"bonding restores trust")
  _check(int(bonding["state"]["members"][0]["loyalty"]) == 68,"bonding raises loyalty")
  _check(int(bonding["state"]["tension"]) < 35,"bonding eases tension")
  _check(int(bonding["state"]["tour_day"]) == 2,"bonding consumes one day")
  _check(JSON.parse_string(JSON.stringify(bonding["state"])) is Dictionary,"session persists to JSON")
 _check(not Practice.resolve(initial,"unknown").get("ok",true),"invalid focus rejected")
 var solo := initial.duplicate(true)
 solo["members"][1]["life_status"] = "leave"
 _check(not Practice.resolve(solo,"tighten").get("ok",true),"solo rehearsal cannot bypass lineup rules")
 _check(initial["relationships"]["0_1"] == 40 and initial["members"][0]["morale"] == 50,"source never mutated")
 if failures == 0:
  print("V22 PRACTICE ROOM TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V22 PRACTICE FAILURE: "+detail)
