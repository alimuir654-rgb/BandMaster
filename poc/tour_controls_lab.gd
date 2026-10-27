extends Control
## Tour control family, isolated from live career/save/economy.
## Original SVGs are physical surface plates; all changing labels remain Godot text.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
const CASE_ART := preload("res://Art/UI/Tour/road_case_surface.svg")
const TICKET_ART := preload("res://Art/UI/Tour/ticket_stock.svg")
const STOPS := [
	{"id": "bristol", "label": "BRISTOL", "type": "LOCAL SHOW", "date": "FRIDAY"},
	{"id": "cardiff", "label": "CARDIFF", "type": "ROAD SHOW", "date": "SATURDAY"},
	{"id": "bath", "label": "BATH", "type": "ROAD SHOW", "date": "SUNDAY"},
]
var phase := "day"
var stop_id := "bristol"
var van_ready := false
var _scale := 1.0
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild()

func set_context(next_phase: String) -> void:
	phase = next_phase if Worlds.PHASES.has(next_phase) else "day"
	if is_inside_tree():
		_rebuild()

func select_stop(next_stop: String) -> void:
	for stop in STOPS:
		if str(stop["id"]) == next_stop:
			stop_id = next_stop
			break
	if is_inside_tree():
		_rebuild()

func toggle_van() -> void:
	van_ready = not van_ready
	if is_inside_tree():
		_rebuild()

func preview_plan() -> void:
	if _status != null:
		_status.text = ("PREVIEW ONLY / %s / VAN %s / NO SAVE CHANGES" %
			[_selected_stop()["label"], "SECURED" if van_ready else "NOT SECURED"])

func _selected_stop() -> Dictionary:
	for stop in STOPS:
		if str(stop["id"]) == stop_id:
			return stop
	return STOPS[0]

func _rebuild() -> void:
	var logical_width := get_viewport_rect().size.x
	_scale = clampf(logical_width / float(maxi(1, DisplayServer.window_get_size().x)), 0.7, 2.3)
	var mobile := DisplayServer.window_get_size().x < 680
	var compact := DisplayServer.window_get_size().y <= 800
	for old in get_children():
		remove_child(old)
		old.queue_free()
	var p: Dictionary = Worlds.palette("tour", phase)
	var background := ColorRect.new()
	background.name = "TourTimeBackdrop"
	background.color = p["bg"]
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.name = "TourLabScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var page := MarginContainer.new()
	page.custom_minimum_size.x = minf(920 * _scale, maxf(320 * _scale, logical_width - 28 * _scale))
	for edge in ["left", "right"]:
		page.add_theme_constant_override("margin_" + edge, roundi(12 * _scale))
	page.add_theme_constant_override("margin_top", roundi((10 if compact else 13) * _scale))
	page.add_theme_constant_override("margin_bottom", roundi((12 if compact else 25) * _scale))
	center.add_child(page)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi((6 if compact else (8 if mobile else 12)) * _scale))
	page.add_child(col)

	_text(col, "LIVIN' THE DREAM   /   TOUR CONTROL LAB 02", 12, p["muted"], "TourOverline")
	_text(col, "THE ROAD DESK", 26 if compact else (30 if mobile else 36), p["ink"], "TourHeading")
	if not compact:
		_text(col, "DAYLIGHT ROUTES / DUSK ARRIVALS / ROAD-WORN HARDWARE", 13, p["muted"], "TourSubhead")

	var phases := HBoxContainer.new()
	phases.add_theme_constant_override("separation", roundi(6 * _scale))
	col.add_child(phases)
	for next_phase in Worlds.PHASES:
		var choice: String = next_phase
		_button(phases, choice.to_upper(), choice == phase, func() -> void: set_context(choice), p, "", false)

	var case := Control.new()
	case.name = "TourRoadCase"
	case.custom_minimum_size.y = (182 if compact else (228 if mobile else 256)) * _scale
	case.clip_contents = true
	col.add_child(case)
	_texture(case, CASE_ART)
	var case_margin := MarginContainer.new()
	case.add_child(case_margin)
	case_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]:
		case_margin.add_theme_constant_override("margin_" + edge, roundi(24 * _scale))
	for edge in ["top", "bottom"]:
		case_margin.add_theme_constant_override("margin_" + edge, roundi((13 if compact else 20) * _scale))
	var case_col := VBoxContainer.new()
	case_col.add_theme_constant_override("separation", roundi((5 if compact else 8) * _scale))
	case_margin.add_child(case_col)
	_text(case_col, "ROUTE SELECTOR  /  FLIGHT CASE", 12, Color("#D9DFDB"), "CaseHeading")
	var stops := HBoxContainer.new()
	stops.add_theme_constant_override("separation", roundi(5 * _scale))
	case_col.add_child(stops)
	for stop in STOPS:
		var id: String = stop["id"]
		var name: String = stop["label"]
		_button(stops, name, id == stop_id, func() -> void: select_stop(id), p,
			"Route" + name.capitalize(), true)
	var rule := ColorRect.new()
	rule.color = Color("#687477")
	rule.custom_minimum_size.y = 1 * _scale
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	case_col.add_child(rule)
	var latch_row := HBoxContainer.new()
	latch_row.add_theme_constant_override("separation", roundi(8 * _scale))
	case_col.add_child(latch_row)
	var latch_column := VBoxContainer.new()
	latch_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	latch_row.add_child(latch_column)
	_text(latch_column, "VAN LOAD / SAFETY LATCH", 12, Color("#C7D0CD"))
	_text(latch_column, "SECURED" if van_ready else "NOT SECURED", 18, Color("#B5D9C4") if van_ready else Color("#F5CE92"), "VanStatus")
	var lamp := ColorRect.new()
	lamp.name = "VanLamp"
	lamp.color = Color("#55D9A0") if van_ready else Color("#E2A14B")
	lamp.custom_minimum_size = Vector2(9, 9) * _scale
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	latch_row.add_child(lamp)
	_button(case_col, "UNLATCH VAN" if van_ready else "SECURE VAN LOAD", false,
		toggle_van, p, "VanLatch", true)

	var ticket := Control.new()
	ticket.name = "TourPaperTicket"
	ticket.custom_minimum_size.y = (98 if compact else (110 if mobile else 124)) * _scale
	ticket.clip_contents = true
	col.add_child(ticket)
	_texture(ticket, TICKET_ART)
	var ticket_margin := MarginContainer.new()
	ticket.add_child(ticket_margin)
	ticket_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ticket_margin.add_theme_constant_override("margin_left", roundi(19 * _scale))
	ticket_margin.add_theme_constant_override("margin_right", roundi(21 * _scale))
	ticket_margin.add_theme_constant_override("margin_top", roundi((8 if compact else 12) * _scale))
	ticket_margin.add_theme_constant_override("margin_bottom", roundi((8 if compact else 11) * _scale))
	var ticket_col := VBoxContainer.new()
	ticket_col.add_theme_constant_override("separation", roundi(1 * _scale))
	ticket_margin.add_child(ticket_col)
	_text(ticket_col, "TOUR PASS   /   SAMPLE ITINERARY", 11, Color("#62523E"), "TicketHeading")
	var chosen: Dictionary = _selected_stop()
	_text(ticket_col, str(chosen["label"]), 25 if mobile else 29, Color("#27312D"), "TicketDestination")
	_text(ticket_col, "%s   /   %s   /   VENUE TBC" % [chosen["date"], chosen["type"]], 12, Color("#514B41"), "TicketDetail")

	var rail := PanelContainer.new()
	rail.name = "ItineraryRail"
	rail.add_theme_stylebox_override("panel", _paper_surface(p))
	col.add_child(rail)
	var rail_row := HBoxContainer.new()
	rail_row.add_theme_constant_override("separation", roundi(7 * _scale))
	rail.add_child(rail_row)
	for item in ["01 / LOAD", "02 / DRIVE", "03 / SHOW"]:
		var step := Label.new()
		step.text = item
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step.add_theme_font_size_override("font_size", roundi(13 * _scale))
		step.add_theme_color_override("font_color", p["ink"])
		rail_row.add_child(step)

	var budget := HBoxContainer.new()
	budget.name = "TourBudgetReadouts"
	budget.add_theme_constant_override("separation", roundi(7 * _scale))
	col.add_child(budget)
	_readout(budget, "TRAVEL", "REVIEW", p)
	_readout(budget, "VAN", "READY" if van_ready else "CHECK", p)
	_readout(budget, "ROOM", "OPTIONAL", p)

	_status = _text(col, "SAMPLE DATA / PREVIEW DOES NOT BOOK OR SPEND", 12, p["muted"], "TourLabStatus")
	_button(col, "PREVIEW ROAD PLAN", false, preview_plan, p, "PrimaryAction", false, true)

