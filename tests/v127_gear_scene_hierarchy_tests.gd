extends SceneTree
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains("var desktop_shop := get_viewport_rect().size.x >= 680.0"),"desktop shop splits catalogue/detail")
 _check(src.contains("content = detail_column"),"purchase detail in adjacent column")
 _check(src.contains("details_parent.move_child(detail"),"phone purchase detail above catalogue")
 _check(src.contains('var scene_view := "PROMOTE"'),"scene defaults to actions")
 _check(src.contains('if scene_view == "HISTORY":'),"scrapbook is explicit mode")
 _check(src.contains("func _scene_scrapbook() -> void:"),"memorabilia preserved")
 _check(src.contains('scene_view = id'),"scene mode tabs work")
 _check(src.contains("preserve_gear_scroll = false"),"navigation resets selection scroll")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career hub imports")
 if failures == 0:
  print("V127 GEAR SCENE HIERARCHY PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V127 FAILURE: "+reason)
