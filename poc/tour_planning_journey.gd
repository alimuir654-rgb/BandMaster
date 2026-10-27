extends "res://poc/tour_controls_lab.gd"
## Sprint 03 playable journey PoC. Inherits the approved Sprint 02 control family.
## All state is a local copy; no autoload, main game, career save or economy mutation.
const Model = preload("res://Scripts/tour_planning_poc_model.gd")
const Itinerary = preload("res://Scripts/tour_itinerary.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")

var demo_state: Dictionary = Model.sample_state()
var venue_id := "cardiff"
var plan_id := Itinerary.DRIVE
var stage := "plan" # plan -> review -> arrival (dusk)
var message := "SAMPLE BAND / IN-GAME TARIFFS / NO CAREER SAVE CHANGES"

func choose_venue(next_id: String) -> void:
 if stage != "plan" or not Model.VENUES.has(next_id):
  return
 venue_id = next_id
 plan_id = Itinerary.DRIVE
 message = "SELECT THE VAN LOAD AND JOURNEY OPTION"
 _rebuild()

func choose_plan(next_id: String) -> void:
 if stage != "plan" or Itinerary.preview(demo_state,venue_id,next_id).is_empty():
  return
 plan_id = next_id
 message = "REVIEW THE COST AND FATIGUE BEFORE CONFIRMING"
 _rebuild()

func review_journey() -> void:
 if stage != "plan":
  return
 var result := Model.preview(demo_state,venue_id,plan_id,van_ready)
 if not bool(result.get("ok",false)):
  message = str(result.get("message","Unable to preview."))
  _rebuild()
  return
 stage = "review"
 message = "REVIEW ONLY / CASH AND VAN HEALTH UNCHANGED"
 _rebuild()

func confirm_journey() -> void:
 if stage != "review":
  return
 var result := Model.commit(demo_state,venue_id,plan_id,van_ready)
 if not bool(result.get("ok",false)):
  message = str(result.get("message","Unable to confirm."))
  _rebuild()
  return
 demo_state = result["state"]
 stage = "arrival"
 message = "CONFIRMED IN DEMO / DUSK ARRIVAL / NO SHOW SETTLEMENT"
 _rebuild()

func back_to_plan() -> void:
 if stage != "review":
  return
 stage = "plan"
 message = "CHANGES NOT COMMITTED / NO CASH OR TIME SPENT"
 _rebuild()

func restart_demo() -> void:
 demo_state = Model.sample_state()
 venue_id = "cardiff"
 plan_id = Itinerary.DRIVE
 van_ready = false
 stage = "plan"
 message = "DEMO RESET / CAREER SAVE STILL UNTOUCHED"
 _rebuild()

