extends SceneTree
const Genres = preload("res://Scripts/genre_profiles.gd")
var failures := 0
func _initialize() -> void:
 for pair in [{"raw":"Indie rock","expected":"indie"},{"raw":"Post-punk","expected":"indie"},{"raw":"Punk","expected":"punk"},{"raw":"Garage rock","expected":"punk"},{"raw":"Metal","expected":"metal"},{"raw":"Synth-pop","expected":"electronic"},{"raw":"Country / Americana","expected":"indie"}]:
  _check(Genres.normalize(pair["raw"])==pair["expected"],"mapping: "+pair["raw"])
 var old := {"band":{"genre":"Synth-pop"}}
 _check(Genres.from_save(old)["name"]=="Electronic / Synth","legacy band skin")
 var source := FileAccess.get_file_as_string("res://Scripts/band_builder.gd")
 _check(source.contains("Genres.normalize(genre)"),"builder themes recruitment")
 _check(source.contains("VISUAL IDENTITY"),"genre art direction preview")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career imports")
 if failures==0:
  print("V55 GENRE FORMATION TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V55 GENRE FAILURE: "+detail)
