extends Control

const UI = preload("res://Scripts/ui_theme.gd")
const Genres = preload("res://Scripts/genre_profiles.gd")
const Components = preload("res://Scripts/ui_components.gd")
const SceneEnvironment = preload("res://Scripts/scene_environment.gd")
const Presentation = preload("res://Scripts/career_presentation.gd")
const Scrapbook = preload("res://Scripts/scrapbook_filter.gd")
const LocalDialogue = preload("res://Scripts/local_dialogue_adapter.gd")
const BandReplies = preload("res://Scripts/band_conversation_replies.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const VenueBrowser = preload("res://Scripts/venue_browser.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const GigNight = preload("res://Scripts/gig_night_flow.gd")
const BackstageIncident = preload("res://Scripts/gig_backstage_incident.gd")
const LiveBrief = preload("res://Scripts/live_night_briefing.gd")
const Recording = preload("res://Scripts/recording_career.gd")
const Campaigns = preload("res://Scripts/release_campaigns.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const SongStudio = preload("res://Scripts/song_studio_presentation.gd")
const Songbook = preload("res://Scripts/songbook_presentation.gd")
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
const SceneSheet = preload("res://Scripts/scene_sheet.gd")
const Life = preload("res://Scripts/member_life.gd")
const BandPulse = preload("res://Scripts/band_pulse_presentation.gd")
const Chemistry = preload("res://Scripts/band_chemistry_presentation.gd")
const SAVE_PATH := "user://tour_save.json"
const TABS := ["HOME","GIGS","GEAR","BAND","ACTIONS","SCENE"]

var save_data: Dictionary = {}
var tab := "HOME"
var message := ""
var content: VBoxContainer
var scene_view := "PROMOTE"
var scrapbook_filter := "ALL"
var action_view := "JAM"
var gig_show_locked := false
var gig_selected_venue := ""
var selected_band_member := -1
var roster_sort := "LINEUP"
var preserve_venue_scroll := false
var selected_gear_item := ""
var selected_tour_plan := Tour.DRIVE
var preserve_gear_scroll := false
var career_scroll: ScrollContainer
var preserve_roster_scroll := false
var dialogue_request: HTTPRequest
var dialogue_busy := false
var dialogue_serial := 0

func _ready() -> void:
 _load()
 if _is_show_day():
  tab = "GIGS"
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

func _scene_identity() -> String:
 if tab == "ACTIONS":
  return "STUDIO" if action_view == "JAM" else "DAY"
 return tab if ["HOME","GIGS"].has(tab) else "DEFAULT"

func _card(title: String, description: String = "") -> VBoxContainer:
 return Components.section(content,title,description,_genre_id(),_scene_identity())

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
 if (preserve_roster_scroll or preserve_gear_scroll or preserve_venue_scroll) and is_instance_valid(career_scroll):
  previous_scroll = career_scroll.scroll_vertical
 preserve_roster_scroll = false
 preserve_gear_scroll = false
 preserve_venue_scroll = false
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var background := ColorRect.new()
 background.color = UI.palette(_genre_id())["bg"]
 add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var environment := SceneEnvironment.new()
 environment.set_scene(_scene_identity())
 environment.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(environment)
 environment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
 match tab:
  "HOME": _home()
  "GIGS": _gigs()
  "GEAR": _gear()
  "BAND": _band()
  "ACTIONS": _actions()
  "SCENE": _scene()
 if not message.is_empty():
  var feedback := PanelContainer.new()
  var fb_style := UI.style(UI.palette(_genre_id())["alt"],8)
  fb_style.border_width_left = 3
  fb_style.border_color = UI.palette(_genre_id())["accent"]
  feedback.add_theme_stylebox_override("panel",fb_style)
  content.add_child(feedback)
  var feedback_label := _label(feedback,"LAST ACTION  /  "+message,12,UI.MUTED)
  feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
  {"title":"CASH","value":"£%d" % _num("cash"),"symbol":"£","detail":"Available band funds"},
  {"title":"FANS","value":str(_num("fans")),"symbol":"♫","detail":"Your audience"},
  {"title":"REPUTATION","value":str(_num("reputation")),"symbol":"★","detail":"Industry standing"}
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
   var metric_icon := _label(metric_row,str(entry["symbol"]),23,UI.palette(_genre_id())["accent"])
   metric_icon.custom_minimum_size.x = 28
   metric_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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


func _environment_dashboard() -> void:
 # Phone layouts prioritise player actions over a second layer of atmospheric status.
 if get_viewport_rect().size.x < 720.0:
  return
 var identity := _scene_identity()
 if not ["HOME","STUDIO","GIGS","DAY"].has(identity):
  return
 var panel := PanelContainer.new()
 var colors := UI.palette(_genre_id())
 var skin := UI.style(colors["panel"],14)
 skin.bg_color = {"HOME":Color("#372921"),"DAY":Color("#514D3E"),"STUDIO":Color("#172930"),"GIGS":Color("#1D172B")}[identity]
 skin.border_color = {"HOME":Color("#A17A4A"),"DAY":Color("#B5AD89"),"STUDIO":Color("#619B9B"),"GIGS":Color("#995876")}[identity]
 panel.add_theme_stylebox_override("panel",skin)
 content.add_child(panel)
 var header := VBoxContainer.new()
 header.add_theme_constant_override("separation",10)
 panel.add_child(header)
 match identity:
  "HOME":
   _label(header,"ON THE NOTICEBOARD  /  THE NEXT FEW DAYS",14,Color("#E7C58C"))
   var booking: Dictionary = Calendar.pending(_state())
   var note := "NO SHOW ON THE CALENDAR" if booking.is_empty() else ("%d DAYS UNTIL %s" % [maxi(0,int(booking.get("day",1))-_num("tour_day")),str(booking.get("venue","THE NEXT SHOW")).to_upper()])
   _label(header,note,22,UI.WHITE)
   var quick := HBoxContainer.new()
   quick.add_theme_constant_override("separation",8)
   header.add_child(quick)
   for destination in [{"text":"BAND LIFE","tab":"BAND","icon":"users"},{"text":"TODAY'S PLAN","tab":"ACTIONS","icon":"calendar-days"},{"text":"GIG DIARY","tab":"GIGS","icon":"ticket"}]:
    var target: String = str(destination["tab"])
    var control := UI.themed_button(str(destination["text"]),_genre_id(),false)
    control.icon_start = str(destination["icon"])
    control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    control.custom_minimum_size.y = 48
    quick.add_child(control)
    control.pressed.connect(func() -> void: _switch(target))
  "DAY":
   _label(header,"DAY PLANNER  /  CHOOSE WHAT MATTERS",14,Color("#EEE0B7"))
   _label(header,"Every commitment has an opportunity cost. Make the daylight count.",13,UI.WHITE)
   var calendar_row := HBoxContainer.new()
   header.add_child(calendar_row)
   for entry in ["MORNING  /  RESET","AFTERNOON  /  CREATE","EVENING  /  CONNECT"]:
    var slot := PanelContainer.new()
    slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slot.add_theme_stylebox_override("panel",UI.style(Color("#615D4B"),9))
    calendar_row.add_child(slot)
    var slot_title := _label(slot,entry,12,UI.WHITE)
    slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  "STUDIO":
   _label(header,"CONTROL DESK  /  BAND SIGNAL",14,Color("#9AD1C9"))
   var channels := GridContainer.new()
   channels.columns = 3 if get_viewport_rect().size.x >= 760.0 else 1
   channels.add_theme_constant_override("h_separation",8)
   channels.add_theme_constant_override("v_separation",8)
   header.add_child(channels)
   var session_channels := [
    {"name":"READINESS","amount":_num("readiness"),"hint":"Rehearsals prepare the band for bigger stages."},
    {"name":"MORALE","amount":_num("morale"),"hint":"Good relationships help creativity and performance."},
    {"name":"TENSION","amount":_num("tension"),"hint":"High tension puts extra pressure on the lineup."}
   ]
   for channel in session_channels:
    var channel_panel := PanelContainer.new()
    channel_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    channel_panel.add_theme_stylebox_override("panel",UI.style(Color("#233940"),8))
    channels.add_child(channel_panel)
    var lane := VBoxContainer.new()
    lane.add_theme_constant_override("separation",7)
    channel_panel.add_child(lane)
    _label(lane,str(channel["name"]),11,UI.MUTED)
    var meter := ProgressBar.new()
    meter.custom_minimum_size.y = 14
    UI.themed_progress(meter,_genre_id(),"secondary" if str(channel["name"]) == "TENSION" else "accent")
    meter.max_value = 100
    meter.value = clampi(int(channel["amount"]),0,100)
    lane.add_child(meter)
    _label(lane,"%d / 100" % int(channel["amount"]),13,UI.WHITE)
    channel_panel.tooltip_text = str(channel["hint"])
   var studio_advice := "Write or rehearse to strengthen your band's sound."
   if _num("tension") >= 65:
    studio_advice = "Tension is high. Consider spending time with the band before recording."
   elif _num("morale") < 40:
    studio_advice = "Morale is low. Band life and downtime may be more valuable than another session."
   _label(header,studio_advice,13,Color("#A9D2CD"))
   var console_actions := HBoxContainer.new()
   console_actions.add_theme_constant_override("separation",8)
   header.add_child(console_actions)
   for option in [{"text":"WORK ON A SONG","mode":"JAM","icon":"music"},{"text":"BAND LIFE","mode":"HANG OUT","icon":"users"}]:
    var select_mode: String = str(option["mode"])
    var console_button := UI.themed_button(str(option["text"]),_genre_id(),action_view == select_mode)
    console_button.icon_start = str(option["icon"])
    console_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    console_button.custom_minimum_size.y = 48
    console_actions.add_child(console_button)
    console_button.pressed.connect(func() -> void:
     action_view = select_mode
     _render()
    )
  "GIGS":
   _label(header,"FRONT OF HOUSE  /  STAGE SYSTEM",14,Color("#E7A9CE"))
   var stage_row := HBoxContainer.new()
   stage_row.add_theme_constant_override("separation",8)
   header.add_child(stage_row)
   for entry in [{"label":"L  /  PA","icon":"speaker"},{"label":"THE CROWD","icon":"users"},{"label":"R  /  PA","icon":"speaker"}]:
    var cabinet := PanelContainer.new()
    cabinet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cabinet.add_theme_stylebox_override("panel",UI.style(Color("#2B2438"),10))
    stage_row.add_child(cabinet)
    var cabinet_copy := VBoxContainer.new()
    cabinet_copy.add_theme_constant_override("separation",5)
    cabinet.add_child(cabinet_copy)
    var symbol := _label(cabinet_copy,"◉" if str(entry["icon"]) == "speaker" else "♫",23,Color("#D58CB5"))
    symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var text_label := _label(cabinet_copy,str(entry["label"]),11,UI.WHITE)
    text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   _label(header,"LIVE READINESS %d  /  MORALE %d  /  TENSION %d" % [_num("readiness"),_num("morale"),_num("tension")],13,UI.WHITE)

func _scene_instrument_strip() -> void:
 # Context-specific control language with real simulation information.
 var identity := _scene_identity()
 var strip := PanelContainer.new()
 var style := UI.style(UI.palette(_genre_id())["panel"],10)
 style.bg_color = {"HOME":Color("#453329"),"DAY":Color("#5C5848"),"STUDIO":Color("#20343B"),"GIGS":Color("#2E203C")}.get(identity,UI.PANEL)
 style.border_color = {"HOME":Color("#A17A4A"),"DAY":Color("#BAAF85"),"STUDIO":Color("#68A6A5"),"GIGS":Color("#B45986")}.get(identity,UI.AMBER)
 style.border_width_left = 4
 strip.add_theme_stylebox_override("panel",style)
 content.add_child(strip)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",12)
 strip.add_child(row)
 var copy := VBoxContainer.new()
 copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(copy)
 var title: String = {"HOME":"THE BAND HOUSE","DAY":"TODAY'S PLANS","STUDIO":"REHEARSAL CONSOLE","GIGS":"LIVE CONTROL ROOM"}.get(identity,"BANDMASTER")
 _label(copy,title,14,UI.WHITE)
 var caption: String = {"HOME":"A place to regroup, plan and connect.","DAY":"Daylight hours: choose where to spend your time.","STUDIO":"Build a song, experiment and check the levels.","GIGS":"The room is waiting. Prepare for the lights."}.get(identity,"")
 if get_viewport_rect().size.x >= 720.0:
  _label(copy,caption,12,UI.MUTED)
 var metric := ""
 match identity:
  "HOME":
   metric = "DAY %d" % _num("tour_day")
  "DAY":
   metric = "MORALE %d" % _num("morale")
  "STUDIO":
   metric = "READINESS %d" % _num("readiness")
  "GIGS":
   var booking: Dictionary = Calendar.pending(_state())
   metric = "SHOW IN %d DAYS" % maxi(0,int(booking.get("day",0))-_num("tour_day")) if not booking.is_empty() else "NO SHOW BOOKED"
 var indicator := _label(row,metric,13,UI.palette(_genre_id())["accent"])
 indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 indicator.autowrap_mode = TextServer.AUTOWRAP_OFF
 indicator.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 indicator.custom_minimum_size.x = 150 if get_viewport_rect().size.x >= 720.0 else 94
 indicator.size_flags_horizontal = Control.SIZE_SHRINK_END
 if get_viewport_rect().size.x < 720.0:
  indicator.add_theme_font_size_override("font_size",11)
 row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 strip.custom_minimum_size.y = 0

func _home_spotlight() -> void:
 # Landscape command deck: strong photograph, clear next action and contextual band data.
 var colours := UI.palette(_genre_id())
 var deck := PanelContainer.new()
 deck.add_theme_stylebox_override("panel",UI.style(colours["panel"],16))
 content.add_child(deck)
 var frame := HBoxContainer.new()
 frame.add_theme_constant_override("separation",18)
 deck.add_child(frame)
 var visual := TextureRect.new()
 visual.custom_minimum_size = Vector2(290,204)
 visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 visual.size_flags_stretch_ratio = 1.0
 visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var art_path := "res://Art/Backgrounds/%s/band.webp" % _genre_id()
 if not ResourceLoader.exists(art_path):
  art_path = "res://Art/Backgrounds/shared/band.webp"
 if ResourceLoader.exists(art_path):
  visual.texture = load(art_path)
 frame.add_child(visual)
 var details := VBoxContainer.new()
 details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 details.size_flags_stretch_ratio = 1.35
 details.add_theme_constant_override("separation",9)
 frame.add_child(details)
 _label(details,"BANDMASTER  /  THE CAREER DESK",12,colours["accent"])
 var band_name := str(save_data.get("band",{}).get("name","YOUR BAND"))
 var headline := _label(details,band_name,31,UI.WHITE)
 headline.max_lines_visible = 2
 headline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 _label(details,"DAY %d   •   %s" % [_num("tour_day"),str(Genres.from_save(save_data).get("name","Indie")).to_upper()],13,UI.MUTED)
 var guidance: Dictionary = Director.next_move(_state())
 _label(details,str(guidance.get("title","MAKE YOUR NEXT MOVE")).to_upper(),19,UI.WHITE)
 var description := _label(details,str(guidance.get("detail","Build your band, shape its music and find an audience.")),14,UI.MUTED)
 description.max_lines_visible = 3
 var commands := HBoxContainer.new()
 commands.add_theme_constant_override("separation",10)
 details.add_child(commands)
 var destination := str(guidance.get("tab","ACTIONS"))
 var primary := UI.themed_button(str(guidance.get("action","CONTINUE")).to_upper(),_genre_id(),true)
 primary.icon_end = "arrow-right"
 primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 commands.add_child(primary)
 primary.pressed.connect(func() -> void: _switch(destination))
 var secondary := UI.themed_button("YOUR BAND",_genre_id(),false)
 secondary.icon_start = "users"
 secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 commands.add_child(secondary)
 secondary.pressed.connect(func() -> void: _switch("BAND"))

func _home() -> void:
 _scene_instrument_strip()
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
  content = full_content
  _home_spotlight()
  content = main_column
 _environment_dashboard()
 if landscape_dashboard:
  content = sidebar
 var stage := _card("YOUR BAND","Your story starts in the rehearsal room.")
 var feature_path := "res://Art/Backgrounds/%s/band.webp" % _genre_id()
 if not ResourceLoader.exists(feature_path):
  feature_path = "res://Art/Backgrounds/shared/band.webp"
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
  {"name":"THE STUDIO","tab":"ACTIONS","caption":"Jam · Rehearse · Hang out","art":"studio"},
  {"name":"THE VENUES","tab":"GIGS","caption":"Book · Prepare · Perform","art":"gigs"},
  {"name":"THE BAND","tab":"BAND","caption":"People · Chemistry · Stories","art":"band"},
  {"name":"THE SCENE","tab":"SCENE","caption":"Promoters · Press · Scrapbook","art":"scene"},
  {"name":"THE GEAR SHOP","tab":"GEAR","caption":"Buy · Upgrade · Repair","art":"gear"}
 ]:
  var data: Dictionary = spot
  var destination_card := PanelContainer.new()
  destination_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  destination_card.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["panel"],12))
  places.add_child(destination_card)
  var destination_column := VBoxContainer.new()
  destination_column.add_theme_constant_override("separation",5)
  destination_card.add_child(destination_column)
  var thumb_path := "res://Art/Backgrounds/%s/%s.webp" % [_genre_id(),str(data["art"])]
  if not ResourceLoader.exists(thumb_path):
   thumb_path = "res://Art/Backgrounds/shared/%s.webp" % str(data["art"])
  if ResourceLoader.exists(thumb_path):
   var thumbnail := TextureRect.new()
   thumbnail.texture = load(thumb_path)
   thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
   thumbnail.custom_minimum_size.y = 98 if landscape_dashboard else 72
   thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
   destination_column.add_child(thumbnail)
  var tile := WoldButton.new()
  tile.shape = WoldButton.Shape.SECONDARY
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tile.custom_minimum_size.y = 56 if landscape_dashboard else 62
  tile.icon_start = {"ACTIONS":"music","GIGS":"ticket","BAND":"users","SCENE":"globe","GEAR":"guitar"}.get(str(data["tab"]),"arrow-right")
  tile.icon_end = "chevron-right"
  tile.text = str(data["name"])
  tile.tooltip_text = str(data["caption"])
  tile.accessibility_name = str(data["name"])+" — "+str(data["caption"])
  tile.add_theme_font_size_override("font_size",15 if CareerLayout.is_compact(get_viewport_rect().size.x) else 17)
  tile.add_theme_stylebox_override("normal",UI.style(UI.palette(_genre_id())["alt"],10))
  tile.add_theme_stylebox_override("hover",UI.style(UI.palette(_genre_id())["alt"].lightened(0.14),10))
  tile.add_theme_stylebox_override("pressed",UI.style(UI.palette(_genre_id())["panel"],10))
  destination_column.add_child(tile)
  var target: String = str(data["tab"])
  tile.pressed.connect(func() -> void: _switch(target))

 if landscape_dashboard:
  content = sidebar
 var pulse := _card("BAND PULSE","Your band at a glance — focus on the weakest area.")
 var pulse_row := HBoxContainer.new()
 pulse_row.add_theme_constant_override("separation",8)
 pulse.add_child(pulse_row)
 for key in ["readiness","morale","van_health"]:
  var amount := _num(key)
  var state_label := "STRONG" if amount >= 70 else ("WATCH" if amount >= 40 else "CRITICAL")
  var tint := Color("#67B894") if amount >= 70 else (Color("#F0B44D") if amount >= 40 else Color("#E57479"))
  var pill := UI.themed_button(key.to_upper().replace("_"," ")+"  ·  "+state_label,_genre_id(),false)
  pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  pill.add_theme_color_override("font_color",tint)
  pill.tooltip_text = "Current condition: %d / 100" % amount
  pulse_row.add_child(pill)
  var remedy_tab := "GEAR" if key == "van_health" else "ACTIONS"
  pill.pressed.connect(func() -> void: _switch(remedy_tab))
 var weakest := "readiness"
 for key in ["morale","van_health"]:
  if _num(key) < _num(weakest):
   weakest = key
 var advice := {"readiness":"Rehearse to prepare for tougher gigs.","morale":"Spend time together to rebuild morale.","van_health":"Repair the van before booking longer trips."}
 _label(pulse,str(advice[weakest]),13,UI.MUTED)
 _action(pulse,"IMPROVE THE BAND" if weakest != "van_health" else "OPEN GEAR & REPAIRS",func() -> void: _switch("GEAR" if weakest == "van_health" else "ACTIONS"))
 var opportunities := _card("WAYS FORWARD","Pick a practical route to grow the band.")
 var pathways := [
  {"title":"BUILD YOUR AUDIENCE","detail":"Perform and promote to attract fans.","tab":"SCENE","action":"PROMOTION"},
  {"title":"RAISE YOUR PROFILE","detail":"Play shows and complete chapters for reputation.","tab":"GIGS","action":"LIVE CIRCUIT"},
  {"title":"EARN YOUR KEEP","detail":"Collect gig fees and chapter rewards for cash.","tab":"GIGS","action":"FIND PAID SHOWS"}
 ]
 var pathway_grid := GridContainer.new()
 pathway_grid.columns = 1 if get_viewport_rect().size.x < 720.0 else 3
 pathway_grid.add_theme_constant_override("h_separation",9)
 pathway_grid.add_theme_constant_override("v_separation",9)
 opportunities.add_child(pathway_grid)
 for pathway in pathways:
  var path_panel := PanelContainer.new()
  path_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  path_panel.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],10))
  pathway_grid.add_child(path_panel)
  var path_stack := VBoxContainer.new()
  path_stack.add_theme_constant_override("separation",6)
  path_panel.add_child(path_stack)
  _label(path_stack,str(pathway["title"]),12,UI.palette(_genre_id())["accent"])
  var path_description := _label(path_stack,str(pathway["detail"]),12,UI.WHITE)
  path_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var jump := UI.themed_button(str(pathway["action"]),_genre_id(),false)
  jump.custom_minimum_size.y = 45
  path_stack.add_child(jump)
  var jump_tab: String = str(pathway["tab"])
  jump.pressed.connect(func() -> void: _switch(jump_tab))

 var upcoming: Dictionary = Calendar.pending(_state())
 if upcoming.is_empty():
  var no_booking := _card("NO GIG BOOKED","Your calendar is clear. Book your next show to start building momentum.")
  _action(no_booking,"EXPLORE VENUES",func() -> void: _switch("GIGS"),true)
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
 var chapter_box := _card("CAREER CHAPTER  /  "+str(chapter.get("title","")),str(chapter.get("description","")))
 if bool(chapter.get("done",false)):
  _label(chapter_box,"ALL OPENING CHAPTERS COMPLETED",14,UI.palette(_genre_id())["accent"])
 else:
  var requirements: Array = chapter.get("requirements",[])
  var complete_count := 0
  for objective in requirements:
   if int(objective.get("current",0)) >= int(objective.get("target",1)):
    complete_count += 1
   Components.objective(chapter_box,objective)
  var ready := bool(chapter.get("ready",false))
  _label(chapter_box,"READY TO CLAIM" if ready else "%d OF %d OBJECTIVES COMPLETE" % [complete_count,requirements.size()],13,UI.palette(_genre_id())["accent"] if ready else UI.MUTED)
  _label(chapter_box,"REWARD  /  £%d  +%d REPUTATION" % [int(chapter.get("reward_cash",0)),int(chapter.get("reward_rep",0))],14,UI.WHITE)
  var claim := UI.themed_button("CLAIM REWARD" if ready else "FINISH OBJECTIVES TO CLAIM",_genre_id(),ready)
  claim.disabled = not ready
  claim.tooltip_text = "Finish the listed objectives first." if not ready else "Claim the reward once. Cash and reputation are saved immediately."
  claim.custom_minimum_size.y = 52
  chapter_box.add_child(claim)
  var chapter_id := str(chapter.get("id",""))
  claim.pressed.connect(func() -> void: _finish(Chapters.claim(_state(),chapter_id),"chapter:"+chapter_id))

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

