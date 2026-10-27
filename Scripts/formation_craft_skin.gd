extends RefCounted
## Livin' The Dream — Formation-specific stationery visual skins.
## Original 22 generated raster assets + NATIVE Godot button text and actions.
## Purpose-built role families; do not treat this as global generic button theme.
const TEXTURES := "res://Art/UI/FormationCraft/"
const TYPES := ["candidate", "activity", "tab", "commit"]
const STATES := ["idle", "hover", "pressed", "chosen", "disabled"]
const SKIN_MARGIN := {"candidate": 26, "activity": 23, "tab": 19, "commit": 31}

static func _skin(kind: String, state: String) -> StyleBoxTexture:
	var path: String = TEXTURES + kind + "_" + state + ".png"
	var image: Texture2D = load(path) as Texture2D
	if image == null:
		push_error("Missing original formation stationery texture: " + path)
		return null
	var box := StyleBoxTexture.new()
	box.texture = image
	var edge: float = float(SKIN_MARGIN[kind])
	box.texture_margin_left = edge
	box.texture_margin_right = edge
	box.texture_margin_top = 15.0
	box.texture_margin_bottom = 15.0
	return box

static func apply_to(button: Button, kind: String, selected: bool, physical_min: float = 50.0) -> void:
	if not TYPES.has(kind):
		push_error("Unknown formation stationery class: " + kind)
		return
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = maxf(physical_min, 48.0)
	# Native editable ink is deliberately bolder than the distressed print
	# underneath: previous 390px Godot pixels made auditions and DAY tabs
	# read like illegible grey stamps. This is not text baked into sprites.
	var type_size: int = 18 if kind == "candidate" or kind == "commit" else (17 if kind == "activity" else 17)
	button.add_theme_font_size_override("font_size", type_size)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_color_override("font_outline_color", Color("#FFF6E5"))
	button.add_theme_color_override("font_color", Color("#152B31"))
	button.add_theme_color_override("font_hover_color", Color("#112A32"))
	button.add_theme_color_override("font_pressed_color", Color("#0F262C"))
	button.add_theme_color_override("font_disabled_color", Color("#58605E"))
	button.add_theme_color_override("font_focus_color", Color("#0F3440"))
	button.add_theme_stylebox_override("normal", _skin(kind, "chosen" if selected else "idle"))
	button.add_theme_stylebox_override("hover", _skin(kind, "hover"))
	button.add_theme_stylebox_override("pressed", _skin(kind, "pressed"))
	button.add_theme_stylebox_override("disabled", _skin(kind, "disabled"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#155D70")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(7)
	button.add_theme_stylebox_override("focus", focus)

static func validate_source() -> bool:
	for kind in TYPES:
		for state in STATES:
			var path: String = TEXTURES + kind + "_" + state + ".png"
			if not ResourceLoader.exists(path):
				return false
	for file in ["rehearsal_desk.png", "rehearsal_notebook.png"]:
		if not ResourceLoader.exists(TEXTURES + file):
			return false
	return true
