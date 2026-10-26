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
  _check(home.contains("hero.name = \"BandHouseHero\""),"hero is a named scene")
  _check(home.contains("BandHousePhotograph"),"hero contains a photographic layer")
  _check(home.contains("BandHouseLegibilityScrim"),"foreground contrast layer present")
  _check(home.contains("BandHousePrimaryAction"),"single primary decision present")
  _check(home.count("_genre_id(),true)") == 1,"only one primary CTA in home")
  _check(not home.contains("landscape_dashboard"),"legacy dual dashboard removed")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V91 BAND HOUSE PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V91 BAND HOUSE FAILURE: "+reason)
