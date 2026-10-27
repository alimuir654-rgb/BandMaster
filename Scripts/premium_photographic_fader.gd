extends Control
## ORIGINAL Lab08 photographed chassis/cap, no procedural plate or save writes.
signal value_changed(value: float)

const H_BASE: Texture2D = preload("res://bandmaster_premium_dashboard_poc/assets/horizontal_base.png")
const H_CAP: Texture2D = preload("res://bandmaster_premium_dashboard_poc/assets/horizontal_cap.png")
const V_BASE: Texture2D = preload("res://bandmaster_premium_dashboard_poc/assets/vertical_base.png")
const V_CAP: Texture2D = preload("res://bandmaster_premium_dashboard_poc/assets/vertical_cap.png")

@export_enum("horizontal", "vertical") var orientation: String = "horizontal"
@export_range(0.0, 100.0, 1.0) var value: float = 50.0
@export var disabled: bool = false
@export var light_color: Color = Color("#F6BA59")
var dragging: bool = false
var _drag_origin: Vector2 = Vector2.ZERO
var _value_origin: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	queue_redraw()

func set_value_safe(next: float) -> void:
	var normalized: float = clampf(next, 0.0, 100.0)
	if is_equal_approx(value, normalized):
		return
	value = normalized
	queue_redraw()
	value_changed.emit(value)

func set_disabled(next: bool) -> void:
	disabled = next
	dragging = false
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT:
			if click.pressed:
				grab_focus()
				dragging = true
				_drag_origin = click.position
				_value_origin = value
			else:
				dragging = false
			accept_event()
		elif click.pressed and click.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_value_safe(value + 2.0)
			accept_event()
		elif click.pressed and click.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_value_safe(value - 2.0)
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_drag_to(motion.position)
		accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		dragging = touch.pressed
		if dragging:
			grab_focus()
			_drag_origin = touch.position
			_value_origin = value
		accept_event()
	elif event is InputEventScreenDrag and dragging:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		_drag_to(drag.position)
		accept_event()
	elif event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if not key.pressed or key.echo:
			return
		match key.keycode:
			KEY_LEFT, KEY_DOWN: set_value_safe(value - 1.0)
			KEY_RIGHT, KEY_UP: set_value_safe(value + 1.0)
			KEY_HOME: set_value_safe(0.0)
			KEY_END: set_value_safe(100.0)
			_: return
		accept_event()

func _drag_to(pos: Vector2) -> void:
	var movement: float = (pos.x - _drag_origin.x) if orientation == "horizontal" else (_drag_origin.y - pos.y)
	var travel: float = maxf(size.x if orientation == "horizontal" else size.y, 90.0)
	set_value_safe(_value_origin + movement * 125.0 / travel)

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var plate: Texture2D = H_BASE if orientation == "horizontal" else V_BASE
	var cap: Texture2D = H_CAP if orientation == "horizontal" else V_CAP
	var sx: float = size.x / float(plate.get_width())
	var sy: float = size.y / float(plate.get_height())
	draw_texture_rect(plate, Rect2(Vector2.ZERO, size), false)
	# Critical Lab08 correction: zero paints absolutely no emissive rail pixels.
	if value > 0.0 and not disabled:
		if orientation == "horizontal":
			var start: Vector2 = Vector2(130.0 * sx, 138.0 * sy)
			var finish: Vector2 = Vector2(lerpf(130.0, 719.0, value / 100.0) * sx, 138.0 * sy)
			if finish.x > start.x + 0.1:
				draw_line(start, finish, Color(light_color, 0.23), 8.0 * sy, true)
				draw_line(start, finish, light_color, 3.5 * sy, true)
		else:
			var cap_top: float = lerpf(500.0, 90.0, value / 100.0)
			var start: Vector2 = Vector2(195.0 * sx, (cap_top + 122.0) * sy)
			var finish: Vector2 = Vector2(195.0 * sx, 630.0 * sy)
			if finish.y > start.y + 0.1:
				draw_line(start, finish, Color(light_color, 0.23), 9.0 * sx, true)
				draw_line(start, finish, light_color, 4.0 * sx, true)
	if orientation == "horizontal":
		var x: float = lerpf(60.0, 685.0, value / 100.0)
		draw_texture_rect(cap, Rect2(Vector2(x * sx, 62.0 * sy), Vector2(float(cap.get_width()) * sx, float(cap.get_height()) * sy)), false)
	else:
		var y: float = lerpf(500.0, 90.0, value / 100.0)
		draw_texture_rect(cap, Rect2(Vector2(137.0 * sx, y * sy), Vector2(float(cap.get_width()) * sx, float(cap.get_height()) * sy)), false)
	if disabled:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.09, 0.10, 0.42), true)
	elif has_focus():
		draw_rect(Rect2(Vector2.ZERO, size), Color(light_color, 0.75), false, 2.0)