func _editorial_banner(title: String, subtitle: String, artwork: String, destination: String, action_label: String) -> void:
 # Shared wide-screen feature banner for the three core management workspaces.
 if get_viewport_rect().size.x < 960.0:
  return
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["panel"],14))
 content.add_child(panel)
 var line := HBoxContainer.new()
 line.add_theme_constant_override("separation",18)
 panel.add_child(line)
 var picture := TextureRect.new()
 picture.custom_minimum_size = Vector2(300,176)
 picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var path := "res://Art/Backgrounds/%s/%s.webp" % [_genre_id(),artwork]
 if not ResourceLoader.exists(path):
  path = "res://Art/Backgrounds/shared/%s.webp" % artwork
 if ResourceLoader.exists(path):
  picture.texture = load(path)
 line.add_child(picture)
 var copy := VBoxContainer.new()
 copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 copy.size_flags_stretch_ratio = 1.35
 copy.add_theme_constant_override("separation",10)
 line.add_child(copy)
 _label(copy,"BANDMASTER  /  YOUR CAREER",12,UI.palette(_genre_id())["accent"])
 var heading := _label(copy,title,28,UI.WHITE)
 heading.max_lines_visible = 2
 heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 var body := _label(copy,subtitle,15,UI.MUTED)
 body.max_lines_visible = 3
 var cta := UI.themed_button(action_label,_genre_id(),true)
 cta.icon_end = "arrow-right"
 cta.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 cta.custom_minimum_size.x = 200
 copy.add_child(cta)
 cta.pressed.connect(func() -> void: _switch(destination))

