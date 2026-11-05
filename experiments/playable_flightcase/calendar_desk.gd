extends RefCounted
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")
const Dates = preload("res://experiments/playable_flightcase/career_dates.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")
## Read-only ordinal career calendar. No resolver, expiry, IO or save calls.
const FUTURE_DAYS := 14
const RECENT_NOTES := 5

static func _day(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=1.0 and float(value)<=2147483647.0

static func summary(career: Dictionary) -> Dictionary:
 var issues: Array[String]=[]
 var raw_today: Variant=career.get("tour_day",1)
 var today_valid: bool=_day(raw_today)
 var today: int=int(raw_today) if today_valid else 0
 if not today_valid:issues.append("The current saved day cannot be read. No date has been invented.")
 var booking: Dictionary={"present":false,"valid":true,"day":0,"venue":"","city":"","status":"none","days_until":0}
 var raw_booking: Variant=career.get("booked_show",{})
 if not raw_booking is Dictionary:
  booking["present"]=true
  booking["valid"]=false
  booking["status"]="invalid"
  issues.append("The saved booking cannot be read safely. It has not been changed.")
 elif not raw_booking.is_empty():
  booking["present"]=true
  var date_valid: bool=_day(raw_booking.get("day",0))
  var words_valid: bool=true
  for field in ["venue","city"]:
   var value: Variant=raw_booking.get(field,"")
   if value is String:
    booking[field]=value
   else:
    words_valid=false
    issues.append("The saved booking "+field+" cannot be read safely.")
  booking["valid"]=date_valid and words_valid and today_valid
  if date_valid:booking["day"]=int(raw_booking["day"])
  if not date_valid:issues.append("The saved show date cannot be read. No appointment date has been invented.")
  if bool(booking["valid"]):
   booking["days_until"]=int(booking["day"])-today
   booking["status"]="upcoming" if int(booking["day"])>today else ("due" if int(booking["day"])==today else "overdue")
  else:
   booking["status"]="invalid"
 var days: Array=[]
 if today_valid:
  for offset in range(FUTURE_DAYS+1):
   var number: int=today+offset
   days.append({"day":number,"today":offset==0,"booking":bool(booking["present"]) and bool(booking["valid"]) and int(booking["day"])==number})
 var notes: Array=[]
 var raw_journal: Variant=career.get("career_journal",[])
 if not raw_journal is Array:
  issues.append("The saved notes cannot be read safely. They have not been changed.")
 else:
  # Preserve saved order. Journal entries are narrative notes, not a complete
  # appointment ledger; same-day notes/IDs may legitimately repeat.
  for index in range(raw_journal.size()-1,maxi(-1,raw_journal.size()-81),-1):
   var raw: Variant=raw_journal[index]
   if not raw is Dictionary:
    issues.append("A saved note could not be read and is not displayed.")
    continue
   var entry: Dictionary={"day":0,"title":"SAVED NOTE","text":"","kind":"note"}
   if raw.has("day"):
    if _day(raw["day"]):entry["day"]=int(raw["day"])
    else:issues.append("A saved note has no readable day; it is shown without a date.")
   for field in ["title","text","kind"]:
    if not raw.has(field):continue
    if raw[field] is String:entry[field]=raw[field]
    else:issues.append("A saved note has unreadable "+field+"; only its readable fields are shown.")
   notes.append(entry)
   if notes.size()>=RECENT_NOTES:break
 var result: Dictionary={"today":today,"today_valid":today_valid,"booking":booking,"days":days,"notes":notes,"issues":issues}
 if Booking.modern(career):
  var trip: Dictionary={"present":true,"valid":false}
  var valid: Dictionary=Booking.validate(career)
  if not bool(valid.get("ok",false)) or not today_valid:
   issues.append(str(valid.get("message","The saved trip needs validation.")))
   booking["valid"]=false
   booking["status"]="invalid"
   for row in days:row["booking"]=false
  else:
   var t: Dictionary=Booking.terms(career)
   var start: int=int(t["day"]);var count: int=int(t["tariff"]["duration"]);var next: int=int(t["next_available_day"])
   trip={"present":true,"valid":true,"start_day":start,"last_reserved_day":start+count-1,"next_available_day":next,"duration":count,"travel_plan":str(t["travel_plan"])}
   var horizon: int=mini(Booking.MAX_DAY,today+FUTURE_DAYS)
   var upcoming: bool=start>=today
   if upcoming:horizon=maxi(horizon,next)
   var extended: Array=[]
   for number in range(today,horizon+1):
    extended.append({"day":number,"today":number==today,"booking":number==start,"trip_start":upcoming and number==start,"trip_reserved":upcoming and number>start and number<next,"next_available":upcoming and number==next})
   result["days"]=extended
   trip["extended"]=horizon>mini(Booking.MAX_DAY,today+FUTURE_DAYS)
  result["trip"]=trip
 return result

static func _copy(owner, parent: Node, text: String, node_name: String="", points: int=16, muted: bool=false) -> Label:
 var label: Label=owner._copy(parent,text,points,muted)
 if not node_name.is_empty():label.name=node_name
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.focus_mode=Control.FOCUS_NONE
 return label

static func render(owner, parent: Node, compact: bool) -> void:
 var data: Dictionary=summary(owner.game.career)
 var clock: Dictionary=Dates.inspect(owner.game.career)
 if clock.ok and clock.exists and data.today_valid and not Dates.info(owner.game.career,int(data.today)).is_empty():
  _render_dated(owner,parent,compact,data)
  return
 var booking: Dictionary=data["booking"]
 var body: VBoxContainer=owner._paper(parent,compact)
 body.name="CalendarSheet"
 _copy(owner,body,"YOUR BAND CALENDAR","CalendarTitle",26)
 _copy(owner,body,"TODAY  /  DAY %d" % int(data["today"]) if bool(data["today_valid"]) else "TODAY  /  DAY NOT RECORDED","CalendarToday",20)
 _copy(owner,body,"Career days, not real-world dates. Viewing the calendar never advances time.","CalendarExplanation",16,true)
 if not clock.ok:_copy(owner,body,str(clock.message),"CalendarClockWarning")
 elif not clock.exists:
  _copy(owner,body,"Put this career on a dated calendar when you agree the band's working week.","CalendarStartProposal")
  body.add_child(owner._button("PLAN OUR WEEK · FREE","CalendarPlanWeekAction",owner._open_situation))
 var booked: VBoxContainer=owner._box(4)
 booked.name="CalendarBooking"
 booked.mouse_filter=Control.MOUSE_FILTER_PASS
 body.add_child(booked)
 var status: String=str(booking["status"])
 if status=="none":
  _copy(owner,booked,"NO SHOW CURRENTLY BOOKED","CalendarStatus",20)
 elif status=="invalid":
  _copy(owner,booked,"SAVED BOOKING NEEDS REVIEW","CalendarStatus",20)
  _copy(owner,booked,"The saved booking is retained. Its date is not shown as an appointment.","CalendarBookingWarning")
 else:
  var headline: String="UPCOMING SHOW"
  if status=="due":headline="SHOW DAY  /  DUE TODAY"
  elif status=="overdue":headline="OVERDUE SHOW  /  SAVED BOOKING"
  _copy(owner,booked,headline,"CalendarStatus",20)
  _copy(owner,booked,str(booking["venue"]) if not str(booking["venue"]).is_empty() else "Venue not recorded","CalendarBookingVenue",20)
  _copy(owner,booked,str(booking["city"]) if not str(booking["city"]).is_empty() else "City not recorded","CalendarBookingCity")
  var date: String="BOOKED FOR DAY %d" % int(booking["day"])
  if status=="upcoming":date+="  /  %d DAY%s AWAY" % [int(booking["days_until"]),"" if int(booking["days_until"])==1 else "S"]
  _copy(owner,booked,date,"CalendarBookingDay")
  if status=="overdue":_copy(owner,booked,"This saved booking is overdue. Viewing it does not cancel or settle it.","CalendarOverdueNote",16,true)
 var trip: Dictionary=data.get("trip",{})
 if bool(trip.get("valid",false)):
  _copy(owner,booked,"%d CAREER DAYS RESERVED" % int(trip["duration"]),"CalendarTripSpan")
  _copy(owner,booked,"NEXT AVAILABLE DAY %d · PLANNED" % int(trip["next_available_day"]),"CalendarTripNextDay")
 var grid: GridContainer=GridContainer.new()
 grid.name="CalendarDays"
 grid.columns=3 if compact else 7
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",12)
 body.add_child(grid)
 for raw in data["days"]:
  var row: Dictionary=raw
  var words: String="DAY %d" % int(row["day"])
  if bool(row["today"]):words+="\nTODAY"
  if bool(row.get("trip_start",false)):words+="\nSHOW / TRIP START"
  elif bool(row["booking"]):words+="\nSHOW"
  elif bool(row.get("trip_reserved",false)):words+="\nRESERVED TRIP"
  elif bool(row.get("next_available",false)):words+="\nNEXT AVAILABLE / PLANNED"
  var day: Label=_copy(owner,grid,words,"CalendarDay_"+str(row["day"]),16,not bool(row["today"]) and not bool(row["booking"]))
  day.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  day.custom_minimum_size.y=48
  for flag in ["trip_start","trip_reserved","next_available"]:day.set_meta(flag,bool(row.get(flag,false)))
 _copy(owner,body,"Your next fortnight, including the full booked trip." if bool(trip.get("extended",false)) else ("Today and the next 14 career days. Your actual show and agreed trip span are marked." if bool(trip.get("valid",false)) else "Today and the next 14 career days. Only the actual saved show booking is marked; other days have no appointment recorded here."),"CalendarGridNote",16,true)
 if not data["issues"].is_empty():
  var warnings: VBoxContainer=owner._paper(parent,compact)
  warnings.name="CalendarValidation"
  _copy(owner,warnings,"SAVED DATA TO REVIEW","CalendarValidationTitle",20)
  for issue in data["issues"]:_copy(owner,warnings,str(issue))
 var saved: VBoxContainer=owner._paper(parent,compact)
 saved.name="CalendarSavedNotes"
 _copy(owner,saved,"RECENT SAVED NOTES","CalendarNotesTitle",20)
 _copy(owner,saved,"The latest five readable notes, newest saved first. Booking notes record when arrangements were made; they are not additional future appointments.","CalendarNotesExplanation",16,true)
 var notes: Array=data["notes"]
 if notes.is_empty():_copy(owner,saved,"No saved notes yet.","CalendarEmptyNotes")
 for index in range(notes.size()):
  var note: Dictionary=notes[index]
  var entry: VBoxContainer=owner._box(4)
  entry.name="CalendarNote_"+str(index)
  entry.mouse_filter=Control.MOUSE_FILTER_PASS
  saved.add_child(entry)
  _copy(owner,entry,"DAY %d" % int(note["day"]) if int(note["day"])>0 else "DAY NOT RECORDED","CalendarNoteDay_"+str(index),16,true)
  _copy(owner,entry,str(note["title"]),"CalendarNoteTitle_"+str(index),18)
  _copy(owner,entry,str(note["text"]),"CalendarNoteText_"+str(index))

static func _event_source(career: Dictionary) -> Dictionary:
 var core: Dictionary=Core.validate(career)
 var booking: Dictionary=Booking.validate(career)
 var memory: Dictionary=Booking.memory(career) if booking.ok else {}
 var history: Array=career.get("gig_history",[]) if career.get("gig_history",[]) is Array else []
 return {"people":Core.members(career) if core.ok else [],"plans":core.core.plans if core.ok else [],"records":memory.get("records",[]),"first_booking":booking.ok and int(memory.get("sequence",0))==1 and memory.get("records",[]).is_empty() and career.has("gig_history") and history.is_empty(),"legacy":history,"availability_ok":bool(core.ok)}

static func day_events(data: Dictionary, source: Dictionary, day: int) -> Array:
 var result: Array=[]
 var booking: Dictionary=data.booking
 if booking.present and booking.valid and int(booking.day)==day:
  result.append({"kind":"show","text":("FIRST SHOW · BOOKED" if source.first_booking else "BOOKED SHOW")+"\n"+str(booking.venue)+" · "+str(booking.city)})
 var trip: Dictionary=data.get("trip",{})
 if trip.get("valid",false):
  if day>int(trip.start_day) and day<=int(trip.last_reserved_day):result.append({"kind":"travel","text":"RESERVED FOR THE BOOKED TRIP"})
  if day==int(trip.next_available_day):result.append({"kind":"return","text":"NEXT AVAILABLE · PLANNED RETURN"})
 for person in source.people:
  if person.active and Core._shift(person.context,day):result.append({"kind":"work","text":"WORK EVENING · "+str(person.name)})
 for plan in source.plans:
  if int(plan.day)==day:result.append({"kind":"rehearsal","text":"REHEARSAL · "+str(plan.status).to_upper()+"\nEVENING · agreed band participants"})
 for record in source.records:
  if not record is Dictionary or not record.get("terms") is Dictionary:continue
  var terms: Dictionary=record.terms
  if not Booking.terms_valid(terms):continue
  var name: String=str(terms.venue_snapshot.get("venue","Saved venue"))
  if int(terms.day)==day:
   var kind: String=str(record.get("kind",""))
   var title: String="SHOW PLAYED" if kind=="completed" else ("SHOW · CANCELLED" if kind=="cancelled" else "SHOW · MISSED")
   result.append({"kind":"show_memory","text":title+"\n"+name})
  if record.get("kind")=="completed":
   if _day(record.get("day")) and int(record.day)==day and int(record.day)!=int(terms.day):result.append({"kind":"return","text":"RETURNED FROM THE SHOW · "+name})
 for record in source.legacy:
  if not record is Dictionary or not _day(record.get("day")):continue
  if int(record.day)==day:
   var venue: String=str(record.get("venue","Saved venue")) if record.get("venue","") is String else "Saved venue"
   result.append({"kind":"legacy_memory","text":"COMPLETED / RETURNED · "+venue+"\nOriginal show date was not recorded here."})
 return result

static func _light(parent: Node, words: String, name: String, points: int=16) -> Label:
 var label: Label=C.label(words,points)
 label.name=name
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 parent.add_child(label)
 return label

static func _render_dated(owner, parent: Node, compact: bool, data: Dictionary) -> void:
 var career: Dictionary=owner.game.career
 var today: int=int(data.today)
 var cursor: int=today if int(owner.calendar_cursor)==0 else int(owner.calendar_cursor)
 if Dates.info(career,cursor).is_empty():cursor=today
 var date: Dictionary=Dates.info(career,cursor)
 var source: Dictionary=_event_source(career)
 var header: VBoxContainer=owner._paper(parent,compact)
 header.name="CalendarSheet"
 _copy(owner,header,str(date.month_name)+" "+str(date.year),"CalendarTitle",26)
 _copy(owner,header,"TODAY · "+Dates.caption(career,today),"CalendarToday",18)
 _copy(owner,header,"Your agreed career dates. Looking ahead never uses a day.","CalendarExplanation",16,true)
 if data.booking.present and data.booking.valid:
  _copy(owner,header,("SAVED SHOW OVERDUE" if data.booking.status=="overdue" else ("SHOW DUE TODAY" if data.booking.status=="due" else "NEXT SHOW"))+" · "+str(data.booking.venue),"CalendarStatus",18)
  _copy(owner,header,Dates.caption(career,int(data.booking.day)),"CalendarBookingDay",16)
 else:_copy(owner,header,"NO SHOW BOOKED" if not data.booking.present else "SAVED BOOKING NEEDS REVIEW","CalendarStatus",18)
 var nav: HBoxContainer=HBoxContainer.new()
 nav.add_theme_constant_override("separation",6)
 parent.add_child(nav)
 nav.add_child(owner._button("‹","CalendarPrevious",owner._calendar_shift.bind(-1)))
 nav.add_child(owner._button("TODAY","CalendarTodayAction",owner._calendar_today))
 nav.add_child(owner._button("›","CalendarNext",owner._calendar_shift.bind(1)))
 var modes: HBoxContainer=HBoxContainer.new()
 modes.add_theme_constant_override("separation",6)
 parent.add_child(modes)
 for mode in ["week","month"]:
  var button: Button=owner._button(str(mode).to_upper(),"CalendarMode_"+str(mode),owner._calendar_set_mode.bind(str(mode)))
  button.toggle_mode=true
  button.set_pressed_no_signal(owner.calendar_mode==mode)
  modes.add_child(button)
 # The grid occupies the available full width, outside the sheet's ink insets.
 # Seven 48px targets plus six 2px gaps fit the native 390px phone composition.
 var grid: GridContainer=GridContainer.new()
 grid.name="CalendarDatedGrid"
 grid.columns=7
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.mouse_filter=Control.MOUSE_FILTER_PASS
 grid.add_theme_constant_override("h_separation",2)
 grid.add_theme_constant_override("v_separation",4)
 parent.add_child(grid)
 for index in range(7):_light(grid,Core.WEEKDAYS[index],"CalendarWeekday_"+str(index),16)
 var cells: Array=Dates.cells(career,cursor,str(owner.calendar_mode))
 for cell in cells:
  var day: int=int(cell.day)
  var events: Array=day_events(data,source,day) if cell.supported else []
  var words: String=str(cell.date)+( "\n•" if not events.is_empty() else "")
  var button: Button=owner._button(words,"CalendarDate_"+str(day),owner._calendar_select.bind(day))
  button.toggle_mode=true
  button.set_pressed_no_signal(day==cursor)
  button.disabled=owner.busy or not cell.supported
  button.set_meta("career_day",day)
  button.set_meta("appointment_events",events.duplicate(true))
  button.set_meta("today",day==today)
  button.tooltip_text=Dates.caption(career,day) if cell.supported else "Before the agreed career start"
  if day==today:button.tooltip_text="TODAY · "+button.tooltip_text
  for event in events:button.tooltip_text+="\n"+str(event.text)
  grid.add_child(button)
 var selected: VBoxContainer=owner._paper(parent,compact)
 selected.name="CalendarSelectedDay"
 _copy(owner,selected,Dates.caption(career,cursor),"CalendarSelectedDate",20)
 var events: Array=day_events(data,source,cursor)
 if events.is_empty():_copy(owner,selected,"No appointment or work clash recorded for this evening.","CalendarEmptyDay")
 for index in range(events.size()):
  var row: Dictionary=events[index]
  _copy(owner,selected,str(row.text),"CalendarEvent_"+str(index),18)
 if not source.availability_ok:_copy(owner,selected,"Saved availability needs compatible review. No free evening has been assumed.","CalendarAvailabilityWarning")
 if not data.issues.is_empty():
  for issue in data.issues:_copy(owner,selected,str(issue),"",16)
 var next: VBoxContainer=owner._paper(parent,compact)
 _copy(owner,next,"NEXT IN YOUR BAND WEEK","CalendarNextTitle",20)
 var writing: Dictionary=Core.inspect_writing(career)
 if writing.ok:
  if int(writing.next_full_day)>0:_copy(owner,next,"NEXT EVENING WITHOUT A RECORDED WORK CLASH\n"+Dates.caption(career,int(writing.next_full_day)),"CalendarNextBandEvening")
  else:_copy(owner,next,"No common evening is recorded in the next fortnight. Review the existing work agreements.","CalendarNoCommonEvening")
 if data.booking.present and data.booking.valid:_copy(owner,next,str(data.booking.venue)+"\n"+Dates.caption(career,int(data.booking.day)),"CalendarNextShow")
 var trip: Dictionary=data.get("trip",{})
 if trip.get("valid",false):_copy(owner,next,"TRIP RESERVED THROUGH "+Dates.caption(career,int(trip.last_reserved_day))+"\nNEXT AVAILABLE · "+Dates.caption(career,int(trip.next_available_day)),"CalendarTripDates")
 next.add_child(owner._button("REVIEW OUR WORKING WEEK ›","CalendarReviewWeekAction",owner._open_situation))
