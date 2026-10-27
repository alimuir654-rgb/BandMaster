extends TextureButton
## S04 five-state purpose-made printed ticket / rugged seal / booking stamp.
## The imported SVG is original authored art. All mutable copy stays native.
signal ticket_chosen(choice_id: String)
const ROOT := "res://Art/UI/TourCraft/"
const FONT := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
@export var family: String = "route"
@export var choice_id: String = ""
@export var caption: String = ""
var chosen: bool = false
var _caption: Label

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_caption = Label.new()
	_caption.name = "NativeTicketCaption"
	_caption.text = caption
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_color_override("font_color", Color("#26393B"))
	_caption.add_theme_color_override("font_disabled_color", Color("#414C4D"))
	_caption.add_theme_constant_override("outline_size", 1)
	_caption.add_theme_color_override("font_outline_color", Color("#F9F1DF"))
	var font: Font = load(FONT) as Font if ResourceLoader.exists(FONT) else null
	if font != null:
		_caption.add_theme_font_override("font", font)
	add_child(_caption)
	resized.connect(_layout_caption)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	pressed.connect(_on_pressed)
	_refresh()
	call_deferred("_layout_caption")

func _texture(state: String) -> Texture2D:
	var path: String = ROOT + family + "_" + state + ".svg"
	var texture: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	if texture == null:
		push_error("S04 missing original ticket texture: " + path)
	return texture

func _layout_caption() -> void:
	if _caption == null:
		return
	var inset: float = 16.0 if size.x < 150.0 else 34.0
	_caption.position = Vector2(inset, 4)
	_caption.size = Vector2(maxf(1.0, size.x - inset - 14.0), maxf(1.0, size.y - 8.0))
	_caption.add_theme_font_size_override("font_size", 13 if size.x < 135.0 else (15 if size.x < 340.0 else 17))

func set_chosen(value: bool) -> void:
	chosen = value
	if is_inside_tree():
		_refresh()

func _refresh() -> void:
	texture_normal = _texture("selected" if chosen else "idle")
	texture_hover = _texture("selected" if chosen else "hover")
	texture_pressed = _texture("pressed")
	texture_disabled = _texture("disabled")
	queue_redraw()

func _on_pressed() -> void:
	if not disabled:
		ticket_chosen.emit(choice_id)

func _draw() -> void:
	if has_focus() and not disabled:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#E3B75F"), false, 3.0)
