extends RefCounted
## S03 first-pass adapter (verified PR #192): authoritative Practice.compose on deep-copied local state.
## Never accesses CareerHub, FileAccess, save_data or autoloads.
const Practice = preload("res://Scripts/practice_room.gd")

static func sample_state() -> Dictionary:
	return {
		"band_name":"The Feedback", "tour_day":7, "cash":185, "songs":0,
		"readiness":48, "morale":56, "tension":12, "fans":0,
		"song_draft_progress":0, "current_song_draft":{}, "song_catalogue":[],
		"members":[
			{"name":"Jo","trait":"creative","skill":66,"fatigue":12,"morale":65,"life_status":"active"},
			{"name":"Lee","trait":"reliable","skill":59,"fatigue":9,"morale":60,"life_status":"active"},
			{"name":"Kit","trait":"restless","skill":55,"fatigue":15,"morale":52,"life_status":"active"}
		],
		"action_counters":{}, "career_journal":[], "relationships":{}
	}

static func simulate(state: Dictionary, idea: String, form: String, title: String, leader_index: int) -> Dictionary:
	# The real resolver validates title uniqueness and musician availability
	# BEFORE its day-costing action. Both paths receive an independent copy.
	var before: Dictionary = state.duplicate(true)
	var response: Dictionary = Practice.compose(before, idea, form, title, leader_index)
	if not bool(response.get("ok", false)):
		return {"ok":false, "message":str(response.get("message","Unable to compose."))}
	var after: Dictionary = response["state"]
	return {
		"ok":true, "state":after, "message":str(response.get("message","")),
		"days":int(after.get("tour_day",0)) - int(state.get("tour_day",0)),
		"cash":int(after.get("cash",0)) - int(state.get("cash",0)),
		"morale":int(after.get("morale",0)) - int(state.get("morale",0)),
		"readiness":int(after.get("readiness",0)) - int(state.get("readiness",0)),
		"progress":int(after.get("song_draft_progress",0)),
		"finished":after.get("song_catalogue",[]).size() > state.get("song_catalogue",[]).size()
	}
