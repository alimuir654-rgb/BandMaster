extends SceneTree
const UI = preload("res://Scripts/ui_theme.gd")
var failures := 0
func _initialize() -> void:
 var button := UI.button("PLAY",true)
 _check(button.focus_mode==Control.FOCUS_ALL,"keyboard focus")
 _check(button.has_theme_stylebox_override("hover"),"hover style")
 _check(button.has_theme_stylebox_override("disabled"),"disabled style")
 _check(button.has_theme_stylebox_override("focus"),"focus ring")
 var bar := ProgressBar.new()
 UI.progress(bar)
 _check(bar.custom_minimum_size.y <= 12,"thin meter")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("if tab != \"HOME\" and tab != \"ACTIONS\" and tab != \"BAND\":"),"large hero removed from priority screens")
 _check(source.contains("YOUR BAND"),"home identity card")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene loads")
 if failures==0:
  print("V52 UI CONTROLS TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V52 UI FAILURE: "+detail)
