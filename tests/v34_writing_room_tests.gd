extends SceneTree
const Studio = preload("res://Scripts/song_studio_presentation.gd")
var failures := 0
func _initialize() -> void:
 var empty := {"song_draft_progress":0,"current_song_draft":{}}
 var before := JSON.stringify(empty)
 var first: Dictionary = Studio.view(empty)
 _check(first["completed"] == 0 and first["stage"] == "THE SPARK","blank start")
 var draft := {"song_draft_progress":2,"current_song_draft":{"title":"TEST TRACK","sessions":[{"day":3,"idea":"Riff","form":"Slow Build","leader":"Jo"}]}}
 var late: Dictionary = Studio.view(draft)
 _check(late["completed"] == 2 and late["history"].size() == 1,"advanced writing history")
 var note: Dictionary = Studio.preview("Riff","Verse / Chorus","NO WAY HOME","Jo")
 _check(note["title"] == "NO WAY HOME","choice title")
 _check(str(note["identity"]).contains("Guitar"),"idea guidance")
 _check(str(note["arrangement"]).contains("completion bonus"),"arrangement tradeoff")
 _check(JSON.stringify(empty) == before,"preview does not mutate save")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("YOUR SONG  /  LIVE PREVIEW"),"visible preview")
 _check(source.contains("item_selected.connect"),"reactive selectors")
 _check(source.contains("WRITING ROOM NOTES"),"past writing sessions visible")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures == 0:
  print("V34 WRITING ROOM TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V34 WRITING ROOM FAILURE: "+detail)
