extends Control

const CareerActions = preload("res://Scripts/career_actions.gd")
const CareerOpportunities = preload("res://Scripts/career_opportunities.gd")
const UKGigs = preload("res://Scripts/uk_gig_circuit.gd")
const GearShop = preload("res://Scripts/gear_shop.gd")
const MemberManagement = preload("res://Scripts/member_management.gd")

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
var career_extra: Dictionary = {"songs": 0, "gear": 0, "buzz": 0, "press": 0, "fans": 0, "action_count": 0, "action_counters": {}, "opportunities_seen": {}, "opportunities_resolved": {}, "demos": 0, "gig_history": [], "owned_equipment": []}
var career_feedback := ""
var career_tab := "HOME"
var selected_venue := ""
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
	var saved_extra = parsed.get("career_extra", {})
	if saved_extra is Dictionary:
		career_extra.merge(saved_extra, true)
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
		"last_outcome": last_outcome, "career_extra": career_extra
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
	if current_event == "aftershow" and pending_next.is_empty():
		scroll.offset_bottom = 0
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
	if current_event == "aftershow" and pending_next.is_empty():
		_show_compact_career_header()
	else:
		_label(page, "LIVIN' THE DREAM  //  BRITISH MUSIC SCENE", 13, AMBER)
		_label(page, str(band.get("name","Unknown Band")), 30, WHITE)
		_label(page, "%s / Influence: %s" % [str(band.get("genre","Unknown")),str(band.get("influence","Unknown"))], 13, MUTED)
		_separator()
		_label(page, "BAND DASHBOARD", 15, AMBER)
		var stats := GridContainer.new()
		stats.columns = 3
		stats.add_theme_constant_override("h_separation",18)
		stats.add_theme_constant_override("v_separation",10)
		page.add_child(stats)
		_stat(stats, "CASH £%d" % cash, AMBER)
		_stat(stats, "VAN %d%%" % van_health, WHITE)
		_stat(stats, "MORALE %d" % morale, WHITE)
		_stat(stats, "READINESS %d" % readiness, WHITE)
		_stat(stats, "TENSION %d" % tension, WHITE)
		_stat(stats, "REPUTATION %d" % reputation, WHITE)
	if current_event != "aftershow":
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

func _show_compact_career_header() -> void:
	_label(page, "LIVIN' THE DREAM  /  UK GRASSROOTS", 12, AMBER)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	page.add_child(top)
	var band_label := _label(top,str(band.get("name","Unknown Band")),27,WHITE)
	band_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(top,"DAY %d" % tour_day,15,AMBER)
	_label(page, "%s   ·   CASH £%d   ·   FANS %d   ·   REP %d" % [
		str(band.get("genre","Unknown")),cash,int(career_extra.get("fans",0)),reputation],14,WHITE)


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
	_label(page, "CAREER HQ", 22, AMBER)
	_label(page, "The first gig is complete. Enter the rebuilt career hub to manage your band.", 16, WHITE)
	_choice("ENTER CAREER HQ", "Gigs, gear, band members and the local scene.", _open_career_hub)
	_choice("BACK TO MAIN MENU", "Your existing save is preserved.", _menu)


func _open_career_hub() -> void:
	current_event = "aftershow"
	pending_next = ""
	_save_game()
	get_tree().change_scene_to_file("res://Scenes/CareerHub.tscn")


