extends SceneTree
const UI = preload("res://Scripts/ui_theme.gd")
var failed := 0
func _initialize() -> void:
 var normal := UI.button("REHEARSE")
 var primary := UI.button("COMMIT",true)
 var indie := UI.themed_button("TALK","indie",true)
 _check(normal is WoldButton,"default buttons use WoldUI")
 _check(primary is WoldButton,"primary actions use WoldUI")
 _check(indie is WoldButton,"genre CTA uses WoldUI")
 _check(primary.has_theme_stylebox_override("focus"),"focus remains visible")
 _check(indie.has_theme_stylebox_override("normal"),"genre styling preserved")
 var career := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(career.contains("var button := WoldButton.new()"),"navigation uses WoldUI")
 normal.free()
 primary.free()
 indie.free()
 _check(load("res://Scenes/CareerHub.tscn") != null,"game career loads")
 if failed==0:
  print("WOLDUI LIVE BUTTONS PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failed+=1
  push_error("WOLDUI LIVE FAILURE: "+reason)
