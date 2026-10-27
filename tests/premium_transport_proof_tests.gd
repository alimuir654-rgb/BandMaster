extends SceneTree
## Real Godot isolated transport proof: original state sprites and input semantics.
func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	get_root().size = Vector2i(1280, 720)
	var scene: PackedScene = load("res://poc/premium_transport_proof.tscn")
	if scene == null:
		_fail("scene missing")
		return
	var view: Control = scene.instantiate()
	get_root().add_child(view)
	for i in range(6):
		await process_frame
	var key: TextureButton = view.find_child("PhotographicTransportKey", true, false)
	var rig: Panel = view.find_child("TransportPhotoRack", true, false)
	var state: Label = view.find_child("TransportStateReadout", true, false)
	if key == null or rig == null or state == null:
		_fail("transport or enclosure missing")
		return
	if key.focus_mode != Control.FOCUS_ALL or not key.toggle_mode or key.texture_normal == null or key.texture_hover == null or key.texture_pressed == null or key.texture_disabled == null:
		_fail("missing playable control states or keyboard focus")
		return
	if key.texture_normal.get_width() != 790 or key.texture_normal.get_height() != 430:
		_fail("original Lab07 source photography is not in use")
		return
	if not state.text.contains("STANDBY") or key.button_pressed:
		_fail("initial transport state wrong")
		return
	var events: Array[bool] = []
	key.transport_armed.connect(func(armed: bool) -> void: events.append(armed))
	view.set_transport_armed(true)
	if not key.button_pressed or not state.text.contains("ARMED") or events.size() != 0:
		_fail("model driven preview must not fake a user event")
		return
	key.toggled.emit(false)
	if events.size() != 1 or events[0] or state.text.contains("LOCKED"):
		_fail("one-shot user toggle signal invalid")
		return
	view.set_transport_armed(false)
	view.set_locked(true)
	if not key.disabled or key.button_pressed or key.focus_mode != Control.FOCUS_NONE or not state.text.contains("LOCKED"):
		_fail("locked is not represented")
		return
	var count_before: int = events.size()
	key._on_toggled(true)
	if events.size() != count_before or key.button_pressed:
		_fail("disabled key sent an interaction")
		return
	view.set_transport_armed(true)
	if key.button_pressed:
		_fail("locked key allowed model arming")
		return
	view.set_locked(false)
	for finish in ["studio", "electronic", "punk"]:
		view.set_finish(finish)
		if key.finish != finish or key.texture_disabled == null or key.texture_pressed == null:
			_fail("palette-state source missing: " + finish)
			return
		if key.texture_normal.get_width() != 790:
			_fail("incorrect source aspect in " + finish)
			return
	for scene_phase in ["day", "dusk", "night"]:
		view.set_phase(scene_phase)
		if view.phase != scene_phase:
			_fail("phase navigation failed: " + scene_phase)
			return
	if view.background.color != Color("#10151B"):
		_fail("night backdrop not atmospheric")
		return
	view.set_phase("day")
	if view.background.color != Color("#ECE7DA"):
		_fail("DAY must be visibly light")
		return
	print("TRANSPORT PHOTO FAMILY TESTS PASSED")
	view.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("TRANSPORT PROOF FAILURE: " + message)
	quit(1)