func _rebuild() -> void:
 phase = Worlds.resolve_phase({"moment":"arrival" if stage == "arrival" else "planning"})
 var width := DisplayServer.window_get_size().x
 var height := DisplayServer.window_get_size().y
 var mobile := width < 680
 var compact := height <= 800
 _scale = clampf(get_viewport_rect().size.x / float(maxi(1,width)),0.7,2.3)
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var p: Dictionary = Worlds.palette("tour",phase)
 var bg := ColorRect.new()
 bg.name = "TourJourneyBackdrop"
 bg.color = p["bg"]
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(bg)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroll := ScrollContainer.new()
 scroll.name = "TourJourneyScroll"
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(center)
 var page := MarginContainer.new()
 page.custom_minimum_size.x = minf(920.0 * _scale,maxf(320.0 * _scale,get_viewport_rect().size.x-28.0*_scale))
 for side in ["left","right"]:
  page.add_theme_constant_override("margin_"+side,roundi(12*_scale))
 page.add_theme_constant_override("margin_top",roundi(9*_scale))
 page.add_theme_constant_override("margin_bottom",roundi(14*_scale))
 center.add_child(page)
 var col := VBoxContainer.new()
 col.add_theme_constant_override("separation",roundi((5 if compact else 8)*_scale))
 page.add_child(col)
 _text(col,"LIVIN' THE DREAM  /  TOUR PLANNING 03  /  ISOLATED DEMO",12,p["muted"],"JourneyOverline")
 _text(col,"ARRIVE BEFORE THE LIGHTS" if stage == "arrival" else "THE NEXT STOP",26 if compact else 31,p["ink"],"JourneyHeading")
 _text(col,"DUSK / ARRIVAL" if stage == "arrival" else "DAY / ROAD DESK",13,p["muted"],"JourneyPhase")
 var case := Control.new()
 case.name = "JourneyRoadCase"
 case.custom_minimum_size.y = (194 if compact else (213 if mobile else 226))*_scale
 case.clip_contents = true
 col.add_child(case)
 _texture(case,CASE_ART)
 var case_margin := MarginContainer.new()
 case.add_child(case_margin)
 case_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right"]:
  case_margin.add_theme_constant_override("margin_"+side,roundi((43 if mobile else 48)*_scale))
 for side in ["top","bottom"]:
  case_margin.add_theme_constant_override("margin_"+side,roundi((10 if compact else 12)*_scale))
 var case_col := VBoxContainer.new()
 case_col.add_theme_constant_override("separation",roundi(5*_scale))
 case_margin.add_child(case_col)
 _text(case_col,"01 / VENUE  /  FICTIONAL UK CIRCUIT",12,Color("#D9DFDB"))
 var routes := HBoxContainer.new()
 routes.add_theme_constant_override("separation",roundi(4*_scale))
 case_col.add_child(routes)
 for id in Model.VENUES:
  var route_id: String = id
  var route: Dictionary = Circuit.get_venue(route_id)
  var route_button: Button = _button(routes,str(route["city"]),route_id==venue_id,
   func() -> void: choose_venue(route_id),p,"Venue"+route_id.capitalize(),true)
  route_button.disabled = stage != "plan"
  if route_button.disabled:
   route_button.add_theme_color_override("font_disabled_color",Color("#E8E9DF"))
 var rule := ColorRect.new()
 rule.color = Color("#637276")
 rule.custom_minimum_size.y = 1*_scale
 case_col.add_child(rule)
 var latch_row := HBoxContainer.new()
 latch_row.add_theme_constant_override("separation",roundi(8*_scale))
 case_col.add_child(latch_row)
 var amp: Dictionary = demo_state.get("gear_records",{}).get("amp",{})
 var latch_text := "SECURED" if van_ready else "CHECK LOAD"
 var latch_label: Label = _text(latch_row,"02 / AMP %d/100  /  %s" % [int(amp.get("condition",-1)),latch_text],
  12,Color("#E8D4B5") if not van_ready else Color("#B5D9C4"),"JourneyVanState")
 latch_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 latch_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var lamp := ColorRect.new()
 lamp.name = "JourneyVanLamp"
 lamp.color = Color("#55D9A0") if van_ready else Color("#E2A14B")
 lamp.custom_minimum_size = Vector2(9,9)*_scale
 lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
 lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 latch_row.add_child(lamp)
 var latch: Button = _button(case_col,"UNLATCH VAN" if van_ready else "SECURE VAN & GEAR",false,
  toggle_van,p,"JourneyVanLatch",true)
 latch.disabled = stage != "plan"
 if latch.disabled:
  latch.add_theme_color_override("font_disabled_color",Color("#E8E9DF"))
 var venue: Dictionary = Circuit.get_venue(venue_id)
 var ticket := Control.new()
 ticket.name = "JourneyPaperTicket"
 ticket.custom_minimum_size.y = (82 if compact else 94)*_scale
 ticket.clip_contents = true
 col.add_child(ticket)
 _texture(ticket,TICKET_ART)
 var ticket_margin := MarginContainer.new()
 ticket.add_child(ticket_margin)
 ticket_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ticket_margin.add_theme_constant_override("margin_left",roundi(19*_scale))
 ticket_margin.add_theme_constant_override("margin_top",roundi(7*_scale))
 var ticket_col := VBoxContainer.new()
 ticket_col.add_theme_constant_override("separation",roundi(1*_scale))
 ticket_margin.add_child(ticket_col)
 _text(ticket_col,"ITINERARY  /  SIMULATED GAME DAY %d" % (int(demo_state["tour_day"])+2),11,Color("#62523E"),"JourneyTicketDate")
 _text(ticket_col,str(venue["venue"]).to_upper(),22 if mobile else 25,Color("#27312D"),"JourneyTicketVenue")
 _text(ticket_col,"%s  /  SHOW FEE £%d  /  NO DISTANCE ESTIMATE" % [str(venue["city"]),int(venue["fee"])],11,Color("#514B41"))
 var plans: Array = Model.options(demo_state,venue_id)
 var choice_row := HBoxContainer.new()
 choice_row.name = "JourneyOptions"
 choice_row.add_theme_constant_override("separation",roundi(6*_scale))
 col.add_child(choice_row)
 for option in plans:
  var option_id: String = str(option["id"])
  var label := "DRIVE HOME" if option_id == Itinerary.DRIVE else "ROOM + REST"
  var choice: Button = _button(choice_row,"%s  £%d" % [label,int(option["total_cost"])],
   option_id==plan_id,func() -> void: choose_plan(option_id),p,"Plan"+option_id.capitalize(),false)
  choice.disabled = stage != "plan" or not bool(option["available"])
  if choice.disabled:
   choice.add_theme_color_override("font_disabled_color",p["ink"])
 var plan: Dictionary = Itinerary.preview(demo_state,venue_id,plan_id)
 var readouts := HBoxContainer.new()
 readouts.name = "JourneyConsequences"
 readouts.add_theme_constant_override("separation",roundi(6*_scale))
 col.add_child(readouts)
 _readout(readouts,"CASH NOW","£%d" % int(demo_state["cash"]),p)
 _readout(readouts,"COST AT SHOW","£%d" % int(plan.get("total_cost",0)),p)
 _readout(readouts,"VAN WEAR","-%d" % int(plan.get("van_wear",0)),p)
 var after := Model.preview(demo_state,venue_id,plan_id,van_ready)
 var summary := ""
 if stage == "arrival":
  summary = "ROUTE LOCKED / £%d STILL IN CASH / VAN %d / SHOW NOT PLAYED" % [int(demo_state["cash"]),int(demo_state["van_health"])]
 elif bool(after.get("ok",false)):
  summary = "AFTER COSTS £%d  /  VAN %d  /  FATIGUE %+d  /  MORALE %+d" % [
   int(after["cash_after_costs"]),int(after["van_after"]),int(after["fatigue_delta"]),int(after["morale_delta"])]
 else:
  summary = str(after.get("message","Review your journey."))
 _text(col,summary,13,p["ink"],"JourneyPreview")
 _text(col,message,12,p["muted"],"JourneyStatus")
 if stage == "plan":
  _button(col,"REVIEW JOURNEY",false,review_journey,p,"JourneyPrimary",false,true)
 elif stage == "review":
  _button(col,"CONFIRM ITINERARY",false,confirm_journey,p,"JourneyPrimary",false,true)
  _button(col,"BACK / CHANGE PLAN",false,back_to_plan,p,"JourneyBack")
 else:
  _button(col,"RESTART SAMPLE JOURNEY",false,restart_demo,p,"JourneyPrimary",false,true)
 _text(col,"TARIFFS FROM TOUR ITINERARY ENGINE  /  NO SAVE, CASH OR TIME WRITES",11,p["muted"],"JourneyDisclaimer")
