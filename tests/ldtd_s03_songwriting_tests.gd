extends SceneTree
const Model = preload("res://Scripts/ldtd_songwriting_preview.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, reason: String) -> void:
	if not condition:
		failures += 1
		push_error("S03 FAILURE: " + reason)

func _run() -> void:
	var original: Dictionary = Model.sample_state()
	var snapshot: String = JSON.stringify(original)
	var invalid: Dictionary = Model.simulate(original, "Lyric", "Verse / Chorus", "NO", 0)
	_check(not bool(invalid.get("ok", false)), "invalid title rejected without spending a day")
	_check(JSON.stringify(original) == snapshot, "rejected preview preserves caller")
	var first: Dictionary = Model.simulate(original, "Lyric", "Verse / Chorus", "LATE TRAIN", 0)
	_check(bool(first.get("ok", false)) and int(first.get("days", -1)) == 1, "first session uses authoritative one-day rule")
	_check(int(first.get("cash", 1)) == 0 and int(first.get("progress", -1)) == 1, "first draft no invented cash and 1/3 progress")
	_check(JSON.stringify(original) == snapshot, "successful preview also deep copies caller")
	var second: Dictionary = Model.simulate(first.get("state", {}), "Riff", "Slow Build", "LATE TRAIN", 1)
	_check(bool(second.get("ok", false)) and int(second.get("progress", -1)) == 2, "second session advances existing draft")
	var third: Dictionary = Model.simulate(second.get("state", {}), "Groove", "Loose Jam", "LATE TRAIN", 2)
	_check(bool(third.get("ok", false)) and bool(third.get("finished", false)), "third session finishes original")
	_check(third.get("state", {}).get("song_catalogue", []).size() == 1, "exactly one original in catalogue")
	var duplicate: Dictionary = Model.simulate(third.get("state", {}), "Riff", "Loose Jam", "LATE TRAIN", 0)
	_check(not bool(duplicate.get("ok", false)), "duplicate title rejected without cost")

	var packed: PackedScene = load("res://poc/ldtd_songwriting_journey.tscn")
	_check(packed != null, "S03 isolated Godot scene exists")
	if packed == null:
		quit(1)
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	for i in range(12):
		await process_frame
	_check(view.stage == "editing" and view.commits == 0, "starts in editable session without settlement")
	var room: TextureRect = view.find_child("RealDaylightWritingRoom", true, false)
	var board: TextureRect = view.find_child("PhotographedSongwritingBoard", true, false)
	var notebook: TextureRect = view.find_child("SongwritingNotebookMaterial", true, false)
	var transport: TextureButton = view.find_child("PhotographicSongwritingTransport", true, false)
	var rotary: Control = view.find_child("Lab084ArrangementRotary", true, false)
	var primary: Button = view.find_child("SongwritingCommitSession", true, false)
	var stats: Label = view.find_child("ReadOnlySongwritingStats", true, false)
	_check(room != null and room.texture != null, "real photographed bright rehearsal room imported")
	_check(board != null and board.texture != null and notebook != null and notebook.texture != null, "photo cork and physical notebook source")
	_check(transport != null and transport.texture_normal != null and transport.texture_hover != null and transport.texture_disabled != null, "actual Lab07 five-state transport")
	_check(rotary != null and rotary.control_kind == "focus" and not rotary.read_only, "real Lab08.4 interactive rotary")
	_check(primary != null and primary.get_theme_stylebox("normal") is StyleBoxTexture, "session commitment has original raster paper art")
	_check(stats != null and stats.focus_mode == Control.FOCUS_NONE, "career outcome stats read-only")
	_check(view._choice_buttons.has("IdeaLyric") and view._choice_buttons.has("Form0"), "meaningful native pad choices present")
	var sample_pad: TextureButton = view._choice_buttons.get("IdeaLyric")
	var inset: Panel = sample_pad.find_child("PhysicalCaptionInsert", true, false) as Panel
	var native_caption: Label = sample_pad.find_child("NativePadCaption", true, false) as Label
	_check(inset != null and inset.get_theme_stylebox("panel") is StyleBoxFlat, "original photo's baked JAM lettering is physically masked by inset")
	_check(native_caption != null and native_caption.text == "LYRIC", "native player choice is readable above inset, not baked into photo")
	view.choose_idea("Groove")
	for i in range(4):
		await process_frame
	view.choose_form("Slow Build")
	for i in range(4):
		await process_frame
	view.commit_session()
	for i in range(6):
		await process_frame
	_check(view.commits == 1 and int(view.local_state.get("song_draft_progress", 0)) == 1, "one explicit session charged once")
	_check(int(view.local_state.get("tour_day", 0)) == 8, "first session advances one day")
	view.commit_session()
	for i in range(6):
		await process_frame
	view.commit_session()
	for i in range(6):
		await process_frame
	_check(view.stage == "finished" and view.commits == 3, "third session finishes once")
	_check(view.local_state.get("song_catalogue", []).size() == 1, "real song in local catalogue")
	var finished_snapshot: String = JSON.stringify(view.local_state)
	view.commit_session()
	_check(JSON.stringify(view.local_state) == finished_snapshot and view.commits == 3, "disabled finished action cannot double-settle")
	_check(JSON.stringify(original) == snapshot, "production-like input never mutated by scene")
	view.queue_free()
	if failures > 0:
		push_error("S03 FAILED: %d checks" % failures)
		quit(1)
	else:
		print("LDTD S03 SONGWRITING MODEL AND THREE-SESSION INPUT TESTS PASSED")
		quit(0)
