extends "res://poc/gig_night_controls_lab.gd"
## Sprint 07 — isolated show-day journey built on the Sprint 06 live rig.
## Stage transitions are simulated GAME moments, never wall-clock. No FileAccess.
const Model = preload("res://Scripts/gig_night_journey_model.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")
const WorldsJourney = preload("res://Scripts/scene_world_theme.gd")

const APPROACHES := ["tight", "wild", "crowd"]
var journey_step := 0 # 0 load-in; 1 soundcheck; 2 show; 3 aftershow
var demo_state: Dictionary = Model.sample_state()
var settled := false
var settlement_count := 0
var settlement: Dictionary = {}
var error_message := ""

func _ready() -> void:
	phase = "day"
	super._ready()

func set_phase(_value: String) -> void:
	# Deliberately disable the lab's free time-of-day jump.
	pass

func reset_demo() -> void:
	# The generic lab reset button must not bypass settlement or restart mid-show.
	pass

func restart_journey() -> void:
	if journey_step != 3:
		return
	demo_state = Model.sample_state()
	journey_step = 0
	phase = "day"
	equipment_ready = false
	soundcheck_ready = false
	held = false
	selected_song = 0
	songs_played = 0
	encore_fired = false
	preview_count = 0
	settled = false
	settlement_count = 0
	settlement = {}
	error_message = ""
	_render()

func toggle_equipment() -> void:
	if journey_step == 0:
		super.toggle_equipment()

func toggle_soundcheck() -> void:
	if journey_step == 1:
		super.toggle_soundcheck()

func toggle_hold() -> void:
	if journey_step == 2:
		super.toggle_hold()

func select_song(index: int) -> void:
	if journey_step == 2:
		super.select_song(index)

func can_go() -> bool:
	return journey_step == 2 and not settled and super.can_go()

func fire_go() -> void:
	if journey_step == 2:
		super.fire_go()

func can_encore() -> bool:
	return journey_step == 2 and not settled and super.can_encore()

func fire_encore() -> void:
	if journey_step == 2:
		super.fire_encore()

func choose_approach(value: String) -> void:
	if journey_step > 2 or songs_played > 0 or settled:
		return
	var result: Dictionary = Model.choose_approach(demo_state, value)
	if not bool(result.get("ok", false)):
		error_message = str(result.get("message", "Invalid show choice."))
	else:
		demo_state = result["state"]
		error_message = ""
	_render()

func preview_cues() -> void:
	# The inherited primary action is rebound through this virtual method.
	advance_journey()

func advance_journey() -> void:
	error_message = ""
	match journey_step:
		0:
			if not equipment_ready:
				error_message = "SECURE THE GEAR BEFORE SOUNDCHECK"
			else:
				journey_step = 1
				phase = WorldsJourney.resolve_phase({"moment": "soundcheck"})
		1:
			if not soundcheck_ready:
				error_message = "COMPLETE SOUNDCHECK BEFORE STAGE"
			else:
				journey_step = 2
				phase = WorldsJourney.resolve_phase({"moment": "performance"})
		2:
			var result: Dictionary = Model.settle(demo_state, songs_played, equipment_ready, soundcheck_ready, held, settled)
			if not bool(result.get("ok", false)):
				error_message = str(result.get("message", "Set cannot be settled."))
			else:
				demo_state = result["state"]
				settlement = result
				settled = true
				settlement_count += 1
				journey_step = 3
				phase = WorldsJourney.resolve_phase({"moment": "aftershow"})
		3:
			restart_journey()
			return
	_render()

func _phase_caption() -> String:
	match journey_step:
		0:
			return "DAY / LOAD-IN / GET THE GEAR SAFELY ON STAGE"
		1:
			return "DUSK / SOUNDCHECK / CHECK THE SIGNAL BEFORE DOORS"
		2:
			return "NIGHT / PERFORMANCE / THREE SONGS, ONE SHOW"
		_:
			return "AFTERSHOW / SETTLED ONCE / LOCAL DEMO ONLY"

func _status_message() -> String:
	if not error_message.is_empty():
		return error_message
	match journey_step:
		0:
			return "DAYLIGHT LOAD-IN / SECURE THE GEAR"
		1:
			return "DUSK SOUNDCHECK / TEST THE LIVE SIGNAL"
		2:
			return "NIGHT SET / %d OF 3 SONGS PLAYED / %s" % [songs_played, "HOLD" if held else "READY"]
		_:
			return "SHOW PAID ONCE / NO CAREER SAVE WRITES"