func _gigs() -> void:
 _scene_instrument_strip()
 var venue_picker: VBoxContainer
 var booked: Dictionary = Calendar.pending(_state())
 if booked.is_empty():
  var book_intro := _card("YOUR NEXT SHOW","No gig booked. Browse local venues and choose a promoter deal.")
  _action(book_intro,"FIND A VENUE  ›",func() -> void: _open_venue_browser(),true)
 if not booked.is_empty():
  var due := int(booked.get("day",1)) - _num("tour_day")
  var calendar_box := _card("NEXT SHOW  /  DAY %d" % int(booked.get("day",1)),str(booked.get("venue","Venue"))+"  ·  "+str(booked.get("city","HOME")))
  var journey_id := str(booked.get("travel_plan",""))
  var booked_plan: Dictionary = Tour.preview(_state(),str(booked.get("venue_id","")),journey_id)
  if booked_plan.is_empty():
   _label(calendar_box,"TRAVEL  /  LEGACY BOOKING  ·  STANDARD JOURNEY",12,UI.MUTED)
  else:
   _label(calendar_box,"TRAVEL  /  %s  ·  ROOM £%d" % [str(booked_plan["label"]),int(booked_plan["accommodation_cost"])],12,UI.AMBER)
  var journey_dates: Array = Tour.timeline(_state())
  var date_strip := HBoxContainer.new()
  date_strip.add_theme_constant_override("separation",6)
  calendar_box.add_child(date_strip)
  for step in journey_dates:
   var date_panel := PanelContainer.new()
   date_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   date_panel.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],6))
   date_strip.add_child(date_panel)
   var day_stack := VBoxContainer.new()
   date_panel.add_child(day_stack)
   _label(day_stack,"DAY %d" % int(step["day"]),11,UI.AMBER if bool(step["show"]) else UI.MUTED)
   _label(day_stack,str(step["label"]),11,UI.WHITE)
  if due >= 0 and (due > 0 or str(_state().get("gig_night_phase","arrival")) == "arrival"):
   _action(calendar_box,"TRAVEL & OVERNIGHT OPTIONS  ›",func() -> void: _open_itinerary_editor())
  if due > 0:
   _label(calendar_box,"%d DAYS LEFT TO PREPARE  /  REHEARSE, WRITE OR PROMOTE" % due,14,UI.AMBER)
   _action(calendar_box,"PREPARE FOR THE SHOW  ›",func() -> void: _switch("ACTIONS"),true)
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
   progress.add_theme_constant_override("separation",8)
   calendar_box.add_child(progress)
   var phase_order := ["arrive","soundcheck","stage"]
   var current_phase := phase_order.find(str(scene.get("phase","arrive")))
   for phase_index in range(3):
    var phase_panel := PanelContainer.new()
    phase_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var active_phase := phase_index == current_phase
    var finished_phase := phase_index < current_phase
    var phase_style := UI.style(UI.palette(_genre_id())["alt"] if active_phase or finished_phase else UI.palette(_genre_id())["panel"],9)
    phase_style.border_width_top = 3 if active_phase else 1
    phase_style.border_color = UI.palette(_genre_id())["accent"] if active_phase else UI.palette(_genre_id())["alt"]
    phase_panel.add_theme_stylebox_override("panel",phase_style)
    progress.add_child(phase_panel)
    var phase_column := VBoxContainer.new()
    phase_column.add_theme_constant_override("separation",4)
    phase_panel.add_child(phase_column)
    _label(phase_column,"%02d" % (phase_index+1),11,UI.palette(_genre_id())["accent"] if active_phase else UI.MUTED)
    _label(phase_column,["ARRIVAL","SOUNDCHECK","ON STAGE"][phase_index],14,UI.WHITE if active_phase else UI.MUTED)
    _label(phase_column,"COMPLETE" if finished_phase else ("NOW" if active_phase else "UP NEXT"),11,UI.palette(_genre_id())["accent"] if active_phase or finished_phase else UI.MUTED)
   if str(scene.get("phase","")) == "soundcheck":
    var illness: Dictionary = BackstageIncident.incident(_state())
    if not illness.is_empty():
     var illness_panel := PanelContainer.new()
     var illness_style := UI.style(UI.palette(_genre_id())["alt"],12)
     illness_style.border_color = UI.palette(_genre_id())["secondary"]
     illness_style.border_width_left = 4
     illness_panel.add_theme_stylebox_override("panel",illness_style)
     calendar_box.add_child(illness_panel)
     var illness_column := VBoxContainer.new()
     illness_column.add_theme_constant_override("separation",8)
     illness_panel.add_child(illness_column)
     _label(illness_column,"BACKSTAGE INCIDENT  /  "+str(illness["name"]).to_upper(),15,UI.WHITE)
     _label(illness_column,"Your bassist is throwing up before the show. How do you handle it?",13,UI.MUTED)
     for option in illness["options"]:
      var choice_id := str(option["id"])
      var decision := UI.themed_button(str(option["label"]),_genre_id(),false)
      decision.custom_minimum_size.y = 48
      illness_column.add_child(decision)
      decision.pressed.connect(func() -> void: _resolve_backstage_illness(choice_id))
    _label(calendar_box,"YOUR LIVE SET  /  CHOOSE AN APPROACH",13,UI.AMBER)
    var approach_grid := GridContainer.new()
    approach_grid.columns = 3 if get_viewport_rect().size.x >= 960.0 else 1
    approach_grid.add_theme_constant_override("h_separation",10)
    approach_grid.add_theme_constant_override("v_separation",10)
    calendar_box.add_child(approach_grid)
    for approach_key in ["tight","wild","crowd"]:
     var approach: String = str(approach_key)
     var projection: Dictionary = Gigs.approach_preview(_state(),approach)
     var chosen := str(booked.get("approach","tight")) == approach
     var choice_panel := PanelContainer.new()
     choice_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
     var choice_style := UI.style(UI.palette(_genre_id())["alt"],10)
     choice_style.border_width_top = 3 if chosen else 1
     choice_style.border_color = UI.palette(_genre_id())["accent"] if chosen else UI.palette(_genre_id())["panel"]
     choice_panel.add_theme_stylebox_override("panel",choice_style)
     approach_grid.add_child(choice_panel)
     var choice_column := VBoxContainer.new()
     choice_column.add_theme_constant_override("separation",7)
     choice_panel.add_child(choice_column)
     _label(choice_column,{"tight":"CONTROLLED","wild":"HIGH ENERGY","crowd":"CROWD FIRST"}[approach],12,UI.palette(_genre_id())["accent"])
     var button := UI.themed_button(str(projection["label"]),_genre_id(),chosen)
     button.icon_start = {"tight":"target","wild":"zap","crowd":"users"}[approach]
     button.custom_minimum_size.y = 56
     choice_column.add_child(button)
     button.pressed.connect(func() -> void: _change_gig_strategy(approach))
     _label(choice_column,"SET QUALITY %+d   /   FAN BONUS %+d" % [int(projection["quality_modifier"]),int(projection["fan_bonus"])],12,UI.WHITE)
     _label(choice_column,"TENSION %+d   /   %s" % [int(projection["tension_modifier"]),str(projection["outlook"])],12,UI.MUTED)
    _label(calendar_box,"Outlook uses current readiness, morale and tension. Final outcome also depends on your available lineup.",12,UI.MUTED)
   if bool(scene.get("can_play",false)):
    _label(calendar_box,"SET APPROACH  /  "+str(booked.get("approach","tight")).to_upper(),13,UI.MUTED)
    _action(calendar_box,"TAKE THE STAGE",func() -> void: _show_stage_entry(),true)
   else:
    _action(calendar_box,"CONTINUE THE NIGHT  ›",func() -> void: _advance_gig_night(),true)
  else:
   _label(calendar_box,"THIS BOOKING IS OVERDUE.",14,UI.AMBER)
  _action(calendar_box,"CANCEL BOOKING  ·  UP TO £15",func() -> void: _finish(Calendar.cancel(_state()),"booking_cancel"))
 else:
  _card("BOOK AHEAD","Shows are booked three days in advance. Use those days to prepare, but don't miss the date.")
 _environment_dashboard()
 _editorial_banner("THE LIVE CIRCUIT","Build your reputation one venue at a time. Prepare your musicians, choose a deal and take the stage.","gigs","ACTIONS","PREPARE FOR A SHOW")
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

 venue_picker = _card("FIND YOUR NEXT VENUE","Choose a venue to inspect promoter terms. Locked venues are kept separate.")
 var filter_row := HBoxContainer.new()
 filter_row.add_theme_constant_override("separation",6)
 venue_picker.name = "VenuePickerAnchor"
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
   preserve_venue_scroll = true
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
   var itinerary := _card("TOUR PLANNING  /  "+str(selected_venue["city"]).to_upper(),"Plan the journey before meeting the promoter.")
   _label(itinerary,"VENUE  /  "+str(selected_venue["venue"]),16,UI.WHITE)
   _label(itinerary,"TRAVEL ESTIMATE  £%d   /   POTENTIAL FEE  £%d" % [int(selected_venue["travel"]),int(selected_venue["fee"])],14,UI.AMBER)
   _label(itinerary,"AVAILABLE FUNDS  £%d   /   VAN CONDITION  %d" % [_num("cash"),_num("van_health")],13,UI.MUTED)
   _label(itinerary,"Choose drive-home or overnight travel when meeting the promoter. Accommodation is charged after the show; the fee is not guaranteed profit.",12,UI.MUTED)
   var meeting_venue_id := gig_selected_venue
   var meet := UI.themed_button("MEET THE PROMOTER  ›",_genre_id(),true)
   meet.custom_minimum_size.y = 58
   meet.disabled = not booked.is_empty() or (not line_up_ready and available_count < 1)
   itinerary.add_child(meet)
   meet.pressed.connect(func() -> void: _open_promoter_meeting(meeting_venue_id,line_up_ready,available_count))
 var repairs := _card("KEEP THE VAN MOVING","£45 restores 30 van condition. Hometown gigs are still available when cash is low.")
 _action(repairs,"REPAIR VAN — £45",_repair)

