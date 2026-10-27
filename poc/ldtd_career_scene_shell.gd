extends Control
## Sprint S01: isolated world selection and premium career-shell proof.
## All captions and choices are native nodes. Existing image-backed WebP art.
## No user:// access, save writes, real costs or career mutations.

const PHASES := ["day", "dusk", "night"]
const SCENES := ["career", "formation", "songwriting", "tour", "gig", "studio"]
const WORLD: Dictionary = {
	"career": {"heading": "THE LONG ROAD", "summary": "Your band's next chapter starts with a choice.", "moment": "CAREER  /  EARLY DAYS", "photo": "home", "primary": "EXPLORE CAREER", "next": "S01  /  CAREER SHELL"},
	"formation": {"heading": "FIND YOUR PEOPLE", "summary": "Build trust, find a shared sound and earn your first rehearsal.", "moment": "BAND  /  FORMATION", "photo": "formation", "primary": "OPEN THE BAND DESK", "next": "S02  /  FORMATION"},
	"songwriting": {"heading": "FIND THE SOUND", "summary": "An idea begins at a daytime writing table before it meets the studio.", "moment": "SONGS  /  JAM SESSION", "photo": "home", "primary": "OPEN TRANSPORT PROOF", "next": "S03  /  SONGWRITING"},
	"tour": {"heading": "THE NEXT STOP", "summary": "Plot the route, prepare the van and make every mile count.", "moment": "ON THE ROAD  /  PLANNING", "photo": "studio", "primary": "REVIEW TOUR BRIEF", "next": "S04  /  TOUR"},
	"gig": {"heading": "LIGHTS DOWN", "summary": "From daytime load-in to the last encore: one believable show.", "moment": "GIG  /  LIVE SHOW", "photo": "gigs", "primary": "REVIEW SHOW BRIEF", "next": "S05  /  GIG NIGHT"},
	"studio": {"heading": "MAKE IT REAL", "summary": "Real hardware, real decisions. Inputs adjust effort; meters show results.", "moment": "STUDIO  /  REHEARSAL", "photo": "formation", "primary": "OPEN HARDWARE PROOF", "next": "S06  /  STUDIO"}
}
const CREAM := Color("#EFEADF")
const DUSK := Color("#283A40")
const NIGHT := Color("#0E1318")
const GOLD := Color("#DEA54D")
var family: String = "career"
var phase: String = "day"
var _surface: Control
var _scale: float = 1.0
var _status: Label
var _primary: Button
var _scene_buttons: Dictionary = {}
var _phase_buttons: Dictionary = {}
var _preview_status: String = "FIRST-PASS SCENE SHELL  /  NO GAME STATE CHANGES"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resize)
	call_deferred("_render")

func _on_resize() -> void:
	if is_inside_tree():
		call_deferred("_render")

func set_world(next: String) -> void:
	if not WORLD.has(next):
		return
	family = next
	_preview_status = str(WORLD[family]["next"]) + "  /  FIRST-PASS PREVIEW"
	if is_inside_tree():
		call_deferred("_render")

func set_phase(next: String) -> void:
	if not PHASES.has(next):
		return
	phase = next
	if is_inside_tree():
		call_deferred("_render")

func _rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.position = Vector2(x, y)
	c.size = Vector2(maxf(w, 1.0), maxf(h, 1.0))

func _ink() -> Color:
	return Color("#23313A") if phase == "day" else Color("#F2EEE6")

func _soft_ink() -> Color:
	return Color("#53646A") if phase == "day" else Color("#B8C5C7")

func _panel(fill: Color, edge: Color, radius: int, drop: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	if drop:
		s.shadow_color = Color(0, 0, 0, 0.16)
		s.shadow_size = 12
		s.shadow_offset = Vector2(0, 4)
	return s

func _label(parent: Node, name_value: String, text_value: String, size_pt: int, tint: Color) -> Label:
	var l := Label.new()
	l.name = name_value
	l.text = text_value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size_pt)
	l.add_theme_color_override("font_color", tint)
	parent.add_child(l)
	return l

