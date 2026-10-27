extends SceneTree
## Screenshot and interaction gate for the isolated Tour Control Lab.
const Worlds = preload("res://Scripts/scene_world_theme.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var phase := "day"
	var width := 390
	var height := 844
	var output := "screenshots/tour-controls-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not Worlds.PHASES.has(phase) or width < 320 or height < 600:
		push_error("TOUR CONTROL CAPTURE: Invalid viewport/phase")
		quit(1)
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/tour_controls_lab.tscn")
	if packed == null:
		push_error("TOUR CONTROL CAPTURE: Scene failed to load")
		quit(1)
		return
	var lab: Control = packed.instantiate()
	get_root().add_child(lab)
	lab.set_context(phase)
	lab.select_stop("cardiff")
	lab.toggle_van()
	for frame in range(20):
		await process_frame
	var selected: Label = lab.find_child("TicketDestination", true, false)
	var status: Label = lab.find_child("VanStatus", true, false)
	var latch: Button = lab.find_child("VanLatch", true, false)
	var primary: Button = lab.find_child("PrimaryAction", true, false)
	var road_case: Control = lab.find_child("TourRoadCase", true, false)
	if selected == null or selected.text != "CARDIFF" or status == null or status.text != "SECURED":
		push_error("TOUR CONTROL CAPTURE: State/ticket synchronization failed")
		quit(1)
		return
	if latch == null or primary == null or road_case == null:
		push_error("TOUR CONTROL CAPTURE: Physical controls missing")
		quit(1)
		return
	if latch.get_global_rect().end.y > road_case.get_global_rect().end.y - 4.0:
		push_error("TOUR CONTROL CAPTURE: Van latch clipped by road case")
		quit(1)
		return
	var selected_phase: Button = lab.find_child("Phase" + phase.capitalize(), true, false)
	if selected_phase == null:
		push_error("TOUR CONTROL CAPTURE: Phase selector missing")
		quit(1)
		return
	var selected_style: StyleBoxFlat = selected_phase.get_theme_stylebox("normal")
	if Worlds.contrast_ratio(selected_phase.get_theme_color("font_color"), selected_style.bg_color) < 4.5:
		push_error("TOUR CONTROL CAPTURE: Selected phase lacks text contrast")
		quit(1)
		return
	var pixel_scale := float(DisplayServer.window_get_size().x) / float(lab.get_viewport_rect().size.x)
	if primary.custom_minimum_size.y * pixel_scale < 44.0 or latch.custom_minimum_size.y * pixel_scale < 44.0:
		push_error("TOUR CONTROL CAPTURE: Action target below 44px")
		quit(1)
		return
	var bottom := primary.get_global_rect().end.y * pixel_scale
	if bottom > float(height) - 12.0:
		push_error("TOUR CONTROL CAPTURE: Primary action below first fold")
		quit(1)
		return
	primary.pressed.emit()
	var message: Label = lab.find_child("TourLabStatus", true, false)
	if message == null or not message.text.contains("NO SAVE CHANGES"):
		push_error("TOUR CONTROL CAPTURE: Preview action did not respond")
		quit(1)
		return
	for frame in range(4):
		await process_frame
	var image := get_root().get_texture().get_image()
	var expected: Color = Worlds.palette("tour", phase)["bg"]
	var pixel: Color = image.get_pixel(3, 3)
	if absf(pixel.r - expected.r) > 0.12 or absf(pixel.g - expected.g) > 0.12 or absf(pixel.b - expected.b) > 0.12:
		push_error("TOUR CONTROL CAPTURE: Time-of-day backdrop did not render")
		quit(1)
		return
	var dir := output.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var saved := image.save_png(ProjectSettings.globalize_path(output))
	lab.queue_free()
	if saved != OK or image.get_width() < width or image.get_height() < height:
		push_error("TOUR CONTROL CAPTURE: PNG write failed")
		quit(1)
		return
	print("TOUR CONTROL CAPTURE PASSED: " + output)
	quit(0)
