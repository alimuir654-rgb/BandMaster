extends SceneTree
const Portrait = preload("res://Scripts/member_portrait.gd")
var failures := 0
func _initialize() -> void:
 var roster := ["jo","alex","sam","dev"]
 for candidate in roster:
  var p := Portrait.new()
  p.set_character(candidate,candidate.capitalize(),"indie")
  _check(p.initials.length() >= 1,"fallback identity "+candidate)
  if p.portrait_texture != null:
   if p.portrait_texture is AtlasTexture:
    _check(p.portrait_texture.get_width()>=96 and p.portrait_texture.get_height()>=96,"prototype atlas crop size")
   else:
    _check(p.portrait_texture.get_width()>=128 and p.portrait_texture.get_height()>=128,"minimum production portrait size")
  p.free()
 var unknown := Portrait.new()
 unknown.set_character("../bad","Guest","indie")
 _check(unknown.portrait_texture==null,"unavailable art fallback")
 unknown.free()
 _check(load("res://Scenes/CareerHub.tscn")!=null,"scene loads")
 if failures==0:
  print("V62 ART CONTRACT TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V62 ART CONTRACT FAILURE: "+reason)
