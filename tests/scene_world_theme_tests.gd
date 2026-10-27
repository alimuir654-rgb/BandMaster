extends SceneTree
const Worlds = preload("res://Scripts/scene_world_theme.gd")
var failures := 0

func _initialize() -> void:
	_check(Worlds.resolve_phase({"moment": "load_in"}) == "day", "load-in uses day")
	_check(Worlds.resolve_phase({"moment": "soundcheck"}) == "dusk", "soundcheck uses dusk")
	_check(Worlds.resolve_phase({"moment": "performance"}) == "night", "showtime uses night")
	_check(Worlds.resolve_phase({"simulated_hour": 11}) == "day", "11 simulated hour uses day")
	_check(Worlds.resolve_phase({"simulated_hour": 18}) == "dusk", "18 simulated hour uses dusk")
	_check(Worlds.resolve_phase({"simulated_hour": 23}) == "night", "23 simulated hour uses night")
	_check(Worlds.resolve_phase({"phase": "day", "moment": "performance"}) == "day", "explicit phase wins")
	_check(Worlds.resolve_phase({}) == "day", "unknown defaults to daylight")
	var day := Worlds.palette("tour", "day")
	var dusk := Worlds.palette("tour", "dusk")
	var night := Worlds.palette("tour", "night")
	_check(Worlds.relative_luminance(day["bg"]) > Worlds.relative_luminance(dusk["bg"]) * 2.0, "day substantially brighter than dusk")
	_check(Worlds.relative_luminance(day["bg"]) > Worlds.relative_luminance(night["bg"]) * 7.0, "day substantially brighter than night")
	for family in Worlds.FAMILIES:
		for phase in Worlds.PHASES:
			var tokens := Worlds.palette(family, phase)
			_check(Worlds.contrast_ratio(tokens["ink"], tokens["bg"]) >= 4.5, family + " " + phase + " main contrast")
			_check(Worlds.contrast_ratio(tokens["muted"], tokens["bg"]) >= 4.5, family + " " + phase + " muted contrast")
			_check(Worlds.contrast_ratio(tokens["ink"], tokens["surface"]) >= 4.5, family + " " + phase + " surface contrast")
			_check(Worlds.contrast_ratio(tokens["action"], tokens["action_ink"]) >= 4.5, family + " " + phase + " action contrast")
	_check(ResourceLoader.exists("res://Art/Backgrounds/shared/gigs.webp"), "existing tour art")
	_check(ResourceLoader.exists("res://Art/Backgrounds/shared/studio.webp"), "existing songwriting art")
	_check(load("res://poc/scene_worlds_day_night.tscn") != null, "Godot scene loads")
	if failures == 0:
		print("SCENE WORLD TOKEN TESTS PASSED")
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("SCENE WORLD FAILURE: " + message)
