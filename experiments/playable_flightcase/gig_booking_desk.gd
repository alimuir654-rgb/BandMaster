extends RefCounted
## Free native booking drafts. Owner alone confirms, accounts and saves.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Journey = preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
const Encounter=preload("res://experiments/playable_flightcase/promoter_encounter.gd")
const Promoters=preload("res://experiments/playable_flightcase/promoter_profiles.gd")
const Conversation=preload("res://experiments/playable_flightcase/conversation_panel.gd")
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
 if name.begins_with("BookingPitch_") or name.begins_with("BookingOffer_"):
  Poster.choice_style(button);button.toggle_mode=true;button.set_pressed_no_signal(selected)
 elif selected:button.add_theme_color_override("font_color",Color("f1be62"))
 parent.add_child(button)
 preload("res://experiments/playable_flightcase/navigation_bar.gd").minimum(button,host)
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
 _copy(parent,str({"rooms":"FIND YOUR NEXT ROOM","pitch":"MEET THE PROMOTER","terms":"TALK TERMS","agreement":"AGREE THE NIGHT"}.get(step,"BOOK A SHOW")),"BookingHeading",24)
 if not str(host.notice).is_empty():_copy(parent,str(host.notice),"BookingNotice")
 if step=="rooms":
  _hero(parent,compact)
  var grid: GridContainer=GridContainer.new()
  grid.mouse_filter=Control.MOUSE_FILTER_PASS
  grid.columns=1 if compact else 2
  grid.add_theme_constant_override("h_separation",12)
  grid.add_theme_constant_override("v_separation",12)
  parent.add_child(grid)
  for room in options["rooms"]:
   var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",Poster.control_stock(Poster.INK,12))
   # Decorative cards must pass a finger drag to the venue list's scroll.
   frame.mouse_filter=Control.MOUSE_FILTER_PASS
   frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   grid.add_child(frame)
   var card: VBoxContainer=VBoxContainer.new()
   card.mouse_filter=Control.MOUSE_FILTER_PASS
   card.add_theme_constant_override("separation",6)
   frame.add_child(card)
   _copy(card,str(room["city"]),"",16)
   _copy(card,str(room["venue"]),"",21)
   _copy(card,"Listed fee £%d · %d career day(s)" % [int(room["listed_fee"]),int(room["duration"])])
   _copy(card,str(room["message"]))
   var action: Button=_button(host,card,"TALK ABOUT THIS ROOM  ›","BookingVenue_"+str(room["id"]),host._booking_select.bind("venue_id",str(room["id"]),expected.duplicate(true),generation))
   action.disabled=bool(host.busy) or not bool(room["available"])
 else:
  var presence: Node=parent
  if not compact:
   var spread:=HBoxContainer.new();spread.name="BookingConversationSpread";spread.add_theme_constant_override("separation",24);parent.add_child(spread)
   var person:=VBoxContainer.new();person.custom_minimum_size.x=360;spread.add_child(person);presence=person
   var exchange:=VBoxContainer.new();exchange.name="BookingCurrentExchange";exchange.add_theme_constant_override("separation",10);exchange.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spread.add_child(exchange);parent=exchange
  var biography: VBoxContainer=_presence(presence,_room_name(options,draft),str(draft.get("venue_id","")),compact)
  if step=="pitch":
   _dialogue(parent,Encounter.opening(host.game.career,str(draft.venue_id)),str(Promoters.for_venue(str(draft.venue_id)).get("name","Promoter")))
   for pitch in Circuit.PITCHES:
    _button(host,parent,str(Encounter.PITCH_WORDS[pitch]),"BookingPitch_"+str(pitch),host._booking_pitch_select.bind(str(pitch),expected.duplicate(true),generation),host.booking_pitch==pitch)
   var aside:=VBoxContainer.new();aside.visible=false
   var question: Button=_button(host,biography,"What matters to you on a shared bill?","BookingPromoterQuestion",func():pass)
   question.toggle_mode=true;question.toggled.connect(aside.set_visible)
   biography.add_child(aside)
   Conversation.turn(aside,str(Promoters.for_venue(str(draft.venue_id)).get("name","Promoter")),Encounter.aside(str(draft.venue_id)),"BookingPromoterAside")
  elif step=="terms":
   Conversation.turn(parent,"YOU",str(Encounter.PITCH_WORDS.get(host.booking_pitch,"")),"BookingYourPitch",false)
   _dialogue(parent,Encounter.reaction(host.game.career,str(draft.venue_id),host.booking_pitch),str(Promoters.for_venue(str(draft.venue_id)).get("name","Promoter")))
   for offer in ["standard","guarantee","guestlist"]:
    var ask: Button=_button(host,parent,str(Encounter.ASKS[offer]),"BookingOffer_"+offer,host._booking_select.bind("offer_id",offer,expected.duplicate(true),generation),draft.get(Circuit.BILL,{}).get("asked")==offer)
    ask.disabled=bool(host.busy) or (bool(draft.get("session_drummer",false)) and offer!="standard")
   if host._booking_session_needed():_copy(parent,"Session cover needed: standard terms, with £25 drummer cover at the show.","BookingSessionCover")
   else:_copy(parent,"Guarantee: ask for £15 more at settlement. Guest list: £10 less.","BookingTermsPrices")
  elif draft.has(Circuit.BILL):
   var proposal: Dictionary=Circuit.proposal(host.game.career,str(draft.venue_id),host.booking_pitch,str(draft[Circuit.BILL].asked))
   if not proposal.get("ok",false):
    _copy(parent,str(proposal.get("message","Review the offer.")),"BookingNotice")
    return
   Conversation.turn(parent,"YOU",str(Encounter.ASKS.get(str(draft[Circuit.BILL].asked),"")),"BookingYourAsk",false)
   _dialogue(parent,Encounter.agreement(str(draft.venue_id),proposal),str(Promoters.for_venue(str(draft.venue_id)).get("name","Promoter")))
   for room in options["rooms"]:
    if room["id"]==draft.get("venue_id"):_copy(parent,"Listed fee £%d. Actual settlement depends on the show and agreed terms." % int(room["listed_fee"]),"BookingListedFee")
   var bill: Dictionary=draft[Circuit.BILL]
   _copy(parent,("COUNTEROFFER · " if proposal.get("counteroffer",false) else "OFFER · ")+str(OFFER_LABELS[bill.offer_id])+" · "+str(bill.slot).replace("_"," ").to_upper(),"BookingActualOffer",18)
   _button(host,parent,"HIDE THE FULL BILL" if host.booking_bill_open else "WHO ELSE IS PLAYING?","BookingBillToggle",host._booking_toggle_bill.bind(generation))
   if host.booking_bill_open:bill_copy(parent,bill)
   _copy(parent,"WHEN CAN YOU PLAY?","BookingDayHeading",18)
   var days:=GridContainer.new();days.columns=3 if compact else 6
   days.add_theme_constant_override("h_separation",4);days.add_theme_constant_override("v_separation",4);parent.add_child(days)
   if int(options["first_day"])>0:
    for day in range(int(options["first_day"]),int(options["last_day"])+1):
     var action: Button=_button(host,days,"DAY %d" % day,"BookingDay_%d" % day,host._booking_select.bind("day",day,expected.duplicate(true),generation),int(draft.get("day",0))==day)
     action.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   for room in options["rooms"]:
    if room["id"]!=draft.get("venue_id"):continue
    _copy(parent,"GETTING HOME","",18)
    for trip in room["trips"]:
     if room["trips"].size()==1:
      _copy(parent,str(trip["label"])+" AFTER THE SHOW","BookingOnlyTrip")
     else:
      var action: Button=_button(host,parent,str(trip["label"]),"BookingTrip_"+str(trip["id"]),host._booking_select.bind("travel_plan",str(trip["id"]),expected.duplicate(true),generation),draft.get("travel_plan")==trip["id"])
      action.disabled=bool(host.busy) or not bool(trip["available"])
     _copy(parent,"Transport £%d · room £%d · %d career day(s)" % [int(trip["transport"]),int(trip["accommodation"]),int(trip["duration"])])
   if host._booking_session_needed():_copy(parent,"SESSION DRUMMER · £25 AT THE SHOW","BookingSessionCover")

