extends SceneTree
## Captures the ACTUAL Godot renderer at three viewports, not an image mock.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var phase := "day"
	var width := 390
	var height := 844
	var output := "screenshots/gig-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day", "dusk", "night"].has(phase) or width < 320 or height < 600:
		push_error("GIG CAPTURE: invalid phase or dimensions")
		quit(1)
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/gig_night_controls_lab.tscn")
	if packed == null:
		push_error("GIG CAPTURE: missing scene")
		quit(1)
		return
	var lab: Control = packed.instantiate()
	get_root().add_child(lab)
	lab.set_phase(phase)
	if phase != "day":
		lab.toggle_equipment()
		lab.toggle_soundcheck()
	if phase == "night":
		lab.fire_go()
	for i in range(22):
		await process_frame
	var hero: Control = lab.find_child("GigPhotographicHero", true, false)
	var rack: Control = lab.find_child("GigHardwareRack", true, false)
	var go: Button = lab.find_child("GigGo", true, false)
	var hold: Button = lab.find_child("GigHold", true, false)
	var encore: Button = lab.find_child("GigEncore", true, false)
	var primary: Button = lab.find_child("GigPrimary", true, false)
	var footer: Control = lab.find_child("GigActionDock", true, false)
	var cue: Control = lab.find_child("GigCueControls", true, false)
	var safety: Control = lab.find_child("GigSafetyControls", true, false)
	var backdrop: ColorRect = lab.find_child("GigTimeBackdrop", true, false)
	if hero == null or rack == null or go == null or hold == null or encore == null or primary == null or footer == null or backdrop == null or cue == null or safety == null:
		push_error("GIG CAPTURE: missing controls")
		quit(1)
		return
	var pixel_scale := float(DisplayServer.window_get_size().x) / float(lab.get_viewport_rect().size.x)
	if primary.custom_minimum_size.y * pixel_scale < 44.0:
		push_error("GIG CAPTURE: primary action smaller than 44px")
		quit(1)
		return
	if primary.get_global_rect().end.y * pixel_scale > float(height) - 4.0:
		push_error("GIG CAPTURE: primary action outside first fold")
		quit(1)
		return
	if hero.get_global_rect().position.y * pixel_scale > float(height) * 0.52:
		push_error("GIG CAPTURE: photo hero not visible near first fold")
		quit(1)
		return
	if cue.get_global_rect().end.y * pixel_scale > footer.get_global_rect().position.y * pixel_scale - 2.0:
		push_error("GIG CAPTURE: GO HOLD ENCORE hidden below first fold")
		quit(1)
		return
	if rack.get_global_rect().size.y * pixel_scale < 170.0:
		push_error("GIG CAPTURE: stage rack collapsed")
		quit(1)
		return
	if minf(go.custom_minimum_size.y, minf(hold.custom_minimum_size.y, encore.custom_minimum_size.y)) * pixel_scale < 44.0:
		push_error("GIG CAPTURE: cue button below 44px")
		quit(1)
		return
	if phase == "night" and (go.disabled or lab.songs_played != 1):
		push_error("GIG CAPTURE: night GO not live after safety checks")
		quit(1)
		return
	if phase == "day" and not go.disabled:
		push_error("GIG CAPTURE: GO should be disabled in daylight")
		quit(1)
		return
	primary.pressed.emit()
	var status: Label = lab.find_child("GigStatus", true, false)
	if status == null or not status.text.contains("NO SAVE WRITES"):
		push_error("GIG CAPTURE: preview did not respond")
		quit(1)
		return
	for i in range(5):
		await process_frame
	var img := get_root().get_texture().get_image()
	var expected: Color = Worlds.palette("gig", phase)["bg"]
	var actual: Color = img.get_pixel(3, 3)
	if absf(actual.r - expected.r) > 0.12 or absf(actual.g - expected.g) > 0.12 or absf(actual.b - expected.b) > 0.12:
		push_error("GIG CAPTURE: incorrect phase backdrop")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var saved := img.save_png(ProjectSettings.globalize_path(output))
	lab.queue_free()
	if saved != OK or img.get_width() < width or img.get_height() < height:
		push_error("GIG CAPTURE: screenshot save failed")
		quit(1)
		return
	print("GIG CAPTURE PASSED: " + output)
	quit(0)
