extends Button
## Hardware-inspired reusable button; native keyboard, mouse and focus semantics.
## Keep a true Button to preserve Godot navigation and screen-reader metadata.

@export_enum("transport", "channel", "pad") var hardware_style := "transport":
	set(value):
		hardware_style = value
		queue_redraw()

@export var signal_color := Color("#E6B45B"):
	set(value):
		signal_color = value
		queue_redraw()

@export var active := false:
	set(value):
		active = value
		queue_redraw()

@export var symbol := "▶":
	set(value):
		symbol = value
		queue_redraw()

func _ready() -> void:
	custom_minimum_size.y = 56 if hardware_style == "transport" else 48
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	flat = true
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(key, Color("#F5F1E8"))
	add_theme_font_size_override("font_size", 15)
	add_theme_constant_override("h_separation", 10)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)

func _draw() -> void:
	var down := button_pressed or (toggle_mode and active)
	var hovering := get_global_rect().has_point(get_global_mouse_position())
	var focused := has_focus()
	var rect := Rect2(Vector2.ZERO, size)
	var body := Color("#25323A")
	if hardware_style == "transport":
		body = Color("#323B3D")
	elif hardware_style == "pad":
		body = Color("#232B35")
	if disabled:
		body = Color("#25292C")
	elif hovering:
		body = body.lightened(0.10)
	if down:
		body = body.darkened(0.17)

	# Physical enclosure: lower bevel and edge highlights, never a web-style pill.
	draw_rect(rect.grow(-1), Color("#080D10"), true)
	var face := rect.grow(-3)
	if down:
		face.position.y += 2
		face.size.y -= 2
	draw_rect(face, body, true)
	draw_line(Vector2(4, face.position.y + 1), Vector2(size.x - 4, face.position.y + 1), Color(1, 1, 1, 0.20 if not down else 0.04), 2)
	draw_line(Vector2(4, size.y - 4), Vector2(size.x - 4, size.y - 4), Color(0, 0, 0, 0.50), 2)
	draw_rect(face, signal_color if focused else Color("#53636A"), false, 2 if focused else 1)

	# Hardware LED is the action-state indicator, not merely accent trim.
	var led := signal_color if (active or down or hovering) and not disabled else Color("#3D494D")
	draw_circle(Vector2(17, size.y * 0.5), 5.5, Color("#070B0E"))
	draw_circle(Vector2(17, size.y * 0.5), 3.5, led)
	if active or down:
		draw_arc(Vector2(17, size.y * 0.5), 8.0, 0, TAU, 24, Color(signal_color, 0.35), 2)
	if hardware_style == "transport":
		draw_rect(Rect2(Vector2(size.x - 11, 10), Vector2(3, size.y - 20)), signal_color if not disabled else Color("#596067"), true)
	elif hardware_style == "channel":
		draw_rect(Rect2(Vector2(5, 6), Vector2(3, size.y - 12)), signal_color if active else Color("#405057"), true)
