extends SceneTree
const Layout = preload("res://Scripts/career_layout.gd")
var failures := 0
func _initialize() -> void:
 _check(Layout.footer_height(390.0) <= 158.0,"mobile footer below 158px")
 _check(Layout.footer_height(1280.0) <= 96.0,"desktop footer below 96px")
 _check(Layout.content_inset(390.0) >= Layout.footer_height(390.0),"scroll clears navigation")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _bottom_nav() -> void:")
 var end := source.find("func _switch(next_tab:",start)
 _check(start >= 0 and end > start,"navigation implemented")
 if start >= 0 and end > start:
  var nav := source.substr(start,end-start)
  _check(nav.contains("UI.palette(_genre_id())"),"active genre palette")
  _check(nav.contains("border_width_bottom = 3 if selected else 1"),"selected tab indicator")
  _check(nav.contains("add_theme_stylebox_override(\"focus\",focus)"),"keyboard focus visible")
  _check(nav.contains("button.tooltip_text"),"navigation hints preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene valid")
 if failures == 0:
  print("V71 NAV UX TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V71 NAV FAILURE: "+reason)
