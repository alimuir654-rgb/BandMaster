extends RefCounted
## Presentation only: current UI plans are free; the host owns every commit/save.
## Host is deliberately untyped so its existing dynamic desk API stays valid.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Brief = preload("res://Scripts/live_night_briefing.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
const Reviews = preload("res://experiments/playable_flightcase/review_policy.gd")
const OFFER_IDS := ["standard","guarantee","guestlist"]
const APPROACH_IDS := ["tight","wild","crowd"]


static func focus_name(_host) -> String:
 return "LiveMainAction"


static func _sync_context(host, state: Dictionary) -> void:
 var booking: Dictionary = Calendar.pending(state)
 var context: String = "none" if booking.is_empty() else "%s:%d" % [str(booking.get("venue_id","")),int(booking.get("day",0))]
 if str(host.live_context_id)!=context:
  host.live_context_id=context
  if not booking.is_empty():
   host.live_approach=str(booking.get("approach","tight"))
 if not Promoter.OFFERS.has(str(host.live_offer)):
  host.live_offer="standard"
 if not Gigs.APPROACHES.has(str(host.live_approach)):
  host.live_approach="tight"
 if booking.is_empty():
  var eligibility: Dictionary = Live.booking_eligibility(state,false)
  # Clear an obsolete UI-only fallback after the real lineup becomes ready.
  # No musician, role, booking, fee, day or saved state is assigned here.
  if bool(eligibility.get("normal_ready",false)):
   host.live_hire_session=false


static func render(host, parent: Node, compact: bool) -> void:
 var state: Dictionary = host.game.career
 _sync_context(host,state)
 var booking: Dictionary = Calendar.pending(state)
 var stage: Dictionary = Night.stage(state)
 var phase: String = str(stage.get("phase","none"))
 if booking.is_empty():
  _last_show(host,parent,compact,state)
  _unbooked(host,parent,compact,state)
 else:
  _booked(host,parent,compact,state,booking,stage,phase)
 refresh_plans(host)


static func _notice(host, body: Node) -> void:
 if not str(host.notice).is_empty():
  host._copy(body,str(host.notice),16)


static func _toggle(parent: Node, text: String, node_name: String, callback: Callable, locked: bool) -> Button:
 var result: Button = C.button(text,"flightcase","tab",true)
 result.name=node_name
 result.disabled=locked
 result.pressed.connect(callback)
 parent.add_child(result)
 return result


static func _unbooked(host, parent: Node, compact: bool, state: Dictionary) -> void:
 var venue: Dictionary = Gigs.get_venue("local")
 var body: VBoxContainer = host._paper(parent,compact)
 _notice(host,body)
 host._copy(body,str(venue.get("venue","Hometown show")).to_upper(),26)
 host._copy(body,str(venue.get("city","HOMETOWN"))+"  •  DAY %d" % (int(state.get("tour_day",1))+Calendar.LEAD_DAYS),16)
 host._copy(body,"Booking: £0 now. %d days to prepare." % Calendar.LEAD_DAYS,14,true)
 for id in OFFER_IDS:
  var offer: Dictionary = Promoter.OFFERS[id]
  _toggle(body,str(offer["label"]),"LiveOffer_"+str(id),host._select_live_offer.bind(str(id)),bool(host.busy))
 var description: Label = host._copy(body,"",16)
 description.name="LiveOfferDescription"
 var eligibility: Dictionary = Live.booking_eligibility(state,false)
 if not bool(eligibility.get("normal_ready",false)) and int(eligibility.get("active",0))>=1:
  _toggle(body,"SESSION DRUMMER  •  £25","LiveSessionDrummerAction",host._toggle_live_session,bool(host.busy))
  var session_hint: Label = host._copy(body,"Paid at the performance; quality −8. Standard offer only. This player does not join your band.",14,true)
  session_hint.name="LiveSessionHint"
 var lineup: Label = host._copy(body,"",16)
 lineup.name="LiveEligibility"
 host._copy(body,"Venue base fee £%d; the final fee depends on your set, turnout and promoter terms." % int(venue.get("fee",0)),14,true)
 host._copy(body,"Travel costs up to £%d at the show. A selected session drummer costs another £25 there." % int(venue.get("travel",0)),14,true)


