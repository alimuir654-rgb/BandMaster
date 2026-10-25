extends SceneTree
const Portrait = preload("res://Scripts/member_portrait.gd")
var failures := 0
func _initialize() -> void:
 for genre in ["indie","punk","metal","electronic"]:
  var missing := Portrait.new()
  missing.set_character("unknown","Unknown",genre)
  _check(missing.portrait_texture==null,"fallback "+genre)
  missing.free()
 for name in ["Jo","Alex","Sam","Dev"]:
  var person := Portrait.new()
  person.set_character("",name,"indie")
  _check(person.portrait_texture is Texture2D,"prototype portrait "+name)
  person.free()
 var s := FileAccess.get_file_as_string("res://Scripts/member_portrait.gd")
 _check(s.contains("draw_texture_rect_region(portrait_texture,image_bounds,crop)"),"photo crop preserved")
 _check(s.contains("draw_rect(Rect2(0,bounds.y-footer_height"),"consistent image footer")
 _check(s.contains("draw_string(font,position,initials"),"fallback identity remains")
 if failures == 0:
  print("V104 PORTRAIT PRESENTATION PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V104 PORTRAIT FAILURE: "+detail)
