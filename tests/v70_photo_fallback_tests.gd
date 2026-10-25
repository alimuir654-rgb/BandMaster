extends SceneTree
const Genres = preload("res://Scripts/genre_profiles.gd")
var failures := 0
func _initialize() -> void:
 for genre in Genres.all_ids():
  for scene_name in ["home","band","studio","backstage","formation","gigs","gear","scene","promotion","actions"]:
   var path := "res://Art/Backgrounds/%s/%s.webp" % [genre,scene_name]
   if not ResourceLoader.exists(path):
    path = "res://Art/Backgrounds/shared/%s.webp" % scene_name
   _check(ResourceLoader.exists(path),genre+" "+scene_name+" missing")
   if ResourceLoader.exists(path):
    var picture = load(path)
    _check(picture is Texture2D,"invalid texture "+genre+" "+scene_name)
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("feature_path = \"res://Art/Backgrounds/shared/band.webp\""),"shared Home fallback wired")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene loads")
 if failures==0:
  print("V70 CROSS-GENRE PHOTO TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,message: String) -> void:
 if not ok:
  failures += 1
  push_error("V70 ART FAILURE: "+message)
