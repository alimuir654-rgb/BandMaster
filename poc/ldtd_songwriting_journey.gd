extends Control
## S03: isolated, genuinely playable three-session songwriting notebook.
## Real Practice.compose resolver on deep-copied local state; never touches user://.
## Actual source-photographed DAY room, Lab07 transport + sampler pads, Lab08.4 rotary.
const Model = preload("res://Scripts/ldtd_songwriting_preview.gd")
const Pad = preload("res://Scripts/ldtd_songwriting_pad.gd")
const Transport = preload("res://Scripts/premium_transport_key.gd")
const Rotary = preload("res://Art/References/PremiumHardware/Lab08_4_FixOnly/bandmaster_premium_dashboard_poc/studio_control.gd")
const Craft = preload("res://Scripts/formation_craft_skin.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const PHASES := ["day", "dusk", "night"]
const FONT_DISPLAY := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
const FONT_BODY := "res://Art/Fonts/IBMPlexSans-Variable.ttf"
const FONT_NUMBERS := "res://Art/Fonts/IBMPlexMono-Regular.ttf"
const ROOM := "res://Art/Photography/Formation/daylight_music_room_pexels.webp"
const CORK := "res://Art/Photography/Formation/corkboard_day_pexels.webp"
const PAPER := "res://Art/UI/FormationCraft/rehearsal_notebook.png"
const INK := Color("#24353A")
const CREAM := Color("#F7F0E2")

var local_state: Dictionary = {}
var phase: String = "day"
var title: String = "LATE TRAIN"
var idea: String = "Lyric"
var form: String = "Verse / Chorus"
var leader_index: int = 0
var stage: String = "editing"
var commits: int = 0
var arrangement_focus: float = 55.0
var transport_armed: bool = false
var last_message: String = "A writing session takes one day. Three sessions complete an original."
var _surface: Control
var _scale: float = 1.0
var _primary: Button
var _status: Label
var _stats: Label
var _title_input: LineEdit
var _rotary: Control
var _transport: TextureButton
var _choice_buttons: Dictionary = {}
var _render_pending: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	local_state = Model.sample_state()
	resized.connect(_on_resize)
	call_deferred("_render")

func _on_resize() -> void:
	if is_inside_tree() and not _render_pending:
		_render_pending = true
		call_deferred("_render")

func set_phase(next: String) -> void:
	if PHASES.has(next):
		phase = next
		call_deferred("_render")

func set_title(next: String) -> void:
	title = next.substr(0, 48)
	if is_instance_valid(_primary) and stage == "editing":
		_primary.disabled = not bool(session_preview().get("ok", false))

func choose_idea(next: String) -> void:
	if stage == "editing" and Workshop.IDEAS.has(next):
		idea = next
		call_deferred("_render")

func choose_form(next: String) -> void:
	if stage == "editing" and Workshop.FORMS.has(next):
		form = next
		call_deferred("_render")

func choose_leader(index: int) -> void:
	var roster: Array = local_state.get("members", [])
	if stage == "editing" and index >= 0 and index < roster.size():
		leader_index = index
		call_deferred("_render")

func session_preview() -> Dictionary:
	if stage != "editing":
		return {"ok":false, "message":"This original is finished."}
	return Model.simulate(local_state, idea, form, title.strip_edges(), leader_index)

func commit_session() -> void:
	if stage != "editing":
		return
	var result: Dictionary = session_preview()
	if not bool(result.get("ok", false)):
		last_message = str(result.get("message", "Session unavailable."))
		if is_instance_valid(_status):
			_status.text = last_message
		return
	# The resolver returns a NEW dictionary, never modifies the input.
	local_state = result["state"]
	commits += 1
	last_message = str(result.get("message", "Session completed."))
	transport_armed = false
	if bool(result.get("finished", false)):
		stage = "finished"
		phase = "dusk"
	call_deferred("_render")

func _on_transport_armed(armed: bool) -> void:
	transport_armed = armed
	if is_instance_valid(_status):
		_status.text = "TRANSPORT ARMED / rehearsal preview only" if armed else last_message

func _on_focus_changed(level: float) -> void:
	arrangement_focus = level
	var label: Label = find_child("ArrangementTempoReadout", true, false) as Label
	if label != null:
		label.text = "ARRANGEMENT SKETCH  /  %d BPM" % int(round(70.0 + level * 0.9))

func _return_to_gallery() -> void:
	var dest := "res://poc/ldtd_career_scene_shell.tscn"
	if ResourceLoader.exists(dest):
		get_tree().change_scene_to_file(dest)

func _rect(node: Control, x: float, y: float, width: float, height: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(maxf(width, 1.0), maxf(height, 1.0))

func _font(path: String) -> Font:
	return load(path) as Font if ResourceLoader.exists(path) else null

func _label(parent: Node, node_name: String, content: String, pt: int, tint: Color, role: String = "body") -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = content
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.add_theme_font_size_override("font_size", pt)
	l.add_theme_color_override("font_color", tint)
	var font_path: String = FONT_DISPLAY if role == "display" else (FONT_NUMBERS if role == "numbers" else FONT_BODY)
	var f: Font = _font(font_path)
	if f != null:
		l.add_theme_font_override("font", f)
	parent.add_child(l)
	return l

func _panel(fill: Color, edge: Color, radius: int = 5) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0.05, 0.04, 0.03, 0.24)
	sb.shadow_size = 9
	sb.shadow_offset = Vector2(0, 4)
	return sb

func _pad(parent: Control, id: String, caption: String, chosen: bool, action: Callable,
		x: float, y: float, width: float, height: float) -> TextureButton:
	var pad: TextureButton = Pad.new()
	pad.name = id
	pad.choice_id = id
	pad.caption = caption
	pad.selected = chosen
	pad.disabled = stage == "finished"
	parent.add_child(pad)
	_rect(pad, x, y, width, height)
	pad.pad_chosen.connect(func(_key: String) -> void: action.call())
	_choice_buttons[id] = pad
	return pad

func _render() -> void:
	_render_pending = false
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_choice_buttons.clear()
	var vp: Vector2 = get_viewport_rect().size
	_scale = maxf(float(DisplayServer.window_get_size().x) / maxf(vp.x, 1.0), 0.35)
	var w: float = vp.x * _scale
	var h: float = vp.y * _scale
	var narrow: bool = w < 760.0
	var ink: Color = INK if phase == "day" else CREAM
	var quiet: Color = Color("#53676A") if phase == "day" else Color("#C3CAC9")

	var bg := ColorRect.new()
	bg.name = "SongwritingBackdrop"
	bg.color = Color("#EEE7D8") if phase == "day" else (Color("#34464A") if phase == "dusk" else Color("#121B21"))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface = Control.new()
	_surface.name = "SongwritingPhysicalSurface"
	_surface.scale = Vector2.ONE / _scale
	add_child(_surface)
	_rect(_surface, 0, 0, w, h)
	var board := TextureRect.new()
	board.name = "PhotographedSongwritingBoard"
	board.texture = load(CORK)
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.modulate = Color("#F7F2E8") if phase == "day" else (Color("#A6AAA8") if phase == "dusk" else Color("#657078"))
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.add_child(board)
	_rect(board, 0, 0, w, h)

	var header := Panel.new()
	header.name = "SongwritingHeader"
	header.add_theme_stylebox_override("panel", _panel(CREAM if phase == "day" else Color("#1B2B32"), Color("#C9B79A")))
	_surface.add_child(header)
	_rect(header, 12, 9, w - 24, 83)
	var brand := _label(header, "PlayerFacingTitle", "LIVIN’ THE DREAM", 23 if narrow else 28, ink, "display")
	_rect(brand, 14, 9, w - (144 if narrow else 200), 35)
	var sub := _label(header, "SongwritingChapter", "CH. 02  /  THE WRITING ROOM", 13, quiet)
	_rect(sub, 14, 50, w - 160, 25)
	var back := Button.new()
	back.name = "ReturnToGallery"
	back.text = "GALLERY"
	Craft.apply_to(back, "tab", false, 48.0)
	back.pressed.connect(_return_to_gallery)
	header.add_child(back)
	_rect(back, w - (123 if narrow else 155), 12, 99 if narrow else 130, 48)

	for i in range(PHASES.size()):
		var time: String = PHASES[i]
		_pad(_surface, "Phase" + time.capitalize(), time.to_upper(), phase == time,
			func() -> void: set_phase(time), 14 + i * 96, 101, 89, 46)

	var dock_h: float = 104.0
	var scroll := ScrollContainer.new()
	scroll.name = "SongwritingScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_surface.add_child(scroll)
	_rect(scroll, 0, 155, w, maxf(130.0, h - 155.0 - dock_h))
	var page := Control.new()
	page.name = "SongwritingPage"
	scroll.add_child(page)
	var page_w: float = minf(1110.0, w - 22.0)
	var left: float = (w - page_w) * 0.5
	var page_h: float = 860.0 if narrow else 690.0
	_rect(page, 0, 0, w, page_h)
	page.custom_minimum_size = Vector2(w, page_h)

	var photo_w: float = page_w if narrow else 380.0
	var photo_h: float = 125.0 if narrow else 330.0
	var photo_frame := Panel.new()
	photo_frame.name = "WritingRoomPhotoFrame"
	photo_frame.clip_contents = true
	photo_frame.add_theme_stylebox_override("panel", _panel(Color("#E7D9C0"), Color("#C6AE8A")))
	page.add_child(photo_frame)
	_rect(photo_frame, left, 6, photo_w, photo_h)
	var photo := TextureRect.new()
	photo.name = "RealDaylightWritingRoom"
	photo.texture = load(ROOM)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.modulate = Color.WHITE if phase == "day" else (Color("#93B2BB") if phase == "dusk" else Color("#52636E"))
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_frame.add_child(photo)
	_rect(photo, 4, 4, photo_w - 8, photo_h - 8)
	var photo_tag := _label(photo_frame, "WritingRoomPhotoCaption", "REAL DAYLIGHT ROOM  /  REHEARSAL", 12, Color("#FCF2DF"), "numbers")
	photo_tag.add_theme_constant_override("outline_size", 3)
	photo_tag.add_theme_color_override("font_outline_color", Color("#15232A"))
	_rect(photo_tag, 12, photo_h - 29, photo_w - 20, 22)

	var paper_x: float = left if narrow else left + 397.0
	var paper_y: float = 143.0 if narrow else 6.0
	var paper_w: float = page_w if narrow else page_w - 397.0
	var paper_h: float = 686.0 if narrow else 634.0
	var notebook := TextureRect.new()
	notebook.name = "SongwritingNotebookMaterial"
	notebook.texture = load(PAPER)
	notebook.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	notebook.stretch_mode = TextureRect.STRETCH_SCALE
	notebook.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(notebook)
	_rect(notebook, paper_x, paper_y, paper_w, paper_h)
	var paper := Control.new()
	paper.name = "SongwritingNotebookNativeInk"
	page.add_child(paper)
	_rect(paper, paper_x, paper_y, paper_w, paper_h)
	var inner: float = paper_w - 34.0
	var top := _label(paper, "SongwritingHeading", "WRITE AN ORIGINAL" if stage == "editing" else "THE SONG IS YOURS", 26 if narrow else 30, INK, "display")
	_rect(top, 16, 12, inner, 40)
	var progress: int = int(local_state.get("song_draft_progress", 0))
	_stats = _label(paper, "ReadOnlySongwritingStats", "DAY %d   ·   SESSION %d/3   ·   ORIGINALS %d" % [
		int(local_state.get("tour_day", 1)), mini(3, progress + 1), local_state.get("song_catalogue", []).size()],
		13, Color("#526168"), "numbers")
	_rect(_stats, 16, 54, inner, 30)

	var title_caption := _label(paper, "TitleCaption", "SONG TITLE", 13, INK, "display")
	_rect(title_caption, 16, 89, inner, 22)
	_title_input = LineEdit.new()
	_title_input.name = "SongwritingTitle"
	_title_input.text = title
	_title_input.max_length = 48
	_title_input.placeholder_text = "Name your original"
	_title_input.editable = stage == "editing"
	_title_input.custom_minimum_size.y = 48
	_title_input.add_theme_font_size_override("font_size", 17)
	_title_input.add_theme_color_override("font_color", INK)
	_title_input.add_theme_stylebox_override("normal", _panel(Color("#FFFDF6"), Color("#A9A087"), 3))
	_title_input.add_theme_stylebox_override("focus", _panel(Color("#FFFDF6"), Color("#946A35"), 3))
	_title_input.text_changed.connect(set_title)
	paper.add_child(_title_input)
	_rect(_title_input, 16, 112, inner, 48)

	var ideas_label := _label(paper, "IdeaCaption", "STARTING POINT  /  RIFF, LYRIC OR GROOVE", 13, INK, "display")
	_rect(ideas_label, 16, 165, inner, 23)
	var pad_w: float = (inner - 12.0) / 3.0
	for i in range(Workshop.IDEAS.size()):
		var value: String = str(Workshop.IDEAS[i])
		_pad(paper, "Idea" + value, value.to_upper(), idea == value,
			func() -> void: choose_idea(value), 16 + i * (pad_w + 6), 189, pad_w, 69)

	var form_label := _label(paper, "StructureCaption", "STRUCTURE  /  CHOOSE THE SHAPE", 13, INK, "display")
	_rect(form_label, 16, 264, inner, 22)
	for i in range(Workshop.FORMS.size()):
		var value: String = str(Workshop.FORMS[i])
		var caption: String = "VERSE / CHORUS" if value == "Verse / Chorus" else ("SLOW BUILD" if value == "Slow Build" else "LOOSE JAM")
		_pad(paper, "Form%d" % i, caption, form == value,
			func() -> void: choose_form(value), 16 + i * (pad_w + 6), 290, pad_w, 69)

	var focus_caption := _label(paper, "ArrangementTempoReadout",
		"ARRANGEMENT SKETCH  /  %d BPM" % int(round(70.0 + arrangement_focus * 0.9)),
		13, INK, "numbers")
	_rect(focus_caption, 16, 373, inner, 27)
	_rotary = Rotary.new()
	_rotary.name = "Lab084ArrangementRotary"
	_rotary.control_kind = "focus"
	_rotary.read_only = stage == "finished"
	_rotary.level = arrangement_focus
	paper.add_child(_rotary)
	_rect(_rotary, 16, 402, 153, 151)
	_rotary.level_changed.connect(_on_focus_changed)
	var knob_note := _label(paper, "ArrangementRole",
		"LAB 08.4  /  SOUND SKETCH\nThe dial changes a rehearsal idea, not your career stats.", 14, INK)
	_rect(knob_note, 180, 414, maxf(95.0, inner - 184.0), 100)

	var choice_note := _label(paper, "SongwritingConsequence",
		"ONE DAY PER SESSION\nSession three finishes the original.\nYour title, starting point and structure are kept.",
		14, Color("#40535B"))
	_rect(choice_note, 16, 567, inner, 92)

	if narrow:
		var transport_label := _label(page, "TransportTitle", "REHEARSAL DECK  /  LAB 07", 15, INK, "display")
		_rect(transport_label, left + 10, 838, page_w - 20, 25)
	else:
		var transport_title := _label(page, "TransportTitle", "REHEARSAL TRANSPORT  /  LAB 07", 16, Color("#F7EFE0"), "display")
		transport_title.add_theme_constant_override("outline_size", 3)
		transport_title.add_theme_color_override("font_outline_color", Color("#203137"))
		_rect(transport_title, left + 12, 347, 355, 29)
		_transport = Transport.new()
		_transport.name = "PhotographicSongwritingTransport"
		_transport.finish = "studio"
		page.add_child(_transport)
		_rect(_transport, left + 20, 380, 340, 185)
		_transport.transport_armed.connect(_on_transport_armed)
		_transport.set_armed_from_model(transport_armed)
		if stage == "finished":
			_transport.set_locked(true)
		var role := _label(page, "TransportRole", "ARM / STANDBY  ·  NO AUDIO OR SAVE WRITES", 13, Color("#F9F0E1"), "numbers")
		role.add_theme_constant_override("outline_size", 3)
		role.add_theme_color_override("font_outline_color", Color("#17242B"))
		_rect(role, left + 10, 577, 360, 32)

	# Fixed action dock keeps the actual decision visible on phones.
	var dock := Panel.new()
	dock.name = "SongwritingActionDock"
	dock.add_theme_stylebox_override("panel", _panel(CREAM if phase == "day" else Color("#21333A"), Color("#BBA985")))
	_surface.add_child(dock)
	_rect(dock, 12, h - dock_h + 5, w - 24, dock_h - 12)
	_primary = Button.new()
	_primary.name = "SongwritingCommitSession"
	_primary.text = "COMMIT SESSION  /  1 DAY" if stage == "editing" else "ORIGINAL COMPLETE  /  3 SESSIONS"
	Craft.apply_to(_primary, "commit", true, 53.0)
	_primary.disabled = stage != "editing" or not bool(session_preview().get("ok", false))
	_primary.pressed.connect(commit_session)
	dock.add_child(_primary)
	_rect(_primary, 10, 8, w - 44, 52)
	_status = _label(dock, "SongwritingStatus", last_message, 13, quiet)
	_rect(_status, 13, 65, w - 50, 24)