static func _presence(parent: Node,room: String,venue: String,compact: bool) -> VBoxContainer:
 var person: Dictionary=Promoters.for_venue(venue)
 var row:=HBoxContainer.new();row.name="BookingPromoterPresence";row.mouse_filter=Control.MOUSE_FILTER_PASS
 row.add_theme_constant_override("separation",14);parent.add_child(row)
 var photo:=TextureRect.new();photo.name="BookingPromoterPortrait";photo.texture=Promoters.portrait(venue)
 photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 photo.custom_minimum_size=Vector2(132,154) if compact else Vector2(150,210)
 photo.mouse_filter=Control.MOUSE_FILTER_IGNORE;photo.set_meta("promoter_id",str(person.get("id","")));row.add_child(photo)
 var detail:=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.mouse_filter=Control.MOUSE_FILTER_PASS
 detail.add_theme_constant_override("separation",6);row.add_child(detail)
 _copy(detail,str(person.get("name","The promoter")).to_upper(),"BookingPromoterHeading",24)
 _copy(detail,str(person.get("role","Promoter")),"BookingPromoterRole",16)
 _copy(detail,room,"BookingReviewVenue",18)
 var biography:=VBoxContainer.new();biography.visible=false
 var more: Button=Poster.quiet("ABOUT "+str(person.get("name","THE PROMOTER")).to_upper());more.name="BookingAboutPromoter";more.custom_minimum_size.y=48;more.pressed.connect(func():biography.visible=not biography.visible);detail.add_child(more)
 preload("res://experiments/playable_flightcase/navigation_bar.gd").minimum(more,row)
 detail.add_child(biography)
 _copy(biography,str(person.get("detail","")),"BookingPromoterCharacter",16)
 return biography

