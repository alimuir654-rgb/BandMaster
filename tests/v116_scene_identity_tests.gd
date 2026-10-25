extends SceneTree
const SceneBackdrop = preload("res://Scripts/scene_environment.gd")
const Components = preload("res://Scripts/ui_components.gd")
var failures := 0
func _initialize() -> void:
 var backgrounds := ["HOME","DAY","STUDIO","GIGS"]
 for scene_id in backgrounds:
  var env := SceneBackdrop.new()
  env.set_scene(scene_id)
  _check(env.scene_id==scene_id,"scene identity "+scene_id)
  env.free()
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains('return "STUDIO" if action_view == "JAM" else "DAY"'),"day and studio separate")
 _check(src.contains('environment.set_scene(_scene_identity())'),"environment rendered")
 _check(src.contains('Components.section(content,title,description,_genre_id(),_scene_identity())'),"scene panels styled")
 _check(src.contains('func _scene_instrument_strip() -> void:'),"context instruments")
 _check(src.contains('"SHOW IN %d DAYS"'),"real gig countdown")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures==0:
  print("V116 SCENE IDENTITIES PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V116 SCENE FAILURE: "+reason)
