extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var actions_start := source.find("func _actions() -> void:")
 var band_start := source.find("func _band() -> void:")
 _check(actions_start >= 0 and band_start >= 0,"both screens exist")
 var next_actions := source.find("\nfunc ",actions_start+8)
 var studio := source.substr(actions_start,next_actions-actions_start)
 var next_band := source.find("\nfunc ",band_start+8)
 var band := source.substr(band_start,next_band-band_start)
 _check(studio.find('var switches := _card("CHOOSE YOUR DAY"') < studio.find("_environment_dashboard()"),"activity selection before decorative controls")
 _check(studio.contains("content.move_child(songbook_panel,content.get_child_count()-1)"),"phone songbook follows composition workbench")
 _check(studio.contains("songbook_panel.get_parent() == content"),"songbook only reordered when owned by the active container")
 _check(band.contains("briefing_parent.move_child(briefing_panel,briefing_parent.get_child_count()-1)"),"band stats secondary to roster")
 _check(band.contains("var dialogue := _card("),"conversation remains visible")
 _check(band.contains("var talk := UI.themed_button("),"talk interaction retained")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene imports")
 if failures == 0:
  print("V126 TASK-FIRST STUDIO AND BAND PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("V126 FAILURE: "+why)
