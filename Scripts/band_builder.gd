extends Control

const BG := Color("#101216")
const PANEL := Color("#1A1E24")
const AMBER := Color("#F0B44D")
const WHITE := Color("#F2F0E9")
const MUTED := Color("#9BA5B2")
const GENRES := ["Post-punk", "Indie rock", "Punk", "Britpop", "Shoegaze", "Synth-pop", "Garage rock", "Goth", "Prog rock", "Experimental"]
const INFLUENCES := ["Joy Division", "The Velvet Underground", "The Smiths", "The Clash", "Talking Heads", "Sonic Youth", "The Cure", "New Order", "Pixies", "Kraftwerk", "ABBA", "Black Sabbath"]
const ROLES := ["Singer", "Guitarist", "Bassist", "Drummer", "Keyboardist", "Multi-instrumentalist"]
const TRAITS := ["Control freak", "Unreliable genius", "Peacemaker", "Chaos agent", "Attention seeker", "Cynic", "Perfectionist", "People pleaser", "Secret softie", "Chronic liar", "Money obsessed"]
const IDENTITIES := ["Woman", "Man", "Non-binary", "Self-describe", "Prefer not to say"]
const DEFAULT_NAMES := ["Alex", "Mick", "Sam", "Jo", "Kit", "Fran"]
const DEFAULT_TRAITS := ["Control freak", "Unreliable genius", "Peacemaker", "Chaos agent", "Perfectionist", "Cynic"]

