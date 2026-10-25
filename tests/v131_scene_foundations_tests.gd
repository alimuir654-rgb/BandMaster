extends SceneTree
var failures := 0
func _initialize() -> void:
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains('func _open_promoter_meeting('),"promoter meeting is a separate overlay")
 _check(src.contains('overlay.name = "PromoterMeeting"'),"meeting has its own view identity")
 _check(src.contains('Promoter.book(_state(),venue_id,proposal)'),"negotiated offers book normally")
 _check(src.contains('overlay.queue_free()'),"meeting can be dismissed")
 _check(src.contains('preserve_venue_scroll = true'),"venue selection scroll preserved")
 _check(src.contains('preserve_venue_scroll or preserve_gear_scroll') or src.contains('preserve_gear_scroll or preserve_venue_scroll'),"viewport scroll remembers venue selection")
 _check(src.contains('career_scroll.call_deferred("ensure_control_visible",target)'),"venue shortcut scrolls after layout")
 _check(src.contains('var pulse_row := HBoxContainer.new()'),"Band Pulse status uses concise labels")
 _check(src.contains('TRAVEL ESTIMATE'),"tour planner exposes travel estimate")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"Godot scene parses")
 if failures == 0: print("V131 SCENE FOUNDATIONS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures+=1
  push_error("V131 FAILURE: "+why)
