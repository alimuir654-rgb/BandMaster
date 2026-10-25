extends Control

const UI = preload("res://Scripts/ui_theme.gd")
const Genres = preload("res://Scripts/genre_profiles.gd")
const Components = preload("res://Scripts/ui_components.gd")
const Presentation = preload("res://Scripts/career_presentation.gd")
const Scrapbook = preload("res://Scripts/scrapbook_filter.gd")
const LocalDialogue = preload("res://Scripts/local_dialogue_adapter.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const VenueBrowser = preload("res://Scripts/venue_browser.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const GigNight = preload("res://Scripts/gig_night_flow.gd")
const LiveBrief = preload("res://Scripts/live_night_briefing.gd")
const Recording = preload("res://Scripts/recording_career.gd")
const Campaigns = preload("res://Scripts/release_campaigns.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const SongStudio = preload("res://Scripts/song_studio_presentation.gd")
const SongLab = preload("res://Scripts/songwriting_lab.gd")
const RosterView = preload("res://Scripts/band_roster_view.gd")
const Social = preload("res://Scripts/band_social.gd")
const Experience = preload("res://Scripts/band_life_experience.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Members = preload("res://Scripts/member_management.gd")
const Story = preload("res://Scripts/career_story.gd")
const Chapters = preload("res://Scripts/career_chapters.gd")
const Director = preload("res://Scripts/first_month_director.gd")
const OpeningHandoff = preload("res://Scripts/opening_handoff.gd")
const CareerLayout = preload("res://Scripts/career_layout.gd")
const Momentum = preload("res://Scripts/career_momentum_presentation.gd")
const Portrait = preload("res://Scripts/member_portrait.gd")
const Motion = preload("res://Scripts/career_motion.gd")
const Drama = preload("res://Scripts/band_drama.gd")
const Life = preload("res://Scripts/member_life.gd")
const BandPulse = preload("res://Scripts/band_pulse_presentation.gd")
const Chemistry = preload("res://Scripts/band_chemistry_presentation.gd")
const SAVE_PATH := "user://tour_save.json"
const TABS := ["HOME","GIGS","GEAR","BAND","ACTIONS","SCENE"]

var save_data: Dictionary = {}
var tab := "HOME"
var message := ""
var content: VBoxContainer
var scrapbook_filter := "ALL"
var action_view := "JAM"
var gig_show_locked := false
var gig_selected_venue := ""
var selected_band_member := -1
var roster_sort := "LINEUP"
var selected_gear_item := ""
var preserve_gear_scroll := false
var career_scroll: ScrollContainer
var preserve_roster_scroll := false
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
 var readable_size := size + 2 if get_viewport_rect().size.x >= 960.0 and size <= 17 else size
 label.add_theme_font_size_override("font_size",readable_size)
 label.add_theme_color_override("font_color",colour)
 parent.add_child(label)
 return label

func _genre_id() -> String:
 var band_data = save_data.get("band",{})
 return Genres.normalize(str(band_data.get("genre","indie"))) if band_data is Dictionary else "indie"

func _card(title: String, description: String = "") -> VBoxContainer:
 return Components.section(content,title,description,_genre_id())

func _action(parent: Node, name: String, callback: Callable, primary: bool = false) -> void:
 var button := UI.themed_button(name,_genre_id(),primary)
 parent.add_child(button)
 button.pressed.connect(callback)

func _progress(parent: Node, name: String, value: int, maximum: int = 100) -> void:
 var row := HBoxContainer.new()
 parent.add_child(row)
 var label := _label(row,name + "  %d" % value,14,UI.WHITE)
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var bar := ProgressBar.new()
 bar.custom_minimum_size = Vector2(105,12)
 bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 UI.themed_progress(bar,_genre_id())
 bar.max_value = maxi(1,maximum)
 bar.value = clampi(value,0,int(bar.max_value))
 bar.show_percentage = false
 row.add_child(bar)

func _render() -> void:
 var previous_scroll := 0
 if (preserve_roster_scroll or preserve_gear_scroll) and is_instance_valid(career_scroll):
  previous_scroll = career_scroll.scroll_vertical
 preserve_roster_scroll = false
 preserve_gear_scroll = false
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var background := ColorRect.new()
 background.color = UI.palette(_genre_id())["bg"]
 add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroll := ScrollContainer.new()
 career_scroll = scroll
 add_child(scroll)
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 if get_viewport_rect().size.x >= 960.0:
  scroll.offset_left = 116
 else:
  scroll.offset_bottom = -CareerLayout.content_inset(get_viewport_rect().size.x)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 var margin := MarginContainer.new()
 margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 margin.add_theme_constant_override("margin_left",CareerLayout.content_gutter(get_viewport_rect().size.x))
 margin.add_theme_constant_override("margin_right",CareerLayout.content_gutter(get_viewport_rect().size.x))
 margin.add_theme_constant_override("margin_top",12)
 margin.add_theme_constant_override("margin_bottom",24)
 scroll.add_child(margin)
 content = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",10)
 margin.add_child(content)
 _header()
 if tab != "HOME" and tab != "ACTIONS" and tab != "BAND":
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
 if get_viewport_rect().size.x < 960.0:
  var menu := UI.button("SAVE & MAIN MENU")
  menu.custom_minimum_size.y = 48
  content.add_child(menu)
  menu.pressed.connect(_menu)
 _bottom_nav()
 if previous_scroll > 0:
  scroll.set_deferred("scroll_vertical",previous_scroll)
 content.modulate.a = 0.0
 var appear := create_tween()
 appear.tween_property(content,"modulate:a",1.0,0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _header() -> void:
 var palette: Dictionary = save_data.get("band",{}).get("palette",{})
 var colour: Color = UI.palette(_genre_id())["accent"]
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
 day_panel.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["panel"],12))
 row.add_child(day_panel)
 var day := _label(day_panel,"DAY %d" % _num("tour_day"),15,UI.AMBER)
 day.autowrap_mode = TextServer.AUTOWRAP_OFF
 day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 day.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 day.clip_text = true
 if get_viewport_rect().size.x >= 960.0:
  var command := UI.themed_button("SAVE & MENU",_genre_id(),false)
  command.size_flags_horizontal = Control.SIZE_SHRINK_END
  command.custom_minimum_size = Vector2(156,48)
  if command is WoldButton:
   command.icon_start = "menu"
  row.add_child(command)
  command.pressed.connect(_menu)
 var stats := HBoxContainer.new()
 stats.add_theme_constant_override("separation",10 if get_viewport_rect().size.x >= 960.0 else 5)
 content.add_child(stats)
 var wide := get_viewport_rect().size.x >= 960.0
 for entry in [
  {"title":"CASH","value":"£%d" % _num("cash"),"icon":"wallet","detail":"Available band funds"},
  {"title":"FANS","value":str(_num("fans")),"icon":"users","detail":"Your audience"},
  {"title":"REPUTATION","value":str(_num("reputation")),"icon":"star","detail":"Industry standing"}
 ]:
  var metric_panel := PanelContainer.new()
  metric_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  metric_panel.size_flags_stretch_ratio = 1.0
  metric_panel.custom_minimum_size.y = 78 if wide else 62
  var metric_style := UI.style(UI.palette(_genre_id())["panel"],12)
  metric_style.border_width_top = 2
  metric_style.border_color = UI.palette(_genre_id())["accent"].darkened(0.20)
  metric_panel.add_theme_stylebox_override("panel",metric_style)
  metric_panel.tooltip_text = str(entry["detail"])
  stats.add_child(metric_panel)
  var inner := MarginContainer.new()
  inner.add_theme_constant_override("margin_left",12 if wide else 7)
  inner.add_theme_constant_override("margin_right",10 if wide else 5)
  inner.add_theme_constant_override("margin_top",8)
  inner.add_theme_constant_override("margin_bottom",8)
  metric_panel.add_child(inner)
  var metric_row := HBoxContainer.new()
  metric_row.add_theme_constant_override("separation",10)
  inner.add_child(metric_row)
  if wide:
   var metric_icon := WoldIcon.new()
   metric_icon.icon_name = str(entry["icon"])
   metric_icon.custom_minimum_size = Vector2(28,28)
   metric_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
   metric_row.add_child(metric_icon)
  var metric_copy := VBoxContainer.new()
  metric_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  metric_copy.add_theme_constant_override("separation",1)
  metric_row.add_child(metric_copy)
  var name_label := _label(metric_copy,str(entry["title"]),11 if wide else 10,UI.MUTED)
  name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
  name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  var value_label := _label(metric_copy,str(entry["value"]),22 if wide else 17,UI.WHITE)
  value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
  value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _hero() -> void:
 var colours := UI.palette(_genre_id())
 var profile: Dictionary = Genres.from_save(save_data)
 var card := PanelContainer.new()
 card.add_theme_stylebox_override("panel",UI.style(colours["panel"],12))
 content.add_child(card)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",10)
 card.add_child(column)
 var genre_name := str(profile.get("name","Indie / Alternative")).to_upper()
 _label(column,genre_name+"  /  "+tab,12,colours["accent"])
 var titles := {
  "HOME":"YOUR BAND. YOUR FUTURE.","GIGS":"THE LIVE CIRCUIT",
  "GEAR":"FIND YOUR SOUND","BAND":"THE PEOPLE BEHIND THE MUSIC",
  "ACTIONS":"THE WRITING ROOM","SCENE":"YOUR MUSIC SCENE"
 }
 _label(column,str(titles.get(tab,"THE NEXT CHAPTER")),23,UI.WHITE)
 var art_path := "res://Art/Backgrounds/%s/%s.webp" % [_genre_id(),tab.to_lower()]
 if not ResourceLoader.exists(art_path):
  art_path = "res://Art/Backgrounds/shared/%s.webp" % tab.to_lower()
 if ResourceLoader.exists(art_path):
  var artwork := TextureRect.new()
  artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  artwork.custom_minimum_size.y = CareerLayout.hero_height(get_viewport_rect().size.x)
  artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
  artwork.texture = load(art_path)
  column.add_child(artwork)
 else:
  _label(column,str(profile.get("tagline","Make your next move.")),15,UI.MUTED)


func _home() -> void:
 var full_content := content
 var landscape_dashboard := get_viewport_rect().size.x >= 960.0
 var main_column: VBoxContainer
 var sidebar: VBoxContainer
 if landscape_dashboard:
  var dashboard := HBoxContainer.new()
  dashboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  dashboard.add_theme_constant_override("separation",14)
  full_content.add_child(dashboard)
  main_column = VBoxContainer.new()
  main_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  main_column.size_flags_stretch_ratio = 1.65
  main_column.add_theme_constant_override("separation",12)
  dashboard.add_child(main_column)
  sidebar = VBoxContainer.new()
  sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  sidebar.size_flags_stretch_ratio = 1.0
  sidebar.add_theme_constant_override("separation",12)
  dashboard.add_child(sidebar)
  content = main_column
 var guidance: Dictionary = Director.next_move(_state())
 var focus := _card("YOUR NEXT MOVE  /  "+str(guidance.get("title","")),str(guidance.get("detail","")))
 var destination := str(guidance.get("tab","ACTIONS"))
 _action(focus,str(guidance.get("action","CONTINUE"))+"  ›",func() -> void: _switch(destination),true)
 if landscape_dashboard:
  content = sidebar
 var stage := _card("YOUR BAND","Your story starts in the rehearsal room.")
 var feature_path := "res://Art/Backgrounds/%s/home.webp" % _genre_id()
 if not ResourceLoader.exists(feature_path):
  feature_path = "res://Art/Backgrounds/shared/home.webp"
 if ResourceLoader.exists(feature_path):
  var feature := TextureRect.new()
  feature.custom_minimum_size.y = 92 if CareerLayout.is_compact(get_viewport_rect().size.x) else 144
  feature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  feature.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  feature.mouse_filter = Control.MOUSE_FILTER_IGNORE
  feature.texture = load(feature_path)
  stage.add_child(feature)
 var band_label := _label(stage,str(save_data.get("band",{}).get("name","YOUR BAND")),28,UI.WHITE)
 band_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _label(stage,"DAY %d   /   %s" % [_num("tour_day"),str(Genres.from_save(save_data)["name"]).to_upper()],13,UI.palette(_genre_id())["accent"])
 if landscape_dashboard:
  content = main_column
 var destinations := _card("YOUR WORLD","Choose where the band heads next.")
 var places := GridContainer.new()
 places.columns = CareerLayout.destination_columns(get_viewport_rect().size.x)
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
  var tile := WoldButton.new()
  tile.shape = WoldButton.Shape.SECONDARY
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tile.custom_minimum_size.y = 78 if CareerLayout.is_compact(get_viewport_rect().size.x) else 96
  tile.icon_start = {"ACTIONS":"music","GIGS":"ticket","BAND":"users","SCENE":"globe","GEAR":"guitar"}.get(str(data["tab"]),"arrow-right")
  tile.icon_end = "chevron-right"
  tile.text = str(data["name"])
  tile.tooltip_text = str(data["caption"])
  tile.accessibility_name = str(data["name"])+" — "+str(data["caption"])
  tile.add_theme_font_size_override("font_size",16 if CareerLayout.is_compact(get_viewport_rect().size.x) else 18)
  tile.add_theme_stylebox_override("normal",UI.style(UI.palette(_genre_id())["alt"],12))
  tile.add_theme_stylebox_override("hover",UI.style(UI.palette(_genre_id())["alt"].lightened(0.14),12))
  tile.add_theme_stylebox_override("pressed",UI.style(UI.palette(_genre_id())["panel"],12))
  places.add_child(tile)
  var target: String = str(data["tab"])
  tile.pressed.connect(func() -> void: _switch(target))

 if landscape_dashboard:
  content = sidebar
 if landscape_dashboard:
  content = sidebar
 var pulse := _card("BAND PULSE","Your next show depends on preparation and morale.")
 for key in ["readiness","morale","van_health"]:
  _progress(pulse,key.to_upper().replace("_"," "),_num(key))
 var momentum := _card("CAREER MOMENTUM","Your band's current priorities at a glance.")
 for status_entry in Momentum.signals(_state()):
  var target_tab := str(status_entry["tab"])
  var signal_button := UI.button(str(status_entry["label"])+"  /  "+str(status_entry["detail"]))
  signal_button.custom_minimum_size.y = 54
  signal_button.tooltip_text = str(status_entry["detail"])
  momentum.add_child(signal_button)
  signal_button.pressed.connect(func() -> void: _switch(target_tab))

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
 if landscape_dashboard:
  content = main_column
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
 if landscape_dashboard:
  content = sidebar
 var songs: Array = _extra().get("song_catalogue",[])
 if not songs.is_empty():
  var songbook := _card("ORIGINAL SONGS","Your band is building its first setlist.")
  for i in range(songs.size()-1,maxi(-1,songs.size()-4),-1):
   var tune: Dictionary = songs[i]
   _label(songbook,str(tune.get("title","UNTITLED"))+"  /  QUALITY %d" % int(tune.get("quality",0)),14,UI.WHITE)
  _label(songbook,"%d TOTAL ORIGINALS" % _num("songs"),12,UI.AMBER)
 var memories := Story.latest(_state(),3)
 if not memories.is_empty():
  var journal := _card("LATEST FROM THE BAND","A living scrapbook of gigs, friendships and turning points.")
  for moment in memories:
   if moment is Dictionary:
    var clipping: Dictionary = Presentation.clipping(moment)
    _label(journal,str(clipping["rubric"])+"  /  DAY %d" % int(clipping["day"]),11,UI.AMBER)
    Components.story(journal,moment)
  _action(journal,"OPEN FULL SCRAPBOOK",func() -> void: _switch("SCENE"))
 if not landscape_dashboard:
  var quick := _card("SHORTCUTS","Jump straight into your next session.")
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
  write.pressed.connect(func() -> void:
   action_view = "JAM"
   _switch("ACTIONS")
  )
  practise.pressed.connect(func() -> void:
   action_view = "JAM"
   _switch("ACTIONS")
  )
 if landscape_dashboard:
  content = full_content

func _gigs() -> void:
 var brief: Dictionary = LiveBrief.briefing(_state())
 var briefing_card := _card("LIVE CIRCUIT  /  SHOW CONTROL",str(brief["detail"]))
 _label(briefing_card,str(brief["headline"]),23,UI.WHITE)
 if bool(brief["active"]):
  _label(briefing_card,str(brief["city"]).to_upper()+"  /  DAY %d  /  %s" % [int(brief["day"]),str(brief["deal"])],12,UI.AMBER)
  var timeline := HBoxContainer.new()
  timeline.add_theme_constant_override("separation",5)
  briefing_card.add_child(timeline)
  var active_step := LiveBrief.stage_index(str(brief["phase"]))
  for i in range(3):
   var marker := PanelContainer.new()
   marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   marker.add_theme_stylebox_override("panel",UI.style(UI.ALT if i<=active_step else UI.PANEL,8))
   timeline.add_child(marker)
   var step_text := _label(marker,"%02d  %s" % [i+1,str(brief["steps"][i])],11,UI.AMBER if i<=active_step else UI.MUTED)
   step_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _progress(briefing_card,"LIVE READINESS",int(brief["readiness"]))
  _label(briefing_card,"ORIGINALS IN THE SET  /  %d" % int(brief["originals"]),13,UI.WHITE)
  for tip in brief["tips"]:
   _label(briefing_card,str(tip),13,UI.MUTED)
  if int(brief["days_left"])>0:
   _action(briefing_card,"GO PREPARE THE BAND",func() -> void: _switch("ACTIONS"),true)
 var recap: Dictionary = LiveBrief.last_show(_state())
 if not recap.is_empty():
  var report := _card("LAST NIGHT  /  THE AFTERMATH",str(recap["venue"]))
  _label(report,"SHOW %s  /  FEE £%d" % ["LANDED" if bool(recap["success"]) else "WAS TOUGH",int(recap["fee"])],18,UI.AMBER)
  _label(report,"ORIGINALS PLAYED %d  /  DEAL %s" % [int(recap["originals"]),str(recap["terms"]).to_upper()],13,UI.MUTED)
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

 var venue_picker := _card("FIND YOUR NEXT VENUE","Choose a venue to inspect promoter terms. Locked venues are kept separate.")
 var filter_row := HBoxContainer.new()
 filter_row.add_theme_constant_override("separation",6)
 venue_picker.add_child(filter_row)
 for filter in [false,true]:
  var locked_view: bool = filter
  var filter_button := UI.button("AVAILABLE" if not locked_view else "LOCKED",gig_show_locked==locked_view)
  filter_button.custom_minimum_size.y = 50
  filter_row.add_child(filter_button)
  filter_button.pressed.connect(func() -> void:
   gig_show_locked = locked_view
   gig_selected_venue = ""
   _render()
  )
 var listed: Array = VenueBrowser.entries(_state(),gig_show_locked)
 gig_selected_venue = VenueBrowser.pick(listed,gig_selected_venue)
 if listed.is_empty():
  _label(venue_picker,"No venues in this category yet.",14,UI.MUTED)
 for entry in listed:
  var venue_id := str(entry["id"])
  var selected := gig_selected_venue == venue_id
  var item := UI.button(("●  " if selected else "")+str(entry["title"])+"  /  "+str(entry["city"]),selected)
  item.custom_minimum_size.y = 52
  venue_picker.add_child(item)
  item.pressed.connect(func() -> void:
   gig_selected_venue = venue_id
   _render()
  )
 if not gig_selected_venue.is_empty():
  var selected_venue: Dictionary = Gigs.get_venue(gig_selected_venue)
  if gig_show_locked:
   for entry in listed:
    if str(entry["id"])==gig_selected_venue:
     var gate := _card("UNLOCK  /  "+str(entry["title"]),"Requirements to secure a future booking")
     _label(gate,"%d MORE FANS  /  %d MORE REPUTATION" % [int(entry["missing_fans"]),int(entry["missing_rep"])],16,UI.AMBER)
     _action(gate,"BUILD YOUR AUDIENCE  ›",func() -> void: _switch("SCENE"),true)
     break
  else:
   var venue_key := gig_selected_venue
   var box := _card(str(selected_venue["venue"])+"  /  "+str(selected_venue["city"]),"POTENTIAL FEE £%d  ·  TRAVEL £%d  ·  %d DAYS AWAY" % [int(selected_venue["fee"]),int(selected_venue["travel"]),int(selected_venue["days"])])
   _label(box,"CHOOSE THE PROMOTER DEAL",13,UI.AMBER)
   for offer_id in ["standard","guarantee","guestlist"]:
    var proposal: String = offer_id
    var terms: Dictionary = Promoter.OFFERS[proposal]
    var choice := UI.button(str(terms["label"])+"  ›")
    choice.custom_minimum_size.y = 54
    choice.disabled = not booked.is_empty() or not line_up_ready
    box.add_child(choice)
    _label(box,str(terms["description"]),12,UI.MUTED)
    choice.pressed.connect(func() -> void: _finish(Promoter.book(_state(),venue_key,proposal)))
   if not line_up_ready and available_count >= 1 and booked.is_empty():
    var session := UI.button("BOOK WITH SESSION DRUMMER · £25",true)
    session.disabled = _num("cash") < 25 or (venue_key != "local" and _num("cash") < 25+int(selected_venue["travel"]))
    box.add_child(session)
    session.pressed.connect(func() -> void: _finish(Promoter.book(_state(),venue_key,"standard",true)))
 var repairs := _card("KEEP THE VAN MOVING","£45 restores 30 van condition. Hometown gigs are still available when cash is low.")
 _action(repairs,"REPAIR VAN — £45",_repair)

func _gear() -> void:
 var owned: Array = _extra().get("owned_equipment",[])
 var heading := _card("THE MUSIC SHOP","Browse second-hand equipment, then inspect a single item before buying.")
 _progress(heading,"READINESS",_num("readiness"))
 _label(heading,"%d OWNED  /  %d AVAILABLE  /  £%d CASH" % [owned.size(),Gear.ITEMS.size()-owned.size(),_num("cash")],13,UI.AMBER)
 var inventory := _card("EQUIPMENT CATALOGUE","Select equipment to view its condition, cost and effect on readiness.")
 var valid_selection := false
 for item in Gear.ITEMS:
  if str(item["id"]) == selected_gear_item:
   valid_selection = true
 if not valid_selection:
  selected_gear_item = str(Gear.ITEMS[0]["id"]) if not Gear.ITEMS.is_empty() else ""
 for item in Gear.ITEMS:
  var key: String = str(item["id"])
  var selected := selected_gear_item == key
  var owned_item := owned.has(key)
  var row_button := UI.button(("●  " if selected else "")+str(item["name"])+("  ·  OWNED" if owned_item else "  ·  £%d" % int(item["price"])),selected)
  row_button.custom_minimum_size.y = 54
  row_button.tooltip_text = str(item["type"])+": "+str(item["description"])
  inventory.add_child(row_button)
  row_button.pressed.connect(func() -> void:
   selected_gear_item = key
   preserve_gear_scroll = true
   _render()
  )
 for item in Gear.ITEMS:
  if str(item["id"]) != selected_gear_item:
   continue
  var detail := _card(str(item["name"]),str(item["description"]))
  _label(detail,str(item["type"]).to_upper()+"  /  +%d READINESS" % int(item["readiness"]),13,UI.AMBER)
  _label(detail,"ASKING PRICE  /  £%d" % int(item["price"]),15,UI.WHITE)
  if owned.has(selected_gear_item):
   _label(detail,"✓  ALREADY IN YOUR INVENTORY",14,UI.AMBER)
  else:
   var afford := _num("cash") >= int(item["price"])
   if not afford:
    _label(detail,"NEED £%d MORE TO BUY" % (int(item["price"])-_num("cash")),13,UI.MUTED)
   var buy := UI.button("BUY EQUIPMENT  ·  £%d" % int(item["price"]),true)
   buy.custom_minimum_size.y = 54
   buy.disabled = not afford
   detail.add_child(buy)
   var purchase_key := selected_gear_item
   buy.pressed.connect(func() -> void: _buy(purchase_key))
  break

func _band() -> void:
 _band_situations()
 _life_situations()
 var band_data: Dictionary = save_data.get("band",{})
 var members: Array = band_data.get("members",[])
 var pulse: Dictionary = BandPulse.overview(members)
 var pairs: Array = Chemistry.connections(members,save_data.get("relationships",{}))
 if get_viewport_rect().size.x >= 960.0 and not members.is_empty():
  var brief := _card("BAND MANAGEMENT  /  LIVE BRIEFING","Keep the band ready, connected and able to perform.")
  var briefing_row := HBoxContainer.new()
  briefing_row.add_theme_constant_override("separation",10)
  brief.add_child(briefing_row)
  for metric in [
   {"label":"ACTIVE","value":int(pulse.get("active",0)),"icon":"users"},
   {"label":"NEED REST","value":int(pulse.get("exhausted",0)),"icon":"heart-pulse"},
   {"label":"GROUP LOYALTY","value":int(pulse.get("loyalty",0)),"icon":"handshake"}
  ]:
   var metric_card := PanelContainer.new()
   metric_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   metric_card.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],10))
   briefing_row.add_child(metric_card)
   var metric_stack := VBoxContainer.new()
   metric_stack.add_theme_constant_override("separation",3)
   metric_card.add_child(metric_stack)
   _label(metric_stack,str(metric["label"]),12,UI.MUTED)
   _label(metric_stack,str(metric["value"]),25,UI.palette(_genre_id())["accent"])
  var brief_actions := HBoxContainer.new()
  brief_actions.add_theme_constant_override("separation",10)
  brief.add_child(brief_actions)
  var rehearse := UI.themed_button("OPEN STUDIO",_genre_id(),true)
  rehearse.icon_start = "music"
  brief_actions.add_child(rehearse)
  rehearse.pressed.connect(func() -> void: _switch("ACTIONS"))
  var gigs := UI.themed_button("GIG SCHEDULE",_genre_id(),false)
  gigs.icon_start = "calendar-days"
  brief_actions.add_child(gigs)
  gigs.pressed.connect(func() -> void: _switch("GIGS"))
  if int(pulse.get("exhausted",0)) > 0:
   _label(brief,"%d BANDMATE(S) NEED RECOVERY BEFORE THE NEXT SHOW" % int(pulse["exhausted"]),13,UI.palette(_genre_id())["secondary"])

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
   speaker_portrait.set_character(str(speaker_data.get("candidate_id",speaker_data.get("id",speaker_index))),speaker_name,_genre_id())
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
 if get_viewport_rect().size.x >= 960.0 and members.size() > 1:
  var sorting := HBoxContainer.new()
  sorting.add_theme_constant_override("separation",8)
  content.add_child(sorting)
  for mode in RosterView.MODES:
   var sort_mode: String = mode
   var control := UI.themed_button(sort_mode,_genre_id(),roster_sort == sort_mode)
   control.custom_minimum_size.y = 45
   control.tooltip_text = "Sort by "+sort_mode.to_lower()
   sorting.add_child(control)
   control.pressed.connect(func() -> void:
    roster_sort = sort_mode
    preserve_roster_scroll = true
    _render()
   )
 var roster_grid := GridContainer.new()
 var landscape_roster := get_viewport_rect().size.x >= 960.0
 roster_grid.columns = 2 if landscape_roster else 1
 roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 roster_grid.add_theme_constant_override("h_separation",12)
 roster_grid.add_theme_constant_override("v_separation",12)
 content.add_child(roster_grid)
 for i in RosterView.sorted_indices(members,roster_sort):
  if not members[i] is Dictionary:
   continue
  var member: Dictionary = members[i]
  var index := i
  var status := str(member.get("life_status","active"))
  var box := Components.section(roster_grid,"","",_genre_id())
  var identity := HBoxContainer.new()
  identity.add_theme_constant_override("separation",14)
  box.add_child(identity)
  var portrait := Portrait.new()
  portrait.custom_minimum_size = CareerLayout.member_portrait_size(get_viewport_rect().size.x)
  portrait.set_character(str(member.get("candidate_id",member.get("id",i))),str(member.get("name","Musician")),_genre_id())
  identity.add_child(portrait)
  var name_stack := VBoxContainer.new()
  name_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  identity.add_child(name_stack)
  _label(name_stack,str(member.get("name","Musician")).to_upper(),CareerLayout.member_name_font_size(get_viewport_rect().size.x),UI.WHITE)
  _label(name_stack,str(member.get("role","")).to_upper(),13,UI.palette(_genre_id())["accent"])
  _label(name_stack,str(member.get("trait","")),13,UI.MUTED)
  if get_viewport_rect().size.x >= 960.0:
   var badges := HBoxContainer.new()
   badges.add_theme_constant_override("separation",8)
   name_stack.add_child(badges)
   for entry in [{"label":"SKILL","key":"skill"},{"label":"MORALE","key":"morale"}]:
    var metric_panel := PanelContainer.new()
    metric_panel.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],8))
    metric_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    badges.add_child(metric_panel)
    var metric_text := _label(metric_panel,"%s  %d" % [str(entry["label"]),int(member.get(str(entry["key"]),50))],13,UI.WHITE)
    metric_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  else:
   _label(name_stack,"SKILL %d  /  MORALE %d" % [int(member.get("skill",50)),int(member.get("morale",50))],13,UI.WHITE)
  _label(name_stack,BandPulse.member_note(member),12,UI.palette(_genre_id())["accent"])
  if str(member.get("life_status","active")) != "active":
   _label(name_stack,str(member.get("life_status","")).to_upper()+" UNTIL DAY %d" % int(member.get("available_day",0)),12,UI.AMBER)
  if get_viewport_rect().size.x >= 960.0:
   var readiness_row := GridContainer.new()
   readiness_row.columns = 2
   readiness_row.add_theme_constant_override("h_separation",12)
   box.add_child(readiness_row)
   for metric_data in [
    {"label":"LOYALTY","key":"loyalty","kind":"accent"},
    {"label":"FATIGUE","key":"fatigue","kind":"secondary"}
   ]:
    var progress_block := VBoxContainer.new()
    progress_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_block.add_theme_constant_override("separation",4)
    readiness_row.add_child(progress_block)
    var amount := clampi(int(member.get(str(metric_data["key"]),50)),0,100)
    _label(progress_block,"%s  %d" % [str(metric_data["label"]),amount],12,UI.MUTED)
    var progress_meter := ProgressBar.new()
    progress_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_meter.custom_minimum_size.y = 8
    UI.themed_progress(progress_meter,_genre_id(),str(metric_data["kind"]))
    progress_meter.value = amount
    progress_block.add_child(progress_meter)
   if int(member.get("fatigue",0)) >= 75:
    _label(box,"HIGH FATIGUE  /  CONSIDER A REST DAY",12,UI.palette(_genre_id())["secondary"])
  var action_row := HBoxContainer.new()
  action_row.add_theme_constant_override("separation",8)
  box.add_child(action_row)
  var profile := UI.themed_button("CLOSE PROFILE" if selected_band_member == index else "VIEW DETAILS",_genre_id(),selected_band_member == index)
  profile.custom_minimum_size.y = 52
  if profile is WoldButton:
   profile.icon_start = "chart-no-axes-column"
  action_row.add_child(profile)
  profile.pressed.connect(func() -> void:
   selected_band_member = -1 if selected_band_member == index else index
   preserve_roster_scroll = true
   _render()
  )
  var talk := UI.themed_button("TALK",_genre_id(),false)
  talk.custom_minimum_size.y = 52
  if talk is WoldButton:
   talk.icon_start = "message-circle"
  action_row.add_child(talk)
  talk.pressed.connect(func() -> void: _listen(index))
  if selected_band_member != index:
   continue
  var rule := ColorRect.new()
  rule.color = UI.palette(_genre_id())["alt"]
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
   UI.themed_progress(meter,_genre_id(),"secondary" if key == "fatigue" else "accent")
   meter.value = clampi(int(member.get(key,50)),0,100)
   metric.add_child(meter)
  var member_actions := _label(box,"SPEND TIME WITH "+str(member.get("name","THE BANDMATE")).to_upper(),13,UI.AMBER)
  member_actions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  for choice in Experience.member_options(_state(),index):
   var choice_id := str(choice["id"])
   _experience_tile(box,str(choice["title"]),"A personal choice that changes how this musician feels about the band.",str(choice["impact"]),int(choice["cost"]),bool(choice["enabled"]),func() -> void: _member(index,choice_id))

 var overview := _card("THE LINEUP","%d ACTIVE  /  %d TOTAL  /  %s" % [int(pulse["active"]),members.size(),str(pulse["mood"]).to_upper()])
 if int(pulse["exhausted"]) > 0:
  _label(overview,"%d BANDMATE(S) NEED REST BEFORE THE NEXT SHOW" % int(pulse["exhausted"]),14,UI.palette(_genre_id())["secondary"])
 _label(overview,"TALK TO BANDMATES OR OPEN THEIR PROFILES.",13,UI.MUTED)
 var alumni: Array = _extra().get("former_members",[])
 if not alumni.is_empty():
  var alumni_box := _card("FORMER MEMBERS","The people who helped shape the band.")
  for person in alumni:
   if person is Dictionary:
    _label(alumni_box,str(person.get("name","Musician"))+"  /  "+str(person.get("role",""))+"  ·  "+str(person.get("reason","Left the band")),13,UI.MUTED)
 var chemistry := _card("BAND PULSE","How the band is coping between shows.")
 _progress(chemistry,"GROUP MORALE",int(pulse["morale"]))
 _progress(chemistry,"GROUP LOYALTY",int(pulse["loyalty"]))
 if not pairs.is_empty():
  var connection_card := _card("BAND CHEMISTRY","Shared experiences shape the connection between musicians.")
  for bond in pairs:
   _progress(connection_card,str(bond["first"])+" + "+str(bond["second"])+"  /  "+str(bond["mood"]),int(bond["value"]))

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

