extends Control
## Standalone, read-only visual proof. Does not read or modify saves.
## Layout uses anchors and explicit positioning: no nested container minimum-size chain.

const BG := Color("#0C1116")
const SURFACE := Color("#151E25")
const ELEVATED := Color("#1C2B33")
const BORDER := Color("#32434C")
const WHITE := Color("#F7F1E6")
const MUTED := Color("#A2B1B8")
const GOLD := Color("#F0B85A")
const MINT := Color("#6AD3C4")

var scroll: ScrollContainer
var content: VBoxContainer
var nav: Control
var header: Control
var toast: Label
var active_section := "Overview"
var is_wide := false
var genre := "Indie / Alternative"
const GENRES := {
	"Indie / Alternative": ["#E6B45B", "#74B3AE", "#3A5360"],
	"Electronic": ["#70E5DB", "#B09CFF", "#1E4C61"],
	"Punk / Garage": ["#DCE85B", "#FF7169", "#4A413A"],
	"Metal / Hard Rock": ["#F08B57", "#D55F69", "#4D3843"],
	"Pop": ["#FF94BA", "#AFB6FF", "#4C3C60"],
	"Jazz / Soul": ["#D1B475", "#86B79D", "#394E43"]
}
func accent() -> Color:
	return Color(GENRES[genre][0])
func secondary_accent() -> Color:
	return Color(GENRES[genre][1])
func tint() -> Color:
	return Color(GENRES[genre][2])


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_relayout)
	_build()

func _relayout() -> void:
	var wide := size.x >= 900.0
	if wide != is_wide:
		_build()
	else:
		_position_regions()

