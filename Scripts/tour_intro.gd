extends Control

const BG := Color("#101216")
const PANEL := Color("#1A1E24")
const AMBER := Color("#F0B44D")
const WHITE := Color("#F2F0E9")
const MUTED := Color("#9BA5B2")
const SAVE_PATH := "user://tour_save.json"
const BAND_PATH := "user://band_profile.json"

var band: Dictionary = {}
var cash := 120
var van_health := 45
var morale := 55
var reputation := 10
var readiness := 15
var tension := 10
var tour_day := 1
var rehearsal_number := 0
var current_event := "rehearsal"
var decisions: Dictionary = {}
var relationships: Dictionary = {}
var pending_next := ""
var last_outcome := ""
var page: VBoxContainer

func _ready() -> void:
	_load_band()
	_load_game()
	_normalize_members()
	_build_screen()

func _load_band() -> void:
	band = {"name": "The Feedback", "genre": "Post-punk", "influence": "Joy Division", "members": []}
	if not FileAccess.file_exists(BAND_PATH):
		return
	var file := FileAccess.open(BAND_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		band = parsed

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("NEW CAREER // REHEARSAL ROOM")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read save")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Invalid save JSON")
		return
	band = parsed.get("band", band)
	cash = int(parsed.get("cash", cash))
	van_health = int(parsed.get("van_health", van_health))
	morale = int(parsed.get("morale", morale))
	reputation = int(parsed.get("reputation", reputation))
	readiness = int(parsed.get("readiness", readiness))
	tension = int(parsed.get("tension", tension))
	tour_day = int(parsed.get("tour_day", tour_day))
	rehearsal_number = int(parsed.get("rehearsal_number", rehearsal_number))
	current_event = str(parsed.get("current_event", current_event))
	decisions = parsed.get("decisions", {})
	relationships = parsed.get("relationships", {})
	pending_next = str(parsed.get("pending_next", ""))
	last_outcome = str(parsed.get("last_outcome", ""))
	# Older Update 01 saves are supported; they resume where they stopped.
	print("GAME LOADED // ", current_event)

func _normalize_members() -> void:
	var members: Array = band.get("members", [])
	for i in range(members.size()):
		if members[i] is Dictionary:
			var member: Dictionary = members[i]
			member["id"] = i
			if not member.has("morale"):
				member["morale"] = 55
			if not member.has("loyalty"):
				member["loyalty"] = 60
			if not member.has("skill"):
				member["skill"] = 45
			if not member.has("fatigue"):
				member["fatigue"] = 5
			if not member.has("gender"):
				member["gender"] = "Not specified"
			if not member.has("note"):
				member["note"] = ""
	for i in range(members.size()):
		for j in range(i + 1, members.size()):
			var key := "%d_%d" % [i, j]
			if not relationships.has(key):
				relationships[key] = 50

func _save_game() -> void:
	var data := {
		"band": band, "cash": cash, "van_health": van_health,
		"morale": morale, "reputation": reputation,
		"readiness": readiness, "tension": tension,
		"tour_day": tour_day, "rehearsal_number": rehearsal_number,
		"current_event": current_event, "decisions": decisions,
		"relationships": relationships, "pending_next": pending_next,
		"last_outcome": last_outcome
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("GAME SAVED // ", current_event)

func _build_screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 36)
	scroll.add_child(margin)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	_label(page, "ROADIE // BAND CONTROL", 13, AMBER)
	_label(page, str(band.get("name", "Unknown Band")), 30, WHITE)
	_label(page, "%s / Influence: %s" % [band.get("genre", "Unknown"), band.get("influence", "Unknown")], 13, MUTED)
	_separator()
	_label(page, "BAND DASHBOARD", 15, AMBER)
	var stats := GridContainer.new()
	stats.columns = 3
	stats.add_theme_constant_override("h_separation", 18)
	stats.add_theme_constant_override("v_separation", 10)
	page.add_child(stats)
	_stat(stats, "CASH £%d" % cash, AMBER)
	_stat(stats, "VAN %d%%" % van_health, WHITE)
	_stat(stats, "MORALE %d" % morale, WHITE)
	_stat(stats, "READINESS %d" % readiness, WHITE)
	_stat(stats, "TENSION %d" % tension, WHITE)
	_stat(stats, "REPUTATION %d" % reputation, WHITE)
	_separator()
	_show_lineup()
	_separator()
	if pending_next != "":
		_label(page, "LATEST CONSEQUENCES", 19, AMBER)
		_label(page, last_outcome, 15, WHITE)
		_choice("CONTINUE  >", "Save progress and move to the next stage.", _advance)
		return
	match current_event:
		"rehearsal": _show_rehearsal()
		"booking": _show_booking()
		"travel": _show_travel()
		"van_problem": _show_legacy_van()
		"soundcheck": _show_soundcheck()
		"show": _show_gig()
		"aftershow": _show_aftershow()
		_: _label(page, "UNKNOWN STAGE: " + current_event, 16, AMBER)

