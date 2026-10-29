extends SceneTree
## U04: four-viewport REAL Godot hardware state proof, not a static PIL atlas.
const DIAL = preload("res://bandmaster_premium_dashboard_poc/studio_control.gd")
var failures: Array[String] = []
var captures: Array = []
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, why: String) -> void:
    if not ok:
        failures.append(why)
        push_error(why)
func settle() -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
func label(parent: Control, value: String, pos: Vector2, width: float, font_size: int = 17) -> void:
    var note := Label.new()
    note.text = value
    note.position = pos
    note.custom_minimum_size = Vector2(width, 30)
    note.add_theme_color_override("font_color", Color("#e1d3bd"))
    note.add_theme_font_size_override("font_size", font_size)
    note.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(note)
func hardware(parent: Control, kind: String, pos: Vector2, dims: Vector2) -> Control:
    var node := Control.new()
    node.set_script(DIAL)
    node.set("control_kind", kind)
    node.set("level", 0.0)
    node.set("read_only", false)
    parent.add_child(node)
    node.position = pos
    node.size = dims
    return node
func _run() -> void:
    var proof_dir := DirAccess.open("res://")
    check(proof_dir != null and proof_dir.dir_exists("proof-shots"),"proof-shots missing; CI must create it")
    for sz in [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720),Vector2i(1600,900)]:
        var window := Window.new()
        window.size = sz
        window.position = Vector2i.ZERO
        root.add_child(window)
        window.show()
        var canvas := Control.new()
        canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        window.add_child(canvas)
        var bg := ColorRect.new()
        bg.color = Color("#111a20")
        bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        canvas.add_child(bg)
        label(canvas,"SOURCE LAB08.4  /  LIVE HARDWARE INPUTS",Vector2(24,24),sz.x-48,18 if sz.x < 900 else 27)
        label(canvas,"Value-driven LEDs; 0 = no lit ring or fader rail",Vector2(24,59),sz.x-48,13 if sz.x < 900 else 16)
        var controls: Array[Control] = []
        if sz.x < 900:
            var diameter := minf(250.0,(sz.x-50.0)*0.5)
            var top := 110.0
            controls.append(hardware(canvas,"focus",Vector2(12,top),Vector2(diameter,diameter)))
            controls.append(hardware(canvas,"buzz",Vector2(sz.x-diameter-12,top),Vector2(diameter,diameter)))
            var hy := top+diameter+58.0
            controls.append(hardware(canvas,"horizontal",Vector2(20,hy),Vector2(sz.x-40,105)))
            var vy := hy+145.0
            controls.append(hardware(canvas,"vertical",Vector2((sz.x-130)*0.5,vy),Vector2(130,minf(355,sz.y-vy-35))))
        else:
            controls.append(hardware(canvas,"focus",Vector2(35,145),Vector2(225,225)))
            controls.append(hardware(canvas,"buzz",Vector2(283,145),Vector2(225,225)))
            controls.append(hardware(canvas,"horizontal",Vector2(555,150),Vector2(sz.x-620,152)))
            controls.append(hardware(canvas,"vertical",Vector2(585,340),Vector2(160,minf(340,sz.y-370))))
        await settle()
        check(controls.size()==4,"Wrong controls count")
        check((controls[0].get("ring_layers") as Array).size()==27,"Creative Focus LED count " + str(sz))
        check((controls[1].get("ring_layers") as Array).size()==23,"Venue Buzz LED count " + str(sz))
        for control in controls:
            check(control.focus_mode==Control.FOCUS_ALL,"Input control not keyboard focusable " + str(sz))
            check(control.mouse_filter==Control.MOUSE_FILTER_STOP,"Input control missing pointer " + str(sz))
            check(control.get_global_rect().size.x>=44 and control.get_global_rect().size.y>=44,"Small target " + str(sz))
            check(Rect2(Vector2.ZERO,Vector2(sz)).encloses(control.get_global_rect()),"Control offscreen "+str(sz))
        for value in [0,25,50,75,100]:
            for control in controls:
                control.set_level(float(value))
                check(int(control.get("level"))==value,"Wrong value")
            await settle()
            var fname: String = "u04-%dx%d-value%03d.png" % [sz.x,sz.y,value]
            var shot: Image = window.get_texture().get_image()
            check(shot!=null and shot.get_size()==sz,"Viewport capture mismatch "+fname)
            check(shot.save_png("res://proof-shots/"+fname)==OK,"Capture failed "+fname)
            captures.append(dict(file=fname,width=sz.x,height=sz.y,value=value))
        window.queue_free()
        await process_frame
    var file := FileAccess.open("res://proof-shots/u04-results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({ "captures":captures,"failures":failures,"engine":Engine.get_version_info()}, "  "))
    print("U04_NATIVE_RESULT: ",captures.size()," captures; ",failures.size()," failures")
    quit(0 if failures.is_empty() and captures.size()==20 else 1)
