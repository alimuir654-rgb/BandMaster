extends SceneTree
var failed := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("scroll.offset_left = 116"),"wide game content clears sidebar")
 _check(source.contains("Control.PRESET_LEFT_WIDE"),"wide navigation uses left rail")
 _check(source.contains("bar.columns = 1 if landscape"),"one-column navigation")
 _check(source.contains("button.icon_start ="),"WoldUI rail icons")
 _check(source.contains("if not landscape and ResourceLoader.exists(icon_path)"),"no duplicate icons")
 _check(source.contains("Control.PRESET_BOTTOM_WIDE"),"mobile footer preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"CareerHub imports")
 if failed==0:
  print("WOLDUI LANDSCAPE SHELL PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failed+=1
  push_error("LANDSCAPE SHELL FAILURE: "+reason)
