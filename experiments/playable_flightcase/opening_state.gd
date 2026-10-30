extends RefCounted
## C27 isolated opening state; wraps C26 genuine recruitment model and save schema.
## No writes to main game's tour_save.json or band_profile.json.
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const SAVE_PATH := "user://c27_opening_draft.json"
const DOUBLE_VOCAL_COST := 5
# Explicit fictional audition notes, not appearance-inferred abilities.
# Only listed instrumentalists may double as front-person; singer roles retain source vocal arrays.
const VOCAL_TRIALS := {
 "cast_jack":[3,4,4,4,3,3], "cast_ryan":[5,5,4,6,5,4],
 "cast_tom":[3,3,3,4,3,2], "cast_arjun":[5,6,5,6,5,5],
 "cast_bex":[6,5,6,8,4,4], "cast_zoe":[4,4,4,5,4,3],
 "cast_ben":[3,3,3,3,3,2], "cast_hannah":[5,5,5,6,5,4],
 "cast_ellis":[3,3,4,4,3,2], "cast_marcus":[3,4,4,5,4,3],
 "cast_casey":[4,5,5,5,4,4], "cast_dan":[4,5,5,4,5,4],
 "cast_freya":[5,6,5,6,5,5], "cast_oscar":[4,5,5,6,5,4]
}
var game = Game.new()
var screen: String = "menu"
var lead_vocal_id: String = ""
var formed_once: bool = false
var change_counter: int = 0

func begin_new() -> bool:
 game = Game.new()
 screen = "genre"
 lead_vocal_id = ""
 formed_once = false
 change_counter = 0
 return save_draft()

func set_genre(value: String) -> bool:
 if screen != "genre" or not Base.genres().has(value):
  return false
 game.genre = value
 change_counter += 1
 return save_draft()

func to_recruit() -> bool:
 if screen != "genre" or not Base.genres().has(game.genre):
  return false
 screen = "recruit"
 return save_draft()

func back_to_genre() -> bool:
 if screen != "recruit":
  return false
 screen = "genre"
 return save_draft()

func vocal_scores(person: Dictionary) -> Array:
 var original: Array = person.get("vocal",[])
 if original.size() == 6 and (person.get("roles",[]) as Array).has("Singer"):
  return original.duplicate()
 return (VOCAL_TRIALS.get(str(person.get("id","")),[]) as Array).duplicate()

func _lead_person() -> Dictionary:
 for person in game.roster:
  if str(person["id"]) == lead_vocal_id:
   return person
 return {}

func vocal_extra_cost() -> int:
 var person := _lead_person()
 if person.is_empty():
  return 0
 return 0 if (person["roles"] as Array).has("Singer") else DOUBLE_VOCAL_COST

func remaining() -> int:
 return game.remaining() - vocal_extra_cost()

func can_recruit(id: String) -> bool:
 var person: Dictionary = game.person_by_id(id)
 return not person.is_empty() and Base.can_add(game.roster,person) and game.remaining()-Base.incremental_cost(game.roster,person)-vocal_extra_cost()>=0

func recruit(id: String) -> Dictionary:
 if screen != "recruit":
  return {"ok":false,"message":"Finish choosing your genre first."}
 if not can_recruit(id):
  return {"ok":false,"message":"Already selected, full band or not enough talent for the complete lineup."}
 var result: Dictionary = game.recruit(id)
 if result.get("ok",false):
  change_counter += 1
  save_draft()
 return result

func remove_member(id: String) -> Dictionary:
 if screen != "recruit":
  return {"ok":false,"message":"Return to the lineup first."}
 var result: Dictionary = game.remove_member(id)
 if result.get("ok",false):
  if lead_vocal_id == id:
   lead_vocal_id = ""
  change_counter += 1
  save_draft()
 return result

