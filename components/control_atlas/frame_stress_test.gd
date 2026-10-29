extends "res://components/control_atlas/frame_test.gd"
## Additional stress cases; the original C20 and C21 tests remain unmodified.
func stress_dialog(scene: Control, window: Window, look: String, sz: Vector2i) -> void:
    var original_children := scene.get_child_count()
    var opener: Button = scene.live.dialog_open
    opener.grab_focus()
    var popup = Kit.dialog("A longer decision title must wrap without pushing the actions off screen", "This is deliberately long accessible review text. The action buttons must stay visible while this body scrolls. ".repeat(40), look)
    scene.add_child(popup)
    popup.open_modal()
    await settle()
    await settle()
    check(Rect2(Vector2.ZERO,Vector2(sz)).encloses(popup.panel.get_global_rect()), "Long-copy dialog bounded")
    check(popup.message_scroll.get_v_scroll_bar().max_value > popup.message_scroll.size.y, "Long copy is scrollable")
    await send_key(window, KEY_PAGEDOWN)
    check(popup.message_scroll.scroll_vertical > 0, "Keyboard PageDown scrolls long copy")
    check(popup.cancel_button.has_focus(), "Body scrolling keeps safe action focus")
    window.size = Vector2i(1280,720) if sz.x < 900 else Vector2i(390,844)
    await settle()
    await settle()
    check(Rect2(Vector2.ZERO,Vector2(window.size)).encloses(popup.panel.get_global_rect()), "Open dialog live resize stays bounded")
    window.size = sz
    await settle()
    await settle()
    await screenshot(window, "%s-frames-%dx%d-long-dialog" % [look,sz.x,sz.y])
    opener.disabled = true
    await send_key(window, KEY_ESCAPE)
    check(not opener.has_focus(), "Disabled invoker is not refocused")
    opener.disabled = false
    popup.queue_free()
    await settle()
    var transient: Button = Kit.button("Temporary focus target", look)
    scene.add_child(transient)
    transient.grab_focus()
    popup = Kit.dialog("Safe lifecycle", "The focus target is removed while this dialog is open.", look)
    scene.add_child(popup)
    popup.open_modal()
    transient.queue_free()
    await settle()
    var done := [0]
    popup.completed.connect(func(_yes: bool): done[0] += 1)
    await send_key(window, KEY_ESCAPE)
    check(done[0] == 1 and not popup.is_open, "Deleted-invoker close is safe")
    for i in range(3):
        opener.grab_focus()
        popup.open_modal()
        popup.open_modal()
        await send_key(window, KEY_ESCAPE)
        check(done[0] == i + 2, "Reopen completes once")
        check(opener.has_focus(), "Reopen restores correct invoker")
    popup.queue_free()
    await settle()
    check(scene.get_child_count() == original_children, "Dialog lifecycle leaves no orphan nodes")
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
            await stress_dialog(scene, root, look, sz)
            scene.queue_free()
            await process_frame
    var output := FileAccess.open("res://components/control_atlas/proof/stress-results.json", FileAccess.WRITE)
    output.store_string(JSON.stringify({"engine":Engine.get_version_info(),"renderer":DisplayServer.get_name(),"assertions":assertions,"failures":failures,"screenshots":records},"  "))
    print("C21_STRESS_RESULT: ",records.size()," captures; ",assertions," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() and records.size() == 8 else 1)
