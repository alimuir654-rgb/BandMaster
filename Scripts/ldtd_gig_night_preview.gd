extends RefCounted
## S05 isolated gig-night preview adapted from verified PR #191
## Scripts/gig_night_journey_model.gd. Real Calendar.book/perform rules.
## Never writes a production save; one performance settlement only.
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")

static func sample_state() -> Dictionary:
	var seed: Dictionary = {
		"cash":180, "tour_day":1, "readiness":78, "morale":65,
		"tension":12, "reputation":5, "fans":0, "van_health":80,
		"songs":3, "gig_history":[], "career_journal":[],
		"members":[
			{"name":"Jo","role":"Drummer","life_status":"active","fatigue":10,"trait":"Reliable"},
			{"name":"Ash","role":"Guitarist","life_status":"active","fatigue":12,"trait":"Creative"}
		]
	}
	var booked: Dictionary = Calendar.book(seed,"local","tight")
	if not bool(booked.get("ok",false)):
		return {}
	var state: Dictionary = booked["state"]
	# Sample scene opens on booked day. This is not a player calendar action.
	state["tour_day"] = int(state["booked_show"]["day"])
	return state

static func choose_approach(state: Dictionary, approach: String) -> Dictionary:
	if not Circuit.APPROACHES.has(approach):
		return {"ok":false,"message":"Unknown performance approach."}
	var booking: Dictionary = Calendar.pending(state)
	if booking.is_empty():
		return {"ok":false,"message":"No live booking."}
	var next: Dictionary = state.duplicate(true)
	var show: Dictionary = next["booked_show"].duplicate(true)
	show["approach"] = approach
	next["booked_show"] = show
	return {"ok":true,"state":next,"preview":Circuit.approach_preview(next,approach)}

static func settle(state: Dictionary, cues: int, gear: bool, sound: bool, held: bool, already: bool) -> Dictionary:
	if already:
		return {"ok":false,"message":"This show has already been settled."}
	if cues != 3 or not gear or not sound or held:
		return {"ok":false,"message":"Finish three cues with safe gear and sound before settlement."}
	var booking: Dictionary = Calendar.pending(state)
	if booking.is_empty() or int(state.get("tour_day",0)) != int(booking.get("day",-1)):
		return {"ok":false,"message":"Only the booked show day can be settled."}
	return Calendar.perform(state.duplicate(true))
