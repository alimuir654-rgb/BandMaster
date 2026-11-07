extends RefCounted

const ROLES := ["guitar", "bass", "drums"]
const DIRECTORY := "res://Audio/Songwriting/Rehearsam/"
const DURATION := 9.48

static func asset(role: String, phrase: int) -> String:
	return DIRECTORY + role + "_" + str(phrase) + ".wav"

static func available() -> bool:
	for role in ROLES:
		for phrase in range(3):
			if not ResourceLoader.exists(asset(role, phrase)):
				return false
	return true

static func choices(state: Dictionary, role: String) -> Array:
	var member_index := participant(state, role)
	if member_index < 0:
		return []
	var owner := str(state["members"][member_index].get("audio_bank_id", "unassigned"))
	var used: Array = state.get("used_song_phrases", [])
	var current: Dictionary = state.get("current_song_draft", {}).get("audio_mix", {}).get("parts", {}).get(role, {})
	var result := []
	for phrase in range(3):
		if not used.has(owner + "|" + role + ":" + str(phrase)) or (str(current.get("contributor_id", "")) == owner and int(current.get("phrase", -1)) == phrase):
			result.append(phrase)
	return result

static func participant(state: Dictionary, role: String) -> int:
	var members: Array = state.get("members", [])
	for index in range(members.size()):
		var member = members[index]
		if member is Dictionary and str(member.get("life_status", "active")) == "active" and str(member.get("role", "")).to_lower().contains("drum" if role == "drums" else role):
			return index
	return -1

static func attach(state: Dictionary, mix: Dictionary) -> Dictionary:
	if mix.is_empty():
		return {"ok":true, "state":state.duplicate(true)}
	var parts = mix.get("parts", {})
	if not parts is Dictionary or parts.size() != 3:
		return {"ok":false, "message":"Choose one phrase for each instrument."}
	for role in ROLES:
		var part = parts.get(role, {})
		if not part is Dictionary or not part.get("phrase") is int or not choices(state, role).has(part["phrase"]):
			return {"ok":false, "message":"That " + role + " phrase is no longer available."}
		var level = part.get("level_db", 0)
		if not (level is int or level is float) or not is_finite(float(level)) or float(level) < -48 or float(level) > 0:
			return {"ok":false, "message":"Choose a valid instrument level."}
		if not part.get("breakdown", false) is bool or not part.get("solo", false) is bool:
			return {"ok":false, "message":"Choose valid arrangement controls."}
	var next := state.duplicate(true)
	var used: Array = next.get("used_song_phrases", []).duplicate()
	var saved := {"source":"rehearsam-v1", "parts":{}}
	for role in ROLES:
		var part: Dictionary = parts[role]
		var index := participant(next, role)
		var member: Dictionary = next["members"][index]
		if not member.has("audio_bank_id"):
			var serial := int(next.get("next_audio_bank_id", 1))
			member["audio_bank_id"] = "player-part-" + str(serial)
			next["next_audio_bank_id"] = serial + 1
		var owner := str(member["audio_bank_id"])
		var key: String = owner + "|" + role + ":" + str(part["phrase"])
		if not used.has(key):
			used.append(key)
		saved["parts"][role] = {"phrase":part["phrase"], "level_db":float(part.get("level_db", 0)), "breakdown":part.get("breakdown", false), "solo":part.get("solo", false), "contributor":str(member.get("name", "")), "contributor_id":owner}
	next["used_song_phrases"] = used
	next["current_song_draft"]["audio_mix"] = saved
	return {"ok":true, "state":next}
