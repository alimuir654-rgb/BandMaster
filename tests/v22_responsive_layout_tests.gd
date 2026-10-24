extends SceneTree
const Layout = preload("res://Scripts/career_layout.gd")
var failures := 0
func _initialize() -> void:
 _check(Layout.columns(360) == 3,"phone uses three columns")
 _check(Layout.columns(559) == 3,"narrow breakpoint stable")
 _check(Layout.columns(560) == 6,"tablet can display six tabs")
 _check(Layout.columns(900) == 6,"desktop six columns")
 _check(Layout.footer_height(360) > Layout.footer_height(900),"phone allocates a second navigation row")
 _check(Layout.content_inset(360) > Layout.footer_height(360),"body scroll clears phone nav")
 _check(Layout.content_inset(900) > Layout.footer_height(900),"body scroll clears desktop nav")
 if failures == 0:
  print("V22 RESPONSIVE LAYOUT TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V22 LAYOUT FAILURE: "+detail)
