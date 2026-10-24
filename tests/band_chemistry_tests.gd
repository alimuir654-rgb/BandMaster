extends SceneTree
const Actions = preload("res://Scripts/career_actions.gd")
var failures := 0
func _initialize() -> void:
 var base := {"cash":100,"tour_day":2,"readiness":30,"morale":55,"tension":20,"songs":0,"members":[{"name":"Ash","role":"Drummer","trait":"Reliable","skill":35,"fatigue":10},{"name":"Jo","role":"Guitarist","trait":"Creative","skill":45,"fatigue":20},{"name":"Sam","role":"Bassist","trait":"Perfectionist","skill":50,"fatigue":12}]}
 var rehearsal: Dictionary = Actions.resolve(base,"rehearse")
 _check(rehearsal.get("ok",false),"rehearsal resolves")
 if rehearsal.get("ok",false):
  var state: Dictionary = rehearsal["state"]
  _check(int(state["readiness"]) > 39,"traits increase preparation")
  _check(int(state["members"][0]["skill"]) == 37,"rehearsal builds personal skill")
  _check(int(state["members"][1]["fatigue"]) == 26,"rehearsals consume energy")
  _check(state.get("career_journal",[]).size() == 1,"first rehearsal remembered")
  var repeated: Dictionary = Actions.resolve(state,"rehearse")
  _check(repeated.get("ok",false) and repeated["state"]["career_journal"].size() == 1,"rehearsal memory is unique")
 var writing: Dictionary = Actions.resolve(base,"songwrite")
 _check(writing.get("ok",false),"songwriting resolves")
 if writing.get("ok",false):
  _check(int(writing["state"]["songs"]) == 1,"new song created")
  _check(writing["state"].get("song_catalogue",[]).size() == 1,"original song saved")
  _check(writing["state"]["song_catalogue"][0]["writers"].size() == 3,"all available writers credited")
  _check(int(writing["state"]["song_catalogue"][0]["quality"]) > 0,"song quality assigned")
  _check(int(writing["state"]["readiness"]) >= 35,"creative traits help songwriting")
  _check(JSON.parse_string(JSON.stringify(writing["state"])) is Dictionary,"JSON persistence")
 _check(int(base["members"][0]["skill"]) == 35,"input state is immutable")
 _check(base.get("song_catalogue",[]).is_empty(),"song catalogue is immutable")
 var unavailable := base.duplicate(true)
 unavailable["members"][1]["life_status"] = "leave"
 var result: Dictionary = Actions.resolve(unavailable,"rehearse")
 _check(result.get("ok",false),"two remaining bandmates can rehearse")
 if result.get("ok",false):
  _check(int(result["state"]["members"][1]["fatigue"]) == 20,"absent musician does not tire")
 var solo := base.duplicate(true)
 solo["members"] = [base["members"][0]]
 _check(not Actions.resolve(solo,"rehearse").get("ok",true),"solo rehearsal refused")
 if failures == 0:
  print("BAND CHEMISTRY TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(condition: bool, detail: String) -> void:
 if not condition:
  failures += 1
  push_error("CHEMISTRY FAILURE: "+detail)
