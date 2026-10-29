extends RefCounted
## Native reusable controls backed by verified original source artwork.
const MATERIAL := "res://components/control_atlas/art/"
const Hardware = preload("res://components/control_atlas/bandmaster_premium_dashboard_poc/studio_control.gd")
static var skin_textures: Dictionary = {}
static func ink(look: String) -> Color:
    return Color("282620") if look == "notepaper" else Color("efe9da")
static func skin(look: String, family: String, state: String) -> StyleBoxTexture:
    var s := StyleBoxTexture.new()
    var path := MATERIAL + "control_%s_%s_%s.png" % [family, look, state]
    if not skin_textures.has(path):
        var source: Texture2D = load(path)
        var image := source.get_image()
        image.resize(roundi(float(image.get_width()) * 48.0 / image.get_height()), 48, Image.INTERPOLATE_LANCZOS)
        skin_textures[path] = ImageTexture.create_from_image(image)
    s.texture = skin_textures[path]
    s.set_texture_margin_all(12)
    s.content_margin_left = 12
    s.content_margin_right = 12
    s.content_margin_top = 6
    s.content_margin_bottom = 6
    return s
static func button(label: String, look := "flightcase", family := "tab", toggle := false) -> Button:
    var b := Button.new()
    b.text = label
    b.tooltip_text = label
    b.toggle_mode = toggle
    b.custom_minimum_size = Vector2(48, 48)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.focus_mode = Control.FOCUS_ALL
    b.add_theme_font_size_override("font_size", 16)
    b.add_theme_stylebox_override("normal", skin(look, family, "idle"))
    b.add_theme_stylebox_override("hover", skin(look, family, "hover"))
    b.add_theme_stylebox_override("pressed", skin(look, family, "active" if toggle else "pressed"))
    b.add_theme_stylebox_override("hover_pressed", skin(look, family, "active"))
    b.add_theme_stylebox_override("disabled", skin(look, family, "disabled"))
    var focus := skin(look, family, "focus")
    focus.draw_center = false
    focus.set_texture_margin_all(5)
    b.add_theme_stylebox_override("focus", focus)
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
        b.add_theme_color_override(state, ink(look))
    if look == "flightcase":
        b.add_theme_color_override("font_pressed_color", Color("f1be62"))
        b.add_theme_color_override("font_hover_pressed_color", Color("f1be62"))
    b.add_theme_color_override("font_disabled_color", Color("615b51") if look == "notepaper" else Color("8d9396"))
    b.set_meta("source", "U18/U03 Lab07 original state family; proportional runtime downsample")
    return b
static func label(text: String, look: String, points := 16) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", points)
    l.add_theme_color_override("font_color", ink(look))
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l
static func frame(look: String, preset := "panel") -> PanelContainer:
    return load("res://components/control_atlas/frame_styles.gd").make(look, preset)
static func dialog(title: String, message: String, look := "flightcase") -> Control:
    var overlay = load("res://components/control_atlas/framed_dialog.gd").new()
    overlay.look = look
    overlay.title_text = title
    overlay.body_text = message
    return overlay
static func badge(text: String, look: String) -> PanelContainer:
    var p := frame(look, "ticket")
    var caption := label(text, look, 14)
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    p.add_child(caption)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.focus_mode = Control.FOCUS_NONE
    return p
class PassiveMeter extends TextureRect:
    var look := "flightcase"
    var score := 0
    func _init(style: String = "flightcase", initial: int = 0) -> void:
        look = style
        custom_minimum_size = Vector2(148, 24)
        expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        focus_mode = Control.FOCUS_NONE
        set_score(initial)
    func set_score(next: int) -> void:
        score = clampi(next, 0, 10)
        texture = load("res://components/control_atlas/art/passive_meter_%s_%02d.png" % [look, score])
        tooltip_text = "%d / 10 (read only)" % score
