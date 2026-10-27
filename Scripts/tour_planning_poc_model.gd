extends RefCounted
## Sprint 03: deterministic, SAVE-INDEPENDENT itinerary prototype model.
## The prices, wear and rest deltas come directly from TourItinerary/UKGigCircuit.
## A confirmed plan is a booking intention, NOT a completed show or charged expense.
const Itinerary = preload("res://Scripts/tour_itinerary.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")
const Gear = preload("res://Scripts/gear_shop.gd")

const VENUES := ["bristol", "cardiff", "birmingham"]

static func sample_state() -> Dictionary:
 return {
  "cash":135, "van_health":30, "tour_day":5, "reputation":44, "fans":88,
  "readiness":66, "morale":64, "tension":9,
  "members":[
   {"name":"Alex","role":"guitar","life_status":"active","fatigue":18,"candidate_id":"demo-guitar"},
   {"name":"Jo","role":"drums","life_status":"active","fatigue":20,"candidate_id":"demo-drums"}
  ],
  "owned_equipment":["amp"],
  "gear_records":{"amp":{"condition":74,"holder_index":0,"holder_name":"Alex","holder_role":"guitar","holder_id":"demo-guitar","provenance":"Sample second-hand purchase"}},
  "booked_show":{}, "gig_history":[]
 }

static func options(state: Dictionary, venue_id: String) -> Array:
 if not VENUES.has(venue_id):
  return []
 var venue := Circuit.get_venue(venue_id)
 if venue.is_empty() or not Circuit.available(int(state.get("reputation",0)),int(state.get("fans",0))).has(venue):
  return []
 return Itinerary.choices(state,venue_id)

static func preview(state: Dictionary, venue_id: String, plan_id: String, van_secured: bool) -> Dictionary:
 var venue := Circuit.get_venue(venue_id)
 if not VENUES.has(venue_id) or not options(state,venue_id).size():
  return {"ok":false,"message":"The promoter has not offered that venue."}
 var checked := Itinerary.validate(state,venue_id,plan_id)
 if not bool(checked.get("ok",false)):
  return checked
 if not van_secured:
  return {"ok":false,"message":"Secure the van load before confirming this journey."}
 var plan: Dictionary = checked["plan"]
 var gear: Dictionary = Gear.record(state,"amp")
 return {
  "ok":true, "venue":venue.duplicate(true), "plan":plan.duplicate(true),
  "cash":int(state.get("cash",0)),
  "cash_after_costs":int(state.get("cash",0))-int(plan["total_cost"]),
  "van_after":int(state.get("van_health",0))-int(plan["van_wear"]),
  "fatigue_delta":int(plan["fatigue_delta"]),
  "morale_delta":int(plan["morale_delta"]),
  "quality_bonus":int(plan["quality_bonus"]),
  "gear_condition":int(gear.get("condition",-1)),
  "message":"Illustrative band state; costs are in-game tariffs, not road distances or real quotes."
 }

static func commit(state: Dictionary, venue_id: String, plan_id: String, van_secured: bool) -> Dictionary:
 var booking: Dictionary = state.get("booked_show",{})
 if bool(booking.get("plan_confirmed",false)):
  return {"ok":false,"message":"A journey is already confirmed. No second booking or charge."}
 var checked := preview(state,venue_id,plan_id,van_secured)
 if not bool(checked.get("ok",false)):
  return checked
 var next := state.duplicate(true)
 next["booked_show"] = {
  "venue_id":venue_id, "day":int(state.get("tour_day",1))+2,
  "travel_plan":plan_id, "plan_confirmed":true
 }
 # Deliberately do NOT call Circuit.play or Itinerary.apply_after_show:
 # those are authoritative show settlement, not planning. No day/cash/wear change.
 return {"ok":true,"state":next,"preview":checked,"message":"Itinerary confirmed in this isolated demo. No show performed or money spent."}
