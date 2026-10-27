extends Control
## User-reviewable separated input faders and read-only metering in a real console bay.
## Uses original Lab08 photographic hardware. All data is local demo state only.
const Fader = preload("res://Scripts/premium_photographic_fader.gd")
const Meter = preload("res://Scripts/premium_photographic_meter.gd")
const PHASES := ["day", "dusk", "night"]
const DAY := Color("#ECE7DA")
const DUSK := Color("#283941")
const NIGHT := Color("#0B1116")
var phase: String = "day"
var background: ColorRect
var rack: Panel
var input_bay: Panel
var output_bay: Panel
var heading: Label
var subhead: Label
var rack_title: Label
var rack_meta: Label
var horizontal_label: Label
var vertical_label: Label
var meter_label: Label
var horizontal_readout: Label
var vertical_readout: Label
var meter_readout: Label
var footer: Label
var horizontal: Control
var vertical: Control
var meter: Control
var phase_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background = ColorRect.new()
	background.name = "RigTimeBackdrop"
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heading = _label(self, "RigHeading", "LIVING THE DREAM", 27)
	subhead = _label(self, "RigSubheading", "INSTRUMENT CONSOLE  /  INPUTS + TELEMETRY", 15)
	for context in PHASES:
		var btn := Button.new()
		btn.name = "RigPhase" + context.capitalize()
		btn.text = context.to_upper()
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_ALL
		add_child(btn)
		btn.pressed.connect(func() -> void: set_phase(context))
		phase_buttons[context] = btn
	rack = Panel.new()
	rack.name = "PhotographicHardwareRack"
	rack.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(rack)
	var rail := ColorRect.new()
	rail.name = "RackAccentRail"
	rail.color = Color("#CDA665")
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rack.add_child(rail)
	rack_title = _label(rack, "RigTitle", "MIXER  /  CONTROL DECK", 18)
	rack_meta = _label(rack, "RigMeta", "02 INPUTS   /   01 MONITOR", 13)
	input_bay = _panel(rack, "FaderInputBay")
	output_bay = _panel(rack, "ReadOnlyMeterBay")
	horizontal_label = _label(rack, "HorizontalInputLabel", "01  /  PREP EFFORT  ·  INPUT", 15)
	vertical_label = _label(rack, "VerticalInputLabel", "MORALE SUPPORT  /  INPUT", 15)
	meter_label = _label(rack, "ReadOnlyStatLabel", "HYPE  /  METER", 15)
	horizontal_readout = _label(rack, "HorizontalInputValue", "", 16)
	vertical_readout = _label(rack, "VerticalInputValue", "", 16)
	meter_readout = _label(rack, "ReadOnlyStatValue", "", 16)
	footer = _label(rack, "RigStatus", "INPUTS: DRAG OR USE ARROW KEYS       MONITOR: GAME STATE ONLY", 13)
	horizontal = Fader.new()
	horizontal.name = "RigHorizontalInput"
	horizontal.orientation = "horizontal"
	horizontal.value = 50.0
	rack.add_child(horizontal)
	vertical = Fader.new()
	vertical.name = "RigVerticalInput"
	vertical.orientation = "vertical"
	vertical.value = 50.0
	rack.add_child(vertical)
	meter = Meter.new()
	meter.name = "RigReadOnlyHypeMeter"
	meter.reading = 68.0
	rack.add_child(meter)
	horizontal.value_changed.connect(func(_v: float) -> void: _refresh_readouts())
	vertical.value_changed.connect(func(_v: float) -> void: _refresh_readouts())
	resized.connect(_layout)
	set_phase("day")
	call_deferred("_layout")

