extends Control
# Full-screen five-place gig-day journey; all costs and outcomes use existing engines.
const UI = preload("res://Scripts/ui_theme.gd")
const Journey = preload("res://Scripts/show_day_journey.gd")
const Fade = preload("res://Scripts/journey_fade.gd")
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
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 parent.add_child(label)
 return label

func _button(parent: Node, caption: String, callback: Callable, primary: bool = false) -> Button:
 var button := UI.themed_button(caption,genre_id,primary)
 button.custom_minimum_size.y = 54
 button.focus_mode = Control.FOCUS_ALL
 var step := maxi(0,Journey.current_step(source_state))
 var style := UI.style(ACCENTS[step] if primary else BACKDROPS[step].lightened(0.15),10)
 style.border_color = ACCENTS[step]
 style.set_border_width_all(2)
 button.add_theme_stylebox_override("normal",style)
 button.add_theme_color_override("font_color",Color("#142024") if primary else Color("#FFFFFF"))
 parent.add_child(button)
 button.pressed.connect(callback)
 return button

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
 var art_path: String = "res://Art/Journeys/ShowDay/"+str(ART[step])
 if ResourceLoader.exists(art_path):
  var ambient := TextureRect.new()
  ambient.name = "ShowJourneyAmbient"
  ambient.texture = load(art_path)
  ambient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  ambient.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  ambient.modulate.a = 0.21
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
 var scroller := ScrollContainer.new()
 scroller.name = "ShowJourneyScroll"
 scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
 layout.add_child(scroller)
 var centered := CenterContainer.new()
 centered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroller.add_child(centered)
 var body := VBoxContainer.new()
 body.custom_minimum_size.x = minf(780.0,maxf(280.0,get_viewport_rect().size.x-2.0*gutter-14.0))
 body.add_theme_constant_override("separation",12)
 centered.add_child(body)
 if ResourceLoader.exists(art_path):
  var illustration := TextureRect.new()
  illustration.name = "ShowJourneyArtwork"
  illustration.texture = load(art_path)
  illustration.custom_minimum_size.y = 210 if get_viewport_rect().size.x < 600 else 280
  illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
  body.add_child(illustration)
 else:
  _label(body,"ILLUSTRATION NOT INSTALLED",14,ACCENTS[step])
 _label(body,str(booking.get("venue","THE VENUE")).to_upper()+"  /  "+str(booking.get("city","")),16,ACCENTS[step])
 match step:
  0:
   _label(body,"Flight cases scrape the pavement. The band's ready to leave — but what is actually going in the van?",18,Color("#FFF7EC"))
   var equipment: Array = source_state.get("owned_equipment",[])
   _label(body,"EQUIPMENT OWNED  /  %d ITEMS" % equipment.size(),15,ACCENTS[step])
   _label(body,"VAN CONDITION  /  %d%%" % int(source_state.get("van_health",0)),15,Color("#FFF7EC"))
   var penalty := int(Gear.readiness_penalty(source_state))
   _label(body,"WORN GEAR READINESS EFFECT  /  %+d" % penalty,15,Color("#FFF7EC"))
   _label(body,"Check the gear before departure. Repairs and shopping require a day off; show-day loading is free.",14,Color("#D6E4DD"))
  1:
   _label(body,"Streetlights fall behind. The band watches the motorway unspool while tomorrow's stories start forming.",18,Color("#FFF7EC"))
   var plan_id := str(booking.get("travel_plan",Tour.DRIVE))
   var plan: Dictionary = Tour.preview(source_state,str(booking.get("venue_id","")),plan_id)
   _label(body,"CURRENT ROUTE  /  "+str(plan.get("label","LEGACY TRAVEL PLAN")),15,ACCENTS[step])
   _label(body,"TRAVEL £%d  /  ROOM £%d  /  VAN WEAR %d" % [int(plan.get("travel_cost",0)),int(plan.get("accommodation_cost",0)),int(plan.get("van_wear",0))],14,Color("#FFF7EC"))
   for option in Tour.choices(source_state,str(booking.get("venue_id",""))):
    if str(option.get("id","")) != plan_id and bool(option.get("available",false)):
     var alternative := str(option.get("id",""))
     _button(body,"CHANGE PLAN  /  "+str(option.get("label","")),func() -> void: _replan(alternative))
   _label(body,"The trip is charged by the existing gig settlement, not by viewing this scene.",13,Color("#B9CEDD"))
  2:
   _label(body,"The venue sign glows above the loading doors. You can hear a kick drum through the brickwork.",18,Color("#FFF7EC"))
   _label(body,"PROMOTER BOOKING  /  "+str(booking.get("venue","")),15,ACCENTS[step])
   _label(body,"SET APPROACH  /  "+str(booking.get("approach","tight")).to_upper(),15,Color("#FFF7EC"))
   _label(body,"Unload, meet the crew and walk into the room. No money or time changes hands at arrival.",14,Color("#E6D9E9"))
  3:
   _label(body,"Empty floor, bright work lights, cables everywhere. The room sounds different from rehearsal.",18,Color("#FFF7EC"))
   var illness: Dictionary = Backstage.incident(source_state)
   if not illness.is_empty():
    _label(body,str(illness.get("name","A bandmate")).to_upper()+" IS STRUGGLING BACKSTAGE",17,ACCENTS[step])
    for option in illness.get("options",[]):
     var choice := str(option.get("id",""))
     _button(body,str(option.get("label","")),func() -> void: _resolve_incident(choice))
   _label(body,"CHOOSE THE LIVE APPROACH  /  REAL CONSEQUENCES",15,ACCENTS[step])
   for approach_id in ["tight","wild","crowd"]:
    var id := str(approach_id)
    var preview: Dictionary = Gigs.approach_preview(source_state,id)
    var active := str(booking.get("approach","tight")) == id
    _button(body,("✓  " if active else "")+str(preview.get("label",id))+"  /  "+str(preview.get("outlook","")),func() -> void: _choose_approach(id),active)
   _label(body,"Set choice changes performance quality, audience growth and tension at settlement.",13,Color("#D2E3E6"))
  4:
   _label(body,"The band is lined up behind the curtain. The support act leaves the stage. The room goes dark.",18,Color("#FFF7EC"))
   _label(body,"YOUR SET  /  "+str(booking.get("approach","tight")).to_upper(),16,ACCENTS[step])
   _label(body,"ORIGINAL SONGS  /  %d" % int(source_state.get("songs",0)),15,Color("#FFF7EC"))
   _label(body,"The show settles once, through the existing gig engine. This final step does not pay twice.",13,Color("#F0D6DE"))
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
