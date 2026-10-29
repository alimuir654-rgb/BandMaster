extends RefCounted
## Opt-in casting supplement. Never replaces canonical people or writes saves.
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const DATA_PATH := "res://Data/CharacterCast/approved_cast_2026-10-29.json"
const MAX_TALENT := Base.MAX_TALENT
const ROLE_TABS := Base.ROLE_TABS

static func people() -> Array:
 var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
 if not raw is Dictionary or not raw.get("people") is Array:
  push_error("Approved cast data missing or invalid")
  return []
 return raw["people"].duplicate(true)

static func combined_people() -> Array:
 var result: Array = Base.people().duplicate(true)
 for person in people():
  if not Base.contains(result, str(person["id"])):
   result.append(person)
 return result

static func by_id(id: String) -> Dictionary:
 for person in people():
  if person["id"] == id:
   return person.duplicate(true)
 return {}

static func pool(genre: String, role: String) -> Array:
 if not Base.genres().has(genre) or not ROLE_TABS.has(role):
  return []
 var result: Array = []
 for person in people():
  if (person["roles"] as Array).has(role):
   result.append(person.duplicate(true))
 return result

static func cost(person: Dictionary) -> int:
 return Base.cost(person)

static func stats_for(person: Dictionary, role: String) -> Array:
 return Base.stats_for(person, role)

static func labels_for(role: String) -> Array:
 return Base.labels_for(role)

static func rehearsal_risk(person: Dictionary) -> Dictionary:
 # Metadata hook, not a claim that the career system applies penalties yet.
 return (person.get("rehearsal_risk", {}) as Dictionary).duplicate(true)
