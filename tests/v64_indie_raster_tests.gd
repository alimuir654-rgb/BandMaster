extends SceneTree
var failures := 0
func _initialize() -> void:
 for name in ["home","band","studio","backstage","formation","gigs","gear","scene","promotion","actions"]:
  var path := "res://Art/Backgrounds/indie/%s.webp" % name
  _check(ResourceLoader.exists(path),"missing Indie scene "+name)
  if ResourceLoader.exists(path):
   var image = load(path)
   _check(image is Texture2D,"invalid texture "+name)
   if image is Texture2D:
    _check(image.get_width() >= 320 and image.get_height() >= 160,"image resolution "+name)
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene compiles")
 if failures==0:
  print("V64 INDIE RASTER ART TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V64 ART FAILURE: "+reason)
