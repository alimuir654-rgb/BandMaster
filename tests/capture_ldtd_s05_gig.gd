extends SceneTree
## S05 actual Godot renderer screenshot and first-fold physical controls gate.
const Scene = preload("res://poc/ldtd_gig_night.tscn")
func _initialize() -> void:
	call_deferred("_capture")
func _fail(reason: String) -> void:
	push_error("S05 SCREENSHOT FAILURE: "+reason)
	quit(1)
func _capture() -> void:
	var width: int = 390
	var height: int = 844
	var moment: String = "day"
	var output: String = "screenshots/s05-gig-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--moment="):
			moment = arg.trim_prefix("--moment=")
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day","dusk","night","after"].has(moment):
		_fail("unknown moment")
		return
	get_root().size = Vector2i(width,height)
	DisplayServer.window_set_size(Vector2i(width,height))
	var view: Control = Scene.instantiate()
	get_root().add_child(view)
	for i in range(8):
		await process_frame
	if moment!="day":
		view.toggle_equipment()
		view.advance_journey()
		for i in range(4):
			await process_frame
	if moment in ["night","after"]:
		view.toggle_soundcheck()
		view.advance_journey()
		for i in range(4):
			await process_frame
	if moment=="after":
		view.fire_go()
		view.fire_go()
		view.fire_go()
		view.fire_encore()
		view.advance_journey()
	for i in range(18):
		await process_frame
	var expected: int = ["day","dusk","night","after"].find(moment)
	if view.journey_step!=expected:
		_fail("wrong moment or phase sequence")
		return
	var photo: TextureRect = view.find_child("RepoBackedGigPhasePhoto",true,false)
	var board: TextureRect = view.find_child("OriginalGigShowboard",true,false)
	var primary: TextureButton = view.find_child("GigPrimaryAction",true,false)
	var dock: Panel = view.find_child("GigActionDock",true,false)
	var scroll: ScrollContainer = view.find_child("GigNightScroll",true,false)
	var stats: Label = view.find_child("ReadOnlyGigOutcome",true,false)
	if photo==null or photo.texture==null or board==null or board.texture==null or primary==null or dock==null or scroll==null or stats==null:
		_fail("missing photo, physical showboard, dock or readonly outcomes")
		return
	var px: float = float(DisplayServer.window_get_size().x)/maxf(view.get_viewport_rect().size.x,1.0)
	if primary.get_global_rect().size.y*px<44.0 or primary.get_global_rect().end.y*px>float(height)+3.0:
		_fail("primary target smaller than 44px or below first fold")
		return
	if scroll.get_global_rect().end.y*px>dock.get_global_rect().position.y*px+3.0:
		_fail("scroll collides with dock")
		return
	if stats.focus_mode!=Control.FOCUS_NONE:
		_fail("readonly outcomes focusable")
		return
	var required: Array = ["GigGearLatch","GigSoundLatch","GigApproachTight","GigApproachWild","GigApproachCrowd","GigCue0","GigCue1","GigCue2","GigHold","GigGo"]
	for key in required:
		var item: TextureButton = view._keys.get(key)
		if item==null or item.texture_normal==null or item.texture_hover==null or item.texture_pressed==null or item.texture_disabled==null:
			_fail("missing genuine five-state physical show key "+key)
			return
		if item.get_global_rect().size.y*px<44.0:
			_fail("show key below 44 physical px "+key)
			return
		if ["GigGearLatch","GigSoundLatch","GigApproachTight","GigCue0","GigHold","GigGo"].has(key) and item.get_global_rect().end.y*px>dock.get_global_rect().position.y*px-2.0:
			_fail("consequential first-fold control behind dock "+key)
			return
	if moment=="after" and (view.settlement_count!=1 or view.demo_state.get("gig_history",[]).size()!=1 or not primary.disabled):
		_fail("aftershow not terminal once-only settlement")
		return
	var image: Image = get_root().get_texture().get_image()
	if image.get_width()<width or image.get_height()<height:
		_fail("renderer dimensions below device")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	if image.save_png(ProjectSettings.globalize_path(output))!=OK:
		_fail("could not save native Godot PNG")
		return
	print("LDTD S05 ACTUAL GODOT SCREENSHOT PASSED: "+output)
	view.queue_free()
	quit(0)
