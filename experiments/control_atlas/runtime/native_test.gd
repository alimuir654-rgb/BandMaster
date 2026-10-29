extends SceneTree
const Kit = preload("res://kit.gd")
const Gallery = preload("res://gallery.tscn")
var failures: Array[String] = []
var records: Array = []
var assertions := 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    assertions += 1
    if not ok:
        failures.append(message)
        push_error(message)
func settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
func screenshot(window: Window, tag: String) -> void:
    await settle()
    var image: Image = window.get_texture().get_image()
    check(image != null and image.get_size() == window.size, "Native render dimensions " + tag)
    if image == null:
        return
    check(image.save_png("res://proof/" + tag + ".png") == OK, "PNG write " + tag)
    records.append({"file":tag + ".png", "size":[image.get_width(),image.get_height()]})
func click(window: Window, button: Button) -> void:
    var centre := button.get_global_rect().get_center()
    window.notify_mouse_entered()
    var motion := InputEventMouseMotion.new()
    motion.position = centre
    motion.global_position = centre
    window.push_input(motion, true)
    await process_frame
    for down in [true, false]:
        var e := InputEventMouseButton.new()
        e.button_index = MOUSE_BUTTON_LEFT
        e.position = centre
        e.global_position = centre
        e.pressed = down
        window.push_input(e, true)
        await process_frame
func exercise(scene: Control, window: Window) -> void:
    var step = scene.live.stepper
    var hits := [0]
    step.value_changed.connect(func(_v: int): hits[0] += 1)
    step.set_value(500)
    check(step.value == 10 and step.plus.disabled, "Stepper upper boundary")
    step.set_value(500)
    check(hits[0] == 1, "No duplicate stepper signal at same value")
    step.set_value(-5)
    check(step.value == 0 and step.minus.disabled, "Stepper lower boundary")
    step.set_value(4)
    step.set_locked(true)
    check(step.plus.disabled and step.minus.disabled, "Stepper disabled")
    step.set_locked(false)
    var choices = scene.live.roles
    choices.select(2)
    choices.select(99)
    check(choices.selected == 2 and choices.buttons[2].button_pressed, "Segment selection and invalid-index guard")
    var selected_count := 0
    for b in choices.buttons:
        if b.button_pressed: selected_count += 1
        check(b.custom_minimum_size.x >= 44 and b.custom_minimum_size.y >= 44, "44px choice target")
    check(selected_count == 1, "ChoiceStrip exclusive selection")
    var browse = scene.live.browse
    browse.move(-1)
    check(browse.selected == 2, "Browse wrapping")
    browse.wrap = false
    browse.move(1)
    check(browse.selected == 2, "Browse upper clamp")
    browse.set_locked(true)
    browse.move(-1)
    check(browse.selected == 2 and browse.next.disabled, "Browse disabled guard")
    browse.set_locked(false)
    var meter = scene.live.meter
    meter.set_score(50)
    check(meter.score == 10 and meter.mouse_filter == Control.MOUSE_FILTER_IGNORE and meter.focus_mode == Control.FOCUS_NONE, "Passive meter has no input/focus")
    meter.set_score(8)
    var toggle: Button = scene.live.toggle
    scene.scroll.ensure_control_visible(toggle)
    await settle()
    await click(window, toggle)
    check(toggle.button_pressed and toggle.text.ends_with("ON"), "Actual mouse click toggles state")
    toggle.grab_focus()
    await settle()
    var e := InputEventKey.new()
    e.keycode = KEY_SPACE
    e.pressed = true
    window.push_input(e, true)
    await process_frame
    e = InputEventKey.new()
    e.keycode = KEY_SPACE
    e.pressed = false
    window.push_input(e, true)
    await settle()
    check(not toggle.button_pressed and toggle.text.ends_with("OFF"), "Actual keyboard activation toggles state")
    check(toggle.has_focus(), "Keyboard focus retained")
    for b in scene.controls:
        check(b.get_global_rect().size.x >= 44 and b.get_global_rect().size.y >= 44, "Physical touch size " + b.text)
        check(b.get_theme_stylebox("normal") is StyleBoxTexture, "Image-backed button skin " + b.text)
    scene.scroll.scroll_vertical = 0
func run() -> void:
    DirAccess.make_dir_recursive_absolute("res://proof")
    root.gui_embed_subwindows = false
    # Every promised drop-in scene must instantiate, not merely parse.
    for kind in ["toggle", "stepper", "choices", "browse", "pagination", "meter", "action", "panel", "ticket"]:
        var wrapper = load("res://scenes/" + kind + ".tscn").instantiate()
        root.add_child(wrapper)
        await process_frame
        check(wrapper.control != null and wrapper.control.get_parent() == wrapper, "Reusable scene instantiates " + kind)
        wrapper.queue_free()
        await process_frame
    for look in ["flightcase", "notepaper"]:
        for sz in [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720),Vector2i(1600,900)]:
            var window := Window.new()
            window.size = sz
            window.position = Vector2i.ZERO
            root.add_child(window)
            window.show()
            var scene = Gallery.instantiate()
            window.add_child(scene)
            await settle()
            for page in ["controls", "hardware", "frames"]:
                scene.display(look, page)
                await settle()
                check(scene.grid.columns == (3 if sz.x>=1200 else (2 if sz.x>=760 else 1)), "Responsive grid")
                if page == "controls":
                    await exercise(scene, window)
                if page == "hardware":
                    for h in scene.hardware_controls:
                        h.set_level(-10)
                        check(h.level == 0, "Existing Lab08 zero clamp")
                        h.set_level(110)
                        check(h.level == 100, "Existing Lab08 maximum clamp")
                        h.set_level(50)
                await screenshot(window,"%s-%s-%dx%d-top" % [look,page,sz.x,sz.y])
                scene.scroll.scroll_vertical = int(scene.grid.size.y)
                await settle()
                await screenshot(window,"%s-%s-%dx%d-bottom" % [look,page,sz.x,sz.y])
                check(scene.scroll.get_global_rect().end.x <= sz.x + 1, "Scroll area within viewport")
            window.size = Vector2i(1280,720) if sz.x<900 else Vector2i(390,844)
            await settle()
            check(scene.grid.columns == (3 if window.size.x>=1200 else 1), "Live responsive resize")
            window.queue_free()
            await process_frame
    var output := FileAccess.open("res://proof/results.json", FileAccess.WRITE)
    output.store_string(JSON.stringify({"engine":Engine.get_version_info(),"renderer":DisplayServer.get_name(),"assertions":assertions,"failures":failures,"screenshots":records},"  "))
    print("C20_RESULT: ",records.size()," captures; ",assertions," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() and records.size()==48 else 1)
