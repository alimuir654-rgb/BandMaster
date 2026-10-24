extends SceneTree
const Studio = preload("res://Scripts/song_studio_presentation.gd")
var failures := 0

func _initialize() -> void:
 var empty := {"song_draft_progress":0}
 var first: Dictionary = Studio.view(empty)
 _check(first["completed"] == 0 and first["headline"] == "A BLANK PAGE", "empty studio")
 _check(not empty.has("current_song_draft"), "view is nonmutating")
 for n in [1, 2]:
  var state := {"song_draft_progress":n,"current_song_draft":{"title":"THE LAST TRAIN"}}
  var view: Dictionary = Studio.view(state)
  _check(view["completed"] == n and view["active"], "session %d progress" % n)
  _check(view["headline"] == "THE LAST TRAIN", "draft title retained")
  _check(JSON.parse_string(JSON.stringify(state)) == state, "save compatible")
 _check(Studio.view({"song_draft_progress":99,"current_song_draft":{"title":"X"}})["completed"] == 2, "clamped progress")
 _check(Studio.view({"song_draft_progress":2,"current_song_draft":{}})["completed"] == 0, "legacy empty draft")
 if failures == 0:
  print("V24 SONG STUDIO PRESENTATION PASSED")
 quit(0 if failures == 0 else 1)

func _check(value: bool, detail: String) -> void:
 if not value:
  failures += 1
  push_error("V24 SONG STUDIO FAILURE: " + detail)