func _show_lineup() -> void:
	var members: Array = band.get("members", [])
	_label(page, "THE LINE-UP // %d MEMBERS" % members.size(), 15, AMBER)
	if members.is_empty():
		_label(page, "No musicians recorded. Start a new band from the main menu.", 13, MUTED)
		return
	for member in members:
		if member is Dictionary:
			_label(page, "%s / %s / %s | morale %d | loyalty %d | skill %d | fatigue %d" % [str(member.get("name", "?")), str(member.get("role", "?")), str(member.get("trait", "?")), int(member.get("morale", 55)), int(member.get("loyalty", 60)), int(member.get("skill", 45)), int(member.get("fatigue", 5))], 12, MUTED)
	_label(page, "Relationships: %d/100 average" % _average_relationship(), 12, MUTED)

func _show_rehearsal() -> void:
	_label(page, "WEEK 01 // REHEARSAL %d OF 3" % (rehearsal_number + 1), 22, WHITE)
	_label(page, "A damp practice room behind a carpet warehouse. The landlord wants the rent up front. Nobody agrees on the tempo. You have three sessions to get good enough to book a gig.", 15, WHITE)
	_label(page, "HOW DO YOU USE THIS SESSION?", 16, AMBER)
	_choice("A // DRILL THE SET", "Tighter playing, more fatigue; perfectionists approve.", func(): _rehearse("drill"))
	_choice("B // WRITE SOMETHING NEW", "Creative progress, but a less reliable live set.", func(): _rehearse("write"))
	_choice("C // CLEAR THE AIR", "Build trust and relieve tension; less rehearsal progress.", func(): _rehearse("bond"))

func _rehearse(action: String) -> void:
	if cash < 15:
		_commit("The rehearsal room owner refuses to hand over the keys until you pay. You scrape together a free practice outdoors.", "booking")
		return
	cash -= 15
	rehearsal_number += 1
	var story := ""
	match action:
		"drill":
			readiness += 24
			tension += 9
			_change_members(2, -4, 8)
			if _has_trait("Perfectionist") or _has_trait("Control freak"):
				readiness += 6
				tension += 3
			story = "You run the set until everyone knows the changes. The perfectionists are delighted. The others are starting to resent the metronome."
		"write":
			readiness += 15
			reputation += 2
			tension += 2
			_change_members(3, 1, 5)
			if _has_trait("Unreliable genius"):
				readiness += 5
			story = "You stumble onto a new song. Half the band thinks it is a masterpiece; nobody is certain how it ends."
		"bond":
			readiness += 8
			tension -= 13
			morale += 8
			_change_members(8, 4, -4)
			_change_relationships(9)
			if _has_trait("Peacemaker"):
				tension -= 5
			story = "The group finally talks instead of shouting over the amplifiers. The set is still rough, but at least everyone wants to be here."
	decisions["rehearsal_%d" % rehearsal_number] = action
	_clamp_all()
	var target := "rehearsal"
	if rehearsal_number >= 3:
		target = "booking"
		story += " Three sessions are up. Time to see whether a venue will take you."
	_commit(story, target)

func _show_booking() -> void:
	_label(page, "WEEK 02 // FIND A FIRST GIG", 22, WHITE)
	_label(page, "A local promoter has one opening at The Toadstool. You have never played a proper show together. They want to know whether you can bring a crowd.", 15, WHITE)
	_label(page, "THE OFFER", 16, AMBER)
	_choice("A // PAY TO PLAY", "Pay £30 for a support slot. Easier to secure, but risky.", func(): _book("pay"))
	_choice("B // TALK YOUR WAY IN", "Pitch the act. Readiness and reputation matter.", func(): _book("pitch"))
	_choice("C // FREE SHOWCASE", "Play a community event first. Gain confidence, lose time.", func(): _book("showcase"))

func _book(action: String) -> void:
	var story := ""
	match action:
		"pay":
			if cash >= 30:
				cash -= 30
				morale -= 4
				story = "The promoter pockets your thirty quid. You have a slot, although everyone feels slightly exploited."
			else:
				tension += 8
				story = "You cannot afford the fee. After some awkward bargaining, the promoter agrees to let you open for free."
		"pitch":
			if readiness + reputation >= 90:
				reputation += 8
				morale += 6
				story = "Your rehearsal recording convinces the promoter. They offer a modest guaranteed fee if you bring an audience."
			else:
				tension += 6
				story = "The promoter is unconvinced, but gives you the opening slot nobody else wanted."
		"showcase":
			readiness += 12
			morale += 5
			reputation += 4
			tour_day += 3
			story = "The community-centre showcase goes well enough to earn a first booking. Your friends promise to come. Some of them might mean it."
	decisions["booking"] = action
	_clamp_all()
	_commit(story, "travel")

