extends SceneTree
const Portrait = preload("res://Scripts/member_portrait.gd")
var failures := 0
func _initialize() -> void:
 for name in ["jo","alex","sam","dev"]:
  var p: String = "res://Art/Portraits/indie/%s.webp" % name
  _check(ResourceLoader.exists(p),name+" artwork committed")
  var tex = load(p)
  _check(tex is Texture2D,name+" asset loads")
  if tex is Texture2D:
   _check(tex.get_size()==Vector2(160,160),name+" source pixels")
  var character := Portrait.new()
  character.set_character("",name.capitalize(),"indie")
  _check(character.portrait_texture is Texture2D and not character.portrait_texture is AtlasTexture,name+" individual asset has precedence")
  character.free()
 var fallback := Portrait.new()
 fallback.set_character("other","Other","indie")
 _check(fallback.portrait_texture==null,"unknown falls back")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene loads")
 if failures==0:
  print("V105 INDIVIDUAL WEBP PORTRAITS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V105 PORTRAIT FAILURE: "+reason)
