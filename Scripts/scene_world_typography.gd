extends RefCounted
## Sprint 08 production-feasibility typography contract. OFL licences in Art/Fonts.
## Three font families, five semantic roles. Native Godot text; no baked UI copy.
const BARLOW := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
const PLEX_SANS := "res://Art/Fonts/IBMPlexSans-Variable.ttf"
const PLEX_MONO := "res://Art/Fonts/IBMPlexMono-Regular.ttf"
const ROLE_SIZES := {"display": 34, "module": 21, "body": 16, "caption": 14, "technical": 15}

static func font_path(role: String) -> String:
	if ["display", "module"].has(role):
		return BARLOW
	if role == "technical":
		return PLEX_MONO
	return PLEX_SANS

static func font_for(role: String) -> Font:
	var path := font_path(role)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Font

static func apply(label: Label, role: String, scale: float = 1.0) -> void:
	var font := font_for(role)
	if font != null:
		label.add_theme_font_override("font", font)
	var size := int(ROLE_SIZES.get(role, ROLE_SIZES["body"]))
	label.add_theme_font_size_override("font_size", maxi(12, roundi(float(size) * scale)))
