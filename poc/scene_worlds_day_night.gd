extends Control
## Runnable, save-independent material and typography lab.
## Existing repository photography only; approved Lab 08.4 hardware awaits import.

const Worlds = preload("res://Scripts/scene_world_theme.gd")
const ART := {
	"tour": "res://Art/Backgrounds/shared/gigs.webp",
	"songwriting": "res://Art/Backgrounds/shared/studio.webp",
	"gig": "res://Art/Backgrounds/shared/backstage.webp",
	"studio": "res://Art/Backgrounds/shared/actions.webp",
}
const SCENES := {
	"tour": {
		"heading": "PLAN THE NEXT RUN",
		"copy": "The van is loaded. Two venues want Friday. Decide which show the band can actually reach.",
		"day": "DAY / ROUTE DESK", "dusk": "DUSK / ROAD ARRIVAL", "night": "NIGHT / AFTER THE DRIVE",
		"stat_a": "NEXT STOP", "value_a": "BRISTOL", "stat_b": "AVAILABLE", "value_b": "£285",
		"action": "REVIEW THE ITINERARY",
	},
	"songwriting": {
		"heading": "FIND THE CHORUS",
		"copy": "One good line, a half-finished riff and a room full of opinions. Give the song a direction.",
		"day": "DAY / WRITING ROOM", "dusk": "DUSK / REHEARSAL", "night": "NIGHT / LAST TAKE",
		"stat_a": "DRAFT", "value_a": "01 / 03", "stat_b": "IDEA", "value_b": "THE HOOK",
		"action": "OPEN THE WRITING DESK",
	},
	"gig": {
		"heading": "TONIGHT IS THE NIGHT",
		"copy": "The venue doors open soon. The crew need a clear cue, not another spreadsheet.",
		"day": "DAY / LOAD-IN", "dusk": "DUSK / SOUNDCHECK", "night": "NIGHT / ON STAGE",
		"stat_a": "SETLIST", "value_a": "06 SONGS", "stat_b": "SOUND", "value_b": "READY",
		"action": "CHECK THE SHOW CUES",
	},
	"studio": {
		"heading": "SHAPE THE SOUND",
		"copy": "The band has a new idea. Choose what deserves a proper recording session.",
		"day": "DAY / STUDIO PLAN", "dusk": "DUSK / FIRST TAKE", "night": "NIGHT / MIX DESK",
		"stat_a": "SESSION", "value_a": "02 / 04", "stat_b": "FOCUS", "value_b": "78%",
		"action": "OPEN STUDIO CONTROLS",
	},
}
var family := "tour"
var phase := "day"
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild()

func set_context(next_family: String, next_phase: String) -> void:
	family = next_family if Worlds.FAMILIES.has(next_family) else "tour"
	phase = next_phase if Worlds.PHASES.has(next_phase) else "day"
	if is_inside_tree():
		_rebuild()

