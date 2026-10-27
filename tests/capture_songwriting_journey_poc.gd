extends SceneTree
## Render real Godot scene. Test first-fold, day/dusk, model state and readable controls.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var phase := "day"
	var width := 390
	var height := 844
	var output := "screenshots/song-journey-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day", "dusk", "result"].has(phase) or width < 320 or height < 600:
		push_error("SONG JOURNEY CAPTURE: invalid phase or viewport")
		quit(1)
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/songwriting_journey_poc.tscn")
	if packed == null:
		push_error("SONG JOURNEY CAPTURE: scene missing")
		quit(1)
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	view.set_title("LATE TRAIN")
	view.choose_idea("Lyric")
	view.advance()
	view.choose_form("Slow Build")
	view.choose_leader(1)
	view.choose_feel("SWELL")
	view.set_bpm(138)
	view.choose_part("BRIDGE")
	view.append_part()
	if phase == "result":
		for i in range(3):
			if view.stage == 0:
				view.advance()
			view.advance()
			view.commit_session()
	else:
		view.set_phase(phase)
	for i in range(20):
		await process_frame
	var paper: Control = view.find_child("JourneyNotebook", true, false)
	var primary: Button = view.find_child("JourneyPrimary", true, false)
	var footer: Control = view.find_child("JourneyActionDock", true, false)
	var backdrop: ColorRect = view.find_child("JourneyTimeBackdrop", true, false)
	var scroll: ScrollContainer = view.find_child("JourneyScroll", true, false)
	if paper == null or primary == null or footer == null or backdrop == null or scroll == null:
		push_error("SONG JOURNEY CAPTURE: required controls missing")
		quit(1)
		return
	var px := float(DisplayServer.window_get_size().x) / float(view.get_viewport_rect().size.x)
	if primary.custom_minimum_size.y * px < 44.0:
		push_error("SONG JOURNEY CAPTURE: action target below 44px")
		quit(1)
		return
	if primary.get_global_rect().end.y * px > float(height) - 3.0:
		push_error("SONG JOURNEY CAPTURE: primary action outside first fold")
		quit(1)
		return
	if paper.get_global_rect().position.y * px > float(height) * 0.52:
		push_error("SONG JOURNEY CAPTURE: notebook starts below half screen")
		quit(1)
		return
	if paper.get_global_rect().size.x <= 0 or scroll.get_global_rect().size.y <= 0:
		push_error("SONG JOURNEY CAPTURE: scroll or notebook collapsed")
		quit(1)
		return
	if phase == "result":
		if view.stage != 3 or view.local_state.get("song_catalogue", []).size() != 1 or view.commits != 3:
			push_error("SONG JOURNEY CAPTURE: result not real finished original")
			quit(1)
			return
	else:
		if view.stage != 1 or view.commits != 0 or view.local_state.get("song_catalogue", []).size() != 0:
			push_error("SONG JOURNEY CAPTURE: preview must not commit")
			quit(1)
			return
		var bpm: Label = view.find_child("JourneyTempoReadout", true, false)
		if bpm == null or bpm.get_line_count() != 1 or bpm.get_global_rect().size.x * px < 58.0:
			push_error("SONG JOURNEY CAPTURE: tempo readout wrapped")
			quit(1)
			return
	var image := get_root().get_texture().get_image()
	var actual: Color = image.get_pixel(3, 3)
	var expected: Color = Worlds.palette("songwriting", "dusk" if phase == "result" else phase)["bg"]
	if absf(actual.r - expected.r) > 0.12 or absf(actual.g - expected.g) > 0.12 or absf(actual.b - expected.b) > 0.12:
		push_error("SONG JOURNEY CAPTURE: incorrect simulated time-of-day palette")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var saved := image.save_png(ProjectSettings.globalize_path(output))
	view.queue_free()
	if saved != OK or image.get_width() < width or image.get_height() < height:
		push_error("SONG JOURNEY CAPTURE: screenshot save failed")
		quit(1)
		return
	print("SONG JOURNEY CAPTURE PASSED: " + output)
	quit(0)