static func _booked(host, parent: Node, compact: bool, state: Dictionary, booking: Dictionary, stage: Dictionary, phase: String) -> void:
 var body: VBoxContainer = host._paper(parent,compact)
 _notice(host,body)
 host._copy(body,str(booking.get("venue","YOUR BOOKED SHOW")).to_upper(),24)
 var briefing: Dictionary = Brief.briefing(state)
 host._copy(body,str(booking.get("city",""))+"  •  SHOW DAY %d" % int(booking.get("day",0)),16)
 if phase=="preparation":
  host._copy(body,"%d DAYS TO PREPARE" % int(briefing.get("days_left",0)),22)
  _set_status(host,body,state)
  for tip in briefing.get("tips",[]):
   host._copy(body,str(tip),16)
  body.add_child(host._button("WRITE AN ORIGINAL  ›","LiveWriteAction",host._practice.bind("create")))
  body.add_child(host._button("REHEARSE THE LIVE SET  ›","LiveRehearseAction",host._practice.bind("tighten")))
 elif phase=="overdue":
  host._copy(body,str(stage.get("title","MISSED DATE")),22)
  host._copy(body,str(stage.get("detail","The booked date has passed.")),16)
  host._copy(body,"Clear the missed date with its reputation and morale consequences. There is no performance payout.",16)
 else:
  var index: int = Brief.stage_index(phase)
  if index>=0:
   host._copy(body,"%02d / 03  •  %s" % [index+1,phase.to_upper()],14,true)
  host._copy(body,str(stage.get("title","YOUR SHOW")),22)
  host._copy(body,str(stage.get("detail","")),16)
  if phase=="soundcheck":
   for id in APPROACH_IDS:
    var approach: Dictionary = Gigs.APPROACHES[id]
    _toggle(body,str(approach["label"]),"LiveApproach_"+str(id),host._select_live_approach.bind(str(id)),bool(host.busy))
   var description: Label = host._copy(body,"",16)
   description.name="LiveApproachDescription"
   host._copy(body,"These are modifiers, not a final quality prediction. Fan bonuses require a successful show; originals, chemistry and equipment also matter.",14,true)
   _incident(host,body,state)
  else:
   _set_status(host,body,state)
   if phase=="stage":
    var agreed: Dictionary = Gigs.APPROACHES.get(str(booking.get("approach","tight")),Gigs.APPROACHES["tight"])
    host._copy(body,"AGREED SET  /  "+str(agreed["label"]),16)
    host._copy(body,"Review the performance confirmation before stepping onstage.",16)
 if phase!="overdue":
  var cancel: Button = host._button("CANCEL THIS BOOKING","LiveCancelBookingAction",host._ask_live_confirmation.bind("cancel"))
  cancel.tooltip_text="Review the cancellation fee and reputation consequence before confirming."
  body.add_child(cancel)


static func _set_status(host, body: Node, state: Dictionary) -> void:
 host._copy(body,"READINESS %d / 100  •  %d ORIGINALS" % [int(state.get("readiness",0)),int(state.get("songs",0))],16)


static func _incident(host, body: Node, state: Dictionary) -> void:
 var incident: Dictionary = Backstage.incident(state)
 if incident.is_empty():
  return
 host._copy(body,"BACKSTAGE  /  "+str(incident.get("name","Your bassist")),20)
 host._copy(body,"Your bassist is unwell. You may respond below, or continue soundcheck with the current state.",16)
 for raw in incident.get("options",[]):
  var option: Dictionary = raw
  var id: String = str(option.get("id",""))
  var action: Button = host._button(str(option.get("label","Respond")),"LiveIncident_"+id,host._commit_live.bind("incident",id))
  body.add_child(action)
  host._copy(body,"READINESS %+d  •  MORALE %+d  •  FATIGUE %+d" % [int(option.get("readiness",0)),int(option.get("morale",0)),int(option.get("fatigue",0))],14,true)
 # The original incident is OPTIONAL. It must never disable LiveMainAction.


