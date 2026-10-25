extends SceneTree
var errors := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains("func _open_venue_browser() -> void:"),"venue browser exists")
 _check(src.contains('overlay.name = "VenueBrowserScreen"'),"directory dedicated scene")
 _check(src.contains('overlay.name = "VenueDetailScreen"'),"venue dossier dedicated scene")
 _check(src.contains('func _open_venue_details(venue_id: String) -> void:'),"venue details available")
 _check(src.contains('_open_promoter_meeting(venue_id,active >= 2 and drummer,active)'),"detail leads to promoter")
 _check(src.contains('_open_venue_browser(),true)'),"first fold launches venue browser")
 _check(src.contains('var song_finished := after_songs.size() > before_songs.size()'),"song event detected")
 _check(src.contains('NEW ORIGINAL  /  SONG FINISHED'),"song has tangible memento")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career hub compiles")
 if errors == 0: print("V135 VENUE JOURNEY AND MEMENTO PASSED")
 quit(0 if errors == 0 else 1)
func _check(ok: bool,msg: String) -> void:
 if not ok:
  errors += 1
  push_error("V135 FAILURE: "+msg)
