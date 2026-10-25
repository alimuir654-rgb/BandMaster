extends SceneTree
const Components = preload("res://Scripts/ui_components.gd")
const UI = preload("res://Scripts/ui_theme.gd")
var failures := 0
func _initialize() -> void:
 for genre in ["indie","punk","metal","electronic"]:
  var host := VBoxContainer.new()
  var body := Components.section(host,"BAND IDENTITY","Visual differences should be legible.",genre)
  _check(body is VBoxContainer,"section created for "+genre)
  var panel: PanelContainer = host.get_child(0)
  var skin: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
  _check(skin != null and skin.bg_color == UI.palette(genre)["panel"],"genre panel "+genre)
  var heading: Label = body.get_child(0)
  _check(heading.get_theme_color("font_color") == UI.palette(genre)["accent"],"genre heading "+genre)
  host.free()
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("Components.section(content,title,description,_genre_id(),_scene_identity())"),"career uses genre sections")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene compiles")
 if failures == 0:
  print("V58 GENRE UI TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V58 GENRE UI FAILURE: "+detail)
