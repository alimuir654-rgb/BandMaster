extends Control
## Owner control proof: ONE original Lab07 transport key, in a coherent DAY/DUSK/NIGHT rehearsal housing.
## All values local demonstrator state; no audio, career model or user:// writes.
const TransportKey = preload("res://Scripts/premium_transport_key.gd")
const PHASES: Array[String] = ["day", "dusk", "night"]
const FINISHES: Array[String] = ["studio", "electronic", "punk"]
const DAY: Color = Color("#ECE7DA")
const DUSK: Color = Color("#354147")
const NIGHT: Color = Color("#10151B")
var phase: String = "day"
var finish: String = "studio"
var background: ColorRect
var title: Label
var subtitle: Label
var rack: Panel
var module_title: Label
var module_subtitle: Label
var transport: TextureButton
var mode_display: Label
var explanation: Label
var notice: Label
var phase_buttons: Dictionary = {}
var finish_buttons: Dictionary = {}
var rack_rail: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background = ColorRect.new()
	background.name = "TransportTimeBackdrop"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title = _label(self, "TransportHeading", "Livin’ The Dream", 25)
	subtitle = _label(self, "TransportSubheading", "SONGWRITING  /  PREMIUM TRANSPORT PROOF", 14)
	for context in PHASES:
		var button := Button.new()
		button.name = "Transport" + context.capitalize()
		button.text = context.to_upper()
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		add_child(button)
		button.pressed.connect(func() -> void: set_phase(context))
		phase_buttons[context] = button
	rack = Panel.new()
	rack.name = "TransportPhotoRack"
	rack.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(rack)
	rack_rail = ColorRect.new()
	rack_rail.name = "TransportTrim"
	rack_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rack.add_child(rack_rail)
	module_title = _label(rack, "TransportModuleTitle", "REHEARSAL  /  TRANSPORT DECK", 17)
	module_subtitle = _label(rack, "TransportModuleSubtitle", "PHOTOGRAPHIC PLAY/EXECUTE KEY  ·  LAB 07", 13)
	transport = TransportKey.new()
	transport.name = "PhotographicTransportKey"
	transport.finish = finish
	transport.tooltip_text = "Arm or disarm the rehearsal transport preview"
	rack.add_child(transport)
	transport.transport_armed.connect(_on_transport_armed)
	mode_display = _label(rack, "TransportStateReadout", "", 18)
	explanation = _label(rack, "TransportRoleCopy", "PLAYER INPUT  /  NO AUDIO OR SAVE CHANGES", 13)
	notice = _label(rack, "TransportProofDisclaimer", "Review the physical surface. This lab never advances game time.", 12)
	for sample in FINISHES:
		var button := Button.new()
		button.name = "Finish" + sample.capitalize()
		button.text = sample.to_upper()
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		rack.add_child(button)
		button.pressed.connect(func() -> void: set_finish(sample))
		finish_buttons[sample] = button
	resized.connect(_layout)
	set_phase("day")
	set_finish("studio")
	call_deferred("_layout")

func _label(parent: Node, n: String, content: String, pt: int) -> Label:
	var node := Label.new()
	node.name = n
	node.text = content
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", pt)
	parent.add_child(node)
	return node

