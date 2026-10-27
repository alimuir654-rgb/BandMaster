extends Control
## Standalone large-scale inspection of Lab 05 layered textures and interactions.
const DIAL := preload("res://bandmaster_premium_dashboard_poc/studio_control.gd")
const BG := Color("#081116")
const INK := Color("#F3F0E8")
const MUTED := Color("#9CABAF")
const GOLD := Color("#EAB55D")
var report: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BG
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(1230, 935)
	scroll.add_child(canvas)
	_label(canvas, "LIVING THE DREAM  /  PREMIUM CONTROLS LAB 08", 28, 23, 1120, 24, 17, GOLD)
	_label(canvas, "PHOTOGRAPHIC HARDWARE / LIVE CONTROLS", 28, 55, 1160, 44, 27, INK)
	_label(canvas, "Drag vertically on knobs, slide faders, use mouse wheel or keyboard arrows. HOME and END set extremes.", 28, 112, 1150, 40, 15, MUTED)
	_widget(canvas, "horizontal", 29, 175, 643, 197, 64)
	_widget(canvas, "vertical", 691, 175, 196, 387, 72)
	_widget(canvas, "focus", 32, 427, 290, 286, 57)
	_widget(canvas, "buzz", 339, 427, 290, 286, 82)
	_widget(canvas, "meter", 915, 175, 196, 395, 68)
	_label(canvas, "HORIZONTAL FADER / READINESS", 38, 373, 530, 22, 14, MUTED)
	_label(canvas, "VERTICAL FADER / MORALE", 693, 578, 240, 22, 14, MUTED)
	_label(canvas, "CREATIVE FOCUS", 85, 725, 225, 25, 14, MUTED)
	_label(canvas, "VENUE BUZZ", 415, 725, 225, 25, 14, MUTED)
	_label(canvas, "SIGNAL LEVEL / HYPE", 922, 586, 260, 25, 14, MUTED)
	report = _label(canvas, "DEMO VALUES  /  No career saves affected", 31, 826, 1165, 32, 16, GOLD)

func _label(parent: Node, value: String, x: float, y: float, w: float, h: float, px: int, colour: Color) -> Label:
	var text := Label.new()
	text.text = value
	text.add_theme_color_override("font_color", colour)
	text.add_theme_font_size_override("font_size", px)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(text)
	text.position = Vector2(x, y)
	text.size = Vector2(w, h)
	return text

func _widget(parent: Node, kind: String, x: float, y: float, w: float, h: float, initial: float) -> void:
	var control := Control.new()
	control.set_script(DIAL)
	control.set("control_kind", kind)
	control.set("level", initial)
	control.set("read_only", kind == "meter")
	control.set("highlight", GOLD)
	parent.add_child(control)
	control.position = Vector2(x, y)
	control.size = Vector2(w, h)
	control.connect("level_changed", func(level: float) -> void:
		if is_instance_valid(report):
			report.text = "%s  /  %d" % [kind.to_upper(), int(level)]
	)
