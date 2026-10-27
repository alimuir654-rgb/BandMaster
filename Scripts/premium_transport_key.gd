extends TextureButton
## Livin' The Dream: original Lab07 photographed PLAY/EXECUTE transport.
## One control family, with five genuine source textures per finish.
## Emits user intent only. No saving, economy, or audio playback.
signal transport_armed(armed: bool)

const TEXTURE_DIR: String = "res://bandmaster_premium_controls_lab/assets/"
const FINISHES: Array[String] = ["studio", "electronic", "punk"]
@export_enum("studio", "electronic", "punk") var finish: String = "studio"
var _pressed_by_pointer: bool = false
var _texture_cache: Dictionary = {}

func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	toggled.connect(_on_toggled)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	_apply_textures()

func set_finish(next: String) -> void:
	if not FINISHES.has(next):
		return
	finish = next
	_apply_textures()

func set_locked(locked: bool) -> void:
	disabled = locked
	focus_mode = Control.FOCUS_NONE if locked else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
	if locked:
		_pressed_by_pointer = false
		set_pressed_no_signal(false)
		release_focus()
	_apply_textures()

func set_armed_from_model(armed: bool) -> void:
	if disabled and armed:
		return
	set_pressed_no_signal(armed)
	_apply_textures()

func _texture(state: String) -> Texture2D:
	var path: String = TEXTURE_DIR + "transport_" + finish + "_" + state + ".png"
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	var tex: Texture2D = _texture_cache[path] as Texture2D
	if tex == null:
		push_error("Livin' The Dream transport missing photographic state: " + path)
	return tex

func _apply_textures() -> void:
	texture_normal = _texture("idle")
	texture_hover = _texture("hover")
	texture_pressed = _texture("pressed" if _pressed_by_pointer else "active")
	texture_disabled = _texture("disabled")
	queue_redraw()

func _on_button_down() -> void:
	_pressed_by_pointer = true
	_apply_textures()

func _on_button_up() -> void:
	_pressed_by_pointer = false
	_apply_textures()

func _on_toggled(armed: bool) -> void:
	if disabled:
		return
	transport_armed.emit(armed)
	queue_redraw()

func _draw() -> void:
	# Visible keyboard focus is outside the actual photographic chassis.
	if has_focus() and not disabled:
		var ink: Color = Color("#F4B759") if finish == "studio" else (Color("#6EE6D8") if finish == "electronic" else Color("#DBE763"))
		draw_rect(Rect2(Vector2.ZERO, size), ink, false, 2.0)
