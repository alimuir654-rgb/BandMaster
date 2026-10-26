extends RefCounted
# Pure show-day route. Existing GigNight/Calendar/Gear/Tour remain authoritative.
const GigNight = preload("res://Scripts/gig_night_flow.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const STEPS := ["LOAD THE VAN","ON THE ROAD","VENUE ARRIVAL","SURVEY & SOUNDCHECK","BACKSTAGE / SHOWTIME"]

static func booking_key(state: Dictionary) -> String:
 var booking: Dictionary = Calendar.pending(state)
 if booking.is_empty():
  return ""
 return "%s:%d" % [str(booking.get("venue_id","")),int(booking.get("day",0))]

static func current_step(state: Dictionary) -> int:
 if booking_key(state).is_empty():
  return -1
 var saved = state.get("show_journey_progress",{})
 var step := 0
 if saved is Dictionary and str(saved.get("booking_key","")) == booking_key(state):
  step = clampi(int(saved.get("step",0)),0,4)
 var phase := str(GigNight.stage(state).get("phase","none"))
 if phase == "soundcheck":
  step = maxi(step,3)
 elif phase == "stage":
  step = 4
 return step

static func advance(state: Dictionary) -> Dictionary:
 var booking: Dictionary = Calendar.pending(state)
 if booking.is_empty() or int(booking.get("day",-1)) != int(state.get("tour_day",0)):
  return {"ok":false,"message":"This journey is available on the booked show day."}
 var step := current_step(state)
 if step < 0 or step >= 4:
  return {"ok":false,"message":"There is no further preparation stage."}
 var next := state.duplicate(true)
 if step == 2 or step == 3:
  var progressed: Dictionary = GigNight.advance(next)
  if not bool(progressed.get("ok",false)):
   return progressed
  next = progressed["state"]
 next["show_journey_progress"] = {"booking_key":booking_key(state),"step":step+1}
 return {"ok":true,"state":next}

static func ready_to_perform(state: Dictionary) -> bool:
 return current_step(state) == 4 and bool(GigNight.stage(state).get("can_play",false))
