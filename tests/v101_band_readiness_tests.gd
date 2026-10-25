extends SceneTree
var failed := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := s.find("func _band() -> void:")
 var b := s.find("func _listen(",a)
 _check(a>=0 and b>a,"Band view")
 if a>=0 and b>a:
  var view := s.substr(a,b-a)
  _check(view.contains('{"label":"LOYALTY","key":"loyalty"'),"loyalty visible on roster")
  _check(view.contains('{"label":"FATIGUE","key":"fatigue"'),"fatigue visible on roster")
  _check(view.contains('if int(member.get("fatigue",0)) >= 75:'),"rest warning threshold")
  _check(view.contains("UI.themed_progress(progress_meter,_genre_id()"),"genre-aware meter")
  _check(view.contains("if get_viewport_rect().size.x >= 960.0:"),"desktop only to prevent mobile clutter")
  _check(view.contains("talk.pressed.connect"),"conversations retained")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career loads")
 if failed==0:
  print("V101 BAND READINESS PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failed += 1
  push_error("V101 BAND FAILURE: "+reason)
