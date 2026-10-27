extends SceneTree
## Actual Godot native studio screenshot, original photo hardware and first-fold gate.
const Scene = preload("res://poc/ldtd_studio_recording.tscn")
func _initialize() -> void:
	call_deferred("_capture")
func _fail(reason: String) -> void:
	push_error("S06 SCREENSHOT FAILURE: "+reason)
	quit(1)
func _capture() -> void:
	var width: int = 390
	var height: int = 844
	var moment: String = "day"
	var output: String = "screenshots/s06-studio-day-390x844.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--moment="):
			moment = arg.trim_prefix("--moment=")
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if not ["day","dusk","night"].has(moment):
		_fail("unknown moment")
		return
	get_root().size = Vector2i(width,height)
	DisplayServer.window_set_size(Vector2i(width,height))
	var view: Control = Scene.instantiate()
	get_root().add_child(view)
	for i in range(8):
		await process_frame
	if moment!="day":
		view.arm_transport(true)
		for i in range(5):
			await process_frame
		view.record_demo()
		for i in range(6):
			await process_frame
	if moment=="night":
		view.release_demo()
		for i in range(6):
			await process_frame
	for i in range(12):
		await process_frame
	if view.phase!=moment:
		_fail("wrong studio phase")
		return
	var photo: TextureRect = view.find_child("SourceBackedStudioPhasePhoto",true,false)
	var chassis: TextureRect = view.find_child("AuthoredStudioMetalChassis",true,false)
	var transport: TextureButton = view.find_child("PhotographicStudioTransport",true,false)
	var guitar: Control = view.find_child("PhotographicGuitarFader",true,false)
	var vocal: Control = view.find_child("PhotographicVocalFader",true,false)
	var rotary: Control = view.find_child("Lab084StudioFocusRotary",true,false)
	var meter: Control = view.find_child("ReadOnlyPhotographicReadinessMeter",true,false)
	var stats: Label = view.find_child("ReadOnlyStudioOutcome",true,false)
	var primary: TextureButton = view.find_child("StudioPrimaryAction",true,false)
	var dock: Panel = view.find_child("StudioActionDock",true,false)
	var scroll: ScrollContainer = view.find_child("StudioScroll",true,false)
	if photo==null or photo.texture==null or chassis==null or chassis.texture==null or transport==null or guitar==null or vocal==null or rotary==null or meter==null or stats==null or primary==null or dock==null or scroll==null:
		_fail("missing source-backed photographic studio component or native label")
		return
	var px: float = float(DisplayServer.window_get_size().x)/maxf(view.get_viewport_rect().size.x,1.0)
	if primary.get_global_rect().size.y*px<44.0 or primary.get_global_rect().end.y*px>float(height)+3.0:
		_fail("studio primary smaller than 44px or outside first fold")
		return
	if scroll.get_global_rect().end.y*px>dock.get_global_rect().position.y*px+3.0:
		_fail("studio scroll collides with dock")
		return
	for control in [transport,guitar,vocal,rotary]:
		if control.get_global_rect().size.y*px<44.0:
			_fail("studio input below 44 physical pixels: "+control.name)
			return
	if transport.get_global_rect().end.y*px>dock.get_global_rect().position.y*px:
		_fail("arm deck not visible before first-fold action")
		return
	if stats.focus_mode!=Control.FOCUS_NONE or meter.focus_mode!=Control.FOCUS_NONE or meter.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
		_fail("read-only studio outcomes are interactive")
		return
	if transport.texture_normal==null or transport.texture_hover==null or transport.texture_pressed==null or transport.texture_disabled==null:
		_fail("original Lab07 five-state transport missing")
		return
	if primary.texture_normal==null or primary.texture_hover==null or primary.texture_pressed==null or primary.texture_disabled==null:
		_fail("original studio photo hardware states missing")
		return
	for i in range(3):
		var moment_label: Label = view.find_child("StudioMoment"+str(i),true,false)
		if moment_label==null or moment_label.text.is_empty() or not moment_label.is_visible_in_tree():
			_fail("native DAY DUSK NIGHT studio phase missing")
			return
	if moment=="night" and (view.record_count!=1 or view.release_count!=1 or not primary.disabled):
		_fail("studio release not terminal once-only")
		return
	var image: Image = get_root().get_texture().get_image()
	if image.get_width()<width or image.get_height()<height:
		_fail("renderer dimensions below device")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	if image.save_png(ProjectSettings.globalize_path(output))!=OK:
		_fail("cannot save native Godot PNG")
		return
	print("LDTD S06 ACTUAL GODOT SCREENSHOT PASSED: "+output)
	view.queue_free()
	quit(0)