func _open_venue_browser() -> void:
 if not Calendar.pending(_state()).is_empty():
  return
 var overlay := ColorRect.new()
 overlay.name = "VenueBrowserScreen"
 overlay.color = Color("#10131D")
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(overlay)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroll := ScrollContainer.new()
 overlay.add_child(scroll)
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin := MarginContainer.new()
 margin.add_theme_constant_override("margin_left",18)
 margin.add_theme_constant_override("margin_right",18)
 margin.add_theme_constant_override("margin_top",18)
 margin.add_theme_constant_override("margin_bottom",24)
 scroll.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",14)
 margin.add_child(column)
 _label(column,"THE LIVE CIRCUIT  /  VENUE DIRECTORY",13,UI.AMBER)
 _label(column,"WHERE TO PLAY NEXT",29,UI.WHITE)
 _label(column,"Explore venues and inspect their costs before meeting a promoter.",15,UI.MUTED)
 var close := UI.themed_button("BACK TO TOUR PLANNING",_genre_id(),false)
 column.add_child(close)
 close.pressed.connect(func() -> void: overlay.queue_free())
 for locked in [false,true]:
  var items: Array = VenueBrowser.entries(_state(),locked)
  _label(column,"AVAILABLE VENUES" if not locked else "FUTURE AMBITIONS",18,UI.AMBER)
  var grid := GridContainer.new()
  grid.columns = 2 if get_viewport_rect().size.x >= 900.0 else 1
  grid.add_theme_constant_override("h_separation",12)
  grid.add_theme_constant_override("v_separation",12)
  column.add_child(grid)
  for entry in items:
   var venue_id := str(entry["id"])
   var panel := PanelContainer.new()
   panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   panel.add_theme_stylebox_override("panel",UI.style(Color("#242B36"),12))
   grid.add_child(panel)
   var contents := VBoxContainer.new()
   contents.add_theme_constant_override("separation",8)
   panel.add_child(contents)
   var art_path := "res://Art/Backgrounds/%s/gigs.webp" % _genre_id()
   if not ResourceLoader.exists(art_path):
    art_path = "res://Art/Backgrounds/shared/gigs.webp"
   if ResourceLoader.exists(art_path):
    var image := TextureRect.new()
    image.texture = load(art_path)
    image.custom_minimum_size.y = 126
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    contents.add_child(image)
   _label(contents,str(entry["title"]).to_upper()+"  /  "+str(entry["city"]),17,UI.WHITE)
   _label(contents,"POTENTIAL FEE  £%d  ·  TRAVEL £%d" % [int(entry["fee"]),int(entry["travel"])],13,UI.AMBER)
   if locked:
    _label(contents,"NEED %d MORE FANS  ·  %d MORE REPUTATION" % [int(entry["missing_fans"]),int(entry["missing_rep"])],12,UI.MUTED)
   var details := UI.themed_button("VIEW VENUE & COSTS  ›" if not locked else "NOT YET AVAILABLE",_genre_id(),not locked)
   details.custom_minimum_size.y = 52
   details.disabled = locked
   contents.add_child(details)
   details.pressed.connect(func() -> void:
    overlay.queue_free()
    _open_venue_details(venue_id)
   )

func _open_venue_details(venue_id: String) -> void:
 if not Calendar.pending(_state()).is_empty():
  return
 var venue: Dictionary = Gigs.get_venue(venue_id)
 if venue.is_empty():
  return
 var overlay := ColorRect.new()
 overlay.name = "VenueDetailScreen"
 overlay.color = Color("#151924")
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(overlay)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(center)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size.x = minf(760.0,get_viewport_rect().size.x-24.0)
 scroll.custom_minimum_size.y = minf(680.0,get_viewport_rect().size.y-24.0)
 center.add_child(scroll)
 var panel := VBoxContainer.new()
 panel.add_theme_constant_override("separation",14)
 scroll.add_child(panel)
 _label(panel,"VENUE DOSSIER  /  "+str(venue.get("city","HOME")).to_upper(),13,UI.AMBER)
 _label(panel,str(venue.get("venue","THE VENUE")).to_upper(),27,UI.WHITE)
 var art_path := "res://Art/Backgrounds/%s/gigs.webp" % _genre_id()
 if not ResourceLoader.exists(art_path):
  art_path = "res://Art/Backgrounds/shared/gigs.webp"
 if ResourceLoader.exists(art_path):
  var image := TextureRect.new()
  image.texture = load(art_path)
  image.custom_minimum_size.y = 210
  image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  panel.add_child(image)
 _label(panel,"POTENTIAL FEE  £%d  /  TRAVEL £%d" % [int(venue.get("fee",0)),int(venue.get("travel",0))],16,UI.AMBER)
 _label(panel,"CASH £%d  /  VAN CONDITION %d  /  BOOKINGS REQUIRE A PROMOTER DEAL" % [_num("cash"),_num("van_health")],13,UI.MUTED)
 var meet := UI.themed_button("MEET THE PROMOTER",_genre_id(),true)
 meet.custom_minimum_size.y = 58
 panel.add_child(meet)
 meet.pressed.connect(func() -> void:
  overlay.queue_free()
  var roster: Array = save_data.get("band",{}).get("members",[])
  var active := 0
  var drummer := false
  for member in roster:
   if member is Dictionary and str(member.get("life_status","active")) == "active":
    active += 1
    if str(member.get("role","")).to_lower().contains("drum"):
     drummer = true
  _open_promoter_meeting(venue_id,active >= 2 and drummer,active)
 )
 var back := UI.themed_button("BACK TO VENUES",_genre_id(),false)
 panel.add_child(back)
 back.pressed.connect(func() -> void:
  overlay.queue_free()
  _open_venue_browser()
 )

