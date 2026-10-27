extends SceneTree
## Sprint 01 fader logic tests: NOT an artwork fidelity test.
const Fader = preload("res://Scripts/premium_hardware/fader_state.gd")
var failures := 0
var signals := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var f = Fader.new()
	f.value_changed.connect(func(_v: float) -> void: signals += 1)
	_check(f.value == 0.0 and f.illuminated_ratio() == 0.0, "off means no illuminated level")
	_check(f.visual_state() == "normal", "normal state")
	f.set_hovered(true)
	_check(f.visual_state() == "hover", "hover state")
	f.set_focused(true)
	_check(f.visual_state() == "focused", "focus outranks hover")
	f.set_selected(true)
	_check(f.visual_state() == "selected", "selected outranks focus")
	_check(f.begin_drag(), "drag begins when enabled")
	_check(f.visual_state() == "pressed", "pressed state")
	f.drag_to_pointer(100.0, 100.0, 300.0)
	_check(is_equal_approx(f.value, 1.0), "track top is 100 percent")
	f.drag_to_pointer(200.0, 100.0, 300.0)
	_check(is_equal_approx(f.value, 0.5), "middle is exactly half")
	f.drag_to_pointer(300.0, 100.0, 300.0)
	_check(is_zero_approx(f.value) and is_zero_approx(f.illuminated_ratio()), "track bottom and off are zero")
	f.drag_to_pointer(999.0, 100.0, 300.0)
	_check(is_zero_approx(f.value), "pointer clamps below track")
	f.drag_to_pointer(-999.0, 100.0, 300.0)
	_check(is_equal_approx(f.value, 1.0), "pointer clamps above track")
	f.drag_to_pointer(200.0, 300.0, 100.0)
	_check(is_equal_approx(f.value, 1.0), "invalid geometry ignored")
	f.end_drag()
	_check(not f.pressed, "drag ends")
	f.set_selected(false)
	f.keyboard_step(-1, true)
	_check(is_equal_approx(f.value, 0.9), "large keyboard decrement")
	f.keyboard_step(1)
	_check(is_equal_approx(f.value, 0.92), "small keyboard increment")
	_check(is_equal_approx(f.cap_ratio_from_value(), 0.08), "cap position follows value")
	var before: float = f.value
	f.set_enabled(false)
	_check(f.visual_state() == "disabled", "disabled overrides all")
	_check(not f.begin_drag(), "disabled blocks drag")
	f.keyboard_step(1)
	f.set_value(0.0)
	_check(is_equal_approx(f.value, before) and f.illuminated_ratio() == 0.0, "disabled prevents changes and extinguishes LED")
	f.set_enabled(true)
	f.set_value(0.0)
	_check(is_zero_approx(f.illuminated_ratio()), "enabled zero still fully unlit")
	_check(signals >= 5, "value_changed emitted on actual changes")
	if failures == 0:
		print("PREMIUM FADER INPUT TESTS PASSED (ART SOURCE GATE SEPARATE)")
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PREMIUM FADER INPUT FAILURE: " + message)
