extends SceneTree
var failures := 0

func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("var preserve_roster_scroll := false"),"scroll restoration defaults off")
 _check(source.contains("if preserve_roster_scroll and is_instance_valid(career_scroll):"),"capture only on roster disclosure")
 _check(source.contains("previous_scroll = career_scroll.scroll_vertical"),"capture position before rebuilding")
 _check(source.contains("scroll.set_deferred(\"scroll_vertical\",previous_scroll)"),"restore after layout")
 _check(source.contains("preserve_roster_scroll = false"),"restore flag resets")
 var profile_start := source.find("var profile := UI.button(")
 var profile_end := source.find("if selected_band_member != index:",profile_start)
 _check(profile_start >= 0 and profile_end > profile_start,"roster disclosure exists")
 if profile_start >= 0 and profile_end > profile_start:
  var profile_action := source.substr(profile_start,profile_end-profile_start)
  _check(profile_action.contains("preserve_roster_scroll = true"),"roster toggle opts in")
  _check(profile_action.contains("_render()"),"roster toggle rebuilds")
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(scene != null,"career scene loads")
 if failures == 0:
  print("V32 ROSTER SCROLL TESTS PASSED")
 quit(0 if failures == 0 else 1)

func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V32 ROSTER SCROLL FAILURE: "+detail)
