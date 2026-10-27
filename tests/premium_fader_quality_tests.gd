extends SceneTree
## Native Godot input tests; no data writes, real original PNG preloads.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	var packed: PackedScene = load("res://poc/premium_fader_quality_lab.tscn")
	if packed == null:
		_fail("review scene could not load")
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	for frame in range(5):
		await process_frame
	var h: Control = view.find_child("PremiumHorizontalFader", true, false)
	var v: Control = view.find_child("PremiumVerticalFader", true, false)
	if h == null or v == null:
		_fail("fader widgets missing")
		return
	if h.orientation != "horizontal" or v.orientation != "vertical":
		_fail("wrong photo fader orientation")
		return
	view.set_levels(0.0, 0.0)
	if h.value != 0.0 or v.value != 0.0:
		_fail("OFF value not respected")
		return
	view.set_levels(50.0, 100.0)
	if h.value != 50.0 or v.value != 100.0:
		_fail("independent values failed")
		return
	h.set_value_safe(-100.0)
	v.set_value_safe(900.0)
	if h.value != 0.0 or v.value != 100.0:
		_fail("out of range not clamped")
		return
	var k := InputEventKey.new()
	k.pressed = true
	k.keycode = KEY_END
	h._gui_input(k)
	if h.value != 100.0:
		_fail("END key failed")
		return
	k.keycode = KEY_HOME
	h._gui_input(k)
	if h.value != 0.0:
		_fail("HOME not OFF")
		return
	k.keycode = KEY_RIGHT
	h._gui_input(k)
	if h.value != 1.0:
		_fail("keyboard step failed")
		return
	h.set_disabled(true)
	k.keycode = KEY_END
	h._gui_input(k)
	if h.value != 1.0 or h.focus_mode != Control.FOCUS_NONE:
		_fail("disabled input is not locked")
		return
	h.set_disabled(false)
	if h.focus_mode != Control.FOCUS_ALL:
		_fail("focus not restored")
		return
	view.set_phase("night")
	if view.background.color != Color("#0B1116"):
		_fail("night environment failed")
		return
	view.set_phase("day")
	if view.background.color != Color("#ECE7DA"):
		_fail("day environment failed")
		return
	if not view.readout_h.text.contains("001%"):
		_fail("value-readout mismatch")
		return
	print("PREMIUM FADER ENGINE TESTS PASSED")
	view.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("PREMIUM FADER TEST FAILURE: " + message)
	quit(1)
