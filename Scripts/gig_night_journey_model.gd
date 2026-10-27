extends RefCounted
## Sprint 07: pure, isolated show-day settlement adapter. No disk or autoload access.
## Delegates all economy and rewards to the existing GigCalendar once.
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")

static func sample_state() -> Dictionary:
	var starting: Dictionary = {
		"cash": 180, "tour_day": 1, "readiness": 78, "morale": 65,
		"tension": 12, "reputation": 5, "fans": 0, "van_health": 80,
		"songs": 3, "gig_history": [], "career_journal": [],
		"members": [
			{"name": "Jo", "role": "Drummer", "life_status": "active", "fatigue": 10, "trait": "Reliable"},
			{"name": "Ash", "role": "Guitarist", "life_status": "active", "fatigue": 12, "trait": "Creative"}
		]
	}
	var booking: Dictionary = Calendar.book(starting, "local", "tight")
	if not bool(booking.get("ok", false)):
		return {}
	var state: Dictionary = booking["state"]
	# This is an isolated sample ON show day, not a live career advance.
	state["tour_day"] = int(state["booked_show"]["day"])
	return state

static func choose_approach(state: Dictionary, approach: String) -> Dictionary:
	if not Circuit.APPROACHES.has(approach):
		return {"ok": false, "message": "Unknown show approach."}
	var booked: Dictionary = Calendar.pending(state)
	if booked.is_empty():
		return {"ok": false, "message": "There is no booked show."}
	var next: Dictionary = state.duplicate(true)
	var next_booking: Dictionary = next["booked_show"]
	next_booking["approach"] = approach
	return {"ok": true, "state": next, "preview": Circuit.approach_preview(next, approach)}

static func settle(state: Dictionary, songs_played: int, gear_ready: bool, sound_ready: bool, held: bool, already_settled: bool) -> Dictionary:
	if already_settled:
		return {"ok": false, "message": "This show has already been settled."}
	if songs_played != 3 or not gear_ready or not sound_ready or held:
		return {"ok": false, "message": "Finish the set with safe sound and gear before settlement."}
	var booking: Dictionary = Calendar.pending(state)
	if booking.is_empty():
		return {"ok": false, "message": "No live booking remains to settle."}
	if int(state.get("tour_day", 0)) != int(booking.get("day", -1)):
		return {"ok": false, "message": "The performance must happen on the booked day."}
	# Existing authoritative gameplay settlement, on a deep copy only.
	return Calendar.perform(state.duplicate(true))
