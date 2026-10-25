extends SceneTree
const Layout = preload("res://Scripts/career_layout.gd")
var failed := 0
func _initialize() -> void:
 _check(Layout.member_portrait_size(1280.0)==Vector2(112,136),"prominent landscape portrait")
 _check(Layout.member_portrait_size(390.0)==Vector2(88,108),"mobile size unchanged")
 _check(Layout.member_portrait_size(360.0)==Vector2(64,82),"small mobile safe")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failed==0:
  print("V90 PORTRAIT EMPHASIS PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failed+=1
  push_error("V90 PORTRAIT FAILURE: "+detail)