func _render() -> void:
	super._render()
	var primary: Button = find_child("GigPrimary", true, false) as Button
	if primary == null:
		return
	var overline: Label = find_child("GigOverline", true, false) as Label
	if overline != null:
		overline.text = "LIVIN' THE DREAM  /  GIG NIGHT JOURNEY 07  /  LOCAL DEMO"
	var heading: Label = find_child("GigHeading", true, false) as Label
	var caption: Label = find_child("GigPhotoCaption", true, false) as Label
	var disclaimer: Label = find_child("GigSetlistDisclaimer", true, false) as Label
	var status: Label = find_child("GigStatus", true, false) as Label
	var reset: Button = find_child("GigReset", true, false) as Button
	var gear: Button = find_child("GigGearLatch", true, false) as Button
	var sound: Button = find_child("GigSoundLatch", true, false) as Button
	var hold_button: Button = find_child("GigHold", true, false) as Button
	if reset != null:
		reset.disabled = true
		reset.visible = false
	if gear != null:
		gear.disabled = journey_step != 0
	if sound != null:
		sound.disabled = journey_step != 1 or not equipment_ready
	if hold_button != null:
		hold_button.disabled = journey_step != 2
	var approach: String = str(demo_state.get("booked_show", {}).get("approach", "tight"))
	for i in range(APPROACHES.size()):
		var item: String = APPROACHES[i]
		var phase_name: String = ["PhaseDay", "PhaseDusk", "PhaseNight"][i]
		var option: Button = find_child(phase_name, true, false) as Button
		if option == null:
			continue
		option.text = ["TIGHT SET", "BIG NIGHT", "WIN ROOM"][i]
		option.tooltip_text = str(Circuit.APPROACHES[item]["label"])
		option.disabled = journey_step == 3 or songs_played > 0
		option.toggle_mode = false
		var fill: Color = Color("#D7A45D") if item == approach else WorldsJourney.palette("gig", phase)["surface"]
		var edge: Color = Color("#E9C184") if item == approach else WorldsJourney.palette("gig", phase)["border"]
		var ink: Color = Color("#17252C") if item == approach else WorldsJourney.palette("gig", phase)["ink"]
		option.add_theme_stylebox_override("normal", _plate(fill, edge, 2 if item == approach else 1))
		option.add_theme_stylebox_override("hover", _plate(fill.lightened(0.07), edge, 2))
		option.add_theme_stylebox_override("pressed", _plate(fill.darkened(0.10), edge, 2))
		option.add_theme_stylebox_override("hover_pressed", _plate(fill.lightened(0.05), edge, 2))
		option.add_theme_stylebox_override("disabled", _plate(fill if item == approach else fill.darkened(0.12), edge.darkened(0.12), 1))
		option.add_theme_color_override("font_disabled_color", Color("#17252C") if item == approach else WorldsJourney.palette("gig", phase)["muted"])
		for font_state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			option.add_theme_color_override(font_state, ink)
		option.pressed.connect(func() -> void: choose_approach(item))
	primary.text = ["GO TO SOUNDCHECK", "OPEN THE STAGE", "SETTLE SHOW", "RESTART SAMPLE SHOW"][journey_step]
	primary.disabled = (journey_step == 0 and not equipment_ready) or (journey_step == 1 and not soundcheck_ready) or (journey_step == 2 and (songs_played != 3 or held or settled))
	if heading != null:
		heading.text = "THE AFTERSHOW" if journey_step == 3 else "GIG NIGHT / THE SHOW"
	if caption != null:
		caption.text = ["DAYLIGHT / LOAD-IN", "SUNSET / SOUNDCHECK", "LIGHTS DOWN / ON STAGE", "AFTER THE ENCORE / SETTLED"][journey_step]
	if disclaimer != null:
		if journey_step == 3:
			var history: Array = demo_state.get("gig_history", [])
			var last: Dictionary = history.back() if not history.is_empty() else {}
			disclaimer.text = "FEE £%d / FANS %d / CASH £%d / ONCE ONLY" % [int(last.get("fee", 0)), int(demo_state.get("fans", 0)), int(demo_state.get("cash", 0))]
		else:
			var preview: Dictionary = Circuit.approach_preview(demo_state, approach)
			disclaimer.text = "%s / %s / FICTIONAL BAND DEMO" % [str(preview.get("label", "TIGHT SET")), str(preview.get("outlook", "RISKY"))]
	if status != null:
		status.text = _status_message()
