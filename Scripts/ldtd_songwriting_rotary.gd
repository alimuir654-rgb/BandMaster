extends Control
## S03 Lab08.4 Creative Focus: original photographed 27-tick ring and movable
## photographed centre. The upstream Lab08.4 studio_control.gd references
## rotary_pointer.png, which is NOT tracked in this GitHub branch. Use the
## actually tracked focus_rotor.png cropped to its centre; never invent a
## missing source asset or claim this is the final approved pointer.
signal level_changed(new_level: float)
const ROOT := "res://bandmaster_premium_dashboard_poc/assets/"
const BASE = preload("res://bandmaster_premium_dashboard_poc/assets/focus_ring_off.png")
const ROTOR = preload("res://bandmaster_premium_dashboard_poc/assets/focus_rotor.png")
const TICKS: int = 27
var control_kind: String = "focus"
var read_only: bool = false
var level: float = 55.0
var dragging: bool = false
var start_level: float = 0.0
var drag_start: Vector2 = Vector2.ZERO
var overlays: Array[Texture2D] = []

func _ready() -> void:
	for i in range(TICKS):
		var tex: Texture2D = load(ROOT + "focus_led_%02d.png" % i) as Texture2D
		if tex == null:
			push_error("Missing actual Lab08.4 focus LED %d" % i)
		else:
			overlays.append(tex)
	focus_mode = Control.FOCUS_NONE if read_only else Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS if read_only else Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if read_only else Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	queue_redraw()

func set_level(next: float) -> void:
	var clamped: float = clampf(next, 0.0, 100.0)
	if is_equal_approx(clamped, level):
		return
	level = clamped
	queue_redraw()
	level_changed.emit(level)

func _gui_input(event: InputEvent) -> void:
	if read_only:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				grab_focus()
				dragging = true
				start_level = level
				drag_start = mouse.position
			else:
				dragging = false
			accept_event()
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_level(level + 2.0)
			accept_event()
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_level(level - 2.0)
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		set_level(start_level - (motion.position.y - drag_start.y) / maxf(size.y, 90.0) * 130.0)
		accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		dragging = touch.pressed
		if dragging:
			start_level = level
			drag_start = touch.position
		accept_event()
	elif event is InputEventScreenDrag and dragging:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		set_level(start_level - (drag.position.y - drag_start.y) / maxf(size.y, 90.0) * 130.0)
		accept_event()
	elif event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_LEFT or key.keycode == KEY_DOWN:
			set_level(level - 1.0)
		elif key.keycode == KEY_RIGHT or key.keycode == KEY_UP:
			set_level(level + 1.0)
		elif key.keycode == KEY_HOME:
			set_level(0.0)
		elif key.keycode == KEY_END:
			set_level(100.0)
		else:
			return
		accept_event()

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	draw_texture_rect(BASE, Rect2(Vector2.ZERO, size), false)
	for i in range(clampi(int(round(level * overlays.size() / 100.0)), 0, overlays.size())):
		draw_texture_rect(overlays[i], Rect2(Vector2.ZERO, size), false)
	# The source centre is photographic; only the cropped rotor rotates, not LEDs.
	# Cropping excludes outer edge fragments from the older Lab05 rotor.
	var sx: float = size.x / 394.0
	var sy: float = size.y / 390.0
	var centre := Vector2(215.0 * sx, 221.0 * sy)
	var angle: float = deg_to_rad(-135.0 + level * 2.7)
	draw_set_transform(centre, angle, Vector2(sx, sy))
	draw_texture_rect_region(ROTOR, Rect2(-75.0, -75.0, 150.0, 150.0),
		Rect2(21.0, 21.0, 150.0, 150.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if has_focus() and not read_only:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#F2C06B"), false, 3.0)
