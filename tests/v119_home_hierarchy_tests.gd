extends SceneTree
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains('var opportunities := _card("WAYS FORWARD"'),"combined career routes")
 _check(src.contains('pathway_grid.columns = 1 if get_viewport_rect().size.x < 720.0 else 3'),"responsive routes")
 _check(src.contains('{"title":"BUILD YOUR AUDIENCE"'),"audience route")
 _check(src.contains('{"title":"RAISE YOUR PROFILE"'),"reputation route")
 _check(src.contains('{"title":"EARN YOUR KEEP"'),"cash route")
 _check(not src.contains('var momentum := _card("CAREER MOMENTUM"'),"duplicate status card removed")
 _check(src.contains('claim.pressed.connect(func() -> void: _finish(Chapters.claim(_state(),chapter_id),"chapter:"+chapter_id))'),"reward action preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene compiles")
 if failures==0:
  print("V119 HOME HIERARCHY PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V119 FAILURE: "+reason)
