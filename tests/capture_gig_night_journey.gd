extends SceneTree
## Captures actual Godot render: daylight load-in, dusk check, night show, aftershow.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var moment := "day"
	var width := 390
	var height := 844
	var output := "screenshots/gig-journey-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--moment="):
			moment = arg.trim_prefix("--moment=")
		elif arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day", "dusk", "night", "after"].has(moment) or width < 320 or height < 600:
		push_error("GIG JOURNEY CAPTURE: invalid moment/viewport")
		quit(1)
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/gig_night_journey_poc.tscn")
	if packed == null:
		push_error("GIG JOURNEY CAPTURE: scene unavailable")
		quit(1)
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	view.toggle_equipment()
	if moment != "day":
		view.advance_journey()
		view.toggle_soundcheck()
	if ["night", "after"].has(moment):
		view.advance_journey()
		view.fire_go()
	if moment == "after":
		view.fire_go()
		view.fire_go()
		view.fire_encore()
		view.advance_journey()
	for i in range(24):
		await process_frame
	var expected_step := ["day", "dusk", "night", "after"].find(moment)
	if view.journey_step != expected_step:
		push_error("GIG JOURNEY CAPTURE: wrong story step")
		quit(1)
		return
	if moment == "after" and (view.settlement_count != 1 or view.demo_state.get("gig_history", []).size() != 1):
		push_error("GIG JOURNEY CAPTURE: missing once-only real settlement")
		quit(1)
		return
	var approach_button: Button = view.find_child("PhaseDay", true, false) as Button
	if approach_button == null or approach_button.text != "TIGHT SET":
		push_error("GIG JOURNEY CAPTURE: stale phase tabs instead of actual show approach")
		quit(1)
		return
	var primary: Button = view.find_child("GigPrimary", true, false) as Button
	var footer: Control = view.find_child("GigActionDock", true, false) as Control
	var cue: Control = view.find_child("GigCueControls", true, false) as Control
	var rack: Control = view.find_child("GigHardwareRack", true, false) as Control
	var backdrop: ColorRect = view.find_child("GigTimeBackdrop", true, false) as ColorRect
	if primary == null or footer == null or cue == null or rack == null or backdrop == null:
		push_error("GIG JOURNEY CAPTURE: missing control")
		quit(1)
		return
	var px := float(DisplayServer.window_get_size().x) / float(view.get_viewport_rect().size.x)
	if primary.custom_minimum_size.y * px < 44.0 or primary.get_global_rect().end.y * px > float(height) - 4.0:
		push_error("GIG JOURNEY CAPTURE: primary target or first fold failed")
		quit(1)
		return
	if cue.get_global_rect().end.y * px > footer.get_global_rect().position.y * px - 2.0:
		push_error("GIG JOURNEY CAPTURE: live cues hidden below first fold")
		quit(1)
		return
	if rack.get_global_rect().size.y * px < 170.0:
		push_error("GIG JOURNEY CAPTURE: hardware rack collapsed")
		quit(1)
		return
	var expected: Color = Worlds.palette("gig", "night" if moment == "after" else moment)["bg"]
	var image := get_root().get_texture().get_image()
	var actual: Color = image.get_pixel(3, 3)
	if absf(actual.r - expected.r) > 0.12 or absf(actual.g - expected.g) > 0.12 or absf(actual.b - expected.b) > 0.12:
		push_error("GIG JOURNEY CAPTURE: wrong day/dusk/night palette")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var saved := image.save_png(ProjectSettings.globalize_path(output))
	view.queue_free()
	if saved != OK or image.get_width() < width or image.get_height() < height:
		push_error("GIG JOURNEY CAPTURE: screenshot write failed")
		quit(1)
		return
	print("GIG JOURNEY CAPTURE PASSED: " + output)
	quit(0)
