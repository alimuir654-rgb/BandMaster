extends Control
## Studio Hardware 07 — standalone image-front component validation.
## No career model imports, no save reads/writes, no network.

const COLORS := {
	"studio": Color("#E9B35A"),
	"electronic": Color("#65DDD4"),
	"punk": Color("#E0E85B")
}
const BG := Color("#0B1116")
const PANEL := Color("#152027")
const TEXT := Color("#F1F0E8")
const MUTED := Color("#9DACB5")
const TEXTURE_DIR := "res://bandmaster_premium_controls_lab/assets/"
const CONTROL_NAMES := ["transport", "pad", "channel"]

var theme_name := "studio"
var compact := false
var controls: Dictionary = {}
var focus_frames: Dictionary = {}
var cards: Array[Panel] = []
var headings: Array[Label] = []
var notes: Array[Label] = []
var canvas: Control
var viewport_scroll: ScrollContainer
var status: Label
var theme_picker: OptionButton
var disable_toggle: CheckButton
var compact_toggle: CheckButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = BG
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_scroll = ScrollContainer.new()
	viewport_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(viewport_scroll)
	viewport_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas = Control.new()
	viewport_scroll.add_child(canvas)
	_make_interface()
	resized.connect(_layout)
	_layout()

func _text(value: String, font_size: int, colour: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label)
	return label

func _make_interface() -> void:
	var eyebrow := _text("LIVING THE DREAM    /    COMPONENT PROOF 07", 14, COLORS[theme_name])
	eyebrow.name = "Eyebrow"
	var title := _text("STUDIO CONTROL SURFACES", 27)
	title.name = "Title"
	var intro := _text("Photographic face artwork, native Godot input, separate genre and state textures.", 14, MUTED)
	intro.name = "Intro"
	theme_picker = OptionButton.new()
	theme_picker.add_item("Studio / amber")
	theme_picker.add_item("Electronic / cyan")
	theme_picker.add_item("Punk / acid")
	theme_picker.custom_minimum_size.y = 42
	theme_picker.item_selected.connect(_theme_changed)
	canvas.add_child(theme_picker)
	disable_toggle = CheckButton.new()
	disable_toggle.text = "Disable all"
	disable_toggle.toggled.connect(_disable_changed)
	canvas.add_child(disable_toggle)
	compact_toggle = CheckButton.new()
	compact_toggle.text = "Compact scale"
	compact_toggle.toggled.connect(func(value: bool) -> void:
		compact = value
		_layout()
	)
	canvas.add_child(compact_toggle)

	for index in range(CONTROL_NAMES.size()):
		var name: String = CONTROL_NAMES[index]
		var card := Panel.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := StyleBoxFlat.new()
		box.bg_color = PANEL
		box.border_color = Color("#35454C")
		box.set_border_width_all(1)
		box.set_corner_radius_all(11)
		card.add_theme_stylebox_override("panel", box)
		canvas.add_child(card)
		cards.append(card)
		var heading := _text(["01  /  TRANSPORT", "02  /  PERFORMANCE PAD", "03  /  CHANNEL BANK"][index], 15, COLORS[theme_name])
		headings.append(heading)
		var note := _text(["PLAY / EXECUTE", "JAM / TOGGLE", "GUITAR / SELECT"][index], 15)
		notes.append(note)
		var focus_frame := Panel.new()
		focus_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var focus_style := StyleBoxFlat.new()
		focus_style.bg_color = Color.TRANSPARENT
		focus_style.border_color = COLORS[theme_name]
		focus_style.set_border_width_all(2)
		focus_style.set_corner_radius_all(6)
		focus_frame.add_theme_stylebox_override("panel", focus_style)
		focus_frame.hide()
		canvas.add_child(focus_frame)
		focus_frames[name] = focus_frame
		var button := TextureButton.new()
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "Toggle " + name + " hardware control"
		button.pressed.connect(_control_pressed.bind(name))
		button.button_down.connect(_set_down_texture.bind(name, true))
		button.button_up.connect(_set_down_texture.bind(name, false))
		button.focus_entered.connect(focus_frame.show)
		button.focus_exited.connect(focus_frame.hide)
		canvas.add_child(button)
		controls[name] = button

	status = _text("READY  /  Click to latch. Hover, keyboard focus and disabled states available.", 14, MUTED)
	status.name = "Status"
	_apply_textures()

func _control_pressed(name: String) -> void:
	var button: TextureButton = controls[name]
	status.text = "%s  /  %s" % [name.to_upper(), "LATCHED ON" if button.button_pressed else "OFF"]

