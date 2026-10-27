extends SceneTree
## Actual Godot viewport capture; never a Photoshop/static composite.
func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var phase := "day"
    var value := 50
    var width := 390
    var height := 844
    var mode := "normal"
    var output := "screenshots/rotary-day-50-390x844.png"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--phase="):
            phase = arg.trim_prefix("--phase=")
        elif arg.begins_with("--value="):
            value = int(arg.trim_prefix("--value="))
        elif arg.begins_with("--width="):
            width = int(arg.trim_prefix("--width="))
        elif arg.begins_with("--height="):
            height = int(arg.trim_prefix("--height="))
        elif arg.begins_with("--mode="):
            mode = arg.trim_prefix("--mode=")
        elif arg.begins_with("--output="):
            output = arg.trim_prefix("--output=")
    if not ["day", "dusk", "night"].has(phase) or not [0, 25, 50, 75, 100].has(value) or not ["normal", "disabled", "latched"].has(mode) or width < 320 or height < 600:
        _fail("invalid capture args")
        return
    get_root().size = Vector2i(width, height)
    DisplayServer.window_set_size(Vector2i(width, height))
    var packed: PackedScene = load("res://poc/premium_rotary_quality_lab.tscn")
    if packed == null:
        _fail("scene not found")
        return
    var view: Control = packed.instantiate()
    get_root().add_child(view)
    view.set_phase(phase)
    view.set_values(float(value), float(value))
    view.set_review_state(mode)
    for frame in range(18):
        await process_frame
    var focus: Control = view.find_child("PremiumFocusKnob", true, false)
    var buzz: Control = view.find_child("PremiumBuzzKnob", true, false)
    if focus == null or buzz == null or int(focus.value) != value or int(buzz.value) != value:
        _fail("control value mismatch")
        return
    var expected_focus: int = int(round(float(value) * 27.0 / 100.0))
    var expected_buzz: int = 0 if mode == "disabled" else int(round(float(value) * 23.0 / 100.0))
    if focus.active_led_count() != expected_focus or buzz.active_led_count() != expected_buzz:
        _fail("source-backed ring count mismatch")
        return
    if mode == "latched" and not focus.latched:
        _fail("latched state missing")
        return
    var px_scale: float = float(DisplayServer.window_get_size().x) / maxf(view.get_viewport_rect().size.x, 1.0)
    for dial in [focus, buzz]:
        var bounds: Rect2 = dial.get_global_rect()
        if bounds.position.x < -1.0 or bounds.position.y < -1.0 or bounds.end.x > view.get_viewport_rect().size.x + 1.0 or bounds.end.y > view.get_viewport_rect().size.y + 1.0:
            _fail("photo dial clipped")
            return
        if bounds.size.x * px_scale < 110.0 or bounds.size.y * px_scale < 110.0:
            _fail("original photo dial too small")
            return
    var phase_button: Button = view.find_child("RotaryPhaseDusk", true, false)
    if phase_button == null or phase_button.get_global_rect().size.y * px_scale < 44.0:
        _fail("phase keyboard/touch target too small")
        return
    var title: Label = view.find_child("RotaryTitle", true, false)
    if title == null or title.get_theme_font_size("font_size") * px_scale < 22.0:
        _fail("heading below 22px physical")
        return
    var image := get_root().get_texture().get_image()
    var expected: Color = Color("#ECE7DA") if phase == "day" else (Color("#283941") if phase == "dusk" else Color("#0B1116"))
    var actual: Color = image.get_pixel(3, 3)
    if absf(actual.r - expected.r) > 0.12 or absf(actual.g - expected.g) > 0.12 or absf(actual.b - expected.b) > 0.12:
        _fail("time-of-day background wrong")
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
    var result := image.save_png(ProjectSettings.globalize_path(output))
    if result != OK or image.get_width() < width or image.get_height() < height:
        _fail("screenshot failed")
        return
    print("PREMIUM ROTARY CAPTURE PASSED: " + output)
    view.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("PREMIUM ROTARY CAPTURE FAILURE: " + message)
    quit(1)