class Stepper extends HBoxContainer:
    signal value_changed(value: int)
    var minimum := 0
    var maximum := 10
    var increment := 1
    var value := 0
    var minus: Button
    var plus: Button
    var display: Label
    var locked := false
    func _init(look := "flightcase", low := 0, high := 10, initial := 0) -> void:
        minimum = mini(low, high)
        maximum = maxi(low, high)
        minus = load("res://components/control_atlas/kit.gd").button("−", look)
        plus = load("res://components/control_atlas/kit.gd").button("+", look)
        display = load("res://components/control_atlas/kit.gd").label("", look, 18)
        display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        display.custom_minimum_size.x = 56
        add_child(minus)
        add_child(display)
        add_child(plus)
        minus.pressed.connect(func(): set_value(value - increment))
        plus.pressed.connect(func(): set_value(value + increment))
        value = clampi(initial, minimum, maximum)
        _refresh()
    func set_value(next: int, emit := true) -> void:
        var bounded := clampi(next, minimum, maximum)
        if bounded == value:
            return
        value = bounded
        _refresh()
        if emit:
            value_changed.emit(value)
    func set_locked(next: bool) -> void:
        locked = next
        _refresh()
    func _refresh() -> void:
        display.text = str(value)
        minus.disabled = locked or value <= minimum
        plus.disabled = locked or value >= maximum
        minus.tooltip_text = "Decrease value"
        plus.tooltip_text = "Increase value"
class ChoiceStrip extends HBoxContainer:
    signal selection_changed(index: int)
    var selected := 0
    var buttons: Array[Button] = []
    var group := ButtonGroup.new()
    func _init(look := "flightcase", labels := PackedStringArray(["A", "B", "C"]), initial := 0) -> void:
        add_theme_constant_override("separation", 4)
        group.allow_unpress = false
        for i in range(labels.size()):
            var b: Button = load("res://components/control_atlas/kit.gd").button(labels[i], look, "tab", true)
            b.button_group = group
            buttons.append(b)
            add_child(b)
            b.pressed.connect(select.bind(i))
        if not buttons.is_empty():
            selected = clampi(initial, 0, buttons.size() - 1)
            buttons[selected].set_pressed_no_signal(true)
    func select(index: int, emit := true) -> void:
        if index < 0 or index >= buttons.size() or buttons[index].disabled:
            return
        # set_pressed_no_signal intentionally does not update ButtonGroup peers.
        for i in range(buttons.size()):
            buttons[i].set_pressed_no_signal(i == index)
        if selected == index:
            return
        selected = index
        if emit:
            selection_changed.emit(index)
    func set_locked(next: bool) -> void:
        for b in buttons:
            b.disabled = next
class BrowseSelector extends HBoxContainer:
    signal selection_changed(index: int, item: String)
    var items: PackedStringArray
    var selected := 0
    var wrap := true
    var locked := false
    var previous: Button
    var next: Button
    var display: Label
    func _init(look := "flightcase", choices := PackedStringArray(["First", "Second"])) -> void:
        items = choices
        previous = load("res://components/control_atlas/kit.gd").button("‹", look)
        next = load("res://components/control_atlas/kit.gd").button("›", look)
        display = load("res://components/control_atlas/kit.gd").label("", look, 16)
        display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        display.clip_text = true
        display.custom_minimum_size.x = 100
        previous.size_flags_horizontal = Control.SIZE_FILL
        next.size_flags_horizontal = Control.SIZE_FILL
        add_child(previous)
        add_child(display)
        add_child(next)
        previous.pressed.connect(move.bind(-1))
        next.pressed.connect(move.bind(1))
        previous.tooltip_text = "Previous item"
        next.tooltip_text = "Next item"
        _refresh()
    func move(delta: int) -> void:
        if locked or items.is_empty():
            return
        var index := posmod(selected + delta, items.size()) if wrap else clampi(selected + delta, 0, items.size() - 1)
        if index == selected:
            return
        selected = index
        _refresh()
        selection_changed.emit(selected, items[selected])
    func set_locked(value: bool) -> void:
        locked = value
        _refresh()
    func _refresh() -> void:
        display.text = items[selected] if not items.is_empty() else "No items"
        previous.disabled = locked or items.size() < 2 or (not wrap and selected == 0)
        next.disabled = locked or items.size() < 2 or (not wrap and selected == items.size() - 1)
static func toggle(look: String, title := "Metronome") -> Button:
    var b := button(title + " · OFF", look, "tab", true)
    b.toggled.connect(func(on: bool): b.text = title + (" · ON" if on else " · OFF"))
    return b
static func hardware(kind: String, initial: float = 50.0) -> Control:
    var h := Hardware.new()
    h.control_kind = kind
    h.level = initial
    h.custom_minimum_size = Vector2(280, 98) if kind == "horizontal" else (Vector2(100, 190) if kind == "vertical" else Vector2(180, 180))
    return h
