extends SceneTree
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var first := src.find("func _actions() -> void:")
 var last := src.find("\nfunc ",first+8)
 var actions := src.substr(first,last-first)
 _check(actions.contains('if action_view != "JAM":\n  _environment_dashboard()'),"studio avoids duplicate control dashboard")
 _check(actions.contains('if action_view != "JAM":\n  scene_card = _card('),"JAM avoids decorative scene card")
 _check(actions.contains('Color("#EFE3C9")'),"working song sheet uses paper treatment")
 _check(actions.contains('Color("#332820")'),"songwriting desk has its own material")
 _check(actions.contains('content.move_child(songbook_panel,content.get_child_count()-1)'),"songbook moved below active composition")
 _check(actions.contains("COMMIT TO THIS SONG  /  1 DAY"),"commit cost remains clear")
 _check(actions.contains("SAVE TAKE A"),"A/B workbench remains")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures == 0: print("V132 CREATIVE WORKBENCH PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures+=1
  push_error("V132 FAILURE: "+why)
