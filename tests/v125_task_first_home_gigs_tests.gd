extends SceneTree
# Acceptance assertions updated for the owner-approved photo-led Band House.
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := src.find("func _home() -> void:")
 var b := src.find("func _editorial_banner(",a)
 _check(a>=0 and b>a,"home scene source available")
 if a>=0 and b>a:
  var home := src.substr(a,b-a)
  _check(home.find("BandHousePrimaryAction") >= 0 and home.find("BandHousePrimaryAction") < home.find("BandHouseDestinations"),"home primary decision precedes destinations")
  _check(home.contains("Director.next_move(_state())"),"director decision remains state-driven")
  _check(home.contains("call.pressed.connect(func() -> void: _switch(target))"),"primary decision navigates without spending")
  _check(src.contains("BackstageIncident.incident(_state())"),"backstage decision retained")
  _check(src.contains("TAKE THE STAGE"),"show entry retained")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V125 TASK FIRST PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V125 TASK FIRST FAILURE: "+reason)
