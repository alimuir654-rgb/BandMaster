extends SceneTree
const Workshop = preload("res://Scripts/song_workshop.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Social = preload("res://Scripts/band_social.gd")
var failures := 0
func _initialize() -> void:
 var base := {"cash":120,"tour_day":1,"songs":0,"morale":50,"tension":20,"readiness":30,"career_journal":[],"relationships":{"0_1":40},"members":[{"name":"Jo","role":"Drummer","trait":"Reliable","skill":50,"morale":50,"loyalty":50,"fatigue":0},{"name":"Alex","role":"Guitarist","trait":"Creative","skill":50,"morale":50,"loyalty":50,"fatigue":0}]}
 var state := base.duplicate(true)
 for i in range(3):
  var attempt: Dictionary = Practice.compose(state,"Riff","Verse / Chorus","NO WAY HOME",1)
  _check(bool(attempt.get("ok",false)),"jam step %d" % i)
  if not attempt.get("ok",false):
   break
  state = attempt["state"]
 _check(int(state.get("songs",0)) == 1,"three creative sessions finish one song")
 _check(int(state.get("song_draft_progress",0)) == 0,"completed draft resets")
 var songs: Array = state.get("song_catalogue",[])
 _check(songs.size() == 1,"song persisted")
 if not songs.is_empty():
  _check(str(songs[0].get("title","")) == "NO WAY HOME","selected title retained")
  _check(str(songs[0].get("lead_writer","")) == "Alex","leader credited")
  _check(songs[0].get("writing_sessions",[]).size() == 3,"jam history retained")
 var meal: Dictionary = Social.attend(base,"dinner")
 _check(bool(meal.get("ok",false)),"dinner possible")
 if meal.get("ok",false):
  _check(int(meal["state"]["cash"]) == 104,"two meals cost £16")
  _check(int(meal["state"]["relationships"]["0_1"]) == 45,"meal builds trust")
  _check(int(meal["state"]["tour_day"]) == 2,"outing spends day")
 var show: Dictionary = Social.attend(base,"watch_gig")
 _check(bool(show.get("ok",false)),"watching local act possible")
 if show.get("ok",false):
  _check(int(show["state"].get("buzz",0)) == 3,"local gig inspires and creates buzz")
  _check(JSON.parse_string(JSON.stringify(show["state"])) is Dictionary,"outing persists")
 _check(not Social.attend(base,"unknown").get("ok",true),"unknown outing rejected")
 _check(not Workshop.develop(base,"x","Loose Jam","NO WAY HOME",1).get("ok",true),"unknown song idea rejected")
 _check(not Workshop.develop(base,"Riff","Loose Jam","NO WAY HOME",99).get("ok",true),"invalid leader rejected")
 var broke := base.duplicate(true)
 broke["cash"] = 0
 _check(not Social.attend(broke,"dinner").get("ok",true),"cash constraints enforced")
 _check(base["relationships"]["0_1"] == 40 and base["cash"] == 120,"original career immutable")
 if failures == 0:
  print("V23 JAMS AND SOCIAL TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V23 FAILURE: "+detail)
