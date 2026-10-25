extends SceneTree
var failures := 0
func _initialize() -> void:
 var hub := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var builder := FileAccess.get_file_as_string("res://Scripts/band_builder.gd")
 _check(not hub.contains("uk_street_banner.svg"),"SVG hero removed")
 _check(not builder.contains("uk_band_banner.svg"),"SVG formation removed")
 _check(hub.contains("Art/Backgrounds/%s/%s.webp"),"genre hero slot")
 _check(builder.contains("Art/Backgrounds/%s/formation.webp"),"genre formation slot")
 _check(hub.contains("ResourceLoader.exists(art_path)"),"missing art handled")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failures == 0:
  print("V57 ARTWORK HERO TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V57 ARTWORK FAILURE: "+detail)
