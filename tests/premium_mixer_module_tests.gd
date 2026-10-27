extends SceneTree
## Enforce control semantics: inputs editable; displayed game stat is strictly read-only.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	get_root().size = Vector2i(1280, 720)
	var resource: PackedScene = load("res://poc/premium_mixer_module_lab.tscn")
	if resource == null:
		_fail("scene unavailable")
		return
	var view: Control = resource.instantiate()
	get_root().add_child(view)
	for i in range(5):
		await process_frame
	var fader: Control = view.find_child("RigHorizontalInput", true, false)
	var energy: Control = view.find_child("RigVerticalInput", true, false)
	var meter: Control = view.find_child("RigReadOnlyHypeMeter", true, false)
	var rack: Panel = view.find_child("PhotographicHardwareRack", true, false)
	if fader == null or energy == null or meter == null or rack == null:
		_fail("input, monitor or hardware rack missing")
		return
	if fader.focus_mode != Control.FOCUS_ALL or energy.focus_mode != Control.FOCUS_ALL:
		_fail("editable faders not keyboard accessible")
		return
	if meter.focus_mode != Control.FOCUS_NONE or meter.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("meter must not intercept input or keyboard focus")
		return
	if not meter.has_method("set_reading") or meter.has_signal("value_changed"):
		_fail("meter must use model reading API without a user-change signal")
		return
	view.set_levels(25.0, 75.0)
	if not is_equal_approx(fader.value, 25.0) or not is_equal_approx(energy.value, 75.0):
		_fail("input values not set")
		return
	if not is_equal_approx(meter.reading, 68.0):
		_fail("read-only stat changed with user input")
		return
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_HOME
	fader._gui_input(key)
	if fader.value != 0.0 or meter.reading != 68.0:
		_fail("input key or stat independence broken")
		return
	view.set_stat_reading(100.0)
	if meter.reading != 100.0 or energy.value != 75.0:
		_fail("telemetry updated a player input")
		return
	view.set_stat_reading(-2.0)
	if meter.reading != 0.0:
		_fail("meter input clamping broken")
		return
	view.set_stat_reading(68.0)
	if meter.reading != 68.0:
		_fail("meter cannot restore independent model state")
		return
	for name in ["day", "dusk", "night"]:
		view.set_phase(name)
		if view.phase != name:
			_fail("phase state failed")
			return
		var box: StyleBox = rack.get_theme_stylebox("panel")
		if not (box is StyleBoxFlat):
			_fail("missing physical rack housing")
			return
	if view.background.color != Color("#0B1116"):
		_fail("night colour absent")
		return
	view.set_phase("day")
	if view.background.color != Color("#ECE7DA"):
		_fail("day is not light")
		return
	print("PREMIUM MIXER INPUT/METER CONTRACT PASSED")
	view.queue_free()
	quit(0)

func _fail(reason: String) -> void:
	push_error("PREMIUM MIXER FAILURE: " + reason)
	quit(1)
