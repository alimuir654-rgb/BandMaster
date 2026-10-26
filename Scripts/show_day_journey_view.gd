extends Control
# Full-screen five-place gig-day journey; all costs and outcomes use existing engines.
const UI = preload("res://Scripts/ui_theme.gd")
const Journey = preload("res://Scripts/show_day_journey.gd")
const Fade = preload("res://Scripts/journey_fade.gd")
const Photos = preload("res://Scripts/journey_photo.gd")
const Cinematic = preload("res://Scripts/journey_cinematic_stage.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const GigNight = preload("res://Scripts/gig_night_flow.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
const ART := ["01-load.svg","02-road.svg","03-arrival.svg","04-soundcheck.svg","05-backstage.svg"]
const BACKDROPS := [Color("#1C2928"),Color("#14243D"),Color("#2D1D37"),Color("#2B3036"),Color("#351A26")]
const ACCENTS := [Color("#D3E89A"),Color("#A6D8F3"),Color("#FFC69A"),Color("#A5E1E0"),Color("#F9B4C6")]
var source_state: Dictionary = {}
var genre_id := "indie"
var save_callback: Callable
var show_callback: Callable
var close_callback: Callable
var reduced_motion := false
var busy := false
var stage_root: Control
var fade_layer: ColorRect
var status_message := ""

func open(state: Dictionary, selected_genre: String, on_save: Callable, on_show: Callable, on_close: Callable) -> void:
 source_state = state.duplicate(true)
 genre_id = selected_genre
 save_callback = on_save
 show_callback = on_show
 close_callback = on_close
 name = "ShowDayJourney"
 mouse_filter = Control.MOUSE_FILTER_STOP
 stage_root = Control.new()
 stage_root.name = "ShowJourneyScene"
 add_child(stage_root)
 stage_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 fade_layer = ColorRect.new()
 fade_layer.name = "ShowJourneyFade"
 fade_layer.color = Color(0,0,0,0)
 fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(fade_layer)
 fade_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _render_stage()

func _label(parent: Node, words: String, size: int, color: Color) -> Label:
 var label := Label.new()
 label.text = words
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 # Small copy was unreadable in populated 1280x720 captures; preserve
 # headline hierarchy but enforce a readable floor across all viewports.
 label.add_theme_font_size_override("font_size",maxi(size,16))
 label.add_theme_color_override("font_color",color)
 parent.add_child(label)
 return label

func _button(parent: Node, caption: String, callback: Callable, primary: bool = false) -> Button:
 var button := UI.themed_button(caption,genre_id,primary)
 button.custom_minimum_size.y = 56
 button.focus_mode = Control.FOCUS_ALL
 button.add_theme_font_size_override("font_size",16)
 parent.add_child(button)
 button.pressed.connect(callback)
 return button

# Physical loadout manifest. Each case has a carrier, a condition and an
# accessible crew selector; assignment uses the existing persistent gear engine.
func _cargo_card(parent: Node, item_id: String, ordinal: int) -> void:
 var record: Dictionary = Gear.record(source_state,item_id)
 var holder := Gear.holder_index(source_state,record)
 var members: Array = source_state.get("members",[])
 var gear_name := str(Gear.item_for(item_id).get("name",item_id))
 var condition := "NOT INSPECTED" if int(record.get("condition",-1)) < 0 else "%d%% CONDITION" % int(record.get("condition",0))
 var card := PanelContainer.new()
 card.name = "CargoCase%02d" % ordinal
 card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var surface := UI.flat(Color("#17252D"),8)
 surface.set_content_margin_all(14)
 surface.border_color = Color("#4A625C")
 surface.border_width_left = 3
 card.add_theme_stylebox_override("panel",surface)
 parent.add_child(card)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",7)
 card.add_child(stack)
 _label(stack,"CASE %02d   /   %s" % [ordinal,condition],13,Color("#D3E89A"))
 _label(stack,gear_name.to_upper(),18,Color("#FFF7EC"))
 if holder >= 0 and holder < members.size():
  _label(stack,"LOADED BY  /  "+str(members[holder].get("name","CREW")).to_upper(),14,Color("#C6D8D2"))
  return
 var crew := OptionButton.new()
 crew.name = "CargoCrewPicker%02d" % ordinal
 crew.custom_minimum_size.y = 52
 crew.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 crew.focus_mode = Control.FOCUS_ALL
 crew.add_item("ASSIGN A BANDMATE")
 var candidate_indices: Array[int] = []
 for index in range(members.size()):
  var member: Dictionary = members[index]
  if str(member.get("life_status","active")) == "active" and Gear.compatible(item_id,member):
   candidate_indices.append(index)
   crew.add_item("LOAD WITH "+str(member.get("name","MUSICIAN")).to_upper())
 if candidate_indices.is_empty():
  crew.disabled = true
  crew.set_item_text(0,"NO COMPATIBLE CREW")
 crew.add_theme_stylebox_override("normal",UI._button_surface(Color("#263C40"),false))
 crew.add_theme_color_override("font_color",Color("#FFF7EC"))
 crew.add_theme_font_size_override("font_size",16)
 stack.add_child(crew)
 var item_key := item_id
 crew.item_selected.connect(func(option: int) -> void:
  if option > 0 and option <= candidate_indices.size():
   _assign_loading_gear(item_key,candidate_indices[option-1])
 )

func _render_stage() -> void:
 if not is_instance_valid(stage_root):
  return
 for child in stage_root.get_children():
  stage_root.remove_child(child)
  child.queue_free()
 var step := Journey.current_step(source_state)
 if step < 0:
  queue_free()
  return
 var booking: Dictionary = Calendar.pending(source_state)
 var background := ColorRect.new()
 background.color = BACKDROPS[step]
 stage_root.add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var art_path: String = Photos.scene_or_fallback("showday",step,1280.0,"res://Art/Journeys/ShowDay/"+str(ART[step]))
 var ambient_path: String = Photos.scene_or_fallback("showday",step,get_viewport_rect().size.x,art_path)
 if ResourceLoader.exists(ambient_path):
  var ambient := TextureRect.new()
  ambient.name = "ShowJourneyAmbient"
  ambient.texture = load(ambient_path)
  ambient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  ambient.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  ambient.modulate.a = 0.10
  ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
  stage_root.add_child(ambient)
  ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margins := MarginContainer.new()
 stage_root.add_child(margins)
 margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var gutter := 14 if get_viewport_rect().size.x < 600 else 32
 for edge in ["margin_left","margin_right"]:
  margins.add_theme_constant_override(edge,gutter)
 margins.add_theme_constant_override("margin_top",14)
 margins.add_theme_constant_override("margin_bottom",16)
 var layout := VBoxContainer.new()
 layout.add_theme_constant_override("separation",10)
 margins.add_child(layout)
 _label(layout,"LIVE TONIGHT  /  %02d OF 05  /  DAY %d" % [step+1,int(booking.get("day",0))],13,ACCENTS[step])
 _label(layout,Journey.STEPS[step],29,Color("#FFF7EC"))
 var rail := HBoxContainer.new()
 rail.name = "ShowJourneyProgressRail"
 rail.add_theme_constant_override("separation",7)
 layout.add_child(rail)
 for index in range(5):
  var segment := ColorRect.new()
  segment.custom_minimum_size.y = 5
  segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  segment.color = ACCENTS[step] if index <= step else BACKDROPS[step].lightened(0.22)
  segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
  rail.add_child(segment)
 var scroller := ScrollContainer.new()
 scroller.name = "ShowJourneyScroll"
 scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
 layout.add_child(scroller)
 var centered := CenterContainer.new()
 centered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroller.add_child(centered)
 var body := VBoxContainer.new()
 var cinematic_split := get_viewport_rect().size.x >= 960.0
 body.custom_minimum_size.x = maxf(280.0,get_viewport_rect().size.x-2.0*gutter-14.0) if cinematic_split else minf(760.0,maxf(280.0,get_viewport_rect().size.x-2.0*gutter-14.0))
 body.add_theme_constant_override("separation",12)
 centered.add_child(body)
 # Wide displays use a cinematic two-plane composition: environment on the
 # left, readable decisions on the right. Phones keep the linear story.
 var scene_planes: BoxContainer = HBoxContainer.new() if cinematic_split else VBoxContainer.new()
 scene_planes.name = "ShowJourneyScenePlanes"
 scene_planes.add_theme_constant_override("separation",24 if cinematic_split else 12)
 body.add_child(scene_planes)
 var hero_height := 310.0 if get_viewport_rect().size.x < 600.0 else (370.0 if cinematic_split else 350.0)
 Cinematic.add_hero(scene_planes,art_path,"GIG DAY  /  %02d OF 05" % (step+1),str(Journey.STEPS[step]),ACCENTS[step],hero_height)
 var story_panel := PanelContainer.new()
 story_panel.name = "ShowJourneyStoryPanel"
 story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if cinematic_split:
  story_panel.custom_minimum_size.y = 340
 var panel_tone := UI.flat(Color("#101923"),8)
 panel_tone.set_content_margin_all(18)
 panel_tone.border_color = Color("#425A59")
 panel_tone.border_width_top = 2
 story_panel.add_theme_stylebox_override("panel",panel_tone)
 scene_planes.add_child(story_panel)
 var story_holder: Node = story_panel
 var story := VBoxContainer.new()
 story.name = "ShowJourneyStory"
 story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 story.add_theme_constant_override("separation",12)
 story_holder.add_child(story)
 _label(story,str(booking.get("venue","THE VENUE")).to_upper()+"  /  "+str(booking.get("city","")),16,ACCENTS[step])
 match step:
  0:
   _label(story,"Every case needs a carrier. Assign the loadout before leaving the kerb.",17,Color("#FFF7EC"))
   var equipment: Array = source_state.get("owned_equipment",[])
   _label(story,"CARGO BAY  /  %d OWNED CASES" % equipment.size(),15,ACCENTS[step])
   if equipment.is_empty():
    _label(story,"NO OWNED GEAR  /  VENUE BACKLINE NOT CONFIRMED",16,Color("#F1D6B7"))
   else:
    var bay := GridContainer.new()
    bay.name = "ShowJourneyCargoBay"
    bay.columns = 2 if get_viewport_rect().size.x >= 960.0 else 1
    bay.add_theme_constant_override("h_separation",12)
    bay.add_theme_constant_override("v_separation",12)
    bay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    story.add_child(bay)
    for item_index in range(mini(equipment.size(),4)):
     _cargo_card(bay,str(equipment[item_index]),item_index+1)
    if equipment.size() > 4:
     _label(story,"%d MORE CASES ARE IN YOUR INVENTORY" % (equipment.size()-4),15,Color("#C6D8D2"))
   var penalty := int(Gear.readiness_penalty(source_state))
   _label(story,"VAN %d%%   /   GEAR READINESS %+d" % [int(source_state.get("van_health",0)),penalty],16,ACCENTS[step])
   _label(story,"Crew assignment is free today. Repairs and purchases need a day off.",16,Color("#C6D8D2"))
  1:
   _label(story,"Streetlights fall behind. The band watches the motorway unspool while tomorrow's stories start forming.",18,Color("#FFF7EC"))
   var plan_id := str(booking.get("travel_plan",Tour.DRIVE))
   var plan: Dictionary = Tour.preview(source_state,str(booking.get("venue_id","")),plan_id)
   _label(story,"CURRENT ROUTE  /  "+str(plan.get("label","LEGACY TRAVEL PLAN")),15,ACCENTS[step])
   _label(story,"TRAVEL £%d  /  ROOM £%d  /  VAN WEAR %d" % [int(plan.get("travel_cost",0)),int(plan.get("accommodation_cost",0)),int(plan.get("van_wear",0))],14,Color("#FFF7EC"))
   for option in Tour.choices(source_state,str(booking.get("venue_id",""))):
    if str(option.get("id","")) != plan_id and bool(option.get("available",false)):
     var alternative := str(option.get("id",""))
     _button(story,"CHANGE PLAN  /  "+str(option.get("label","")),func() -> void: _replan(alternative))
   _label(story,"The trip is charged by the existing gig settlement, not by viewing this scene.",13,Color("#B9CEDD"))
  2:
   _label(story,"The venue sign glows above the loading doors. You can hear a kick drum through the brickwork.",18,Color("#FFF7EC"))
   _label(story,"PROMOTER BOOKING  /  "+str(booking.get("venue","")),15,ACCENTS[step])
   _label(story,"SET APPROACH  /  "+str(booking.get("approach","tight")).to_upper(),15,Color("#FFF7EC"))
   _label(story,"Unload, meet the crew and walk into the room. No money or time changes hands at arrival.",14,Color("#E6D9E9"))
  3:
   _label(story,"Empty floor, bright work lights, cables everywhere. The room sounds different from rehearsal.",18,Color("#FFF7EC"))
   var illness: Dictionary = Backstage.incident(source_state)
   if not illness.is_empty():
    _label(story,str(illness.get("name","A bandmate")).to_upper()+" IS STRUGGLING BACKSTAGE",17,ACCENTS[step])
    for option in illness.get("options",[]):
     var choice := str(option.get("id",""))
     _button(story,str(option.get("label","")),func() -> void: _resolve_incident(choice))
   _label(story,"CHOOSE THE LIVE APPROACH  /  REAL CONSEQUENCES",15,ACCENTS[step])
   for approach_id in ["tight","wild","crowd"]:
    var id := str(approach_id)
    var preview: Dictionary = Gigs.approach_preview(source_state,id)
    var active := str(booking.get("approach","tight")) == id
    _button(story,("✓  " if active else "")+str(preview.get("label",id))+"  /  "+str(preview.get("outlook","")),func() -> void: _choose_approach(id),active)
   _label(story,"Set choice changes performance quality, audience growth and tension at settlement.",13,Color("#D2E3E6"))
  4:
   _label(story,"The band is lined up behind the curtain. The support act leaves the stage. The room goes dark.",18,Color("#FFF7EC"))
   _label(story,"YOUR SET  /  "+str(booking.get("approach","tight")).to_upper(),16,ACCENTS[step])
   _label(story,"ORIGINAL SONGS  /  %d" % int(source_state.get("songs",0)),15,Color("#FFF7EC"))
   _label(story,"The show settles once, through the existing gig engine. This final step does not pay twice.",13,Color("#F0D6DE"))
 if get_viewport_rect().size.y >= 780:
  var members: Array = source_state.get("members",[])
  var speaker := "THE BAND"
  for member in members:
   if member is Dictionary and str(member.get("life_status","active")) == "active":
    speaker = str(member.get("name","THE BAND")).to_upper()
    break
  var quotes := [
   "Are the cables in? Last time we were looking for the drum key at the venue.",
   "Someone turn the music up. We're actually doing this.",
   "That's our name on the door. It's smaller than I imagined, but it's ours.",
   "Listen to that room. We need to play to the space, not just the setlist.",
   "No more rehearsals. Whatever happens, we go out there together."
  ]
  var moment := PanelContainer.new()
  moment.name = "ShowJourneyCharacterBeat"
  var moment_style := UI.style(BACKDROPS[step].lightened(0.12),10)
  moment_style.border_color = ACCENTS[step]
  moment_style.border_width_left = 4
  moment.add_theme_stylebox_override("panel",moment_style)
  layout.add_child(moment)
  var moment_body := VBoxContainer.new()
  moment_body.add_theme_constant_override("separation",4)
  moment.add_child(moment_body)
  _label(moment_body,speaker+"  /  IN THE MOMENT",12,ACCENTS[step])
  _label(moment_body,"“"+str(quotes[step])+"”",15,Color("#FFF7EC"))
 if not status_message.is_empty():
  _label(layout,status_message,14,Color("#FFE0D6"))
 var footer := HBoxContainer.new()
 footer.name = "ShowJourneyFooter"
 footer.add_theme_constant_override("separation",10)
 layout.add_child(footer)
 _button(footer,"CLOSE",func() -> void:
  if not busy:
   close_callback.call()
 )
 var action: String = ["HIT THE ROAD  ›","ARRIVE AT VENUE  ›","SURVEY THE STAGE  ›","HEAD BACKSTAGE  ›","LIGHTS UP  /  SHOWTIME"][step]
 var next := _button(footer,action,_next_pressed,true)
 next.name = "ShowJourneyNext"
 next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if step == 3 and not Backstage.incident(source_state).is_empty():
  next.disabled = true
  next.tooltip_text = "Resolve the backstage incident before continuing."
 var motion := _button(layout,"REDUCE MOTION: "+("ON" if reduced_motion else "OFF"),func() -> void:
  reduced_motion = not reduced_motion
  _render_stage()
 )
 motion.name = "ShowJourneyMotionToggle"
 motion.custom_minimum_size.y = 44
 motion.add_theme_font_size_override("font_size",11)

func _store(state: Dictionary) -> void:
 source_state = state.duplicate(true)
 save_callback.call(source_state)

func _advance() -> void:
 if busy:
  return
 busy = true
 Fade.play(fade_layer,func() -> void:
  var result: Dictionary = Journey.advance(source_state)
  if bool(result.get("ok",false)):
   status_message = ""
   _store(result["state"])
  else:
   status_message = str(result.get("message","Unable to continue"))
  _render_stage()
 ,func() -> void:
  busy = false
  var next := find_child("ShowJourneyNext",true,false) as Button
  if next != null:
   next.grab_focus()
 ,reduced_motion)

func _assign_loading_gear(item_id: String, member_index: int) -> void:
 if busy or Journey.current_step(source_state) != 0:
  return
 var result: Dictionary = Gear.assign(source_state,item_id,member_index)
 if bool(result.get("ok",false)):
  _store(result["state"])
 status_message = str(result.get("message","Unable to assign equipment."))
 _render_stage()

func _replan(plan_id: String) -> void:
 if busy:
  return
 var result: Dictionary = Calendar.replan(source_state,plan_id)
 if bool(result.get("ok",false)):
  _store(result["state"])
  status_message = str(result.get("message",""))
 else:
  status_message = str(result.get("message","Unavailable"))
 _render_stage()

func _resolve_incident(choice: String) -> void:
 if busy:
  return
 var result: Dictionary = Backstage.resolve(source_state,choice)
 if bool(result.get("ok",false)):
  _store(result["state"])
 status_message = str(result.get("message",""))
 _render_stage()

func _choose_approach(approach: String) -> void:
 if busy:
  return
 var result: Dictionary = GigNight.choose_set(source_state,approach)
 if bool(result.get("ok",false)):
  _store(result["state"])
 status_message = str(result.get("message",""))
 _render_stage()

func _begin_show() -> void:
 if busy or not Journey.ready_to_perform(source_state):
  status_message = "Complete the soundcheck before going on stage."
  _render_stage()
  return
 busy = true
 queue_free()
 show_callback.call()

func _next_pressed() -> void:
 if Journey.current_step(source_state) == 4:
  _begin_show()
 else:
  _advance()