var name_field: LineEdit
var genre_field: OptionButton
var influence_field: OptionButton
var member_container: VBoxContainer
var status_label: Label
var count_label: Label
var member_rows: Array[Dictionary] = []
var steps: Array[VBoxContainer] = []
var summary_label: Label
var current_step := 0
var form_scroll: ScrollContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	form_scroll = ScrollContainer.new()
	form_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	form_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(form_scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_scroll.add_child(margin)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	_label(page, "ROADIE // BAND FORMATION", 14, AMBER)
	_label(page, "MAKE SOME NOISE", 30, WHITE)
	_label(page, "Start in the practice room. Fame comes later, if at all.", 15, MUTED)
	page.add_child(HSeparator.new())
	var identity_page := _make_step(page)
	_label(identity_page, "01 / BAND IDENTITY", 20, AMBER)
	_label(identity_page, "Band name", 16, WHITE)
	name_field = LineEdit.new()
	name_field.text = "The Feedback"
	name_field.custom_minimum_size.y = 54
	identity_page.add_child(name_field)
	_label(identity_page, "Genre", 16, WHITE)
	genre_field = _option(GENRES)
	identity_page.add_child(genre_field)
	_label(identity_page, "Primary influence", 16, WHITE)
	influence_field = _option(INFLUENCES)
	identity_page.add_child(influence_field)
	_button(identity_page, "NEXT / BUILD YOUR LINE-UP  >", func() -> void: _show_step(1))

	var personnel_page := _make_step(page)
	_label(personnel_page, "02 / PERSONNEL", 20, AMBER)
	_label(personnel_page, "Choose 2–6 musicians. Roles can overlap; personalities have consequences.", 15, MUTED)
	count_label = _label(personnel_page, "", 14, AMBER)
	member_container = VBoxContainer.new()
	member_container.add_theme_constant_override("separation", 14)
	personnel_page.add_child(member_container)
	_button(personnel_page, "+ ADD MUSICIAN", _add_member)
	_button(personnel_page, "- REMOVE LAST", _remove_member)
	for i in range(4):
		_add_member()
	_button(personnel_page, "<  BACK TO IDENTITY", func() -> void: _show_step(0))
	_button(personnel_page, "NEXT / REVIEW BAND  >", func() -> void: _show_step(2))

	var review_page := _make_step(page)
	_label(review_page, "03 / READY TO REHEARSE", 20, AMBER)
	_label(review_page, "Review your line-up before creating a new career.", 15, MUTED)
	summary_label = _label(review_page, "", 17, WHITE)
	_button(review_page, "<  EDIT MUSICIANS", func() -> void: _show_step(1))
	_button(review_page, "CREATE BAND / START REHEARSALS  >", _create_band)
	status_label = _label(review_page, "AWAITING BAND REGISTRATION", 14, MUTED)
	_show_step(0)


func _make_step(parent: VBoxContainer) -> VBoxContainer:
	var step := VBoxContainer.new()
	step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step.add_theme_constant_override("separation", 12)
	parent.add_child(step)
	steps.append(step)
	return step


func _show_step(index: int) -> void:
	current_step = clampi(index, 0, steps.size() - 1)
	for i in range(steps.size()):
		steps[i].visible = i == current_step
	if current_step == 2:
		var names: PackedStringArray = []
		for row in member_rows:
			names.append(row["name"].text.strip_edges() + " — " + _selected(row["role"]))
		summary_label.text = "BAND: %s\nGENRE: %s\nINFLUENCE: %s\n\n%d MUSICIANS\n%s" % [
			name_field.text.strip_edges(), _selected(genre_field),
			_selected(influence_field), member_rows.size(), "\n".join(names)
		]
	form_scroll.scroll_vertical = 0


func _add_member() -> void:
	if member_rows.size() >= 6:
		return
	var index := member_rows.size()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	member_container.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	_label(content, "MUSICIAN %02d" % (index + 1), 13, AMBER)
	var fields := GridContainer.new()
	fields.columns = 1
	fields.add_theme_constant_override("h_separation", 16)
	fields.add_theme_constant_override("v_separation", 8)
	content.add_child(fields)
	var person_name := LineEdit.new()
	person_name.text = DEFAULT_NAMES[index]
	person_name.placeholder_text = "Name"
	person_name.custom_minimum_size.y = 52
	fields.add_child(person_name)
	var role := _option(ROLES)
	role.select(index)
	fields.add_child(role)
	var identity := _option(IDENTITIES)
	identity.select(4)
	fields.add_child(identity)
	var trait_field := _option(TRAITS)
	trait_field.select(TRAITS.find(DEFAULT_TRAITS[index]))
	fields.add_child(trait_field)
	var descriptor := LineEdit.new()
	descriptor.custom_minimum_size.y = 52
	descriptor.placeholder_text = "Optional identity / pronouns / backstory note"
	content.add_child(descriptor)
	member_rows.append({"panel": panel, "name": person_name, "role": role, "identity": identity, "trait": trait_field, "note": descriptor})
	_update_count()

func _remove_member() -> void:
	if member_rows.size() <= 2:
		return
	var row: Dictionary = member_rows.pop_back()
	row["panel"].queue_free()
	_update_count()

func _update_count() -> void:
	count_label.text = "%d MEMBERS // MIN 2 / MAX 6" % member_rows.size()

func _create_band() -> void:
	var band_name := name_field.text.strip_edges()
	if band_name.is_empty():
		status_label.text = "ENTER A BAND NAME FIRST"
		return
	var members: Array[Dictionary] = []
	for i in range(member_rows.size()):
		var row: Dictionary = member_rows[i]
		var person_name: String = row["name"].text.strip_edges()
		if person_name.is_empty():
			status_label.text = "EVERY MUSICIAN NEEDS A NAME"
			return
		members.append({
			"id": i,
			"name": person_name,
			"role": _selected(row["role"]),
			"gender": _selected(row["identity"]),
			"note": row["note"].text.strip_edges(),
			"trait": _selected(row["trait"]),
			"morale": 55,
			"loyalty": 60,
			"skill": 45,
			"fatigue": 5
		})
	var new_band := {
		"name": band_name,
		"genre": _selected(genre_field),
		"influence": _selected(influence_field),
		"members": members
	}
	var file := FileAccess.open("user://band_profile.json", FileAccess.WRITE)
	if file == null:
		status_label.text = "COULD NOT WRITE BAND PROFILE"
		return
	file.store_string(JSON.stringify(new_band, "\t"))
	file.close()
	# A newly created band always begins a fresh career.
	if FileAccess.file_exists("user://tour_save.json"):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path("user://tour_save.json"))
		if error != OK:
			status_label.text = "COULD NOT RESET OLD TOUR SAVE"
			return
	var change_error := get_tree().change_scene_to_file("res://tour_intro.tscn")
	if change_error != OK:
		status_label.text = "TOUR SCENE NOT FOUND"

func _selected(button: OptionButton) -> String:
	return button.get_item_text(button.selected)

func _option(items: Array) -> OptionButton:
	var button := OptionButton.new()
	for item in items:
		button.add_item(str(item))
	button.custom_minimum_size.y = 54
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _label(parent: Control, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, value: String, action: Callable) -> void:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 56
	button.pressed.connect(action)
	parent.add_child(button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(7)
	style.set_content_margin_all(12)
	return style
