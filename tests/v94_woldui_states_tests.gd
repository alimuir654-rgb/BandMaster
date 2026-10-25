extends SceneTree
const UI = preload("res://Scripts/ui_theme.gd")
var failed := 0
func _initialize() -> void:
 for genre in ["indie","punk","metal","electronic"]:
  for primary in [true,false]:
   var control := UI.themed_button("PLAY",genre,primary)
   _check(control is WoldButton,"WoldUI button "+genre)
   for key in ["normal","hover","pressed","disabled","focus"]:
    _check(control.has_theme_stylebox_override(key),genre+" "+key)
   var normal: StyleBoxFlat = control.get_theme_stylebox("normal") as StyleBoxFlat
   var focus: StyleBoxFlat = control.get_theme_stylebox("focus") as StyleBoxFlat
   _check(normal != null and normal.border_color == UI.palette(genre)["accent"] if primary else normal != null,"CTA accent")
   _check(focus != null and focus.border_color == UI.palette(genre)["accent"],"genre focus ring")
   control.free()
 _check(load("res://Scenes/CareerHub.tscn")!=null,"CareerHub imports")
 if failed==0:
  print("V94 WOLDUI STATES PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failed+=1
  push_error("V94 STATES FAILURE: "+detail)