func _show_travel() -> void:
	_label(page, "DAY %02d // THE ROAD TO THE TOADSTOOL" % tour_day, 22, WHITE)
	_label(page, "You've got a gig, a questionable van and precisely one working map app. Halfway there, the engine begins to make an expensive noise.", 15, WHITE)
	_choice("A // PAY THE MECHANIC", "Spend £60 to improve the van.", func(): _travel("repair"))
	_choice("B // IGNORE THE NOISE", "Keep the money, risk a breakdown.", func(): _travel("ignore"))
	_choice("C // ASK THE BAND TO FIX IT", "Personality and skills may help — or not.", func(): _travel("band"))

func _travel(action: String) -> void:
	var story := ""
	match action:
		"repair":
			if cash >= 60:
				cash -= 60
				van_health += 35
				morale += 3
				story = "A mechanic replaces the failing belt. The van makes it to the venue. The singer questions the expense."
			else:
				van_health -= 12
				story = "You cannot afford a mechanic. A roadside patch gets you moving, but the engine is not happy."
		"ignore":
			van_health -= 24
			morale -= 7
			tension += 5
			story = "The noise gets louder. The drummer claims it is harmonising with the bass line."
		"band":
			if _has_trait("Chaos agent"):
				van_health += 12
				morale += 4
				story = "Against all evidence, your most chaotic musician fixes the van. There are a few spare parts."
			else:
				van_health -= 13
				tension += 5
				story = "After an hour under the bonnet, the van now makes two noises instead of one."
	decisions["van_problem"] = action
	_clamp_all()
	_commit(story, "soundcheck")

func _show_legacy_van() -> void:
	# Compatibility with Update 01 save files that have not reached soundcheck.
	_label(page, "DAY 01 // PREVIOUS TOUR SAVE", 22, WHITE)
	_label(page, "Your earlier save is preserved. Continue to the soundcheck, or start a new career for the rehearsal-led progression.", 15, WHITE)
	_choice("CONTINUE TO SOUND CHECK  >", "Keep your existing progress.", func(): _commit("The band arrives at The Toadstool.", "soundcheck"))

func _show_soundcheck() -> void:
	_label(page, "DAY %02d // SOUND CHECK" % tour_day, 22, WHITE)
	_label(page, "The promoter has a request: play forty extra minutes for no extra pay. Your tightness as a band and your previous bargaining decisions will affect what happens next.", 15, WHITE)
	_choice("A // DEMAND PAYMENT", "Stand your ground; risk losing goodwill.", func(): _soundcheck("demand"))
	_choice("B // PLAY FOR EXPOSURE", "Win local goodwill, but drain the band.", func(): _soundcheck("exposure"))
	_choice("C // NEGOTIATE BAR TAKINGS", "A calculated gamble on the crowd.", func(): _soundcheck("bar"))

func _soundcheck(action: String) -> void:
	var story := ""
	match action:
		"demand":
			if readiness >= 60:
				cash += 35
				reputation += 3
				story = "The promoter has heard your rehearsal tape and reluctantly finds another £35."
			else:
				tension += 10
				reputation -= 2
				story = "The promoter calls your bluff. You keep the slot, but soundcheck is icy."
		"exposure":
			reputation += 8
			morale -= 8
			_change_members(-5, -2, 10)
			story = "The promoter beams. The band less so: you have just volunteered their evening for free."
		"bar":
			if reputation + readiness >= 105:
				cash += 48
				morale += 4
				story = "The room fills, the bar sells out of lager and your share is £48."
			else:
				cash += 8
				tension += 5
				story = "A handful of regulars buy pints. Your share is £8 and a packet of crisps."
	decisions["soundcheck"] = action
	_clamp_all()
	_commit(story, "show")

func _show_gig() -> void:
	_label(page, "DAY %02d // FIRST GIG" % tour_day, 22, WHITE)
	_label(page, "The lights dim. There are real people out there. Your band has to decide what kind of show to put on.", 15, WHITE)
	_choice("A // PLAY IT SAFE", "Stick to the rehearsed set.", func(): _gig("safe"))
	_choice("B // GO FULL CHAOS", "An unpredictable show that could build a following.", func(): _gig("chaos"))
	_choice("C // MAKE IT PERSONAL", "Talk to the crowd; invest in connection.", func(): _gig("connect"))

