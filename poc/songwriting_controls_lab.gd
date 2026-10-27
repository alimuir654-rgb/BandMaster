extends Control
## Visual Sprint 04 — tactile songwriting control family. Isolated from career saves.
## Original SVG paper is a PROTOTYPE surface, not owner-approved photo hardware.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
const PAPER = preload("res://Art/UI/Songwriting/writing_desk_surface.svg")
const KINDS := ["VERSE", "CHORUS", "BRIDGE", "OUTRO"]
const GROOVES := ["SPARSE", "DRIVE", "SWELL"]

var phase := "day"
var active_kind := "CHORUS"
var groove := "DRIVE"
var tempo := 112
var idea_text := "The streetlights know our names"
var sequence: Array[String] = ["VERSE", "CHORUS", "VERSE", "CHORUS"]
var preview_count := 0
var _scale := 1.0
var _status: Label
var _tempo_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild()

func set_phase(next_phase: String) -> void:
	if not ["day", "dusk"].has(next_phase):
		return
	phase = next_phase
	if is_inside_tree():
		_rebuild()

func choose_section(kind: String) -> void:
	if not KINDS.has(kind):
		return
	active_kind = kind
	if is_inside_tree():
		_rebuild()

func append_section() -> void:
	if sequence.size() >= 6:
		return
	sequence.append(active_kind)
	if is_inside_tree():
		_rebuild()

func remove_section() -> void:
	if sequence.size() <= 2:
		return
	sequence.remove_at(sequence.size() - 1)
	if is_inside_tree():
		_rebuild()

func choose_groove(next_groove: String) -> void:
	if not GROOVES.has(next_groove):
		return
	groove = next_groove
	if is_inside_tree():
		_rebuild()

func set_tempo(next_tempo: int) -> void:
	tempo = clampi(next_tempo, 65, 165)
	if _tempo_label != null and is_instance_valid(_tempo_label):
		_tempo_label.text = "%d BPM" % tempo

func set_idea(value: String) -> void:
	idea_text = value.substr(0, 160)

func preview_draft() -> void:
	preview_count += 1
	if _status != null and is_instance_valid(_status):
		_status.text = "PREVIEW %02d / %d SECTIONS / %s / %d BPM / NO SAVE WRITES" % [preview_count, sequence.size(), groove, tempo]

