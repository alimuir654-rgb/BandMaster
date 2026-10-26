extends SceneTree
# Real-photo routing is deterministic, offline and backward compatible.
const Photos = preload("res://Scripts/journey_photo.gd")
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("PHOTO ROUTING FAILURE: "+detail)

func _run() -> void:
 _check(Photos.SONG_SCENES.size() == 4,"four distinct songwriting photo slots")
 _check(Photos.SHOW_SCENES.size() == 5,"five distinct show-day photo slots")
 for journey in ["songwriting","showday"]:
  var total := 4 if journey == "songwriting" else 5
  for index in range(total):
   var fallback := "res://Art/Journeys/Songwriting/01-spark.svg" if journey == "songwriting" else "res://Art/Journeys/ShowDay/01-load.svg"
   for width in [390.0,720.0,1280.0]:
    var photo: String = Photos.scene_path(journey,index,width)
    var selected: String = Photos.scene_or_fallback(journey,index,width,fallback)
    _check(selected == (photo if not photo.is_empty() else fallback),"correct photo/fallback selection "+journey+str(index)+str(width))
    if not photo.is_empty():
     _check(ResourceLoader.exists(photo),"photo exists "+photo)
     var texture: Texture2D = load(photo)
     _check(texture != null and texture.get_width() >= 900,"photo imports at usable resolution "+photo)
 _check(Photos.scene_path("songwriting",-1,390.0).is_empty(),"negative slot rejected")
 _check(Photos.scene_path("showday",5,1280.0).is_empty(),"out of range slot rejected")
 _check(Photos.scene_path("unknown",0,1280.0).is_empty(),"unknown journey rejected")
 if failures == 0:
  print("LIVING THE DREAM PHOTO ROUTING PASSED")
 quit(0 if failures == 0 else 1)
