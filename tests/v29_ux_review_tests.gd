extends SceneTree
const Layout = preload("res://Scripts/career_layout.gd")
var failures := 0
func _initialize() -> void:
 for width in [320.0,375.0,390.0,430.0,560.0,768.0,1280.0]:
  _check(Layout.hero_height(width)>0.0 and Layout.hero_height(width)<270.0,"smaller hero "+str(width))
  _check(Layout.content_inset(width)>=Layout.footer_height(width),"navigation clearance")
  _check(Layout.destination_columns(width)>=1,"valid tile columns")
 _check(Layout.destination_columns(320.0)==1 and Layout.destination_columns(430.0)==1 and Layout.destination_columns(768.0)==2,"phone grid responsiveness")
 _check(Layout.nav_label("ACTIONS")=="STUDIO" and Layout.nav_label("SCENE")=="CAREER","player language")
 _check(Layout.nav_label("BAND")=="BAND","stable core tabs")
 _check(not Layout.nav_hint("GIGS").is_empty(),"navigation accessibility hints")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _home() -> void:")
 var next := source.find("func _gigs() -> void:",start)
 _check(start>=0 and next>start,"home source available")
 if start>=0 and next>start:
  var home := source.substr(start,next-start)
  _check(home.find("BandHousePrimaryAction") >= 0 and home.find("BandHousePrimaryAction") < home.find("BandHouseDestinations"),"primary action precedes curated navigation")
  _check(home.count("Director.next_move(_state())")==1,"single guidance render")
 _check(source.contains("CareerLayout.nav_label(target)"),"navigation uses accessible labels")
 _check(source.contains("CareerLayout.hero_height(get_viewport_rect().size.x)"),"hero obeys breakpoints")
 if failures==0:
  print("V29 UX REVIEW REGRESSIONS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V29 UX FAILURE: "+detail)
