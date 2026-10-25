extends SceneTree
var failures := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := s.find("func _actions() -> void:")
 var b := s.find("func _recording_studio() -> void:",a)
 _check(a>=0 and b>a,"studio section")
 if a>=0 and b>a:
  var studio := s.substr(a,b-a)
  _check(studio.contains("selector_grid.columns = 1 if CareerLayout.is_compact"),"responsive selector grid")
  _check(studio.contains("selector_grid.add_child(field)"),"fields grouped")
  _check(studio.contains("control.tooltip_text"),"field hints")
  _check(studio.contains("item_selected.connect"),"preview updates wired")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene loads")
 if failures==0:
  print("V77 RESPONSIVE SONGWRITING PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V77 SONGWRITING FAILURE: "+detail)
