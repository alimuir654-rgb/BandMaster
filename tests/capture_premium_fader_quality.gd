extends SceneTree
## Physical screenshot of native Godot renderer, not a composite mock.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var phase := "day"
	var level := 50
	var width := 390
	var height := 844
	var output := "screenshots/premium-faders-day-50-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--level="):
			level = int(arg.trim_prefix("--level="))
		elif arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day", "dusk", "night"].has(phase) or not [0, 50, 100].has(level) or width < 320 or height < 600:
		_fail("bad input")
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/premium_fader_quality_lab.tscn")
	if packed == null:
		_fail("scene missing")
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	view.set_phase(phase)
	view.set_levels(float(level), float(level))
	for frame in range(18):
		await process_frame
	var h: Control = view.find_child("PremiumHorizontalFader", true, false)
	var v: Control = view.find_child("PremiumVerticalFader", true, false)
	if h == null or v == null or int(h.value) != level or int(v.value) != level:
		_fail("control state mismatch")
		return
	if v.get_global_rect().end.y > view.get_viewport_rect().size.y + 2.0 or h.get_global_rect().end.x > view.get_viewport_rect().size.x + 2.0:
		_fail("hardware clipped")
		return
	if h.get_global_rect().size.y < 80.0 or v.get_global_rect().size.x < 110.0:
		_fail("hardware below minimum physical size")
		return
	var image := get_root().get_texture().get_image()
	var expected: Color = Color("#ECE7DA") if phase == "day" else (Color("#283941") if phase == "dusk" else Color("#0B1116"))
	var actual: Color = image.get_pixel(3, 3)
	if absf(actual.r - expected.r) > 0.12 or absf(actual.g - expected.g) > 0.12 or absf(actual.b - expected.b) > 0.12:
		_fail("wrong background")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var saved := image.save_png(ProjectSettings.globalize_path(output))
	if saved != OK or image.get_width() < width or image.get_height() < height:
		_fail("PNG save failed")
		return
	print("PREMIUM FADER CAPTURE PASSED: " + output)
	view.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("PREMIUM FADER CAPTURE FAILURE: " + message)
	quit(1)
