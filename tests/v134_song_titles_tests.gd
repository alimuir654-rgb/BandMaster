extends SceneTree
const Workshop = preload("res://Scripts/song_workshop.gd")
var failures := 0
func _initialize() -> void:
 var state := {"members":[{"name":"Jo","trait":"Creative","life_status":"active"}],"song_catalogue":[{"title":"NO WAY HOME"}],"tour_day":3}
 var duplicate: Dictionary = Workshop.develop(state,"Riff","Slow Build"," no way home ",0)
 _check(not bool(duplicate.get("ok",true)),"duplicate prevented")
 _check(not duplicate.has("state"),"duplicate leaves state unchanged")
 var unique: Dictionary = Workshop.develop(state,"Riff","Slow Build","Something Only Ours",0)
 _check(bool(unique.get("ok",false)),"custom title accepted")
 if bool(unique.get("ok",false)):
  _check(str(unique["state"]["current_song_draft"]["title"])=="SOMETHING ONLY OURS","custom title normalized")
 _check(not bool(Workshop.develop(state,"Riff","Slow Build","  ",0).get("ok",true)),"blank title rejected")
 var ui := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(ui.contains('title_entry.name = "WorkingTitleInput"'),"UI exposes song title editor")
 _check(ui.contains("title_entry.text,indices[leads.selected]"),"commit uses custom title")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene parses")
 if failures==0: print("V134 SONG TITLES PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures+=1
  push_error("V134 FAILURE: "+why)
