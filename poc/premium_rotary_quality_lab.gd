extends Control
## Standalone original photographic Lab08.4 rotary review; zero career writes.
const Rotary = preload("res://Scripts/premium_photographic_rotary.gd")
const PHASES := ["day", "dusk", "night"]
const DAY := Color("#ECE7DA")
const DUSK := Color("#283941")
const NIGHT := Color("#0B1116")
var phase := "day"
var background: ColorRect
var title: Label
var caption: Label
var focus_label: Label
var buzz_label: Label
var instructions: Label
var focus_knob: Control
var buzz_knob: Control
var phase_buttons: Dictionary = {}

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background = ColorRect.new()
    background.name = "RotaryBackdrop"
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    title = _make_label("RotaryTitle", "LIVING THE DREAM", 25)
    caption = _make_label("RotaryCaption", "LAB 08.4  /  ORIGINAL PHOTOGRAPHIC ROTARIES", 15)
    for context in PHASES:
        var button := Button.new()
        button.name = "RotaryPhase" + context.capitalize()
        button.text = context.to_upper()
        button.focus_mode = Control.FOCUS_ALL
        button.toggle_mode = true
        add_child(button)
        button.pressed.connect(func() -> void: set_phase(context))
        phase_buttons[context] = button
    focus_knob = Rotary.new()
    focus_knob.name = "PremiumFocusKnob"
    focus_knob.dial_kind = "focus"
    focus_knob.value = 50.0
    add_child(focus_knob)
    buzz_knob = Rotary.new()
    buzz_knob.name = "PremiumBuzzKnob"
    buzz_knob.dial_kind = "buzz"
    buzz_knob.value = 50.0
    add_child(buzz_knob)
    focus_label = _make_label("FocusReadout", "", 17)
    buzz_label = _make_label("BuzzReadout", "", 17)
    instructions = _make_label("RotaryHelp", "DRAG / ARROWS TO ADJUST    HOME = OFF    END = FULL    SPACE = LOCK", 13)
    focus_knob.value_changed.connect(func(_v: float) -> void: _refresh())
    buzz_knob.value_changed.connect(func(_v: float) -> void: _refresh())
    focus_knob.latch_changed.connect(func(_v: bool) -> void: _refresh())
    buzz_knob.latch_changed.connect(func(_v: bool) -> void: _refresh())
    resized.connect(_layout)
    set_phase("day")
    call_deferred("_layout")

func _make_label(n: String, t: String, font_size: int) -> Label:
    var label := Label.new()
    label.name = n
    label.text = t
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.add_theme_font_size_override("font_size", font_size)
    add_child(label)
    return label

func set_phase(next: String) -> void:
    if not PHASES.has(next):
        return
    phase = next
    background.color = DAY if phase == "day" else (DUSK if phase == "dusk" else NIGHT)
    var ink: Color = Color("#172329") if phase == "day" else Color("#F3F0E8")
    for label in [title, caption, focus_label, buzz_label, instructions]:
        label.add_theme_color_override("font_color", ink)
    for context in PHASES:
        var button: Button = phase_buttons[context]
        var active: bool = context == phase
        button.button_pressed = active
        button.disabled = active
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#D9BA7E") if active else (Color("#D4D5D1") if phase == "day" else Color("#364950"))
        style.set_corner_radius_all(5)
        for state in ["normal", "hover", "pressed", "disabled"]:
            button.add_theme_stylebox_override(state, style)
        var text_ink := Color("#1B272C") if active or phase == "day" else Color("#F5F1EA")
        button.add_theme_color_override("font_color", text_ink)
        button.add_theme_color_override("font_disabled_color", text_ink)
        button.add_theme_color_override("font_hover_color", text_ink)
    _refresh()

func set_values(focus_value: float, buzz_value: float) -> void:
    if not focus_knob.disabled:
        focus_knob.set_value_safe(focus_value)
    if not buzz_knob.disabled:
        buzz_knob.set_value_safe(buzz_value)
    _refresh()

func set_review_state(state: String) -> void:
    focus_knob.set_disabled(false)
    buzz_knob.set_disabled(false)
    focus_knob.set_latched(false)
    buzz_knob.set_latched(false)
    if state == "disabled":
        buzz_knob.set_disabled(true)
    elif state == "latched":
        focus_knob.set_latched(true)
    _refresh()

func _refresh() -> void:
    if focus_knob == null or buzz_knob == null:
        return
    focus_label.text = "CREATIVE FOCUS  /  %03d%%  %s" % [int(focus_knob.value), "LOCKED" if focus_knob.latched else ""]
    buzz_label.text = "VENUE BUZZ  /  %03d%%  %s" % [int(buzz_knob.value), "DISABLED" if buzz_knob.disabled else ("LOCKED" if buzz_knob.latched else "")]

func _layout() -> void:
    if focus_knob == null or background == null:
        return
    var w: float = size.x
    var h: float = size.y
    var physical_scale: float = float(DisplayServer.window_get_size().x) / maxf(get_viewport_rect().size.x, 1.0)
    var u: float = 1.0 / maxf(physical_scale, 0.35)
    var margin: float = 20.0 * u
    var headline_px: int = int(ceil(23.0 * u))
    var copy_px: int = int(ceil(16.0 * u))
    var note_px: int = int(ceil(13.0 * u))
    title.add_theme_font_size_override("font_size", headline_px)
    for label in [caption, focus_label, buzz_label]:
        label.add_theme_font_size_override("font_size", copy_px)
    instructions.add_theme_font_size_override("font_size", note_px)
    title.position = Vector2(margin, 22.0 * u)
    title.size = Vector2(w - margin * 2.0, 37.0 * u)
    caption.position = Vector2(margin, 67.0 * u)
    caption.size = Vector2(w - margin * 2.0, 30.0 * u)
    var gap: float = 10.0 * u
    var button_width: float = minf(110.0 * u, (w - margin * 2.0 - gap * 2.0) / 3.0)
    for i in range(PHASES.size()):
        var button: Button = phase_buttons[PHASES[i]]
        button.position = Vector2(margin + float(i) * (button_width + gap), 119.0 * u)
        button.size = Vector2(button_width, 48.0 * u)
        button.add_theme_font_size_override("font_size", copy_px)
    var dial_top: float = 235.0 * u
    var dial_gap: float = 18.0 * u
    var dial_size: float = minf(240.0 * u, (w - margin * 2.0 - dial_gap) * 0.5)
    dial_size = minf(dial_size, h - dial_top - 110.0 * u)
    dial_size = maxf(dial_size, 90.0 * u)
    var left: float = (w - dial_size * 2.0 - dial_gap) * 0.5
    focus_knob.position = Vector2(left, dial_top)
    buzz_knob.position = Vector2(left + dial_size + dial_gap, dial_top)
    focus_knob.size = Vector2(dial_size, dial_size)
    buzz_knob.size = Vector2(dial_size, dial_size)
    var labels_y: float = dial_top + dial_size + 16.0 * u
    focus_label.position = Vector2(left, labels_y)
    buzz_label.position = Vector2(left + dial_size + dial_gap, labels_y)
    focus_label.size = Vector2(dial_size + 5.0 * u, 54.0 * u)
    buzz_label.size = Vector2(dial_size + 5.0 * u, 54.0 * u)
    instructions.position = Vector2(margin, minf(h - 53.0 * u, labels_y + 80.0 * u))
    instructions.size = Vector2(w - 2.0 * margin, 46.0 * u)
