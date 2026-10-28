extends TextureButton
## Original photographed Lab control family: five independent physical PNG states.
## Live studio labels are native Godot text; chosen remains latched on hover.
signal key_chosen(id: String)
const ROOT := "res://bandmaster_premium_dashboard_poc/assets/"
const FONT := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
@export_enum("nav", "pad", "channel") var family: String = "nav"
@export var choice_id: String = ""
@export var caption: String = ""
var chosen: bool = false
var _caption: Label

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_caption = Label.new()
	_caption.name = "NativeStudioKeyCaption"
	_caption.text = caption
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_constant_override("outline_size",3)
	_caption.add_theme_color_override("font_outline_color",Color("#14232A"))
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
	var path: String = ROOT+family+"_studio_"+state+".png"
	var result: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	if result == null:
		push_error("Missing original photographed studio key "+path)
	return result

func _layout_caption() -> void:
	if _caption == null:
		return
	var inset: float = 9.0 if size.x<150.0 else 18.0
	_caption.position = Vector2(inset,3)
	_caption.size = Vector2(maxf(1.0,size.x-inset*2.0),maxf(1.0,size.y-6.0))
	_caption.add_theme_font_size_override("font_size",14 if size.x<145.0 else (17 if size.x<340.0 else 20))
	_caption.add_theme_color_override("font_color",Color("#F8F0DB"))
	_caption.add_theme_color_override("font_disabled_color",Color("#C9C7BD"))

func set_chosen(value: bool) -> void:
	chosen = value
	if is_inside_tree():
		_refresh()

func _refresh() -> void:
	texture_normal = _texture("active" if chosen else "idle")
	texture_hover = _texture("active" if chosen else "hover")
	texture_pressed = _texture("pressed")
	texture_disabled = _texture("disabled")
	queue_redraw()

func _on_pressed() -> void:
	if not disabled:
		key_chosen.emit(choice_id)

func _draw() -> void:
	if has_focus() and not disabled:
		draw_rect(Rect2(Vector2.ZERO,size),Color("#F6BF67"),false,3.0)
