extends Control

const BG := Color("#101216")
const PANEL := Color("#1A1E24")
const AMBER := Color("#F0B44D")
const WHITE := Color("#F2F0E9")
const MUTED := Color("#9BA5B2")
const SAVE_PATH := "user://tour_save.json"
const BAND_PATH := "user://band_profile.json"

var message_label: Label

func _ready() -> void:
	_build_menu()

func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	_add_label(column, "ROADIE // MANAGEMENT SYSTEM", 14, AMBER)
	_add_label(column, "BANDMASTER", 38, WHITE)
	_add_label(column, "Bad decisions. Better stories.", 16, MUTED)
	column.add_child(HSeparator.new())

	var continue_button := _add_button(column, "CONTINUE TOUR", _continue_game)
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)
	_add_button(column, "NEW BAND / NEW GAME", _new_game)
	_add_button(column, "QUIT", _quit_game)

	message_label = _add_label(column, "", 13, MUTED)
	if continue_button.disabled:
		message_label.text = "No saved tour found. Start a new band."
	else:
		message_label.text = "Saved tour detected."

func _continue_game() -> void:
	_go_to("res://tour_intro.tscn")

func _new_game() -> void:
	# Deleting both files means the band builder creates a genuinely new tour.
	# The user is warned because this overwrites previous progress.
	var dialog := ConfirmationDialog.new()
	dialog.title = "Start a new band?"
	dialog.dialog_text = "This deletes your current band and tour save. Continue?"
	dialog.confirmed.connect(_confirm_new_game)
	add_child(dialog)
	dialog.popup_centered()

func _confirm_new_game() -> void:
	for path in [SAVE_PATH, BAND_PATH]:
		if FileAccess.file_exists(path):
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if error != OK:
				message_label.text = "Could not delete save: " + path
				return
	_go_to("res://band_builder.tscn")

func _quit_game() -> void:
	get_tree().quit()

func _go_to(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		message_label.text = "Scene not found: " + path

func _add_label(parent: Control, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _add_button(parent: Control, value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 54
	button.pressed.connect(action)
	parent.add_child(button)
	return button
