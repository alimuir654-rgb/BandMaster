extends Control
## Self-contained premium interface proof. All displayed career data is sample data.
## Does not import CareerHub, read user://, or modify live saves.
const CONTROL_SCRIPT := preload("res://bandmaster_premium_dashboard_poc/studio_control.gd")
const ASSET_DIR := "res://bandmaster_premium_dashboard_poc/assets/"
const BG := Color("#081116")
const PANEL := Color("#141D22")
const BORDER := Color("#34444A")
const WHITE := Color("#F4F0E7")
const MUTED := Color("#98ACB1")
const THEMES := {"studio": Color("#EAB55D"), "electronic": Color("#65DED3"), "punk": Color("#DCE95F")}
const NAV_ITEMS := ["OVERVIEW", "BAND", "SONGS", "GIGS", "JOURNAL"]

var theme_name: String = "studio"
var active_tab: String = "OVERVIEW"
var band_values: Dictionary = {"vertical": 72.0, "horizontal": 64.0, "focus": 57.0, "buzz": 82.0, "meter": 68.0}
var compact: bool = false
var jam_armed: bool = false
var canvas_root: Control
var canvas_area: Control
var scroll_view: ScrollContainer
var status: Label
var scene_buttons: Array[TextureButton] = []
var nav_buttons: Dictionary = {}
var controls: Dictionary = {}
var header_theme: Label
var readiness_readout: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resize)
	_render()

func _on_resize() -> void:
	var new_compact: bool = size.x < 900.0
	if new_compact != compact:
		call_deferred("_render")
	elif is_instance_valid(scroll_view):
		_apply_scale()

func _position(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)

func _label(parent: Node, value: String, x: float, y: float, w: float, h: float, px: int = 15, colour: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", px)
	parent.add_child(label)
	_position(label, x, y, w, h)
	return label

func _panel(parent: Node, x: float, y: float, w: float, h: float, fill: Color = PANEL) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	_position(panel, x, y, w, h)
	return panel

func _render() -> void:
	compact = size.x < 900.0
	scene_buttons.clear()
	nav_buttons.clear()
	controls.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := ColorRect.new()
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_view = ScrollContainer.new()
	scroll_view.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll_view)
	scroll_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_area = Control.new()
	scroll_view.add_child(canvas_area)
	canvas_root = Control.new()
	canvas_area.add_child(canvas_root)
	if compact:
		_build_compact()
	else:
		_build_desktop()
	_apply_scale()

func _apply_scale() -> void:
	if not is_instance_valid(canvas_root):
		return
	var design_w: float = 390.0 if compact else 1280.0
	var design_h: float = 1900.0 if compact else 790.0
	var scale_factor: float = minf(size.x / design_w, 1.40) if compact else minf(size.x / design_w, 1.0)
	canvas_area.custom_minimum_size = Vector2(design_w * scale_factor, design_h * scale_factor)
	canvas_root.size = Vector2(design_w, design_h)
	canvas_root.scale = Vector2(scale_factor, scale_factor)

func _control(kind: String, x: float, y: float, w: float, h: float) -> Control:
	var widget := Control.new()
	widget.set_script(CONTROL_SCRIPT)
	widget.set("control_kind", kind)
	widget.set("level", float(band_values.get(kind, 50.0)))
	widget.set("read_only", kind == "meter")
	widget.set("highlight", THEMES[theme_name])
	canvas_root.add_child(widget)
	_position(widget, x, y, w, h)
	widget.connect("level_changed", _value_changed.bind(kind))
	controls[kind] = widget
	return widget

func _value_changed(new_value: float, kind: String) -> void:
	band_values[kind] = new_value
	if kind == "horizontal" and is_instance_valid(readiness_readout):
		readiness_readout.text = "%d / 100  ·  %s" % [int(new_value), "READY" if new_value >= 75.0 else "NEEDS REHEARSAL"]
	if is_instance_valid(status):
		status.text = "%s  /  %d     ·     DEMO VALUES ONLY" % [kind.to_upper(), int(new_value)]

func _hardware_button(kind: String, x: float, y: float, w: float, h: float, toggle: bool, selected: bool = false) -> TextureButton:
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.toggle_mode = toggle
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	canvas_root.add_child(button)
	_position(button, x, y, w, h)
	var prefix: String = ASSET_DIR + kind + "_" + theme_name + "_"
	button.texture_normal = load(prefix + ("active.png" if selected else "idle.png"))
	button.texture_hover = load(prefix + ("active.png" if selected else "hover.png"))
	button.texture_pressed = load(prefix + "active.png") if toggle else load(prefix + "pressed.png")
	button.texture_disabled = load(prefix + "disabled.png")
	button.button_pressed = toggle and selected
	button.focus_entered.connect(func() -> void: button.modulate = Color(1.13, 1.13, 1.13))
	button.focus_exited.connect(func() -> void: button.modulate = Color.WHITE)
	scene_buttons.append(button)
	return button

