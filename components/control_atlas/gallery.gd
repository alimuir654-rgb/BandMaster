extends Control
const Kit = preload("res://components/control_atlas/kit.gd")
var look := "flightcase"
var page := "controls"
var scroll: ScrollContainer
var grid: GridContainer
var subtitle: Label
var live: Dictionary = {}
var cards: Array[Control] = []
var controls: Array[BaseButton] = []
var hardware_controls: Array[Control] = []
var top: VBoxContainer
func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(_layout)
    display(look, page)
func display(style: String, view: String) -> void:
    look = style
    page = view
    for c in get_children():
        remove_child(c)
        c.queue_free()
    live.clear()
    cards.clear()
    controls.clear()
    hardware_controls.clear()
    var backing := TextureRect.new()
    backing.texture = load("res://components/control_atlas/art/paper_surface.png" if look == "notepaper" else "res://components/control_atlas/art/case_surface.png")
    backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backing.stretch_mode = TextureRect.STRETCH_TILE
    backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backing)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for edge in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + edge, 18)
    add_child(margin)
    top = VBoxContainer.new()
    top.add_theme_constant_override("separation", 10)
    margin.add_child(top)
    var heading := Kit.label("BANDMASTER  /  COMPONENT LIBRARY", look, 22)
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    heading.custom_minimum_size.y = 32
    top.add_child(heading)
    subtitle = Kit.label(("DAY · NOTEPAPER" if look == "notepaper" else "NIGHT · FLIGHT CASE") + "   /   " + page.to_upper(), look, 14)
    top.add_child(subtitle)
    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation", 4)
    top.add_child(nav)
    for v in ["controls", "hardware", "frames"]:
        var n := Kit.button(v.capitalize(), look)
        n.add_theme_font_size_override("font_size", 14)
        n.pressed.connect(display.bind(look, v))
        nav.add_child(n)
    var swap := Kit.button("Day" if look == "flightcase" else "Night", look)
    swap.add_theme_font_size_override("font_size", 14)
    swap.pressed.connect(display.bind("notepaper" if look == "flightcase" else "flightcase", page))
    nav.add_child(swap)
    scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    top.add_child(scroll)
    grid = GridContainer.new()
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 16)
    grid.add_theme_constant_override("v_separation", 16)
    scroll.add_child(grid)
    if page == "hardware":
        _hardware_page()
    elif page == "frames":
        _frames_page()
    else:
        _controls_page()
    _layout()
func _card(title: String, text: String) -> VBoxContainer:
    var p := Kit.frame(look)
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    p.custom_minimum_size.y = 210
    grid.add_child(p)
    cards.append(p)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 10)
    p.add_child(body)
    var title_label := Kit.label(title, look, 17)
    title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(title_label)
    var info := Kit.label(text, look, 13)
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(info)
    return body
func _row(parent: Node) -> HBoxContainer:
    var r := HBoxContainer.new()
    r.add_theme_constant_override("separation", 6)
    parent.add_child(r)
    return r
func _controls_page() -> void:
    var c := _card("01  ACTIONS + ICON KEYS", "Existing six-state Lab07 skins. Native text; no baked labels.")
    var r := _row(c)
    var primary := Kit.button("Confirm", look, "action")
    var secondary := Kit.button("Cancel", look)
    r.add_child(primary)
    r.add_child(secondary)
    controls.append_array([primary, secondary])
    r = _row(c)
    for title in ["‹", "›", "+", "×"]:
        var b := Kit.button(title, look)
        r.add_child(b)
        controls.append(b)
    var inactive := Kit.button("Unavailable", look)
    inactive.disabled = true
    c.add_child(inactive)
    c = _card("02  SEGMENTED SELECTION", "Single selection; selected is not disabled. Keyboard focus preserved.")
    var roles := Kit.ChoiceStrip.new(look, PackedStringArray(["Vox", "Gtr", "Bass", "Keys"]))
    c.add_child(roles)
    controls.append_array(roles.buttons)
    live.roles = roles
    c.add_child(Kit.badge("SELECT ONE  /  exclusive choice", look))
    c = _card("03  TOGGLE + BOUNDED STEPPER", "Reusable state APIs. Bounds disable the relevant button.")
    var toggle := Kit.toggle(look)
    c.add_child(toggle)
    live.toggle = toggle
    controls.append(toggle)
    var step := Kit.Stepper.new(look, 0, 10, 4)
    c.add_child(step)
    controls.append_array([step.minus, step.plus])
    live.stepper = step
    c = _card("04  BROWSE SELECTOR", "Native previous/next flow; wrapping or bounded navigation.")
    var browse := Kit.BrowseSelector.new(look, PackedStringArray(["Verse", "Chorus", "Bridge"]))
    c.add_child(browse)
    controls.append_array([browse.previous, browse.next])
    live.browse = browse
    c.add_child(Kit.badge("SECTION 01   /   03", look))
    c = _card("05  PAGINATION + VALUE CHIP", "44px+ selectable page targets; passive data stays unfocusable.")
    var pages := Kit.ChoiceStrip.new(look, PackedStringArray(["1", "2", "3", "4"]), 1)
    c.add_child(pages)
    controls.append_array(pages.buttons)
    live.pages = pages
    c.add_child(Kit.badge("TALENT 200  ·  SESSION 03", look))
    c = _card("06  SELECTABLE ROW + PASSIVE STAT", "The original owner-liked meter texture is unchanged.")
    var row := Kit.button("AUDITION  /  51 talent", look, "browse", true)
    c.add_child(row)
    controls.append(row)
    live.row = row
    var stats := _row(c)
    stats.add_child(Kit.label("Tone", look))
    var meter := Kit.PassiveMeter.new(look, 8)
    meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats.add_child(meter)
    stats.add_child(Kit.label("8 / 10", look))
    live.meter = meter
func _hardware_page() -> void:
    var c := _card("01  HORIZONTAL FADER", "Original Lab08 source and input logic. No new fader artwork.")
    var h := Kit.hardware("horizontal")
    c.add_child(h)
    hardware_controls.append(h)
    c = _card("02  ROTARY / FOCUS", "Exact source LED positions; Home and End set 0 and 100.")
    h = Kit.hardware("focus")
    h.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    c.add_child(h)
    hardware_controls.append(h)
    c = _card("03  VERTICAL FADER", "Touch, mouse and keyboard input retained from the proven assembly.")
    h = Kit.hardware("vertical")
    h.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    c.add_child(h)
    hardware_controls.append(h)
    c = _card("04  ROTARY / BUZZ", "Reuse the separate 23-segment source family, not a re-drawn dial.")
    h = Kit.hardware("buzz")
    h.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    c.add_child(h)
    hardware_controls.append(h)
    c = _card("05  PASSIVE METERS", "Original zero, mid and maximum states; no input or focus.")
    for score in [0, 5, 10]:
        var r := _row(c)
        r.add_child(Kit.PassiveMeter.new(look, score))
        r.add_child(Kit.label(str(score) + " / 10", look))
    c = _card("06  STATE SEPARATION", "Direct controls emit level_changed. Passive stats only accept model updates.")
    c.add_child(Kit.badge("INPUT ≠ OUTPUT", look))
func _frames_page() -> void:
    load("res://components/control_atlas/frame_examples.gd").populate(self)
func _layout() -> void:
    if not is_instance_valid(grid):
        return
    grid.columns = 3 if size.x >= 1200 else (2 if size.x >= 760 else 1)
    for card in cards:
        card.custom_minimum_size.x = 0
