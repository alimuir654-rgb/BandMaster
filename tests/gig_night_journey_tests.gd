extends SceneTree
## Sprint 07: exercise real GigCalendar settlement in an isolated Godot journey.
const Model = preload("res://Scripts/gig_night_journey_model.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Worlds = preload("res://Scripts/scene_world_theme.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original: Dictionary = Model.sample_state()
	_check(not original.is_empty(), "sample booked via real gig calendar")
	_check(int(original.get("tour_day", 0)) == int(original.get("booked_show", {}).get("day", -1)), "sample starts on real booked show day")
	_check(not Model.settle(original, 0, true, true, false, false).get("ok", false), "cannot settle unplayed set")
	_check(not Model.settle(original, 3, false, true, false, false).get("ok", false), "cannot settle unsafe gear")
	_check(not Model.settle(original, 3, true, true, true, false).get("ok", false), "HOLD blocks settlement")
	_check(not Model.choose_approach(original, "invalid").get("ok", false), "invalid approach rejected")
	var chosen: Dictionary = Model.choose_approach(original, "crowd")
	_check(bool(chosen.get("ok", false)), "actual show approach can change before performance")
	var demo: Dictionary = chosen.get("state", {})
	_check(str(demo.get("booked_show", {}).get("approach", "")) == "crowd", "show approach persisted in isolated booking")
	_check(str(original.get("booked_show", {}).get("approach", "")) == "tight", "approach change does not mutate source state")
	var first: Dictionary = Model.settle(demo, 3, true, true, false, false)
	_check(bool(first.get("ok", false)), "real GigCalendar performs completed show")
	if bool(first.get("ok", false)):
		var final_state: Dictionary = first["state"]
		_check(Calendar.pending(final_state).is_empty(), "settlement clears booking")
		_check(final_state.get("gig_history", []).size() == 1, "one real gig history entry")
		_check(not Model.settle(final_state, 3, true, true, false, false).get("ok", false), "replay cannot pay again without booking")
		_check(not Model.settle(demo, 3, true, true, false, true).get("ok", false), "explicit settled guard blocks stale source replay")
		_check(JSON.parse_string(JSON.stringify(final_state)) is Dictionary, "local outcome remains save-compatible JSON")
		_check(original.get("gig_history", []).is_empty(), "original state not mutated by settlement")
	var packed: PackedScene = load("res://poc/gig_night_journey_poc.tscn")
	_check(packed != null, "playable scene imports")
	if packed == null:
		quit(1)
		return
	var view: Control = packed.instantiate()
	get_root().add_child(view)
	for i in range(5):
		await process_frame
	_check(view.journey_step == 0 and view.phase == "day", "starts in daylight load-in")
	_check(not view.can_go(), "no premature stage GO")
	var approach_button: Button = view.find_child("PhaseNight", true, false) as Button
	_check(approach_button != null and approach_button.text == "WIN ROOM", "time tabs are actual show approach controls")
	if approach_button != null:
		approach_button.pressed.emit()
	_check(view.phase == "day" and str(view.demo_state.get("booked_show", {}).get("approach", "")) == "crowd", "choosing show approach does not skip daylight")
	view.advance_journey()
	_check(view.journey_step == 0, "cannot skip gear checks")
	view.toggle_equipment()
	view.advance_journey()
	_check(view.journey_step == 1 and view.phase == "dusk", "day to dusk follows in-game show context")
	view.advance_journey()
	_check(view.journey_step == 1, "soundcheck required before stage")
	view.toggle_soundcheck()
	view.choose_approach("wild")
	view.advance_journey()
	_check(view.journey_step == 2 and view.phase == "night", "dusk to night after soundcheck")
	_check(str(view.demo_state.get("booked_show", {}).get("approach", "")) == "wild", "chosen approach reaches live booking")
	view.set_phase("day")
	_check(view.phase == "night", "free phase switch cannot bypass story progression")
	view.toggle_hold()
	view.fire_go()
	_check(view.songs_played == 0, "HOLD blocks GO")
	view.toggle_hold()
	view.fire_go()
	view.choose_approach("crowd")
	_check(str(view.demo_state.get("booked_show", {}).get("approach", "")) == "wild", "approach locked after first song")
	view.fire_go()
	view.fire_go()
	_check(view.songs_played == 3, "three songs played in order")
	view.advance_journey()
	_check(view.journey_step == 3 and view.settled and view.settlement_count == 1, "one show settlement")
	_check(view.demo_state.get("gig_history", []).size() == 1, "actual history present after stage")
	view.fire_encore()
	_check(not view.encore_fired, "no encore after show settlement")
	# A direct second settlement is forbidden; only explicit restart creates new sample.
	_check(not Model.settle(view.demo_state, 3, true, true, false, view.settled).get("ok", false), "cannot pay twice")
	_check(Worlds.relative_luminance(Worlds.palette("gig", "day")["bg"]) > Worlds.relative_luminance(Worlds.palette("gig", "night")["bg"]) * 15.0, "day backdrop substantially lighter than night")
	view.queue_free()
	if failures == 0:
		print("GIG NIGHT JOURNEY TESTS PASSED")
	quit(0 if failures == 0 else 1)

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error("GIG JOURNEY FAILURE: " + detail)