func _experience_tile(parent: Node, heading: String, story: String, impact: String, cost: int, enabled: bool, callback: Callable) -> void:
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",UI.style(UI.PANEL,14))
 parent.add_child(panel)
 var layout := VBoxContainer.new()
 layout.add_theme_constant_override("separation",8)
 panel.add_child(layout)
 _label(layout,heading,18,UI.WHITE)
 if not story.is_empty():
  _label(layout,story,14,UI.MUTED)
 _label(layout,impact,12,UI.AMBER)
 var start := UI.button("SPEND THE DAY  ›" if cost==0 else "COMMIT £%d  ·  1 DAY  ›" % cost,true)
 start.disabled = not enabled
 start.custom_minimum_size.y = 54
 layout.add_child(start)
 start.pressed.connect(callback)

func _actions() -> void:
 var mode_titles := {"JAM":"THE WRITING ROOM","HANG OUT":"AFTER HOURS","PROMOTE":"MAKE SOME NOISE"}
 var mode_descriptions := {"JAM":"Build a song from someone's idea.","HANG OUT":"Be people together, not just bandmates.","PROMOTE":"Get your name around town."}
 var switches := _card("CHOOSE YOUR DAY","Select an activity. Each commitment moves the band's story forward.")
 var navigation := HBoxContainer.new()
 navigation.add_theme_constant_override("separation",8)
 switches.add_child(navigation)
 for mode in ["JAM","HANG OUT","PROMOTE"]:
  var destination := str(mode)
  var selected := action_view == destination
  var button := UI.button(destination,selected)
  button.custom_minimum_size.y = 54
  button.add_theme_font_size_override("font_size",15 if get_viewport_rect().size.x >= 960.0 else 12)
  navigation.add_child(button)
  button.pressed.connect(func() -> void:
   action_view = destination
   _render()
  )
 # Desktop: a management workspace, not one long stack of cards.
 # Preserve the mobile single-column flow and existing action callbacks.
 var full_content := content
 var wide_workspace := get_viewport_rect().size.x >= 960.0
 var decision_column: VBoxContainer
 if wide_workspace:
  var split := HBoxContainer.new()
  split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  split.add_theme_constant_override("separation",14)
  full_content.add_child(split)
  decision_column = VBoxContainer.new()
  decision_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  decision_column.size_flags_stretch_ratio = 1.8
  decision_column.add_theme_constant_override("separation",10)
  split.add_child(decision_column)
  var context_column := VBoxContainer.new()
  context_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  context_column.size_flags_stretch_ratio = 1.0
  context_column.add_theme_constant_override("separation",10)
  split.add_child(context_column)
  content = context_column
 var scene_card := _card(str(mode_titles.get(action_view,"THE STUDIO")),str(mode_descriptions.get(action_view,"")))
 var image_path := "res://Art/Backgrounds/%s/studio.webp" % _genre_id()
 if action_view == "HANG OUT":
  image_path = "res://Art/Backgrounds/%s/backstage.webp" % _genre_id()
 elif action_view == "PROMOTE":
  image_path = "res://Art/Backgrounds/%s/promotion.webp" % _genre_id()
 if not ResourceLoader.exists(image_path):
  var shared_name := "studio" if action_view == "JAM" else ("backstage" if action_view == "HANG OUT" else "promotion")
  image_path = "res://Art/Backgrounds/shared/%s.webp" % shared_name
 if ResourceLoader.exists(image_path):
  var scene_art := TextureRect.new()
  scene_art.custom_minimum_size.y = 88 if CareerLayout.is_compact(get_viewport_rect().size.x) else 128
  scene_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  scene_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  scene_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
  scene_art.texture = load(image_path)
  scene_card.add_child(scene_art)
 var upcoming: Dictionary = Calendar.pending(_state())
 var snapshot: VBoxContainer
 if not wide_workspace or not upcoming.is_empty():
  snapshot = _card("TODAY IN THE STUDIO","READINESS %d  /  MORALE %d  /  TENSION %d" % [_num("readiness"),_num("morale"),_num("tension")] if not wide_workspace else "UPCOMING LIVE COMMITMENT")
 if wide_workspace:
  var dashboard := _card("SESSION CONTROL","A clear briefing before committing a day.")
  for meter_info in [
   {"label":"READINESS","key":"readiness"},
   {"label":"MORALE","key":"morale"},
   {"label":"TENSION","key":"tension"}
  ]:
   _progress(dashboard,str(meter_info["label"]),_num(str(meter_info["key"])))
  if action_view == "JAM":
   var progress: Dictionary = SongStudio.view(_state())
   var done := clampi(int(progress.get("completed",0)),0,3)
   _label(dashboard,"CURRENT SONG  /  %d OF 3 SESSIONS" % done,16,UI.palette(_genre_id())["accent"])
   var phase_bar := ProgressBar.new()
   phase_bar.max_value = 3
   phase_bar.value = done
   phase_bar.show_percentage = false
   phase_bar.custom_minimum_size.y = 14
   UI.themed_progress(phase_bar,_genre_id())
   dashboard.add_child(phase_bar)
   _label(dashboard,"NEXT: %s" % str(progress.get("stage","IDEA")),14,UI.WHITE)
  elif action_view == "HANG OUT":
   _label(dashboard,"CONNECTIONS & BAND CHEMISTRY",15,UI.palette(_genre_id())["accent"])
   _action(dashboard,"VIEW BAND RELATIONSHIPS",func() -> void: _switch("BAND"))
  else:
   _label(dashboard,"FANS %d  /  REPUTATION %d" % [_num("fans"),_num("reputation")],15,UI.palette(_genre_id())["accent"])
   _action(dashboard,"VIEW CAREER PROGRESS",func() -> void: _switch("SCENE"))
 if not upcoming.is_empty():
  var countdown := int(upcoming.get("day",1)) - _num("tour_day")
  if countdown > 0:
   _label(snapshot,"NEXT SHOW IN %d DAYS  /  %s" % [countdown,str(upcoming.get("venue","VENUE"))],13,UI.MUTED)
  elif countdown == 0:
   _action(snapshot,"SHOW DAY  /  HEAD TO THE GIG",func() -> void: _switch("GIGS"),true)
 if wide_workspace:
  content = decision_column
 if action_view == "JAM":
  var draft: Dictionary = _extra().get("current_song_draft",{})
  var workshop := _card("SONGWRITING  /  "+("START A NEW SONG" if draft.is_empty() else "DEVELOP YOUR SONG"),"Choose the sound, arrangement, title and session leader. Every session takes one day.")
  var studio: Dictionary = SongStudio.view(_state())
  var studio_title := _label(workshop,str(studio["headline"]),22,UI.WHITE)
  studio_title.add_theme_font_size_override("font_size",22)
  _label(workshop,str(studio["detail"]),14,UI.MUTED)
  var song_chemistry: Dictionary = studio["chemistry"]
  _label(workshop,"BAND CHEMISTRY  /  "+str(song_chemistry["label"])+"  ·  SCORE %d" % int(song_chemistry["score"]),13,UI.AMBER)
  _label(workshop,"CURRENT SONG QUALITY BONUS  /  +%d (BEFORE FINAL CAP)" % int(song_chemistry["bonus"]),12,UI.MUTED)

  var stages := HBoxContainer.new()
  stages.add_theme_constant_override("separation",6)
  workshop.add_child(stages)
  var phase_names := ["IDEA","SHAPE","FINISH"]
  var completed_sessions := int(studio["completed"])
  for step in range(3):
   var step_panel := PanelContainer.new()
   step_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   var stage_fill: Color = UI.palette(_genre_id())["alt"] if step <= completed_sessions else UI.palette(_genre_id())["panel"]
   var stage_style := UI.style(stage_fill,8)
   stage_style.border_color = UI.palette(_genre_id())["accent"] if step == completed_sessions else UI.palette(_genre_id())["alt"]
   stage_style.border_width_bottom = 3 if step == completed_sessions else 1
   step_panel.add_theme_stylebox_override("panel",stage_style)
   stages.add_child(step_panel)
   var stage_name := ("✓  " if step < completed_sessions else "%d  " % (step+1)) + str(phase_names[step])
   var marker := _label(step_panel,stage_name,12,UI.palette(_genre_id())["accent"] if step <= completed_sessions else UI.MUTED)
   marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _label(workshop,"%s  /  %d OF 3 SESSIONS COMPLETE" % [str(studio["stage"]),completed_sessions],13,UI.MUTED)
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
  var selector_grid := GridContainer.new()
  selector_grid.columns = 1 if CareerLayout.is_compact(get_viewport_rect().size.x) else 2
  selector_grid.add_theme_constant_override("h_separation",12)
  selector_grid.add_theme_constant_override("v_separation",10)
  workshop.add_child(selector_grid)
  for selector in selectors:
   var field := VBoxContainer.new()
   field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   field.add_theme_constant_override("separation",5)
   selector_grid.add_child(field)
   _label(field,str(selector["label"]),12,UI.MUTED)
   var control: OptionButton = selector["control"]
   control.custom_minimum_size.y = 52
   control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   control.tooltip_text = str(selector["label"])
   field.add_child(control)
  if get_viewport_rect().size.x >= 960.0:
   selector_grid.visible = false
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
  var preview_panel := PanelContainer.new()
  var preview_style := UI.style(UI.palette(_genre_id())["alt"],10)
  preview_style.border_color = UI.palette(_genre_id())["accent"]
  preview_style.border_width_left = 3
  preview_panel.add_theme_stylebox_override("panel",preview_style)
  workshop.add_child(preview_panel)
  var preview := VBoxContainer.new()
  preview.add_theme_constant_override("separation",6)
  preview_panel.add_child(preview)
  _label(preview,"YOUR SONG  /  LIVE PREVIEW",12,UI.palette(_genre_id())["accent"])
  _label(preview,"Selections update instantly. No day is spent until you commit.",12,UI.MUTED)
  var preview_heading := _label(preview,"",17,UI.WHITE)
  var preview_identity := _label(preview,"",13,UI.AMBER)
  var preview_arrangement := _label(preview,"",13,UI.MUTED)
  var preview_leader := _label(preview,"",12,UI.MUTED)
  var refresh_preview := func() -> void:
   var leader_name := leads.get_item_text(leads.selected) if leads.selected >= 0 else ""
   var details: Dictionary = SongStudio.preview(ideas.get_item_text(ideas.selected),forms.get_item_text(forms.selected),titles.get_item_text(titles.selected),leader_name)
   preview_heading.text = str(details["title"])
   preview_identity.text = str(details["identity"])
   preview_arrangement.text = str(details["arrangement"])
   preview_leader.text = str(details["leader"])
  for selector_control in [ideas,forms,titles,leads]:
   selector_control.item_selected.connect(func(_index: int) -> void: refresh_preview.call())
  if ideas.item_count > 0 and forms.item_count > 0 and titles.item_count > 0:
   refresh_preview.call()
  var lab := VBoxContainer.new()
  lab.add_theme_constant_override("separation",8)
  workshop.add_child(lab)
  _label(lab,"EXPERIMENT  /  NO TIME COST",12,UI.palette(_genre_id())["accent"])
  _label(lab,"Try a different riff, structure, title or bandmate before committing.",13,UI.MUTED)
  var experiment_grid := GridContainer.new()
  experiment_grid.columns = 2 if CareerLayout.is_compact(get_viewport_rect().size.x) else 4
  experiment_grid.add_theme_constant_override("h_separation",8)
  experiment_grid.add_theme_constant_override("v_separation",8)
  lab.add_child(experiment_grid)
  var choice_repaints: Array[Callable] = []
  var saved_take: Dictionary = {}
  var take_panel := PanelContainer.new()
  take_panel.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["panel"],9))
  lab.add_child(take_panel)
  var take_stack := VBoxContainer.new()
  take_stack.add_theme_constant_override("separation",7)
  take_panel.add_child(take_stack)
  _label(take_stack,"YOUR IDEAS  /  A-B WORKBENCH",12,UI.palette(_genre_id())["accent"])
  var take_status := _label(take_stack,"No take saved. Find a sound you like, then save it to compare.",13,UI.MUTED)
  var take_actions := HBoxContainer.new()
  take_actions.add_theme_constant_override("separation",8)
  take_stack.add_child(take_actions)
  var save_take := UI.themed_button("SAVE TAKE A",_genre_id(),false)
  save_take.custom_minimum_size.y = 48
  take_actions.add_child(save_take)
  var restore_take := UI.themed_button("RESTORE TAKE A",_genre_id(),false)
  restore_take.custom_minimum_size.y = 48
  restore_take.disabled = true
  take_actions.add_child(restore_take)
  var update_comparison := func() -> void:
   if saved_take.is_empty():
    return
   var changes := SongLab.difference(saved_take,ideas,forms,titles,leads)
   take_status.text = "TAKE A SAVED  /  %d OF 4 CHOICES DIFFER FROM CURRENT" % changes
  save_take.pressed.connect(func() -> void:
   saved_take.clear()
   saved_take.merge(SongLab.capture(ideas,forms,titles,leads))
   restore_take.disabled = saved_take.is_empty()
   update_comparison.call()
  )
  restore_take.pressed.connect(func() -> void:
   if SongLab.restore(saved_take,ideas,forms,titles,leads):
    refresh_preview.call()
    update_comparison.call()
    for repaint_card in choice_repaints:
     repaint_card.call()
  )
  for comparison_control in [ideas,forms,titles,leads]:
   comparison_control.item_selected.connect(func(_index: int) -> void: update_comparison.call())
  # Desktop creative controls: large, direct, tactile choice cards.
  # Underlying OptionButtons remain the authoritative choices and mobile UI.
  if get_viewport_rect().size.x >= 960.0:
   var creative_grid := GridContainer.new()
   creative_grid.columns = 2
   creative_grid.add_theme_constant_override("h_separation",10)
   creative_grid.add_theme_constant_override("v_separation",10)
   lab.add_child(creative_grid)
   lab.move_child(creative_grid,2)
   experiment_grid.visible = false
   for choice in [
    {"name":"01  SOUND","control":ideas,"icon":"audio-lines"},
    {"name":"02  STRUCTURE","control":forms,"icon":"list-music"},
    {"name":"03  TITLE","control":titles,"icon":"pen-line"},
    {"name":"04  SESSION LEAD","control":leads,"icon":"users"}
   ]:
    var selector_control: OptionButton = choice["control"]
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],10))
    creative_grid.add_child(card)
    var card_contents := VBoxContainer.new()
    card_contents.add_theme_constant_override("separation",6)
    card.add_child(card_contents)
    _label(card_contents,str(choice["name"]),13,UI.palette(_genre_id())["accent"])
    var choice_row := HBoxContainer.new()
    choice_row.add_theme_constant_override("separation",5)
    card_contents.add_child(choice_row)
    var previous := UI.themed_button("‹",_genre_id(),false)
    previous.custom_minimum_size = Vector2(42,48)
    previous.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    choice_row.add_child(previous)
    var active_choice := _label(choice_row,"",15,UI.WHITE)
    active_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    active_choice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    active_choice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    active_choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var next := UI.themed_button("›",_genre_id(),false)
    next.custom_minimum_size = Vector2(42,48)
    next.size_flags_horizontal = Control.SIZE_SHRINK_END
    choice_row.add_child(next)
    var repaint := func() -> void:
     active_choice.text = selector_control.get_item_text(selector_control.selected) if selector_control.selected >= 0 else "NOT SET"
    repaint.call()
    choice_repaints.append(repaint)
    selector_control.item_selected.connect(func(_index: int) -> void: repaint.call())
    previous.pressed.connect(func() -> void:
     if SongLab.advance(selector_control,-1):
      refresh_preview.call()
      update_comparison.call()
      repaint.call()
    )
    next.pressed.connect(func() -> void:
     if SongLab.advance(selector_control,1):
      refresh_preview.call()
      update_comparison.call()
      repaint.call()
    )
  for experiment in [
   {"name":"NEW IDEA","control":ideas},
   {"name":"NEW SHAPE","control":forms},
   {"name":"NEW TITLE","control":titles},
   {"name":"SWAP LEAD","control":leads}
  ]:
   var experiment_control: OptionButton = experiment["control"]
   var experiment_button := UI.themed_button(str(experiment["name"]),_genre_id(),false)
   experiment_button.custom_minimum_size.y = 48
   experiment_button.add_theme_font_size_override("font_size",14 if get_viewport_rect().size.x >= 960.0 else 12)
   experiment_button.disabled = experiment_control.item_count <= 1
   experiment_grid.add_child(experiment_button)
   experiment_button.pressed.connect(func() -> void:
    if SongLab.advance(experiment_control):
     refresh_preview.call()
     update_comparison.call()
   )
  var remix := UI.themed_button("REMIX ALL FOUR CHOICES",_genre_id(),false)
  remix.custom_minimum_size.y = 50
  remix.disabled = ideas.item_count <= 1 and forms.item_count <= 1 and titles.item_count <= 1 and leads.item_count <= 1
  lab.add_child(remix)
  remix.pressed.connect(func() -> void:
   SongLab.remix(ideas,forms,titles,leads)
   refresh_preview.call()
   update_comparison.call()
   for repaint_card in choice_repaints:
    repaint_card.call()
  )
  var jam := UI.themed_button("COMMIT TO THIS SONG  /  1 DAY",_genre_id(),true)
  jam.custom_minimum_size.y = 54
  jam.disabled = indices.is_empty() or not SongLab.can_commit(ideas,forms,titles,leads)
  workshop.add_child(jam)
  jam.pressed.connect(func() -> void:
   _finish(Practice.compose(_state(),ideas.get_item_text(ideas.selected),forms.get_item_text(forms.selected),titles.get_item_text(titles.selected),indices[leads.selected]))
  )
  if not draft.is_empty():
   var past: Array = studio.get("history",[])
   if not past.is_empty():
    var sessions_card := _card("WRITING ROOM NOTES","Revisit the choices that brought this track here.")
    for session in past:
     if session is Dictionary:
      _label(sessions_card,"DAY %d  ·  %s / %s  ·  %s" % [int(session.get("day",1)),str(session.get("idea","")),str(session.get("form","")),str(session.get("leader",""))],12,UI.MUTED)
  var drills := _card("REHEARSAL SESSIONS","Choose the pressure level. Technical discipline and band chemistry compete for time.")
  for option in Experience.practice_options(_state()):
   var focus_id := str(option["id"])
   _experience_tile(drills,str(option["title"]),str(option["story"]),str(option["impact"]),int(option["cost"]),bool(option["enabled"]),func() -> void: _practice(focus_id))
 if action_view == "HANG OUT":
  var socials := _card("LIFE OUTSIDE THE STUDIO","Bandmates need more than rehearsals. Going out costs money and a day, but builds trust.")
  for outing in Experience.social_options(_state()):
   var outing_id := str(outing["id"])
   _experience_tile(socials,str(outing["title"]),str(outing["story"]),str(outing["impact"]),int(outing["cost"]),bool(outing["enabled"]),func() -> void: _finish(Social.attend(_state(),outing_id)))
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
 content = full_content

