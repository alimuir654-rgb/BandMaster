extends Control
## Sprint 05 — playable isolated songwriting journey. Never reads or writes career saves.
## Art is provisional Sprint 04 paper, NOT approved Lab 08.4 hardware.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
const Model = preload("res://Scripts/songwriting_journey_preview.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const SongStudio = preload("res://Scripts/song_studio_presentation.gd")
const SongSleeve = preload("res://Scripts/song_sleeve.gd")
const PAPER = preload("res://Art/UI/Songwriting/writing_desk_surface.svg")
const PARTS := ["VERSE", "CHORUS", "BRIDGE", "OUTRO"]
const FEELS := ["SPARSE", "DRIVE", "SWELL"]

var local_state: Dictionary = {}
var stage := 0
var phase := "day"
var title := "LATE TRAIN, LAST CHANCE"
var idea := "Lyric"
var form := "Verse / Chorus"
var leader_index := 0
var active_part := "CHORUS"
var sections: Array[String] = ["VERSE", "CHORUS", "VERSE", "CHORUS"]
var feel := "DRIVE"
var bpm := 112
var commits := 0
var last_message := ""
var _scale := 1.0
var _status: Label
var _primary: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	local_state = Model.sample_state()
	_render()

func set_phase(value: String) -> void:
	if not ["day", "dusk"].has(value):
		return
	phase = value
	if is_inside_tree():
		_render()

func set_title(value: String) -> void:
	title = value.substr(0, 48)

func choose_idea(value: String) -> void:
	if not Workshop.IDEAS.has(value):
		return
	idea = value
	if is_inside_tree():
		_render()

func choose_form(value: String) -> void:
	if not Workshop.FORMS.has(value):
		return
	form = value
	if is_inside_tree():
		_render()

func choose_leader(value: int) -> void:
	var roster: Array = local_state.get("members", [])
	if value < 0 or value >= roster.size():
		return
	leader_index = value
	if is_inside_tree():
		_render()

func choose_part(value: String) -> void:
	if not PARTS.has(value):
		return
	active_part = value
	if is_inside_tree():
		_render()

func append_part() -> void:
	if sections.size() >= 6:
		return
	sections.append(active_part)
	if is_inside_tree():
		_render()

func remove_part() -> void:
	if sections.size() <= 2:
		return
	sections.remove_at(sections.size() - 1)
	if is_inside_tree():
		_render()

func choose_feel(value: String) -> void:
	if not FEELS.has(value):
		return
	feel = value
	if is_inside_tree():
		_render()

func set_bpm(value: int) -> void:
	bpm = clampi(value, 65, 165)
	var readout: Label = find_child("JourneyTempoReadout", true, false)
	if readout != null:
		readout.text = "%d BPM" % bpm

func advance() -> void:
	if stage == 3:
		# Starting another composition is allowed only after a finished original.
		stage = 0
		phase = "day"
		title = ""
		idea = "Riff"
		form = "Verse / Chorus"
		last_message = "New song / the previous original remains in this local session."
		_render()
		return
	if stage == 0:
		var clean := title.strip_edges()
		if clean.length() < 3 or clean.length() > 48:
			last_message = "Enter a title between 3 and 48 characters."
			_render()
			return
		stage = 1
		last_message = ""
	elif stage == 1:
		stage = 2
		last_message = ""
	else:
		commit_session()
		return
	_render()

func go_back() -> void:
	if stage <= 0 or stage >= 3:
		return
	stage -= 1
	last_message = ""
	_render()

func session_preview() -> Dictionary:
	return Model.simulate(local_state, idea, form, title, leader_index)

func commit_session() -> void:
	if stage != 2:
		return
	var outcome: Dictionary = session_preview()
	if not bool(outcome.get("ok", false)):
		last_message = str(outcome.get("message", "Session unavailable."))
		_render()
		return
	# The model returns a new state; no FileAccess, autoload or main-game mutation.
	local_state = outcome["state"]
	commits += 1
	last_message = str(outcome.get("message", ""))
	if bool(outcome.get("finished", false)):
		stage = 3
		phase = "dusk"
	else:
		stage = 0
		phase = "dusk"
	_render()

func _render() -> void:
	_scale = clampf(get_viewport_rect().size.x / float(maxi(1, DisplayServer.window_get_size().x)), 0.7, 2.3)
	var compact := DisplayServer.window_get_size().y <= 800
	var mobile := DisplayServer.window_get_size().x < 680
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var p: Dictionary = Worlds.palette("songwriting", phase)
	var backdrop := ColorRect.new()
	backdrop.name = "JourneyTimeBackdrop"
	backdrop.color = p["bg"]
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dock_h := 108.0 * _scale
	var scroll := ScrollContainer.new()
	scroll.name = "JourneyScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -dock_h
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var page := MarginContainer.new()
	page.custom_minimum_size.x = minf(860.0 * _scale, maxf(320.0 * _scale, get_viewport_rect().size.x - 22.0 * _scale))
	for side in ["left", "right"]:
		page.add_theme_constant_override("margin_" + side, roundi(12 * _scale))
	page.add_theme_constant_override("margin_top", roundi(12 * _scale))
	page.add_theme_constant_override("margin_bottom", roundi(18 * _scale))
	center.add_child(page)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi((8 if compact else 11) * _scale))
	page.add_child(col)
	_text(col, "LIVIN' THE DREAM  /  SONGWRITING JOURNEY 05", 12, p["muted"], "JourneyOverline")
	_text(col, "WRITE AN ORIGINAL" if stage < 3 else "THE SONG IS YOURS", 29 if mobile else 34, p["ink"], "JourneyHeading")
	var phase_text := "DAYLIGHT / WRITING TABLE" if phase == "day" else "DUSK / LATE REHEARSAL"
	_text(col, phase_text + "  ·  DAY %d" % int(local_state.get("tour_day", 1)), 13, p["muted"], "JourneyPhase")
	var phase_row := HBoxContainer.new()
	phase_row.add_theme_constant_override("separation", roundi(7 * _scale))
	col.add_child(phase_row)
	_button(phase_row, "DAYLIGHT", phase == "day", func() -> void: set_phase("day"), p, "JourneyDay")
	_button(phase_row, "EVENING", phase == "dusk", func() -> void: set_phase("dusk"), p, "JourneyDusk")
	var steps := HBoxContainer.new()
	steps.name = "JourneyStageRail"
	steps.add_theme_constant_override("separation", roundi(5 * _scale))
	col.add_child(steps)
	var captions := ["01  THE SPARK", "02  FIND SOUND", "03  SONGSHEET"]
	for i in range(3):
		var step_label := _text(steps, captions[i], 11, p["ink"] if i == stage else p["muted"], "JourneyStep%d" % i)
		step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		step_label.add_theme_stylebox_override("normal", _plate(p["action"] if i == stage else p["surface"], p["border"]))
	var notebook := Control.new()
	notebook.name = "JourneyNotebook"
	notebook.custom_minimum_size.y = ((590 if compact else 610) if stage == 1 else (370 if compact else (415 if mobile else 425))) * _scale
	notebook.clip_contents = true
	col.add_child(notebook)
	var art := TextureRect.new()
	art.name = "JourneyPaperArt"
	art.texture = PAPER
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notebook.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper_margin := MarginContainer.new()
	notebook.add_child(paper_margin)
	paper_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_margin.add_theme_constant_override("margin_left", roundi(26 * _scale))
	paper_margin.add_theme_constant_override("margin_right", roundi(18 * _scale))
	paper_margin.add_theme_constant_override("margin_top", roundi(15 * _scale))
	paper_margin.add_theme_constant_override("margin_bottom", roundi(12 * _scale))
	var paper_col := VBoxContainer.new()
	paper_col.add_theme_constant_override("separation", roundi((7 if compact else 10) * _scale))
	paper_margin.add_child(paper_col)
	if stage == 0:
		_build_spark(paper_col, p)
	elif stage == 1:
		_build_sound(paper_col, p)
	elif stage == 2:
		_build_review(paper_col, p)
	else:
		_build_result(paper_col, p)
	var explanation := "ISOLATED DEMO  /  CHOICES USE REAL SONG RULES; NO CAREER SAVE WRITES"
	_text(col, explanation, 11, p["muted"], "JourneyDisclaimer")
	# Fixed dock prevents mobile scroll from hiding the single primary action.
	var dock := PanelContainer.new()
	dock.name = "JourneyActionDock"
	dock.add_theme_stylebox_override("panel", _plate(p["surface"], p["border"]))
	add_child(dock)
	var dock_w := minf(720.0 * _scale, get_viewport_rect().size.x - 16.0 * _scale)
	dock.anchor_left = 0.5
	dock.anchor_right = 0.5
	dock.anchor_top = 1
	dock.anchor_bottom = 1
	dock.offset_left = -dock_w * 0.5
	dock.offset_right = dock_w * 0.5
	dock.offset_top = -dock_h
	dock.offset_bottom = -4 * _scale
	var dock_margin := MarginContainer.new()
	for side in ["left", "right"]:
		dock_margin.add_theme_constant_override("margin_" + side, roundi(9 * _scale))
	dock_margin.add_theme_constant_override("margin_top", roundi(5 * _scale))
	dock_margin.add_theme_constant_override("margin_bottom", roundi(4 * _scale))
	dock.add_child(dock_margin)
	var dock_col := VBoxContainer.new()
	dock_col.add_theme_constant_override("separation", roundi(4 * _scale))
	dock_margin.add_child(dock_col)
	var status_text := last_message if not last_message.is_empty() else ("SESSION %d OF 3  /  %d COMPLETED ORIGINALS" % [int(local_state.get("song_draft_progress", 0)) + 1, local_state.get("song_catalogue", []).size()])
	_status = _text(dock_col, status_text, 11, p["muted"], "JourneyStatus")
	_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status.clip_text = true
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", roundi(6 * _scale))
	dock_col.add_child(actions)
	if stage > 0 and stage < 3:
		var back := _button(actions, "BACK", false, go_back, p, "JourneyBack", false, false)
		back.size_flags_stretch_ratio = 0.35
	var primary_caption := "FIND THE SOUND" if stage == 0 else ("REVIEW SESSION" if stage == 1 else ("COMMIT SESSION  /  1 DAY" if stage == 2 else "WRITE ANOTHER SONG"))
	_primary = _button(actions, primary_caption, false, advance, p, "JourneyPrimary", false, true)
	if stage == 2:
		var check: Dictionary = session_preview()
		_primary.disabled = not bool(check.get("ok", false))