func choose_vocal(id: String) -> Dictionary:
 if screen != "recruit":
  return {"ok":false,"message":"Choose band members first."}
 var person: Dictionary = _lead_person()
 for candidate in game.roster:
  if str(candidate["id"]) == id:
   person = candidate
   break
 if person.is_empty() or str(person.get("id","")) != id or vocal_scores(person).size() != 6:
  return {"ok":false,"message":"This musician has no assessed lead-vocal audition."}
 var fee: int = 0 if (person["roles"] as Array).has("Singer") else DOUBLE_VOCAL_COST
 if game.remaining() < fee:
  return {"ok":false,"message":"You need %d talent for these additional vocal duties." % fee}
 lead_vocal_id = id
 change_counter += 1
 save_draft()
 return {"ok":true,"message":"%s takes lead vocals%s." % [str(person["name"]),(" (+5 talent)" if fee else "")]}

func missing() -> String:
 var roles: Array = Base.coverage(game.roster)
 var problems: Array[String] = []
 for pair in [["Guitarist","guitar"],["Bassist","bass"],["Drummer","drums"]]:
  if not roles.has(pair[0]):
   problems.append(str(pair[1]))
 if game.roster.size() < 3:
  problems.append("three distinct players")
 if lead_vocal_id.is_empty() or _lead_person().is_empty():
  problems.append("lead vocals")
 if remaining() < 0:
  problems.append("talent budget")
 return ", ".join(problems)

func ready() -> bool:
 return screen == "recruit" and missing().is_empty() and game.roster.size() <= 6

func confirm_lineup() -> Dictionary:
 if not ready():
  return {"ok":false,"message":"Still need "+missing()+"."}
 screen = "formed"
 formed_once = true
 save_draft()
 return {"ok":true,"message":"You've got a band. The lineup is locked for the first milestone."}

func snapshot() -> Dictionary:
 return {"schema_version":1,"screen":screen,"game":game.snapshot(),
  "lead_vocal_id":lead_vocal_id,"formed_once":formed_once,"change_counter":change_counter}

func restore(value: Dictionary) -> bool:
 if int(value.get("schema_version",0)) != 1:
  return false
 var proposed := str(value.get("screen",""))
 if proposed not in ["genre","recruit","formed"]:
  return false
 var raw: Variant = value.get("game",null)
 if not raw is Dictionary:
  return false
 var candidate = Game.new()
 if not candidate.restore(raw):
  return false
 if candidate.phase != "recruit":
  return false
 var voice := str(value.get("lead_vocal_id",""))
 if not voice.is_empty():
  var found := false
  for person in candidate.roster:
   if str(person["id"]) == voice:
    found = vocal_scores(person).size() == 6
  if not found:
   return false
  var voice_person: Dictionary = {}
  for person in candidate.roster:
   if str(person["id"]) == voice:
    voice_person = person
  if candidate.remaining() - (0 if (voice_person["roles"] as Array).has("Singer") else DOUBLE_VOCAL_COST) < 0:
   return false
 if proposed == "formed":
  var roles: Array = Base.coverage(candidate.roster)
  if not roles.has("Guitarist") or not roles.has("Bassist") or not roles.has("Drummer") or voice.is_empty() or candidate.roster.size()<3:
   return false
 game = candidate
 screen = proposed
 lead_vocal_id = voice
 formed_once = bool(value.get("formed_once",false))
 change_counter = maxi(0,int(value.get("change_counter",0)))
 return true

func save_draft() -> bool:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  return false
 file.store_string(JSON.stringify(snapshot(),"  "))
 file.close()
 return true

func load_draft() -> bool:
 if not FileAccess.file_exists(SAVE_PATH):
  return false
 var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
 if not parsed is Dictionary:
  return false
 var normalised: Variant = game._restore_integral_numbers(parsed)
 return restore(normalised as Dictionary) if normalised is Dictionary else false

func has_valid_draft() -> bool:
 var trial = get_script().new()
 return trial.load_draft()