func _recording_studio() -> void:
 var songs: Array = Recording.catalogue(_state())
 var recorded = _extra().get("recordings",[])
 var sessions: Array = recorded if recorded is Array else []
 var studio := _card("RECORDING STUDIO  /  YOUR FIRST RELEASE","Turn original songs into a local recording, then release it to build a following.")
 _label(studio,"%d ORIGINALS  /  %d DEMO SESSIONS" % [songs.size(),sessions.size()],14,UI.AMBER)
 var latest: Dictionary = Recording.can_record(_state())
 var record_button := UI.button("BOOK TWO DAYS IN THE STUDIO  ·  £%d" % Recording.DEMO_COST,true)
 record_button.disabled = not bool(latest.get("ok",false))
 studio.add_child(record_button)
 record_button.pressed.connect(func() -> void: _finish(Recording.record(_state()),"recording"))
 if not bool(latest.get("ok",false)):
  _label(studio,str(latest.get("message","")),13,UI.MUTED)
 for i in range(sessions.size()-1,-1,-1):
  if not sessions[i] is Dictionary:
   continue
  var session: Dictionary = sessions[i]
  var box := _card("DEMO %02d  /  %s" % [i+1,"RELEASED" if bool(session.get("released",false)) else "READY TO RELEASE"],"Recorded on day %d" % int(session.get("day",1)))
  _progress(box,"RECORDING QUALITY",int(session.get("quality",0)))
  for song in session.get("tracks",[]):
   if song is Dictionary:
    _label(box,str(song.get("title","UNTITLED"))+"  /  %d QUALITY" % int(song.get("quality",0)),13,UI.WHITE)
  if bool(session.get("released",false)):
   _label(box,"RELEASE DAY %d  /  +%d FANS" % [int(session.get("release_day",0)),int(session.get("fans_gained",0))],13,UI.AMBER)
   for offer in Campaigns.options(_state(),i):
    var campaign_id := str(offer["id"])
    var source_index := i
    var row := PanelContainer.new()
    row.add_theme_stylebox_override("panel",UI.style(UI.ALT,10))
    box.add_child(row)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation",5)
    row.add_child(body)
    _label(body,str(offer["label"]),15,UI.WHITE)
    _label(body,str(offer["description"]),12,UI.MUTED)
    var campaign_button := UI.button("DONE" if bool(offer["completed"]) else ("RUN CAMPAIGN · £%d / %d DAY(S)" % [int(offer["cost"]),int(offer["days"])]))
    campaign_button.custom_minimum_size.y = 50
    campaign_button.disabled = not bool(offer["enabled"])
    body.add_child(campaign_button)
    if not str(offer["reason"]).is_empty():
     _label(body,str(offer["reason"]),11,UI.AMBER)
    campaign_button.pressed.connect(func() -> void: _finish(Campaigns.launch(_state(),source_index,campaign_id),"campaign"))

  else:
   var index := i
   var publish := UI.button("RELEASE LOCALLY  ·  £%d" % Recording.RELEASE_COST,true)
   publish.disabled = _num("cash") < Recording.RELEASE_COST
   box.add_child(publish)
   publish.pressed.connect(func() -> void: _finish(Recording.release(_state(),index),"release"))