static func _dialogue(parent: Node,text: String,speaker: String="PROMOTER") -> void:
 var label: Label=Conversation.turn(parent,speaker,text,"BookingPromoterReply")
 label.focus_mode=Control.FOCUS_ALL

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

static func bill_copy(parent: Node,bill: Dictionary) -> void:
 _copy(parent,"TONIGHT'S BILL", "BookingBillHeading",20)
 var lineup: Array=bill.lineup.duplicate();lineup.reverse()
 for index in range(lineup.size()):
  var id: String=str(lineup[index])
  var label: String="YOUR BAND" if id=="player" else str(Circuit.BANDS[id].name)
  _copy(parent,("HEADLINER · " if index==0 else ("OPENING · " if index==lineup.size()-1 else "SUPPORT · "))+label,"BookingBill_"+id,20 if index==0 else 18)
 _copy(parent,"This is a shared night. Your place on the bill and the other bands are saved with the agreement.","",16)

static func dock(host,parent: Node) -> void:
 var step: String=str(host.booking_step)
 if step!="rooms":
  var options: Dictionary=Booking.options(host.game.career)
  var fresh: bool=host.booking_expected==Booking.expected(host.game.career)
  if not options.get("ok",false):
   _copy(parent,str(options.get("message","The saved booking needs review.")),"BookingDockNotice")
  elif not fresh:
   _copy(parent,"The band changed. Review current rooms before discussing the offer.","BookingDockNotice")
   _button(host,parent,"REVIEW CURRENT ROOMS ›","BookingCommitAction",host._open_booking.bind({}))
  elif step=="agreement" and host.booking_draft.has(Circuit.BILL):
   var prepared: Dictionary=Booking.prepare(host.game.career,host.booking_draft,host.booking_expected)
   if prepared.get("ok",false):
    var q: Dictionary=prepared.quote
    _copy(parent,"DAY %d · £0 now · £%d costs at wrap\n%d career day(s) reserved · free DAY %d" % [int(q.day),int(q.total_cost),int(q.duration),int(q.next_available_day)],"BookingReviewCommitment")
   else:_copy(parent,str(prepared.get("message","Review this agreement.")),"BookingDockNotice")
   var action: Button=_button(host,parent,"AGREE THIS NIGHT  ›","BookingCommitAction",host._ask_booking_commit.bind(int(host._render_generation)))
   action.disabled=bool(host.busy) or not prepared.get("ok",false)
  else:
   _copy(parent,"Just talking. No time or money spent.","BookingDockNotice")
   if step=="terms" and host.booking_draft.has(Circuit.BILL):
    _button(host,parent,"RETURN TO THE OFFER ›","BookingReturnOffer",host._booking_go.bind("agreement",int(host._render_generation)))
 var back: String=str({"rooms":"‹ LEAVE THE VENUES","pitch":"‹ ANOTHER ROOM","terms":"‹ CHANGE MY PITCH","agreement":"‹ TALK TERMS AGAIN"}.get(step,"‹ BACK"))
 _button(host,parent,back,"BookingBackAction",host._booking_back.bind(int(host._render_generation)))

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
 if t.has(Circuit.BILL):bill_copy(box,t[Circuit.BILL])
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