func _button(parent: Node, name_value: String, text_value: String, callback: Callable, selected: bool = false) -> Button:
	var b := Button.new()
	b.name = name_value
	b.text = text_value
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size.y = 48.0
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _panel(GOLD if selected else (Color("#E2D8C8") if phase == "day" else Color("#35444A")), Color("#B6A68B") if phase == "day" else Color("#617077"), 5))
	b.add_theme_stylebox_override("hover", _panel(Color("#F2C270"), GOLD, 5))
	b.add_theme_stylebox_override("pressed", _panel(Color("#D49C44"), GOLD, 5))
	b.add_theme_stylebox_override("focus", _panel(Color.TRANSPARENT, Color("#F3C26A"), 6))
	b.add_theme_color_override("font_color", Color("#253238") if selected or phase == "day" else Color("#EEEAE2"))
	b.add_theme_color_override("font_hover_color", Color("#203038"))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _render() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_scene_buttons.clear()
	_phase_buttons.clear()
	var logical_size: Vector2 = get_viewport_rect().size
	var window: Vector2i = DisplayServer.window_get_size()
	_scale = maxf(float(window.x) / maxf(logical_size.x, 1.0), 0.35)
	var physical_w: float = logical_size.x * _scale
	var physical_h: float = logical_size.y * _scale
	var narrow: bool = physical_w < 780.0

	var background := ColorRect.new()
	background.name = "SceneSweepBackdrop"
	background.color = CREAM if phase == "day" else (DUSK if phase == "dusk" else NIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_surface = Control.new()
	_surface.name = "PhysicalSceneShell"
	_surface.scale = Vector2.ONE / _scale
	add_child(_surface)
	_rect(_surface, 0, 0, physical_w, physical_h)

	var header := Panel.new()
	header.name = "CareerShellHeader"
	header.add_theme_stylebox_override("panel", _panel(Color("#F6F1E9") if phase == "day" else Color("#18252D"), Color("#D7CABA") if phase == "day" else Color("#55656D"), 10, true))
	_surface.add_child(header)
	_rect(header, 14, 12, physical_w - 28, 84 if narrow else 75)
	var brand: Label = _label(header, "PlayerFacingTitle", "LIVIN’ THE DREAM", 23 if narrow else 29, _ink())
	_rect(brand, 17, 13, physical_w - (36 if narrow else 330), 34)
	var cap: Label = _label(header, "CareerStage", "ONE BAND. A THOUSAND SMALL DECISIONS.", 12, _soft_ink())
	_rect(cap, 18, 51, physical_w - 38, 23)
	var marker := Panel.new()
	marker.name = "TimeOfDayBadge"
	marker.add_theme_stylebox_override("panel", _panel(Color("#E7D6B8") if phase == "day" else Color("#263640"), Color("#CCA866"), 5))
	header.add_child(marker)
	_rect(marker, physical_w - 213, 15, 183, 43)
	if not narrow:
		var clock: Label = _label(marker, "SimulatedPhase", phase.to_upper() + "  /  DAY 12", 14, _ink())
		_rect(clock, 11, 10, 162, 27)
	else:
		marker.hide()

	var nav_top: float = 104 if narrow else 95
	var nav_rows: int = 2 if narrow else 1
	var nav_cols: int = 3 if narrow else 6
	var nav_width: float = (physical_w - 28 - float(nav_cols - 1) * 6.0) / float(nav_cols)
	for i in range(SCENES.size()):
		var choice: String = SCENES[i]
		var b: Button = _button(_surface, "Scene" + choice.capitalize(), choice.to_upper(), func() -> void: set_world(choice), choice == family)
		var row: int = int(i / nav_cols)
		var col_idx: int = i % nav_cols
		_rect(b, 14 + col_idx * (nav_width + 6), nav_top + row * 51, nav_width, 46)
		_scene_buttons[choice] = b

	var phase_top: float = nav_top + nav_rows * 51 + 7
	var chip_width: float = 89.0
	for i in range(PHASES.size()):
		var next_phase: String = PHASES[i]
		var phase_button: Button = _button(_surface, "World" + next_phase.capitalize(), next_phase.to_upper(), func() -> void: set_phase(next_phase), next_phase == phase)
		_rect(phase_button, 14 + i * (chip_width + 7), phase_top, chip_width, 46)
		_phase_buttons[next_phase] = phase_button

	var content_top: float = phase_top + 56
	var dock_h: float = 90
	var scroll := ScrollContainer.new()
	scroll.name = "SceneSweepScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_surface.add_child(scroll)
	_rect(scroll, 0, content_top, physical_w, maxf(190.0, physical_h - content_top - dock_h))
	var scene_card := Control.new()
	scroll.add_child(scene_card)
	_rect(scene_card, 0, 0, physical_w, 570 if narrow else 548)
	scene_card.custom_minimum_size = Vector2(physical_w, 570 if narrow else 548)

	var p: Dictionary = WORLD[family]
	var head: Label = _label(scene_card, "SceneTitle", str(p["heading"]), 29 if narrow else 36, _ink())
	_rect(head, 21, 16, physical_w - 44, 49)
	var eyebrow: Label = _label(scene_card, "SceneEyebrow", str(p["moment"]), 13, GOLD.darkened(0.35) if phase == "day" else GOLD)
	_rect(eyebrow, 23, 72, physical_w - 48, 25)
	var copy: Label = _label(scene_card, "SceneSummary", str(p["summary"]), 16, _soft_ink())
	_rect(copy, 23, 106, physical_w - 50, 57)

	var photography := Panel.new()
	photography.name = "SceneNativePhotoFrame"
	photography.clip_contents = true
	photography.add_theme_stylebox_override("panel", _panel(Color("#323D40"), Color("#D1B68B") if phase == "day" else Color("#647478"), 9, true))
	scene_card.add_child(photography)
	var photo_height: float = 248.0 if narrow else 306.0
	var photo_width: float = physical_w - 42.0
	_rect(photography, 21, 172, photo_width, photo_height)
	var photo := TextureRect.new()
	photo.name = "RepoBackedScenePhotography"
	photo.texture = load("res://Art/Backgrounds/shared/" + str(p["photo"]) + ".webp")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photography.add_child(photo)
	_rect(photo, 3, 3, photo_width - 6, photo_height - 6)
	var photo_label := Panel.new()
	photo_label.name = "PhotoSourceBadge"
	photo_label.add_theme_stylebox_override("panel", _panel(Color(0.07, 0.12, 0.16, 0.88), Color("#A6A49A"), 4))
	photography.add_child(photo_label)
	_rect(photo_label, 16, photo_height - 45, minf(photo_width - 28, 366), 34)
	var explanation: Label = _label(photo_label, "PhotoProvenance", "REPO PHOTO  /  ART TARGET STILL UNDER REVIEW", 11, Color("#F2EFE7"))
	_rect(explanation, 8, 7, minf(photo_width - 42, 344), 23)

	var info_label := _label(scene_card, "SceneProvenance", str(p["next"]) + "  /  ISOLATED FIRST PASS", 14, _soft_ink())
	_rect(info_label, 24, 180 + photo_height, physical_w - 48, 30)
	var info_label2 := _label(scene_card, "SceneArtGate", "MATERIAL TARGET: NOT YET APPROVED IN GODOT", 13, GOLD.darkened(0.24) if phase == "day" else GOLD)
	_rect(info_label2, 24, 215 + photo_height, physical_w - 48, 30)

	var footer := Panel.new()
	footer.name = "SceneActionDock"
	footer.add_theme_stylebox_override("panel", _panel(Color("#F4EDE2") if phase == "day" else Color("#17232B"), Color("#D7C9B2") if phase == "day" else Color("#5A6870"), 7, true))
	_surface.add_child(footer)
	_rect(footer, 14, physical_h - dock_h + 2, physical_w - 28, dock_h - 12)
	_primary = _button(footer, "ScenePrimaryAction", str(p["primary"]), func() -> void: _open_preview(), true)
	_rect(_primary, 12, 11, physical_w - 52, 48)
	_status = _label(footer, "SceneStatus", _preview_status, 11, _soft_ink())
	_rect(_status, 14, 61, physical_w - 64, 18)

func _open_preview() -> void:
	var dest := ""
	if family == "songwriting":
		dest = "res://poc/premium_transport_proof.tscn"
	elif family == "studio":
		dest = "res://poc/premium_mixer_module_lab.tscn"
	if dest.is_empty():
		_status.text = "DESIGN FIRST PASS  /  " + str(WORLD[family]["next"]) + " PENDING"
		return
	if not ResourceLoader.exists(dest):
		_status.text = "SCENE NOT INCLUDED ON THIS BRANCH  /  " + dest
		return
	var result: Error = get_tree().change_scene_to_file(dest)
	if result != OK:
		_status.text = "FAILED TO OPEN SCENE  /  " + dest
