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
  _check(home.find("BandHousePrimaryAction") < home.find("BandHouseDestinations"),"decision before navigation")
  _check(home.contains("Chapters.progress(_state())"),"career chapter retained")
  _check(home.contains("Chapters.claim(_state(),chapter_id)"),"once-only chapter claim action preserved")
  _check(home.contains("Calendar.pending(_state())"),"gig diary status retained")
  _check(not home.contains("WAYS FORWARD"),"repetitive pathway button grid removed")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V119 HERO HIERARCHY PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V119 HERO HIERARCHY FAILURE: "+reason)
