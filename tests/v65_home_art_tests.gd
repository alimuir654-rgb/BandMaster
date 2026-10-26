extends SceneTree
# Acceptance assertions updated for the owner-approved photo-led Band House.
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := src.find("func _home() -> void:")
 var b := src.find("func _editorial_banner(",a)
 _check(a>=0 and b>a,"home scene source available")
 if a>=0 and b>a:
  var home := src.substr(a,b-a)
  _check(home.contains("world_home_wide.webp") and home.contains("world_home_portrait.webp"),"real photo crop paths for landscape and portrait")
  _check(home.contains("ResourceLoader.exists(photo_path)"),"safe fallback if asset missing")
  _check(home.contains("STRETCH_KEEP_ASPECT_COVERED"),"cinematic image crop")
  _check(home.contains("scrim.color = Color("),"foreground text scrim")
  _check(home.contains("hero.clip_contents = true"),"hero crop does not overflow")
  _check(home.contains("hero.custom_minimum_size = Vector2("),"responsive hero size")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V65 PHOTO-LED HOME PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V65 PHOTO-LED HOME FAILURE: "+reason)