func _scene() -> void:
 _recording_studio()
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
 var career: Dictionary = Campaigns.next_milestone(_state())
 var milestone := _card("CAREER MOMENTUM  /  "+str(career["name"]),"Every recording, campaign and gig builds the audience needed for bigger venues.")
 _progress(milestone,"FANS",int(career["fans"]),maxi(1,int(career["target_fans"])))
 _progress(milestone,"REPUTATION",int(career["reputation"]),maxi(1,int(career["target_rep"])))
 _label(milestone,"TARGET  /  %d FANS  +  %d REPUTATION" % [int(career["target_fans"]),int(career["target_rep"])],13,UI.AMBER)
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
 var colours := UI.palette(_genre_id())
 var compact := CareerLayout.is_compact(get_viewport_rect().size.x)
 var panel := PanelContainer.new()
 var landscape := get_viewport_rect().size.x >= 960.0
 if landscape:
  panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
  panel.offset_right = 108
 else:
  panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
  panel.offset_top = -CareerLayout.footer_height(get_viewport_rect().size.x)
 panel.add_theme_stylebox_override("panel",UI.style(colours["panel"],0))
 add_child(panel)
 var bar := GridContainer.new()
 bar.columns = 1 if landscape else CareerLayout.columns(get_viewport_rect().size.x)
 bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 bar.add_theme_constant_override("h_separation",5)
 bar.add_theme_constant_override("v_separation",5)
 panel.add_child(bar)
 for tab_id in TABS:
  var target: String = tab_id
  var selected := target == tab
  var button := WoldButton.new()
  button.shape = WoldButton.Shape.SECONDARY
  button.custom_minimum_size.y = 68 if landscape else (56 if compact else 62)
  button.focus_mode = Control.FOCUS_ALL
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var fill: Color = colours["alt"] if selected else colours["panel"]
  var normal := UI.style(fill,10)
  normal.border_color = colours["accent"] if selected else colours["alt"]
  normal.border_width_bottom = 3 if selected else 1
  button.add_theme_stylebox_override("normal",normal)
  button.add_theme_stylebox_override("hover",UI.style(colours["alt"].lightened(0.12),10))
  button.add_theme_stylebox_override("pressed",UI.style(colours["alt"].darkened(0.1),10))
  var focus := UI.flat(Color(0,0,0,0),11)
  focus.border_color = colours["accent"]
  focus.set_border_width_all(2)
  button.add_theme_stylebox_override("focus",focus)
  var box := VBoxContainer.new()
  box.mouse_filter = Control.MOUSE_FILTER_IGNORE
  box.alignment = BoxContainer.ALIGNMENT_CENTER
  box.add_theme_constant_override("separation",2)
  button.add_child(box)
  box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  var icon_path := "res://Art/Icons/%s.svg" % target.to_lower()
  if not landscape and ResourceLoader.exists(icon_path):
   var glyph := TextureRect.new()
   glyph.texture = load(icon_path)
   glyph.custom_minimum_size = Vector2(21,22)
   glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   glyph.modulate = colours["accent"] if selected else UI.MUTED
   glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
   box.add_child(glyph)
  if landscape:
   button.icon_start = {"HOME":"house","GIGS":"ticket","GEAR":"guitar","BAND":"users","ACTIONS":"music","SCENE":"globe"}.get(target,"circle")
   button.icon_only = true
   button.button_size = WoldButton.Size.LG
   button.text = ""
  button.tooltip_text = CareerLayout.nav_hint(target)
  button.accessibility_name = CareerLayout.nav_label(target)+(" (current)" if selected else "")
  if not landscape:
   var caption := _label(box,CareerLayout.nav_label(target),12,colours["accent"] if selected else UI.WHITE)
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
