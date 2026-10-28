extends SceneTree
## S04 actual Godot 4.7.2 native renderer, device geometry and choice-first gate.
const Scene = preload("res://poc/ldtd_tour_planning.tscn")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var width: int = 390
	var height: int = 844
	var phase: String = "day"
	var stage: String = "planning"
	var output: String = "screenshots/s04-planning-day-390x844.png"
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
	if not ["day","dusk","night"].has(phase) or not ["planning","confirmed"].has(stage):
		_fail("unknown phase/stage")
		return
	get_root().size = Vector2i(width,height)
	DisplayServer.window_set_size(Vector2i(width,height))
	var view: Control = Scene.instantiate()
	get_root().add_child(view)
	for i in range(8):
		await process_frame
	if stage=="confirmed":
		view.toggle_load()
		for i in range(3):
			await process_frame
		view.commit_plan()
		for i in range(4):
			await process_frame
	view.set_phase(phase)
	for i in range(17):
		await process_frame
	if view.stage!=stage:
		_fail("unexpected tour stage")
		return
	var cork: TextureRect = view.find_child("PhotographedTourCork",true,false)
	var photo: TextureRect = view.find_child("RepoBackedTourHomePhoto",true,false)
	var paper: TextureRect = view.find_child("OriginalClippedItinerarySheet",true,false)
	var primary: TextureButton = view.find_child("TourConfirmBooking",true,false)
	var scroll: ScrollContainer = view.find_child("TourPlanningScroll",true,false)
	var dock: Panel = view.find_child("TourActionDock",true,false)
	var stats: Label = view.find_child("ReadOnlyTourStats",true,false)
	if cork==null or cork.texture==null or photo==null or photo.texture==null or paper==null or paper.texture==null or primary==null or scroll==null or dock==null or stats==null:
		_fail("missing source-backed physical material or real controls")
		return
	var px: float = float(DisplayServer.window_get_size().x)/maxf(view.get_viewport_rect().size.x,1.0)
	if primary.get_global_rect().size.y*px<44.0 or primary.get_global_rect().end.y*px>float(height)+3.0:
		_fail("booking stamp below 44 physical pixels or offscreen")
		return
	if scroll.get_global_rect().end.y*px>dock.get_global_rect().position.y*px+3.0:
		_fail("scroll intersects booking dock")
		return
	if stats.focus_mode!=Control.FOCUS_NONE:
		_fail("readonly cash/van stats incorrectly focusable")
		return
	if stage=="planning":
		for key in ["VenueBristol","VenueCardiff","VenueBirmingham","Journeydrive_home","Journeyovernight","SecureVanLoad"]:
			var ticket: TextureButton = view._choice_buttons.get(key)
			if ticket==null:
				_fail("missing consequential route control "+key)
				return
			if ticket.get_global_rect().size.y*px<44.0:
				_fail("route control below 44 physical px "+key)
				return
			if ticket.get_global_rect().end.y*px>dock.get_global_rect().position.y*px-3.0:
				_fail("venue, route or van load hidden behind dock "+key)
				return
			if ticket.get_global_rect().intersects(photo.get_global_rect()):
				_fail("route choice collides with real photograph "+key)
				return
		if not primary.disabled:
			_fail("unsecured load incorrectly allows booking")
			return
	if stage=="confirmed" and not primary.disabled:
		_fail("confirmed booking can be repeated")
		return
	var image: Image = get_root().get_texture().get_image()
	if image.get_width()<width or image.get_height()<height:
		_fail("actual Godot renderer dimensions smaller than device")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	if image.save_png(ProjectSettings.globalize_path(output))!=OK:
		_fail("Godot failed to save native screenshot")
		return
	print("LDTD S04 ACTUAL GODOT SCREENSHOT PASSED: "+output)
	view.queue_free()
	quit(0)

func _fail(reason: String) -> void:
	push_error("S04 SCREENSHOT FAILURE: "+reason)
	quit(1)