func _gig(action: String) -> void:
	var quality := readiness + int((morale - tension) / 3.0) - int(_average_fatigue() / 3.0)
	var story := ""
	match action:
		"safe":
			if quality >= 65:
				cash += 45
				reputation += 12
				story = "A confident, tight set. Someone from a nearby venue asks for your details."
			else:
				cash += 20
				reputation += 3
				story = "A shaky but respectable debut. You get through every song. Mostly."
		"chaos":
			if _has_trait("Chaos agent") and morale >= 48:
				cash += 35
				reputation += 16
				tension += 5
				story = "The chaotic encore becomes the story of the night. It could have been a disaster."
			else:
				cash += 10
				reputation -= 3
				tension += 12
				story = "An ambitious onstage experiment ends in feedback and a furious sound engineer."
		"connect":
			cash += 28
			morale += 8
			reputation += 8
			_change_relationships(4)
			story = "You win over the room with humour and a good story. A few people buy your homemade merch."
	decisions["first_gig"] = action
	_clamp_all()
	_commit(story, "aftershow")

func _show_aftershow() -> void:
	_label(page, "AFTER THE SHOW // CAREER LOG", 22, WHITE)
	_label(page, "Your first chapter is complete. The band is no longer an idea on a beer mat.", 15, WHITE)
	_label(page, "REHEARSAL CHOICES: %s / %s / %s" % [str(decisions.get("rehearsal_1", "legacy")), str(decisions.get("rehearsal_2", "legacy")), str(decisions.get("rehearsal_3", "legacy"))], 14, AMBER)
	_label(page, "BOOKING: %s  |  VAN: %s  |  SOUND CHECK: %s  |  GIG: %s" % [str(decisions.get("booking", "legacy")), str(decisions.get("van_problem", "-")), str(decisions.get("soundcheck", "-")), str(decisions.get("first_gig", "-"))], 13, WHITE)
	_label(page, "The next update will expand tours, members' relationships and long-term careers. All current progress is saved.", 14, MUTED)
	_choice("RETURN TO MAIN MENU", "Continue this save when the next chapter is added.", _menu)

func _change_members(morale_delta: int, loyalty_delta: int, fatigue_delta: int) -> void:
	var members: Array = band.get("members", [])
	for member in members:
		if member is Dictionary:
			member["morale"] = clampi(int(member.get("morale", 55)) + morale_delta, 0, 100)
			member["loyalty"] = clampi(int(member.get("loyalty", 60)) + loyalty_delta, 0, 100)
			member["fatigue"] = clampi(int(member.get("fatigue", 5)) + fatigue_delta, 0, 100)

func _change_relationships(amount: int) -> void:
	for key in relationships.keys():
		relationships[key] = clampi(int(relationships[key]) + amount, 0, 100)

func _average_relationship() -> int:
	if relationships.is_empty():
		return 50
	var total := 0
	for value in relationships.values():
		total += int(value)
	return int(round(float(total) / float(relationships.size())))

func _average_fatigue() -> int:
	var members: Array = band.get("members", [])
	if members.is_empty():
		return 0
	var total := 0
	for member in members:
		if member is Dictionary:
			total += int(member.get("fatigue", 0))
	return int(round(float(total) / float(members.size())))

func _has_trait(trait_name: String) -> bool:
	for member in band.get("members", []):
		if member is Dictionary and str(member.get("trait", "")) == trait_name:
			return true
	return false

func _clamp_all() -> void:
	cash = maxi(0, cash)
	van_health = clampi(van_health, 0, 100)
	morale = clampi(morale, 0, 100)
	reputation = clampi(reputation, 0, 100)
	readiness = clampi(readiness, 0, 100)
	tension = clampi(tension, 0, 100)

func _commit(story: String, next_event: String) -> void:
	last_outcome = story
	pending_next = next_event
	_save_game()
	_build_screen()

func _advance() -> void:
	current_event = pending_next
	pending_next = ""
	last_outcome = ""
	_save_game()
	_build_screen()

func _menu() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _stat(parent: GridContainer, value: String, color: Color) -> void:
	var item := _label(parent, value, 14, color)
	item.custom_minimum_size.x = 180

func _choice(title: String, description: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title + "\n" + description
	button.custom_minimum_size.y = 68
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_stylebox_override("normal", _style(PANEL))
	button.add_theme_stylebox_override("hover", _style(Color("#303640")))
	button.pressed.connect(callback)
	page.add_child(button)

func _label(parent: Control, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _separator() -> void:
	page.add_child(HSeparator.new())

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	return style