func _open_itinerary_editor() -> void:
 var state: Dictionary = _state()
 var booking: Dictionary = Calendar.pending(state)
 if booking.is_empty():
  return
 var venue_id := str(booking.get("venue_id",""))
 var overlay := ColorRect.new()
 overlay.name = "TourItineraryEditor"
 overlay.color = Color("#141922")
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(overlay)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroll := ScrollContainer.new()
 overlay.add_child(scroll)
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin := MarginContainer.new()
 margin.add_theme_constant_override("margin_left",18)
 margin.add_theme_constant_override("margin_right",18)
 margin.add_theme_constant_override("margin_top",18)
 margin.add_theme_constant_override("margin_bottom",24)
 scroll.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",13)
 margin.add_child(column)
 _label(column,"THE TOUR DESK  /  DAY %d" % int(booking.get("day",0)),13,UI.AMBER)
 _label(column,str(booking.get("venue","THE SHOW")).to_upper(),26,UI.WHITE)
 _label(column,"FROM HOMETOWN TO "+str(booking.get("city","VENUE"))+"  /  FICTIONAL GAME COSTS, NOT REAL ROUTE DISTANCES",13,UI.MUTED)
 _label(column,"CASH £%d  /  VAN %d" % [int(state.get("cash",0)),int(state.get("van_health",0))],15,UI.AMBER)
 var current := str(booking.get("travel_plan",""))
 for option in Tour.choices(state,venue_id):
  var id := str(option["id"])
  var block := PanelContainer.new()
  block.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],12))
  column.add_child(block)
  var details := VBoxContainer.new()
  details.add_theme_constant_override("separation",7)
  block.add_child(details)
  _label(details,str(option["label"])+("  /  SELECTED" if id == current else ""),17,UI.WHITE)
  _label(details,str(option["description"]),14,UI.MUTED)
  _label(details,"TRAVEL £%d  +  ROOM £%d  =  £%d" % [int(option["travel_cost"]),int(option["accommodation_cost"]),int(option["total_cost"])],15,UI.AMBER)
  _label(details,"SET QUALITY %+d  /  MORALE %+d  /  MEMBER FATIGUE %+d  /  VAN WEAR %d" % [int(option["quality_bonus"]),int(option["morale_delta"]),int(option["fatigue_delta"]),int(option["van_wear"])],13,UI.MUTED)
  var choose := UI.themed_button("CURRENT PLAN" if id == current else "CHOOSE THIS JOURNEY",_genre_id(),id != current)
  choose.custom_minimum_size.y = 52
  choose.disabled = id == current or not bool(Tour.validate(state,venue_id,id,bool(booking.get("session_drummer",false))).get("ok",false))
  details.add_child(choose)
  choose.pressed.connect(func() -> void:
   var changed: Dictionary = Calendar.replan(_state(),id)
   if bool(changed.get("ok",false)):
    _apply(changed["state"])
    _save()
   message = str(changed.get("message","Journey unavailable."))
   overlay.queue_free()
   _render()
  )
 _label(column,"Room charges settle once after the gig. You can change plans until venue arrival; ensure you can still afford the journey on show day.",13,UI.MUTED)
 _action(column,"BACK TO GIGS",func() -> void: overlay.queue_free())

func _open_promoter_meeting(venue_id: String, line_up_ready: bool, available_count: int) -> void:
 if not Calendar.pending(_state()).is_empty():
  return
 var venue: Dictionary = Gigs.get_venue(venue_id)
 if venue.is_empty():
  return
 var overlay := ColorRect.new()
 overlay.name = "PromoterMeeting"
 overlay.color = Color(0.025,0.035,0.055,0.96)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(overlay)
 var scroll := ScrollContainer.new()
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(scroll)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.add_child(center)
 var desk := PanelContainer.new()
 desk.custom_minimum_size.x = minf(get_viewport_rect().size.x-32.0,760.0)
 desk.add_theme_stylebox_override("panel",UI.style(UI.PANEL,16))
 center.add_child(desk)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",12)
 desk.add_child(column)
 _label(column,"PROMOTER'S OFFICE  /  CONTRACT NEGOTIATIONS",13,UI.AMBER)
 _label(column,str(venue.get("venue","THE VENUE")).to_upper(),25,UI.WHITE)
 _label(column,str(venue.get("city","HOME"))+"  /  TRAVEL £%d  /  POTENTIAL FEE £%d" % [int(venue.get("travel",0)),int(venue.get("fee",0))],14,UI.MUTED)
 var portrait_path := "res://Art/Backgrounds/%s/backstage.webp" % _genre_id()
 if not ResourceLoader.exists(portrait_path):
  portrait_path = "res://Art/Backgrounds/shared/backstage.webp"
 if ResourceLoader.exists(portrait_path):
  var meeting_art := TextureRect.new()
  meeting_art.texture = load(portrait_path)
  meeting_art.custom_minimum_size.y = 170
  meeting_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  meeting_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  column.add_child(meeting_art)
 _label(column,"THE BOOKER  /  Let's see what deal makes sense for both of us.",17,UI.WHITE)
 if Tour.preview(_state(),venue_id,selected_tour_plan).is_empty():
  selected_tour_plan = Tour.DRIVE
 _label(column,"JOURNEY PLAN  /  CHOOSE BEFORE SIGNING",13,UI.AMBER)
 for journey_option in Tour.choices(_state(),venue_id):
  var plan_id := str(journey_option["id"])
  var selected := selected_tour_plan == plan_id
  var travel_button := UI.themed_button(("●  " if selected else "")+str(journey_option["label"]),_genre_id(),selected)
  travel_button.custom_minimum_size.y = 48
  travel_button.disabled = not bool(journey_option["available"])
  column.add_child(travel_button)
  _label(column,"TRAVEL £%d  /  ROOM £%d  /  TOTAL £%d  /  SET %+d  /  FATIGUE %+d" % [int(journey_option["travel_cost"]),int(journey_option["accommodation_cost"]),int(journey_option["total_cost"]),int(journey_option["quality_bonus"]),int(journey_option["fatigue_delta"])],12,UI.MUTED)
  travel_button.pressed.connect(func() -> void:
   selected_tour_plan = plan_id
   overlay.queue_free()
   _open_promoter_meeting(venue_id,line_up_ready,available_count)
  )
 var plan_validation: Dictionary = Tour.validate(_state(),venue_id,selected_tour_plan)
 if not bool(plan_validation.get("ok",false)):
  _label(column,str(plan_validation.get("message","Journey unavailable.")),13,UI.AMBER)
 for offer_id in ["standard","guarantee","guestlist"]:
  var proposal: String = offer_id
  var terms: Dictionary = Promoter.OFFERS[proposal]
  var option := UI.themed_button(str(terms["label"]),_genre_id(),proposal=="standard")
  option.custom_minimum_size.y = 56
  option.disabled = not line_up_ready or not bool(plan_validation.get("ok",false))
  column.add_child(option)
  _label(column,str(terms["description"]),12,UI.MUTED)
  option.pressed.connect(func() -> void:
   overlay.queue_free()
   _finish(Promoter.book(_state(),venue_id,proposal,false,selected_tour_plan))
  )
 if not line_up_ready and available_count >= 1:
  var session := UI.themed_button("HIRE A SESSION DRUMMER  /  £25",_genre_id(),true)
  session.disabled = not bool(Tour.validate(_state(),venue_id,selected_tour_plan,true).get("ok",false))
  column.add_child(session)
  session.pressed.connect(func() -> void:
   overlay.queue_free()
   _finish(Promoter.book(_state(),venue_id,"standard",true,selected_tour_plan))
  )
 _action(column,"BACK TO THE TOUR PLANNER",func() -> void: overlay.queue_free())

func _scroll_to_venue_picker() -> void:
 # Scroll after the rendered content has settled; ensure_control_visible on a
 # newly created control may run before container layout is final.
 if not is_instance_valid(career_scroll):
  return
 var target: Control = find_child("VenuePickerAnchor",true,false) as Control
 if target != null:
  career_scroll.call_deferred("ensure_control_visible",target)

func _gear() -> void:
 var owned: Array = _extra().get("owned_equipment",[])
 var members: Array = save_data.get("band",{}).get("members",[])
 var heading := _card("THE MUSIC SHOP","Choose an item, review its cost and buy when ready.")
 _progress(heading,"READINESS",_num("readiness"))
 _label(heading,"%d OWNED  /  %d AVAILABLE  /  £%d CASH" % [owned.size(),Gear.ITEMS.size()-owned.size(),_num("cash")],13,UI.AMBER)
 var full_content := content
 var inventory: VBoxContainer
 var detail_column: VBoxContainer
 var desktop_shop := get_viewport_rect().size.x >= 680.0
 if desktop_shop:
  var split := HBoxContainer.new()
  split.add_theme_constant_override("separation",12)
  full_content.add_child(split)
  var catalogue_column := VBoxContainer.new()
  catalogue_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  split.add_child(catalogue_column)
  detail_column = VBoxContainer.new()
  detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  split.add_child(detail_column)
  content = catalogue_column
 inventory = _card("EQUIPMENT CATALOGUE","Select equipment to inspect its benefits and cost.")
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
 if desktop_shop:
  content = detail_column
 var detail: VBoxContainer
 for item in Gear.ITEMS:
  if str(item["id"]) != selected_gear_item:
   continue
  detail = _card(str(item["name"]),str(item["description"]))
  var icon_name: String = str({"amp":"guitar","mics":"mic","pedals":"sliders-horizontal","drums":"sliders-horizontal","pa":"mic"}.get(selected_gear_item,"guitar"))
  var icon_path := "res://Art/UI/Icons/%s.svg" % icon_name
  if ResourceLoader.exists(icon_path):
   var gear_icon := TextureRect.new()
   gear_icon.name = "GearDossierIcon"
   gear_icon.texture = load(icon_path)
   gear_icon.custom_minimum_size = Vector2(48,48)
   gear_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   gear_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
   detail.add_child(gear_icon)
  _label(detail,str(item["type"]).to_upper()+"  /  +%d READINESS ON PURCHASE" % int(item["readiness"]),13,UI.AMBER)
  _label(detail,"ASKING PRICE  /  £%d" % int(item["price"]),15,UI.WHITE)
  if owned.has(selected_gear_item):
   var gear_entry: Dictionary = Gear.record(_state(),selected_gear_item)
   var gear_condition := int(gear_entry.get("condition",-1))
   _label(detail,"CONDITION  /  "+("UNKNOWN — SERVICE TO ASSESS" if gear_condition < 0 else "%d / 100" % gear_condition),14,UI.AMBER)
   _label(detail,"HISTORY  /  "+str(gear_entry.get("provenance","Unrecorded")),13,UI.MUTED)
   _label(detail,"REPAIRS  /  %d" % int(gear_entry.get("repairs",0)),12,UI.MUTED)
   var holder_index := Gear.holder_index(_state(),gear_entry)
   if holder_index >= 0 and holder_index < members.size() and members[holder_index] is Dictionary:
    _label(detail,"IN USE BY  /  "+str(members[holder_index].get("name","Musician")),13,UI.WHITE)
   else:
    _label(detail,"UNASSIGNED — CHOOSE A BANDMATE BELOW",13,UI.MUTED)
   var service := UI.themed_button("SERVICE & ASSESS  ·  £%d  /  1 DAY" % Gear.SERVICE_COST,_genre_id(),true)
   service.icon_start = "wrench"
   service.custom_minimum_size.y = 54
   service.disabled = _num("cash") < Gear.SERVICE_COST or gear_condition >= 100
   detail.add_child(service)
   var service_key := selected_gear_item
   service.pressed.connect(func() -> void: _service_gear(service_key))
   for member_index in range(members.size()):
    var candidate = members[member_index]
    if not candidate is Dictionary or str(candidate.get("life_status","active")) != "active" or not Gear.compatible(selected_gear_item,candidate):
     continue
    if holder_index == member_index:
     continue
    var assign := UI.themed_button("ASSIGN TO  "+str(candidate.get("name","MUSICIAN")).to_upper()+"  ·  FREE",_genre_id(),false)
    assign.custom_minimum_size.y = 50
    detail.add_child(assign)
    var assign_key := selected_gear_item
    var chosen_index := member_index
    assign.pressed.connect(func() -> void: _assign_gear(assign_key,chosen_index))
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
 if not desktop_shop:
  var details_parent := detail.get_parent() if is_instance_valid(detail) else null
  if details_parent != null:
   details_parent.move_child(detail,mini(inventory.get_index(),details_parent.get_child_count()-1))
 content = full_content
 var garage := _card("THE BAND'S EQUIPMENT  /  ROAD CASES","Assign equipment to a musician, track wear and service it before a difficult show.")
 var cases := GridContainer.new()
 cases.columns = 2 if get_viewport_rect().size.x >= 960.0 else 1
 cases.add_theme_constant_override("h_separation",10)
 cases.add_theme_constant_override("v_separation",10)
 garage.add_child(cases)
 for member_index in range(members.size()):
  var member = members[member_index]
  if not member is Dictionary:
   continue
  var person_box := PanelContainer.new()
  person_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  person_box.add_theme_stylebox_override("panel",UI.style(Color("#2C2926"),10))
  cases.add_child(person_box)
  var dossier := VBoxContainer.new()
  dossier.add_theme_constant_override("separation",6)
  person_box.add_child(dossier)
  _label(dossier,str(member.get("name","MUSICIAN")).to_upper()+"  /  "+str(member.get("role","")).to_upper(),15,UI.AMBER)
  var matched := 0
  for item in Gear.ITEMS:
   var item_id := str(item["id"])
   if not owned.has(item_id):
    continue
   var entry: Dictionary = Gear.record(_state(),item_id)
   if Gear.holder_index(_state(),entry) != member_index:
    continue
   matched += 1
   var condition := int(entry.get("condition",-1))
   _label(dossier,"IN CASE  /  "+str(item["name"]),13,UI.WHITE)
   _label(dossier,"CONDITION  /  "+("NOT ASSESSED" if condition < 0 else "%d / 100" % condition),12,UI.MUTED)
   _label(dossier,str(entry.get("provenance","History unrecorded")),12,UI.MUTED)
  if matched == 0:
   _label(dossier,"No relevant purchased gear recorded. Current personal equipment is untracked.",12,UI.MUTED)
 var unassigned := PackedStringArray()
 for item_id in owned:
  if Gear.holder_index(_state(),Gear.record(_state(),str(item_id))) < 0:
   unassigned.append(str(Gear.item_for(str(item_id)).get("name",item_id)))
 if not unassigned.is_empty():
  _label(garage,"IN THE SHARED ROAD CASE  /  "+", ".join(unassigned),13,UI.WHITE)
 _label(garage,"Shared purchases are shown against relevant musicians once assigned. Older purchases keep unknown condition until serviced; personal equipment is not invented.",12,UI.MUTED)

