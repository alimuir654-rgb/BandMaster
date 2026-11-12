extends Control
## Independent music-hardware control lab. No career state, no external assets.
## Each face is an actual ImageTexture so artwork can later replace it.
const BG := Color("#0B1116")
const TEXT := Color("#F0F3F0")
const MUTED := Color("#9AADB6")
const GENRES := {
	"Indie": Color("#E5B566"),
	"Electronic": Color("#65E6DE"),
	"Punk": Color("#D9EA55"),
	"Metal": Color("#F0805C"),
	"Pop": Color("#F38FC2"),
	"Jazz": Color("#C8B27D")
}
var accent := Color("#E5B566")
var output: Label
var bank: VBoxContainer
var toggles: Array[BaseButton] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = BG
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var root := _column(margin, 20)
	_label(root, "LIVING THE DREAM  /  CONTROL LAB", 15, accent)
	_label(root, "MUSIC HARDWARE BUTTON EXPERIMENTS", 27)
	_label(root, "Three reusable interaction families. Every face is a generated image texture, not a StyleBox skin.", 15, MUTED)
	var chooser := OptionButton.new()
	chooser.custom_minimum_size.y = 48
	for genre in GENRES.keys():
		chooser.add_item(str(genre))
	chooser.item_selected.connect(func(index: int) -> void:
		accent = GENRES[chooser.get_item_text(index)]
		_rebuild_bank()
	)
	root.add_child(chooser)
	bank = _column(root, 20)
	_rebuild_bank()
	output = _label(root, "Press, hover, tab-focus and toggle controls to compare their behaviour.", 14, MUTED)

func _column(parent: Node, spacing: int = 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", spacing)
	parent.add_child(v)
	return v

func _label(parent: Node, text: String, font_size: int, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l

func _rebuild_bank() -> void:
	for child in bank.get_children():
		bank.remove_child(child)
		child.queue_free()
	toggles.clear()
	_section("01  /  TRANSPORT", "Main career actions: raised, metal-faced, positive mechanical travel.")
	_texture_control(bank, "▶  PLAN THE SHOW", "transport", false)
	_section("02  /  PERFORMANCE PAD", "Scene choices: illuminated silicone pads with clear on/off feedback.")
	var pad := _texture_control(bank, "REHEARSE", "pad", true)
	pad.button_pressed = true
	_texture_control(bank, "WRITE A SONG", "pad", true)
	_section("03  /  CHANNEL SELECTOR", "Navigation: narrow channel controls, active strip and status LED.")
	for item in ["OVERVIEW", "BAND", "SONGS"]:
		var ch := _texture_control(bank, item, "channel", true)
		if item == "OVERVIEW":
			ch.button_pressed = true
	_section("04  /  SIGNAL LEVELS", "True segmented meters, rather than decorative standard progress bars.")
	_meter(bank, "MORALE  /  72", 72)
	_meter(bank, "READINESS  /  64", 64)

func _section(title: String, description: String) -> void:
	_label(bank, title, 18, accent)
	_label(bank, description, 14, MUTED)

func _texture_control(parent: Node, label_text: String, kind: String, toggle: bool) -> TextureButton:
	var b := TextureButton.new()
	var height := 66 if kind == "transport" else 58
	b.custom_minimum_size = Vector2(260, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.texture_normal = _face(kind, height, 0)
	b.texture_hover = _face(kind, height, 1)
	b.texture_pressed = _face(kind, height, 2)
	b.texture_disabled = _face(kind, height, 3)
	b.ignore_texture_size = true
	b.toggle_mode = toggle
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = label_text
	parent.add_child(b)
	var caption := Label.new()
	caption.text = label_text
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 17)
	caption.add_theme_color_override("font_color", Color("#071014") if kind == "transport" else TEXT)
	b.add_child(caption)
	var led := ColorRect.new()
	led.color = accent
	led.mouse_filter = Control.MOUSE_FILTER_IGNORE
	led.position = Vector2(14, 20)
	led.size = Vector2(5, 17)
	b.add_child(led)
	b.pressed.connect(func() -> void:
		_report(label_text + ("  /  ON" if b.button_pressed else "  /  TRIGGERED"))
	)
	return b

func _face(kind: String, h: int, state: int) -> ImageTexture:
	var width := 340
	var image := Image.create(width, h, false, Image.FORMAT_RGBA8)
	var top := Color("#52656C")
	var bottom := Color("#19232B")
	if kind == "transport":
		top = accent.lightened(0.25)
		bottom = accent.darkened(0.26)
	elif kind == "pad":
		top = Color("#46505C")
		bottom = Color("#1B2632")
	else:
		top = Color("#40545B")
		bottom = Color("#162128")
	if state == 1:
		top = top.lightened(0.15)
		bottom = bottom.lightened(0.10)
	elif state == 2:
		top = top.darkened(0.25)
		bottom = bottom.darkened(0.18)
	elif state == 3:
		top = top.darkened(0.42)
		bottom = bottom.darkened(0.32)
	for y in range(h):
		var t := float(y) / float(h)
		var base := top.lerp(bottom, t)
		for x in range(width):
			var rim := x < 4 or x >= width - 4 or y < 4 or y >= h - 4
			var engraving := (kind == "channel" and x > 8 and x < 12)
			var inset := x >= 6 and x < width - 6 and y >= 6 and y < h - 6
			var c := base
			if rim:
				c = Color("#070C11")
			elif engraving:
				c = accent
			elif not inset:
				c = base.darkened(0.24)
			elif y == 6:
				c = base.lightened(0.30)
			elif y == h - 7:
				c = base.darkened(0.33)
			image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)

func _meter(parent: Node, label_text: String, level: int) -> void:
	_label(parent, label_text, 14, TEXT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)
	for i in range(20):
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(12, 19)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lit := i * 5 < level
		segment.color = (accent if i < 14 else Color("#F46B64")) if lit else Color("#26363C")
		row.add_child(segment)

func _report(message: String) -> void:
	if is_instance_valid(output):
		output.text = message
