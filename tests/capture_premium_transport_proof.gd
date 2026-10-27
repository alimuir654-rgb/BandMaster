extends SceneTree
## Actual Godot viewport render, not a concept mock. Creates 36 state/phase/size screenshots in CI.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var width: int = 390
	var height: int = 844
	var phase: String = "day"
	var state: String = "standby"
	var output: String = "screenshots/transport-day-standby-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--state="):
			state = arg.trim_prefix("--state=")
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if width < 320 or height < 600 or not ["day", "dusk", "night"].has(phase) or not ["standby", "armed", "locked"].has(state):
		_fail("invalid capture args")
		return
	get_root().size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	var packed: PackedScene = load("res://poc/premium_transport_proof.tscn")
	if packed == null:
		_fail("could not load scene")
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	view.set_phase(phase)
	view.set_transport_armed(state == "armed")
	view.set_locked(state == "locked")
	for i in range(18):
		await process_frame
	var key: TextureButton = view.find_child("PhotographicTransportKey", true, false)
	var rig: Panel = view.find_child("TransportPhotoRack", true, false)
	var state_label: Label = view.find_child("TransportStateReadout", true, false)
	var heading: Label = view.find_child("TransportHeading", true, false)
	var disclaimer: Label = view.find_child("TransportProofDisclaimer", true, false)
	if key == null or rig == null or state_label == null or heading == null or disclaimer == null:
		_fail("material rig or semantic text missing")
		return
	var px: float = float(DisplayServer.window_get_size().x) / maxf(view.get_viewport_rect().size.x, 1.0)
	if key.get_global_rect().size.y * px < 90.0 or key.get_global_rect().size.x * px < 220.0:
		_fail("hardware below physical input size")
		return
	if not rig.get_global_rect().grow(2.0).encloses(key.get_global_rect()):
		_fail("photographic key escapes its coherent case")
		return
	if rig.get_global_rect().end.y > view.get_viewport_rect().size.y + 3.0:
		_fail("rack extends below device")
		return
	var finish_button: Button = view.find_child("FinishPunk", true, false)
	var subhead: Label = view.find_child("TransportModuleSubtitle", true, false)
	var explanation: Label = view.find_child("TransportRoleCopy", true, false)
	if finish_button == null or subhead == null or disclaimer == null or explanation == null:
		_fail("missing supporting transport text or selector")
		return
	for node in [state_label, subhead, disclaimer, explanation]:
		if node.get_combined_minimum_size().x > node.size.x + 3.0:
			_fail("text too wide for enclosure: " + node.name)
			return
		if not rig.get_global_rect().grow(2.0).encloses(node.get_global_rect()):
			_fail("text outside physical enclosure: " + node.name)
			return
	if state_label.get_global_rect().intersects(finish_button.get_global_rect()) or disclaimer.get_global_rect().intersects(finish_button.get_global_rect()):
		_fail("state, finish and disclaimer layers collide")
		return
	if explanation.get_global_rect().intersects(finish_button.get_global_rect()):
		_fail("explanation overlaps interactive selector")
		return
	if state == "locked" and (not key.disabled or not state_label.text.contains("LOCKED")):
		_fail("disabled state failed")
		return
	if state == "armed" and (not key.button_pressed or not state_label.text.contains("ARMED")):
		_fail("armed state failed")
		return
	if state == "standby" and (key.button_pressed or not state_label.text.contains("STANDBY")):
		_fail("standby state failed")
		return
	if float(heading.get_theme_font_size("font_size")) * px < 21.0:
		_fail("player-facing title too small")
		return
	if float(heading.get_combined_minimum_size().x) > heading.size.x + 3.0:
		_fail("title would clip in current viewport")
		return
	var screen: Image = get_root().get_texture().get_image()
	var expected: Color = Color("#ECE7DA") if phase == "day" else (Color("#354147") if phase == "dusk" else Color("#10151B"))
	var actual: Color = screen.get_pixel(3, 3)
	if absf(expected.r - actual.r) > 0.12 or absf(expected.g - actual.g) > 0.12 or absf(expected.b - actual.b) > 0.12:
		_fail("wrong day/night backdrop")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var result: Error = screen.save_png(ProjectSettings.globalize_path(output))
	if result != OK or screen.get_width() < width or screen.get_height() < height:
		_fail("failed screenshot export")
		return
	print("TRANSPORT REAL GODOT CAPTURE PASSED: " + output)
	view.queue_free()
	quit(0)

func _fail(reason: String) -> void:
	push_error("TRANSPORT CAPTURE FAILURE: " + reason)
	quit(1)
