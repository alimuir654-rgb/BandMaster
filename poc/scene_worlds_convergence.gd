extends Control
## Sprint 08 isolated cross-family quality gate, not a production dashboard.
## All links open local PoCs; never loads or writes a career save.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
const Type = preload("res://Scripts/scene_world_typography.gd")
const WORLDS := {
	"tour": {"title": "THE NEXT STOP", "detail": "Daylight itinerary and van load. Dusk arrival. Real simulated costs.", "scene": "res://poc/tour_planning_journey.tscn", "status": "ROAD-CASE ART: PROTOTYPE / LAB 08.4 HOLD"},
	"songwriting": {"title": "FIND THE SOUND", "detail": "Paper notebook and arrangement tape. Real session choices.", "scene": "res://poc/songwriting_journey_poc.tscn", "status": "PAPER ART: PROTOTYPE / FONT PROOF ONLY"},
	"gig": {"title": "LIGHTS DOWN", "detail": "Load-in, soundcheck, live set and once-only show settlement.", "scene": "res://poc/gig_night_journey_poc.tscn", "status": "DARK DAY PHOTO: REPLACE / LIVE RIG ART HOLD"},
}
var family := "tour"
var phase := "day"
var _scale := 1.0
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild()

func set_family(value: String) -> void:
	if not WORLDS.has(value):
		return
	family = value
	if is_inside_tree():
		_rebuild()

func set_phase(value: String) -> void:
	if not Worlds.PHASES.has(value):
		return
	phase = value
	if is_inside_tree():
		_rebuild()

func _rebuild() -> void:
	_scale = clampf(get_viewport_rect().size.x / float(maxi(1, DisplayServer.window_get_size().x)), 0.7, 2.3)
	for old in get_children():
		remove_child(old)
		old.queue_free()
	var p: Dictionary = Worlds.palette(family, phase)
	var bg := ColorRect.new()
	bg.name = "ConvergenceBackdrop"
	bg.color = p["bg"]
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dock_h := 92.0 * _scale
	var scroll := ScrollContainer.new()
	scroll.name = "ConvergenceScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -dock_h
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var page := MarginContainer.new()
	page.custom_minimum_size.x = minf(880.0 * _scale, maxf(310.0 * _scale, get_viewport_rect().size.x - 24.0 * _scale))
	for side in ["left", "right", "top", "bottom"]:
		page.add_theme_constant_override("margin_" + side, roundi(14.0 * _scale))
	center.add_child(page)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi(10.0 * _scale))
	page.add_child(col)
	_label(col, "LIVIN' THE DREAM  /  CROSS-FAMILY QUALITY GATE 08", "caption", p["muted"], "ConvergenceOverline")
	_label(col, "ONE GAME. THREE WORKSPACES.", "display", p["ink"], "ConvergenceHeading")
	_label(col, "Typography is real OFL font data. The hardware and photography remain provisional until owner review.", "body", p["muted"], "ConvergenceBody")
	_label(col, "CHOOSE THE WORLD", "caption", p["muted"])
	var families := HBoxContainer.new()
	families.add_theme_constant_override("separation", roundi(5.0 * _scale))
	col.add_child(families)
	for key in ["tour", "songwriting", "gig"]:
		var chosen: String = key
		_button(families, {"tour": "TOUR", "songwriting": "WRITE", "gig": "GIG"}[key], chosen == family, func() -> void: set_family(chosen), p, "Family" + key.capitalize())
	_label(col, "SIMULATED GAME MOMENT", "caption", p["muted"])
	var phases := HBoxContainer.new()
	phases.add_theme_constant_override("separation", roundi(5.0 * _scale))
	col.add_child(phases)
	for key in Worlds.PHASES:
		var chosen_phase: String = key
		_button(phases, key.to_upper(), chosen_phase == phase, func() -> void: set_phase(chosen_phase), p, "Moment" + key.capitalize())
	var panel := PanelContainer.new()
	panel.name = "ConvergenceMaterialSpecimen"
	panel.add_theme_stylebox_override("panel", _style(p["surface"], p["border"], 2))
	col.add_child(panel)
	var inner := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, roundi(15.0 * _scale))
	panel.add_child(inner)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", roundi(10.0 * _scale))
	inner.add_child(stack)
	_label(stack, family.to_upper() + "  /  " + phase.to_upper(), "technical", p["muted"], "ConvergenceTechnical")
	_label(stack, str(WORLDS[family]["title"]), "module", p["ink"], "ConvergenceModule")
	_label(stack, str(WORLDS[family]["detail"]), "body", p["ink"], "ConvergenceDescription")
	_label(stack, "03:17  /  £067  /  120 BPM", "technical", p["ink"], "ConvergenceReadout")
	_label(stack, str(WORLDS[family]["status"]), "caption", p["muted"], "ConvergenceArtHold")
	_label(col, "DAY = LIGHT PAPER  /  DUSK = PETROL  /  NIGHT = GRAPHITE", "caption", p["muted"])
	_status = _label(col, "QA-ONLY LAUNCHER  /  NO CAREER SAVE WRITES", "caption", p["muted"], "ConvergenceStatus")
	var dock := PanelContainer.new()
	dock.name = "ConvergenceActionDock"
	dock.add_theme_stylebox_override("panel", _style(p["panel"], p["border"], 1))
	add_child(dock)
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_top = -dock_h
	dock.offset_bottom = 0
	var pad := MarginContainer.new()
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, roundi(16.0 * _scale))
	for side in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, roundi(12.0 * _scale))
	dock.add_child(pad)
	var primary := Button.new()
	primary.name = "ConvergencePrimary"
	primary.text = "OPEN " + family.to_upper() + " JOURNEY"
	primary.custom_minimum_size.y = 58.0 * _scale
	primary.focus_mode = Control.FOCUS_ALL
	primary.add_theme_stylebox_override("normal", _style(p["action"], p["border"], 2))
	primary.add_theme_stylebox_override("hover", _style(p["action"].lightened(0.10), p["border"], 2))
	primary.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, p["ink"], 3))
	primary.add_theme_color_override("font_color", p["action_ink"])
	primary.add_theme_color_override("font_hover_color", p["action_ink"])
	primary.add_theme_font_size_override("font_size", roundi(17.0 * _scale))
	var action_font := Type.font_for("body")
	if action_font != null:
		primary.add_theme_font_override("font", action_font)
	primary.pressed.connect(_open_journey)
	pad.add_child(primary)

func _open_journey() -> void:
	var path: String = str(WORLDS[family]["scene"])
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		_status.text = "QA SCENE FAILED TO OPEN: " + path

func _label(parent: Node, text_value: String, role: String, color: Color, name_value: String = "") -> Label:
	var label := Label.new()
	label.text = text_value
	if not name_value.is_empty():
		label.name = name_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	Type.apply(label, role, _scale)
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, selected: bool, callback: Callable, p: Dictionary, name_value: String) -> Button:
	var b := Button.new()
	b.name = name_value
	b.text = caption
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 50.0 * _scale
	b.focus_mode = Control.FOCUS_ALL
	var fill: Color = p["action"] if selected else p["surface"]
	var ink: Color = p["action_ink"] if selected else p["ink"]
	b.add_theme_stylebox_override("normal", _style(fill, p["border"], 2 if selected else 1))
	b.add_theme_stylebox_override("hover", _style(fill.lightened(0.08), p["border"], 2))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, p["ink"], 3))
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_font_size_override("font_size", roundi(14.0 * _scale))
	var font := Type.font_for("body")
	if font != null:
		b.add_theme_font_override("font", font)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _style(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	return style
