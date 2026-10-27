extends SceneTree
## Capture actual Godot gallery render at physical device sizes.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var family := "tour"
	var phase := "day"
	var width := 390
	var height := 844
	var output := "screenshots/convergence-tour-day-390x844.png"
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
	if not ["tour", "songwriting", "gig"].has(family) or not Worlds.PHASES.has(phase) or width < 320 or height < 600:
		push_error("SPRINT 08 CAPTURE: invalid arguments")
		quit(1)
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/scene_worlds_convergence.tscn")
	if packed == null:
		push_error("SPRINT 08 CAPTURE: gallery unavailable")
		quit(1)
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	view.set_family(family)
	view.set_phase(phase)
	for i in range(20):
		await process_frame
	var primary: Button = view.find_child("ConvergencePrimary", true, false) as Button
	var dock: Control = view.find_child("ConvergenceActionDock", true, false) as Control
	var display: Label = view.find_child("ConvergenceHeading", true, false) as Label
	var body: Label = view.find_child("ConvergenceBody", true, false) as Label
	if primary == null or dock == null or display == null or body == null:
		push_error("SPRINT 08 CAPTURE: missing typography or action controls")
		quit(1)
		return
	var px := float(DisplayServer.window_get_size().x) / float(view.get_viewport_rect().size.x)
	if primary.custom_minimum_size.y * px < 44.0 or primary.get_global_rect().end.y * px > float(height) - 4.0:
		push_error("SPRINT 08 CAPTURE: first-fold or touch target failed")
		quit(1)
		return
	if float(body.get_theme_font_size("font_size")) * px < 15.0 or display.get_theme_font("font") == null:
		push_error("SPRINT 08 CAPTURE: text import or physical size failed")
		quit(1)
		return
	var image := get_root().get_texture().get_image()
	var expected: Color = Worlds.palette(family, phase)["bg"]
	var sample := image.get_pixel(3, 3)
	if absf(sample.r - expected.r) > 0.12 or absf(sample.g - expected.g) > 0.12 or absf(sample.b - expected.b) > 0.12:
		push_error("SPRINT 08 CAPTURE: background wrong")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var saved := image.save_png(ProjectSettings.globalize_path(output))
	view.queue_free()
	if saved != OK or image.get_width() < width or image.get_height() < height:
		push_error("SPRINT 08 CAPTURE: image output failed")
		quit(1)
		return
	print("SPRINT 08 CAPTURE PASSED: " + output)
	quit(0)