func _band() -> void:
 _band_situations()
 _life_situations()
 _editorial_banner("THE PEOPLE BEHIND THE MUSIC","Manage the line-up, keep relationships healthy and develop the sound of your band.","band","ACTIONS","BOOK REHEARSAL")
 var band_data: Dictionary = save_data.get("band",{})
 var members: Array = band_data.get("members",[])
 var pulse: Dictionary = BandPulse.overview(members)
 var pairs: Array = Chemistry.connections(members,save_data.get("relationships",{}))
 var briefing_panel: VBoxContainer
 if get_viewport_rect().size.x >= 960.0 and not members.is_empty():
  briefing_panel = _card("BAND MANAGEMENT  /  LIVE BRIEFING","Keep the band ready, connected and able to perform.")
  var briefing_row := HBoxContainer.new()
  briefing_row.add_theme_constant_override("separation",10)
  briefing_panel.add_child(briefing_row)
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
  briefing_panel.add_child(brief_actions)
  var rehearse := UI.themed_button("OPEN STUDIO",_genre_id(),true)
  rehearse.icon_start = "music"
  brief_actions.add_child(rehearse)
  rehearse.pressed.connect(func() -> void: _switch("ACTIONS"))
  var gigs := UI.themed_button("GIG SCHEDULE",_genre_id(),false)
  gigs.icon_start = "calendar-days"
  brief_actions.add_child(gigs)
  gigs.pressed.connect(func() -> void: _switch("GIGS"))
  if int(pulse.get("exhausted",0)) > 0:
   _label(briefing_panel,"%d BANDMATE(S) NEED RECOVERY BEFORE THE NEXT SHOW" % int(pulse["exhausted"]),13,UI.palette(_genre_id())["secondary"])

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
  if bool(conversation.get("answered",false)):
   _label(dialogue,"YOU: "+str(conversation.get("player_reply","")),13,UI.palette(_genre_id())["accent"])
   _label(dialogue,str(conversation.get("response_text","")),15,UI.WHITE)
  elif speaker_index >= 0:
   var replies := BandReplies.options(_state(),speaker_index)
   if replies.is_empty():
    _label(dialogue,"YOU'VE ALREADY RESPONDED TO THIS MUSICIAN TODAY.",12,UI.MUTED)
   else:
    _label(dialogue,"YOUR REPLY  /  FREE CONVERSATION",12,UI.palette(_genre_id())["accent"])
    var reply_grid := GridContainer.new()
    reply_grid.columns = 1 if get_viewport_rect().size.x < 720.0 else 3
    reply_grid.add_theme_constant_override("h_separation",8)
    reply_grid.add_theme_constant_override("v_separation",8)
    dialogue.add_child(reply_grid)
    for reply in replies:
     var reply_id := str(reply["id"])
     var reply_button := UI.themed_button(str(reply["label"]),_genre_id(),false)
     reply_button.custom_minimum_size.y = 52
     reply_grid.add_child(reply_button)
     var target_index := speaker_index
     reply_button.pressed.connect(func() -> void: _reply_to_musician(target_index,reply_id))
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
  if landscape_roster:
   # Keep roster cards top-aligned instead of stretching their content over a tall grid row.
   box.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
   var member_header := HBoxContainer.new()
   member_header.add_theme_constant_override("separation",8)
   box.add_child(member_header)
   var status_label := _label(member_header,"AVAILABLE" if status == "active" else status.to_upper(),11,UI.palette(_genre_id())["accent"] if status == "active" else UI.palette(_genre_id())["secondary"])
   status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
   var personnel_label := _label(member_header,"MEMBER %02d" % (index+1),11,UI.MUTED)
   personnel_label.autowrap_mode = TextServer.AUTOWRAP_OFF
   personnel_label.size_flags_horizontal = Control.SIZE_SHRINK_END
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
   var relationship := PanelContainer.new()
   relationship.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],10))
   connection_card.add_child(relationship)
   var pair_body := VBoxContainer.new()
   pair_body.add_theme_constant_override("separation",5)
   relationship.add_child(pair_body)
   var bond_value := int(bond["value"])
   var relationship_status := "CONNECTED" if bond_value >= 70 else ("STRAINED" if bond_value < 40 else "STEADY")
   var colour := Color("#68BC95") if bond_value >= 70 else (Color("#EA777C") if bond_value < 40 else Color("#F0B44D"))
   _label(pair_body,str(bond["first"])+" + "+str(bond["second"])+"  /  "+relationship_status,15,colour)
   if bond_value < 40:
    _label(pair_body,"The connection needs attention before tension spills into rehearsal.",12,UI.MUTED)
    _action(pair_body,"SPEND TIME TOGETHER  ›",func() -> void:
     action_view = "HANG OUT"
     _switch("ACTIONS")
    )
   elif bond_value >= 70:
    _label(pair_body,"A reliable creative partnership. Keep giving both musicians a voice.",12,UI.MUTED)
   else:
    _label(pair_body,"A steady partnership. Shared experiences could bring them closer.",12,UI.MUTED)

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
 if is_instance_valid(briefing_panel):
  var briefing_parent := briefing_panel.get_parent()
  if briefing_parent != null:
   briefing_parent.move_child(briefing_panel,briefing_parent.get_child_count()-1)

func _reply_to_musician(index: int, reply_id: String) -> void:
 dialogue_serial += 1
 _cancel_dialogue_request()
 var result := BandReplies.respond(_state(),index,reply_id)
 if not bool(result.get("ok",false)):
  message = str(result.get("message","Reply unavailable"))
  _render()
  return
 _apply(result["state"])
 message = str(result["message"])
 _save()
 preserve_roster_scroll = true
 _render()

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
 # Present a real pair's disagreement as one actionable scene rather than
 # scattering multiple generic choice buttons through the roster.
 for incident in Drama.pair_pending(_state()):
  var case_id: String = str(incident["id"])
  var box := _card("BACKSTAGE  /  "+str(incident["title"]),str(incident["intro"]))
  _label(box,"%s  +  %s    /    PAIR TRUST %d" % [str(incident["first"]),str(incident["second"]),int(incident["trust"])],13,UI.palette(_genre_id())["accent"])
  var launcher := UI.themed_button("HEAR BOTH SIDES  /  1 DAY",_genre_id(),true)
  launcher.name = "PairIncidentOpen"
  launcher.custom_minimum_size.y = 54
  if launcher is WoldButton:
   launcher.icon_start = "users"
  box.add_child(launcher)
  launcher.pressed.connect(func() -> void: _open_pair_incident(case_id,launcher))
 for event_id in Drama.pending(_state()):
  var id: String = str(event_id)
  var definition: Dictionary = Drama.EVENTS[id]
  var box := _card(str(definition["title"]),str(definition["intro"]))
  for option in definition["choices"]:
   var choice: String = str(option["id"])
   _action(box,str(option["label"]),func() -> void: _finish(Drama.resolve(_state(),id,choice)),choice == str(definition["choices"][0]["id"]))

