extends SceneTree
const Recording = preload("res://Scripts/recording_career.gd")
var failures := 0
func _initialize() -> void:
 var state := {"cash":160,"tour_day":5,"fans":12,"press":0,"buzz":18,"readiness":55,"song_catalogue":[{"title":"ONE","quality":55},{"title":"TWO","quality":70}],"career_journal":[]}
 var snapshot := JSON.stringify(state)
 _check(not Recording.can_record({"cash":160,"song_catalogue":[]})["ok"],"two tracks required")
 var rec: Dictionary = Recording.record(state)
 _check(bool(rec.get("ok",false)),"record two tracks")
 _check(JSON.stringify(state)==snapshot,"does not mutate original")
 if bool(rec.get("ok",false)):
  var made: Dictionary = rec["state"]
  _check(int(made["cash"])==100 and int(made["tour_day"])==7,"studio days and cash")
  _check(not bool(Recording.record(made).get("ok",false)),"cannot farm same tracks")
  var released: Dictionary = Recording.release(made,0)
  _check(bool(released.get("ok",false)),"local release")
  if bool(released.get("ok",false)):
   var after: Dictionary = released["state"]
   _check(int(after["cash"])==75 and int(after["tour_day"])==8,"release day and cost")
   _check(int(after["fans"])>12 and int(after["press"])>0,"measurable audience")
   _check(not bool(Recording.release(after,0).get("ok",false)),"release once")
   _check(JSON.parse_string(JSON.stringify(after)) is Dictionary,"saved JSON")
  made["song_catalogue"].append({"title":"THREE","quality":80})
  _check(bool(Recording.record(made).get("ok",false)),"new material unlocks studio")
 _check(not bool(Recording.release(state,0).get("ok",false)),"unrecorded cannot release")
 if failures==0:
  print("V27 RECORDING CAREER TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, description: String) -> void:
 if not ok:
  failures+=1
  push_error("V27 RECORDING FAILURE: "+description)
