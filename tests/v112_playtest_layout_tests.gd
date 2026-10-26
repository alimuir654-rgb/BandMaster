extends SceneTree
const Layout = preload("res://Scripts/career_layout.gd")
var failures := 0
func _initialize() -> void:
 _check(Layout.destination_columns(360.0)==1,"legacy destination helper remains stable")
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains("box.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN"),"roster vertical layout preserved")
 _check(src.contains("personnel_label.autowrap_mode = TextServer.AUTOWRAP_OFF"),"personnel text cannot break letter by letter")
 _check(src.contains("var hero_height := clampf(viewport_height") and src.contains("hero.custom_minimum_size = Vector2(0.0,hero_height)"),"responsive viewport-scaled hero height")
 _check(src.contains("button.custom_minimum_size.y = 84"),"destinations remain touch sized")
 _check(src.contains("THE NEXT GIG"),"gig status on home")
 _check(src.contains("CHAPTER  /  "),"career progression on home")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failures==0:
  print("V112 RESPONSIVE HOME PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V112 FAILURE: "+reason)
