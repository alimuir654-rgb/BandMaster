extends SceneTree
## Capture real renderer states at user-device sizes.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var phase := "day"
	var level := 50
	var width := 390
	var height := 844
	var output := "screenshots/mixer-day-50-390x844.png"
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
		_fail("capture arguments")
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/premium_mixer_module_lab.tscn")
	if packed == null:
		_fail("scene unavailable")
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	view.set_phase(phase)
	view.set_levels(float(level), float(level))
	view.set_stat_reading(68.0)
	for frame in range(18):
		await process_frame
	var f: Control = view.find_child("RigHorizontalInput", true, false)
	var v: Control = view.find_child("RigVerticalInput", true, false)
	var m: Control = view.find_child("RigReadOnlyHypeMeter", true, false)
	var rack: Panel = view.find_child("PhotographicHardwareRack", true, false)
	if f == null or v == null or m == null or rack == null:
		_fail("controls missing")
		return
	if int(f.value) != level or int(v.value) != level or int(m.reading) != 68:
		_fail("value and independent stat mismatch")
		return
	if m.focus_mode != Control.FOCUS_NONE or m.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("meter improperly editable")
		return
	var viewport: Rect2 = view.get_viewport_rect()
	if rack.get_global_rect().end.x > viewport.size.x + 2.0 or rack.get_global_rect().end.y > viewport.size.y + 2.0:
		_fail("enclosure clipped")
		return
	for ctrl in [f, v, m]:
		var child_bounds: Rect2 = ctrl.get_global_rect()
		if child_bounds.size.x < 85.0 or child_bounds.size.y < 80.0:
			_fail("hardware drawn below acceptable review size")
			return
		if not rack.get_global_rect().grow(2.0).encloses(child_bounds):
			_fail("hardware outside enclosure")
			return
	if v.get_global_rect().intersects(m.get_global_rect()):
		_fail("input and read-only monitor overlap")
		return
	for label_name in ["HorizontalInputValue", "VerticalInputValue", "ReadOnlyStatValue", "HorizontalInputLabel", "VerticalInputLabel", "ReadOnlyStatLabel"]:
		var label: Label = view.find_child(label_name, true, false)
		if label == null:
			_fail("semantic caption missing: " + label_name)
			return
		if label.get_combined_minimum_size().x > label.size.x + 3.0:
			_fail("semantic caption overflows hardware bay: " + label_name)
			return
	var image := get_root().get_texture().get_image()
	var target: Color = Color("#ECE7DA") if phase == "day" else (Color("#283941") if phase == "dusk" else Color("#0B1116"))
	var actual: Color = image.get_pixel(3, 3)
	if absf(target.r - actual.r) > 0.12 or absf(target.g - actual.g) > 0.12 or absf(target.b - actual.b) > 0.12:
		_fail("background did not switch with game phase")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var result: Error = image.save_png(ProjectSettings.globalize_path(output))
	if result != OK or image.get_width() < width or image.get_height() < height:
		_fail("image write failed")
		return
	print("PREMIUM MIXER SCREENSHOT PASSED: " + output)
	view.queue_free()
	quit(0)

func _fail(reason: String) -> void:
	push_error("PREMIUM MIXER CAPTURE FAILURE: " + reason)
	quit(1)