static func _last_show(host, parent: Node, compact: bool, state: Dictionary) -> void:
 var view: Dictionary = Brief.last_show(state)
 if view.is_empty():
  return
 var history: Array = state.get("gig_history",[])
 if history.is_empty() or not history.back() is Dictionary:
  return
 var record: Dictionary = history.back()
 var body: VBoxContainer = host._paper(parent,compact)
 host._copy(body,"LAST SHOW RECORD",16,true)
 var venue_label: Label = host._copy(body,str(view.get("venue","LAST SHOW")),22)
 venue_label.name="LiveLastShowVenue"
 var fee: String = "FEE RECEIVED £%d" % int(view.get("fee",0)) if record.has("fee") else "FEE NOT RECORDED"
 var result: String = ("GOOD RECEPTION" if bool(view.get("success",false)) else "A TOUGH NIGHT") if record.has("success") else "OUTCOME NOT RECORDED"
 var fee_label: Label = host._copy(body,fee+"  •  "+result,16)
 fee_label.name="LiveLastShowFee"
 var facts: PackedStringArray = []
 if record.has("day"):
  facts.append("RECORDED DAY %d" % int(record["day"]))
 if record.has("originals_played"):
  facts.append("%d ORIGINALS" % int(record["originals_played"]))
 if not facts.is_empty():
  var facts_label: Label = host._copy(body,"  •  ".join(facts),14,true)
  facts_label.name="LiveLastShowFacts"
 if record.has("promoter_terms"):
  var terms_id: String = str(record["promoter_terms"])
  var terms: Dictionary = Promoter.OFFERS.get(terms_id,{})
  var terms_label: Label = host._copy(body,"AGREEMENT  /  "+str(terms.get("label",terms_id)),14,true)
  terms_label.name="LiveLastShowTerms"
 if record.has("session_fee") and int(record["session_fee"])>0:
  host._copy(body,"SESSION DRUMMER FEE £%d" % int(record["session_fee"]),14,true)
 if record.has("travel_cost"):
  # Original history records the plan tariff; at low hometown cash the actual
  # debit can be smaller. Do not label this as exact spending or net profit.
  host._copy(body,"RECORDED TRAVEL TARIFF £%d" % int(record["travel_cost"]),14,true)
 var review: Dictionary = Reviews.latest(state)
 if not review.is_empty():
  var headline: Label = host._copy(body,str(review.get("headline","SHOW REPORT")),20)
  headline.name="LiveReviewHeadline"
  var response: Label = host._copy(body,str(review.get("body","")),16)
  response.name="LiveReviewBody"
  var confidence: Dictionary = Reviews.eligibility(state,"local","guarantee")
  var recovery: Label = host._copy(body,str(confidence.get("recovery","")),16,true)
  recovery.name="LiveReviewRecovery"


static func dock(host, parent: Node, _compact: bool) -> void:
 var state: Dictionary = host.game.career
 _sync_context(host,state)
 var phase: String = str(Night.stage(state).get("phase","none"))
 var review_status: Label = C.label("",16)
 review_status.name="LiveReviewStatus"
 review_status.visible=false
 parent.add_child(review_status)
 var commitment: Label = C.label("",16)
 commitment.name="LiveCommitment"
 parent.add_child(commitment)
 var caption: String = ""
 var callback: Callable
 match phase:
  "preparation":
   caption="PREPARE IN THE PRACTICE ROOM  ›"
   callback=host._practice.bind("")
  "arrival":
   caption="ARRIVE AT THE VENUE  ›"
   callback=host._commit_live.bind("advance")
  "soundcheck":
   caption="FINISH SOUNDCHECK  ›"
   callback=func() -> void:
    host._commit_live("soundcheck",str(host.live_approach))
  "stage":
   caption="TAKE THE STAGE  ›"
   callback=host._ask_live_confirmation.bind("perform")
  "overdue":
   caption="RESOLVE MISSED SHOW  ›"
   callback=host._commit_live.bind("expire")
  _:
   # Read the CURRENT free plan on the actual click. Binding values here would
   # silently use stale terms after an in-place offer/session selection.
   caption="CONFIRM HOMETOWN BOOKING  ›"
   callback=func() -> void:
    host._commit_live("book",str(host.live_offer),bool(host.live_hire_session))
 var main: Button = host._button(caption,"LiveMainAction",callback,true)
 parent.add_child(main)
 refresh_plans(host)


