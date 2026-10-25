extends SceneTree
const Genres = preload("res://Scripts/genre_profiles.gd")
const UI = preload("res://Scripts/ui_theme.gd")
var failures := 0
func _initialize() -> void:
 _check(Genres.normalize("unknown") == "indie","legacy fallback")
 for id in Genres.all_ids():
  var scheme: Dictionary = UI.palette(id)
  _check(scheme["accent"] is Color,"colour token")
  _check(UI.themed_button("PLAY",id,true) is Button,"button rendering")
 var band := {"band":{"genre":"punk"}}
 var old := JSON.stringify(band)
 _check(Genres.from_save(band)["name"]=="Punk / Garage","save genre")
 _check(JSON.stringify(band)==old,"immutable lookup")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene compiles")
 if failures == 0:
  print("V50 GENRE TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V50 GENRE FAILURE: "+detail)
