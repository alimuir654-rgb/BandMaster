extends SceneTree
const Portrait = preload("res://Scripts/member_portrait.gd")
var failures := 0
func _initialize() -> void:
 var portrait := Portrait.new()
 portrait.set_character("person_01","Alex","indie")
 _check(portrait.person_id=="person_01","portrait identity")
 _check(portrait.genre_id=="indie","genre-aware lookup")
 _check(portrait.portrait_texture is AtlasTexture,"Indie artwork is loaded")
 var unknown := Portrait.new()
 unknown.set_character("unmatched","Unmatched","indie")
 _check(unknown.portrait_texture==null,"fallback for missing art")
 _check(portrait._safe_id("Joe/../../<bad>")=="joebad","path is sanitized")
 portrait.set_character("person_01","Alex","metal")
 _check(portrait.genre_id=="metal","genre change reloads")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene compiles")
 if failures==0:
  print("V51 PORTRAIT PIPELINE TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V51 PORTRAIT FAILURE: "+detail)
