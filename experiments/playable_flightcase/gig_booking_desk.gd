extends RefCounted
## Free native booking drafts. Owner alone confirms, accounts and saves.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Journey = preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const STAGE := "res://experiments/playable_flightcase/art/opening_stage.png"
const OFFER_COPY := {"standard":"Accept the venue's ordinary arrangement.","guarantee":"Ask the promoter to add £15 to the settled fee.","guestlist":"Accept £10 less from the settled fee to make room for a guest list."}
const OFFER_LABELS := {"standard":"STANDARD TERMS","guarantee":"ASK FOR A GUARANTEE","guestlist":"OFFER A GUEST LIST"}

static func active(host) -> bool:
 return host.game!=null and Calendar.pending(host.game.career).is_empty() and not Journey.locked(host.game.career)

static func _copy(parent: Node, text: String, name: String = "", points: int = 16) -> Label:
 var label: Label=C.label(text,points)
 if not name.is_empty():label.name=name
 parent.add_child(label)
 return label

static func _button(host,parent: Node,text: String,name: String,callback: Callable,selected: bool = false) -> Button:
 var button: Button=host._button(text,name,callback)
 button.custom_minimum_size.y=48
 if name.begins_with("BookingDay_") or name.begins_with("BookingOffer_") or name.begins_with("BookingTrip_") or name=="BookingBackAction":
  preload("res://experiments/playable_flightcase/control_roles.gd").quiet(button)
 if selected:button.add_theme_color_override("font_color",Color("f1be62"))
 parent.add_child(button)
 return button

static func _hero(parent: Node, compact: bool) -> void:
 var art: TextureRect=TextureRect.new()
 art.name="BookingRoomIllustration"
 art.texture=load(STAGE)
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size=Vector2(0,135 if compact else 180)
 art.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(art)

static func render(host,parent: Node,compact: bool) -> void:
 host._sync_booking_draft()
 var options: Dictionary=Booking.options(host.game.career)
 var expected: Dictionary=host.booking_expected
 if not bool(options.get("ok",false)):
  _copy(parent,str(options.get("message","The booking record needs attention.")))
  return
 if expected!=Booking.expected(host.game.career):
  _copy(parent,"The band changed while you were looking. Review fresh rooms and dates before booking.")
  _button(host,parent,"REVIEW CURRENT ROOMS","BookingRestartAction",host._open_booking.bind({}))
  return
 var step: String=str(host.booking_step)
 var draft: Dictionary=host.booking_draft
 var generation: int=int(host._render_generation)
 _copy(parent,str({"rooms":"FIND YOUR NEXT ROOM","date":"YOUR SHOW AGREEMENT","trip":"YOUR SHOW AGREEMENT","review":"YOUR SHOW AGREEMENT"}.get(step,"BOOK A SHOW")),"BookingHeading",24)
 if not str(host.notice).is_empty():_copy(parent,str(host.notice),"BookingNotice")
 if step=="rooms":
  _hero(parent,compact)
  var grid: GridContainer=GridContainer.new()
  grid.columns=1 if compact else 2
  grid.add_theme_constant_override("h_separation",12)
  grid.add_theme_constant_override("v_separation",12)
  parent.add_child(grid)
  for room in options["rooms"]:
   var frame: PanelContainer=Kit.frame("flightcase","inset")
   frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   grid.add_child(frame)
   var card: VBoxContainer=VBoxContainer.new()
   card.add_theme_constant_override("separation",6)
   frame.add_child(card)
   _copy(card,str(room["city"]),"",16)
   _copy(card,str(room["venue"]),"",21)
   _copy(card,"Listed fee £%d · %d career day(s)" % [int(room["listed_fee"]),int(room["duration"])])
   _copy(card,str(room["message"]))
   var action: Button=_button(host,card,"TALK ABOUT THIS ROOM  ›","BookingVenue_"+str(room["id"]),host._booking_select.bind("venue_id",str(room["id"]),expected.duplicate(true),generation))
   action.disabled=bool(host.busy) or not bool(room["available"])
 else:
  _copy(parent,_room_name(options,draft),"BookingReviewVenue",22)
  _copy(parent,"Choose the date, trip and terms here. Nothing is booked until you confirm.","BookingDraftExplanation")
  _copy(parent,"SHOW DAY","",18)
  var days:=HFlowContainer.new();days.add_theme_constant_override("h_separation",4);days.add_theme_constant_override("v_separation",4);parent.add_child(days)
  if int(options["first_day"])>0:
   for day in range(int(options["first_day"]),int(options["last_day"])+1):
    _button(host,days,"DAY %d" % day,"BookingDay_%d" % day,host._booking_select.bind("day",day,expected.duplicate(true),generation),int(draft.get("day",0))==day)
  for room in options["rooms"]:
   if room["id"]!=draft.get("venue_id"):continue
   _copy(parent,"THE TRIP","",18)
   for trip in room["trips"]:
    if room["trips"].size()==1:
     _copy(parent,str(trip["label"])+" AFTER THE SHOW","BookingOnlyTrip")
    else:
     var action: Button=_button(host,parent,str(trip["label"]),"BookingTrip_"+str(trip["id"]),host._booking_select.bind("travel_plan",str(trip["id"]),expected.duplicate(true),generation),draft.get("travel_plan")==trip["id"])
     action.disabled=bool(host.busy) or not bool(trip["available"])
    _copy(parent,"Transport £%d · room £%d · %d career day(s)" % [int(trip["transport"]),int(trip["accommodation"]),int(trip["duration"])])
  _copy(parent,"PROMOTER TERMS","",18)
  for offer in ["standard","guarantee","guestlist"]:
   _button(host,parent,("● " if draft.get("offer_id")==offer else "○ ")+str(OFFER_LABELS[offer]),"BookingOffer_"+offer,host._booking_select.bind("offer_id",offer,expected.duplicate(true),generation),draft.get("offer_id")==offer)
  _copy(parent,str(OFFER_COPY.get(draft.get("offer_id"),"")),"BookingSelectedTerms")
  if host._booking_session_needed():_copy(parent,"SESSION DRUMMER · £25 AT THE SHOW","BookingSessionCover")
  var prepared: Dictionary=Booking.prepare(host.game.career,draft,expected)
  if prepared.get("ok",false):
   var q: Dictionary=prepared.quote
   _copy(parent,"£0 NOW · £%d trip/session costs at final wrap · %d career day(s) reserved, next available DAY %d. Listed fee £%d; the actual settlement depends on the show and agreed terms." % [int(q.total_cost),int(q.duration),int(q.next_available_day),int(q.listed_fee)],"BookingReviewCommitment")
  else:_copy(parent,str(prepared.get("message","Review this agreement.")),"BookingNotice")

