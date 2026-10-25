extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains('var show_result := source.begins_with("gig:")'),"only real gig results receive reveal")
 _check(source.contains("HOUSE LIGHTS DOWN"),"prelude onstage")
 _check(source.contains('stage_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED'),"stage image crops properly")
 _check(source.contains('tween_property(stage_image,"modulate:a",1.0,0.85)'),"stage image fades")
 _check(source.contains("◉ PA LEFT"),"sound-system visual language")
 _check(source.contains("THE SHOW  /  BACKSTAGE REPORT"),"performance-specific copy")
 _check(source.contains('var next_button := UI.button("CONTINUE  ›",true)'),"animation dismissible")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures==0:
  print("V121 STAGE REVEAL PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V121 STAGE FAILURE: "+reason)
