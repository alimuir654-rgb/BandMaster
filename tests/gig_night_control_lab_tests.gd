extends SceneTree
## Sprint 06: pure local state and interactive live-rig controls.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists("res://Art/Backgrounds/shared/backstage.webp"), "existing backstage photo bytes import")
	_check(ResourceLoader.exists("res://Art/Backgrounds/shared/gigs.webp"), "existing gigs photo bytes import")
	_check(ResourceLoader.exists("res://Art/UI/Tour/road_case_surface.svg"), "existing steel plate reference imports")
	var packed: PackedScene = load("res://poc/gig_night_controls_lab.tscn")
	_check(packed != null, "gig-night lab scene imports")
	if packed == null:
		quit(1)
		return
	var lab: Control = packed.instantiate()
	get_root().add_child(lab)
	for i in range(5):
		await process_frame
	_check(lab.phase == "day", "starts in genuinely light daytime load-in")
	_check(lab.songs_played == 0 and lab.preview_count == 0, "no automatic performance or preview")
	_check(not lab.can_go() and not lab.can_encore(), "cannot play during daylight load-in")
	lab.set_phase("night")
	_check(not lab.can_go(), "stage GO gated by safety readiness")
	lab.toggle_equipment()
	_check(not lab.can_go(), "soundcheck still required after gear latch")
	lab.toggle_soundcheck()
	_check(lab.can_go(), "GO becomes available with sound and gear ready")
	lab.toggle_hold()
	_check(lab.held and not lab.can_go(), "HOLD interlocks GO")
	lab.fire_go()
	_check(lab.songs_played == 0, "blocked GO never advances set")
	lab.toggle_hold()
	lab.fire_go()
	_check(lab.songs_played == 1 and lab.selected_song == 1, "GO advances one demo song")
	lab.select_song(0)
	_check(lab.selected_song == 1, "completed songs cannot be replay-selected")
	lab.select_song(2)
	_check(not lab.can_go(), "cannot skip setlist sequence by selecting future song")
	lab.select_song(1)
	lab.fire_go()
	lab.fire_go()
	_check(lab.songs_played == 3, "three GO cues finish the local set")
	_check(not lab.can_go() and lab.can_encore(), "encore only unlocks after set")
	lab.fire_encore()
	lab.fire_encore()
	_check(lab.encore_fired and lab.preview_count == 4, "encore fires once; no repeat cue")
	lab.set_phase("dusk")
	_check(lab.phase == "dusk" and lab.songs_played == 3, "phase change preserves local cue state")
	lab.toggle_equipment()
	_check(not lab.soundcheck_ready and not lab.equipment_ready, "unlatching gear invalidates soundcheck")
	lab.toggle_soundcheck()
	_check(not lab.soundcheck_ready, "cannot mark soundcheck ready without gear")
	lab.set_phase("day")
	_check(not lab.can_go(), "daytime never permits GO even after played set")
	lab.preview_cues()
	var status: Label = lab.find_child("GigStatus", true, false)
	_check(status != null and status.text.contains("NO SAVE WRITES"), "preview explicitly does not mutate career")
	_check(lab.find_child("GigHardwareRack", true, false) != null, "physical rack rendered")
	_check(lab.find_child("GigPhotographicHero", true, false) != null, "actual repository photography rendered")
	var go: Button = lab.find_child("GigGo", true, false)
	var hold: Button = lab.find_child("GigHold", true, false)
	var encore: Button = lab.find_child("GigEncore", true, false)
	_check(go != null and hold != null and encore != null, "GO HOLD ENCORE controls exist")
	if go != null and hold != null and encore != null:
		_check(go.focus_mode == Control.FOCUS_ALL and hold.focus_mode == Control.FOCUS_ALL and encore.focus_mode == Control.FOCUS_ALL, "all live cues keyboard focusable")
		_check(go.disabled and encore.disabled, "day cues gated even after demo completion")
	lab.reset_demo()
	_check(lab.songs_played == 0 and not lab.encore_fired and lab.preview_count == 0, "reset clears local performance once-only state")
	_check(Worlds.relative_luminance(Worlds.palette("gig", "day")["bg"]) > Worlds.relative_luminance(Worlds.palette("gig", "night")["bg"]) * 15.0, "daylight backdrop substantially brighter than stage night")
	_check(Worlds.relative_luminance(Worlds.palette("gig", "dusk")["bg"]) > Worlds.relative_luminance(Worlds.palette("gig", "night")["bg"]), "dusk visually intermediate")
	_check(Worlds.contrast_ratio(Worlds.palette("gig", "day")["bg"], Worlds.palette("gig", "day")["ink"]) >= 4.5, "daylight text contrast")
	_check(Worlds.contrast_ratio(Worlds.palette("gig", "night")["bg"], Worlds.palette("gig", "night")["ink"]) >= 4.5, "night text contrast")
	lab.queue_free()
	if failures == 0:
		print("GIG NIGHT CONTROL LAB TESTS PASSED")
	quit(0 if failures == 0 else 1)

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error("GIG NIGHT CONTROL FAILURE: " + detail)
