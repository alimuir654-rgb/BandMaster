extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _band() -> void:")
 var b := source.find("func _listen(",a)
 _check(a>=0 and b>a,"Band screen exists")
 if a>=0 and b>a:
  var view := source.substr(a,b-a)
  _check(view.contains("if get_viewport_rect().size.x >= 960.0:"),"responsive musician stats")
  _check(view.contains('{"label":"SKILL","key":"skill"}'),"skill stat capsule")
  _check(view.contains('{"label":"MORALE","key":"morale"}'),"morale stat capsule")
  _check(view.contains('profile.icon_start = "chart-no-axes-column"'),"details icon")
  _check(view.contains('talk.icon_start = "message-circle"'),"conversation icon")
  _check(view.contains("talk.pressed.connect(func() -> void: _listen(index))"),"conversation wired")
  _check(view.contains("preserve_roster_scroll = true"),"detail scroll preserved")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"CareerHub loads")
 if failures==0:
  print("V100 BAND CHARACTER CARDS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V100 CHARACTER CARDS FAILURE: "+detail)