func _nav_button(label_text: String, x: float, y: float, w: float, h: float) -> void:
	var selected: bool = label_text == active_tab
	var button := _hardware_button("nav", x, y, w, h, false, selected)
	button.tooltip_text = "Open " + label_text.to_lower()
	var caption := Label.new()
	caption.text = label_text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_color_override("font_color", WHITE)
	caption.add_theme_font_size_override("font_size", 13 if compact else 14)
	button.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.position.y = -6.0
	button.pressed.connect(func() -> void:
		if compact:
			_next_tab()
		else:
			active_tab = label_text
			_render()
			_message("CHANNEL / " + label_text + " SELECTED (PoC)")
	)
	nav_buttons[label_text] = button

func _message(value: String) -> void:
	if is_instance_valid(status):
		status.text = value

func _build_desktop() -> void:
	# Compact hardware rail: distinct from generic stacked rectangular buttons.
	_panel(canvas_root, 13, 13, 232, 752, Color("#111B21"))
	_label(canvas_root, "LIVING THE DREAM", 30, 31, 200, 28, 20, THEMES[theme_name])
	_label(canvas_root, "CAREER CHANNELS  /  01", 31, 66, 204, 20, 12, MUTED)
	for i in range(NAV_ITEMS.size()):
		_nav_button(str(NAV_ITEMS[i]), 25, 112 + i * 99, 207, 93)
	_label(canvas_root, "THEME", 30, 623, 76, 18, 12, MUTED)
	_theme_switch(27, 648, 202, 67)

	_label(canvas_root, "LIVING THE DREAM   /   YOUR CAREER", 264, 19, 650, 24, 13, THEMES[theme_name])
	_label(canvas_root, "THE LONG WEEKEND", 263, 49, 565, 52, 30)
	_label(canvas_root, "YEAR 01   /   WEEK 06   /   £1,240 CASH", 893, 68, 367, 30, 14, MUTED)

	_panel(canvas_root, 260, 118, 551, 245, Color("#19242B"))
	_label(canvas_root, "NEXT SHOW  /  FRIDAY 21:00", 282, 140, 430, 23, 14, THEMES[theme_name])
	_label(canvas_root, "THE EXCHANGE", 283, 170, 400, 42, 27)
	_label(canvas_root, "BRISTOL  ·  HEADLINE  ·  120 CAPACITY", 282, 217, 390, 25, 13, MUTED)
	_label(canvas_root, "One night. One chance to move up.", 282, 257, 230, 48, 15)
	var transport := _hardware_button("transport", 540, 224, 236, 127, false)
	transport.pressed.connect(func() -> void: _message("PLAN THE SHOW  /  INTERACTIVE PROTOTYPE ONLY"))
	_label(canvas_root, "PLAN THE SHOW", 284, 322, 240, 25, 16)

	_panel(canvas_root, 826, 118, 437, 245, Color("#152027"))
	_label(canvas_root, "SHOW READINESS", 846, 136, 323, 24, 15, THEMES[theme_name])
	_control("horizontal", 838, 161, 414, 126)
	readiness_readout = _label(canvas_root, "64 / 100  ·  NEEDS REHEARSAL", 847, 311, 390, 30, 15, MUTED)

	_panel(canvas_root, 260, 383, 664, 358, Color("#141D22"))
	_label(canvas_root, "THE BAND CONSOLE", 283, 398, 570, 26, 16, THEMES[theme_name])
	_control("vertical", 282, 446, 142, 276)
	_control("focus", 448, 449, 245, 244)
	_control("buzz", 692, 449, 212, 211)
	_label(canvas_root, "MORALE", 310, 715, 100, 18, 12, MUTED)
	_label(canvas_root, "CREATIVE FOCUS", 501, 693, 187, 20, 13, MUTED)
	_label(canvas_root, "VENUE BUZZ", 751, 692, 145, 20, 13, MUTED)

	_panel(canvas_root, 941, 383, 322, 358, Color("#141D22"))
	_label(canvas_root, "LIVE SIGNAL", 959, 397, 250, 25, 16, THEMES[theme_name])
	_control("meter", 954, 440, 136, 277)
	var pad := _hardware_button("pad", 1100, 470, 146, 119, true, jam_armed)
	pad.pressed.connect(func() -> void:
		jam_armed = pad.button_pressed
		_message("JAM SESSION  /  " + ("ARMED" if jam_armed else "DISARMED"))
	)
	_label(canvas_root, "JAM SESSION", 1103, 599, 148, 23, 15)
	_label(canvas_root, "Choose your next", 1103, 635, 150, 20, 12, MUTED)
	_label(canvas_root, "creative move", 1103, 655, 150, 20, 12, MUTED)
	status = _label(canvas_root, "PROOF OF CONCEPT  /  SAMPLE DATA  /  SAVES UNCHANGED", 262, 749, 1020, 22, 13, MUTED)

