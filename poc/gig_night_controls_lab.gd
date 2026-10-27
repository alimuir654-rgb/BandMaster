extends Control
## Sprint 06 — isolated, interactive LIVE RIG control lab.
## Existing licensed repo imagery and tour-case steel are *temporary material references*,
## NOT owner-approved Lab 08.4 photoreal hardware. No save or economy writes.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
const CASE_ART = preload("res://Art/UI/Tour/road_case_surface.svg")
const BACKSTAGE_ART = preload("res://Art/Backgrounds/shared/backstage.webp")
const STAGE_ART = preload("res://Art/Backgrounds/shared/gigs.webp")
const SONGS := ["MIDNIGHT SIGNAL", "HIGHER GROUND", "LOST IN THE NOISE"]
const PHASES := ["day", "dusk", "night"]

var phase := "day"
var soundcheck_ready := false
var equipment_ready := false
var held := false
var selected_song := 0
var songs_played := 0
var encore_fired := false
var preview_count := 0
var _scale := 1.0
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_render()

func set_phase(value: String) -> void:
	if not PHASES.has(value):
		return
	phase = value
	if is_inside_tree():
		_render()

func select_song(index: int) -> void:
	if index < songs_played or index >= SONGS.size():
		return
	selected_song = index
	if is_inside_tree():
		_render()

func toggle_equipment() -> void:
	equipment_ready = not equipment_ready
	if not equipment_ready:
		soundcheck_ready = false
	if is_inside_tree():
		_render()

func toggle_soundcheck() -> void:
	if not equipment_ready:
		return
	soundcheck_ready = not soundcheck_ready
	if is_inside_tree():
		_render()

func toggle_hold() -> void:
	held = not held
	if is_inside_tree():
		_render()

func can_go() -> bool:
	return phase == "night" and equipment_ready and soundcheck_ready and not held and songs_played < SONGS.size() and selected_song == songs_played

func fire_go() -> void:
	if not can_go():
		return
	songs_played += 1
	selected_song = mini(songs_played, SONGS.size() - 1)
	preview_count += 1
	if is_inside_tree():
		_render()

func can_encore() -> bool:
	return phase == "night" and equipment_ready and soundcheck_ready and not held and songs_played == SONGS.size() and not encore_fired

func fire_encore() -> void:
	if not can_encore():
		return
	encore_fired = true
	preview_count += 1
	if is_inside_tree():
		_render()

func reset_demo() -> void:
	held = false
	songs_played = 0
	selected_song = 0
	encore_fired = false
	preview_count = 0
	if is_inside_tree():
		_render()

