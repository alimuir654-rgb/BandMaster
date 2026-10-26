extends SceneTree
const Workshop = preload("res://Scripts/song_workshop.gd")
const Sleeve = preload("res://Scripts/song_sleeve.gd")
const Fade = preload("res://Scripts/journey_fade.gd")
var failures := 0

func _initialize() -> void:
 var original := {"members":[{"name":"Jo","role":"Guitarist","life_status":"active","trait":"Creative"}],"tour_day":2,"song_catalogue":[]}
 var first: Dictionary = Workshop.develop(original,"Lyric","Slow Build","A NEW SONG",0,"Last train home","Dreamy and spacious")
 _check(bool(first.get("ok",false)),"new creative choices accepted")
 _check(not original.has("current_song_draft"),"original state remains unchanged")
 if bool(first.get("ok",false)):
  var draft: Dictionary = first["state"]["current_song_draft"]
  _check(str(draft.get("lyrical_concept","")) == "Last train home","concept in draft")
  _check(str(draft.get("vibe","")) == "Dreamy and spacious","vibe in draft")
  _check(draft.get("sessions",[]).size() == 1,"one actual session")
  # Practice.compose advances progress after the first session; model that boundary.
  var after_first: Dictionary = first["state"].duplicate(true)
  after_first["song_draft_progress"] = 1
  var second: Dictionary = Workshop.develop(after_first,"Riff","Verse / Chorus","A NEW SONG",0)
  _check(bool(second.get("ok",false)),"old signature remains valid")
  if bool(second.get("ok",false)):
   var revised: Dictionary = second["state"]["current_song_draft"]
   _check(str(revised.get("lyrical_concept","")) == "Last train home","old caller preserves concept")
   _check(str(revised.get("vibe","")) == "Dreamy and spacious","old caller preserves vibe")
   _check(revised["sessions"].size() == 2,"legacy call appends second real session")
   if revised["sessions"].size() == 2:
    _check(not revised["sessions"][1].has("lyrical_concept"),"legacy session does not invent concept")
   var ready: Dictionary = second["state"].duplicate(true)
   ready["song_catalogue"] = [{"title":"A NEW SONG","quality":65}]
   var finished: Dictionary = Workshop.finish(ready)
   var song: Dictionary = finished["song_catalogue"][0]
   var info: Dictionary = Sleeve.describe(song,1)
   _check(str(info["concept"]) == "Last train home","concept in finished sleeve")
   _check(str(info["vibe"]) == "Dreamy and spacious","vibe in finished sleeve")
 var legacy: Dictionary = Sleeve.describe({"title":"OLD SONG","quality":40},1)
 _check(str(legacy["concept"]).is_empty() and str(legacy["vibe"]).is_empty(),"legacy songs never invent metadata")
 var shade := ColorRect.new()
 get_root().add_child(shade)
 var calls := [0,0]
 Fade.play(shade,func() -> void: calls[0] += 1,func() -> void: calls[1] += 1,true)
 _check(calls == [1,1] and shade.mouse_filter == Control.MOUSE_FILTER_IGNORE,"reduced motion runs swap exactly once")
 shade.free()
 if failures == 0:
  print("SPRINT A METADATA AND TRANSITIONS PASSED")
 quit(0 if failures == 0 else 1)

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT A METADATA FAILURE: "+reason)
