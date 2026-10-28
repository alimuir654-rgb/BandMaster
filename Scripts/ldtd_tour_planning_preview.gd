extends RefCounted
## S04 isolated planning adapter. Source: PR #192 tour_planning_poc_model.gd;
## uses authoritative TourItinerary, UKGigCircuit, GearShop and Calendar.book.
## Confirmation is a future booking, never a performed gig or cash settlement.
const Itinerary = preload("res://Scripts/tour_itinerary.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const VENUES := ["bristol", "cardiff", "birmingham"]

static func sample_state() -> Dictionary:
	return {
		"cash":135, "van_health":30, "tour_day":5, "reputation":44, "fans":88,
		"readiness":66, "morale":64, "tension":9, "songs":3,
		"members":[
			{"name":"Alex","role":"guitar","life_status":"active","fatigue":18,"candidate_id":"demo-guitar"},
			{"name":"Jo","role":"drums","life_status":"active","fatigue":20,"candidate_id":"demo-drums"}
		],
		"owned_equipment":["amp"],
		"gear_records":{"amp":{"condition":74,"holder_index":0,"holder_name":"Alex",
			"holder_role":"guitar","holder_id":"demo-guitar",
			"provenance":"Sample second-hand purchase"}},
		"booked_show":{}, "gig_history":[]
	}

static func options(state: Dictionary, venue_id: String) -> Array:
	if not VENUES.has(venue_id):
		return []
	var venue: Dictionary = Circuit.get_venue(venue_id)
	if venue.is_empty() or not Circuit.available(int(state.get("reputation",0)),int(state.get("fans",0))).has(venue):
		return []
	return Itinerary.choices(state,venue_id)

static func preview(state: Dictionary, venue_id: String, plan_id: String, van_secured: bool) -> Dictionary:
	var booking: Dictionary = state.get("booked_show",{})
	if not booking.is_empty():
		return {"ok":false,"message":"A show is already on the calendar. No duplicate booking."}
	var venue: Dictionary = Circuit.get_venue(venue_id)
	if not VENUES.has(venue_id) or options(state,venue_id).is_empty():
		return {"ok":false,"message":"The promoter has not offered that venue."}
	var checked: Dictionary = Itinerary.validate(state,venue_id,plan_id)
	if not bool(checked.get("ok",false)):
		return checked
	if not van_secured:
		return {"ok":false,"message":"Secure the amp and van load before confirming the route."}
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
		"show_day":int(state.get("tour_day",1))+Calendar.LEAD_DAYS,
		"message":"Preview only. Fictional in-game tariffs, not real road distances or hotel quotes."
	}

static func commit(state: Dictionary, venue_id: String, plan_id: String, van_secured: bool) -> Dictionary:
	var checked: Dictionary = preview(state,venue_id,plan_id,van_secured)
	if not bool(checked.get("ok",false)):
		return checked
	# Real three-day lead time and pending booking schema; no ad-hoc plan_confirmed flag.
	var booked: Dictionary = Calendar.book(state,venue_id,"tight",false,plan_id)
	if not bool(booked.get("ok",false)):
		return booked
	var next: Dictionary = booked["state"]
	return {"ok":true,"state":next,"preview":checked,
		"message":"%s booked for day %d. Route reserved; £0 charged and no gig played." % [
			str(checked["venue"]["venue"]),int(next["booked_show"]["day"])]}
