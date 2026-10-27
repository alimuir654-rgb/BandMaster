extends Control
## Photographic read-only HYPE meter. Reads authoritative stat input; never handles player input.
const BASE: Texture2D = preload("res://bandmaster_premium_dashboard_poc/assets/meter_base.png")
@export_range(0.0, 100.0, 1.0) var reading: float = 68.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	resized.connect(queue_redraw)
	queue_redraw()

func set_reading(stat: float) -> void:
	var next: float = clampf(stat, 0.0, 100.0)
	if is_equal_approx(next, reading):
		return
	reading = next
	queue_redraw()

func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var sx: float = size.x / float(BASE.get_width())
	var sy: float = size.y / float(BASE.get_height())
	draw_texture_rect(BASE, Rect2(Vector2.ZERO, size), false)
	# Photo contains fixed lit segments: erase only the rectangular glass window.
	# Reproduce neutral unlit wells, then draw the exact number lit from authoritative reading.
	draw_rect(Rect2(141.0 * sx, 102.0 * sy, 74.0 * sx, 565.0 * sy), Color("#061013"))
	for index in range(20):
		var active: bool = float(index) < reading / 5.0
		var colour: Color = Color("#E95051") if index < 6 else (Color("#E8B14E") if index < 14 else Color("#64E89A"))
		if not active:
			colour = Color("#1C292B")
		var y: float = (636.0 - float(index) * 26.3) * sy
		draw_rect(Rect2(145.0 * sx, y, 64.0 * sx, 15.0 * sy), colour)
		if active:
			draw_rect(Rect2(149.0 * sx, y + 3.0 * sy, 56.0 * sx, 4.0 * sy), Color(1, 1, 1, 0.20))
