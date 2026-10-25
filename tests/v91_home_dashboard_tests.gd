extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _home() -> void:")
 var finish := source.find("func _gigs() -> void:",start)
 _check(start>=0 and finish>start,"Home view available")
 if start>=0 and finish>start:
  var home := source.substr(start,finish-start)
  _check(home.contains("landscape_dashboard := get_viewport_rect().size.x >= 960.0"),"landscape breakpoint")
  _check(home.contains("main_column.size_flags_stretch_ratio = 1.65"),"primary tasks wider")
  _check(home.contains("content = sidebar"),"context in sidebar")
  _check(home.contains("content = main_column"),"tasks in main")
  _check(home.contains("content = full_content"),"restores content for render")
  _check(home.contains("Director.next_move(_state())"),"next move retained")
  _check(home.contains("Chapters.claim(_state()"),"chapter actions retained")
  _check(home.contains("Calendar.pending(_state())"),"gig status retained")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"CareerHub imports")
 if failures == 0:
  print("V91 HOME DASHBOARD PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V91 DASHBOARD FAILURE: "+reason)
