extends SceneTree
## Real Godot screenshots only. Six-world × day/night × 4-device matrix.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var category := "career"
	var when := "day"
	var width := 390
	var height := 844
	var output := "screenshots/ltd-career-day-390x844.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--family="):
			category = argument.trim_prefix("--family=")
		elif argument.begins_with("--phase="):
			when = argument.trim_prefix("--phase=")
		elif argument.begins_with("--width="):
			width = int(argument.trim_prefix("--width="))
		elif argument.begins_with("--height="):
			height = int(argument.trim_prefix("--height="))
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	if not ["career", "formation", "songwriting", "tour", "gig", "studio"].has(category) or not ["day", "night"].has(when):
		_fail("bad scene family or phase")
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/ldtd_career_scene_shell.tscn")
	if packed == null:
		_fail("scene missing")
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	for i in range(3):
		await process_frame
	view.set_world(category)
	view.set_phase(when)
	for i in range(18):
		await process_frame
	var title: Label = view.find_child("PlayerFacingTitle", true, false)
	var primary: Button = view.find_child("ScenePrimaryAction", true, false)
	var scene_card: Control = view.find_child("RepoBackedScenePhotography", true, false)
	var dock: Panel = view.find_child("SceneActionDock", true, false)
	var shell: Control = view.find_child("PhysicalSceneShell", true, false)
	var bg: ColorRect = view.find_child("SceneSweepBackdrop", true, false)
	var scroll: ScrollContainer = view.find_child("SceneSweepScroll", true, false)
	if title == null or primary == null or scene_card == null or dock == null or shell == null or bg == null or scroll == null:
		_fail("scene shell missing layout component")
		return
	var px: float = float(DisplayServer.window_get_size().x) / maxf(view.get_viewport_rect().size.x, 1.0)
	var win: Vector2 = Vector2(float(width), float(height))
	if primary.get_global_rect().size.y * px < 44.0:
		_fail("primary button under 44 physical pixels")
		return
	if float(title.get_theme_font_size("font_size")) * title.get_global_transform().get_scale().y * px < 22.0:
		_fail("branding unreadable")
		return
	if primary.get_global_rect().end.y * px > win.y + 2.0 or dock.get_global_rect().end.x * px > win.x + 2.0:
		_fail("footer outside viewport")
		return
	if scroll.get_global_rect().end.y > dock.get_global_rect().position.y + 3.0:
		_fail("scrolling content obscured by fixed action dock")
		return
	if scene_card.texture == null:
		_fail("real WebP photo missing")
		return
	var bitmap: Image = get_root().get_texture().get_image()
	if bitmap.get_width() < width or bitmap.get_height() < height:
		_fail("image output dimensions wrong")
		return
	var corner: Color = bitmap.get_pixel(2, 2)
	var expected: Color = Color("#EFEADF") if when == "day" else Color("#0E1318")
	if absf(corner.r - expected.r) > 0.13 or absf(corner.g - expected.g) > 0.13 or absf(corner.b - expected.b) > 0.13:
		_fail("day/night environment mismatch")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	if bitmap.save_png(ProjectSettings.globalize_path(output)) != OK:
		_fail("PNG save failed")
		return
	print("LDTD S01 ACTUAL GODOT SCREENSHOT PASSED: " + output)
	view.queue_free()
	quit(0)

func _fail(why: String) -> void:
	push_error("LDTD S01 SCREENSHOT FAILURE: " + why)
	quit(1)