static func _room_name(options: Dictionary,draft: Dictionary) -> String:
 for room in options.get("rooms",[]):
  if room["id"]==draft.get("venue_id"):return "%s · %s" % [room["venue"],room["city"]]
 return "Choose a room"

static func quote_copy(parent: Node,quote: Dictionary) -> void:
 _copy(parent,"%s · %s" % [quote["venue"],quote["city"]],"BookingReviewVenue",22)
 _copy(parent,"SHOW / TRIP START · DAY %d" % int(quote["day"]),"BookingReviewDate")
 _copy(parent,"%d CAREER DAY(S) RESERVED · NEXT AVAILABLE DAY %d" % [int(quote["duration"]),int(quote["next_available_day"])],"BookingReviewNextDay")
 _copy(parent,"Transport £%d · room £%d · session cover £%d" % [int(quote["transport"]),int(quote["accommodation"]),int(quote["session"])],"BookingReviewCosts")
 _copy(parent,"£0 now. Agreed trip costs £%d at final wrap. The listed show fee is £%d; the actual settlement depends on the show and promoter terms." % [int(quote["total_cost"]),int(quote["listed_fee"])],"BookingReviewCommitment")
 _copy(parent,str(OFFER_LABELS.get(quote["offer_id"],"")))

static func dock(host,parent: Node) -> void:
 if str(host.booking_step)!="rooms":
  var prepared: Dictionary=Booking.prepare(host.game.career,host.booking_draft,host.booking_expected)
  var action: Button=_button(host,parent,"CONFIRM THIS BOOKING  ›","BookingCommitAction",host._ask_booking_commit.bind(int(host._render_generation)))
  action.disabled=bool(host.busy) or not prepared.get("ok",false)
 _button(host,parent,"‹ CHOOSE ANOTHER ROOM" if str(host.booking_step)!="rooms" else "‹ BACK","BookingBackAction",host._booking_back.bind(int(host._render_generation)))

static func render_agreement(host,parent: Node,compact: bool,state: Dictionary) -> void:
 var valid: Dictionary=Flow.validate(state)
 if not bool(valid.get("ok",false)):
  _copy(parent,str(valid.get("message","The saved agreement needs attention.")))
  return
 var t: Dictionary=Booking.terms(state)
 var box: VBoxContainer=VBoxContainer.new()
 box.name="BookingSavedAgreement"
 box.add_theme_constant_override("separation",8)
 parent.add_child(box)
 _copy(box,str(t["venue_snapshot"]["venue"]),"BookingAgreementVenue",24)
 _copy(box,str(t["venue_snapshot"]["city"]),"BookingAgreementCity")
 _copy(box,"SHOW / TRIP START · DAY %d" % int(t["day"]),"BookingAgreementDate")
 _hero(box,compact)
 _copy(box,"%d career day(s) reserved · next available DAY %d" % [int(t["tariff"]["duration"]),int(t["next_available_day"])],"BookingAgreementNextDay")
 _copy(box,("Head home after the show" if t["travel_plan"]=="drive_home" else "Stay overnight")+(" · transport up to £%d" if t["venue_snapshot"]["id"]=="local" else " · transport £%d") % int(t["tariff"]["travel"])+" · room £%d" % int(t["tariff"]["accommodation"]),"BookingAgreementTrip")
 if bool(t["session_drummer"]):_copy(box,"Session drummer · £25 at settlement")
 _copy(box,str(OFFER_LABELS[t["offer_id"]]))
 _copy(box,"The trip and show are one saved agreement. Costs and career days settle once at the final wrap.")
 if int(state.get("tour_day",1))>int(t["day"]):_copy(box,"MISSED COMMITMENT · The saved date has passed. Acknowledge it explicitly; viewing does not settle it.","BookingMissedState",20)
 if not str(host.notice).is_empty():_copy(box,str(host.notice))

static func agreement_dock(host,parent: Node,state: Dictionary) -> void:
 var token: Dictionary=Booking.expected(state)
 if int(state.get("tour_day",1))>int(Booking.terms(state).get("day",0)):
  _button(host,parent,"ACKNOWLEDGE MISSED COMMITMENT  ›","BookingAcknowledgeMissedAction",host._ask_booking_missed.bind(token,int(host._render_generation)),true)
 else:
  _button(host,parent,"PREPARE WITH THE BAND  ›","BookingPrepareAction",host._practice.bind(""))
 _button(host,parent,"OPEN THE CALENDAR","BookingCalendarAction",host._navigate.bind("calendar"))
 _button(host,parent,"SHOW OPTIONS","JourneyShowOptionsAction",host._ask_booking_options.bind(token,int(host._render_generation),{}))
