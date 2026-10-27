extends SceneTree
## Actual Godot S02 viewport screenshot; no synthetic image substitution.
const Scene = preload("res://poc/ldtd_formation_rehearsal.tscn")
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var width := 390
	var height := 844
	var phase := "day"
	var stage := "recruit"
	var output := "screenshots/s02-recruit-day-390x844.png"
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
	if not ["recruit", "social", "rehearsal", "summary"].has(stage) or not ["day", "dusk", "night"].has(phase):
		_fail("unknown capture stage or phase")
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var view: Control = Scene.instantiate()
	get_root().add_child(view)
	for i in range(5):
		await process_frame
	if stage != "recruit":
		view.commit_stage()
	if stage in ["rehearsal", "summary"]:
		view.choose_outing("dinner")
		view.commit_stage()
	if stage == "summary":
		view.choose_room_focus("tighten")
		view.commit_stage()
	view.set_phase(phase)
	for i in range(18):
		await process_frame
	if view.stage != stage:
		_fail("wrong requested stage")
		return
	var title: Label = view.find_child("PlayerFacingTitle", true, false)
	var primary: Button = view.find_child("FormationPrimaryAction", true, false)
	var photo: TextureRect = view.find_child("RepoBackedFormationPhoto", true, false)
	var dock: Panel = view.find_child("FormationActionDock", true, false)
	var scroll: ScrollContainer = view.find_child("FormationScroll", true, false)
	var stats: Label = view.find_child("ReadOnlyStats", true, false)
	if title == null or primary == null or photo == null or photo.texture == null or dock == null or scroll == null or stats == null:
		_fail("missing native material or interactive component")
		return
	var px: float = float(DisplayServer.window_get_size().x) / maxf(view.get_viewport_rect().size.x, 1.0)
	var screen: Vector2 = Vector2(width, height)
	if primary.get_global_rect().size.y * px < 44.0:
		_fail("primary below 44 physical px")
		return
	if primary.get_global_rect().end.y * px > screen.y + 3.0:
		_fail("dock CTA outside device")
		return
	if scroll.get_global_rect().end.y * px > dock.get_global_rect().position.y * px + 3.0:
		_fail("scroll content obscured by action dock")
		return
	if title.get_theme_font_size("font_size") * title.get_global_transform().get_scale().y * px < 20.0:
		_fail("player-facing title too small")
		return
	if stats.focus_mode != Control.FOCUS_NONE:
		_fail("read-only stats must not accept focus")
		return
	var journal: RichTextLabel = view.find_child("JournalEntry", true, false)
	var gate: Label = view.find_child("MaterialGate", true, false)
	if journal == null or gate == null:
		_fail("missing scrapbook journal or material provenance")
		return
	if journal.position.y + journal.size.y + 3.0 > gate.position.y:
		_fail("scrapbook journal and material gate overlap (note end %.1f, gate top %.1f)" % [journal.position.y + journal.size.y, gate.position.y])
		return
	var chapter: Label = view.find_child("ChapterLabel", true, false)
	var gallery: Button = view.find_child("ReturnToGallery", true, false)
	if chapter == null or gallery == null or chapter.get_global_rect().end.x > gallery.get_global_rect().position.x + 3.0:
		_fail("mobile chapter label collides with gallery action")
		return
	for key in view._choice_buttons.keys():
		var button: Button = view._choice_buttons[key]
		if button.get_global_rect().size.y * px < 44.0:
			_fail("small candidate/choice button " + str(key))
			return
	if width <= 390 and stage == "recruit":
		var last_choice: Button = view._choice_buttons.get("Dev")
		if last_choice == null or last_choice.get_global_rect().end.y * px > dock.get_global_rect().position.y * px - 3.0:
			_fail("bass recruitment choice hidden behind mobile action dock")
			return
	if width >= 900 and stage == "recruit":
		# S02B owner P0: both role choices must be present in landscape FIRST FOLD,
		# not buried under the historic 248px full-width photograph.
		var image_frame: Panel = view.find_child("FormationPhotoFrame", true, false)
		if image_frame == null:
			_fail("missing realistic room photograph frame")
			return
		for candidate_id in ["Jo", "Rae", "Sam", "Dev"]:
			var candidate_btn: Button = view._choice_buttons.get(candidate_id)
			if candidate_btn == null:
				_fail("missing visible audition choice: " + candidate_id)
				return
			if candidate_btn.get_global_rect().end.y * px > dock.get_global_rect().position.y * px - 3.0:
				_fail("desktop choice obscured by dock: " + candidate_id)
				return
			if candidate_btn.get_global_rect().intersects(image_frame.get_global_rect()):
				_fail("audition card overlaps rehearsal photo: " + candidate_id)
				return
			if not (candidate_btn.get_theme_stylebox("normal") is StyleBoxTexture):
				_fail("generic default desktop audition button: " + candidate_id)
				return
	var bitmap: Image = get_root().get_texture().get_image()
	if bitmap.get_width() < width or bitmap.get_height() < height:
		_fail("wrong actual renderer dimensions")
		return
	# S02B daylight is a full-bleed, *textured* original material, not a
	# flat RGB fill. Read the authoritative environment and material phase,
	# rather than comparing pixels to an obsolete flat #EDE5D7 color swatch.
	var environment: ColorRect = view.find_child("FormationBackdrop", true, false)
	var desk: TextureRect = view.find_child("FormationSunlitDesk", true, false)
	var sheet: TextureRect = view.find_child("FormationNotebookMaterial", true, false)
	var expected: Color = Color("#EDE5D7") if phase == "day" else (Color("#34444A") if phase == "dusk" else Color("#101820"))
	if environment == null or environment.color != expected or desk == null or desk.texture == null or sheet == null or sheet.texture == null:
		_fail("phase environment material or genuine stationery missing")
		return
	if phase == "day" and desk.modulate != Color.WHITE:
		_fail("daylight material is not sunlit")
		return
	if phase == "night" and desk.modulate == Color.WHITE:
		_fail("night does not dim paper world")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	if bitmap.save_png(ProjectSettings.globalize_path(output)) != OK:
		_fail("failed saving actual Godot image")
		return
	print("LDTD S02 ACTUAL GODOT SCREENSHOT PASSED: " + output)
	view.queue_free()
	quit(0)
func _fail(message: String) -> void:
	push_error("LDTD S02 SCREENSHOT FAILURE: " + message)
	quit(1)
