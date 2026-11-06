extends Control
## Texture-layered working mixer controls.  No asset generation at runtime.
## Values are demonstration-only and are never written to user://.
signal level_changed(new_level: float)

const ART := "res://bandmaster_premium_dashboard_poc/assets/"
const H_BASE := preload("res://bandmaster_premium_dashboard_poc/assets/horizontal_base.png")
const H_CAP := preload("res://bandmaster_premium_dashboard_poc/assets/horizontal_cap.png")
const V_BASE := preload("res://bandmaster_premium_dashboard_poc/assets/vertical_base.png")
const V_CAP := preload("res://bandmaster_premium_dashboard_poc/assets/vertical_cap.png")
const F_BASE := preload("res://bandmaster_premium_dashboard_poc/assets/focus_ring_off.png")
const DIAL_POINTER := preload("res://bandmaster_premium_dashboard_poc/assets/rotary_pointer.png")
const B_BASE := preload("res://bandmaster_premium_dashboard_poc/assets/buzz_ring_off.png")

const M_BASE := preload("res://bandmaster_premium_dashboard_poc/assets/meter_base.png")

@export_enum("horizontal", "vertical", "focus", "buzz", "meter") var control_kind: String = "horizontal"
@export_range(0, 100, 1) var level: float = 64.0
@export var read_only: bool = false
@export var highlight: Color = Color("#F6BA59")
const FOCUS_SEGMENTS: int = 27
const BUZZ_SEGMENTS: int = 23
var ring_layers: Array[Texture2D] = []
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var start_level: float = 0.0

func _ready() -> void:
	if control_kind == "focus" or control_kind == "buzz":
		# Preload all LED layers once per instance. Dragging redraws cached textures.
		var expected_segments: int = FOCUS_SEGMENTS if control_kind == "focus" else BUZZ_SEGMENTS
		for index in range(expected_segments):
			var file_name: String = "%s_led_%02d.png" % [control_kind, index]
			var texture: Texture2D = load(ART + file_name) as Texture2D
			if texture == null:
				push_error("Lab 08.4 missing LED layer: " + file_name)
				continue
			ring_layers.append(texture)
	mouse_filter = Control.MOUSE_FILTER_PASS if read_only else Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE if read_only else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW if read_only else Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	queue_redraw()

func set_level(new_level: float) -> void:
	var next: float = clampf(new_level, 0.0, 100.0)
	if is_equal_approx(next, level):
		return
	level = next
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
				drag_start = mouse.position
				start_level = level
				accept_event()
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
		var delta: Vector2 = motion.position - drag_start
		var travel: float = maxf(size.y if control_kind == "vertical" else size.x, 90.0)
		if control_kind == "horizontal":
			set_level(start_level + (delta.x / travel) * 125.0)
		else:
			set_level(start_level - (delta.y / travel) * 130.0)
		accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		dragging = touch.pressed
		if dragging:
			start_level = level
			drag_start = touch.position
		accept_event()
	elif event is InputEventScreenDrag and dragging:
		var touch_drag: InputEventScreenDrag = event as InputEventScreenDrag
		var touch_delta: Vector2 = touch_drag.position - drag_start
		var touch_travel: float = maxf(size.y if control_kind == "vertical" else size.x, 90.0)
		if control_kind == "horizontal":
			set_level(start_level + (touch_delta.x / touch_travel) * 125.0)
		else:
			set_level(start_level - (touch_delta.y / touch_travel) * 130.0)
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
	var base: Texture2D
	match control_kind:
		"horizontal":
			base = H_BASE
		"vertical":
			base = V_BASE
		"focus":
			base = F_BASE
		"buzz":
			base = B_BASE
		"meter":
			base = M_BASE
		_:
			return
	if size.x <= 0 or size.y <= 0:
		return
	draw_texture_rect(base, Rect2(Vector2.ZERO, size), false)
	var sx: float = size.x / float(base.get_width())
	var sy: float = size.y / float(base.get_height())
	if control_kind == "horizontal":
		var cap_left: float = lerpf(60.0, 685.0, level / 100.0)
		var glow_end: float = lerpf(126.0, 719.0, level / 100.0)
		var pos_y: float = 138.0 * sy
		draw_line(Vector2(130.0 * sx, pos_y), Vector2(glow_end * sx, pos_y), Color(highlight, 0.32), 8.0 * sy, true)
		draw_line(Vector2(130.0 * sx, pos_y), Vector2(glow_end * sx, pos_y), highlight, 3.5 * sy, true)
		draw_texture_rect(H_CAP, Rect2(cap_left * sx, 62.0 * sy, float(H_CAP.get_width()) * sx, float(H_CAP.get_height()) * sy), false)
	elif control_kind == "vertical":
		var cap_top: float = lerpf(500.0, 90.0, level / 100.0)
		draw_line(Vector2(195.0 * sx, (cap_top + 122.0) * sy), Vector2(195.0 * sx, 630.0 * sy), Color(highlight, 0.32), 9.0 * sx, true)
		draw_line(Vector2(195.0 * sx, (cap_top + 122.0) * sy), Vector2(195.0 * sx, 630.0 * sy), highlight, 4.0 * sx, true)
		draw_texture_rect(V_CAP, Rect2(137.0 * sx, cap_top * sy, float(V_CAP.get_width()) * sx, float(V_CAP.get_height()) * sy), false)
	elif control_kind == "focus" or control_kind == "buzz":
		# Lab 08.4: exact photographic tick positions, no diffuse highpass masks.
		# Creative Focus has 27 visible ticks; Venue Buzz has 23 discrete pads.
		# All layers are fixed relative to the chassis, only the pointer rotates.
		var loaded_count: int = ring_layers.size()
		var lit_count: int = clampi(int(round(level * float(loaded_count) / 100.0)), 0, loaded_count)
		for index in range(lit_count):
			draw_texture_rect(ring_layers[index], Rect2(Vector2.ZERO, size), false)
		var native_centre: Vector2 = Vector2(215.0, 221.0) if control_kind == "focus" else Vector2(220.0, 218.0)
		var centre: Vector2 = Vector2(native_centre.x * sx, native_centre.y * sy)
		var angle: float = deg_to_rad(-135.0 + clampf(level, 0.0, 100.0) * 2.7)
		draw_set_transform(centre, angle, Vector2(sx, sy))
		draw_texture(DIAL_POINTER, -DIAL_POINTER.get_size() / 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif control_kind == "meter":
		# The supplied photo has fixed illuminated bars. Cover only its glass
		# and render true value-dependent segments above the intact metal frame.
		draw_rect(Rect2(Vector2(141.0 * sx, 102.0 * sy), Vector2(74.0 * sx, 565.0 * sy)), Color("#061013"), true)
		for i in range(20):
			var active: bool = float(i) < level / 5.0
			var colour: Color = Color("#E75051") if i < 6 else (Color("#E8B14E") if i < 14 else Color("#64E89A"))
			if not active:
				colour = Color("#263436")
			var segment_y: float = (636.0 - float(i) * 26.3) * sy
			draw_rect(Rect2(Vector2(145.0 * sx, segment_y), Vector2(64.0 * sx, 15.0 * sy)), colour, true)
			if active:
				draw_rect(Rect2(Vector2(149.0 * sx, segment_y + 3.0 * sy), Vector2(56.0 * sx, 4.0 * sy)), Color(1, 1, 1, 0.22), true)
	if has_focus():
		draw_rect(Rect2(Vector2.ZERO, size), Color(highlight, 0.75), false, 2.0)
