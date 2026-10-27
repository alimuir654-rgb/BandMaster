extends SceneTree
const Worlds = preload("res://Scripts/scene_world_theme.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists("res://Art/UI/Songwriting/writing_desk_surface.svg"), "original paper texture exists")
	var packed: PackedScene = load("res://poc/songwriting_controls_lab.tscn")
	_check(packed != null, "songwriting lab loads")
	if packed == null:
		quit(1)
		return
	var lab: Control = packed.instantiate()
	get_root().add_child(lab)
	for i in range(4):
		await process_frame
	_check(lab.phase == "day", "daylight default")
	_check(lab.sequence.size() == 4, "initial arrangement four parts")
	_check(lab.active_kind == "CHORUS", "initial section selection")
	lab.choose_section("BRIDGE")
	lab.append_section()
	_check(lab.sequence.size() == 5 and lab.sequence[4] == "BRIDGE", "section stamp adds correct part")
	lab.remove_section()
	_check(lab.sequence.size() == 4, "remove section works")
	lab.choose_groove("SWELL")
	lab.set_tempo(138)
	lab.set_idea("Late train, last chance")
	lab.set_phase("dusk")
	for i in range(3):
		await process_frame
	_check(lab.phase == "dusk" and lab.groove == "SWELL" and lab.tempo == 138, "dusk preserves sampler")
	var idea: LineEdit = lab.find_child("IdeaLine", true, false)
	_check(idea != null and idea.text == "Late train, last chance", "dusk preserves editable lyrics")
	var tempo_label: Label = lab.find_child("TempoReadout", true, false)
	_check(tempo_label != null and tempo_label.text == "138 BPM", "readout follows tempo")
	var bridge: Button = lab.find_child("KindBridge", true, false)
	_check(bridge != null and bridge.focus_mode == Control.FOCUS_ALL, "section pad keyboard focusable")
	var primary: Button = lab.find_child("WritingPrimary", true, false)
	_check(primary != null and primary.custom_minimum_size.y > 0, "fixed preview action exists")
	lab.preview_draft()
	var status: Label = lab.find_child("WritingStatus", true, false)
	_check(status != null and status.text.contains("NO SAVE WRITES"), "preview does not imply song commit")
	_check(lab.preview_count == 1, "preview counter increments once")
	lab.set_phase("night")
	_check(lab.phase == "dusk", "night mode not incorrectly offered in daytime writing lab")
	lab.choose_section("INVALID")
	_check(lab.active_kind == "BRIDGE", "invalid section rejected")
	lab.set_tempo(500)
	_check(lab.tempo == 165, "tempo clamped")
	lab.set_phase("day")
	_check(lab.phase == "day" and lab.idea_text == "Late train, last chance", "day/dusk state round trip")
	_check(Worlds.relative_luminance(Worlds.palette("songwriting", "day")["bg"]) > Worlds.relative_luminance(Worlds.palette("songwriting", "dusk")["bg"]) * 7.0, "day is substantially lighter than dusk")
	lab.queue_free()
	if failures == 0:
		print("SONGWRITING CONTROL LAB TESTS PASSED")
	quit(0 if failures == 0 else 1)

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error("SONGWRITING CONTROL FAILURE: " + detail)