func _open_pair_incident(case_id: String, launcher: BaseButton) -> void:
 var incident: Dictionary = {}
 for available in Drama.pair_pending(_state()):
  if str(available.get("id","")) == case_id:
   incident = available
   break
 if incident.is_empty():
  message = "That conversation is no longer available."
  _render()
  return
 var art_path := "res://Art/Backgrounds/%s/band.webp" % _genre_id()
 if not ResourceLoader.exists(art_path):
  art_path = "res://Art/Backgrounds/shared/band.webp"
 var sheet: Dictionary = SceneSheet.build(self,str(incident["title"]),str(incident["intro"]),art_path,_genre_id())
 var body: VBoxContainer = sheet["body"]
 var pair_row := HBoxContainer.new()
 pair_row.name = "PairIncidentIdentity"
 pair_row.add_theme_constant_override("separation",10)
 body.add_child(pair_row)
 body.move_child(pair_row,1)
 var icon_path := "res://Art/UI/Icons/users.svg"
 if ResourceLoader.exists(icon_path):
  var icon := TextureRect.new()
  icon.texture = load(icon_path)
  icon.custom_minimum_size = Vector2(34,34)
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  pair_row.add_child(icon)
 var pair_caption := Label.new()
 pair_caption.text = "%s  +  %s  /  TRUST %d" % [str(incident["first"]),str(incident["second"]),int(incident["trust"])]
 pair_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 pair_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 pair_caption.add_theme_color_override("font_color",UI.AMBER)
 pair_row.add_child(pair_caption)
 var actions: VBoxContainer = sheet["actions"]
 var committed := [false]
 var first_choice: BaseButton
 for option in incident["choices"]:
  var choice_id := str(option["id"])
  var consequence := Label.new()
  consequence.text = "TRUST %d  ·  TENSION %d  ·  READINESS %d  /  1 DAY" % [int(option.get("trust",0)),int(option.get("tension",0)),int(option.get("readiness",0))]
  consequence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  consequence.add_theme_font_size_override("font_size",12)
  consequence.add_theme_color_override("font_color",UI.MUTED)
  actions.add_child(consequence)
  var button := SceneSheet.add_choice(sheet,str(option["label"]),func() -> void:
   if committed[0]:
    return
   committed[0] = true
   SceneSheet.dismiss(sheet)
   _finish(Drama.resolve_pair(_state(),case_id,choice_id),"band:pair")
  ,first_choice == null,_genre_id())
  button.name = "PairIncidentChoice"
  if first_choice == null:
   first_choice = button
 var cancel := SceneSheet.add_choice(sheet,"BACK TO THE BAND",func() -> void:
  if committed[0]:
   return
  SceneSheet.dismiss(sheet)
  if is_instance_valid(launcher):
   launcher.call_deferred("grab_focus")
 ,false,_genre_id())
 cancel.name = "PairIncidentCancel"
 if is_instance_valid(first_choice):
  first_choice.call_deferred("grab_focus")

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
 _scene_instrument_strip()
 if action_view != "JAM":
  _editorial_banner("THE CREATIVE STUDIO","Find your sound through rehearsal, songwriting and time spent together.","actions","BAND","VIEW YOUR MUSICIANS")
 var mode_titles := {"JAM":"THE WRITING ROOM","HANG OUT":"AFTER HOURS","PROMOTE":"MAKE SOME NOISE"}
 var mode_descriptions := {"JAM":"Build a song from someone's idea.","HANG OUT":"Be people together, not just bandmates.","PROMOTE":"Get your name around town."}
 var switches := _card("CHOOSE YOUR DAY","Select an activity. Each commitment moves the band's story forward.")
 var navigation := HBoxContainer.new()
 navigation.add_theme_constant_override("separation",8)
 switches.add_child(navigation)
 for mode in ["JAM","HANG OUT","PROMOTE"]:
  var destination := str(mode)
  var selected := action_view == destination
  var button := UI.themed_button({"JAM":"WRITE & REHEARSE","HANG OUT":"BAND LIFE","PROMOTE":"PROMOTION"}.get(destination,destination),_genre_id(),selected)
  button.icon_start = {"JAM":"music","HANG OUT":"users","PROMOTE":"megaphone"}.get(destination,"arrow-right")
  button.custom_minimum_size.y = 58
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.tooltip_text = str(mode_descriptions.get(destination,""))
  button.add_theme_font_size_override("font_size",15 if get_viewport_rect().size.x >= 960.0 else 12)
  navigation.add_child(button)
  button.pressed.connect(func() -> void:
   action_view = destination
   _render()
  )
 # Desktop: a management workspace, not one long stack of cards.
 # Preserve the mobile single-column flow and existing action callbacks.
 if action_view != "JAM":
  _environment_dashboard()
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
 var scene_card: VBoxContainer
 if action_view != "JAM":
  scene_card = _card(str(mode_titles.get(action_view,"THE STUDIO")),str(mode_descriptions.get(action_view,"")))
 var image_path := "res://Art/Backgrounds/%s/studio.webp" % _genre_id()
 if action_view == "HANG OUT":
  image_path = "res://Art/Backgrounds/%s/backstage.webp" % _genre_id()
 elif action_view == "PROMOTE":
  image_path = "res://Art/Backgrounds/%s/promotion.webp" % _genre_id()
 if not ResourceLoader.exists(image_path):
  var shared_name := "studio" if action_view == "JAM" else ("backstage" if action_view == "HANG OUT" else "promotion")
  image_path = "res://Art/Backgrounds/shared/%s.webp" % shared_name
 if ResourceLoader.exists(image_path) and is_instance_valid(scene_card):
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
 var songbook_panel: VBoxContainer
 if action_view == "JAM":
  var finished_songs: Array = Songbook.entries(_state())
  songbook_panel = _card("YOUR SONGBOOK  /  %d ORIGINALS" % finished_songs.size(),"The set you are building. Song quality reflects how developed each composition is.")
  if finished_songs.is_empty():
   _label(songbook_panel,"NO COMPLETED SONGS YET  /  START A JAM SESSION BELOW.",14,UI.MUTED)
  else:
   var song_list_scroll := ScrollContainer.new()
   song_list_scroll.custom_minimum_size.y = minf(330.0,84.0*finished_songs.size())
   song_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
   songbook_panel.add_child(song_list_scroll)
   var song_list := VBoxContainer.new()
   song_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   song_list.add_theme_constant_override("separation",7)
   song_list_scroll.add_child(song_list)
   for track in finished_songs:
    var track_panel := PanelContainer.new()
    track_panel.add_theme_stylebox_override("panel",UI.style(UI.palette(_genre_id())["alt"],9))
    song_list.add_child(track_panel)
    var track_row := HBoxContainer.new()
    track_row.add_theme_constant_override("separation",10)
    track_panel.add_child(track_row)
    var track_number := _label(track_row,"%02d" % int(track["number"]),18,UI.palette(_genre_id())["accent"])
    track_number.custom_minimum_size.x = 34
    var track_info := VBoxContainer.new()
    track_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    track_info.add_theme_constant_override("separation",4)
    track_row.add_child(track_info)
    var track_title := _label(track_info,str(track["title"]),16,UI.WHITE)
    track_title.max_lines_visible = 2
    _label(track_info,str(track["writer"])+"  /  "+str(track["arrangement"]),12,UI.MUTED)
    _label(track_info,"LIVE RECEPTION: "+str(track["reception"]),11,UI.MUTED)
    var quality_stack := VBoxContainer.new()
    quality_stack.custom_minimum_size.x = 120 if wide_workspace else 80
    track_row.add_child(quality_stack)
    _label(quality_stack,"%d / 100" % int(track["quality"]),17,UI.palette(_genre_id())["accent"])
    _label(quality_stack,str(track["verdict"]),11,UI.MUTED)
  var draft: Dictionary = _extra().get("current_song_draft",{})
  var workshop := _card("SONGWRITING  /  "+("START A NEW SONG" if draft.is_empty() else "DEVELOP YOUR SONG"),"Choose the sound, arrangement, title and session leader. Every session takes one day.")
  var writing_skin := UI.style(Color("#332820"),16)
  writing_skin.border_color = Color("#B99563")
  writing_skin.border_width_top = 4
  writing_skin.border_width_bottom = 2
  writing_skin.set_content_margin_all(16)
  var writing_frame := workshop.get_parent() as PanelContainer
  if writing_frame != null:
   writing_frame.add_theme_stylebox_override("panel",writing_skin)
  _label(workshop,"ON THE DESK  /  DRAFT PAPER  ·  SETLIST  ·  STUDIO NOTES",12,Color("#D6BE92"))
  var studio: Dictionary = SongStudio.view(_state())
  if wide_workspace:
   var session_strip := HBoxContainer.new()
   session_strip.add_theme_constant_override("separation",8)
   workshop.add_child(session_strip)
   for session_index in range(3):
    var session_card := PanelContainer.new()
    session_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var is_done := session_index < int(studio.get("completed",0))
    var is_current := session_index == int(studio.get("completed",0))
    var session_style := UI.style(UI.palette(_genre_id())["alt"] if is_done or is_current else UI.palette(_genre_id())["panel"],10)
    session_style.border_width_top = 3 if is_current else 1
    session_style.border_color = UI.palette(_genre_id())["accent"] if is_current else UI.palette(_genre_id())["alt"]
    session_card.add_theme_stylebox_override("panel",session_style)
    session_strip.add_child(session_card)
    var session_copy := VBoxContainer.new()
    session_copy.add_theme_constant_override("separation",3)
    session_card.add_child(session_copy)
    _label(session_copy,"SESSION %02d" % (session_index+1),11,UI.MUTED)
    _label(session_copy,["FIND THE IDEA","SHAPE THE SONG","RECORD A FINISH"][session_index],14,UI.WHITE if is_done or is_current else UI.MUTED)
    _label(session_copy,"COMPLETED" if is_done else ("IN PROGRESS" if is_current else "UP NEXT"),11,UI.palette(_genre_id())["accent"] if is_done or is_current else UI.MUTED)
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
  var preview_style := UI.style(Color("#EFE3C9"),8)
  preview_style.border_color = Color("#B59C73")
  preview_style.set_content_margin_all(16)
  preview_style.border_width_left = 4
  preview_panel.add_theme_stylebox_override("panel",preview_style)
  workshop.add_child(preview_panel)
  var preview := VBoxContainer.new()
  preview.add_theme_constant_override("separation",6)
  preview_panel.add_child(preview)
  _label(preview,"WORKING SONGSHEET  /  LIVE DRAFT",12,Color("#83603E"))
  _label(preview,"Pencil changes are free. Recording a session uses one day.",12,Color("#665F53"))
  var preview_heading := _label(preview,"",20,Color("#241E18"))
  var preview_identity := _label(preview,"",13,Color("#8E512F"))
  var preview_arrangement := _label(preview,"",13,Color("#595044"))
  var preview_leader := _label(preview,"",12,Color("#595044"))
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
  var title_entry := LineEdit.new()
  title_entry.name = "WorkingTitleInput"
  title_entry.placeholder_text = "Give your song an original name"
  title_entry.max_length = 48
  title_entry.text = str(draft.get("title",titles.get_item_text(titles.selected) if titles.selected >= 0 else ""))
  title_entry.custom_minimum_size.y = 52
  workshop.add_child(title_entry)
  _label(workshop,"YOUR TITLE  /  TYPE OR EDIT IT. THE NAME IS YOURS.",12,Color("#D6BE92"))
  titles.item_selected.connect(func(index: int) -> void:
   title_entry.text = titles.get_item_text(index)
  )
  var jam := UI.themed_button("COMMIT TO THIS SONG  /  1 DAY",_genre_id(),true)
  jam.custom_minimum_size.y = 54
  jam.disabled = indices.is_empty() or not SongLab.can_commit(ideas,forms,titles,leads)
  workshop.add_child(jam)
  jam.pressed.connect(func() -> void:
   _finish(Practice.compose(_state(),ideas.get_item_text(ideas.selected),forms.get_item_text(forms.selected),title_entry.text,indices[leads.selected]))
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
 if action_view == "JAM" and is_instance_valid(songbook_panel) and songbook_panel.get_parent() == content:
  content.move_child(songbook_panel,content.get_child_count()-1)
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

func _scrapbook_gig_ticket(parent: Node, moment: Dictionary) -> void:
 # A visual keepsake grounded only in journal facts; no fabricated performance data.
 var ticket := PanelContainer.new()
 var paper_style := UI.style(UI.palette(_genre_id())["alt"],12)
 paper_style.border_width_left = 5
 paper_style.border_color = UI.palette(_genre_id())["accent"]
 ticket.add_theme_stylebox_override("panel",paper_style)
 parent.add_child(ticket)
 var ticket_row := HBoxContainer.new()
 ticket_row.add_theme_constant_override("separation",12)
 ticket.add_child(ticket_row)
 var image_path := "res://Art/Backgrounds/%s/gigs.webp" % _genre_id()
 if not ResourceLoader.exists(image_path):
  image_path = "res://Art/Backgrounds/shared/gigs.webp"
 if ResourceLoader.exists(image_path):
  var artwork := TextureRect.new()
  artwork.texture = load(image_path)
  artwork.custom_minimum_size = Vector2(116,108)
  artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
  ticket_row.add_child(artwork)
 var copy := VBoxContainer.new()
 copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 copy.add_theme_constant_override("separation",5)
 ticket_row.add_child(copy)
 _label(copy,"LIVE TICKET  /  DAY %d" % int(moment.get("day",1)),12,UI.palette(_genre_id())["accent"])
 var heading := _label(copy,str(moment.get("title","A NIGHT TO REMEMBER")),17,UI.WHITE)
 heading.max_lines_visible = 2
 _label(copy,str(moment.get("text","")),13,UI.MUTED)

func _scene() -> void:
 var scene_modes := _card("YOUR SCENE  /  CHOOSE A FOCUS","Build your following or revisit the band's story.")
 var scene_nav := HBoxContainer.new()
 scene_nav.add_theme_constant_override("separation",8)
 scene_modes.add_child(scene_nav)
 for section in [{"id":"PROMOTE","label":"PROMOTE"},{"id":"HISTORY","label":"SCRAPBOOK"}]:
  var id: String = str(section["id"])
  var button := UI.themed_button(str(section["label"]),_genre_id(),scene_view == id)
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.custom_minimum_size.y = 52
  scene_nav.add_child(button)
  button.pressed.connect(func() -> void:
   scene_view = id
   _render()
  )
 if scene_view == "HISTORY":
  _scene_scrapbook()
  return
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
 _recording_studio()

func _scene_scrapbook() -> void:
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
   if str(clipping["kind"]) == "gig":
    _scrapbook_gig_ticket(scrapbook,entry)
   else:
    _label(scrapbook,str(clipping["rubric"])+"  ·  DAY %d" % int(clipping["day"]),12,UI.AMBER)
    Components.story(scrapbook,entry)

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

func _is_show_day() -> bool:
 var booked: Dictionary = Calendar.pending(_state())
 return not booked.is_empty() and int(booked.get("day",-1)) == _num("tour_day")

func _switch(next_tab: String) -> void:
 if _is_show_day() and next_tab != "GIGS":
  tab = "GIGS"
  message = "It's show day. Finish tonight's booking before other activities."
  _render()
  return
 if tab == next_tab:
  return
 preserve_gear_scroll = false
 preserve_roster_scroll = false
 preserve_venue_scroll = false
 tab = next_tab
 _render()
 _reveal_destination()

func _reveal_destination() -> void:
 # Presentation only: transitions never consume a turn or delay gameplay state.
 # The temporary veil ignores pointer input and is disposed of automatically.
 var veil := ColorRect.new()
 veil.name = "NavigationReveal"
 veil.color = UI.palette(_genre_id())["bg"]
 veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(veil)
 veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var tween := create_tween()
 tween.tween_property(veil,"modulate:a",0.0,0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 tween.tween_callback(veil.queue_free)

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
 if _is_show_day() and not source.begins_with("gig:") and source != "backstage" and source != "booking_cancel":
  message = "Tonight's gig comes first. Finish the show before another activity."
  tab = "GIGS"
  _render()
  return
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
 var before_songs: Array = before.get("song_catalogue",[])
 var after_songs: Array = after.get("song_catalogue",[])
 var song_finished := after_songs.size() > before_songs.size()
 if song_finished:
  var song: Dictionary = after_songs.back()
  var sleeve := PanelContainer.new()
  var sleeve_style := UI.style(Color("#E9DDC2"),12)
  sleeve_style.border_color = Color("#B99563")
  sleeve_style.set_border_width_all(3)
  sleeve.add_theme_stylebox_override("panel",sleeve_style)
  stack.add_child(sleeve)
  var sleeve_copy := VBoxContainer.new()
  sleeve_copy.add_theme_constant_override("separation",8)
  sleeve.add_child(sleeve_copy)
  _label(sleeve_copy,"NEW ORIGINAL  /  SONG FINISHED",13,Color("#8A5F30"))
  _label(sleeve_copy,str(song.get("title","UNTITLED")).to_upper(),23,Color("#231C15"))
  _label(sleeve_copy,str(song.get("origin","ORIGINAL"))+"  ·  "+str(song.get("arrangement",""))+"  ·  "+str(song.get("lead_writer","")),13,Color("#665343"))
  _label(sleeve_copy,"A NEW SONG FOR THE SETLIST  /  DAY %d" % int(after.get("tour_day",1)),12,Color("#8A5F30"))
 var chapter_result := source.begins_with("chapter:")
 if chapter_result:
  var reward_heading := _label(stack,"CHAPTER COMPLETE  /  REWARD CLAIMED",14,UI.palette(_genre_id())["accent"])
  reward_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var show_result := source.begins_with("gig:")
 if show_result:
  var show_banner := PanelContainer.new()
  var show_skin := UI.style(Color("#191320"),12)
  show_skin.border_color = Color("#AC668E")
  show_skin.border_width_top = 3
  show_banner.add_theme_stylebox_override("panel",show_skin)
  stack.add_child(show_banner)
  var show_stack := VBoxContainer.new()
  show_stack.add_theme_constant_override("separation",9)
  show_banner.add_child(show_stack)
  var prelude := _label(show_stack,"HOUSE LIGHTS DOWN  /  THE CROWD IS WAITING",12,Color("#E9B9D4"))
  prelude.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var stage_art_path := "res://Art/Backgrounds/%s/gigs.webp" % _genre_id()
  if not ResourceLoader.exists(stage_art_path):
   stage_art_path = "res://Art/Backgrounds/shared/gigs.webp"
  if ResourceLoader.exists(stage_art_path):
   var stage_image := TextureRect.new()
   stage_image.texture = load(stage_art_path)
   stage_image.custom_minimum_size.y = 190
   stage_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   stage_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
   stage_image.modulate.a = 0.0
   show_stack.add_child(stage_image)
   create_tween().tween_property(stage_image,"modulate:a",1.0,0.85).set_trans(Tween.TRANS_SINE)
  var crowd_strip := HBoxContainer.new()
  crowd_strip.add_theme_constant_override("separation",8)
  show_stack.add_child(crowd_strip)
  for caption in ["◉ PA LEFT","♪ CROWD","◉ PA RIGHT"]:
   var light := _label(crowd_strip,caption,12,Color("#E9B9D4"))
   light.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   light.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var overline := _label(stack,"THE SHOW  /  BACKSTAGE REPORT" if show_result else "LIVIN' THE DREAM  /  CAREER MOMENT",11,UI.MUTED)
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

func _resolve_backstage_illness(choice_id: String) -> void:
 var outcome: Dictionary = BackstageIncident.resolve(_state(),choice_id)
 _finish(outcome,"backstage")

func _show_stage_entry() -> void:
 var state := _state()
 var view: Dictionary = GigNight.stage(state)
 if not bool(view.get("can_play",false)):
  message = "Complete arrival and soundcheck first."
  _render()
  return
 var show: Dictionary = Calendar.pending(state)
 var shade := ColorRect.new()
 shade.name = "StageEntry"
 shade.color = Color(0.025,0.015,0.035,0.97)
 shade.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroller := ScrollContainer.new()
 shade.add_child(scroller)
 scroller.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroller.add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size.x = minf(760.0,get_viewport_rect().size.x-32.0)
 panel.add_theme_stylebox_override("panel",UI.style(Color("#241827"),16))
 center.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",14)
 panel.add_child(stack)
 _label(stack,"HOUSE LIGHTS DOWN  /  LIVE TONIGHT",13,Color("#ECB6D4"))
 _label(stack,str(show.get("venue","THE VENUE")).to_upper(),27,UI.WHITE)
 var path := "res://Art/Backgrounds/%s/gigs.webp" % _genre_id()
 if not ResourceLoader.exists(path):
  path = "res://Art/Backgrounds/shared/gigs.webp"
 if ResourceLoader.exists(path):
  var photo := TextureRect.new()
  photo.texture = load(path)
  photo.custom_minimum_size.y = 220
  photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  stack.add_child(photo)
 _label(stack,"The crowd is waiting. Once you start, the show plays out.",16,UI.WHITE)
 var start := UI.themed_button("LIGHTS UP  /  START THE SHOW",_genre_id(),true)
 start.custom_minimum_size.y = 62
 stack.add_child(start)
 start.pressed.connect(func() -> void:
  start.disabled = true
  shade.queue_free()
  _perform_gig()
 )
 _action(stack,"BACK TO SOUNDCHECK",func() -> void: shade.queue_free())
 shade.modulate.a = 0.0
 create_tween().tween_property(shade,"modulate:a",1.0,0.35)

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

func _assign_gear(id: String,member_index: int) -> void:
 _finish(Gear.assign(_state(),id,member_index),"gear:assign")

func _service_gear(id: String) -> void:
 _finish(Gear.service(_state(),id),"gear:service")

func _member(index: int, action: String) -> void:
 _finish(Members.resolve(_state(),index,action))

func _choose(event_id: String,choice_id: String) -> void:
 _finish(Opportunities.resolve(_state(),event_id,choice_id))

func _repair() -> void:
 if _is_show_day():
  message = "The van can't go to the garage on show day."
  tab = "GIGS"
  _render()
  return
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
