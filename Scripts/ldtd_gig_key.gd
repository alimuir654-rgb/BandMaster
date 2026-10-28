extends TextureButton
## Original five-state physical showboard hardware; live text is always native.
signal key_chosen(choice_id: String)
const ROOT := "res://Art/UI/GigCraft/"
const FONT := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
@export var family: String = "cue"
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
	_caption.name = "NativeShowKeyCaption"
	_caption.text = caption
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_constant_override("outline_size",2)
	_caption.add_theme_color_override("font_outline_color",Color("#172329"))
	var font: Font = load(FONT) as Font if ResourceLoader.exists(FONT) else null
	if font != null:
		_caption.add_theme_font_override("font",font)
	add_child(_caption)
	resized.connect(_layout_caption)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	pressed.connect(_on_pressed)
	_refresh()
	call_deferred("_layout_caption")

func _texture(state: String) -> Texture2D:
	var path: String = ROOT+family+"_"+state+".svg"
	var result: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	if result == null:
		push_error("Missing original S05 show key: "+path)
	return result

func _layout_caption() -> void:
	if _caption == null:
		return
	var inset: float = 8.0 if size.x < 140.0 else 17.0
	_caption.position = Vector2(inset,3)
	_caption.size = Vector2(maxf(1.0,size.x-inset*2.0),maxf(1.0,size.y-6.0))
	_caption.add_theme_font_size_override("font_size",13 if size.x<115.0 else (16 if size.x<330.0 else 20))
	_caption.add_theme_color_override("font_color",Color("#F8F1E1") if family in ["go","hold","encore"] else Color("#F3E7CE"))
	_caption.add_theme_color_override("font_disabled_color",Color("#D6C9B4"))

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
		key_chosen.emit(choice_id)

func _draw() -> void:
	if has_focus() and not disabled:
		draw_rect(Rect2(Vector2.ZERO,size),Color("#F4C75B"),false,3.0)
