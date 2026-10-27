extends SceneTree
## Real Godot renderer screenshot, not a static mock. Fails for first-fold/target issues.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var phase := "day"
	var width := 390
	var height := 844
	var output := "screenshots/songwriting-controls-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day", "dusk"].has(phase) or width < 320 or height < 600:
		push_error("WRITING CAPTURE: invalid phase or viewport")
		quit(1)
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/songwriting_controls_lab.tscn")
	if packed == null:
		push_error("WRITING CAPTURE: scene missing")
		quit(1)
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	view.choose_section("BRIDGE")
	view.append_section()
	view.choose_groove("SWELL")
	view.set_tempo(138)
	view.set_idea("Late train, last chance")
	view.set_phase(phase)
	for i in range(20):
		await process_frame
	var paper: Control = view.find_child("WritingNotebook", true, false)
	var idea: LineEdit = view.find_child("IdeaLine", true, false)
	var slider: HSlider = view.find_child("TempoSlider", true, false)
	var primary: Button = view.find_child("WritingPrimary", true, false)
	var footer: Control = view.find_child("WritingActionDock", true, false)
	var backdrop: ColorRect = view.find_child("WritingTimeBackdrop", true, false)
	var readout: Label = view.find_child("TempoReadout", true, false)
	if paper == null or idea == null or slider == null or primary == null or footer == null or backdrop == null or readout == null:
		push_error("WRITING CAPTURE: controls missing")
		quit(1)
		return
	if view.phase != phase or view.sequence.size() != 5 or idea.text != "Late train, last chance" or readout.text != "138 BPM":
		push_error("WRITING CAPTURE: state mismatch")
		quit(1)
		return
	var pixel_scale := float(DisplayServer.window_get_size().x) / float(view.get_viewport_rect().size.x)
	if readout.get_line_count() != 1 or readout.get_global_rect().size.x * pixel_scale < 60.0:
		push_error("WRITING CAPTURE: BPM readout wrapped or collapsed into a vertical column")
		quit(1)
		return
	if primary.custom_minimum_size.y * pixel_scale < 44.0:
		push_error("WRITING CAPTURE: preview tap target under 44px")
		quit(1)
		return
	if primary.get_global_rect().end.y * pixel_scale > float(height) - 4.0:
		push_error("WRITING CAPTURE: primary action outside first fold")
		quit(1)
		return
	if paper.get_global_rect().position.y * pixel_scale > float(height) * 0.50:
		push_error("WRITING CAPTURE: writing notebook not prominent")
		quit(1)
		return
	if idea.get_global_rect().end.y > paper.get_global_rect().end.y + 1.0:
		push_error("WRITING CAPTURE: idea editor clipped from paper")
		quit(1)
		return
	primary.pressed.emit()
	var status: Label = view.find_child("WritingStatus", true, false)
	if status == null or not status.text.contains("NO SAVE WRITES"):
		push_error("WRITING CAPTURE: preview action did not respond")
		quit(1)
		return
	for i in range(4):
		await process_frame
	var img := get_root().get_texture().get_image()
	var expected: Color = Worlds.palette("songwriting", phase)["bg"]
	var actual: Color = img.get_pixel(3, 3)
	if absf(actual.r - expected.r) > 0.12 or absf(actual.g - expected.g) > 0.12 or absf(actual.b - expected.b) > 0.12:
		push_error("WRITING CAPTURE: incorrect time-of-day backdrop")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var saved := img.save_png(ProjectSettings.globalize_path(output))
	view.queue_free()
	if saved != OK or img.get_width() < width or img.get_height() < height:
		push_error("WRITING CAPTURE: screenshot save failed")
		quit(1)
		return
	print("WRITING CAPTURE PASSED: " + output)
	quit(0)