func _texture(parent: Control, art: Texture2D) -> void:
	var texture := TextureRect.new()
	texture.texture = art
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture)
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _readout(parent: HBoxContainer, heading: String, value: String, p: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _paper_surface(p))
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", roundi(1 * _scale))
	panel.add_child(stack)
	_text(stack, heading, 11, p["muted"])
	_text(stack, value, 14, p["ink"])

func _paper_surface(p: Dictionary) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = p["surface"]
	s.border_color = p["border"]
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.set_content_margin_all(roundi(7 * _scale))
	return s

func _text(parent: Node, content: String, size: int, color: Color, id: String = "") -> Label:
	var label := Label.new()
	if not id.is_empty():
		label.name = id
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(size * _scale))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, title: String, selected: bool, handler: Callable, p: Dictionary,
	id: String = "", hardware: bool = false, primary: bool = false) -> Button:
	var button := Button.new()
	if not id.is_empty():
		button.name = id
	button.text = title
	button.custom_minimum_size.y = (47 if hardware else 49) * _scale
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	var fill: Color = (Color("#2A373A") if hardware else p["surface"])
	var edge: Color = (Color("#8C9A99") if hardware else p["border"])
	var ink: Color = (Color("#EDEDE5") if hardware else p["ink"])
	if selected or primary:
		fill = Color("#E4B160") if hardware or primary else p["panel"]
		edge = Color("#8E5D23") if hardware else p["accent"]
		ink = Color("#17252C")
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = edge
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 2
	normal.border_width_bottom = 3
	normal.set_corner_radius_all(2)
	normal.shadow_color = Color(0, 0, 0, 0.28)
	normal.shadow_size = 2
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = fill.lightened(0.12)
	hover.border_color = Color("#F3D5A1") if hardware else p["accent"]
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = fill.darkened(0.15)
	pressed.shadow_size = 0
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = fill.darkened(0.32)
	button.add_theme_stylebox_override("disabled", disabled)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#FFD27C")
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, ink)
	button.add_theme_color_override("font_disabled_color", Color("#7F8C89"))
	button.add_theme_font_size_override("font_size", roundi((14 if hardware else 15) * _scale))
	button.pressed.connect(handler)
	parent.add_child(button)
	return button
