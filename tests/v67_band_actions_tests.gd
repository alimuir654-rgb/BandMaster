extends SceneTree
var failed := 0
func _initialize() -> void:
 var s := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := s.find("func _band() -> void:")
 var b := s.find("func _listen(",a)
 _check(a>=0 and b>a,"band view")
 if a>=0 and b>a:
  var portion := s.substr(a,b-a)
  _check(portion.contains("var talk := UI.themed_button(\"TALK\""),"direct dialogue CTA")
  _check(portion.contains("talk.pressed.connect(func() -> void: _listen(index))"),"dialogue action wired")
  _check(portion.contains("preserve_roster_scroll = true"),"disclosure scroll preserved")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene imports")
 if failed==0:
  print("V67 BAND ACTIONS TESTS PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failed+=1
  push_error("V67 BAND FAILURE: "+detail)
