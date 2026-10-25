extends SceneTree
const Portrait = preload("res://Scripts/member_portrait.gd")
var failures := 0
func _initialize() -> void:
 var portrait := Portrait.new()
 portrait.set_character("42","Alex","indie")
 _check(portrait.initials=="AL","readable fallback identity")
 _check(portrait.genre_id=="indie","genre stored")
 _check(portrait._safe_id("../Alex Doe")=="alexdoe","safe asset key")
 _check(portrait.portrait_texture is AtlasTexture,"Alex now has real Indie artwork")
 var unknown := Portrait.new()
 unknown.set_character("missing","Unmatched","indie")
 _check(unknown.portrait_texture==null,"unknown artwork graceful fallback")
 portrait.set_character("42","Alex","punk")
 _check(portrait.genre_id=="punk","genre switches")
 portrait.set_character("42","","invalid")
 _check(portrait.initials=="?","empty name fallback")
 _check(portrait.genre_id=="indie","invalid genre normalized")
 var source := FileAccess.get_file_as_string("res://Scripts/member_portrait.gd")
 _check(not source.contains("draw_circle("),"procedural cartoon faces retired")
 _check(source.contains("name.replace(\" \",\"_\")"),"name-based artwork lookup supported")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene imports")
 if failures==0:
  print("V54 PORTRAIT IDENTITY TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V54 PORTRAIT FAILURE: "+detail)