static func refresh_plans(host) -> void:
 var state: Dictionary = host.game.career
 _sync_context(host,state)
 var booking: Dictionary = Calendar.pending(state)
 var phase: String = str(Night.stage(state).get("phase","none"))
 var main: Button = host.find_child("LiveMainAction",true,false) as Button
 var commitment: Label = host.find_child("LiveCommitment",true,false) as Label
 if booking.is_empty():
  var hire: bool = bool(host.live_hire_session)
  var offer_id: String = str(host.live_offer)
  var eligible: Dictionary = Live.booking_eligibility(state,hire,offer_id)
  var review_status: Label = host.find_child("LiveReviewStatus",true,false) as Label
  var confidence: Dictionary = Reviews.eligibility(state,"local","guarantee")
  if review_status!=null:
   review_status.visible=not bool(confidence.get("ok",false))
   review_status.text=str(eligible.get("message","")) if offer_id=="guarantee" or not bool(confidence.get("restricted",false)) else "GUARANTEES PAUSED  /  Win a hometown show to restore them."
  var valid_plan: bool = Promoter.OFFERS.has(offer_id) and (not hire or offer_id=="standard")
  for id in OFFER_IDS:
   var button: Button = host.find_child("LiveOffer_"+str(id),true,false) as Button
   if button!=null:
    var selected: bool = offer_id==str(id)
    button.text=("✓  " if selected else "")+str(Promoter.OFFERS[id]["label"])
    button.set_pressed_no_signal(selected)
    button.disabled=bool(host.busy) or (hire and str(id)!="standard")
    button.tooltip_text="Session fallback uses the standard offer." if hire and str(id)!="standard" else str(Promoter.OFFERS[id]["description"])
  var description: Label = host.find_child("LiveOfferDescription",true,false) as Label
  if description!=null:
   description.text=str(Promoter.OFFERS[offer_id]["description"])
  var session: Button = host.find_child("LiveSessionDrummerAction",true,false) as Button
  if session!=null:
   var normal: Dictionary = Live.booking_eligibility(state,false)
   session.set_pressed_no_signal(hire)
   session.text=("✓  " if hire else "")+"SESSION DRUMMER  •  £25"
   session.disabled=bool(host.busy) or (not hire and not bool(normal.get("session_available",false)))
   var hint: Label = host.find_child("LiveSessionHint",true,false) as Label
   if hint!=null and not bool(normal.get("session_available",false)) and not hire:
    var session_check: Dictionary = Live.booking_eligibility(state,true)
    hint.text=str(session_check.get("message","Session booking unavailable."))
  var lineup: Label = host.find_child("LiveEligibility",true,false) as Label
  if lineup!=null:
   lineup.text=("SESSION DRUMMER SELECTED" if hire else "%d ACTIVE MUSICIANS  •  LINEUP READY" % int(eligible.get("active",0))) if bool(eligible.get("ok",false)) and valid_plan else str(eligible.get("message","Choose the standard offer for the session fallback."))
   if not valid_plan:
    lineup.text="The session fallback uses the standard promoter offer."
  if main!=null:
   main.disabled=bool(host.busy) or not bool(eligible.get("ok",false)) or not valid_plan
  if commitment!=null:
   commitment.text="DAY %d  •  £0 NOW" % (int(state.get("tour_day",1))+Calendar.LEAD_DAYS)
   if hire:
    commitment.text+="  •  SESSION £25 AT SHOW"
  _reveal_focused_offer(host)
 else:
  for id in APPROACH_IDS:
   var button: Button = host.find_child("LiveApproach_"+str(id),true,false) as Button
   if button!=null:
    var selected: bool = str(host.live_approach)==str(id)
    button.text=("✓  " if selected else "")+str(Gigs.APPROACHES[id]["label"])
    button.set_pressed_no_signal(selected)
    button.disabled=bool(host.busy)
  var description: Label = host.find_child("LiveApproachDescription",true,false) as Label
  if description!=null:
   var approach: Dictionary = Gigs.APPROACHES[str(host.live_approach)]
   description.text="MODIFIERS  /  QUALITY %+d  •  FAN BONUS %+d  •  TENSION %+d" % [int(approach["quality"]),int(approach["fan_bonus"]),int(approach["tension"])]
  if main!=null:
   main.disabled=bool(host.busy)
  if commitment!=null:
   match phase:
    "preparation": commitment.text="SHOW DAY %d  •  %d DAYS TO PREPARE" % [int(booking.get("day",0)),int(booking.get("day",0))-int(state.get("tour_day",1))]
    "arrival": commitment.text="ARRIVAL  •  NO TIME OR CASH SPENT"
    "soundcheck": commitment.text="SET CHOICE  •  NO TIME OR CASH SPENT"
    "stage": commitment.text="PERFORMANCE  •  SHOW DAY AND SETTLEMENT"
    "overdue": commitment.text="MISSED DATE  •  NO PERFORMANCE PAYOUT"


static func _reveal_focused_offer(host) -> void:
 # The fixed reason can resize the viewport without changing native focus.
 # Footer wrapping may finish after process_frame. Observe rendered layout,
 # then reveal the current native focus without rebuilding any controls.
 var previous: String = ""
 for attempt in range(6):
  await RenderingServer.frame_post_draw
  if not is_instance_valid(host) or not host.is_inside_tree():return
  var scroll: ScrollContainer = host.find_child("CareerScroll",true,false) as ScrollContainer
  var focused: Control = host.get_viewport().gui_get_focus_owner()
  if scroll==null:return
  if focused==null:continue
  if not str(focused.name).begins_with("LiveOffer_") or not scroll.is_ancestor_of(focused):return
  var status: Label = host.find_child("LiveReviewStatus",true,false) as Label
  var signature: String = str(scroll.get_global_rect())+"|"+str(focused.get_global_rect())+"|"+str(scroll.get_v_scroll_bar().page)
  if status!=null:signature+="|"+str(status.get_global_rect())
  if signature==previous:
   scroll.ensure_control_visible(focused)
   return
  previous=signature