func _rebuild() -> void:
	_scale = clampf(get_viewport_rect().size.x / float(maxi(1, DisplayServer.window_get_size().x)), 0.7, 2.3)
	var compact := DisplayServer.window_get_size().y <= 800
	var mobile := DisplayServer.window_get_size().x < 680
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var p: Dictionary = Worlds.palette("songwriting", phase)
	var bg := ColorRect.new()
	bg.name = "WritingTimeBackdrop"
	bg.color = p["bg"]
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dock_height := 100.0 * _scale
	var scroll := ScrollContainer.new()
	scroll.name = "WritingLabScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -dock_height
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var page := MarginContainer.new()
	page.custom_minimum_size.x = minf(920.0 * _scale, maxf(320.0 * _scale, get_viewport_rect().size.x - 28.0 * _scale))
	for side in ["left", "right"]:
		page.add_theme_constant_override("margin_" + side, roundi(12 * _scale))
	page.add_theme_constant_override("margin_top", roundi(12 * _scale))
	page.add_theme_constant_override("margin_bottom", roundi(20 * _scale))
	center.add_child(page)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi((7 if compact else 10) * _scale))
	page.add_child(col)
	_text(col, "LIVIN' THE DREAM  /  SONGWRITING CONTROL LAB 04", 12, p["muted"], "WritingOverline")
	_text(col, "FIND THE HOOK", 29 if mobile else 34, p["ink"], "WritingHeading")
	_text(col, "DAY / WRITING TABLE" if phase == "day" else "DUSK / LATE REHEARSAL", 13, p["muted"], "WritingPhase")

	var phase_row := HBoxContainer.new()
	phase_row.add_theme_constant_override("separation", roundi(7 * _scale))
	col.add_child(phase_row)
	_button(phase_row, "DAYLIGHT", phase == "day", func() -> void: set_phase("day"), p, "PhaseDay")
	_button(phase_row, "EVENING", phase == "dusk", func() -> void: set_phase("dusk"), p, "PhaseDusk")

	# Diegetic paper: artwork contains NO interactive text. All text is native Godot.
	var notebook := Control.new()
	notebook.name = "WritingNotebook"
	notebook.custom_minimum_size.y = (278 if compact else (312 if mobile else 322)) * _scale
	notebook.clip_contents = true
	col.add_child(notebook)
	var paper := TextureRect.new()
	paper.name = "WritingPaperArt"
	paper.texture = PAPER
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notebook.add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper_margin := MarginContainer.new()
	notebook.add_child(paper_margin)
	paper_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_margin.add_theme_constant_override("margin_left", roundi(30 * _scale))
	paper_margin.add_theme_constant_override("margin_right", roundi(17 * _scale))
	paper_margin.add_theme_constant_override("margin_top", roundi(14 * _scale))
	paper_margin.add_theme_constant_override("margin_bottom", roundi(12 * _scale))
	var paper_col := VBoxContainer.new()
	paper_col.add_theme_constant_override("separation", roundi((5 if compact else 7) * _scale))
	paper_margin.add_child(paper_col)
	_text(paper_col, "IDEA CAPTURE  /  PENCIL NOTES", 12, Color("#635849"), "IdeaHeading")
	var idea := LineEdit.new()
	idea.name = "IdeaLine"
	idea.text = idea_text
	idea.placeholder_text = "A lyric, a hook, a title..."
	idea.max_length = 160
	idea.custom_minimum_size.y = 46 * _scale
	idea.add_theme_font_size_override("font_size", roundi(15 * _scale))
	idea.add_theme_color_override("font_color", Color("#202F34"))
	idea.add_theme_color_override("font_placeholder_color", Color("#5D6565"))
	idea.add_theme_stylebox_override("normal", _plate(Color("#FFFDF4"), Color("#B8A990")))
	idea.add_theme_stylebox_override("focus", _plate(Color("#FFFDF4"), Color("#A56B30"), 3))
	idea.text_changed.connect(set_idea)
	paper_col.add_child(idea)
	_text(paper_col, "SECTION STAMP  /  CHOOSE A PART", 11, Color("#635849"))
	var kinds := HBoxContainer.new()
	kinds.add_theme_constant_override("separation", roundi(4 * _scale))
	paper_col.add_child(kinds)
	for kind in KINDS:
		var choice: String = kind
		_button(kinds, kind, active_kind == kind, func() -> void: choose_section(choice), p, "Kind" + kind.capitalize(), true)
	_text(paper_col, "ARRANGEMENT TAPE  /  %d OF 6 PARTS" % sequence.size(), 11, Color("#635849"), "SequenceHeading")
	var seq := HBoxContainer.new()
	seq.name = "SequenceTape"
	seq.add_theme_constant_override("separation", roundi(4 * _scale))
	paper_col.add_child(seq)
	for i in sequence.size():
		var part: String = sequence[i]
		var tag := Label.new()
		tag.name = "Part%02d" % i
		tag.text = "%02d %s" % [i + 1, part.substr(0, 3)]
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tag.custom_minimum_size.y = 28 * _scale
		tag.add_theme_font_size_override("font_size", roundi(11 * _scale))
		tag.add_theme_color_override("font_color", Color("#203034"))
		tag.add_theme_stylebox_override("normal", _plate(Color("#E9D6AE") if part == "CHORUS" else Color("#DDE1D9"), Color("#A49B83")))
		seq.add_child(tag)
	var seq_actions := HBoxContainer.new()
	seq_actions.add_theme_constant_override("separation", roundi(6 * _scale))
	paper_col.add_child(seq_actions)
	var add := _button(seq_actions, "+ ADD %s" % active_kind, false, append_section, p, "AddSection", true)
	add.disabled = sequence.size() >= 6
	var remove := _button(seq_actions, "- LAST PART", false, remove_section, p, "RemoveSection", true)
	remove.disabled = sequence.size() <= 2

	# Compact sampler/transport strip is a distinct family, not a duplicate studio dial.
	var rack := PanelContainer.new()
	rack.name = "WritingSamplerRack"
	rack.add_theme_stylebox_override("panel", _plate(Color("#233035"), Color("#73817D"), 2))
	col.add_child(rack)
	var rack_margin := MarginContainer.new()
	for side in ["left", "right"]:
		rack_margin.add_theme_constant_override("margin_" + side, roundi(12 * _scale))
	for side in ["top", "bottom"]:
		rack_margin.add_theme_constant_override("margin_" + side, roundi(9 * _scale))
	rack.add_child(rack_margin)
	var rack_col := VBoxContainer.new()
	rack_col.add_theme_constant_override("separation", roundi(5 * _scale))
	rack_margin.add_child(rack_col)
	_text(rack_col, "RHYTHM PAD  /  ARRANGEMENT FEEL", 12, Color("#DDE5DE"), "GrooveHeading")
	var pads := HBoxContainer.new()
	pads.add_theme_constant_override("separation", roundi(7 * _scale))
	rack_col.add_child(pads)
	for next_groove in GROOVES:
		var selected_groove: String = next_groove
		_button(pads, next_groove, groove == next_groove, func() -> void: choose_groove(selected_groove), p, "Groove" + next_groove.capitalize(), false, true)
	var tempo_row := HBoxContainer.new()
	tempo_row.add_theme_constant_override("separation", roundi(8 * _scale))
	rack_col.add_child(tempo_row)
	var tempo_caption: Label = _text(tempo_row, "TEMPO", 12, Color("#E3E6DF"))
	tempo_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	tempo_caption.custom_minimum_size.x = 52 * _scale
	var tempo_slider := HSlider.new()
	tempo_slider.name = "TempoSlider"
	tempo_slider.min_value = 65
	tempo_slider.max_value = 165
	tempo_slider.step = 1
	tempo_slider.value = tempo
	tempo_slider.custom_minimum_size.y = 44 * _scale
	tempo_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tempo_slider.focus_mode = Control.FOCUS_ALL
	tempo_slider.value_changed.connect(func(v: float) -> void: set_tempo(int(v)))
	tempo_row.add_child(tempo_slider)
	_tempo_label = _text(tempo_row, "%d BPM" % tempo, 13, Color("#F4D5A1"), "TempoReadout")
	_tempo_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_tempo_label.custom_minimum_size.x = 67 * _scale
	_tempo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not compact:
		_text(col, "LOCAL DRAFT ONLY / NO BAND TIME, CASH OR SONG DATA CHANGED", 11, p["muted"], "WritingDisclaimer")

	# Fixed dock: the preview action remains visible when the writing desk scrolls.
	var dock := PanelContainer.new()
	dock.name = "WritingActionDock"
	dock.add_theme_stylebox_override("panel", _plate(p["surface"], p["border"], 1))
	add_child(dock)
	dock.anchor_left = 0
	dock.anchor_right = 1
	dock.anchor_top = 1
	dock.anchor_bottom = 1
	dock.offset_left = 8 * _scale
	dock.offset_right = -8 * _scale
	dock.offset_top = -dock_height
	dock.offset_bottom = -4 * _scale
	var dock_margin := MarginContainer.new()
	for side in ["left", "right"]:
		dock_margin.add_theme_constant_override("margin_" + side, roundi(9 * _scale))
	dock_margin.add_theme_constant_override("margin_top", roundi(5 * _scale))
	dock_margin.add_theme_constant_override("margin_bottom", roundi(4 * _scale))
	dock.add_child(dock_margin)
	var dock_col := VBoxContainer.new()
	dock_col.add_theme_constant_override("separation", roundi(3 * _scale))
	dock_margin.add_child(dock_col)
	_status = _text(dock_col, "IDEA IN PROGRESS / PREVIEW IS NON-MUTATING", 11, p["muted"], "WritingStatus")
	_button(dock_col, "PREVIEW ARRANGEMENT", false, preview_draft, p, "WritingPrimary", false, false, true)

