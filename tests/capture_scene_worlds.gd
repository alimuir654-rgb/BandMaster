extends SceneTree
## Actual Godot renderer screenshot harness; does not read or write career saves.
const Worlds = preload("res://Scripts/scene_world_theme.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var family := "tour"
	var phase := "day"
	var width := 390
	var height := 844
	var output := "screenshots/scene-world-day-mobile.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--family="):
			family = arg.trim_prefix("--family=")
		elif arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not Worlds.FAMILIES.has(family) or not Worlds.PHASES.has(phase) or width < 320 or height < 600:
		push_error("SCENE WORLD CAPTURE: Invalid arguments")
		quit(1)
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var scene: PackedScene = load("res://poc/scene_worlds_day_night.tscn")
	if scene == null:
		push_error("SCENE WORLD CAPTURE: Scene missing")
		quit(1)
		return
	var ui: Control = scene.instantiate()
	get_root().add_child(ui)
	ui.set_context(family, phase)
	for frame in range(20):
		await process_frame
	var primary: Button = ui.find_child("PrimaryAction", true, false)
	if primary == null:
		push_error("SCENE WORLD CAPTURE: Primary action missing")
		quit(1)
		return
	var pixel_scale := float(DisplayServer.window_get_size().x) / float(ui.get_viewport_rect().size.x)
	var actual_touch_px := primary.custom_minimum_size.y * pixel_scale
	var body: Label = ui.find_child("BodyIntroduction", true, false)
	if actual_touch_px < 44.0 or body == null or float(body.get_theme_font_size("font_size")) * pixel_scale < 15.0:
		push_error("SCENE WORLD CAPTURE: Physical touch or body text below accessibility target")
		quit(1)
		return
	var status: Label = ui.find_child("LabStatus", true, false)
	primary.pressed.emit()
	if status == null or not status.text.contains("SAVE AND ECONOMY UNTOUCHED"):
		push_error("SCENE WORLD CAPTURE: Action did not respond")
		quit(1)
		return
	var image := get_root().get_texture().get_image()
	var sample := image.get_pixel(3, 3)
	var expected: Color = Worlds.palette(family, phase)["bg"]
	if absf(sample.r - expected.r) > 0.12 or absf(sample.g - expected.g) > 0.12 or absf(sample.b - expected.b) > 0.12:
		push_error("SCENE WORLD CAPTURE: Wrong background pixel; phase may not have rendered")
		quit(1)
		return
	var directory := output.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var result := image.save_png(ProjectSettings.globalize_path(output))
	ui.queue_free()
	if result != OK or image.get_width() < width or image.get_height() < height:
		push_error("SCENE WORLD CAPTURE: PNG output failed")
		quit(1)
		return
	print("SCENE WORLD CAPTURE SAVED: " + output)
	quit(0)
