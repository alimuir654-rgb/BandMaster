extends SceneTree
const Game = preload("res://experiments/playable_flightcase/session.gd")
var checks := 0
var failures: Array[String] = []
func _init() -> void:
 call_deferred("run_tests")
func check(ok: bool,msg: String) -> void:
 checks += 1
 if not ok:
  failures.append(msg)
  push_error(msg)
func run_tests() -> void:
 var game = Game.new()
 check(game.remaining()==200 and game.spent()==0,"initial talent 200")
 check(game.choices("Singer").size()==6 and game.choices("Guitarist").size()==6,"C25 plus canonical singer/guitar anchors")
 check(game.choices("Bassist").size()==3 and game.choices("Keyboardist").size()==3 and game.choices("Drummer").size()==3,"three bass keys drums")
 check(game.person_by_id("alex")["name"]=="Alex Vale" and game.person_by_id("nia_griffiths")["name"]=="Nia Griffiths","unchanged canonical identities")
 check(not game.recruit("nonexistent").get("ok",true),"unknown fails")
 check(not game.rehearse().get("ok",true),"rehearsal blocked before formation")
 var empty := JSON.stringify(game.snapshot())
 check(not game.launch().get("ok",true) and JSON.stringify(game.snapshot())==empty,"invalid formation state unchanged")
 for id in ["cast_maya","cast_jack","cast_zoe","cast_dan","cast_casey"]:
  check(game.recruit(id).get("ok",false),"recruited "+id)
 check(game.spent()==178 and game.remaining()==22,"correct source scores and overhead")
 var before := JSON.stringify(game.snapshot())
 check(not game.recruit("cast_jack").get("ok",true) and JSON.stringify(game.snapshot())==before,"duplicate no double spend")
 var removed: Dictionary = game.remove_member("cast_casey")
 check(removed.get("ok",false) and int(removed.get("refunded",-1))==43 and game.spent()==135,"removal refunds fifth overhead")
 check(not game.remove_member("cast_casey").get("ok",true) and game.spent()==135,"no second refund")
 check(game.recruit("cast_casey").get("ok",false) and game.spent()==178,"re-add same total")
 check(game.can_start() and game.launch().get("ok",false),"viable line-up launches")
 check(game.phase=="play" and game.career["members"].size()==5 and game.career["members"][0]["candidate_id"]=="cast_maya","real selected roster in career")
 check(not game.launch().get("ok",true) and not game.remove_member("cast_maya").get("ok",true),"once-only transition")
 var state_before := JSON.stringify(game.career)
 check(not game.write_session("INVALID","Verse / Chorus","FIRST SONG",0).get("ok",true) and JSON.stringify(game.career)==state_before,"invalid song action no state change")
 for i in range(3):
  check(game.write_session("Riff","Verse / Chorus","THE LAST BUS HOME",0).get("ok",false),"writing session "+str(i+1))
 check(int(game.career["songs"])==1 and game.career["song_catalogue"].size()==1,"three sessions one song")
 check(str(game.career["song_catalogue"][0]["title"])=="THE LAST BUS HOME","song title persisted")
 check(int(game.career["tour_day"])==4,"three real writing days")
 check(not game.write_session("Riff","Verse / Chorus","THE LAST BUS HOME",0).get("ok",true),"duplicate finished title rejected")
 var readiness_before := int(game.career["readiness"])
 check(game.rehearse().get("ok",false) and int(game.career["readiness"])>readiness_before,"rehearsal affects real readiness")
 check(int(game.career["cash"])==235,"rehearsal £15 spent once")
 check(game.clear_air().get("ok",false) and int(game.career["tour_day"])==6,"conversation costs a day")
 var snapshot := game.snapshot()
 check(game.save_sandbox(),"sandbox save")
 var loaded = Game.new()
 var loaded_ok: bool = loaded.load_sandbox()
 var expected_text: String = JSON.stringify(snapshot)
 var actual_text: String = JSON.stringify(loaded.snapshot())
 print("C26_SAVE_DEBUG loaded=",loaded_ok," lengths=",expected_text.length(),"/",actual_text.length())
 var first_diff := -1
 for index in range(mini(expected_text.length(),actual_text.length())):
  if expected_text[index] != actual_text[index]:
   first_diff = index
   break
 if first_diff >= 0:
  print("C26_SAVE_DIFF ",first_diff," before=",expected_text.substr(maxi(0,first_diff-30),150)," after=",actual_text.substr(maxi(0,first_diff-30),150))
 check(loaded_ok and actual_text==expected_text,"sandbox restart exact state")
 check(typeof(loaded.career.get("cash",0))==TYPE_INT and typeof(loaded.career.get("action_counters",{}).get("rehearse",0))==TYPE_INT,"nested integer schema survives Godot JSON load")
 check(not loaded.restore({"schema_version":1,"roster":[{"id":"evil"}],"phase":"play"}),"corrupt roster rejected")
 check(JSON.stringify(loaded.snapshot())==JSON.stringify(snapshot),"failed restore non-mutating")
 var stars = Game.new()
 for id in ["cast_sam","cast_bex","cast_ben","cast_dan"]:
  check(stars.recruit(id).get("ok",false),"star lineup partial "+id)
 check(not stars.recruit("cast_ellis").get("ok",true),"both stars plus five roles too expensive")
 check(stars.remaining()==32,"no overspend from blocked star line-up")
 var risky = Game.new()
 for id in ["cast_sam","cast_ryan","cast_zoe","cast_dan","cast_ellis"]:
  check(risky.recruit(id).get("ok",false),"risky lineup "+id)
 check(risky.launch().get("ok",false),"risky line-up viable")
 var prev_tension := int(risky.career["tension"])
 check(risky.write_session("Riff","Verse / Chorus","UNSENT LETTERS",0).get("ok",false),"risky composition succeeds")
 check(int(risky.career["tension"])>=prev_tension+4,"Sam authored collaboration friction changes play")
 var result: Dictionary = risky.rehearse()
 check(result.get("ok",false) and str(result["message"]).contains("Missed preparation"),"wildcard missed practice consequence visible")
 print("C26_GAMEPLAY_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"sandbox_save_only":Game.SAVE_PATH}))
 quit(0 if failures.is_empty() else 1)