func _metal(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(13)
	box.shadow_color = Color(0, 0, 0, 0.24)
	box.shadow_size = 9
	box.shadow_offset = Vector2(0, 4)
	return box

func set_phase(next: String) -> void:
	if not PHASES.has(next):
		return
	phase = next
	background.color = DAY if phase == "day" else (DUSK if phase == "dusk" else NIGHT)
	var text_ink := Color("#1A272A") if phase == "day" else Color("#F2F0E9")
	for label in [title, subtitle]:
		label.add_theme_color_override("font_color", text_ink)
	var chrome: Color = Color("#303A40") if phase == "day" else Color("#1A252D")
	var edging: Color = Color("#A99A85") if phase == "day" else Color("#6A7478")
	rack.add_theme_stylebox_override("panel", _metal(chrome, edging))
	rack_rail.color = Color("#CBA263") if phase == "day" else Color("#B88D51")
	for label in [module_title, module_subtitle, mode_display, explanation, notice]:
		label.add_theme_color_override("font_color", Color("#F3EFE7") if label != notice and label != module_subtitle else Color("#BBC5C4"))
	for context in PHASES:
		var button: Button = phase_buttons[context]
		var selected: bool = context == phase
		button.button_pressed = selected
		button.disabled = selected
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color("#E6C486") if selected and phase == "day" else (Color("#B08A50") if selected else Color.TRANSPARENT)
		skin.set_corner_radius_all(4)
		for mode in ["normal", "disabled", "hover"]:
			button.add_theme_stylebox_override(mode, skin)
		var b_ink := Color("#1A272A") if phase == "day" or selected else Color("#F3EFE7")
		for role in ["font_color", "font_disabled_color", "font_hover_color"]:
			button.add_theme_color_override(role, b_ink)
	_refresh()

func set_finish(next: String) -> void:
	if not FINISHES.has(next):
		return
	finish = next
	transport.set_finish(next)
	for candidate in FINISHES:
		var button: Button = finish_buttons[candidate]
		var selected: bool = candidate == finish
		button.button_pressed = selected
		button.disabled = selected
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#9C865B") if selected else Color("#26343B")
		sb.border_color = Color("#D3AB64") if selected else Color("#607074")
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		button.add_theme_stylebox_override("normal", sb)
		button.add_theme_stylebox_override("disabled", sb)
	_refresh()

func set_locked(value: bool) -> void:
	transport.set_locked(value)
	_refresh()

func set_transport_armed(value: bool) -> void:
	transport.set_armed_from_model(value)
	_refresh()

func _on_transport_armed(_armed: bool) -> void:
	_refresh()

func _refresh() -> void:
	if mode_display == null or transport == null:
		return
	mode_display.text = "LOCKED  /  UNAVAILABLE" if transport.disabled else ("TRANSPORT  /  ARMED" if transport.button_pressed else "TRANSPORT  /  STANDBY")

func _place(control: Control, x: float, y: float, w: float, h: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(maxf(w, 1), maxf(h, 1))

func _layout() -> void:
	if rack == null or not is_instance_valid(transport):
		return
	var px: float = float(DisplayServer.window_get_size().x) / maxf(get_viewport_rect().size.x, 1.0)
	px = maxf(px, 0.35)
	var phys_w: float = size.x * px
	var phys_h: float = size.y * px
	var top_font: int = int(ceil(22.0 / px))
	var body_font: int = int(ceil(15.0 / px))
	title.add_theme_font_size_override("font_size", top_font)
	subtitle.add_theme_font_size_override("font_size", body_font)
	_place(title, 24.0 / px, 19.0 / px, (phys_w - 48.0) / px, 33.0 / px)
	_place(subtitle, 24.0 / px, 57.0 / px, (phys_w - 48.0) / px, 25.0 / px)
	var top_physical: float = 91.0
	for index in range(PHASES.size()):
		var btn: Button = phase_buttons[PHASES[index]]
		btn.add_theme_font_size_override("font_size", body_font)
		_place(btn, (24.0 + index * 94.0) / px, top_physical / px, 88.0 / px, 46.0 / px)
	var rack_top: float = top_physical + 66.0
	var rack_w: float = minf(phys_w - 24.0, 1030.0)
	var rack_h: float = minf(maxf(465.0, phys_h - rack_top - 26.0), 535.0)
	rack.scale = Vector2(1.0 / px, 1.0 / px)
	_place(rack, (phys_w - rack_w) / (2.0 * px), rack_top / px, rack_w, rack_h)
	_place(rack_rail, 16.0, 7.0, rack_w - 32.0, 3.0)
	_place(module_title, 22, 25, rack_w - 44, 28)
	_place(module_subtitle, 22, 55, rack_w - 44, 24)
	module_title.add_theme_font_size_override("font_size", 16)
	module_subtitle.add_theme_font_size_override("font_size", 13)
	var key_w: float = minf(rack_w - 42.0, 630.0)
	var key_h: float = key_w * 430.0 / 790.0
	var key_x: float = (rack_w - key_w) / 2.0
	_place(transport, key_x, 90, key_w, key_h)
	_place(mode_display, 25, 90 + key_h + 17, rack_w - 50, 26)
	mode_display.add_theme_font_size_override("font_size", 17)
	_place(explanation, 25, 90 + key_h + 49, rack_w - 50, 24)
	_place(notice, 25, rack_h - 41, rack_w - 50, 24)
	var controls_y: float = rack_h - 100
	var button_w: float = minf(114.0, (rack_w - 68.0) / 3.0)
	for index in range(FINISHES.size()):
		var btn: Button = finish_buttons[FINISHES[index]]
		btn.add_theme_font_size_override("font_size", 12)
		_place(btn, 20 + index * (button_w + 8.0), controls_y, button_w, 44.0)