func _apply_textures() -> void:
	for name in CONTROL_NAMES:
		var button: TextureButton = controls[name]
		var prefix: String = TEXTURE_DIR + str(name) + "_" + theme_name + "_"
		button.texture_normal = load(prefix + "idle.png")
		button.texture_hover = load(prefix + "hover.png")
		# Toggle mode uses texture_pressed for the entire latched interval.
		# This prevents the old flash-on-release bug.
		button.texture_pressed = load(prefix + "active.png")
		button.texture_disabled = load(prefix + "disabled.png")
		# Godot renders normal if texture_focused is absent; focus is indicated
		# by native keyboard navigation and tooltip, not a destructive overlay.

func _set_down_texture(name: String, down: bool) -> void:
	var button: TextureButton = controls[name]
	var state := "pressed" if down else "active"
	button.texture_pressed = load(TEXTURE_DIR + name + "_" + theme_name + "_" + state + ".png")

func _theme_changed(index: int) -> void:
	theme_name = ["studio", "electronic", "punk"][index]
	_apply_textures()
	var eyebrow: Label = canvas.get_node("Eyebrow") as Label
	eyebrow.add_theme_color_override("font_color", COLORS[theme_name])
	for heading in headings:
		heading.add_theme_color_override("font_color", COLORS[theme_name])
	for frame in focus_frames.values():
		var style: StyleBoxFlat = frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = COLORS[theme_name]
		frame.add_theme_stylebox_override("panel", style)
	status.text = "THEME  /  " + theme_name.to_upper()

func _disable_changed(value: bool) -> void:
	for name in CONTROL_NAMES:
		var button: TextureButton = controls[name]
		button.disabled = value
	status.text = "CONTROLS  /  DISABLED" if value else "CONTROLS  /  ENABLED"

func _layout() -> void:
	if not is_instance_valid(canvas):
		return
	var w := maxf(size.x, 320.0)
	var desktop := w >= 980.0
	var margin := 24.0
	canvas.custom_minimum_size = Vector2(w, 720 if desktop else 1170)
	var eyebrow: Label = canvas.get_node("Eyebrow") as Label
	var title: Label = canvas.get_node("Title") as Label
	var intro: Label = canvas.get_node("Intro") as Label
	eyebrow.position = Vector2(margin, 18)
	eyebrow.size = Vector2(w - 2*margin, 22)
	title.add_theme_font_size_override("font_size", 21 if w < 600 else 27)
	title.position = Vector2(margin, 43)
	title.size = Vector2(w - 2*margin, 39)
	intro.position = Vector2(margin, 84)
	intro.size = Vector2(w - 2*margin, 37)
	var row_y := 125.0
	var opts := maxf(120, minf(245, w - 2*margin))
	theme_picker.position = Vector2(margin, row_y)
	theme_picker.size = Vector2(opts, 43)
	disable_toggle.position = Vector2(margin + opts + 12 if desktop else margin, row_y if desktop else row_y + 50)
	compact_toggle.position = Vector2(margin + opts + 172 if desktop else margin + 155, row_y if desktop else row_y + 50)
	var panel_top := 194.0 if desktop else 249.0
	var panel_gap := 16.0
	var panel_height := 426.0 if desktop else 344.0
	var card_w := (w - 2 * margin - 2 * panel_gap) / 3.0 if desktop else w - 2 * margin
	var ratios := [395.0/215.0, 273.0/221.0, 483.0/213.0]
	var pref_w := [350.0, 225.0, 340.0]
	for i in CONTROL_NAMES.size():
		var name: String = CONTROL_NAMES[i]
		var px := margin + i * (card_w + panel_gap) if desktop else margin
		var py := panel_top if desktop else panel_top + i * (panel_height + 14)
		cards[i].position = Vector2(px, py)
		cards[i].size = Vector2(card_w, panel_height)
		headings[i].position = Vector2(px + 17, py + 22)
		headings[i].size = Vector2(card_w - 34, 25)
		var face_w := minf(pref_w[i] * (0.78 if compact else 1.0), card_w - 30)
		var face_h: float = face_w / float(ratios[i])
		var button: TextureButton = controls[name]
		button.position = Vector2(px + (card_w - face_w)/2, py + (62 if desktop else 60))
		button.size = Vector2(face_w, face_h)
		var frame: Panel = focus_frames[name]
		frame.position = button.position - Vector2(3, 3)
		frame.size = button.size + Vector2(6, 6)
		button.custom_minimum_size = Vector2.ZERO
		notes[i].position = Vector2(px + 17, py + panel_height - 77)
		notes[i].size = Vector2(card_w - 34, 29)
	status.position = Vector2(margin, panel_top + panel_height + 25 if desktop else panel_top + 3 * (panel_height + 14))
	status.size = Vector2(w - 2*margin, 50)
	canvas.custom_minimum_size.y = maxf(720, status.position.y + 90)
