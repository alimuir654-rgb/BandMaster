extends SceneTree
## Native Godot input tests of original Lab08.4 two-dial sprite family.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    get_root().size = Vector2i(1280, 720)
    var packed: PackedScene = load("res://poc/premium_rotary_quality_lab.tscn")
    if packed == null:
        _fail("scene missing")
        return
    var view: Control = packed.instantiate()
    get_root().add_child(view)
    for frame in range(5):
        await process_frame
    var focus: Control = view.find_child("PremiumFocusKnob", true, false)
    var buzz: Control = view.find_child("PremiumBuzzKnob", true, false)
    if focus == null or buzz == null:
        _fail("original photo knobs missing")
        return
    if focus.led_layers.size() != 27 or buzz.led_layers.size() != 23:
        _fail("original 27/23 photo LED layers missing")
        return
    view.set_values(0.0, 0.0)
    if focus.active_led_count() != 0 or buzz.active_led_count() != 0:
        _fail("OFF state emits a ring")
        return
    for pct in [0, 25, 50, 75, 100]:
        view.set_values(float(pct), float(pct))
        if focus.active_led_count() != int(round(float(pct) * 27.0 / 100.0)):
            _fail("Focus LED count wrong at %d" % pct)
            return
        if buzz.active_led_count() != int(round(float(pct) * 23.0 / 100.0)):
            _fail("Buzz LED count wrong at %d" % pct)
            return
        if absf(focus.pointer_degrees() - (-135.0 + 2.7 * pct)) > 0.02:
            _fail("pointer angle inaccurate")
            return
    focus.set_value_safe(-900.0)
    buzz.set_value_safe(900.0)
    if focus.value != 0.0 or buzz.value != 100.0:
        _fail("clamp failure")
        return
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_END
    focus._gui_input(key)
    if focus.value != 100.0:
        _fail("END key failure")
        return
    key.keycode = KEY_HOME
    focus._gui_input(key)
    if focus.value != 0.0 or focus.active_led_count() != 0:
        _fail("HOME not fully off")
        return
    key.keycode = KEY_UP
    focus._gui_input(key)
    if focus.value != 1.0:
        _fail("arrow input failure")
        return
    key.keycode = KEY_PAGEUP
    focus._gui_input(key)
    if focus.value != 11.0:
        _fail("page increment failure")
        return
    key.keycode = KEY_SPACE
    focus._gui_input(key)
    if not focus.latched:
        _fail("selected/latched state failure")
        return
    key.keycode = KEY_SPACE
    focus._gui_input(key)
    if focus.latched:
        _fail("latch release failure")
        return
    focus.set_value_safe(50.0)
    var down := InputEventMouseButton.new()
    down.button_index = MOUSE_BUTTON_LEFT
    down.pressed = true
    down.position = Vector2(80.0, 120.0)
    focus._gui_input(down)
    var drag := InputEventMouseMotion.new()
    drag.position = Vector2(80.0, 70.0)
    focus._gui_input(drag)
    if focus.value <= 50.0:
        _fail("drag up did not raise level")
        return
    down.pressed = false
    focus._gui_input(down)
    view.set_review_state("disabled")
    var previous: float = buzz.value
    key.keycode = KEY_HOME
    buzz._gui_input(key)
    if buzz.value != previous or buzz.active_led_count() != 0 or buzz.focus_mode != Control.FOCUS_NONE:
        _fail("disabled knob accepts input or leaks LEDs")
        return
    view.set_review_state("normal")
    if buzz.focus_mode != Control.FOCUS_ALL:
        _fail("focus not restored")
        return
    view.set_phase("night")
    if view.background.color != Color("#0B1116"):
        _fail("night theme failure")
        return
    view.set_phase("day")
    if view.background.color != Color("#ECE7DA"):
        _fail("day not substantially lighter")
        return
    print("PREMIUM ROTARY GODOT INPUT TESTS PASSED")
    view.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("PREMIUM ROTARY TEST FAILURE: " + message)
    quit(1)