func _label(parent: Node, n: String, text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = n
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _panel(parent: Node, n: String) -> Panel:
	var part := Panel.new()
	part.name = n
	part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(part)
	return part

func _surface(colour: Color, trim: Color, radius: int, shadow_alpha: float = 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.border_color = trim
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	if shadow_alpha > 0.0:
		box.shadow_color = Color(0, 0, 0, shadow_alpha)
		box.shadow_size = 10
		box.shadow_offset = Vector2(0, 4)
	return box

func set_phase(next: String) -> void:
	if not PHASES.has(next):
		return
	phase = next
	background.color = DAY if phase == "day" else (DUSK if phase == "dusk" else NIGHT)
	var ink: Color = Color("#172329") if phase == "day" else Color("#F1EEE8")
	heading.add_theme_color_override("font_color", ink)
	subhead.add_theme_color_override("font_color", ink)
	for context in PHASES:
		var active: bool = context == phase
		var btn: Button = phase_buttons[context]
		btn.button_pressed = active
		btn.disabled = active
		btn.modulate = Color.WHITE
		var surface := StyleBoxFlat.new()
		surface.bg_color = Color("#E6CA8C") if active and phase == "day" else (Color("#B88C52") if active else Color(0, 0, 0, 0))
		surface.set_corner_radius_all(4)
		for state in ["normal", "disabled", "hover"]:
			btn.add_theme_stylebox_override(state, surface)
		var btn_ink: Color = Color("#202B2E") if phase == "day" or active else Color("#F1EEE8")
		for state in ["font_color", "font_hover_color", "font_disabled_color"]:
			btn.add_theme_color_override(state, btn_ink)
	rack.add_theme_stylebox_override("panel",
		_surface(Color("#34424A") if phase == "day" else Color("#1A262E"), Color("#7C8D8E") if phase == "day" else Color("#56666C"), 12, 0.26))
	input_bay.add_theme_stylebox_override("panel", _surface(Color("#222F36"), Color("#51646B"), 8))
	output_bay.add_theme_stylebox_override("panel", _surface(Color("#222F36"), Color("#51646B"), 8))
	for label in [rack_title, rack_meta, horizontal_label, vertical_label, meter_label,
				  horizontal_readout, vertical_readout, meter_readout, footer]:
		label.add_theme_color_override("font_color", Color("#F1EEE8") if label != rack_meta and label != footer else Color("#B9C8C8"))
	_refresh_readouts()

func set_levels(h: float, v: float) -> void:
	horizontal.set_value_safe(h)
	vertical.set_value_safe(v)
	_refresh_readouts()

func set_stat_reading(stat: float) -> void:
	# This is a model-to-view API. No display/mouse action can call it.
	meter.set_reading(stat)
	_refresh_readouts()

func _refresh_readouts() -> void:
	if horizontal == null or vertical == null or meter == null:
		return
	horizontal_readout.text = "PREP EFFORT   %03d%%" % int(horizontal.value)
	vertical_readout.text = "SUPPORT EFFORT  %03d%%" % int(vertical.value)
	meter_readout.text = "HYPE    %03d%%" % int(meter.reading)

func _place(ctrl: Control, x: float, y: float, w: float, h: float) -> void:
	ctrl.position = Vector2(x, y)
	ctrl.size = Vector2(maxf(w, 1.0), maxf(h, 1.0))

func _layout() -> void:
	if rack == null or horizontal == null:
		return
	var w: float = size.x
	var h: float = size.y
	var px: float = float(DisplayServer.window_get_size().x) / maxf(get_viewport_rect().size.x, 1.0)
	px = maxf(px, 0.35)
	var title_font: int = int(ceil(22.0 / px))
	var body_font: int = int(ceil(15.0 / px))
	var label_font: int = int(ceil(13.0 / px))
	heading.add_theme_font_size_override("font_size", title_font)
	subhead.add_theme_font_size_override("font_size", body_font)
	# Labels are local to the scaled rig, so their dimensions are device pixels.
	for l in [rack_title, horizontal_label, vertical_label, meter_label, horizontal_readout, vertical_readout, meter_readout]:
		l.add_theme_font_size_override("font_size", 15)
	for l in [rack_meta, footer]:
		l.add_theme_font_size_override("font_size", 12)
	_place(heading, 22, 20, w - 44, title_font + 13)
	_place(subhead, 22, heading.position.y + heading.size.y + 4, w - 44, body_font + 9)
	var button_top: float = subhead.position.y + subhead.size.y + 7
	var button_h: float = maxf(46.0, 45.0 / px)
	for i in range(PHASES.size()):
		var btn: Button = phase_buttons[PHASES[i]]
		btn.add_theme_font_size_override("font_size", body_font)
		_place(btn, 22 + i * 94.0, button_top, 88.0, button_h)
	# Layout the mixer in *physical* pixels, then inverse-scale it once into
	# Godot's logical canvas. This keeps the enclosure full-size on phones and
	# landscape instead of shrinking the hardware to half the intended size.
	var physical_w: float = w * px
	var physical_h: float = h * px
	var rack_top: float = (button_top + button_h + 18.0) * px
	var rack_w: float = minf(physical_w - 24.0, 1140.0)
	var rack_h: float = maxf(450.0, physical_h - rack_top - 20.0)
	rack_h = minf(rack_h, 560.0 if physical_w >= 900.0 else 665.0)
	rack.scale = Vector2(1.0 / px, 1.0 / px)
	_place(rack, (w - rack_w / px) * 0.5, rack_top / px, rack_w, rack_h)
	var rail: ColorRect = rack.get_node("RackAccentRail")
	_place(rail, 14, 5, rack_w - 28, 3)
	_place(rack_title, 22, 18, rack_w - 44, body_font + 13)
	_place(rack_meta, 22, 45, rack_w - 44, label_font + 8)
	if physical_w < 900.0:
		footer.text = "SET EFFORT  /  HYPE: READ ONLY"
		var hbase_width: float = rack_w - 40.0
		_place(input_bay, 13, 76, rack_w - 26, 155.0)
		_place(horizontal_label, 23, 84, rack_w - 46, body_font + 7)
		_place(horizontal, 22, 113, hbase_width, hbase_width * 246.0 / 808.0)
		_place(horizontal_readout, 25, horizontal.position.y + horizontal.size.y + 3, rack_w - 50, body_font + 9)
		var second_y: float = horizontal_readout.position.y + horizontal_readout.size.y + 22.0
		var bay_gap: float = 10.0
		var bay_w: float = (rack_w - 34.0 - bay_gap) / 2.0
		var module_height: float = minf(285.0, rack_h - second_y - 58.0)
		_place(input_bay, 13, 76, rack_w - 26, maxf(154.0, second_y - 70.0))
		_place(output_bay, rack_w - 13 - bay_w, second_y, bay_w, module_height)
		var v_width: float = minf(bay_w - 20, maxf(108.0, (module_height - 75.0) * 362.0 / 708.0))
		var meter_width: float = minf(bay_w - 20, maxf(108.0, (module_height - 75.0) * 357.0 / 710.0))
		_place(vertical_label, 22, second_y + 9, bay_w - 12, body_font + 7)
		_place(meter_label, output_bay.position.x + 10, second_y + 9, bay_w - 16, body_font + 7)
		_place(vertical, 17 + (bay_w - v_width) * 0.5, second_y + 38, v_width, v_width * 708.0 / 362.0)
		_place(meter, output_bay.position.x + (bay_w - meter_width) * 0.5, second_y + 38, meter_width, meter_width * 710.0 / 357.0)
		_place(vertical_readout, 20, second_y + module_height - 32, bay_w - 12, body_font + 11)
		_place(meter_readout, output_bay.position.x + 10, second_y + module_height - 32, bay_w - 16, body_font + 11)
		# This second inset backs the left fader and mirrors the read-only meter bay.
		_place(input_bay, 13, 76, rack_w - 26, maxf(154.0, second_y - 70.0))
		var left_panel: Panel = rack.get_node_or_null("EnergyInputBay")
		if left_panel == null:
			left_panel = _panel(rack, "EnergyInputBay")
			left_panel.add_theme_stylebox_override("panel", _surface(Color("#222F36"), Color("#51646B"), 8))
			rack.move_child(left_panel, rack.get_children().find(horizontal_label))
		_place(left_panel, 13, second_y, bay_w, module_height)
		_place(footer, 24, second_y + module_height + 12, rack_w - 44, label_font + 12)
	else:
		footer.text = "INPUTS: DRAG OR USE ARROW KEYS       MONITOR: GAME STATE ONLY"
		var left_w: float = minf(638.0, rack_w - 464.0)
		var right_x: float = left_w + 63.0
		var meter_x: float = right_x + 218.0
		_place(input_bay, 18, 78, left_w + 22.0, 318.0)
		_place(output_bay, meter_x - 8.0, 78, 196.0, 398.0)
		_place(horizontal_label, 31, 94, left_w - 6.0, body_font + 11)
		var fader_w: float = left_w - 8.0
		_place(horizontal, 28, 136, fader_w, fader_w * 246.0 / 808.0)
		_place(horizontal_readout, 32, horizontal.position.y + horizontal.size.y + 12, fader_w, body_font + 12)
		_place(vertical_label, right_x, 94, 214.0, body_font + 11)
		_place(meter_label, meter_x, 94, 190.0, body_font + 11)
		var vertical_w: float = minf(185.0, maxf(115.0, (rack_h - 224.0) * 362.0 / 708.0))
		var meter_w: float = minf(184.0, maxf(115.0, (rack_h - 224.0) * 357.0 / 710.0))
		_place(vertical, right_x + 4, 132, vertical_w, vertical_w * 708.0 / 362.0)
		_place(meter, meter_x + 5, 132, meter_w, meter_w * 710.0 / 357.0)
		_place(vertical_readout, right_x, vertical.position.y + vertical.size.y + 12, 205, body_font + 12)
		_place(meter_readout, meter_x, meter.position.y + meter.size.y + 12, 196, body_font + 12)
		_place(footer, 30, rack_h - 48, left_w + 30, label_font + 20)