func _build_compact() -> void:
	_label(canvas_root, "LIVING THE DREAM", 16, 15, 340, 30, 22, THEMES[theme_name])
	_label(canvas_root, "THE LONG WEEKEND  /  YEAR 01 · WEEK 06", 16, 50, 363, 24, 14)
	_nav_button(active_tab, 16, 83, 234, 108)
	_label(canvas_root, "Tap channel to cycle", 257, 99, 125, 56, 12, MUTED)
	_theme_switch(260, 151, 110, 36)

	_panel(canvas_root, 13, 205, 364, 358, Color("#18252B"))
	_label(canvas_root, "NEXT SHOW  /  FRIDAY 21:00", 27, 224, 331, 24, 13, THEMES[theme_name])
	_label(canvas_root, "THE EXCHANGE", 27, 257, 338, 42, 29)
	_label(canvas_root, "BRISTOL · HEADLINE · 120 CAP", 27, 315, 330, 24, 13, MUTED)
	_label(canvas_root, "The road to your first headline gig.", 27, 352, 330, 47, 16)
	var transport := _hardware_button("transport", 43, 410, 305, 164, false)
	transport.pressed.connect(func() -> void: _message("PLAN THE SHOW / DEMO"))

	_panel(canvas_root, 13, 578, 364, 195)
	_label(canvas_root, "SHOW READINESS", 30, 592, 300, 25, 15, THEMES[theme_name])
	_control("horizontal", 28, 627, 335, 102)
	readiness_readout = _label(canvas_root, "64 / 100   ·   NEEDS REHEARSAL", 29, 740, 315, 21, 13, MUTED)

	_panel(canvas_root, 13, 788, 364, 527)
	_label(canvas_root, "BAND CONSOLE", 28, 806, 306, 26, 16, THEMES[theme_name])
	_control("vertical", 26, 848, 145, 284)
	_control("focus", 177, 848, 193, 190)
	_control("buzz", 177, 1050, 193, 193)
	_label(canvas_root, "MORALE", 49, 1150, 107, 20, 12, MUTED)
	_label(canvas_root, "CREATIVE FOCUS / VENUE BUZZ", 173, 1268, 192, 39, 12, MUTED)

	_panel(canvas_root, 13, 1330, 364, 505)
	_label(canvas_root, "LIVE SIGNAL", 29, 1348, 330, 26, 16, THEMES[theme_name])
	_control("meter", 30, 1390, 162, 321)
	var pad := _hardware_button("pad", 204, 1442, 158, 128, true, jam_armed)
	pad.pressed.connect(func() -> void:
		jam_armed = pad.button_pressed
		_message("JAM SESSION / " + ("ARMED" if jam_armed else "OFF"))
	)
	_label(canvas_root, "JAM SESSION", 207, 1593, 150, 25, 15)
	_label(canvas_root, "Band chemistry", 207, 1624, 153, 25, 13, MUTED)
	_label(canvas_root, "and stage energy", 207, 1647, 153, 25, 13, MUTED)
	status = _label(canvas_root, "SAMPLE DATA ONLY  /  SAVES UNCHANGED", 17, 1850, 355, 30, 12, MUTED)

func _next_tab() -> void:
	var current: int = NAV_ITEMS.find(active_tab)
	active_tab = str(NAV_ITEMS[(current + 1) % NAV_ITEMS.size()])
	_render()
	_message("CHANNEL / " + active_tab + " SELECTED")

func _theme_switch(x: float, y: float, w: float, h: float) -> void:
	var button := Button.new()
	button.text = "ACCENT / " + theme_name.to_upper()
	button.focus_mode = Control.FOCUS_ALL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1E3037")
	style.border_color = THEMES[theme_name]
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", WHITE)
	canvas_root.add_child(button)
	_position(button, x, y, w, h)
	button.pressed.connect(func() -> void:
		var names: Array[String] = ["studio", "electronic", "punk"]
		var next_index: int = (names.find(theme_name) + 1) % names.size()
		theme_name = names[next_index]
		_render()
	)