func _rebuild() -> void:
	for old in get_children():
		remove_child(old)
		old.queue_free()
	var p := Worlds.palette(family, phase)
	var sample: Dictionary = SCENES[family]
	var backdrop := ColorRect.new()
	backdrop.name = "TimeOfDayBackdrop"
	backdrop.color = p["bg"]
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.name = "SceneScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var page := MarginContainer.new()
	page.custom_minimum_size.x = minf(920.0, maxf(320.0, get_viewport_rect().size.x - 28.0))
	page.add_theme_constant_override("margin_left", 18)
	page.add_theme_constant_override("margin_right", 18)
	page.add_theme_constant_override("margin_top", 18)
	page.add_theme_constant_override("margin_bottom", 32)
	center.add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	page.add_child(column)

	_text(column, "LIVIN' THE DREAM   /   VISUAL LAB 01", 13, p["muted"], "BrandOverline")
	_text(column, "ONE WORLD. DIFFERENT LIGHT.", 34, p["ink"], "EditorialHeading")
	_text(column, "Daylight is a different environment, not a dark theme with a new accent.", 16, p["muted"], "BodyIntroduction")

	_text(column, "SCENE FAMILY", 13, p["muted"])
	var families := HBoxContainer.new()
	families.add_theme_constant_override("separation", 5)
	column.add_child(families)
	for item in [["tour", "TOUR"], ["songwriting", "WRITE"], ["gig", "GIG"], ["studio", "STUDIO"]]:
		var selected_family := str(item[0])
		_button(families, str(item[1]), selected_family == family, false,
			func() -> void: set_context(selected_family, phase), p)

	_text(column, "SIMULATED SCENE PHASE", 13, p["muted"])
	var phases := HBoxContainer.new()
	phases.add_theme_constant_override("separation", 6)
	column.add_child(phases)
	for next_phase in Worlds.PHASES:
		var chosen_phase: String = next_phase
		_button(phases, next_phase.to_upper(), chosen_phase == phase, false,
			func() -> void: set_context(family, chosen_phase), p)

	var hero := Control.new()
	hero.name = "PhotographicHero"
	hero.custom_minimum_size.y = 136
	hero.clip_contents = true
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(hero)
	if ResourceLoader.exists(ART[family]):
		var photo := TextureRect.new()
		photo.name = "ExistingRepoHero"
		photo.texture = load(ART[family])
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero.add_child(photo)
		photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = p["hero_veil"]
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hero_caption := Label.new()
	hero_caption.text = str(sample[phase])
	hero_caption.position = Vector2(14, 14)
	hero_caption.add_theme_color_override("font_color", Color("#FFFFFF"))
	hero_caption.add_theme_font_size_override("font_size", 15)
	hero.add_child(hero_caption)

	var card := PanelContainer.new()
	card.name = "SceneDecisionCard"
	card.add_theme_stylebox_override("panel", _surface(p["surface"], p["border"]))
	column.add_child(card)
	var card_margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + edge, 12)
	card.add_child(card_margin)
	var card_column := VBoxContainer.new()
	card_column.add_theme_constant_override("separation", 9)
	card_margin.add_child(card_column)
	_text(card_column, str(sample["heading"]), 24, p["ink"], "SceneHeading")
	_text(card_column, str(sample["copy"]), 16, p["ink"], "SceneNarrative")
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	card_column.add_child(stats)
	_stat(stats, str(sample["stat_a"]), str(sample["value_a"]), p)
	_stat(stats, str(sample["stat_b"]), str(sample["value_b"]), p)
	_button(card_column, str(sample["action"]), false, true, _show_lab_action, p, "PrimaryAction")
	_status = _text(card_column, "STYLE STUDY ONLY / NO CAREER DATA CHANGED", 13, p["muted"], "LabStatus")

	var specimen := PanelContainer.new()
	specimen.name = "TypographySpecimen"
	specimen.add_theme_stylebox_override("panel", _surface(p["panel"], p["border"]))
	column.add_child(specimen)
	var specimen_column := VBoxContainer.new()
	specimen_column.add_theme_constant_override("separation", 7)
	specimen.add_child(specimen_column)
	_text(specimen_column, "TYPOGRAPHY STARTER / SYSTEM FALLBACKS ACTIVE", 13, p["muted"])
	_text(specimen_column, "DISPLAY · BARLOW CONDENSED (PROPOSED)", 21, p["ink"])
	_text(specimen_column, "INTERFACE · IBM PLEX SANS (PROPOSED)", 16, p["ink"])
	_text(specimen_column, "READOUT · IBM PLEX MONO (PROPOSED)  02:45 / 78%", 14, p["muted"])
	_text(column, "MATERIAL: " + str(p["material"]).to_upper(), 12, p["muted"])

func _show_lab_action() -> void:
	_status.text = "LAB ACTION RESPONDED / SAVE AND ECONOMY UNTOUCHED"

func _stat(parent: HBoxContainer, heading: String, value: String, p: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _surface(p["panel"], p["border"]))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	_text(box, heading, 12, p["muted"])
	_text(box, value, 19, p["ink"])

func _text(parent: Node, value: String, point_size: int, ink: Color, node_name: String = "") -> Label:
	var label := Label.new()
	if not node_name.is_empty():
		label.name = node_name
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", point_size)
	label.add_theme_color_override("font_color", ink)
	parent.add_child(label)
	return label

func _surface(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.border_width_bottom = 2
	style.set_corner_radius_all(3)
	style.set_content_margin_all(9)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 2
	return style

func _button(parent: Node, label: String, selected: bool, primary: bool, action: Callable, p: Dictionary, node_name: String = "") -> Button:
	var button := Button.new()
	if not node_name.is_empty():
		button.name = node_name
	button.text = label
	button.custom_minimum_size.y = 50
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	var base_fill: Color = p["action"] if primary else (p["panel"] if selected else p["surface"])
	var text_color: Color = p["action_ink"] if primary else p["ink"]
	var normal := _surface(base_fill, p["accent"] if selected else p["border"])
	if selected:
		normal.border_width_bottom = 4
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _surface(base_fill.lightened(0.08), p["accent"]))
	button.add_theme_stylebox_override("pressed", _surface(base_fill.darkened(0.09), p["accent"]))
	button.add_theme_stylebox_override("disabled", _surface(p["panel"], p["border"]))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = p["action"]
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, text_color)
	button.add_theme_color_override("font_disabled_color", p["muted"])
	button.add_theme_font_size_override("font_size", 15 if not primary else 16)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
