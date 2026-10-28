extends TextureButton
## S03 source-photographed Lab07 sampler pad, with an independent physical
## label insert. The original Lab07 photo has "JAM" printed into the image:
## without an opaque inset, dynamic RIFF/LYRIC/FORM labels ghost and collide.
signal pad_chosen(id: String)
const ART := "res://bandmaster_premium_controls_lab/assets/pad_studio_"
@export var choice_id: String = ""
@export var caption: String = ""
var selected: bool = false
var _nameplate: Panel
var _caption: Label

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_nameplate = Panel.new()
	_nameplate.name = "PhysicalCaptionInsert"
	_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nameplate)
	_caption = Label.new()
	_caption.name = "NativePadCaption"
	_caption.text = caption
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_color_override("font_color", Color("#FFF5E4"))
	_caption.add_theme_constant_override("outline_size", 1)
	_caption.add_theme_color_override("font_outline_color", Color("#101719"))
	_nameplate.add_child(_caption)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout_insert)
	resized.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	pressed.connect(_on_pressed)
	_refresh()
	call_deferred("_layout_insert")

func set_chosen(value: bool) -> void:
	selected = value
	if is_inside_tree():
		_refresh()

func _tex(state: String) -> Texture2D:
	var t: Texture2D = load(ART + state + ".png") as Texture2D
	if t == null:
		push_error("S03 missing Lab07 sampler state: " + state)
	return t

func _layout_insert() -> void:
	if _nameplate == null:
		return
	_nameplate.position = Vector2(size.x * 0.17, size.y * 0.28)
	_nameplate.size = Vector2(size.x * 0.66, size.y * 0.44)
	_caption.add_theme_font_size_override("font_size", 12 if size.x < 125.0 else 15)

func _refresh() -> void:
	texture_normal = _tex("active" if selected else "idle")
	texture_hover = _tex("active" if selected else "hover")
	texture_pressed = _tex("pressed")
	texture_disabled = _tex("disabled")
	if _nameplate != null:
		var inset := StyleBoxFlat.new()
		inset.bg_color = Color("#61281F") if selected else Color("#171719")
		inset.border_color = Color("#D7A36D") if selected else Color("#796A5B")
		inset.set_border_width_all(1)
		inset.set_corner_radius_all(6)
		_nameplate.add_theme_stylebox_override("panel", inset)
	queue_redraw()

func _on_pressed() -> void:
	if not disabled:
		pad_chosen.emit(choice_id)

func _draw() -> void:
	if has_focus() and not disabled:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#F3C16B"), false, 3.0)