func _text(parent: Node, value: String, size: int, color: Color, id: String = "") -> Label:
	var label := Label.new()
	if not id.is_empty():
		label.name = id
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(size * _scale))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _plate(fill: Color, edge: Color, edge_width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(edge_width)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(roundi(5 * _scale))
	return box

func _button(parent: Node, caption: String, selected: bool, action: Callable, p: Dictionary,
	id: String = "", paper: bool = false, hardware: bool = false, primary: bool = false) -> Button:
	var b := Button.new()
	if not id.is_empty():
		b.name = id
	b.text = caption
	b.custom_minimum_size.y = (52 if primary else 47) * _scale
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	var fill: Color = p["action"] if primary or selected else (Color("#D5DBD6") if paper else (Color("#36474C") if hardware else p["surface"]))
	var ink: Color = Color("#17252C") if primary or selected or paper else (Color("#F4EEE4") if hardware else p["ink"])
	var edge: Color = Color("#956630") if selected or primary else (Color("#7D8B86") if hardware else p["border"])
	var normal := _plate(fill, edge, 2 if selected else 1)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", _plate(fill.lightened(0.09), p["action"], 2))
	b.add_theme_stylebox_override("pressed", _plate(fill.darkened(0.15), edge, 2))
	b.add_theme_stylebox_override("disabled", _plate(fill.darkened(0.2), edge))
	b.add_theme_stylebox_override("focus", _plate(Color.TRANSPARENT, Color("#E0A94D"), 3))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, ink)
	b.add_theme_color_override("font_disabled_color", Color("#616B68"))
	b.add_theme_font_size_override("font_size", roundi((15 if primary else (12 if paper else 14)) * _scale))
	b.pressed.connect(action)
	parent.add_child(b)
	return b