func _render() -> void:
	_scale = clampf(get_viewport_rect().size.x / float(maxi(1, DisplayServer.window_get_size().x)), 0.7, 2.3)
	var mobile := DisplayServer.window_get_size().x < 680
	var compact := DisplayServer.window_get_size().y <= 800
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var p: Dictionary = Worlds.palette("gig", phase)
	var bg := ColorRect.new()
	bg.name = "GigTimeBackdrop"
	bg.color = p["bg"]
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dock_h := 100.0 * _scale
	var scroll := ScrollContainer.new()
	scroll.name = "GigLabScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -dock_h
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var page := MarginContainer.new()
	page.custom_minimum_size.x = minf(920.0 * _scale, maxf(320.0 * _scale, get_viewport_rect().size.x - 24.0 * _scale))
	for side in ["left", "right"]:
		page.add_theme_constant_override("margin_" + side, roundi(10 * _scale))
	page.add_theme_constant_override("margin_top", roundi((9 if compact else 14) * _scale))
	page.add_theme_constant_override("margin_bottom", roundi(24 * _scale))
	center.add_child(page)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi((6 if compact else 10) * _scale))
	page.add_child(col)
	_text(col, "LIVIN' THE DREAM  /  LIVE RIG CONTROL LAB 06", 11, p["muted"], "GigOverline")
	_text(col, "THE SHOW DESK", 29 if mobile else 36, p["ink"], "GigHeading")
	_text(col, _phase_caption(), 13, p["muted"], "GigPhaseCaption")

	var phases := HBoxContainer.new()
	phases.add_theme_constant_override("separation", roundi(6 * _scale))
	col.add_child(phases)
	for item in PHASES:
		var next_phase: String = item
		var caption: String = str({"day":"DAY / LOAD-IN", "dusk":"DUSK / CHECK", "night":"NIGHT / SHOW"}[item])
		_button(phases, caption, item == phase, func() -> void: set_phase(next_phase), p, "Phase" + item.capitalize(), "phase")

	var hero := Control.new()
	hero.name = "GigPhotographicHero"
	hero.custom_minimum_size.y = (116 if compact else (146 if mobile else 164)) * _scale
	hero.clip_contents = true
	col.add_child(hero)
	var photo := TextureRect.new()
	photo.name = "GigExistingRepoPhoto"
	photo.texture = STAGE_ART if phase == "night" else BACKSTAGE_ART
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.name = "GigPhotoVeil"
	veil.color = Color(0.07, 0.10, 0.11, 0.20 if phase == "day" else (0.30 if phase == "dusk" else 0.38))
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hero_label := Label.new()
	hero_label.name = "GigPhotoCaption"
	hero_label.text = "LOAD-IN  /  CABLES & CASES" if phase == "day" else ("SOUNDCHECK  /  STAGE READY?" if phase == "dusk" else "HOUSE LIGHTS DOWN  /  LIVE")
	hero_label.position = Vector2(13, 13) * _scale
	hero_label.add_theme_font_size_override("font_size", roundi(14 * _scale))
	hero_label.add_theme_color_override("font_color", Color("#F9F3E7"))
	hero_label.add_theme_stylebox_override("normal", _plate(Color(0.03, 0.07, 0.09, 0.84), Color("#8A9595"), 1))
	hero.add_child(hero_label)

	var rack := Control.new()
	rack.name = "GigHardwareRack"
	rack.custom_minimum_size.y = (224 if compact else (244 if mobile else 252)) * _scale
	rack.clip_contents = true
	col.add_child(rack)
	var rack_art := TextureRect.new()
	rack_art.name = "GigCaseMaterialReference"
	rack_art.texture = CASE_ART
	rack_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rack_art.stretch_mode = TextureRect.STRETCH_SCALE
	rack_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rack.add_child(rack_art)
	rack_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rack_margin := MarginContainer.new()
	rack.add_child(rack_margin)
	rack_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		rack_margin.add_theme_constant_override("margin_" + side, roundi(34 * _scale))
	for side in ["top", "bottom"]:
		rack_margin.add_theme_constant_override("margin_" + side, roundi(18 * _scale))
	var rack_col := VBoxContainer.new()
	rack_col.add_theme_constant_override("separation", roundi(4 * _scale))
	rack_margin.add_child(rack_col)
	_text(rack_col, "SETLIST / STAGE CHANNEL 01", 12, Color("#D6DFDB"), "GigSetlistHeading")
	for i in range(SONGS.size()):
		var song_index: int = i
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", roundi(6 * _scale))
		rack_col.add_child(row)
		var badge := _text(row, "%02d" % (i + 1), 12, Color("#E9B965"))
		badge.custom_minimum_size.x = 23 * _scale
		var label: String = str(SONGS[i])
		if i < songs_played:
			label = "✓ " + label
		var song_button := _button(row, label, i == selected_song and i >= songs_played,
			func() -> void: select_song(song_index), p, "GigSong%d" % i, "hardware")
		song_button.disabled = i < songs_played
		song_button.custom_minimum_size.y = 46 * _scale
	_text(rack_col, "DEMO SET / NO CAREER BOOKINGS OR REWARDS", 11, Color("#B5C4C5"), "GigSetlistDisclaimer")

	var safety := HBoxContainer.new()
	safety.name = "GigSafetyControls"
	safety.add_theme_constant_override("separation", roundi(7 * _scale))
	col.add_child(safety)
	_button(safety, "GEAR: " + ("SECURE" if equipment_ready else "CHECK"), equipment_ready,
		toggle_equipment, p, "GigGearLatch", "utility")
	var sound_button := _button(safety, "SOUND: " + ("READY" if soundcheck_ready else "CHECK"), soundcheck_ready,
		toggle_soundcheck, p, "GigSoundLatch", "utility")
	sound_button.disabled = not equipment_ready

	var cue_row := HBoxContainer.new()
	cue_row.name = "GigCueControls"
	cue_row.add_theme_constant_override("separation", roundi(6 * _scale))
	col.add_child(cue_row)
	var go := _button(cue_row, "▶  GO", false, fire_go, p, "GigGo", "go")
	go.disabled = not can_go()
	_button(cue_row, "Ⅱ  " + ("RELEASE" if held else "HOLD"), held, toggle_hold, p, "GigHold", "hold")
	var encore := _button(cue_row, "★  ENCORE", encore_fired, fire_encore, p, "GigEncore", "encore")
	encore.disabled = not can_encore()

	var meters := PanelContainer.new()
	meters.name = "GigSignalRack"
	meters.add_theme_stylebox_override("panel", _plate(Color("#17242A"), Color("#6D7F80"), 2))
	col.add_child(meters)
	var meter_margin := MarginContainer.new()
	for side in ["left", "right"]:
		meter_margin.add_theme_constant_override("margin_" + side, roundi(13 * _scale))
	for side in ["top", "bottom"]:
		meter_margin.add_theme_constant_override("margin_" + side, roundi(8 * _scale))
	meters.add_child(meter_margin)
	var meter_col := VBoxContainer.new()
	meter_col.add_theme_constant_override("separation", roundi(6 * _scale))
	meter_margin.add_child(meter_col)
	_text(meter_col, "LIVE SIGNAL / CREW READINESS", 11, Color("#D4DEDC"))
	_meter(meter_col, "SOUND", 7 if soundcheck_ready else (3 if equipment_ready else 1), Color("#62D69A"))
	_meter(meter_col, "BAND", 7 if equipment_ready else 2, Color("#6FD6D6"))
	_meter(meter_col, "CROWD", 3 if phase == "day" else (5 if phase == "dusk" else 8), Color("#E6AE55"))

	var footer := PanelContainer.new()
	footer.name = "GigActionDock"
	footer.add_theme_stylebox_override("panel", _plate(p["surface"], p["border"], 1))
	add_child(footer)
	var dock_w := minf(730.0 * _scale, get_viewport_rect().size.x - 16.0 * _scale)
	footer.anchor_left = 0.5
	footer.anchor_right = 0.5
	footer.anchor_top = 1
	footer.anchor_bottom = 1
	footer.offset_left = -dock_w * 0.5
	footer.offset_right = dock_w * 0.5
	footer.offset_top = -dock_h
	footer.offset_bottom = -4 * _scale
	var footer_margin := MarginContainer.new()
	for side in ["left", "right"]:
		footer_margin.add_theme_constant_override("margin_" + side, roundi(10 * _scale))
	footer_margin.add_theme_constant_override("margin_top", roundi(5 * _scale))
	footer_margin.add_theme_constant_override("margin_bottom", roundi(5 * _scale))
	footer.add_child(footer_margin)
	var footer_col := VBoxContainer.new()
	footer_col.add_theme_constant_override("separation", roundi(4 * _scale))
	footer_margin.add_child(footer_col)
	var message := _status_message()
	_status = _text(footer_col, message, 12, p["muted"], "GigStatus")
	_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.clip_text = true
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", roundi(6 * _scale))
	footer_col.add_child(footer_row)
	var reset := _button(footer_row, "RESET", false, reset_demo, p, "GigReset", "utility")
	reset.size_flags_stretch_ratio = 0.35
	var primary := _button(footer_row, "REVIEW SHOW CUES", false, preview_cues, p, "GigPrimary", "primary")
	primary.size_flags_stretch_ratio = 1.5

