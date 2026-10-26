extends SceneTree
var failed := 0

func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _home() -> void:")
 var b := source.find("func _editorial_banner(",a)
 _check(a>=0 and b>a,"Band House home function available")
 if a>=0 and b>a:
  var home := source.substr(a,b-a)
  var primary := home.find('call.name = "BandHousePrimaryAction"')
  var places := home.find('places.name = "BandHouseDestinations"')
  _check(home.contains('hero.name = "BandHouseHero"'),"photo-led hero exists")
  _check(home.contains('photograph.name = "BandHousePhotograph"'),"real photographic scene exists")
  _check(home.contains('scrim.name = "BandHouseLegibilityScrim"'),"photograph legibility treatment exists")
  _check(home.contains('bottom_scrim.name = "BandHouseActionScrim"'),"foreground actions have their own scrim")
  _check(home.contains('pulse.name = "BandHouseStatusStrip"'),"band status is visible in the hero")
  _check(primary>=0 and places>primary,"one next-move CTA precedes secondary destinations")
  _check(home.contains("var hero_height := clampf(viewport_height"),"hero height responds to viewport")
  _check(not home.contains("760.0 if wide else 780.0"),"old fixed-height hero removed")
  _check(home.contains('{"name":"WRITE & REHEARSE"') and home.contains('{"name":"BOOK & PLAY"') and home.contains('{"name":"YOUR PEOPLE"'),"exactly three intentional destinations")
  _check(home.contains('button.custom_minimum_size.y = 64'),"secondary destinations have accessible touch height")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failed==0:
  print("V74 PRIORITY CARDS PASSED")
 quit(0 if failed==0 else 1)

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failed+=1
  push_error("V74 PRIORITY FAILURE: "+reason)