func _background(parent: Control, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r

func _box(color: Color, radius: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = BORDER
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(14)
	return s

func _label(parent: Node, value: String, px: int, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _column(parent: Node, gap: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", gap)
	parent.add_child(v)
	return v

func _panel(parent: Node, fill: Color = SURFACE) -> VBoxContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _box(fill, 12))
	parent.add_child(p)
	return _column(p, 11)

func _button(parent: Node, title: String, primary: bool, action: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size.y = 50
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var base := accent() if primary else Color("#25353D")
	var ink := BG if primary else WHITE
	b.text = ("▶  " if primary else "▣  ") + title
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := base
		if state == "hover":
			fill = base.lightened(0.13)
		elif state == "pressed":
			fill = base.darkened(0.14)
		var style := _box(fill, 5)
		style.shadow_color = Color(0, 0, 0, 0.55)
		style.shadow_size = 1 if state == "pressed" else 4
		style.shadow_offset = Vector2(0, 1 if state == "pressed" else 3)
		style.border_color = accent() if primary else BORDER
		if state == "focus":
			style.border_color = accent()
			style.set_border_width_all(2)
		b.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, ink)
	b.add_theme_font_size_override("font_size", 15)
	parent.add_child(b)
	b.pressed.connect(action)
	return b

func _build() -> void:
	is_wide = size.x >= 900.0
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_background(self, BG)

	nav = Control.new()
	add_child(nav)
	_background(nav, Color("#11191F"))

	header = Control.new()
	add_child(header)
	_background(header, Color("#131E24"))

	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 24 if is_wide else 14)
	margin.add_theme_constant_override("margin_right", 24 if is_wide else 14)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 32)
	scroll.add_child(margin)
	content = _column(margin, 16)
	_fill_nav()
	_fill_header()
	_fill_content()
	_position_regions()

func _position_regions() -> void:
	var w := size.x
	var h := size.y
	var side := 235.0 if is_wide else 0.0
	var nav_height := 0.0 if is_wide else 60.0
	nav.position = Vector2(0, 0 if is_wide else 96)
	nav.size = Vector2(side if is_wide else w, h if is_wide else nav_height)
	header.position = Vector2(side, 0)
	header.size = Vector2(maxf(0, w - side), 96)
	scroll.position = Vector2(side, 96 + nav_height)
	scroll.size = Vector2(maxf(0, w - side), maxf(0, h - 96 - nav_height))

func _fill_header() -> void:
	var tag := _label(header, "LIVING THE DREAM  /  CAREER", 12, accent())
	tag.position = Vector2(22, 13)
	tag.size = Vector2(600, 18)
	var title := _label(header, "THE LONG WEEKEND", 22)
	title.position = Vector2(22, 32)
	title.size = Vector2(600, 30)
	var meta := _label(header, "YEAR 01 · WEEK 06 · £1,240 CASH", 13, MUTED)
	meta.position = Vector2(22, 66)
	meta.size = Vector2(600, 21)

func _fill_nav() -> void:
	if is_wide:
		var name := _label(nav, "LIVING THE DREAM", 18, accent())
		name.position = Vector2(16, 19)
		name.size = Vector2(205, 25)
		var subtitle := _label(nav, "CAREER / DEMO", 12, MUTED)
		subtitle.position = Vector2(16, 49)
		subtitle.size = Vector2(205, 19)
	var items := ["Overview", "Band", "Songs", "Gigs", "Journal"]
	for i in range(items.size()):
		var item: String = items[i]
		var b := Button.new()
		b.text = item.to_upper() if is_wide else item
		b.position = Vector2(16, 110 + 60 * i) if is_wide else Vector2((size.x / 5.0) * i, 5)
		b.size = Vector2(203, 49) if is_wide else Vector2(size.x / 5.0, 49)
		var chosen := item == active_section
		var ns := _box(tint() if chosen else SURFACE, 4)
		ns.border_color = accent() if chosen else BORDER
		ns.border_width_left = 4 if chosen else 1
		b.add_theme_stylebox_override("normal", ns)
		b.add_theme_stylebox_override("hover", _box(tint().lightened(0.12), 4))
		b.add_theme_stylebox_override("pressed", _box(tint().darkened(0.12), 4))
		b.add_theme_font_size_override("font_size", 13 if is_wide else 11)
		nav.add_child(b)
		b.pressed.connect(func() -> void: _choose(item))

func _choose(item: String) -> void:
	active_section = item
	_build()
	if item != "Overview":
		_notice(item + " is a navigation prototype; no career data changed.")

func _fill_content() -> void:
	_label(content, "SOUND PROFILE  /  LIVE THEME PREVIEW", 12, accent())
	var selector := OptionButton.new()
	selector.custom_minimum_size.y = 48
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for name in GENRES.keys():
		selector.add_item(str(name))
		if name == genre:
			selector.select(selector.item_count - 1)
	selector.add_theme_stylebox_override("normal", _box(SURFACE, 4))
	selector.add_theme_font_size_override("font_size", 15)
	selector.item_selected.connect(func(index: int) -> void: _change_genre(selector.get_item_text(index)))
	content.add_child(selector)
	_label(content, "CAREER OVERVIEW  /  VISUAL PROOF", 12, accent())
	_label(content, "THE NEXT MOVE IS YOURS.", 28)
	_label(content, "Six weeks into a band's story. One chance to make the next gig count.", 15, MUTED)

	var hero := _panel(content, tint())
	_label(hero, "UP NEXT  /  FRIDAY 9:00 PM", 12, secondary_accent())
	_label(hero, "THE EXCHANGE", 32)
	_label(hero, "BRISTOL   ·   HEADLINE SLOT   ·   120 CAPACITY", 13, MUTED)
	_label(hero, "The set needs tightening. The van isn't sorted. Ticket sales have started moving.", 16)
	_button(hero, "PLAN THE SHOW  ›", true, func() -> void: _notice("Show planning is not connected in the PoC."))
	_button(hero, "VIEW SETLIST", false, func() -> void: _notice("Setlist is not connected in the PoC."))

	_label(content, "AT A GLANCE / CHANNEL METERS", 13, accent())
	_metric("BAND MORALE", "72 / 100", "STEADY", secondary_accent(), 72)
	_metric("SHOW READINESS", "64 / 100", "NEEDS REHEARSAL", accent(), 64)
	_metric("LOCAL FOLLOWING", "218", "+26 THIS WEEK", secondary_accent(), 83)

	var tasks := _panel(content)
	_label(tasks, "THIS WEEK'S PRIORITIES", 13, accent())
	_label(tasks, "01   Finish the second rehearsal", 17)
	_label(tasks, "02   Confirm the van", 17)
	_label(tasks, "03   Promote the headline show", 17)

	var story := _panel(content)
	_label(story, "THE STORY SO FAR", 13, accent())
	_label(story, "A band with momentum, but nothing guaranteed.", 20)
	_label(story, "Every decision shapes the next chapter.", 15, MUTED)
	_button(story, "OPEN JOURNAL", false, func() -> void: _choose("Journal"))
	toast = _label(content, "SAMPLE CAREER · VISUAL PROTOTYPE · SAVES UNCHANGED", 12, MUTED)

func _metric(title: String, value: String, hint: String, hue: Color, level: float) -> void:
	var card := _panel(content)
	_label(card, "●  " + title, 12, MUTED)
	_label(card, value, 27)
	var meter := ProgressBar.new()
	meter.custom_minimum_size.y = 11
	meter.max_value = 100
	meter.value = level
	meter.show_percentage = false
	meter.add_theme_stylebox_override("background", _box(Color("#0B1217"), 2))
	meter.add_theme_stylebox_override("fill", _box(hue, 2))
	card.add_child(meter)
	_label(card, hint, 13, hue)

func _change_genre(value: String) -> void:
	if not GENRES.has(value):
		return
	genre = value
	_build()

func _notice(message: String) -> void:
	if is_instance_valid(toast):
		toast.text = message
