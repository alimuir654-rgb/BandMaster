extends Control

# Public-facing title is intentionally separate from the internal project name.
const DISPLAY_TITLE := "LIVIN' THE DREAM"
const BG := Color("#101216")
const PANEL := Color("#1A1E24")
const AMBER := Color("#F0B44D")
const WHITE := Color("#F2F0E9")
const MUTED := Color("#9BA5B2")
const SAVE_PATH := "user://tour_save.json"
const BAND_PATH := "user://band_profile.json"
const PROFILE_PATH := "user://player_profile.json"

var message_label: Label
var profile_name := "Roadie"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_profile()
	_build_menu()

func _load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		profile_name = str(parsed.get("display_name", "Roadie")).strip_edges().substr(0, 32)
		if profile_name.is_empty():
			profile_name = "Roadie"

func _save_profile() -> bool:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"display_name": profile_name}, "\t"))
	file.close()
	return true

func _build_menu() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# Contrasting bands give this screen an atmospheric poster-like treatment,
	# without forcing a particular future background image into the game.
	var top_band := ColorRect.new()
	top_band.color = Color("#25201C")
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_band)
	top_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_band.offset_bottom = 280

	var scroll := ScrollContainer.new()
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 45)
	margin.add_theme_constant_override("margin_bottom", 42)
	scroll.add_child(margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	_label(column, "A BRITISH MUSIC INDUSTRY SIM", 14, AMBER)
	_label(column, DISPLAY_TITLE, 42, WHITE)
	_label(column, "A band. A van. A plan. How far can you go?", 17, MUTED)
	column.add_child(HSeparator.new())
	_label(column, "YOUR CAREER", 18, AMBER)

	var continue_button := _button(column, "CONTINUE CAREER", _continue_game, true)
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)
	_button(column, "START A NEW BAND", _new_game, false)
	_label(column, "Local career saves stay on this device.", 13, MUTED)

	column.add_child(HSeparator.new())
	_label(column, "YOUR CORNER OF THE SCENE", 18, AMBER)
	_button(column, "PLAYER PROFILE", _show_profile, false)
	_button(column, "FRIENDS & CONNECTIONS", func() -> void: _unavailable("Friends and connections"), false)
	_button(column, "LEADERBOARDS", func() -> void: _unavailable("Online leaderboards"), false)
	_button(column, "INVITE A SUPPORT BAND", func() -> void: _unavailable("Support-band invitations"), false)
	_button(column, "JOIN ANOTHER BAND", func() -> void: _unavailable("Collaborative bands"), false)

	column.add_child(HSeparator.new())
	_button(column, "QUIT", _quit_game, false)
	message_label = _label(column, "Offline prototype // British grassroots career", 13, MUTED)

func _show_profile() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "YOUR PROFILE"
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	dialog.add_child(body)

	var name_title := _label(body, "Display name (local only)", 16, WHITE)
	name_title.custom_minimum_size.x = 430
	var name_edit := LineEdit.new()
	name_edit.text = profile_name
	name_edit.max_length = 32
	name_edit.custom_minimum_size.y = 52
	body.add_child(name_edit)

	var band_data := _read_json(BAND_PATH)
	var career_data := _read_json(SAVE_PATH)
	var band_name := str(band_data.get("name", "No band yet"))
	if career_data.has("band") and career_data["band"] is Dictionary:
		band_name = str(career_data["band"].get("name", band_name))
	_label(body, "BAND: %s" % band_name, 15, WHITE)
	_label(body, "CAREER DAY: %s" % str(career_data.get("tour_day", 1)), 15, MUTED)
	_label(body, "REPUTATION: %s" % str(career_data.get("reputation", 0)), 15, MUTED)
	_label(body, "Online profiles will be optional in a later release.", 13, MUTED)

	dialog.confirmed.connect(func() -> void:
		var candidate := name_edit.text.strip_edges()
		if not candidate.is_empty():
			profile_name = candidate
			if not _save_profile():
				message_label.text = "Could not save local profile"
	)
	add_child(dialog)
	dialog.popup_centered()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}

func _unavailable(feature: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = feature
	dialog.dialog_text = "%s is planned, but is not connected yet. Your offline career remains fully playable." % feature
	add_child(dialog)
	dialog.popup_centered()

func _continue_game() -> void:
	_go_to("res://tour_intro.tscn")

func _new_game() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Start a new band?"
	dialog.dialog_text = "This will replace your current band and career save. Your player profile will be kept. Continue?"
	dialog.confirmed.connect(_confirm_new_game)
	add_child(dialog)
	dialog.popup_centered()

func _confirm_new_game() -> void:
	for path in [SAVE_PATH, BAND_PATH]:
		if FileAccess.file_exists(path):
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if error != OK:
				message_label.text = "Could not remove previous career: " + path
				return
	_go_to("res://band_builder.tscn")

func _quit_game() -> void:
	get_tree().quit()

func _go_to(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		message_label.text = "Could not open scene: " + path

func _label(parent: Control, value: String, font_size: int, colour: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", colour)
	parent.add_child(result)
	return result

func _button(parent: Control, label_text: String, action: Callable, primary: bool) -> Button:
	var result := Button.new()
	result.text = label_text
	result.custom_minimum_size.y = 62
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := StyleBoxFlat.new()
	normal.bg_color = AMBER if primary else Color("#303B48")
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(10)
	var hover := normal.duplicate()
	hover.bg_color = Color("#FFC766") if primary else Color("#455365")
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_color_override("font_color", BG if primary else WHITE)
	result.add_theme_color_override("font_hover_color", BG if primary else WHITE)
	result.pressed.connect(action)
	parent.add_child(result)
	return result