func _build_spark(parent: VBoxContainer, p: Dictionary) -> void:
	_paper_text(parent, "THE SPARK  /  FIND A REASON TO WRITE", 13, "SparkHeading")
	_paper_text(parent, "Give the original a name. Start with a riff, a lyric or a groove.", 15)
	_paper_text(parent, "SONG TITLE", 12)
	var input := LineEdit.new()
	input.name = "JourneyTitle"
	input.text = title
	input.placeholder_text = "A title for this original"
	input.max_length = 48
	input.custom_minimum_size.y = 48 * _scale
	input.add_theme_font_size_override("font_size", roundi(16 * _scale))
	input.add_theme_color_override("font_color", Color("#203034"))
	input.add_theme_stylebox_override("normal", _plate(Color("#FFFDF4"), Color("#A49B83")))
	input.add_theme_stylebox_override("focus", _plate(Color("#FFFDF4"), Color("#956630"), 3))
	input.text_changed.connect(set_title)
	parent.add_child(input)
	_paper_text(parent, "STARTING POINT", 12)
	var ideas := HBoxContainer.new()
	ideas.add_theme_constant_override("separation", roundi(5 * _scale))
	parent.add_child(ideas)
	for choice in Workshop.IDEAS:
		var selected: String = choice
		_button(ideas, choice.to_upper(), idea == choice, func() -> void: choose_idea(selected), p, "Idea" + choice, true)
	_paper_text(parent, str(SongStudio.IDEA_NOTES.get(idea, "")), 14, "JourneyIdeaNote")
	_paper_text(parent, "A title and a starting point do not cost a day until you commit.", 13)

