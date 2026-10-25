extends SceneTree
const Portrait = preload("res://Scripts/member_portrait.gd")
var failed := 0
func _initialize() -> void:
 var tex = load("res://Art/Portraits/indie/roster_atlas.webp")
 _check(tex is Texture2D,"raster atlas imports")
 if tex is Texture2D:
  _check(tex.get_width() == 192 and tex.get_height() == 192,"atlas grid dimensions")
 var regions := {}
 for name in ["Jo","Alex","Sam","Dev"]:
  var portrait := Portrait.new()
  portrait.set_character("",name,"indie")
  _check(portrait.portrait_texture is AtlasTexture,name+" image loaded")
  if portrait.portrait_texture is AtlasTexture:
   var crop: AtlasTexture = portrait.portrait_texture
   _check(crop.get_width()==96,name+" crop dimensions")
   regions[name] = str(crop.region.position)
 _check(regions.size()==4,"four characters loaded")
 if regions.size()==4:
  _check(regions["Jo"]!=regions["Alex"] and regions["Jo"]!=regions["Sam"] and regions["Sam"]!=regions["Dev"],"distinct faces")
 var other := Portrait.new()
 other.set_character("unknown","Unknown","indie")
 _check(other.portrait_texture == null,"unknown character uses initials")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career screen imports")
 if failed==0:
  print("V81 REAL PORTRAITS PASSED")
 quit(0 if failed==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failed+=1
  push_error("V81 REAL PORTRAITS FAILURE: "+detail)