func _phase_caption() -> String:
	match phase:
		"day":
			return "DAYLIGHT / VAN LOAD-IN / PRACTICAL CREW CHECKS"
		"dusk":
			return "DUSK / SOUNDCHECK / AMPS & CABLES"
		_:
			return "NIGHT / STAGE LIGHTS / THE SET IS LIVE"

func _status_message() -> String:
	if held:
		return "HOLD ACTIVE / GO AND ENCORE LOCKED"
	if encore_fired:
		return "ENCORE CUE FIRED ONCE / LOCAL DEMO ONLY"
	if songs_played == SONGS.size():
		return "SET COMPLETE / ENCORE " + ("READY" if can_encore() else "LOCKED")
	if phase == "night" and not equipment_ready:
		return "SAFETY: SECURE THE GEAR BEFORE A LIVE CUE"
	if phase == "night" and not soundcheck_ready:
		return "SOUND: COMPLETE SOUNDCHECK BEFORE GO"
	return "%d / %d SONGS CUE'D / NO SAVE OR ECONOMY CHANGES" % [songs_played, SONGS.size()]

func preview_cues() -> void:
	preview_count += 1
	if _status != null and is_instance_valid(_status):
		_status.text = "CUE PREVIEW %02d / %s / %d SONGS / NO SAVE WRITES" % [preview_count, phase.to_upper(), songs_played]

