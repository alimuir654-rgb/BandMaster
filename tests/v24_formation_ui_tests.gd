extends SceneTree
const Catalogue = preload("res://Scripts/formation_catalogue.gd")
var failures := 0
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var scene: PackedScene = load("res://band_builder.tscn")
 _check(scene != null,"formation scene resource loads")
 if scene != null:
  var builder: Node = scene.instantiate()
  get_root().add_child(builder)
  _check(builder.step == 0,"identity appears first")
  _check(builder.genre_select != null and builder.influence_select != null,"genre and influence selectors display")
  _check(builder.next_button != null,"primary progression action exists")
  var portrait_type: Script = load("res://Scripts/member_portrait.gd")
  builder._go(1)
  _check(builder.step == 1,"recruitment step renders")
  var recruited: Array = []
  for candidate in Catalogue.CANDIDATES:
   if ["alex","jo","sam"].has(str(candidate["id"])):
    recruited.append(Catalogue.to_member(candidate,recruited.size()))
  builder.recruited = recruited
  builder._go(2)
  _check(builder.step == 2,"band reveal renders")
  _check(builder.next_button != null,"create band action exists")
  _check(builder.canvas.get_child_count() > 3,"band reveal contains rich sections")
  builder._go(1)
  _check(builder.recruited.size() == 3,"recruitment state survives back navigation")
  builder.free()
 if failures == 0:
  print("V24 FORMATION UI LIFECYCLE PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,description: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 FORMATION UI FAILURE: "+description)
