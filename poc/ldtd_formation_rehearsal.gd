extends Control
## S02 isolated formation → social → rehearsal slice. All decisions use existing
## formation_catalogue, band_social and practice_room simulation rules.
## No production state, real career economy or user:// writes.
const Catalogue = preload("res://Scripts/formation_catalogue.gd")
const Social = preload("res://Scripts/band_social.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Craft = preload("res://Scripts/formation_craft_skin.gd")
const PHASES := ["day", "dusk", "night"]
const ROOM_PHOTO := "res://Art/Backgrounds/shared/formation.webp"
const PAPER := Color("#F6F0E3")
const INK := Color("#26353B")
const GOLD := Color("#D9A456")
const CANDIDATE_IDS := {"alex": 0, "jo": 1, "sam": 3, "rae": 7, "dev": 8}

var phase: String = "day"
var stage: String = "recruit"
var drummer_id: String = "jo"
var bass_id: String = "sam"
var outing_id: String = ""
var room_focus: String = ""
var preview_state: Dictionary = {}
var result_history: Array[String] = []
var settlement_count: int = 0
var _scale: float = 1.0
var _surface: Control
var _primary: Button
var _status: Label
var _choice_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_state = _initial_state()
	resized.connect(_on_resize)
	call_deferred("_render")

func _on_resize() -> void:
	if is_inside_tree():
		call_deferred("_render")

func _initial_state() -> Dictionary:
	return {"band_name": "The First Draft", "cash": 120, "tour_day": 1,
		"morale": 60, "tension": 20, "readiness": 20, "buzz": 0, "songs": 0,
		"members": [], "relationships": {"0_1": 40, "0_2": 40, "1_2": 40},
		"career_journal": []}

func set_phase(value: String) -> void:
	if PHASES.has(value):
		phase = value
		if is_inside_tree():
			call_deferred("_render")

func choose_drummer(value: String) -> void:
	if stage == "recruit" and ["jo", "rae"].has(value):
		drummer_id = value
		call_deferred("_render")

func choose_bassist(value: String) -> void:
	if stage == "recruit" and ["sam", "dev"].has(value):
		bass_id = value
		call_deferred("_render")

func choose_outing(value: String) -> void:
	if stage == "social" and ["dinner", "watch_gig"].has(value):
		outing_id = value
		call_deferred("_render")

func choose_room_focus(value: String) -> void:
	if stage == "rehearsal" and ["tighten", "connect"].has(value):
		room_focus = value
		call_deferred("_render")

func _candidate(value: String) -> Dictionary:
	return Catalogue.CANDIDATES[int(CANDIDATE_IDS[value])]

func commit_stage() -> void:
	# Each stage must be actively selected; a second queued click cannot pay twice.
	if stage == "recruit":
		var members: Array = []
		for id in ["alex", drummer_id, bass_id]:
			var person: Dictionary = _candidate(id)
			if not Catalogue.can_recruit(members, person):
				return
			members.append(Catalogue.to_member(person, members.size()))
		if not Catalogue.viable(members):
			return
		preview_state["members"] = members
		result_history.append("Line-up agreed: Alex, %s and %s. First rehearsal still to earn." %
			[_candidate(drummer_id)["name"], _candidate(bass_id)["name"]])
		stage = "social"
		outing_id = "" # Prevent the queued second press spending cash.
	elif stage == "social":
		if outing_id.is_empty():
			return
		var outcome: Dictionary = Social.attend(preview_state, outing_id)
		if not bool(outcome.get("ok", false)):
			result_history.append(str(outcome.get("message", "Outing unavailable.")))
			return
		preview_state = outcome["state"]
		result_history.append(str(outcome["message"]))
		settlement_count += 1
		stage = "rehearsal"
		room_focus = "" # No second action without a new explicit choice.
	elif stage == "rehearsal":
		if room_focus.is_empty():
			return
		var outcome: Dictionary = Practice.resolve(preview_state, room_focus)
		if not bool(outcome.get("ok", false)):
			result_history.append(str(outcome.get("message", "Rehearsal unavailable.")))
			return
		preview_state = outcome["state"]
		result_history.append(str(outcome["message"]))
		settlement_count += 1
		stage = "summary"
	else:
		return
	if is_inside_tree():
		call_deferred("_render")

func _rect(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.position = Vector2(x, y)
	c.size = Vector2(maxf(1.0, w), maxf(1.0, h))

func _style(fill: Color, border: Color, radius: int = 4, shadow: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	if shadow:
		s.shadow_color = Color(0.10, 0.09, 0.08, 0.18)
		s.shadow_size = 9
		s.shadow_offset = Vector2(0, 3)
	return s

func _label(parent: Node, name_value: String, caption: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.name = name_value
	l.text = caption
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _button(parent: Node, name_value: String, caption: String, selected: bool, action: Callable) -> Button:
	# Text and click targets remain native; bespoke ripped-paper/ticket/tab/wax assets
	# give each semantic scene action a recognizable material family.
	var kind := "activity"
	if name_value.begins_with("Choice"):
		kind = "candidate" if stage == "recruit" else "activity"
	elif name_value.begins_with("Phase") or name_value == "ReturnToGallery":
		kind = "tab"
	elif name_value == "FormationPrimaryAction":
		kind = "commit"
	var b := Button.new()
	b.name = name_value
	b.text = caption
	Craft.apply_to(b, kind, selected, 52.0 if kind == "commit" else 48.0)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _choice(parent: Control, key: String, caption: String, selected: bool,
		action: Callable, x: float, y: float, width: float) -> void:
	var b: Button = _button(parent, "Choice" + key, caption, selected, action)
	_rect(b, x, y, width, 50)
	_choice_buttons[key] = b

func _ink() -> Color:
	return INK if phase == "day" else Color("#F3E9D7")

func _subtle() -> Color:
	return Color("#55666B") if phase == "day" else Color("#D5CEC2")

func _render() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_choice_buttons.clear()
	var viewport_size: Vector2 = get_viewport_rect().size
	var window: Vector2i = DisplayServer.window_get_size()
	_scale = maxf(float(window.x) / maxf(viewport_size.x, 1.0), 0.35)
	var w: float = viewport_size.x * _scale
	var h: float = viewport_size.y * _scale
	var narrow: bool = w < 760.0
	var bg := ColorRect.new()
	bg.name = "FormationBackdrop"
	bg.color = Color("#EDE5D7") if phase == "day" else (Color("#34444A") if phase == "dusk" else Color("#101820"))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface = Control.new()
	_surface.name = "FormationPhysicalSurface"
	_surface.scale = Vector2.ONE / _scale
	add_child(_surface)
	_rect(_surface, 0, 0, w, h)

	# Physical material carries the entire world: a lit wooden rehearsal desk.
	# Never use a single dim rehearsal photograph as the DAY background.
	var desk := TextureRect.new()
	desk.name = "FormationSunlitDesk"
	desk.texture = load("res://Art/UI/FormationCraft/rehearsal_desk.png")
	desk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desk.stretch_mode = TextureRect.STRETCH_SCALE
	desk.modulate = Color.WHITE if phase == "day" else (Color("#C4B4A5") if phase == "dusk" else Color("#696875"))
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.add_child(desk)
	_rect(desk, 0, 0, w, h)

	var head := Panel.new()
	head.name = "FormationHeader"
	head.add_theme_stylebox_override("panel", _style(PAPER if phase == "day" else Color("#1B2A31"),
		Color("#CDBB9E") if phase == "day" else Color("#647278"), 7, true))
	_surface.add_child(head)
	_rect(head, 12, 10, w - 24, 83)
	var title: Label = _label(head, "PlayerFacingTitle", "LIVIN’ THE DREAM", 22 if narrow else 28, _ink())
	_rect(title, 14, 8, w - (166 if narrow else 215), 38)
	var small: Label = _label(head, "ChapterLabel", "CH. 01  /  REHEARSAL" if narrow else "CHAPTER 01  /  THE FIRST REHEARSAL", 14, _subtle())
	_rect(small, 15, 49, w - (173 if narrow else 195), 25)
	var back: Button = _button(head, "ReturnToGallery", "GALLERY", false, _return_to_gallery)
	_rect(back, w - (129 if narrow else 165), 12, 107 if narrow else 142, 48)

	var chip_w := 87.0
	for i in range(PHASES.size()):
		var next_phase: String = PHASES[i]
		var chip: Button = _button(_surface, "Phase" + next_phase.capitalize(), next_phase.to_upper(),
			next_phase == phase, func() -> void: set_phase(next_phase))
		_rect(chip, 14 + i * (chip_w + 7), 101, chip_w, 46)

	var dock_h := 105.0
	var scroll := ScrollContainer.new()
	scroll.name = "FormationScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_surface.add_child(scroll)
	_rect(scroll, 0, 154, w, maxf(150, h - 154 - dock_h))
	var page := Control.new()
	page.name = "FormationNotebook"
	scroll.add_child(page)
	var page_w: float = minf(880.0, w - 24)
	var left: float = (w - page_w) * 0.5
	_rect(page, 0, 0, w, 970)
	page.custom_minimum_size = Vector2(w, 970)

	# Independent high-resolution scanned-paper-like notebook sits under native data.
	# Paper fibres, ruling, dog-ear and folded tape are pixels, not flat UI panels.
	var sheet := TextureRect.new()
	sheet.name = "FormationNotebookMaterial"
	sheet.texture = load("res://Art/UI/FormationCraft/rehearsal_notebook.png")
	sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.stretch_mode = TextureRect.STRETCH_SCALE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(sheet)
	_rect(sheet, left, 8, page_w, 936)
	var paper := Panel.new()
	paper.name = "ScrapbookPaper"
	paper.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), Color("#C1A985"), 5, true))
	paper.mouse_filter = Control.MOUSE_FILTER_PASS
	page.add_child(paper)
	_rect(paper, left, 8, page_w, 936)
	var pleft: float = 15
	var inner: float = page_w - 30
	var heading: Label = _label(paper, "StageHeading", {
		"recruit": "FIND YOUR PEOPLE", "social": "BE MORE THAN A LINE-UP",
		"rehearsal": "THE ROOM IS BOOKED", "summary": "YOUR FIRST CHAPTER"
	}[stage], 26 if narrow else 32, INK)
	_rect(heading, pleft, 15, inner, 44)
	var step: Label = _label(paper, "StageDescription", {
		"recruit": "Alex sings. Choose your drummer and bassist, then scroll for their notes.",
		"social": "A band is more than a set of instruments. Choose what you do together first.",
		"rehearsal": "The practice room smells of old carpet and warm amplifiers. What matters today?",
		"summary": "A line-up, an outing and one consequential rehearsal. No career save was changed."
	}[stage], 16, Color("#4B5B5D"))
	_rect(step, pleft, 63, inner, 64)

	var frame := Panel.new()
	frame.name = "FormationPhotoFrame"
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", _style(Color("#3D4645"), Color("#B59C74"), 4, true))
	paper.add_child(frame)
	_rect(frame, pleft, 132, inner, 169 if narrow else 248)
	var photo := TextureRect.new()
	photo.name = "RepoBackedFormationPhoto"
	photo.texture = load(ROOM_PHOTO)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(photo)
	_rect(photo, 3, 3, inner - 6, (169 if narrow else 248) - 6)
	var photo_tag := Panel.new()
	photo_tag.add_theme_stylebox_override("panel", _style(Color(0.10, 0.14, 0.16, 0.88), Color("#8D8577"), 3))
	frame.add_child(photo_tag)
	_rect(photo_tag, 10, (169 if narrow else 248) - 39, minf(inner - 20, 360), 30)
	var tag: Label = _label(photo_tag, "PhotoSource", "REPO ROOM PHOTO  /  ART HOLD", 13, Color("#F5EEE1"))
	_rect(tag, 8, 4, minf(inner - 35, 340), 24)

	var y: float = 323 if narrow else 401
	var strip := Panel.new()
	strip.name = "ReadOnlyBandLedger"
	strip.add_theme_stylebox_override("panel", _style(Color("#E7DDC9"), Color("#BDAA8B"), 3))
	paper.add_child(strip)
	_rect(strip, pleft, y, inner, 69)
	var stats: Label = _label(strip, "ReadOnlyStats",
		"DAY %d    CASH £%d    READY %d    TRUST %d" % [
			int(preview_state.get("tour_day", 1)), int(preview_state.get("cash", 120)),
			int(preview_state.get("readiness", 20)),
			int(preview_state.get("relationships", {}).get("0_1", 40))],
		16, INK)
	_rect(stats, 12, 8, inner - 24, 54)
	y += 83

	if stage == "recruit":
		if not narrow:
			_label_line(paper, "Singer", "ALEX VALE  /  singer  /  writes lyrics on train tickets", pleft, y, inner)
			y += 57
		_label_line(paper, "Drummer", "CHOOSE YOUR DRUMMER", pleft, y, inner)
		y += 29 if narrow else 39
		var half: float = (inner - 9) * 0.5
		_choice(paper, "Jo", "JO   ·   STEADY", drummer_id == "jo", func() -> void: choose_drummer("jo"), pleft, y, half)
		_choice(paper, "Rae", "RAE   ·   PRECISE", drummer_id == "rae", func() -> void: choose_drummer("rae"), pleft + half + 9, y, half)
		y += 55 if narrow else 60
		if not narrow:
			_label_line(paper, "DrummerPitch", str(_candidate(drummer_id)["pitch"]), pleft, y, inner)
			y += 63
		_label_line(paper, "Bass", "CHOOSE YOUR BASSIST", pleft, y, inner)
		y += 29 if narrow else 39
		_choice(paper, "Sam", "SAM   ·   CALM", bass_id == "sam", func() -> void: choose_bassist("sam"), pleft, y, half)
		_choice(paper, "Dev", "DEV   ·   CONNECTED", bass_id == "dev", func() -> void: choose_bassist("dev"), pleft + half + 9, y, half)
		y += 55 if narrow else 60
		if narrow:
			_label_line(paper, "DrummerPitch", "DRUMMER: " + str(_candidate(drummer_id)["pitch"]), pleft, y, inner)
			y += 66
			_label_line(paper, "BassPitch", "BASS: " + str(_candidate(bass_id)["pitch"]), pleft, y, inner)
		else:
			_label_line(paper, "BassPitch", str(_candidate(bass_id)["pitch"]), pleft, y, inner)
	elif stage == "social":
		_label_line(paper, "SocialPrompt", "THREE PEOPLE. ONE EVENING. WHICH FIRST?", pleft, y, inner)
		y += 49
		_choice(paper, "Dinner", "DINNER   ·   £24", outing_id == "dinner",
			func() -> void: choose_outing("dinner"), pleft, y, (inner - 9) * 0.5)
		_choice(paper, "LocalGig", "LOCAL GIG   ·   £15", outing_id == "watch_gig",
			func() -> void: choose_outing("watch_gig"), pleft + (inner + 9) * 0.5, y, (inner - 9) * 0.5)
		y += 64
		_label_line(paper, "SocialConsequence", "Dinner builds trust. Watching a local act adds buzz and readiness. Both take a day.", pleft, y, inner)
	elif stage == "rehearsal":
		_label_line(paper, "RehearsalPrompt", "REHEARSAL FOCUS  /  choose one", pleft, y, inner)
		y += 49
		_choice(paper, "Tighten", "DRILL SET   ·   £15", room_focus == "tighten",
			func() -> void: choose_room_focus("tighten"), pleft, y, (inner - 9) * 0.5)
		_choice(paper, "Connect", "CLEAR AIR   ·   £0", room_focus == "connect",
			func() -> void: choose_room_focus("connect"), pleft + (inner + 9) * 0.5, y, (inner - 9) * 0.5)
		y += 64
		_label_line(paper, "RehearsalConsequence", "A set drill builds readiness but costs money. A band conversation restores trust.", pleft, y, inner)
	else:
		_label_line(paper, "SummaryTitle", "FIRST SESSION COMPLETE  /  RESULTS", pleft, y, inner)
		y += 51
		_label_line(paper, "SummaryDetail", "The decisions were resolved once through the existing game rules. This is an isolated preview.", pleft, y, inner)
	y += 94
	_label_line(paper, "JournalHeading", "NOTES FROM THE ROOM", pleft, y, inner)
	y += 44
	var last: String = "Choose a line-up to start the story." if result_history.is_empty() else result_history[-1]
	var journal := RichTextLabel.new()
	journal.name = "JournalEntry"
	journal.bbcode_enabled = false
	journal.text = last
	journal.fit_content = false
	journal.scroll_active = false
	journal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal.add_theme_font_size_override("normal_font_size", 16)
	journal.add_theme_color_override("default_color", Color("#3D4B4D"))
	paper.add_child(journal)
	_rect(journal, pleft, y, inner, 94)
	var gate: Label = _label(paper, "MaterialGate", "REAL ROOM PHOTO  /  SCRAPBOOK MATERIAL: VISUAL HOLD", 14, Color("#745B35"))
	_rect(gate, pleft, y + 156, inner, 52)
	var paper_height: float = maxf(936.0, y + 226.0)
	sheet.size.y = paper_height
	paper.size.y = paper_height
	page.size.y = paper_height + 26.0
	page.custom_minimum_size = Vector2(w, paper_height + 26.0)

	var dock := Panel.new()
	dock.name = "FormationActionDock"
	dock.add_theme_stylebox_override("panel", _style(PAPER if phase == "day" else Color("#23343B"),
		Color("#C8B799") if phase == "day" else Color("#5C6B70"), 5, true))
	_surface.add_child(dock)
	_rect(dock, 12, h - dock_h + 5, w - 24, dock_h - 13)
	var action_text: String = {
		"recruit": "FORM THE BAND  /  3 MEMBERS",
		"social": "CONFIRM OUTING  /  ONE DAY",
		"rehearsal": "COMMIT REHEARSAL CHOICE",
		"summary": "CHAPTER COMPLETE  /  NO DOUBLE CHARGE"
	}[stage]
	_primary = _button(dock, "FormationPrimaryAction", action_text, true, commit_stage)
	_primary.disabled = stage == "summary" or (stage == "social" and outing_id.is_empty()) or (stage == "rehearsal" and room_focus.is_empty())
	_rect(_primary, 11, 8, w - 46, 52)
	var status_copy: String = "ISOLATED PREVIEW  /  %d SETTLED ACTIONS  /  NO SAVE WRITES" % settlement_count
	if narrow:
		status_copy = "PREVIEW  /  %d ACTIONS  /  NO SAVES" % settlement_count
	_status = _label(dock, "FormationStatus", status_copy, 14, _subtle())
	_rect(_status, 13, 65, w - 52, 23)

func _label_line(parent: Node, name_value: String, caption: String, x: float, y: float, width: float) -> void:
	var l: Label = _label(parent, name_value, caption, 16, INK)
	_rect(l, x, y, width, 59)

func _return_to_gallery() -> void:
	var destination := "res://poc/ldtd_career_scene_shell.tscn"
	if ResourceLoader.exists(destination):
		get_tree().change_scene_to_file(destination)