func _build_sound(parent: VBoxContainer, p: Dictionary) -> void:
	_paper_text(parent, "FIND THE SOUND  /  BUILD THE ARRANGEMENT", 13, "SoundHeading")
	_paper_text(parent, "Choose a structure and a bandmate to lead the writing session.", 14)
	var forms := HBoxContainer.new()
	forms.add_theme_constant_override("separation", roundi(4 * _scale))
	parent.add_child(forms)
	for choice in Workshop.FORMS:
		var selected: String = choice
		var caption := "V / C" if choice == "Verse / Chorus" else ("BUILD" if choice == "Slow Build" else "JAM")
		_button(forms, caption, form == choice, func() -> void: choose_form(selected), p, "Form" + caption.replace(" ", ""), true)
	_paper_text(parent, str(SongStudio.FORM_NOTES.get(form, "")), 13, "JourneyFormNote")
	var roster: Array = local_state.get("members", [])
	var lead_row := HBoxContainer.new()
	lead_row.add_theme_constant_override("separation", roundi(4 * _scale))
	parent.add_child(lead_row)
	for i in range(roster.size()):
		var idx := i
		var member: Dictionary = roster[i]
		_button(lead_row, str(member.get("name", "MUSICIAN")).to_upper(), leader_index == i, func() -> void: choose_leader(idx), p, "Leader%d" % i, true)
	_paper_text(parent, "TAPE ARRANGEMENT  /  %d PARTS" % sections.size(), 12)
	var tape := HBoxContainer.new()
	tape.name = "JourneySequenceTape"
	tape.add_theme_constant_override("separation", roundi(4 * _scale))
	parent.add_child(tape)
	for i in range(sections.size()):
		var tag := _paper_text(tape, "%02d %s" % [i + 1, sections[i].substr(0, 3)], 11, "JourneyPart%d" % i)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tag.add_theme_stylebox_override("normal", _plate(Color("#E9D6AE") if sections[i] == "CHORUS" else Color("#DDE1D9"), Color("#A49B83")))
	var tape_actions := HBoxContainer.new()
	tape_actions.add_theme_constant_override("separation", roundi(5 * _scale))
	parent.add_child(tape_actions)
	var add := _button(tape_actions, "+ PART", false, append_part, p, "JourneyAddPart", true)
	add.disabled = sections.size() >= 6
	var remove := _button(tape_actions, "- PART", false, remove_part, p, "JourneyRemovePart", true)
	remove.disabled = sections.size() <= 2
	var rack := HBoxContainer.new()
	rack.add_theme_constant_override("separation", roundi(5 * _scale))
	parent.add_child(rack)
	for groove_choice in FEELS:
		var selected_feel: String = groove_choice
		_button(rack, groove_choice, feel == groove_choice, func() -> void: choose_feel(selected_feel), p, "Feel" + groove_choice, true)
	var tempo_row := HBoxContainer.new()
	tempo_row.add_theme_constant_override("separation", roundi(5 * _scale))
	parent.add_child(tempo_row)
	var tempo_caption := _paper_text(tempo_row, "BPM", 12)
	tempo_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	tempo_caption.custom_minimum_size.x = 35 * _scale
	var slider := HSlider.new()
	slider.name = "JourneyTempoSlider"
	slider.min_value = 65
	slider.max_value = 165
	slider.step = 1
	slider.value = bpm
	slider.custom_minimum_size.y = 44 * _scale
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(func(value: float) -> void: set_bpm(int(value)))
	tempo_row.add_child(slider)
	var tempo_readout := _paper_text(tempo_row, "%d BPM" % bpm, 12, "JourneyTempoReadout")
	tempo_readout.autowrap_mode = TextServer.AUTOWRAP_OFF
	tempo_readout.custom_minimum_size.x = 65 * _scale
	_paper_text(parent, "Tape, groove and BPM are visual sketches; game quality uses form and band chemistry.", 11)

