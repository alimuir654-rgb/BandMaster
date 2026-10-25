extends SceneTree
const Layout = preload("res://Scripts/career_layout.gd")
var failures := 0
func _initialize() -> void:
 for width in [320.0,360.0,375.0,390.0,430.0,560.0,768.0,1280.0]:
  _check(Layout.content_gutter(width) >= 8,"usable gutter")
  _check(Layout.studio_banner_height(width) > 0,"banner visible")
  _check(Layout.member_portrait_size(width).x > 0,"portrait visible")
  _check(Layout.member_name_font_size(width) >= 18,"name readable")
  _check(Layout.content_inset(width) >= Layout.footer_height(width),"nav not obscured")
 _check(Layout.member_portrait_size(320).x < Layout.member_portrait_size(430).x,"small phone portrait")
 _check(Layout.studio_banner_height(320) < Layout.studio_banner_height(768),"compact image footprint")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("CareerLayout.content_gutter(get_viewport_rect().size.x)"),"responsive gutters connected")
 _check(source.contains("CareerLayout.member_portrait_size(get_viewport_rect().size.x)"),"responsive portraits connected")
 _check(source.contains("CareerLayout.studio_banner_height(get_viewport_rect().size.x)"),"responsive scene imagery connected")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failures == 0:
  print("V35 MOBILE LAYOUT TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V35 MOBILE LAYOUT FAILURE: "+detail)
