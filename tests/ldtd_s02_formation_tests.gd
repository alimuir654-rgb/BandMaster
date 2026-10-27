extends SceneTree
const Scene = preload("res://poc/ldtd_formation_rehearsal.tscn")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	get_root().size = Vector2i(390, 844)
	DisplayServer.window_set_size(Vector2i(390, 844))
	var view: Control = Scene.instantiate()
	get_root().add_child(view)
	for i in range(8):
		await process_frame
	if not _check(view.stage == "recruit", "must begin at formation"):
		return
	var title: Label = view.find_child("PlayerFacingTitle", true, false)
	var photo: TextureRect = view.find_child("RepoBackedFormationPhoto", true, false)
	var primary: Button = view.find_child("FormationPrimaryAction", true, false)
	if not _check(title != null and title.text.contains("LIVIN’ THE DREAM"), "brand"):
		return
	if not _check(photo != null and photo.texture != null, "real source photo"):
		return
	if not _check(primary != null and primary.focus_mode == Control.FOCUS_ALL, "keyboard primary"):
		return
	var px: float = float(DisplayServer.window_get_size().x) / maxf(view.get_viewport_rect().size.x, 1.0)
	if not _check(primary.get_global_rect().size.y * px >= 44.0, "44 physical px primary"):
		return
	if not _check(view._choice_buttons["Jo"].get_global_rect().size.y * px >= 44.0, "44 physical px choices"):
		return
	view.choose_drummer("rae")
	view.choose_bassist("dev")
	view.commit_stage()
	if not _check(view.stage == "social" and view.preview_state["members"].size() == 3, "real candidate formation"):
		return
	if not _check(view.preview_state["members"][1]["name"] == "Rae Ellis" and view.preview_state["members"][2]["name"] == "Dev Shah", "selected roster"):
		return
	var original_cash: int = int(view.preview_state["cash"])
	view.commit_stage()
	if not _check(view.stage == "social" and int(view.preview_state["cash"]) == original_cash, "social not auto-charged"):
		return
	view.choose_outing("watch_gig")
	view.commit_stage()
	if not _check(view.stage == "rehearsal" and view.settlement_count == 1, "social settled once"):
		return
	if not _check(int(view.preview_state["cash"]) == 105 and int(view.preview_state["tour_day"]) == 2, "real £15 outing and one day"):
		return
	view.commit_stage()
	if not _check(view.stage == "rehearsal" and view.settlement_count == 1, "rehearsal not auto-settled"):
		return
	view.choose_room_focus("connect")
	view.commit_stage()
	if not _check(view.stage == "summary" and view.settlement_count == 2, "real rehearsal settled once"):
		return
	if not _check(int(view.preview_state["cash"]) == 105 and int(view.preview_state["tour_day"]) == 3, "connect costs £0 and one day"):
		return
	if not _check(int(view.preview_state["relationships"]["0_1"]) == 48, "social plus rehearsal trust model"):
		return
	var immutable: String = JSON.stringify(view.preview_state)
	view.commit_stage()
	if not _check(JSON.stringify(view.preview_state) == immutable and view.settlement_count == 2, "summary never double-settles"):
		return
	for i in range(5):
		await process_frame
	primary = view.find_child("FormationPrimaryAction", true, false)
	if not _check(primary != null and primary.disabled, "completed action disabled"):
		return
	view.queue_free()
	for i in range(3):
		await process_frame
	var second: Control = Scene.instantiate()
	get_root().add_child(second)
	for i in range(6):
		await process_frame
	second.commit_stage()
	second.choose_outing("dinner")
	second.commit_stage()
	second.choose_room_focus("tighten")
	second.commit_stage()
	if not _check(second.stage == "summary" and second.settlement_count == 2, "default line-up real journey"):
		return
	if not _check(int(second.preview_state["cash"]) == 81, "£24 meal plus £15 practice cost exactly once"):
		return
	if not _check(int(second.preview_state["readiness"]) > 20, "rehearsal improves actual readiness"):
		return
	if not _check(int(second.preview_state["tour_day"]) == 3, "two actions advance two days"):
		return
	if not _check(second.preview_state["career_journal"].size() >= 2, "real preview journal"):
		return
	for when in ["day", "dusk", "night"]:
		second.set_phase(when)
		for i in range(3):
			await process_frame
		var bg: ColorRect = second.find_child("FormationBackdrop", true, false)
		if not _check(bg != null, "phase background exists " + when):
			return
		if when == "day" and not _check(bg.color == Color("#EDE5D7"), "DAY warm and light"):
			return
		if when == "night" and not _check(bg.color == Color("#101820"), "NIGHT graphite"):
			return
	if not _check(ResourceLoader.exists("res://poc/ldtd_career_scene_shell.tscn"), "gallery exists"):
		return
	print("LDTD S02 FORMATION REHEARSAL MODEL AND ONCE-ONLY TESTS PASSED")
	second.queue_free()
	quit(0)
func _check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("LDTD S02 TEST FAILURE: " + message)
		quit(1)
	return ok
