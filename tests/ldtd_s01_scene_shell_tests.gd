extends SceneTree
## S01 native contract: six distinct review contexts, phase, branding, safe links.
func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	get_root().size = Vector2i(1280, 720)
	var scene: PackedScene = load("res://poc/ldtd_career_scene_shell.tscn")
	if scene == null:
		_fail("scene resource missing")
		return
	var view: Control = scene.instantiate()
	get_root().add_child(view)
	for frame in range(5):
		await process_frame
	for category in ["career", "formation", "songwriting", "tour", "gig", "studio"]:
		view.set_world(category)
		for frame in range(3):
			await process_frame
		if view.family != category:
			_fail("scene category not changed")
			return
		var title: Label = view.find_child("PlayerFacingTitle", true, false)
		var stage: Label = view.find_child("SceneEyebrow", true, false)
		var photo: TextureRect = view.find_child("RepoBackedScenePhotography", true, false)
		if title == null or not title.text.contains("LIVIN") or title.text.contains("BANDMASTER"):
			_fail("player-facing name wrong")
			return
		if stage == null or stage.text.is_empty() or photo == null or photo.texture == null:
			_fail("missing context or repo-backed photographic asset: " + category)
			return
	for when in ["day", "dusk", "night"]:
		view.set_phase(when)
		for frame in range(3):
			await process_frame
		var bg: ColorRect = view.find_child("SceneSweepBackdrop", true, false)
		if bg == null:
			_fail("missing scene environment")
			return
		var expected: Color = Color("#EFEADF") if when == "day" else (Color("#283A40") if when == "dusk" else Color("#0E1318"))
		if bg.color != expected:
			_fail("wrong " + when + " material phase")
			return
	view.set_phase("day")
	for frame in range(3):
		await process_frame
	if not ResourceLoader.exists("res://poc/premium_transport_proof.tscn") or not ResourceLoader.exists("res://poc/premium_mixer_module_lab.tscn"):
		_fail("studio proof links unavailable")
		return
	# S03/S04/S05 now have real isolated journeys. A previous S01-only
	# assertion treated Tour as a placeholder and became obsolete at S04.
	for path in ["res://poc/ldtd_songwriting_journey.tscn",
			"res://poc/ldtd_tour_planning.tscn",
			"res://poc/ldtd_gig_night.tscn"]:
		if not ResourceLoader.exists(path):
			_fail("implemented scene link missing: "+path)
			return
	view.set_world("career")
	for frame in range(3):
		await process_frame
	view._open_preview()
	var state: Label = view.find_child("SceneStatus", true, false)
	if state == null or not state.text.contains("PENDING"):
		_fail("unimplemented career preview misrepresented as playable")
		return
	print("LDTD S01 SIX SCENE NAVIGATION AND SAFE STATE TESTS PASSED")
	view.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("LDTD S01 TEST FAILURE: " + message)
	quit(1)
