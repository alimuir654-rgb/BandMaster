extends Control
const UI = preload("res://Scripts/ui_theme.gd")

# Public-facing title is intentionally separate from the internal project name.
const DISPLAY_TITLE := "LIVING THE DREAM"
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

const VERSION_LABEL := "EARLY ACCESS  /  UK INDIE SCENE"
const LAUNCH_ART := "res://Art/uk_street_banner.svg"

func _build_menu() -> void:
	_build_screen(false)


func _build_screen(community: bool) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := ColorRect.new()
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The title screen now belongs to the same photographic British music world
	# as the Band House, rather than the old almost-opaque SVG placeholder.
	var is_wide := get_viewport_rect().size.x >= 960.0
	var launch_photo := "res://Art/Photography/approved/world_home_wide.webp" if is_wide else "res://Art/Photography/approved/world_home_portrait.webp"
	if not ResourceLoader.exists(launch_photo):
		launch_photo = LAUNCH_ART
	if ResourceLoader.exists(launch_photo):
		var backdrop := TextureRect.new()
		backdrop.name = "TitleCinematicPhoto"
		backdrop.texture = load(launch_photo)
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var veil := ColorRect.new()
	veil.color = Color(0.02,0.035,0.05,0.38)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var lower := ColorRect.new()
	lower.color = Color(0.02,0.035,0.05,0.58)
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower)
	lower.anchor_top = 0.63
	lower.anchor_bottom = 1.0
	lower.anchor_right = 1.0

	var scroll := ScrollContainer.new()
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.custom_minimum_size.y = get_viewport_rect().size.y
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",24 if not is_wide else 46)
	margin.add_theme_constant_override("margin_right",24 if not is_wide else int(get_viewport_rect().size.x*0.43))
	margin.add_theme_constant_override("margin_top",28)
	margin.add_theme_constant_override("margin_bottom",28)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)

	_label(column,"THE UK GRASSROOTS MUSIC GAME",14,AMBER)
	var title := _label(column,DISPLAY_TITLE,44,WHITE)
	title.name = "TitleHeroHeading"
	_label(column,"Build the lineup. Find your sound. Make a scene.",17,WHITE)

	var breathing_room := Control.new()
	breathing_room.name = "TitlePhotographicBreathingRoom"
	breathing_room.custom_minimum_size.y = 50 if community else 130
	breathing_room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(breathing_room)

	var dock := PanelContainer.new()
	dock.name = "TitleActionDock"
	var dock_style := UI.flat(Color(0.035,0.06,0.085,0.90),9)
	dock_style.set_content_margin_all(17)
	dock_style.border_color = AMBER
	dock_style.border_width_top = 2
	dock.add_theme_stylebox_override("panel",dock_style)
	column.add_child(dock)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation",10)
	dock.add_child(actions)

	if community:
		_label(actions,"YOUR CORNER OF THE SCENE",18,AMBER)
		_button(actions,"PLAYER PROFILE",_show_profile,true)
		_button(actions,"FRIENDS & CONNECTIONS",func() -> void: _unavailable("Friends and connections"),false)
		_button(actions,"COMPARE SCORES",func() -> void: _unavailable("Online leaderboards"),false)
		_button(actions,"INVITE A SUPPORT BAND",func() -> void: _unavailable("Support-band invitations"),false)
		_button(actions,"JOIN ANOTHER BAND",func() -> void: _unavailable("Collaborative bands"),false)
		_button(actions,"‹  BACK TO HOME",func() -> void: _build_screen(false),false)
	else:
		_label(actions,"YOUR NEXT CHAPTER",18,AMBER)
		var has_save := FileAccess.file_exists(SAVE_PATH)
		var primary_label := "CONTINUE CAREER  ›" if has_save else "START A NEW BAND  ›"
		var primary_action: Callable = _continue_game if has_save else _new_game
		_button(actions,primary_label,primary_action,true)
		if has_save:
			_button(actions,"START A NEW BAND",_new_game,false)
		_button(actions,"COMMUNITY & PROFILE",func() -> void: _build_screen(true),false)
		_button(actions,"QUIT",_quit_game,false)

	message_label = _label(actions,VERSION_LABEL+"  /  UK GRASSROOTS",13,MUTED)
	_label(actions,"Offline careers stay on this device.",13,MUTED)


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
	var saved: Dictionary = _read_json(SAVE_PATH)
	if str(saved.get("current_event","")) == "aftershow" and str(saved.get("pending_next","")).is_empty():
		_go_to("res://Scenes/CareerHub.tscn")
	else:
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
	# Share the same focus, hover, pressed and disabled states as the in-game actions.
	var result := UI.button(label_text, primary)
	result.custom_minimum_size.y = 56
	result.pressed.connect(action)
	parent.add_child(result)
	return result
