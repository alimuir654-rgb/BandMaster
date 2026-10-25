extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("func _editorial_banner("),"shared banner helper exists")
 _check(source.contains('func _band() -> void:'),"band screen exists")
 _check(source.contains('_editorial_banner("THE PEOPLE BEHIND THE MUSIC"'),"band editorial context preserved")
 _check(source.contains('func _actions() -> void:\n _scene_instrument_strip()'),"studio keeps context strip")
 _check(source.contains('_editorial_banner("THE CREATIVE STUDIO"'),"studio editorial context preserved")
 _check(source.contains("func _gigs() -> void:\n _scene_instrument_strip()"),"gigs retains context strip")
 _check(source.contains('_editorial_banner("THE LIVE CIRCUIT"'),"gigs retains cinematic masthead")
 _check(source.contains('if get_viewport_rect().size.x < 960.0:'),"mobile preserved")
 _check(source.contains("picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED"),"photo cover crop")
 _check(source.contains("ResourceLoader.exists(path)"),"graceful art fallback")
 _check(source.contains("cta.pressed.connect(func() -> void: _switch(destination))"),"navigation wired")
 _check(load("res://Scenes/CareerHub.tscn") != null,"scene imports")
 if failures == 0:
  print("V108 EDITORIAL SCREEN HEADERS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V108 HEADER FAILURE: "+reason)
