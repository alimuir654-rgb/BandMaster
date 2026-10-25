extends RefCounted
# Pure, deterministic touring choices. Costs are fictional gameplay tariffs,
# not distance estimates or real accommodation quotes.
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const DRIVE := "drive_home"
const OVERNIGHT := "overnight"

static func choices(state: Dictionary, venue_id: String) -> Array:
 var venue: Dictionary = Gigs.get_venue(venue_id)
 if venue.is_empty():
  return []
 var local := venue_id == "local"
 var travel := int(venue.get("travel",0))
 var wear := 0 if local else int(venue.get("wear",0))
 var cash := int(state.get("cash",0))
 var van := int(state.get("van_health",0))
 var hotel := 20 + 12 * int(venue.get("tier",0))
 var base := {
  "id":DRIVE,
  "label":"DRIVE HOME AFTER THE SHOW" if not local else "LOCAL SHOW / HEAD HOME",
  "description":"No room bill. The late journey adds fatigue." if not local else "A hometown show needs no overnight stop.",
  "travel_cost":travel,
  "accommodation_cost":0,
  "total_cost":travel,
  "van_wear":wear,
  "quality_bonus":0,
  "morale_delta":-2 if not local else 0,
  "fatigue_delta":7 if not local else 0,
  "available":(local or (cash >= travel and van >= wear))
 }
 if local:
  base["total_cost"] = mini(cash,travel)
  return [base]
 var night := {
  "id":OVERNIGHT,
  "label":"BOOK A ROOM / REST BEFORE THE SHOW",
  "description":"Pay for a basic overnight room. The band arrives rested.",
  "travel_cost":travel,
  "accommodation_cost":hotel,
  "total_cost":travel + hotel,
  "van_wear":wear,
  "quality_bonus":5,
  "morale_delta":3,
  "fatigue_delta":-5,
  "available":cash >= travel + hotel and van >= wear
 }
 return [base,night]

static func preview(state: Dictionary, venue_id: String, plan_id: String) -> Dictionary:
 for choice in choices(state,venue_id):
  if str(choice.get("id","")) == plan_id:
   return choice.duplicate(true)
 return {}

static func validate(state: Dictionary, venue_id: String, plan_id: String, session_drummer: bool = false) -> Dictionary:
 var plan: Dictionary = preview(state,venue_id,plan_id)
 if plan.is_empty():
  return {"ok":false,"message":"That journey plan is not available for this venue."}
 var required := int(plan["total_cost"]) + (25 if session_drummer else 0)
 if venue_id != "local" and int(state.get("van_health",0)) < int(plan["van_wear"]):
  return {"ok":false,"message":"Repair the van before committing to this journey."}
 if int(state.get("cash",0)) < required:
  return {"ok":false,"message":"This plan needs £%d in cash for travel, room and any session drummer." % required}
 return {"ok":true,"plan":plan}

static func apply_after_show(state: Dictionary, plan: Dictionary, venue_id: String) -> Dictionary:
 # Call only after a successful Gigs.play. Base travel/van wear was already
 # charged by Gigs.play; deduct accommodation ONCE, never again.
 var next := state.duplicate(true)
 next["cash"] = maxi(0,int(next.get("cash",0))-int(plan.get("accommodation_cost",0)))
 next["morale"] = clampi(int(next.get("morale",0))+int(plan.get("morale_delta",0)),0,100)
 var members: Array = next.get("members",[])
 for member in members:
  if member is Dictionary and str(member.get("life_status","active")) == "active":
   member["fatigue"] = clampi(int(member.get("fatigue",0))+int(plan.get("fatigue_delta",0)),0,100)
 var history: Array = next.get("gig_history",[])
 if not history.is_empty() and history.back() is Dictionary:
  var latest: Dictionary = history.back()
  latest["travel_plan"] = str(plan.get("id",DRIVE))
  latest["travel_cost"] = int(plan.get("travel_cost",0))
  latest["accommodation_cost"] = int(plan.get("accommodation_cost",0))
  latest["van_wear"] = int(plan.get("van_wear",0))
  latest["journey_quality_bonus"] = int(plan.get("quality_bonus",0))
 return next

static func timeline(state: Dictionary) -> Array:
 var booking: Dictionary = state.get("booked_show",{})
 if booking.is_empty():
  return []
 var now := int(state.get("tour_day",1))
 var date := int(booking.get("day",now))
 var result: Array = []
 for day in range(now, date + 1):
  result.append({"day":day,"label":"SHOW NIGHT" if day == date else ("TRAVEL / PREP" if day == date-1 else "REHEARSE / PROMOTE"),"show":day == date})
 return result