func _build_review(parent: VBoxContainer, _p: Dictionary) -> void:
	_paper_text(parent, "THE SONGSHEET  /  CHECK BEFORE YOU COMMIT", 13, "ReviewHeading")
	_paper_text(parent, title.strip_edges().to_upper(), 21, "ReviewTitle")
	_paper_text(parent, "%s IDEA  /  %s  /  LEAD: %s" % [idea.to_upper(), form.to_upper(), str(local_state.get("members", [])[leader_index].get("name", "MUSICIAN")).to_upper()], 13)
	_paper_text(parent, "ARRANGEMENT SKETCH  /  %s  /  %d BPM" % [feel, bpm], 12)
	_paper_text(parent, "TAPE: " + "  →  ".join(PackedStringArray(sections)), 12)
	var preview: Dictionary = session_preview()
	if not bool(preview.get("ok", false)):
		_paper_text(parent, "CAN'T COMMIT: " + str(preview.get("message", "")), 14, "JourneyError")
		return
	_paper_text(parent, "GAMEPLAY CONSEQUENCES  /  SIMULATED FROM EXISTING RULES", 12)
	_paper_text(parent, "DAY %+d    CASH £%+d    MORALE %+d    READINESS %+d" % [int(preview["days"]), int(preview["cash"]), int(preview["morale"]), int(preview["readiness"])], 14, "JourneyDeltas")
	var completed: bool = bool(preview.get("finished", false))
	_paper_text(parent, "THIS SESSION FINISHES THE ORIGINAL." if completed else "THE ORIGINAL NEEDS %d MORE WRITING SESSION(S)." % (3 - int(preview["progress"])), 14, "JourneyConsequence")
	_paper_text(parent, "Preview does not advance time. Commit applies this to the local demo only.", 12)

