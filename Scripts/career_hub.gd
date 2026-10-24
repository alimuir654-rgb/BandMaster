extends Control

const UI = preload("res://Scripts/ui_theme.gd")
const Components = preload("res://Scripts/ui_components.gd")
const Presentation = preload("res://Scripts/career_presentation.gd")
const Scrapbook = preload("res://Scripts/scrapbook_filter.gd")
const LocalDialogue = preload("res://Scripts/local_dialogue_adapter.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const GigNight = preload("res://Scripts/gig_night_flow.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const SongStudio = preload("res://Scripts/song_studio_presentation.gd")
const Social = preload("res://Scripts/band_social.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Members = preload("res://Scripts/member_management.gd")
const Story = preload("res://Scripts/career_story.gd")
const Chapters = preload("res://Scripts/career_chapters.gd")
const Director = preload("res://Scripts/first_month_director.gd")
const OpeningHandoff = preload("res://Scripts/opening_handoff.gd")
const CareerLayout = preload("res://Scripts/career_layout.gd")
const Portrait = preload("res://Scripts/member_portrait.gd")
const Motion = preload("res://Scripts/career_motion.gd")
const Drama = preload("res://Scripts/band_drama.gd")
const Life = preload("res://Scripts/member_life.gd")
const BandPulse = preload("res://Scripts/band_pulse_presentation.gd")
const Chemistry = preload("res://Scripts/band_chemistry_presentation.gd")
const SAVE_PATH := "user://tour_save.json"
const TABS := ["HOME","GIGS","GEAR","BAND","ACTIONS","SCENE"]
const ART := {
 "HOME":"res://Art/uk_street_banner.svg",
 "GIGS":"res://Art/uk_gigs_banner.svg",
 "GEAR":"res://Art/uk_gear_banner.svg",
 "BAND":"res://Art/uk_band_banner.svg",
 "ACTIONS":"res://Art/uk_actions_banner.svg",
 "SCENE":"res://Art/uk_scene_banner.svg"
}
var save_data: Dictionary = {}
var tab := "HOME"
var message := ""
var content: VBoxContainer
var scrapbook_filter := "ALL"
var action_view := "JAM"
var dialogue_request: HTTPRequest
var dialogue_busy := false
var dialogue_serial := 0

func _ready() -> void:
 _load()
 _render()

func _load() -> void:
 if not FileAccess.file_exists(SAVE_PATH):
  push_error("CareerHub requires a career save.")
  return
 var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
 if file == null:
  return
 var parsed = JSON.parse_string(file.get_as_text())
 file.close()
 if parsed is Dictionary:
  save_data = OpeningHandoff.migrate(parsed)
  if save_data != parsed:
   _save()
 if not save_data.has("career_extra") or not save_data["career_extra"] is Dictionary:
  save_data["career_extra"] = {}
 if not save_data.has("band") or not save_data["band"] is Dictionary:
  save_data["band"] = {"name":"The Feedback","members":[]}
 var extra: Dictionary = save_data["career_extra"]
 for key in ["songs","fans","gear","buzz","press","demos"]:
  if not extra.has(key):
   extra[key] = 0
 for key in ["opportunities_seen","opportunities_resolved","action_counters"]:
  if not extra.has(key):
   extra[key] = {}
 for key in ["owned_equipment","gig_history"]:
  if not extra.has(key):
   extra[key] = []

func _save() -> void:
 if save_data.is_empty():
  return
 save_data["current_event"] = "aftershow"
 save_data["pending_next"] = ""
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  push_error("Cannot save career")
  return
 file.store_string(JSON.stringify(save_data,"\t"))
 file.close()

func _extra() -> Dictionary:
 return save_data.get("career_extra",{})

func _num(key: String) -> int:
 if _extra().has(key):
  return int(_extra().get(key,0))
 return int(save_data.get(key,0))

func _label(parent: Node, value: String, size: int = 17, colour: Color = UI.WHITE) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",colour)
 parent.add_child(label)
 return label

func _card(title: String, description: String = "") -> VBoxContainer:
 return Components.section(content,title,description)

func _action(parent: Node, name: String, callback: Callable, primary: bool = false) -> void:
 var button := UI.button(name,primary)
 parent.add_child(button)
 button.pressed.connect(callback)

func _progress(parent: Node, name: String, value: int, maximum: int = 100) -> void:
 var row := HBoxContainer.new()
 parent.add_child(row)
 var label := _label(row,name + "  %d" % value,13,UI.MUTED)
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var bar := ProgressBar.new()
 bar.custom_minimum_size = Vector2(105,20)
 bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 UI.progress(bar)
 bar.max_value = maxi(1,maximum)
 bar.value = clampi(value,0,int(bar.max_value))
 bar.show_percentage = false
 row.add_child(bar)

func _render() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var background := ColorRect.new()
 background.color = UI.BG
 add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroll := ScrollContainer.new()
 add_child(scroll)
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.offset_bottom = -CareerLayout.content_inset(get_viewport_rect().size.x)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 var margin := MarginContainer.new()
 margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 margin.add_theme_constant_override("margin_left",12)
 margin.add_theme_constant_override("margin_right",12)
 margin.add_theme_constant_override("margin_top",12)
 margin.add_theme_constant_override("margin_bottom",24)
 scroll.add_child(margin)
 content = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",10)
 margin.add_child(content)
 _header()
 _hero()
 if not message.is_empty():
  _card("LATEST ACTIVITY",message)
 match tab:
  "HOME": _home()
  "GIGS": _gigs()
  "GEAR": _gear()
  "BAND": _band()
  "ACTIONS": _actions()
  "SCENE": _scene()
 var menu := UI.button("SAVE & MAIN MENU")
 menu.custom_minimum_size.y = 48
 content.add_child(menu)
 menu.pressed.connect(_menu)
 _bottom_nav()
 content.modulate.a = 0.0
 var appear := create_tween()
 appear.tween_property(content,"modulate:a",1.0,0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _header() -> void:
 var palette: Dictionary = save_data.get("band",{}).get("palette",{})
 var colour := Color(str(palette.get("primary","#F0B44D")))
 _label(content,"LIVIN' THE DREAM   /   BRITISH GRASSROOTS",12,colour)
 var row := HBoxContainer.new()
 content.add_child(row)
 var band_data: Dictionary = save_data.get("band",{})
 var title := _label(row,str(band_data.get("name","Unknown Band")),25)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.size_flags_stretch_ratio = 1
 title.autowrap_mode = TextServer.AUTOWRAP_OFF
 title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 var day_panel := PanelContainer.new()
 day_panel.custom_minimum_size = Vector2(92,48)
 day_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
 day_panel.add_theme_stylebox_override("panel",UI.style(UI.ALT,12))
 row.add_child(day_panel)
 var day := _label(day_panel,"DAY %d" % _num("tour_day"),15,UI.AMBER)
 day.autowrap_mode = TextServer.AUTOWRAP_OFF
 day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 day.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 day.clip_text = true
 var stats := HBoxContainer.new()
 stats.add_theme_constant_override("separation",5)
 content.add_child(stats)
 for entry in ["CASH £%d" % _num("cash"),"FANS %d" % _num("fans"),"REP %d" % _num("reputation")]:
  var panel := PanelContainer.new()
  panel.add_theme_stylebox_override("panel",UI.style(UI.ALT,10))
  panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  stats.add_child(panel)
  _label(panel,entry,14,UI.WHITE)

func _hero() -> void:
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",UI.flat(UI.ALT,12))
 content.add_child(panel)
 var frame := VBoxContainer.new()
 frame.add_theme_constant_override("separation",0)
 frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_child(frame)
 var path := "res://Art/Backgrounds/%s.webp" % tab.to_lower()
 if not ResourceLoader.exists(path):
  path = "res://%s.webp" % tab.to_lower()
 var picture := TextureRect.new()
 picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 picture.custom_minimum_size.y = 270
 picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
 if ResourceLoader.exists(path):
  picture.texture = load(path)
 else:
  var fallback: String = str(ART.get(tab,""))
  if ResourceLoader.exists(fallback):
   picture.texture = load(fallback)
 frame.add_child(picture)
 var headline := {
  "HOME":"YOUR BAND. YOUR FUTURE.",
  "GIGS":"THE BRITISH LIVE CIRCUIT",
  "GEAR":"SECOND-HAND MUSIC SHOP",
  "BAND":"THE PEOPLE BEHIND THE MUSIC",
  "ACTIONS":"ANOTHER DAY ON THE ROAD",
  "SCENE":"MAKE SOME NOISE"
 }
 var caption := PanelContainer.new()
 caption.add_theme_stylebox_override("panel",UI.style(Color("#141C27"),0))
 frame.add_child(caption)
 var text_stack := VBoxContainer.new()
 text_stack.add_theme_constant_override("separation",3)
 caption.add_child(text_stack)
 _label(text_stack,"THE BAND'S STORY  /  "+tab,11,UI.AMBER)
 _label(text_stack,str(headline.get(tab,tab)),20,UI.WHITE)


func _home() -> void:
 var destinations := _card("YOUR WORLD","Pick a place. Everything starts somewhere.")
 var places := GridContainer.new()
 places.columns = 2
 places.add_theme_constant_override("h_separation",10)
 places.add_theme_constant_override("v_separation",10)
 destinations.add_child(places)
 for spot in [
  {"name":"THE STUDIO","tab":"ACTIONS","caption":"Jam · Rehearse · Hang out","art":"actions"},
  {"name":"THE VENUES","tab":"GIGS","caption":"Book · Prepare · Perform","art":"gigs"},
  {"name":"THE BAND","tab":"BAND","caption":"People · Chemistry · Stories","art":"band"},
  {"name":"THE SCENE","tab":"SCENE","caption":"Promoters · Press · Scrapbook","art":"scene"},
  {"name":"THE GEAR SHOP","tab":"GEAR","caption":"Buy · Upgrade · Repair","art":"gear"}
 ]:
  var data: Dictionary = spot
  var tile := Button.new()
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tile.custom_minimum_size.y = 206
  tile.add_theme_stylebox_override("normal",UI.style(UI.ALT,14))
  tile.add_theme_stylebox_override("hover",UI.style(UI.ALT.lightened(0.12),14))
  tile.add_theme_stylebox_override("pressed",UI.style(UI.PANEL,14))
  places.add_child(tile)
  var tile_content := VBoxContainer.new()
  tile_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
  tile_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  tile_content.add_theme_constant_override("separation",6)
  tile.add_child(tile_content)
  var art := TextureRect.new()
  art.custom_minimum_size.y = 100
  art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  art.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var art_path := "res://Art/uk_%s_banner.svg" % str(data["art"])
  if ResourceLoader.exists(art_path):
   art.texture = load(art_path)
  tile_content.add_child(art)
  var heading := _label(tile_content,str(data["name"]),14,UI.WHITE)
  heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var tagline := _label(tile_content,str(data["caption"]),11,UI.MUTED)
  tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var target: String = str(data["tab"])
  tile.pressed.connect(func() -> void: _switch(target))
 var guidance: Dictionary = Director.next_move(_state())
 var focus := _card("YOUR NEXT MOVE  /  "+str(guidance.get("title","")),str(guidance.get("detail","")))
 var destination := str(guidance.get("tab","ACTIONS"))
 _action(focus,str(guidance.get("action","CONTINUE"))+"  ›",func() -> void: _switch(destination),true)
 var upcoming: Dictionary = Calendar.pending(_state())
 if not upcoming.is_empty():
  var remaining := int(upcoming.get("day",1)) - _num("tour_day")
  var plan := _card("GIG NIGHT  /  DAY %d" % int(upcoming.get("day",1)),str(upcoming.get("venue","Venue"))+"  ·  "+str(upcoming.get("city","HOME")))
  if remaining > 0:
   _label(plan,"%d DAYS TO PREPARE YOUR SET" % remaining,16,UI.AMBER)
   _action(plan,"PREPARE THE BAND",func() -> void: _switch("ACTIONS"),true)
  elif remaining == 0:
   _label(plan,"TONIGHT: THE BAND IS EXPECTED ON STAGE",16,UI.AMBER)
   _action(plan,"GO TO TONIGHT'S GIG",func() -> void: _switch("GIGS"),true)
  else:
   _label(plan,"OVERDUE BOOKING — RESOLVE THIS GIG",15,UI.AMBER)
   _action(plan,"OPEN GIG CALENDAR",func() -> void: _switch("GIGS"),true)
 var chapter: Dictionary = Chapters.progress(_state())
 var chapter_box := _card("YOUR NEXT CHAPTER  /  "+str(chapter.get("title","")) ,str(chapter.get("description","")))
 if not bool(chapter.get("done",false)):
  for objective in chapter.get("requirements",[]):
   Components.objective(chapter_box,objective)
  var claim := UI.button("CLAIM CHAPTER REWARD  ·  £%d" % int(chapter.get("reward_cash",0)),true)
  claim.disabled = not bool(chapter.get("ready",false))
  claim.custom_minimum_size.y = 52
  chapter_box.add_child(claim)
  var chapter_id := str(chapter.get("id",""))
  claim.pressed.connect(func() -> void: _finish(Chapters.claim(_state(),chapter_id)))
 var fans := _num("fans")
 var rep := _num("reputation")
 var missing: Dictionary = {}
 for venue in Gigs.VENUES:
  if fans < int(venue["min_fans"]) or rep < int(venue["min_rep"]):
   missing = venue
   break
 if not missing.is_empty():
  var body := _card("NEXT: " + str(missing["city"]),
   "Unlock %s: %d more fans, %d more reputation." % [str(missing["venue"]),maxi(0,int(missing["min_fans"])-fans),maxi(0,int(missing["min_rep"])-rep)])
  _action(body,"BOOK A HOMETOWN GIG",func() -> void: _switch("GIGS"),true)
 else:
  _card("REGIONAL CIRCUIT UNLOCKED","All current UK venues are available.")
 _opportunities()
 var songs: Array = _extra().get("song_catalogue",[])
 if not songs.is_empty():
  var songbook := _card("ORIGINAL SONGS","Your band is building its first setlist.")
  for i in range(songs.size()-1,maxi(-1,songs.size()-4),-1):
   var tune: Dictionary = songs[i]
   _label(songbook,str(tune.get("title","UNTITLED"))+"  /  QUALITY %d" % int(tune.get("quality",0)),14,UI.WHITE)
  _label(songbook,"%d TOTAL ORIGINALS" % _num("songs"),12,UI.AMBER)
 var memories := Story.latest(_state(),3)
 if not memories.is_empty():
  var journal := _card("THE STORY SO FAR","A living scrapbook of gigs, friendships and turning points.")
  for moment in memories:
   if moment is Dictionary:
    var clipping: Dictionary = Presentation.clipping(moment)
    _label(journal,str(clipping["rubric"])+"  /  DAY %d" % int(clipping["day"]),11,UI.AMBER)
    Components.story(journal,moment)
  _action(journal,"OPEN FULL SCRAPBOOK",func() -> void: _switch("SCENE"))
 var pulse := _card("BAND PULSE","Your next show depends on preparation and morale.")
 for key in ["readiness","morale","van_health"]:
  _progress(pulse,key.to_upper().replace("_"," "),_num(key))
 var quick := _card("NEXT MOVES","Choose how to spend the day.")
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",6)
 quick.add_child(row)
 var book := UI.button("GIGS",true)
 var write := UI.button("WRITE")
 var practise := UI.button("PRACTISE")
 for action in [book,write,practise]:
  action.custom_minimum_size.y = 58
  action.add_theme_font_size_override("font_size",13)
  row.add_child(action)
 book.pressed.connect(func() -> void: _switch("GIGS"))
 write.pressed.connect(func() -> void: _switch("ACTIONS"))
 practise.pressed.connect(func() -> void: _switch("ACTIONS"))

func _gigs() -> void:
 var booked: Dictionary = Calendar.pending(_state())
 if not booked.is_empty():
  var due := int(booked.get("day",1)) - _num("tour_day")
  var calendar_box := _card("NEXT SHOW  /  DAY %d" % int(booked.get("day",1)),str(booked.get("venue","Venue"))+"  ·  "+str(booked.get("city","HOME")))
  if due > 0:
   _label(calendar_box,"%d DAYS LEFT TO PREPARE  /  REHEARSE, WRITE OR PROMOTE" % due,14,UI.AMBER)
  elif due == 0:
   var scene: Dictionary = GigNight.stage(_state())
   _label(calendar_box,str(scene.get("title","SHOW NIGHT")),22,UI.AMBER)
   _label(calendar_box,str(scene.get("detail","")),15,UI.WHITE)
   var chapter_art := TextureRect.new()
   chapter_art.custom_minimum_size.y = 170
   chapter_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   chapter_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
   chapter_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
   var art_path := "res://Art/uk_gigs_banner.svg"
   if str(scene.get("phase","")) == "soundcheck":
    art_path = "res://Art/uk_band_banner.svg"
   if ResourceLoader.exists(art_path):
    chapter_art.texture = load(art_path)
   calendar_box.add_child(chapter_art)
   var progress := HBoxContainer.new()
   calendar_box.add_child(progress)
   for label in ["01 ARRIVE","02 SOUNDCHECK","03 STAGE"]:
    var chip := _label(progress,label,11,UI.MUTED)
    chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   if str(scene.get("phase","")) == "soundcheck":
    _label(calendar_box,"YOUR LIVE SET  /  CHOOSE AN APPROACH",13,UI.AMBER)
    for approach_key in ["tight","wild","crowd"]:
     var approach: String = str(approach_key)
     var rule: Dictionary = Gigs.APPROACHES[approach]
     var chosen := str(booked.get("approach","tight")) == approach
     var button := UI.button(("✓  " if chosen else "")+str(rule["label"]),chosen)
     button.custom_minimum_size.y = 54
     calendar_box.add_child(button)
     button.pressed.connect(func() -> void: _change_gig_strategy(approach))
   if bool(scene.get("can_play",false)):
    _label(calendar_box,"SET APPROACH  /  "+str(booked.get("approach","tight")).to_upper(),13,UI.MUTED)
    _action(calendar_box,"TAKE THE STAGE",func() -> void: _perform_gig(),true)
   else:
    _action(calendar_box,"CONTINUE THE NIGHT  ›",func() -> void: _advance_gig_night(),true)
  else:
   _label(calendar_box,"THIS BOOKING IS OVERDUE.",14,UI.AMBER)
  _action(calendar_box,"CANCEL BOOKING  ·  UP TO £15",func() -> void: _finish(Calendar.cancel(_state())))
 else:
  _card("BOOK AHEAD","Shows are booked three days in advance. Use those days to prepare, but don't miss the date.")
 var summary := _card("BOOK A BRITISH GIG","Every show builds your story. Choose the stage, then the approach.")
 _progress(summary,"VAN",_num("van_health"))
 var roster: Array = save_data.get("band",{}).get("members",[])
 var available_count := 0
 var has_drummer := false
 for member in roster:
  if member is Dictionary and str(member.get("life_status","active")) == "active":
   available_count += 1
   if str(member.get("role","")).to_lower().contains("drum"):
    has_drummer = true
 var line_up_ready := available_count >= 2 and has_drummer
 if not line_up_ready:
  var warning := _card("LINE-UP INCOMPLETE","You need two available musicians and a drummer. Audition a replacement or hire a session drummer.")
  _action(warning,"GO TO AUDITIONS",func() -> void: _switch("BAND"),true)
  if available_count >= 1 and _num("cash") >= 25:
   _label(warning,"SESSION DRUMMER: £25 PER SHOW. PERFORMANCE QUALITY -8.",13,UI.MUTED)

 for venue in Gigs.VENUES:
  var key: String = str(venue["id"])
  var needed_fans := maxi(0,int(venue["min_fans"]) - _num("fans"))
  var needed_rep := maxi(0,int(venue["min_rep"]) - _num("reputation"))
  if needed_fans > 0 or needed_rep > 0:
   var locked := _card(str(venue["venue"])+"  /  "+str(venue["city"]),"LOCKED  ·  Need %d fans and %d reputation" % [needed_fans,needed_rep])
   _label(locked,"Build your following with local gigs and promotion.",13,UI.MUTED)
   continue
  var box := _card(str(venue["venue"])+"  /  "+str(venue["city"]),"POTENTIAL FEE £%d  ·  TRAVEL £%d  ·  %d DAYS AWAY" % [int(venue["fee"]),int(venue["travel"]),int(venue["days"])])
  _label(box,"MEET THE PROMOTER  /  NEGOTIATE THE DEAL",13,UI.AMBER)
  _label(box,"The band will choose its live approach at soundcheck.",12,UI.MUTED)
  for offer_id in ["standard","guarantee","guestlist"]:
   var proposal: String = offer_id
   var terms: Dictionary = Promoter.OFFERS[proposal]
   var choice := UI.button(str(terms["label"])+"  ›")
   choice.custom_minimum_size.y = 54
   choice.disabled = not booked.is_empty() or not line_up_ready
   box.add_child(choice)
   _label(box,str(terms["description"]),12,UI.MUTED)
   choice.pressed.connect(func() -> void: _finish(Promoter.book(_state(),key,proposal)))
  if not line_up_ready and available_count >= 1 and booked.is_empty():
   var session := UI.button("BOOK WITH SESSION DRUMMER · £25",true)
   session.disabled = _num("cash") < 25 or (key != "local" and _num("cash") < 25 + int(venue["travel"]))
   box.add_child(session)
   session.pressed.connect(func() -> void: _finish(Promoter.book(_state(),key,"standard",true)))
 var repairs := _card("KEEP THE VAN MOVING","£45 restores 30 van condition. Hometown gigs are still available when cash is low.")
 _action(repairs,"REPAIR VAN — £45",_repair)

func _gear() -> void:
 var owned: Array = _extra().get("owned_equipment",[])
 var heading := _card("THE MUSIC SHOP","A real backline, built one second-hand find at a time.")
 _progress(heading,"READINESS",_num("readiness"))
 _label(heading,"OWNED  %d ITEMS" % owned.size(),14,UI.AMBER)
 _label(heading,"CASH AVAILABLE £%d" % _num("cash"),13,UI.MUTED)
 for item in Gear.ITEMS:
  var key: String = str(item["id"])
  var box := _card(str(item["name"]),str(item["description"]))
  var category := _label(box,str(item["type"]).to_upper()+"   /   +%d READINESS" % int(item["readiness"]),13,UI.AMBER)
  category.autowrap_mode = TextServer.AUTOWRAP_OFF
  _label(box,"%s  /  +%d READINESS  /  £%d" % [str(item["type"]),int(item["readiness"]),int(item["price"])],14,UI.MUTED)
  if owned.has(key):
   _label(box,"✓  IN YOUR INVENTORY",15,UI.AMBER)
  else:
   var buy := UI.button("BUY  ·  £%d" % int(item["price"]),true)
   buy.custom_minimum_size.y = 52
   buy.disabled = _num("cash") < int(item["price"])
   box.add_child(buy)
   buy.pressed.connect(func() -> void: _buy(key))

func _band() -> void:
 _band_situations()
 _life_situations()
 var band_data: Dictionary = save_data.get("band",{})
 var members: Array = band_data.get("members",[])
 var pulse: Dictionary = BandPulse.overview(members)
 var chemistry := _card("THE BAND RIGHT NOW",str(pulse["mood"])+"  /  "+str(pulse["active"])+" ACTIVE MUSICIANS")
 _progress(chemistry,"GROUP MORALE",int(pulse["morale"]))
 _progress(chemistry,"GROUP LOYALTY",int(pulse["loyalty"]))
 if int(pulse["exhausted"]) > 0:
  _label(chemistry,"%d BANDMATE(S) NEED REST BEFORE THE NEXT SHOW" % int(pulse["exhausted"]),13,UI.AMBER)

 var pairs: Array = Chemistry.connections(members,_state().get("relationships",{}))
 var relationships_card := _card("BETWEEN THE BANDMATES",Chemistry.summary(pairs))
 for pair in pairs:
  var bond := VBoxContainer.new()
  bond.add_theme_constant_override("separation",4)
  relationships_card.add_child(bond)
  _label(bond,str(pair["first"])+"  +  "+str(pair["second"])+"   /   "+str(pair["label"]),13,UI.WHITE)
  _progress(bond,"CONNECTION",int(pair["score"]))
 if pairs.is_empty():
  _label(relationships_card,"Chemistry grows through rehearsals, conversations and time together.",12,UI.MUTED)

 if members.is_empty():
  _card("THE BAND NEEDS MUSICIANS","Start rebuilding the line-up.")
 var conversation: Dictionary = _extra().get("last_band_conversation",{})
 if not conversation.is_empty():
  var dialogue := _card("BACKSTAGE  /  "+str(conversation.get("speaker","Musician")).to_upper(),"A moment with one of your bandmates.")
  var quote_frame := PanelContainer.new()
  quote_frame.add_theme_stylebox_override("panel",UI.style(UI.ALT,12))
  dialogue.add_child(quote_frame)
  var scene := HBoxContainer.new()
  scene.add_theme_constant_override("separation",12)
  quote_frame.add_child(scene)
  var speaker_name := str(conversation.get("speaker","Musician"))
  var speaker_index := -1
  for candidate_index in range(members.size()):
   if members[candidate_index] is Dictionary and str(members[candidate_index].get("name","")) == speaker_name:
    speaker_index = candidate_index
    break
  if speaker_index >= 0:
   var speaker_data: Dictionary = members[speaker_index]
   var speaker_portrait := Portrait.new()
   speaker_portrait.custom_minimum_size = Vector2(92,122)
   speaker_portrait.set_character(str(speaker_data.get("candidate_id",speaker_data.get("id",speaker_index))),speaker_name)
   scene.add_child(speaker_portrait)
  var quote_stack := VBoxContainer.new()
  quote_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  quote_stack.add_theme_constant_override("separation",8)
  scene.add_child(quote_stack)
  _label(quote_stack,speaker_name.to_upper()+"  /  BACKSTAGE",12,UI.AMBER)
  _label(quote_stack,"\""+str(conversation.get("text",""))+"\"",18,UI.WHITE)
  var engine := "LOCAL AI" if str(conversation.get("source","offline")) == "local" else "OFFLINE CHARACTER DIALOGUE"
  _label(quote_stack,engine+"   /   DAY %d" % int(conversation.get("day",_num("tour_day"))),11,UI.MUTED)
  var close_dialogue := UI.button("CLOSE CONVERSATION")
  close_dialogue.custom_minimum_size.y = 46
  dialogue.add_child(close_dialogue)
  close_dialogue.pressed.connect(func() -> void:
   _extra().erase("last_band_conversation")
   _save()
   _render()
  )
 var alumni: Array = _extra().get("former_members",[])
 if not alumni.is_empty():
  var alumni_box := _card("FORMER MEMBERS","The people who helped shape the band.")
  for person in alumni:
   if person is Dictionary:
    _label(alumni_box,str(person.get("name","Musician"))+"  /  "+str(person.get("role",""))+"  ·  "+str(person.get("reason","Left the band")),13,UI.MUTED)
 for i in range(members.size()):
  if not members[i] is Dictionary:
   continue
  var member: Dictionary = members[i]
  var index := i
  var status := str(member.get("life_status","active"))
  var box := _card("ON THE ROAD" if status == "active" else "CURRENTLY UNAVAILABLE","")
  var identity := HBoxContainer.new()
  identity.add_theme_constant_override("separation",14)
  box.add_child(identity)
  var portrait := Portrait.new()
  portrait.custom_minimum_size = Vector2(88,108)
  portrait.set_character(str(member.get("candidate_id",member.get("id",i))),str(member.get("name","Musician")))
  identity.add_child(portrait)
  var name_stack := VBoxContainer.new()
  name_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  identity.add_child(name_stack)
  _label(name_stack,str(member.get("name","Musician")).to_upper(),24,UI.WHITE)
  _label(name_stack,str(member.get("role","")).to_upper(),13,UI.AMBER)
  _label(name_stack,str(member.get("trait","")),13,UI.MUTED)
  _label(name_stack,BandPulse.member_note(member),12,UI.AMBER)
  if str(member.get("life_status","active")) != "active":
   _label(name_stack,str(member.get("life_status","")).to_upper()+" UNTIL DAY %d" % int(member.get("available_day",0)),12,UI.AMBER)
  var rule := ColorRect.new()
  rule.color = Color("#344153")
  rule.custom_minimum_size.y = 1
  box.add_child(rule)
  var scores := GridContainer.new()
  scores.columns = 2
  scores.add_theme_constant_override("h_separation",16)
  scores.add_theme_constant_override("v_separation",12)
  box.add_child(scores)
  for key in ["skill","morale","loyalty","fatigue"]:
   var metric := VBoxContainer.new()
   scores.add_child(metric)
   _label(metric,key.to_upper()+"  %d" % int(member.get(key,50)),12,UI.MUTED)
   var meter := ProgressBar.new()
   meter.custom_minimum_size = Vector2(130,10)
   meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   UI.progress(meter)
   meter.value = clampi(int(member.get(key,50)),0,100)
   metric.add_child(meter)
  var controls := HBoxContainer.new()
  controls.add_theme_constant_override("separation",6)
  box.add_child(controls)
  var talk := UI.button("TALK",true)
  var coach := UI.button("COACH £10")
  var rest := UI.button("REST")
  for control in [talk,coach,rest]:
   control.custom_minimum_size.y = 52
   control.add_theme_font_size_override("font_size",13)
   controls.add_child(control)
  coach.disabled = _num("cash") < 10
  var listen := UI.button("LISTEN")
  listen.custom_minimum_size.y = 50
  box.add_child(listen)
  listen.pressed.connect(func() -> void: _listen(index))
  talk.pressed.connect(func() -> void: _member(index,"chat"))
  coach.pressed.connect(func() -> void: _member(index,"coach"))
  rest.pressed.connect(func() -> void: _member(index,"break"))

 if members.size() < 6:
  var recruitment := _card("AUDITIONS","Three local musicians are available. Weigh talent against loyalty and signing fees.")
  var shortlist := Life.candidates(_state())
  for i in range(shortlist.size()):
   var candidate: Dictionary = shortlist[i]
   var index := i
   _label(recruitment,"%s  ·  %s  ·  %s" % [str(candidate["name"]),str(candidate["role"]),str(candidate["trait"])],15,UI.WHITE)
   _label(recruitment,"SKILL %d  /  LOYALTY %d" % [int(candidate["skill"]),int(candidate["loyalty"])],12,UI.MUTED)
   var sign := UI.button("SIGN  ·  £%d" % int(candidate["cost"]),i == 0)
   sign.custom_minimum_size.y = 48
   sign.disabled = _num("cash") < int(candidate["cost"])
   recruitment.add_child(sign)
   sign.pressed.connect(func() -> void: _recruit(index))
 var settings := _card("DIALOGUE ENGINE","Offline dialogue always works. Optional local AI requires an Ollama server on this device.")
 var cfg: Dictionary = _extra().get("local_dialogue",{})
 var enabled := bool(cfg.get("enabled",false))
 var switcher := UI.button("LOCAL AI: ON" if enabled else "LOCAL AI: OFF")
 switcher.disabled = OS.has_feature("mobile")
 if OS.has_feature("mobile"):
  _label(settings,"PC-local preview only. Mobile uses offline dialogue.",13,UI.MUTED)
 settings.add_child(switcher)
 switcher.pressed.connect(func() -> void:
  var config_store: Dictionary = _extra()
  var updated: Dictionary = config_store.get("local_dialogue",{}).duplicate(true)
  updated["enabled"] = not bool(updated.get("enabled",false))
  if not bool(updated["enabled"]):
   dialogue_serial += 1
   _cancel_dialogue_request()
  config_store["local_dialogue"] = updated
  _save()
  _render()
 )

func _listen(index: int) -> void:
 # Every listen replaces the previous request. A late completion cannot rewrite
 # another musician's dialogue or a more recent player decision.
 dialogue_serial += 1
 _cancel_dialogue_request()
 var snapshot: Dictionary = _state()
 var fallback: Dictionary = Presentation.dialogue_for(snapshot,index)
 if not bool(fallback.get("ok",false)):
  message = str(fallback.get("message","No conversation available."))
  _render()
  return
 fallback["source"] = "offline"
 _display_conversation(fallback)
 var cfg: Dictionary = _extra().get("local_dialogue",{})
 if not LocalDialogue.allowed(cfg,OS.has_feature("mobile")):
  return
 var payload: Dictionary = LocalDialogue.request_payload(snapshot,index)
 if payload.is_empty():
  return
 payload["model"] = str(cfg.get("model","llama3.2:3b"))
 var request_id := dialogue_serial
 var day := int(snapshot.get("tour_day",1))
 var speaker := str(fallback.get("speaker",""))
 dialogue_busy = true
 var request_node := HTTPRequest.new()
 dialogue_request = request_node
 request_node.timeout = 8.0
 add_child(request_node)
 request_node.request_completed.connect(func(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
  if dialogue_request == request_node:
   dialogue_request = null
   dialogue_busy = false
  request_node.queue_free()
  if not LocalDialogue.is_current(request_id,dialogue_serial,day,_num("tour_day"),speaker,str(_extra().get("last_band_conversation",{}).get("speaker",""))):
   return
  if not LocalDialogue.allowed(_extra().get("local_dialogue",{}),OS.has_feature("mobile")):
   return
  if result != HTTPRequest.RESULT_SUCCESS or status != 200:
   return
  var candidate := LocalDialogue.validated_text(body.get_string_from_utf8())
  if candidate.is_empty():
   return
  var ai_reply := fallback.duplicate(true)
  ai_reply["text"] = candidate
  ai_reply["source"] = "local"
  _display_conversation(ai_reply)
 )
 var error := request_node.request("http://127.0.0.1:11434/api/chat",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(payload))
 if error != OK:
  _cancel_dialogue_request()

func _cancel_dialogue_request() -> void:
 dialogue_busy = false
 if is_instance_valid(dialogue_request):
  dialogue_request.cancel_request()
  dialogue_request.queue_free()
 dialogue_request = null

func _display_conversation(response: Dictionary) -> void:
 var extra: Dictionary = _extra()
 extra["last_band_conversation"] = response
 message = str(response.get("speaker","Musician"))+": "+str(response.get("text",""))
 _save()
 _render()

func _life_situations() -> void:
 for situation in Life.pending(_state()):
  var member_index := int(situation["index"])
  var event_id := str(situation["id"])
  var definition: Dictionary = Life.EVENTS[event_id]
  var box := _card(str(definition["title"])+"  /  "+str(situation["name"]),str(definition["intro"]))
  for choice in definition["choices"]:
   var chosen := str(choice["id"])
   _action(box,str(choice["label"]),func() -> void: _finish(Life.resolve(_state(),member_index,event_id,chosen)),chosen == str(definition["choices"][0]["id"]))

func _recruit(index: int = 0) -> void:
 _finish(Life.recruit(_state(),index))

func _band_situations() -> void:
 for event_id in Drama.pending(_state()):
  var id: String = str(event_id)
  var definition: Dictionary = Drama.EVENTS[id]
  var box := _card(str(definition["title"]),str(definition["intro"]))
  for option in definition["choices"]:
   var choice: String = str(option["id"])
   _action(box,str(option["label"]),func() -> void: _finish(Drama.resolve(_state(),id,choice)),choice == str(definition["choices"][0]["id"]))

func _actions() -> void:
 var heading := _card("THE REHEARSAL ROOM","Every session shapes your songs, friendships, morale and live performance.")
 _progress(heading,"READINESS",_num("readiness"))
 _progress(heading,"MORALE",_num("morale"))
 _progress(heading,"TENSION",_num("tension"))
 var upcoming: Dictionary = Calendar.pending(_state())
 if not upcoming.is_empty():
  var countdown := int(upcoming.get("day",1)) - _num("tour_day")
  if countdown > 0:
   _label(heading,"NEXT SHOW IN %d DAYS — %s" % [countdown,str(upcoming.get("venue",""))],15,UI.AMBER)
  elif countdown == 0:
   _label(heading,"SHOW DAY — PREPARATION TIME HAS RUN OUT",15,UI.AMBER)
   _action(heading,"GO TO YOUR BOOKED GIG",func() -> void: _switch("GIGS"),true)
 _label(heading,"ORIGINAL SONGS: %d" % _num("songs"),14,UI.WHITE)
 _label(heading,"SONGWRITING  /  THREE SESSIONS PER ORIGINAL",13,UI.AMBER)
 var mode_titles := {"JAM":"THE WRITING ROOM","HANG OUT":"AFTER HOURS","PROMOTE":"MAKE SOME NOISE"}
 var mode_descriptions := {"JAM":"Build a song from someone's idea.","HANG OUT":"Be people together, not just bandmates.","PROMOTE":"Get your name around town."}
 var scene_card := _card(str(mode_titles.get(action_view,"THE STUDIO")),str(mode_descriptions.get(action_view,"")))
 var scene_art := TextureRect.new()
 scene_art.custom_minimum_size.y = 184
 scene_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 scene_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 scene_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var image_path := "res://Art/uk_actions_banner.svg"
 if action_view == "HANG OUT":
  image_path = "res://Art/uk_band_banner.svg"
 elif action_view == "PROMOTE":
  image_path = "res://Art/uk_scene_banner.svg"
 if ResourceLoader.exists(image_path):
  scene_art.texture = load(image_path)
 scene_card.add_child(scene_art)
 var switches := _card("CHOOSE YOUR DAY","Select an activity. Each commitment moves the band's story forward.")
 var navigation := HBoxContainer.new()
 navigation.add_theme_constant_override("separation",8)
 switches.add_child(navigation)
 for mode in ["JAM","HANG OUT","PROMOTE"]:
  var destination := str(mode)
  var selected := action_view == destination
  var button := UI.button(destination,selected)
  button.custom_minimum_size.y = 54
  button.add_theme_font_size_override("font_size",12)
  navigation.add_child(button)
  button.pressed.connect(func() -> void:
   action_view = destination
   _render()
  )
 if action_view == "JAM":
  var draft: Dictionary = _extra().get("current_song_draft",{})
  var workshop := _card("JAM & WRITE  /  "+("NEW IDEA" if draft.is_empty() else "WORK IN PROGRESS"),"Try different riffs, words and arrangements. Let a bandmate lead the session.")
  var studio: Dictionary = SongStudio.view(_state())
  var studio_title := _label(workshop,str(studio["headline"]),22,UI.WHITE)
  studio_title.add_theme_font_size_override("font_size",22)
  _label(workshop,str(studio["detail"]),14,UI.MUTED)
  var stages := HBoxContainer.new()
  stages.add_theme_constant_override("separation",6)
  workshop.add_child(stages)
  for step in range(3):
   var step_panel := PanelContainer.new()
   step_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   step_panel.add_theme_stylebox_override("panel",UI.style(UI.ALT if step <= int(studio["completed"]) else UI.PANEL,8))
   stages.add_child(step_panel)
   var marker := _label(step_panel,("%02d" % (step+1)) + ("  ✓" if step < int(studio["completed"]) else ""),13,UI.AMBER if step <= int(studio["completed"]) else UI.MUTED)
   marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _label(workshop,"%d / 3 SESSIONS  •  %s" % [int(studio["completed"]),str(studio["stage"])],13,UI.AMBER)
  var separator := HSeparator.new()
  workshop.add_child(separator)
  _label(workshop,"BUILD THE SONG",15,UI.WHITE)
  var ideas := OptionButton.new()
  var forms := OptionButton.new()
  var titles := OptionButton.new()
  var leads := OptionButton.new()
  var catalogue: Dictionary = Workshop.options(_state())
  for value in catalogue["ideas"]:
   ideas.add_item(str(value))
  for value in catalogue["forms"]:
   forms.add_item(str(value))
  for value in catalogue["titles"]:
   titles.add_item(str(value))
  var indices: Array = []
  for person in catalogue["leads"]:
   leads.add_item(str(person["name"])+"  /  "+str(person["trait"]))
   indices.append(int(person["index"]))
  var selectors := [
   {"label":"01  STARTING POINT","control":ideas},
   {"label":"02  ARRANGEMENT","control":forms},
   {"label":"03  WORKING TITLE","control":titles},
   {"label":"04  SESSION LEADER","control":leads}
  ]
  for selector in selectors:
   _label(workshop,str(selector["label"]),12,UI.MUTED)
   var control: OptionButton = selector["control"]
   control.custom_minimum_size.y = 56
   control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   workshop.add_child(control)
  if not draft.is_empty():
   var idea_index := Workshop.IDEAS.find(str(draft.get("idea","")))
   var form_index := Workshop.FORMS.find(str(draft.get("form","")))
   var title_index := Workshop.TITLES.find(str(draft.get("title","")))
   if idea_index >= 0:
    ideas.select(idea_index)
   if form_index >= 0:
    forms.select(form_index)
   if title_index >= 0:
    titles.select(title_index)
  var jam := UI.button("JAM ON THIS SONG  ·  1 DAY",true)
  jam.custom_minimum_size.y = 54
  jam.disabled = indices.is_empty()
  workshop.add_child(jam)
  jam.pressed.connect(func() -> void:
   _finish(Practice.compose(_state(),ideas.get_item_text(ideas.selected),forms.get_item_text(forms.selected),titles.get_item_text(titles.selected),indices[leads.selected]))
  )
  for focus in Practice.FOCUSES:
   var id := str(focus)
   var rule: Dictionary = Practice.FOCUSES[id]
   var base: Dictionary = Actions.ACTIONS[str(rule["action"])]
   var cost := int(base.get("cost",0))
   if id == "create":
    continue
   var session := _card(str(rule["label"]),str(rule["description"]))
   _label(session,"1 DAY  /  £%d" % cost,13,UI.MUTED)
   var start_button := UI.button("START SESSION" if cost == 0 else "BOOK SESSION · £%d" % cost,id == "tighten")
   start_button.custom_minimum_size.y = 56
   start_button.disabled = _num("cash") < cost
   session.add_child(start_button)
   start_button.pressed.connect(func() -> void: _practice(id))
 if action_view == "HANG OUT":
  var socials := _card("LIFE OUTSIDE THE STUDIO","Bandmates need more than rehearsals. Going out costs money and a day, but builds trust.")
  var available_count := 0
  for person in _state().get("members",[]):
   if person is Dictionary and str(person.get("life_status","active")) == "active":
    available_count += 1
  for activity in Social.ACTIVITIES:
   var outing_id := str(activity)
   var rule: Dictionary = Social.ACTIVITIES[outing_id]
   var cost := int(rule["cost_per_member"])*available_count
   var button := UI.button(str(rule["label"])+"  ·  £%d" % cost)
   button.custom_minimum_size.y = 52
   button.disabled = available_count < 2 or _num("cash") < cost
   socials.add_child(button)
   button.pressed.connect(func() -> void: _finish(Social.attend(_state(),outing_id)))
 if action_view == "PROMOTE":
  var other := _card("THE BUSINESS SIDE","Music alone won't pay for studio time. Your days also need promotion and practical work.")
  for action_id in ["promo","press","buy_gear"]:
   var id := str(action_id)
   var rule: Dictionary = Actions.ACTIONS[id]
   var cost := int(rule.get("cost",0))
   var button := UI.button(str(rule["label"])+" · £%d" % cost)
   button.disabled = _num("cash") < cost
   other.add_child(button)
   button.pressed.connect(func() -> void: _do_action(id))

func _scene() -> void:
 var archive: Array = _extra().get("career_journal",[])
 var scrapbook := _card("THE BAND SCRAPBOOK","Explore the people, gigs and turning points in your band's history.")
 var filters := HBoxContainer.new()
 filters.add_theme_constant_override("separation",5)
 scrapbook.add_child(filters)
 for category in Scrapbook.FILTERS:
  var choice := str(category)
  var btn := UI.button(choice,choice == scrapbook_filter)
  btn.add_theme_font_size_override("font_size",11)
  btn.custom_minimum_size.y = 46
  filters.add_child(btn)
  btn.pressed.connect(func() -> void:
   scrapbook_filter = choice
   _render()
  )
 var selected: Array = Scrapbook.select(archive,scrapbook_filter,20)
 if selected.is_empty():
  _label(scrapbook,"No memories in this category yet. Keep playing to make history.",14,UI.MUTED)
 else:
  for entry in selected:
   var clipping: Dictionary = Presentation.clipping(entry)
   _label(scrapbook,str(clipping["rubric"])+"  ·  DAY %d" % int(clipping["day"]),12,UI.AMBER)
   Components.story(scrapbook,entry)
 var snapshot := _card("YOUR LOCAL PROFILE","Press attention, word of mouth and your growing following.")
 _progress(snapshot,"BUZZ",_num("buzz"))
 _progress(snapshot,"PRESS",_num("press"))
 _label(snapshot,"%d FANS   ·   %d REPUTATION" % [_num("fans"),_num("reputation")],14,UI.AMBER)
 _opportunities()
 var box := _card("GET THE WORD OUT","Posters create fans. Press pitches build attention and coverage.")
 var controls := HBoxContainer.new()
 controls.add_theme_constant_override("separation",6)
 box.add_child(controls)
 var promo := UI.button("POSTERS £25",true)
 var press := UI.button("PRESS £10")
 controls.add_child(promo)
 controls.add_child(press)
 promo.pressed.connect(func() -> void: _do_action("promo"))
 press.pressed.connect(func() -> void: _do_action("press"))

func _opportunities() -> void:
 for event_id in Opportunities.pending(_extra()):
  var id: String = str(event_id)
  var event: Dictionary = Opportunities.get_event(id)
  var box := _card(str(event.get("title","OPPORTUNITY")),str(event.get("intro","")))
  for choice in event.get("choices",[]):
   var choice_id: String = str(choice.get("id",""))
   _action(box,str(choice.get("label","CHOOSE")),func() -> void: _choose(id,choice_id),true)

func _bottom_nav() -> void:
 var panel := PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 panel.offset_top = -CareerLayout.footer_height(get_viewport_rect().size.x)
 panel.add_theme_stylebox_override("panel",UI.style(UI.PANEL,0))
 add_child(panel)
 var bar := GridContainer.new()
 bar.columns = CareerLayout.columns(get_viewport_rect().size.x)
 bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 bar.add_theme_constant_override("h_separation",3)
 panel.add_child(bar)
 for tab_id in TABS:
  var target: String = tab_id
  var selected := target == tab
  var button := Button.new()
  button.custom_minimum_size.y = 72 if CareerLayout.is_compact(get_viewport_rect().size.x) else 76
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.add_theme_stylebox_override("normal",UI.style(UI.AMBER if selected else UI.ALT,10))
  button.add_theme_stylebox_override("hover",UI.style(UI.AMBER.lightened(0.08) if selected else UI.ALT.lightened(0.1),10))
  button.add_theme_stylebox_override("pressed",UI.style(UI.AMBER.darkened(0.12),10))
  var box := VBoxContainer.new()
  box.mouse_filter = Control.MOUSE_FILTER_IGNORE
  box.alignment = BoxContainer.ALIGNMENT_CENTER
  box.add_theme_constant_override("separation",3)
  button.add_child(box)
  box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  var icon_path := "res://Art/Icons/%s.svg" % target.to_lower()
  if ResourceLoader.exists(icon_path):
   var glyph := TextureRect.new()
   glyph.texture = load(icon_path)
   glyph.custom_minimum_size = Vector2(24,26)
   glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   glyph.modulate = UI.BG if selected else UI.WHITE
   glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
   box.add_child(glyph)
  var caption := _label(box,target,11,UI.BG if selected else UI.WHITE)
  caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
  bar.add_child(button)
  button.pressed.connect(func() -> void: _switch(target))


func _switch(next_tab: String) -> void:
 tab = next_tab
 _render()

func _state() -> Dictionary:
 var state: Dictionary = _extra().duplicate(true)
 for key in ["cash","tour_day","morale","reputation","readiness","tension","van_health"]:
  state[key] = _num(key)
 state["band_name"] = str(save_data.get("band",{}).get("name","The Band"))
 state["members"] = save_data.get("band",{}).get("members",[]).duplicate(true)
 state["relationships"] = save_data.get("relationships",{}).duplicate(true)
 return state

func _apply(updated: Dictionary) -> void:
 for key in ["cash","tour_day","morale","reputation","readiness","tension","van_health"]:
  if updated.has(key):
   save_data[key] = updated[key]
 if updated.has("members"):
  var band_data: Dictionary = save_data["band"]
  band_data["members"] = updated["members"]
 if updated.has("relationships"):
  save_data["relationships"] = updated["relationships"]
 var extra: Dictionary = _extra()
 for key in updated.keys():
  if not ["cash","tour_day","morale","reputation","readiness","tension","van_health","members","relationships","band_name"].has(key):
   extra[key] = updated[key]

func _finish(result: Dictionary, source: String = "") -> void:
 var before: Dictionary = _state()
 var successful: bool = bool(result.get("ok",false))
 if successful:
  dialogue_serial += 1
  _cancel_dialogue_request()
 message = str(result.get("message","Action unavailable"))
 if successful:
  _apply(Life.refresh(Calendar.expire(Story.observe(before,result["state"],source))))
  _save()
 _render()
 if successful:
  _show_decision_result(before,_state(),message,source)

func _show_decision_result(before: Dictionary, after: Dictionary, description: String, source: String) -> void:
 # The game is committed before animation. A skipped animation never loses a turn.
 var shade := ColorRect.new()
 shade.name = "DecisionOverlay"
 shade.color = Color(0.025,0.04,0.07,0.0)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x-32.0,510.0),0)
 panel.add_theme_stylebox_override("panel",UI.style(UI.PANEL,20))
 center.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",14)
 panel.add_child(stack)
 var overline := _label(stack,"LIVIN' THE DREAM  /  CAREER MOMENT",11,UI.MUTED)
 overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var title := _label(stack,Motion.headline(source,true),24,UI.AMBER)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var description_label := _label(stack,description,16,UI.WHITE)
 description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var changes: Array = Motion.changes(before,after)
 for change in changes.slice(0,5):
  var stat := _label(stack,Motion.delta_text(change),16,UI.AMBER if int(change.get("delta",0)) >= 0 else UI.MUTED)
  stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var next_button := UI.button("CONTINUE  ›",true)
 next_button.name = "DecisionContinue"
 stack.add_child(next_button)
 next_button.pressed.connect(func() -> void:
  next_button.disabled = true
  var dismiss := create_tween()
  dismiss.tween_property(shade,"modulate:a",0.0,0.16)
  dismiss.tween_callback(shade.queue_free)
 )
 shade.modulate.a = 0.0
 var reveal := create_tween()
 reveal.set_parallel(true)
 reveal.tween_property(shade,"modulate:a",1.0,0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 reveal.tween_property(shade,"color:a",0.94,0.25)


func _practice(focus: String) -> void:
 _finish(Practice.resolve(_state(),focus))

func _do_action(id: String) -> void:
 _finish(Actions.resolve(_state(),id))

func _advance_gig_night() -> void:
 var progressed: Dictionary = GigNight.advance(_state())
 if not bool(progressed.get("ok",false)):
  message = str(progressed.get("message","Unavailable"))
  _render()
  return
 _apply(progressed["state"])
 _save()
 _render()

func _change_gig_strategy(approach: String) -> void:
 var result: Dictionary = GigNight.choose_set(_state(),approach)
 if not bool(result.get("ok",false)):
  message = str(result.get("message","Unavailable"))
  _render()
  return
 _apply(result["state"])
 _save()
 _render()

func _perform_gig() -> void:
 var view: Dictionary = GigNight.stage(_state())
 if not bool(view.get("can_play",false)):
  message = "Complete the arrival and soundcheck before going onstage."
  _render()
  return
 var before := _state()
 var booked: Dictionary = Calendar.pending(before)
 var result: Dictionary = Calendar.perform(before)
 if bool(result.get("ok",false)):
  result["state"] = GigNight.reset_after_show(Promoter.settle(result["state"],before))
  var terms: Dictionary = before.get("promoter_offer",{})
  var final_history: Array = result["state"].get("gig_history",[])
  if not terms.is_empty() and not final_history.is_empty():
   var latest: Dictionary = final_history.back()
   result["message"] = str(result.get("message","Show finished."))+" Promoter settlement: £%d after the %s agreement." % [int(latest.get("fee",0)),str(terms.get("offer_id","standard"))]
 _finish(result,"gig:"+str(booked.get("venue_id","")))

func _schedule(id: String,approach: String, hire_session: bool = false) -> void:
 _finish(Calendar.book(_state(),id,approach,hire_session))

func _book(id: String,approach: String, hire_session: bool = false) -> void:
 _finish(Gigs.play(_state(),id,approach,hire_session),"gig:"+id)

func _buy(id: String) -> void:
 _finish(Gear.buy(_state(),id))

func _member(index: int, action: String) -> void:
 _finish(Members.resolve(_state(),index,action))

func _choose(event_id: String,choice_id: String) -> void:
 _finish(Opportunities.resolve(_state(),event_id,choice_id))

func _repair() -> void:
 if _num("cash") < 45:
  message = "You need £45 to repair the van."
  _render()
  return
 save_data["cash"] = _num("cash") - 45
 save_data["tour_day"] = _num("tour_day") + 1
 save_data["van_health"] = mini(100,_num("van_health") + 30)
 _apply(Calendar.expire(_state()))
 message = "The garage gets the van back on the road."
 _save()
 _render()

func _menu() -> void:
 dialogue_serial += 1
 _cancel_dialogue_request()
 _save()
 get_tree().change_scene_to_file("res://main_menu.tscn")
