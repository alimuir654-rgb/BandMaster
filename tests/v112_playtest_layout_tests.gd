extends SceneTree
const Layout = preload("res://Scripts/career_layout.gd")
var failures := 0
func _initialize() -> void:
 _check(Layout.destination_columns(360.0)==1,"small phone has one column")
 _check(Layout.destination_columns(600.0)==1,"phone has one column")
 _check(Layout.destination_columns(720.0)==2,"tablet may have two columns")
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains("box.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN"),"roster does not stretch vertically")
 _check(src.contains('personnel_label.autowrap_mode = TextServer.AUTOWRAP_OFF'),"personnel header cannot wrap by letters")
 _check(src.contains('"art":"studio"'),"studio destination uses studio image")
 _check(src.contains('"WAYS FORWARD"'),"cash fan and reputation guidance")
 _check(src.contains('"NO GIG BOOKED"'),"empty calendar guidance")
 _check(src.contains('"IMPROVE THE BAND"'),"pulse has actionable advice")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failures == 0:
  print("V112 PLAYTEST FIXES PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V112 FAILURE: "+reason)
