extends SceneTree
## Sprint 08 deterministic, no-save typography and cross-family gallery checks.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
const Type = preload("res://Scripts/scene_world_typography.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for role in Type.ROLE_SIZES:
		var path: String = Type.font_path(role)
		_check(ResourceLoader.exists(path), "missing licensed font " + role)
		_check(Type.font_for(role) != null, "font import failed " + role)
	for family in ["tour", "songwriting", "gig"]:
		var day: Dictionary = Worlds.palette(family, "day")
		var night: Dictionary = Worlds.palette(family, "night")
		_check(Worlds.relative_luminance(day["bg"]) > Worlds.relative_luminance(night["bg"]) * 7.0, family + " day/night separation")
		for phase in Worlds.PHASES:
			var p: Dictionary = Worlds.palette(family, phase)
			_check(Worlds.contrast_ratio(p["ink"], p["bg"]) >= 4.5, family + " " + phase + " text contrast")
			_check(Worlds.contrast_ratio(p["muted"], p["bg"]) >= 4.5, family + " " + phase + " muted contrast")
	var packed: PackedScene = load("res://poc/scene_worlds_convergence.tscn")
	_check(packed != null, "convergence gallery loads")
	if packed != null:
		var view: Control = packed.instantiate()
		get_root().add_child(view)
		await process_frame
		for family in ["tour", "songwriting", "gig"]:
			view.set_family(family)
			for phase in Worlds.PHASES:
				view.set_phase(phase)
				var bg: ColorRect = view.find_child("ConvergenceBackdrop", true, false) as ColorRect
				var primary: Button = view.find_child("ConvergencePrimary", true, false) as Button
				var display: Label = view.find_child("ConvergenceHeading", true, false) as Label
				var mono: Label = view.find_child("ConvergenceReadout", true, false) as Label
				_check(bg != null and bg.color == Worlds.palette(family, phase)["bg"], "background " + family + " " + phase)
				_check(primary != null and primary.text.contains(family.to_upper()), "launch action " + family)
				_check(primary != null and primary.focus_mode == Control.FOCUS_ALL, "keyboard focus " + family)
				_check(display != null and display.get_theme_font("font") != null, "display font " + family)
				_check(mono != null and mono.get_theme_font("font") != null, "mono font " + family)
		view.queue_free()
	for path in ["res://poc/tour_planning_journey.tscn", "res://poc/songwriting_journey_poc.tscn", "res://poc/gig_night_journey_poc.tscn"]:
		_check(ResourceLoader.exists(path), "missing linked PoC " + path)
	if failures == 0:
		print("SPRINT 08 TYPOGRAPHY AND CONVERGENCE TESTS PASSED")
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("SPRINT 08 FAILURE: " + message)
