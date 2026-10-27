extends SceneTree
## Genuine Godot 4.7.2 screenshot and geometry gate for S03 at real device dimensions.
const Scene = preload("res://poc/ldtd_songwriting_journey.tscn")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var width: int = 390
	var height: int = 844
	var phase: String = "day"
	var stage: String = "editing"
	var output: String = "screenshots/s03-editing-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--stage="):
			stage = arg.trim_prefix("--stage=")
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day", "dusk", "night"].has(phase) or not ["editing", "finished"].has(stage):
		_fail("unknown phase/stage")
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var view: Control = Scene.instantiate()
	get_root().add_child(view)
	for i in range(7):
		await process_frame
	if stage == "finished":
		for i in range(3):
			view.commit_session()
			for j in range(4):
				await process_frame
	view.set_phase(phase)
	for i in range(17):
		await process_frame
	if view.stage != stage:
		_fail("wrong songwriting stage")
		return
	var photo: TextureRect = view.find_child("RealDaylightWritingRoom", true, false)
	var notebook: TextureRect = view.find_child("SongwritingNotebookMaterial", true, false)
	var title: Label = view.find_child("PlayerFacingTitle", true, false)
	var primary: Button = view.find_child("SongwritingCommitSession", true, false)
	var scroll: ScrollContainer = view.find_child("SongwritingScroll", true, false)
	var dock: Panel = view.find_child("SongwritingActionDock", true, false)
	var stats: Label = view.find_child("ReadOnlySongwritingStats", true, false)
	var transport: TextureButton = view.find_child("PhotographicSongwritingTransport", true, false)
	var rotary: Control = view.find_child("Lab084ArrangementRotary", true, false)
	if photo == null or photo.texture == null or notebook == null or notebook.texture == null or title == null or primary == null or scroll == null or dock == null or stats == null or transport == null or rotary == null:
		_fail("missing native source-backed scene material or input")
		return
	var px: float = float(DisplayServer.window_get_size().x) / maxf(view.get_viewport_rect().size.x, 1.0)
	if primary.get_global_rect().size.y * px < 44.0:
		_fail("primary action smaller than 44 physical pixels")
		return
	if primary.get_global_rect().end.y * px > float(height) + 3.0:
		_fail("primary action below device bottom")
		return
	if scroll.get_global_rect().end.y * px > dock.get_global_rect().position.y * px + 3.0:
		_fail("scroll obscures fixed action dock")
		return
	if stats.focus_mode != Control.FOCUS_NONE:
		_fail("read-only career stats incorrectly focusable")
		return
	if stage == "editing":
		for key in ["IdeaRiff", "IdeaLyric", "IdeaGroove", "Form0", "Form1", "Form2"]:
			var pad: TextureButton = view._choice_buttons.get(key)
			if pad == null:
				_fail("missing songwriting choice " + key)
				return
			if pad.get_global_rect().size.y * px < 44.0:
				_fail("songwriting pad below 44 physical pixels: " + key)
				return
			if pad.get_global_rect().end.y * px > dock.get_global_rect().position.y * px - 3.0:
				_fail("songwriting idea/form hidden behind action dock: " + key)
				return
			if pad.get_global_rect().intersects(photo.get_global_rect()):
				_fail("songwriting choice overlaps real photo: " + key)
				return
	if stage == "finished" and not primary.disabled:
		_fail("finished session can be charged again")
		return
	var img: Image = get_root().get_texture().get_image()
	if img.get_width() < width or img.get_height() < height:
		_fail("Godot screenshot dimensions smaller than actual device")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	if img.save_png(ProjectSettings.globalize_path(output)) != OK:
		_fail("Godot renderer did not save screenshot")
		return
	print("LDTD S03 ACTUAL GODOT SCREENSHOT PASSED: " + output)
	view.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("S03 SCREENSHOT FAILURE: " + message)
	quit(1)