func _show_scene_banner() -> void:
	var themes := {
		"HOME": ["LOCAL SCENE  //  YOUR NEXT MOVE", Color("#2C3136")],
		"GIGS": ["ON THE ROAD  //  UK LIVE CIRCUIT", Color("#293645")],
		"GEAR": ["MUSIC SHOP  //  SECOND-HAND FINDS", Color("#433528")],
		"BAND": ["THE LINE-UP  //  PEOPLE & PERSONALITIES", Color("#334137")],
		"ACTIONS": ["REHEARSAL LOCK-UP  //  DAY TO DAY", Color("#37313F")],
		"SCENE": ["LOCAL PRESS  //  GET THE WORD OUT", Color("#293D45")]
	}
	var theme: Array = themes.get(career_tab, themes["HOME"])
	var banner := PanelContainer.new()
	var box_style := _style(theme[1])
	box_style.set_content_margin_all(22)
	banner.add_theme_stylebox_override("panel", box_style)
	banner.custom_minimum_size.y = 132
	page.add_child(banner)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.add_child(copy)
	var asset_paths := {
		"HOME":"res://Art/uk_street_banner.svg",
		"GIGS":"res://Art/uk_gigs_banner.svg",
		"GEAR":"res://Art/uk_gear_banner.svg",
		"BAND":"res://Art/uk_band_banner.svg",
		"ACTIONS":"res://Art/uk_actions_banner.svg",
		"SCENE":"res://Art/uk_scene_banner.svg"
	}
	var image_path: String = str(asset_paths.get(career_tab,asset_paths["HOME"]))
	if ResourceLoader.exists(image_path):
		var art := TextureRect.new()
		art.texture = load(image_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.custom_minimum_size.y = 110
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(art)
	_label(copy, str(theme[0]), 16, WHITE)
	_label(copy, "LIVIN' THE DREAM  /  BRITISH GRASSROOTS", 12, AMBER)


func _show_home_dashboard() -> void:
	_show_opportunities()
	var fans := int(career_extra.get("fans",0))
	var next_venue: Dictionary = {}
	for venue in UKGigs.VENUES:
		if reputation < int(venue["min_rep"]) or fans < int(venue["min_fans"]):
			next_venue = venue
			break
	if next_venue.is_empty():
		_section("NATIONAL CIRCUIT UNLOCKED","You can now book every venue in the current British circuit.")
		_choice("BROWSE ALL GIGS","Choose the next city.",func() -> void: _set_career_tab("GIGS"))
	else:
		var missing_fans := maxi(0,int(next_venue["min_fans"]) - fans)
		var missing_rep := maxi(0,int(next_venue["min_rep"]) - reputation)
		_section("NEXT OBJECTIVE  //  " + str(next_venue["city"]),
			"Need %d more fans and %d more reputation to unlock %s." % [missing_fans,missing_rep,str(next_venue["venue"])])
		_meter("FANS", fans, maxi(1,int(next_venue["min_fans"])))
		_meter("REPUTATION", reputation, maxi(1,int(next_venue["min_rep"])))
		if missing_fans > 0:
			_choice("PLAY A HOMETOWN GIG","Earn fans and cash, even with a worn-out van.",func() -> void: _set_career_tab("GIGS"))
			_choice("PROMOTE THE BAND — £25","Posters attract new fans and create buzz.",func() -> void: _take_career_action("promo"))
		else:
			_choice("BUILD YOUR REPUTATION","Book another gig to attract promoters.",func() -> void: _set_career_tab("GIGS"))
	_section("TODAY'S BAND PULSE","Your resources determine how well the next gig goes.")
	_meter("READINESS", readiness, 100)
	_meter("MORALE", morale, 100)
	_meter("VAN", van_health, 100)
	_label(page,"SONGS %d  /  DEMOS %d  /  GEAR %d" % [
		int(career_extra.get("songs",0)),int(career_extra.get("demos",0)),int(career_extra.get("gear",0))],15,WHITE)
	_label(page,"QUICK ACTIONS",17,AMBER)
	_choice("BOOK A GIG","Explore local and regional venues.",func() -> void: _set_career_tab("GIGS"))
	_choice("WRITE A SONG","Free  /  one day.",func() -> void: _take_career_action("songwrite"))
	_choice("REHEARSE — £15","One day  /  increase readiness.",func() -> void: _take_career_action("rehearse"))


func _show_band_cards() -> void:
	_section("THE BAND", "These are the people who have to live with your decisions.")
	var members: Array = band.get("members", [])
	if members.is_empty():
		_label(page, "No musicians on record.", 15, MUTED)
	for member in members:
		if member is Dictionary:
			var heading := "%s  //  %s" % [str(member.get("name","Unknown")), str(member.get("role","Musician"))]
			var detail := "%s  /  %s" % [str(member.get("trait","")),str(member.get("gender",""))]
			_section(heading, detail)
			_meter("SKILL", int(member.get("skill",45)),100)
			_meter("MORALE", int(member.get("morale",55)),100)
			_meter("LOYALTY", int(member.get("loyalty",60)),100)
			_meter("FATIGUE", int(member.get("fatigue",5)),100)
			var member_id: int = int(member.get("id",members.find(member)))
			_choice("TALK TO %s" % str(member.get("name","MEMBER")), "Free  /  improve loyalty and morale.", func() -> void: _manage_member(member_id,"chat"))
			_choice("COACH MUSICIAN — £10", "Improve their skill. Adds fatigue.", func() -> void: _manage_member(member_id,"coach"))
			_choice("GIVE INDIVIDUAL BREAK", "Free  /  reduce fatigue.", func() -> void: _manage_member(member_id,"break"))
	_label(page, "BAND RELATIONSHIPS  %d / 100" % _average_relationship(), 15, AMBER)
	_choice("GIVE THE BAND A DAY OFF", "Free  /  one day  /  restore morale.", func() -> void: _take_career_action("rest"))
	_choice("HAVE A REHEARSAL — £15", "One day  /  tighten the band's playing.", func() -> void: _take_career_action("rehearse"))


func _manage_member(member_id: int, option_id: String) -> void:
	var state := {"members": band.get("members",[]), "relationships": relationships, "cash": cash, "tour_day": tour_day, "readiness": readiness, "tension": tension}
	var result: Dictionary = MemberManagement.resolve(state,member_id,option_id)
	career_feedback = str(result.get("message","Action unavailable"))
	if result.get("ok",false) == true:
		var updated: Dictionary = result["state"]
		band["members"] = updated["members"]
		relationships = updated["relationships"]
		cash = int(updated["cash"])
		tour_day = int(updated["tour_day"])
		readiness = int(updated["readiness"])
		tension = int(updated["tension"])
		_clamp_all()
		_save_game()
	_build_screen()


func _section(heading: String, detail: String) -> void:
	var panel := PanelContainer.new()
	var panel_style := _style(Color("#222B35"))
	panel_style.border_color = Color("#495666")
	panel_style.border_width_left = 4
	panel.add_theme_stylebox_override("panel", panel_style)
	page.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	_label(content, heading, 18, AMBER)
	_label(content, detail, 15, WHITE)


func _meter(label_text: String, amount: int, total: int) -> void:
	var row := HBoxContainer.new()
	page.add_child(row)
	var name_label := _label(row, label_text, 13, MUTED)
	name_label.custom_minimum_size.x = 155
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxf(1.0,float(total))
	bar.value = clampf(float(amount),0.0,bar.max_value)
	bar.show_percentage = false
	bar.custom_minimum_size.y = 22
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	var amount_label := _label(row, str(amount), 13, WHITE)
	amount_label.custom_minimum_size.x = 44


func _build_bottom_nav() -> void:
	# Separate from the scroll content: tabs remain reachable on smaller monitors/phones.
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -108
	bottom.offset_bottom = 0
	bottom.add_theme_stylebox_override("panel", _style(Color("#18212A")))
	add_child(bottom)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 3)
	bottom.add_child(grid)
	for destination in ["HOME", "GIGS", "GEAR", "BAND", "ACTIONS", "SCENE"]:
		var target: String = destination
		var button := Button.new()
		button.text = destination
		button.custom_minimum_size = Vector2(0, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", _style(AMBER if destination == career_tab else PANEL))
		button.add_theme_color_override("font_color", BG if destination == career_tab else WHITE)
		button.pressed.connect(func() -> void: _set_career_tab(target))
		grid.add_child(button)


func _set_career_tab(tab: String) -> void:
	career_tab = tab
	_build_screen()


func _show_gear() -> void:
	_section("THE SECOND-HAND SHOP", "A British backstreet music shop. Buy actual equipment for your band's growing backline.")
	_meter("LIVE READINESS", readiness, 100)
	var owned: Array = career_extra.get("owned_equipment", [])
	_label(page, "OWNED EQUIPMENT // %d ITEMS" % owned.size(), 17, AMBER)
	if owned.is_empty():
		_label(page, "Nothing purchased yet. Your existing rehearsal gear still works.", 14, MUTED)
	for item in GearShop.ITEMS:
		if owned.has(item["id"]):
			_section(str(item["name"]) + "  //  OWNED", str(item["description"]))
	_label(page, "FOR SALE", 18, AMBER)
	for item in GearShop.ITEMS:
		if owned.has(item["id"]):
			continue
		var item_id: String = str(item["id"])
		_section(str(item["type"]) + "  //  " + str(item["name"]), str(item["description"]))
		_choice("BUY FOR £%d" % int(item["price"]), "+%d live readiness  /  1 day" % int(item["readiness"]), func() -> void: _purchase_equipment(item_id))
	_choice("REHEARSE — £15", "Improve readiness with the equipment you already have.", func() -> void: _take_career_action("rehearse"))


func _purchase_equipment(item_id: String) -> void:
	var state := career_extra.duplicate(true)
	state["cash"] = cash
	state["tour_day"] = tour_day
	state["readiness"] = readiness
	var result: Dictionary = GearShop.buy(state, item_id)
	career_feedback = str(result.get("message", "Purchase unavailable"))
	if result.get("ok",false) == true:
		var updated: Dictionary = result["state"]
		cash = int(updated["cash"])
		tour_day = int(updated["tour_day"])
		readiness = int(updated["readiness"])
		for key in ["cash","tour_day","readiness"]:
			updated.erase(key)
		career_extra = updated
		_clamp_all()
		_save_game()
	_build_screen()


func _show_circuit() -> void:
	_section("BOOK A BRITISH GIG", "Build a reputation locally, then branch out to regional venues. Every booking costs travel and wears the van.")
	_meter("VAN CONDITION", van_health, 100)
	for venue in UKGigs.VENUES:
		var venue_id: String = str(venue["id"])
		var unlocked := reputation >= int(venue["min_rep"]) and int(career_extra.get("fans",0)) >= int(venue["min_fans"])
		var description := "%s  /  fee £%d  /  travel £%d  /  %d days" % [str(venue["city"]),int(venue["fee"]),int(venue["travel"]),int(venue["days"])]
		if unlocked:
			_choice(str(venue["venue"]), description, func() -> void: _select_venue(venue_id))
		else:
			_label(page, "%s — %s LOCKED" % [str(venue["venue"]),str(venue["city"])], 14, AMBER)
			_label(page, "Requires reputation %d and fans %d" % [int(venue["min_rep"]),int(venue["min_fans"])], 13, MUTED)
	if not selected_venue.is_empty():
		var selected: Dictionary = UKGigs.get_venue(selected_venue)
		if not selected.is_empty():
			_section("CONFIRM BOOKING: " + str(selected["venue"]), "%s  /  £%d fee before travel costs" % [str(selected["city"]),int(selected["fee"])])
			for approach_id in UKGigs.APPROACHES:
				var tactic: String = str(approach_id)
				var details: Dictionary = UKGigs.APPROACHES[tactic]
				_choice(str(details["label"]), "Play the show with this approach.", func() -> void: _book_regional_gig(selected_venue,tactic))
			_choice("CANCEL BOOKING", "Return to available venues.", func() -> void: _select_venue(""))
	var gigs: Array = career_extra.get("gig_history", [])
	if not gigs.is_empty():
		_label(page, "RECENT GIGS", 16, AMBER)
		for i in range(gigs.size() - 1, maxi(-1,gigs.size() - 4), -1):
			var gig: Dictionary = gigs[i]
			_label(page, "%s / %s — £%d" % [str(gig.get("city","")),str(gig.get("venue","")),int(gig.get("fee",0))], 13, MUTED)
	_choice("FIX THE VAN — £45", "Repair 30 condition points; costs one day.", _repair_van)


func _select_venue(venue_id: String) -> void:
	selected_venue = venue_id
	_build_screen()


func _book_regional_gig(venue_id: String, approach: String = "tight") -> void:
	var state := career_extra.duplicate(true)
	state["cash"] = cash
	state["tour_day"] = tour_day
	state["reputation"] = reputation
	state["van_health"] = van_health
	state["morale"] = morale
	state["tension"] = tension
	state["readiness"] = readiness
	var result: Dictionary = UKGigs.play(state, venue_id, approach)
	career_feedback = str(result.get("message","Booking unavailable"))
	if result.get("ok",false) == true:
		var updated: Dictionary = result["state"]
		cash = int(updated["cash"])
		tour_day = int(updated["tour_day"])
		reputation = int(updated["reputation"])
		van_health = int(updated["van_health"])
		morale = int(updated["morale"])
		tension = int(updated["tension"])
		for key in ["cash","tour_day","reputation","van_health","morale","tension","readiness"]:
			updated.erase(key)
		career_extra = updated
		selected_venue = ""
		_clamp_all()
		_save_game()
	_build_screen()


func _repair_van() -> void:
	if cash < 45:
		career_feedback = "You need £45 for the mechanic."
	else:
		cash -= 45
		tour_day += 1
		van_health = clampi(van_health + 30,0,100)
		career_feedback = "The local garage gets the van roadworthy again."
		_save_game()
	_build_screen()


func _show_opportunities() -> void:
	var pending: Array = CareerOpportunities.pending(career_extra)
	if pending.is_empty():
		return
	_label(page, "NEW OPPORTUNITIES // %d" % pending.size(), 19, AMBER)
	var event_id: String = str(pending[0])
	var event: Dictionary = CareerOpportunities.get_event(event_id)
	_label(page, str(event.get("title", "AN OPPORTUNITY")), 18, WHITE)
	_label(page, str(event.get("intro", "")), 15, WHITE)
	for choice in event.get("choices", []):
		var key: String = str(choice.get("id", ""))
		_choice(str(choice.get("label", "DECIDE")), "Cost £%d" % int(choice.get("cost", 0)), func() -> void: _choose_opportunity(event_id, key))


func _choose_opportunity(event_id: String, choice_id: String) -> void:
	var state := career_extra.duplicate(true)
	state["cash"] = cash
	state["tour_day"] = tour_day
	state["morale"] = morale
	state["tension"] = tension
	state["reputation"] = reputation
	state["readiness"] = readiness
	state["van_health"] = van_health
	var result: Dictionary = CareerOpportunities.resolve(state, event_id, choice_id)
	career_feedback = str(result.get("message", "Opportunity unavailable"))
	if result.get("ok", false) == true:
		var updated: Dictionary = result["state"]
		cash = int(updated["cash"])
		tour_day = int(updated["tour_day"])
		morale = int(updated["morale"])
		tension = int(updated["tension"])
		reputation = int(updated["reputation"])
		readiness = int(updated["readiness"])
		van_health = int(updated["van_health"])
		for key in ["cash", "tour_day", "morale", "tension", "reputation", "readiness", "van_health"]:
			updated.erase(key)
		career_extra = updated
		_clamp_all()
		_save_game()
	_build_screen()


func _take_career_action(action_id: String) -> void:
	var state := career_extra.duplicate(true)
	state["cash"] = cash
	state["tour_day"] = tour_day
	state["morale"] = morale
	state["readiness"] = readiness
	state["tension"] = tension
	state["band_name"] = str(band.get("name", "The band"))
	var result: Dictionary = CareerActions.resolve(state, action_id)
	career_feedback = str(result.get("message", "Action unavailable"))
	if result.get("ok", false) == true:
		var updated: Dictionary = result["state"]
		cash = int(updated["cash"])
		tour_day = int(updated["tour_day"])
		morale = int(updated["morale"])
		readiness = int(updated["readiness"])
		tension = int(updated["tension"])
		updated.erase("cash")
		updated.erase("tour_day")
		updated.erase("morale")
		updated.erase("readiness")
		updated.erase("tension")
		updated.erase("band_name")
		career_extra = updated
		_clamp_all()
		_save_game()
	_build_screen()

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
	button.custom_minimum_size.y = 92
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_stylebox_override("normal", _style(PANEL))
	button.add_theme_stylebox_override("hover", _style(Color("#303640")))
	button.add_theme_stylebox_override("pressed", _style(AMBER))
	button.add_theme_color_override("font_pressed_color", BG)
	button.add_theme_font_size_override("font_size", 16)
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
