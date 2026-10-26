extends Control
## Isolated, read-only visual proof of concept. No gameplay state is read or mutated.
## Run with: godot --path . --scene res://poc/premium_dashboard.tscn

const BG := Color("#0A1115")
const PANEL := Color("#172228")
const RAISED := Color("#1E252C")
const LINE := Color("#34464C")
const WHITE := Color("#F5F0E5")
const MUTED := Color("#A0B4B9")
const ACCENT := Color("#F2B84D")
const CYAN := Color("#57CCC7")
const SIDEBAR_WIDTH := 216.0

var stage: VBoxContainer
var header_title: Label
var feedback: Label
var active_tab := "Overview"
var nav_buttons: Dictionary = {}
var desktop := false
var viewport_scroll: ScrollContainer
var body_font: SystemFont
var heading_font: SystemFont

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(["Inter", "Segoe UI", "Arial"])
	heading_font = SystemFont.new()
	heading_font.font_names = PackedStringArray(["Inter", "Segoe UI Semibold", "Arial"])
	heading_font.font_weight = 700
	get_viewport().size_changed.connect(_on_resize)
	_render()

func _on_resize() -> void:
	var should_desktop := size.x >= 950.0
	if should_desktop != desktop:
		_render()

func _style(fill: Color, stroke: Color = LINE, radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = stroke
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _text(parent: Node, value: String, font_size: int, colour: Color = WHITE, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_font_override("font", heading_font if bold else body_font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _gap(parent: BoxContainer, pixels: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = pixels
	parent.add_child(spacer)

func _vertical(parent: Node, space: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", space)
	parent.add_child(v)
	return v

func _horizontal(parent: Node, space: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", space)
	parent.add_child(h)
	return h

func _panel(parent: Node, background: Color = PANEL, radius: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(background, LINE, radius))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	return p

func _button(parent: Node, label: String, kind: String, action: Callable, minimum: float = 48.0) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size.y = minimum
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	var base := PANEL
	var ink := WHITE
	if kind == "primary":
		base = ACCENT
		ink = BG
	elif kind == "ghost":
		base = Color("#11171C")
	elif kind == "selected":
		base = Color("#303B40")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := base
		if state == "hover":
			fill = base.lightened(0.12)
		elif state == "pressed":
			fill = base.darkened(0.14)
		elif state == "disabled":
			fill = Color("#22272A")
		var s := _style(fill, ACCENT if state == "focus" else LINE, 9)
		s.set_content_margin_all(11)
		if state == "focus":
			s.set_border_width_all(2)
		b.add_theme_stylebox_override(state, s)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_focus_color", ink)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_font_override("font", heading_font)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	nav_buttons.clear()

func _render() -> void:
	desktop = size.x >= 950.0
	_clear()
	var background := ColorRect.new()
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shell := HBoxContainer.new()
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if desktop:
		_build_sidebar(shell)

	var column := _vertical(shell, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_topbar(column)
	if not desktop:
		_build_mobile_nav(column)

	var scroll := ScrollContainer.new()
	viewport_scroll = scroll
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var inset := MarginContainer.new()
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := 28 if desktop else 16
	for side in ["left", "right"]:
		inset.add_theme_constant_override("margin_" + side, pad)
	inset.add_theme_constant_override("margin_top", 24)
	inset.add_theme_constant_override("margin_bottom", 32)
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inset)
	stage = _vertical(inset, 18)
	# A scroll child must never dictate the size of the shell.
	inset.custom_minimum_size.x = 0
	stage.custom_minimum_size.x = 0
	_render_stage()

func _build_sidebar(shell: HBoxContainer) -> void:
	var side := _panel(shell, Color("#11161B"), 0)
	side.custom_minimum_size.x = SIDEBAR_WIDTH
	side.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var inner := _vertical(side, 10)
	_text(inner, "LIVING THE DREAM", 17, ACCENT, true)
	_text(inner, "CAREER / DEMO", 11, MUTED)
	_gap(inner, 24)
	for name in ["Overview", "Band", "Songs", "Gigs", "Journal"]:
		_nav(inner, name)
	_gap(inner, 36)
	_text(inner, "PREVIEW BUILD", 11, MUTED)
	_text(inner, "Concept data only. No save changes.", 12, MUTED)

func _build_topbar(column: VBoxContainer) -> void:
	var bar := _panel(column, Color("#101B20"), 0)
	var body := _vertical(bar, 4)
	_text(body, "LIVING THE DREAM  /  CAREER", 11, ACCENT, true)
	header_title = _text(body, "THE LONG WEEKEND", 21 if desktop else 19, WHITE, true)
	_text(body, "YEAR 01  ·  WEEK 06  ·  £1,240 CASH", 12, MUTED)

func _build_mobile_nav(column: VBoxContainer) -> void:
	var bar := _panel(column, Color("#11171C"), 0)
	var nav := _horizontal(bar, 4)
	for name in ["Overview", "Band", "Songs", "Gigs", "Journal"]:
		_nav(nav, name)

func _nav(parent: Node, name: String) -> void:
	var caption := name.to_upper() if desktop else name
	var b := _button(parent, caption, "selected" if active_tab == name else "ghost", func() -> void: _select(name), 46.0)
	b.add_theme_font_size_override("font_size", 12 if not desktop else 14)
	nav_buttons[name] = b

func _select(name: String) -> void:
	active_tab = name
	_render()

func _render_stage() -> void:
	# The proof must first render at the actual viewport width.
	# Single-column content avoids nested horizontal minimum-size propagation
	# that pushed the initial PoC off-screen.
	_text(stage, "CAREER OVERVIEW  /  DESIGN PROOF", 12, ACCENT, true)
	_text(stage, "THE NEXT MOVE IS YOURS.", 29 if desktop else 24, WHITE, true)
	_text(stage, "A working band's next week: rehearsals, transport, a headline gig.", 15, MUTED)

	var hero := _panel(stage, Color("#24353A"), 16)
	var hero_body := _vertical(hero, 10)
	_text(hero_body, "FRIDAY  /  9:00 PM  /  BRISTOL", 12, CYAN, true)
	_text(hero_body, "THE EXCHANGE", 32 if desktop else 27, WHITE, true)
	_text(hero_body, "First headline slot    •    120 capacity", 15, MUTED)
	_text(hero_body, "Six days to tighten the set, arrange transport and get people through the door.", 16)
	_button(hero_body, "PLAN THE SHOW  ›", "primary", func() -> void: _notice("Show planner is not connected in the PoC."), 52)
	_button(hero_body, "VIEW SETLIST", "secondary", func() -> void: _notice("Setlist is not connected in the PoC."))

	_text(stage, "AT A GLANCE", 13, ACCENT, true)
	_stat(stage, "BAND MORALE", "72 / 100", "Steady", CYAN)
	_stat(stage, "SHOW READINESS", "64 / 100", "Needs rehearsal", ACCENT)
	_stat(stage, "LOCAL FOLLOWING", "218", "+26 this week", CYAN)

	var priorities := _panel(stage)
	var priorities_body := _vertical(priorities, 12)
	_text(priorities_body, "THIS WEEK'S PRIORITIES", 13, ACCENT, true)
	_priority(priorities_body, "01", "Finish the second rehearsal", "Improves show readiness")
	_priority(priorities_body, "02", "Confirm the van", "Transport not yet locked")
	_priority(priorities_body, "03", "Promote the headline show", "Ticket interest is building")

	var story := _panel(stage)
	var story_body := _vertical(story, 10)
	_text(story_body, "THE STORY SO FAR", 13, ACCENT, true)
	_text(story_body, "A band with momentum, but nothing guaranteed.", 19, WHITE, true)
	_text(story_body, "Six weeks into the journey. One headline opportunity.", 15, MUTED)
	_button(story_body, "OPEN JOURNAL  ›", "secondary", func() -> void: _select("Journal"))
	feedback = _text(stage, "DESIGN PROTOTYPE  /  SAMPLE DATA  /  SAVES UNCHANGED", 12, MUTED)
	if active_tab != "Overview":
		_notice(active_tab + " selected. Other sections are not part of this PoC.")

func _stat(parent: Node, title: String, value: String, detail: String, hue: Color) -> void:
	var card := _panel(parent)
	var body := _vertical(card, 8)
	_text(body, title, 12, MUTED)
	_text(body, value, 27, WHITE, true)
	_text(body, detail, 14, hue)

func _priority(parent: Node, index: String, name: String, detail: String) -> void:
	var row := _horizontal(parent, 12)
	_text(row, index, 15, ACCENT)
	var content := _vertical(row, 3)
	_text(content, name, 15)
	_text(content, detail, 13, MUTED)

func _notice(message: String) -> void:
	if is_instance_valid(feedback):
		feedback.text = message