func _build_result(parent: VBoxContainer, _p: Dictionary) -> void:
	_paper_text(parent, "NEW ORIGINAL  /  THREE WRITING SESSIONS COMPLETE", 13, "ResultHeading")
	var songs: Array = local_state.get("song_catalogue", [])
	if songs.is_empty():
		_paper_text(parent, "NO FINISHED SONG", 16)
		return
	var song: Dictionary = songs.back()
	var info: Dictionary = SongSleeve.describe(song, songs.size())
	_paper_text(parent, str(info["title"]), 23, "ResultTitle")
	_paper_text(parent, str(info["credits"]), 14, "ResultCredits")
	_paper_text(parent, str(info["origin"]) + "  /  " + str(info["arrangement"]), 14)
	_paper_text(parent, str(info["quality"]) + "  /  " + str(info["day"]), 14, "ResultQuality")
	_paper_text(parent, "LOCAL DEMO: %d WRITING DAYS SPENT  /  £%d CASH REMAINING" % [commits, int(local_state.get("cash", 0))], 13)
	_paper_text(parent, "The original is preserved in this prototype until you leave the scene. No career save has changed.", 13)

func _paper_text(parent: Node, value: String, size: int, id: String = "") -> Label:
	return _text(parent, value, size, Color("#27343A"), id)

func _text(parent: Node, value: String, size: int, colour: Color, id: String = "") -> Label:
	var label := Label.new()
	if not id.is_empty():
		label.name = id
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(size * _scale))
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label

func _plate(fill: Color, edge: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(roundi(5 * _scale))
	return style

func _button(parent: Node, caption: String, selected: bool, action: Callable, p: Dictionary, id: String = "", paper: bool = false, primary: bool = false) -> Button:
	var button := Button.new()
	if not id.is_empty():
		button.name = id
	button.text = caption
	button.custom_minimum_size.y = (53 if primary else 47) * _scale
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	var fill: Color = p["action"] if selected or primary else (Color("#E1E0D5") if paper else p["surface"])
	var ink: Color = Color("#17252C") if selected or primary or paper else p["ink"]
	var edge: Color = Color("#956630") if selected or primary else p["border"]
	button.add_theme_stylebox_override("normal", _plate(fill, edge, 2 if selected else 1))
	button.add_theme_stylebox_override("hover", _plate(fill.lightened(0.08), p["action"], 2))
	button.add_theme_stylebox_override("pressed", _plate(fill.darkened(0.13), edge, 2))
	button.add_theme_stylebox_override("disabled", _plate(fill.darkened(0.2), edge))
	button.add_theme_stylebox_override("focus", _plate(Color.TRANSPARENT, Color("#E0A94D"), 3))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, ink)
	button.add_theme_color_override("font_disabled_color", Color("#616B68"))
	button.add_theme_font_size_override("font_size", roundi((15 if primary else (12 if paper else 14)) * _scale))
	button.pressed.connect(action)
	parent.add_child(button)
	return button
