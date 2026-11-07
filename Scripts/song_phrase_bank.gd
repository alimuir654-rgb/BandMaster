extends RefCounted

const ROLES := ["guitar", "bass", "drums"]
const DIRECTORY := "res://Audio/Songwriting/Rehearsam/"
const DURATION := 9.48

const LEGACY := "rehearsam-v1"
const SOURCES := {
 "steady-early-v1": {"label":"STEADY HUNDRED / EARLY", "dir":"res://Audio/Songwriting/SteadyHundred/Early/", "count":1, "duration":9.6},
 "steady-later-v1": {"label":"STEADY HUNDRED / LATER", "dir":"res://Audio/Songwriting/SteadyHundred/Later/", "count":1, "duration":9.6},
 "rehearsam-v1": {"label":"REHEARSAM LOOP / ORIGINAL BANK", "dir":DIRECTORY, "count":3, "duration":DURATION}
}

static func asset(role: String, phrase: int, source: String = LEGACY) -> String:
 return str(SOURCES.get(source, {}).get("dir", "res://missing-phrase-bank/")) + role + "_" + str(phrase) + ".wav"

static func available(source: String = "") -> bool:
 if source.is_empty():
  for key in SOURCES:
   if available(str(key)):
    return true
  return false
 if not SOURCES.has(source):
  return false
 for role in ROLES:
  for phrase in range(int(SOURCES[source]["count"])):
   if not ResourceLoader.exists(asset(role, phrase, source)):
    return false
 return true

static func usage_key(owner: String, role: String, phrase: int, source: String = LEGACY) -> String:
 # Original consumption keys remain unchanged for existing saves.
 return owner + "|" + ("" if source == LEGACY else source + "|") + role + ":" + str(phrase)

static func duration(source: String) -> float:
 return float(SOURCES.get(source, {}).get("duration", DURATION))

static func choices(state: Dictionary, role: String, source: String = LEGACY) -> Array:
 if not SOURCES.has(source):
  return []
 var member_index := participant(state, role)
 if member_index < 0:
  return []
 var owner := str(state["members"][member_index].get("audio_bank_id", "unassigned"))
 var used: Array = state.get("used_song_phrases", [])
 var draft_mix: Dictionary = state.get("current_song_draft", {}).get("audio_mix", {})
 var current: Dictionary = draft_mix.get("parts", {}).get(role, {}) if str(draft_mix.get("source", LEGACY)) == source else {}
 var result := []
 for phrase in range(int(SOURCES[source]["count"])):
  if not used.has(usage_key(owner, role, phrase, source)) or (str(current.get("contributor_id", "")) == owner and int(current.get("phrase", -1)) == phrase):
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
 var source := str(mix.get("source", LEGACY))
 if not SOURCES.has(source):
  return {"ok":false, "message":"This audio family is unavailable."}
 var parts = mix.get("parts", {})
 if not parts is Dictionary or parts.size() != 3:
  return {"ok":false, "message":"Choose one phrase for each instrument."}
 for role in ROLES:
  var part = parts.get(role, {})
  if not part is Dictionary:
   return {"ok":false, "message":"Choose valid instrument parts."}
  var phrase = part.get("phrase", -1)
  if not (phrase is int or phrase is float) or not is_finite(float(phrase)) or float(phrase) != floor(float(phrase)) or not choices(state, role, source).has(int(phrase)):
   return {"ok":false, "message":"That " + role + " phrase is no longer available."}
  var level = part.get("level_db", 0)
  if not (level is int or level is float) or not is_finite(float(level)) or float(level) < -48 or float(level) > 0:
   return {"ok":false, "message":"Choose a valid instrument level."}
  if not part.get("breakdown", false) is bool or not part.get("solo", false) is bool:
   return {"ok":false, "message":"Choose valid arrangement controls."}
 var next := state.duplicate(true)
 var used: Array = next.get("used_song_phrases", []).duplicate()
 var saved := {"source":source, "parts":{}}
 for role in ROLES:
  var part: Dictionary = parts[role]
  var index := participant(next, role)
  var member: Dictionary = next["members"][index]
  if not member.has("audio_bank_id"):
   var serial := int(next.get("next_audio_bank_id", 1))
   member["audio_bank_id"] = "player-part-" + str(serial)
   next["next_audio_bank_id"] = serial + 1
  var owner := str(member["audio_bank_id"])
  var key := usage_key(owner, role, int(part["phrase"]), source)
  if not used.has(key):
   used.append(key)
  saved["parts"][role] = {"phrase":int(part["phrase"]), "level_db":float(part.get("level_db", 0)), "breakdown":part.get("breakdown", false), "solo":part.get("solo", false), "contributor":str(member.get("name", "")), "contributor_id":owner}
 next["used_song_phrases"] = used
 next["current_song_draft"]["audio_mix"] = saved
 return {"ok":true, "state":next}