func _meter(parent: VBoxContainer, title: String, lit: int, tint: Color) -> void:
	var row := HBoxContainer.new()
	row.name = "GigMeter" + title.capitalize()
	row.add_theme_constant_override("separation", roundi(4 * _scale))
	parent.add_child(row)
	var name := _text(row, title, 11, Color("#D5DEDB"))
	name.custom_minimum_size.x = 66 * _scale
	for i in range(8):
		var segment := ColorRect.new()
		segment.name = title.capitalize() + "Segment%d" % i
		segment.color = tint if i < lit else Color("#35444A")
		segment.custom_minimum_size = Vector2(7, 9) * _scale
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(segment)
	var value := _text(row, "%d/8" % lit, 11, Color("#D5DEDB"))
	value.custom_minimum_size.x = 29 * _scale

func _text(parent: Node, value: String, point_size: int, ink: Color, id: String = "") -> Label:
	var label := Label.new()
	if not id.is_empty():
		label.name = id
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(point_size * _scale))
	label.add_theme_color_override("font_color", ink)
	parent.add_child(label)
	return label

func _plate(fill: Color, edge: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.border_width_bottom = width + 1
	style.set_corner_radius_all(3)
	style.set_content_margin_all(roundi(6 * _scale))
	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 2
	return style

func _button(parent: Node, title: String, selected: bool, action: Callable, p: Dictionary, id: String, kind: String) -> Button:
	var button := Button.new()
	button.name = id
	button.text = title
	button.custom_minimum_size.y = (49 if kind != "hardware" else 44) * _scale
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	var fill: Color = p["surface"]
	var edge: Color = p["border"]
	var ink: Color = p["ink"]
	match kind:
		"hardware":
			fill = Color("#29383D") if not selected else Color("#C18A43")
			edge = Color("#6C7B7C") if not selected else Color("#E8C384")
			ink = Color("#F4F1E9") if not selected else Color("#142329")
		"go":
			fill = Color("#1F654A")
			edge = Color("#61D9A0")
			ink = Color("#F8FFF8")
		"hold":
			fill = Color("#8A5A25") if selected else Color("#59452E")
			edge = Color("#E2AD65")
			ink = Color("#FFF5DD")
		"encore":
			fill = Color("#4D375B")
			edge = Color("#C1A3E2")
			ink = Color("#FCF5FF")
		"primary":
			fill = p["action"]
			edge = Color("#A96D2C")
			ink = p["action_ink"]
		_:
			if selected:
				fill = p["action"]
				edge = Color("#A96D2C")
				ink = p["action_ink"]
	var normal := _plate(fill, edge, 2 if selected else 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _plate(fill.lightened(0.10), edge, 2))
	button.add_theme_stylebox_override("pressed", _plate(fill.darkened(0.14), edge, 2))
	var disabled := _plate(fill.darkened(0.36), edge.darkened(0.26), 1)
	button.add_theme_stylebox_override("disabled", disabled)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#FDE5A4")
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", Color("#AAB4B1") if kind in ["hardware","go","hold","encore"] else p["muted"])
	button.add_theme_font_size_override("font_size", roundi((14 if kind == "hardware" else 15) * _scale))
	button.pressed.connect(action)
	parent.add_child(button)
	return button
