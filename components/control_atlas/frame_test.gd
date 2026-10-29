extends "res://components/control_atlas/native_test.gd"
func send_key(window: Window, code: int, shift := false) -> void:
    for down in [true, false]:
        var event := InputEventKey.new()
        event.window_id = window.get_window_id()
        event.keycode = code
        event.shift_pressed = shift
        event.pressed = down
        window.push_input(event, true)
        await process_frame
    await settle()
func inspect_frame_nodes(node: Node) -> void:
    if node is PanelContainer and node.has_meta("frame_profile"):
        var profile: Dictionary = node.get_meta("frame_profile")
        var style: StyleBoxTexture = node.get_theme_stylebox("panel")
        check(style.texture != null and style.texture.get_width() == profile["size"][0], "Frame source identity")
        check(node.focus_mode == Control.FOCUS_NONE, "Decorative frame not focusable")
        for i in range(4):
            check(style.get_texture_margin(i) == profile.nine_slice[i], "Frame slice matches source manifest")
            check(style.get_content_margin(i) >= 12, "Protected frame content inset")
        for child in node.get_children():
            if child is Control:
                check(node.get_global_rect().grow(1).encloses(child.get_global_rect()), "Frame content not clipped")
    for child in node.get_children():
        inspect_frame_nodes(child)
func exercise_frames(scene: Control, window: Window, look: String, sz: Vector2i) -> void:
    var styles = load("res://components/control_atlas/frame_styles.gd")
    var fallback: PanelContainer = styles.make("unsupported", "unknown")
    check(fallback.get_meta("frame_look") == "flightcase" and fallback.get_meta("frame_preset") == "panel", "Safe frame defaults")
    fallback.free()
    var textures: Array[String] = []
    for preset in ["panel", "inset", "portrait", "ticket", "header", "modal"]:
        var first: PanelContainer = styles.make(look, preset)
        var second: PanelContainer = styles.make(look, preset)
        var a: StyleBoxTexture = first.get_theme_stylebox("panel")
        var b: StyleBoxTexture = second.get_theme_stylebox("panel")
        check(a != b, "No shared mutable frame style")
        check(not textures.has(a.texture.resource_path), "Distinct frame-family source")
        textures.append(a.texture.resource_path)
        a.content_margin_left = 101
        check(b.content_margin_left != 101, "Style mutation isolated to its frame")
        var label := Label.new()
        label.text = "Existing content survives theme changes"
        first.add_child(label)
        styles.apply(first, "notepaper" if look == "flightcase" else "flightcase", preset)
        check(first.get_child(0) == label, "Retheme preserves content instance")
        first.free()
        second.free()
    inspect_frame_nodes(scene)
    var opener: Button = scene.live.dialog_open
    scene.scroll.ensure_control_visible(opener)
    await settle()
    opener.grab_focus()
    await click(window, opener)
    var dialog = scene.get_child(scene.get_child_count() - 1)
    check(dialog.has_method("open_modal") and dialog.is_open, "Mouse opens real dialog")
    await settle()
    check(dialog.cancel_button.has_focus(), "Safe cancel receives initial dialog focus")
    check(Rect2(Vector2.ZERO,Vector2(sz)).encloses(dialog.panel.get_global_rect()), "Dialog inside viewport")
    await send_key(window, KEY_TAB)
    check(dialog.confirm_button.has_focus(), "Tab remains inside dialog")
    await send_key(window, KEY_TAB, true)
    check(dialog.cancel_button.has_focus(), "Shift Tab remains inside dialog")
    var count := [0]
    dialog.completed.connect(func(_yes: bool): count[0] += 1)
    await screenshot(window, "%s-frames-%dx%d-dialog" % [look,sz.x,sz.y])
    await send_key(window, KEY_ESCAPE)
    check(count[0] == 1, "Escape cancels exactly once")
    check(opener.has_focus(), "Dialog restores invoking focus")
    await send_key(window, KEY_ESCAPE)
    check(count[0] == 1, "No duplicate dialog completion")
    await click(window, opener)
    dialog = scene.get_child(scene.get_child_count() - 1)
    var result := [false]
    dialog.completed.connect(func(yes: bool): result[0] = yes)
    await click(window, dialog.confirm_button)
    check(result[0], "Mouse confirms real dialog")
    check(opener.has_focus(), "Confirm restores invoking focus")
    scene.scroll.scroll_vertical = 0
    await settle()
func run() -> void:
    DirAccess.make_dir_recursive_absolute("res://components/control_atlas/proof")
    root.gui_embed_subwindows = false
    root.position = Vector2i.ZERO
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    root.content_scale_size = Vector2i.ZERO
    for look in ["flightcase", "notepaper"]:
        for sz in [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720),Vector2i(1600,900)]:
            root.size = sz
            root.show()
            var scene = Gallery.instantiate()
            root.add_child(scene)
            await settle()
            scene.display(look, "frames")
            await settle()
            await exercise_frames(scene, root, look, sz)
            await screenshot(root, "%s-frames-%dx%d-c21" % [look,sz.x,sz.y])
            root.size = Vector2i(1280,720) if sz.x < 900 else Vector2i(390,844)
            await settle()
            inspect_frame_nodes(scene)
            scene.queue_free()
            await process_frame
    var output := FileAccess.open("res://components/control_atlas/proof/frame-results.json", FileAccess.WRITE)
    output.store_string(JSON.stringify({"engine":Engine.get_version_info(),"renderer":DisplayServer.get_name(),"assertions":assertions,"failures":failures,"screenshots":records},"  "))
    print("C21_FRAME_RESULT: ",records.size()," captures; ",assertions," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() and records.size() == 16 else 1)
