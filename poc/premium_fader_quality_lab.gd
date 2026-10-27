extends Control
## Review ONLY — original Lab08 photo plates, independent caps, light DAY / dusk / dark NIGHT.
const Fader = preload("res://Scripts/premium_photographic_fader.gd")
const PHASES := ["day", "dusk", "night"]
const DAY := Color("#ECE7DA")
const DUSK := Color("#283941")
const NIGHT := Color("#0B1116")
var phase: String = "day"
var horizontal: Control
var vertical: Control
var background: ColorRect
var heading: Label
var readout_h: Label
var readout_v: Label
var caption: Label
var phase_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background = ColorRect.new()
	background.name = "FaderTimeBackdrop"
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heading = _label("PremiumHeading", "LIVING THE DREAM / FADER WORKBENCH", 28)
	caption = _label("PremiumCaption", "LAB 08.4  /  PHOTOGRAPHIC METAL · MOVING CAPS", 15)
	readout_h = _label("HorizontalReadout", "", 17)
	readout_v = _label("VerticalReadout", "", 17)
	for context in PHASES:
		var btn := Button.new()
		btn.name = "FaderPhase" + context.capitalize()
		btn.text = context.to_upper()
		btn.custom_minimum_size = Vector2(80, 46)
		btn.focus_mode = Control.FOCUS_ALL
		btn.toggle_mode = true
		add_child(btn)
		btn.pressed.connect(func() -> void: set_phase(context))
		phase_buttons[context] = btn
	horizontal = Fader.new()
	horizontal.name = "PremiumHorizontalFader"
	horizontal.orientation = "horizontal"
	horizontal.value = 50.0
	add_child(horizontal)
	vertical = Fader.new()
	vertical.name = "PremiumVerticalFader"
	vertical.orientation = "vertical"
	vertical.value = 50.0
	add_child(vertical)
	horizontal.value_changed.connect(func(_level: float) -> void: _refresh_readouts())
	vertical.value_changed.connect(func(_level: float) -> void: _refresh_readouts())
	resized.connect(_layout)
	set_phase("day")
	call_deferred("_layout")

func _label(n: String, content: String, points: int) -> Label:
	var label := Label.new()
	label.name = n
	label.text = content
	label.add_theme_font_size_override("font_size", points)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(label)
	return label

func set_levels(h: float, v: float) -> void:
	horizontal.set_value_safe(h)
	vertical.set_value_safe(v)
	_refresh_readouts()

func set_phase(next: String) -> void:
	if not PHASES.has(next):
		return
	phase = next
	background.color = DAY if phase == "day" else (DUSK if phase == "dusk" else NIGHT)
	var ink: Color = Color("#172329") if phase == "day" else Color("#F3F0E8")
	for label in [heading, caption, readout_h, readout_v]:
		label.add_theme_color_override("font_color", ink)
	for context in PHASES:
		var btn: Button = phase_buttons[context]
		btn.button_pressed = context == phase
		btn.disabled = context == phase
		btn.modulate = Color.WHITE if context == phase else Color(0.8, 0.8, 0.8, 0.8)
	_refresh_readouts()

func _refresh_readouts() -> void:
	if horizontal == null or vertical == null:
		return
	readout_h.text = "READINESS  /  %03d%%" % int(horizontal.value)
	readout_v.text = "ENERGY  /  %03d%%" % int(vertical.value)

func _layout() -> void:
	if background == null or horizontal == null:
		return
	var w: float = size.x
	var h: float = size.y
	# BandMaster uses logical-to-physical stretching in the main Godot project.
	# Scale all review text and selectable phase targets to honest DEVICE pixels.
	var px: float = float(DisplayServer.window_get_size().x) / maxf(get_viewport_rect().size.x, 1.0)
	px = maxf(px, 0.35)
	var heading_px: int = int(ceil(22.0 / px))
	var copy_px: int = int(16.0 / px) + 1
	heading.add_theme_font_size_override("font_size", heading_px)
	for label in [caption, readout_h, readout_v]:
		label.add_theme_font_size_override("font_size", copy_px)
	heading.position = Vector2(24, 24)
	heading.size = Vector2(w - 48.0, float(heading_px + 13))
	caption.position = Vector2(24, heading.position.y + heading.size.y + 6.0)
	caption.size = Vector2(w - 48.0, float(copy_px + 16))
	var buttons_top: float = caption.position.y + caption.size.y + 12.0
	var target_height: float = maxf(46.0, 45.0 / px)
	for i in range(PHASES.size()):
		var btn: Button = phase_buttons[PHASES[i]]
		btn.add_theme_font_size_override("font_size", copy_px)
		btn.position = Vector2(24 + i * 95, buttons_top)
		btn.size = Vector2(89, target_height)
	var readout_top: float = buttons_top + target_height + 32.0
	readout_h.position = Vector2(24, readout_top)
	readout_h.size = Vector2(w - 48.0, float(copy_px + 16))
	if w < 900.0:
		var panel_w: float = minf(w - 36.0, 650.0)
		horizontal.size = Vector2(panel_w, panel_w * 246.0 / 808.0)
		horizontal.position = Vector2((w - panel_w) / 2.0, readout_h.position.y + readout_h.size.y + 12.0)
		readout_v.position = Vector2(24, horizontal.position.y + horizontal.size.y + 26.0)
		readout_v.size = Vector2(w - 48.0, float(copy_px + 16))
		var vertical_top: float = readout_v.position.y + readout_v.size.y + 12.0
		var room: float = h - vertical_top - 22.0
		var vertical_w: float = minf(190.0 if w < 500.0 else 260.0, maxf(110.0, room * 362.0 / 708.0))
		vertical.size = Vector2(vertical_w, vertical_w * 708.0 / 362.0)
		vertical.position = Vector2((w - vertical_w) / 2.0, vertical_top)
	else:
		var h_width: float = minf(820.0, (w - 360.0) * 0.89)
		horizontal.size = Vector2(h_width, h_width * 246.0 / 808.0)
		horizontal.position = Vector2(maxf(36.0, (w - h_width - 300.0) * 0.5), readout_h.position.y + readout_h.size.y + 12.0)
		readout_h.position.x = horizontal.position.x
		readout_h.size.x = h_width
		var vertical_top: float = horizontal.position.y
		var vertical_w: float = minf(245.0, maxf(110.0, (h - vertical_top - 30.0) * 362.0 / 708.0))
		vertical.size = Vector2(vertical_w, vertical_w * 708.0 / 362.0)
		vertical.position = Vector2(minf(w - vertical_w - 26.0, horizontal.position.x + h_width + 70.0), vertical_top)
		readout_v.position = Vector2(vertical.position.x, readout_h.position.y)
		readout_v.size = Vector2(vertical_w + 25.0, float(copy_px + 16))
