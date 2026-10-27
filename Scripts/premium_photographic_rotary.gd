extends Control
## Sprint 02 ONLY: source-backed Lab08.4 rotary family. No game/save mutations.
signal value_changed(next_value: float)
signal latch_changed(is_latched: bool)

const SOURCE := "res://bandmaster_premium_dashboard_poc/assets/"
const FOCUS_OFF = preload("res://bandmaster_premium_dashboard_poc/assets/focus_ring_off.png")
const BUZZ_OFF = preload("res://bandmaster_premium_dashboard_poc/assets/buzz_ring_off.png")
const POINTER = preload("res://bandmaster_premium_dashboard_poc/assets/rotary_pointer.png")
const FOCUS_COUNT := 27
const BUZZ_COUNT := 23

@export_enum("focus", "buzz") var dial_kind: String = "focus"
@export_range(0.0, 100.0, 1.0) var value: float = 50.0
@export var disabled: bool = false
@export var latched: bool = false

var led_layers: Array[Texture2D] = []
var dragging := false
var drag_origin := Vector2.ZERO
var origin_value := 0.0
var hovered := false
var pressing := false

func _ready() -> void:
    _load_source_layers()
    focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
    mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
    mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
    focus_entered.connect(queue_redraw)
    focus_exited.connect(queue_redraw)
    resized.connect(queue_redraw)
    queue_redraw()

func _load_source_layers() -> void:
    led_layers.clear()
    var count: int = FOCUS_COUNT if dial_kind == "focus" else BUZZ_COUNT
    for i in range(count):
        var texture: Texture2D = load(SOURCE + "%s_led_%02d.png" % [dial_kind, i]) as Texture2D
        if texture == null:
            push_error("Premium rotary: original Lab08.4 overlay absent at %d" % i)
            return
        led_layers.append(texture)

func set_value_safe(next_value: float) -> void:
    if disabled:
        return
    var next: float = clampf(next_value, 0.0, 100.0)
    if is_equal_approx(value, next):
        return
    value = next
    queue_redraw()
    value_changed.emit(value)

func set_disabled(next_disabled: bool) -> void:
    disabled = next_disabled
    dragging = false
    pressing = false
    focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
    mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
    if disabled and has_focus():
        release_focus()
    queue_redraw()

func set_latched(next_latched: bool) -> void:
    if disabled:
        return
    if latched != next_latched:
        latched = next_latched
        latch_changed.emit(latched)
        queue_redraw()

func active_led_count() -> int:
    if disabled:
        return 0
    var count: int = FOCUS_COUNT if dial_kind == "focus" else BUZZ_COUNT
    return clampi(int(round(value * float(count) / 100.0)), 0, count)

func pointer_degrees() -> float:
    return -135.0 + clampf(value, 0.0, 100.0) * 2.7

func _gui_input(event: InputEvent) -> void:
    if disabled:
        return
    if event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            dragging = mouse.pressed
            pressing = mouse.pressed
            if dragging:
                grab_focus()
                drag_origin = mouse.position
                origin_value = value
            queue_redraw()
            accept_event()
        elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
            set_value_safe(value + 2.0)
            accept_event()
        elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            set_value_safe(value - 2.0)
            accept_event()
    elif event is InputEventMouseMotion and dragging:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        set_value_safe(origin_value - (motion.position.y - drag_origin.y) * 130.0 / maxf(size.y, 90.0))
        accept_event()
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        dragging = touch.pressed
        pressing = touch.pressed
        if dragging:
            grab_focus()
            drag_origin = touch.position
            origin_value = value
        queue_redraw()
        accept_event()
    elif event is InputEventScreenDrag and dragging:
        var motion: InputEventScreenDrag = event as InputEventScreenDrag
        set_value_safe(origin_value - (motion.position.y - drag_origin.y) * 130.0 / maxf(size.y, 90.0))
        accept_event()
    elif event is InputEventKey:
        var key: InputEventKey = event as InputEventKey
        if not key.pressed or key.echo:
            return
        match key.keycode:
            KEY_LEFT, KEY_DOWN:
                set_value_safe(value - 1.0)
            KEY_RIGHT, KEY_UP:
                set_value_safe(value + 1.0)
            KEY_PAGEUP:
                set_value_safe(value + 10.0)
            KEY_PAGEDOWN:
                set_value_safe(value - 10.0)
            KEY_HOME:
                set_value_safe(0.0)
            KEY_END:
                set_value_safe(100.0)
            KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
                set_latched(not latched)
            _:
                return
        accept_event()

func _draw() -> void:
    if size.x < 44.0 or size.y < 44.0:
        return
    var base: Texture2D = FOCUS_OFF if dial_kind == "focus" else BUZZ_OFF
    var rect := Rect2(Vector2.ZERO, size)
    var tint := Color(0.7, 0.7, 0.7, 1.0) if disabled else Color.WHITE
    draw_texture_rect(base, rect, false, tint)
    var lit: int = active_led_count()
    for i in range(mini(lit, led_layers.size())):
        draw_texture_rect(led_layers[i], rect, false)
    var sx: float = size.x / float(base.get_width())
    var sy: float = size.y / float(base.get_height())
    var native_centre: Vector2 = Vector2(215.0, 221.0) if dial_kind == "focus" else Vector2(220.0, 218.0)
    var centre: Vector2 = Vector2(native_centre.x * sx, native_centre.y * sy)
    draw_set_transform(centre, deg_to_rad(pointer_degrees()), Vector2(sx, sy))
    # No emissive pointer at OFF or when disabled: the plate remains neutral.
    var pointer_tint := Color(0.18, 0.20, 0.21, 0.75) if lit == 0 else Color.WHITE
    draw_texture(POINTER, -POINTER.get_size() * 0.5, pointer_tint)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    # Focus/selection are thin external accessibility cues, never fake metal art.
    if has_focus() or pressing or latched:
        var colour := Color("#F1C77D") if latched else Color("#C7D9DF")
        draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), colour, false, 2.0)
    elif hovered:
        draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.78, 0.83, 0.86, 0.45), false, 1.0)
