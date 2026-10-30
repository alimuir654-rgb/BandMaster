extends RefCounted
## C27 isolated opening state; wraps C26 genuine recruitment model and save schema.
## No writes to main game's tour_save.json or band_profile.json.
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Names = preload("res://experiments/playable_flightcase/name_rules.gd")
const LOGOS := ["Wordmark","Stamp","Monogram"]
const PALETTES := ["Amber / Charcoal","White / Ink","Red / Black"]
const VIBES := ["Unpolished","Nocturnal","Wry","Atmospheric"]
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
var name_offer: String = ""
var name_intent: String = "Raw"
var name_revisions: int = 0
var name_locked: String = ""
var name_delta: int = 0
var name_settled: bool = false
var logo: String = "Wordmark"
var palette: String = "Amber / Charcoal"
var vibe: String = "Unpolished"
var identity_complete: bool = false

func begin_new() -> bool:
 game = Game.new()
 screen = "genre"
 lead_vocal_id = ""
 formed_once = false
 change_counter = 0
 name_offer = ""
 name_intent = "Raw"
 name_revisions = 0
 name_locked = ""
 name_delta = 0
 name_settled = false
 logo = "Wordmark"
 palette = "Amber / Charcoal"
 vibe = "Unpolished"
 identity_complete = false
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


func start_naming() -> bool:
 if screen != "formed" or not formed_once:
  return false
 screen = "name"
 return save_draft()

func suggested_names() -> Array:
 return Names.suggestions(game.genre)

func name_reactions() -> Array:
 return Names.reactions(game.roster,name_intent,game.genre) if not name_offer.is_empty() else []

func submit_name(value: String,intent: String) -> Dictionary:
 if screen != "name" or name_settled:
  return {"ok":false,"message":"Finish the lineup before naming."}
 var proposed: String = value.strip_edges()
 if proposed.length()<2 or proposed.length()>36:
  return {"ok":false,"message":"A name must be between 2 and 36 characters."}
 if not Names.INTENTS.has(intent):
  return {"ok":false,"message":"Choose what you want the name to feel like."}
 for i in range(proposed.length()):
  var code: int = proposed.unicode_at(i)
  if code < 32 or code == 127:
   return {"ok":false,"message":"The band name cannot contain control characters."}
 if not name_offer.is_empty():
  if name_offer.to_lower()==proposed.to_lower() and name_intent == intent:
   return {"ok":true,"message":"The band hasn't changed its mind.","reactions":name_reactions()}
  return {"ok":false,"message":"You've already proposed a name. Use your one free rethink to change it."}
 name_offer = proposed
 name_intent = intent
 change_counter += 1
 save_draft()
 return {"ok":true,"message":"The band's given its verdict.","reactions":name_reactions()}

func rethink_name() -> Dictionary:
 if screen != "name" or name_offer.is_empty() or name_revisions>=1:
  return {"ok":false,"message":"Only one rethink is free."}
 name_revisions = 1
 name_offer = ""
 change_counter += 1
 save_draft()
 return {"ok":true,"message":"One more chance to find a name everyone can live with."}

func lock_name() -> Dictionary:
 if screen != "name" or name_offer.is_empty() or name_settled:
  return {"ok":false,"message":"Propose a valid name first."}
 var comments: Array = name_reactions()
 var love := 0
 var dislikes := 0
 for item in comments:
  if item["reaction"] == "love":
   love += 1
  elif item["reaction"] == "dislike":
   dislikes += 1
 var consequence := 0
 if love == comments.size() and not comments.is_empty():
  consequence = 3
 elif dislikes > comments.size()/2:
  consequence = -2
 name_locked = name_offer
 name_delta = consequence
 name_settled = true
 screen = "name_milestone"
 change_counter += 1
 save_draft()
 return {"ok":true,"message":"Band name confirmed.","chemistry_delta":name_delta}

func start_identity() -> bool:
 if screen != "name_milestone" or not name_settled:
  return false
 screen = "identity"
 return save_draft()

func set_identity(next_logo: String,next_palette: String,next_vibe: String) -> bool:
 if screen != "identity" or not LOGOS.has(next_logo) or not PALETTES.has(next_palette) or not VIBES.has(next_vibe):
  return false
 logo = next_logo
 palette = next_palette
 vibe = next_vibe
 return save_draft()

func finish_identity() -> Dictionary:
 if screen != "identity" or identity_complete or not name_settled:
  return {"ok":false,"message":"Complete the name and design first."}
 var vocalist: Dictionary = _lead_person()
 if vocalist.is_empty() or missing_coverage() != "":
  return {"ok":false,"message":"A complete band and one singer are required."}
 var result: Dictionary = game.launch_with_vocals(lead_vocal_id,vocal_scores(vocalist))
 if not bool(result.get("ok",false)):
  return result
 game.career["band_name"] = name_locked
 game.career["morale"] = clampi(int(game.career.get("morale",55))+name_delta,0,100)
 game.career["name_chemistry_delta"] = name_delta
 game.career["logo"] = logo
 game.career["palette"] = palette
 game.career["vibe"] = vibe
 # The selected actor's band-member morale is not multiplied by number of UI visits.
 for member in game.career.get("members",[]):
  member["morale"] = clampi(int(member.get("morale",55))+name_delta,0,100)
 identity_complete = true
 screen = "complete"
 save_draft()
 return {"ok":true,"message":"The band identity is locked. Head to your first practice."}

func start_playing() -> bool:
 if screen != "complete" or not identity_complete or game.phase != "play":
  return false
 screen = "play"
 return save_draft()

func missing_coverage() -> String:
 var roles: Array = Base.coverage(game.roster)
 var absent: Array[String] = []
 for pair in [["Guitarist","guitar"],["Bassist","bass"],["Drummer","drums"]]:
  if not roles.has(pair[0]):
   absent.append(str(pair[1]))
 if game.roster.size()<3 or game.roster.size()>6:
  absent.append("three to six members")
 if lead_vocal_id.is_empty() or _lead_person().is_empty():
  absent.append("lead vocals")
 if remaining()<0:
  absent.append("talent budget")
 return ", ".join(absent)

func snapshot() -> Dictionary:
 return {"schema_version":1,"screen":screen,"game":game.snapshot(),
  "lead_vocal_id":lead_vocal_id,"formed_once":formed_once,"change_counter":change_counter,
  "name_offer":name_offer,"name_intent":name_intent,"name_revisions":name_revisions,
  "name_locked":name_locked,"name_delta":name_delta,"name_settled":name_settled,
  "logo":logo,"palette":palette,"vibe":vibe,"identity_complete":identity_complete}

func restore(value: Dictionary) -> bool:
 if int(value.get("schema_version",0)) != 1:
  return false
 var proposed := str(value.get("screen",""))
 if proposed not in ["genre","recruit","formed","name","name_milestone","identity","complete","play"]:
  return false
 var raw: Variant = value.get("game",null)
 if not raw is Dictionary:
  return false
 var candidate = Game.new()
 if not candidate.restore(raw):
  return false
 if candidate.phase != ("play" if proposed in ["complete","play"] else "recruit"):
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
 if proposed in ["formed","name","name_milestone","identity","complete","play"]:
  var roles: Array = Base.coverage(candidate.roster)
  if not roles.has("Guitarist") or not roles.has("Bassist") or not roles.has("Drummer") or voice.is_empty() or candidate.roster.size()<3:
   return false
 var offer: String = str(value.get("name_offer",""))
 var intent: String = str(value.get("name_intent","Raw"))
 var locked: String = str(value.get("name_locked",""))
 var revisions: int = int(value.get("name_revisions",0))
 var settled: bool = bool(value.get("name_settled",false))
 var delta: int = int(value.get("name_delta",0))
 var complete: bool = bool(value.get("identity_complete",false))
 var incoming_logo: String = str(value.get("logo","Wordmark"))
 var incoming_palette: String = str(value.get("palette","Amber / Charcoal"))
 var incoming_vibe: String = str(value.get("vibe","Unpolished"))
 if not Names.INTENTS.has(intent) or revisions<0 or revisions>1 or offer.length()>36:
  return false
 if not LOGOS.has(incoming_logo) or not PALETTES.has(incoming_palette) or not VIBES.has(incoming_vibe):
  return false
 if proposed in ["name_milestone","identity","complete","play"]:
  if not settled or locked.length()<2 or locked.length()>36 or locked!=offer or delta not in [-2,0,3]:
   return false
 if proposed in ["complete","play"]:
  if not complete or str(candidate.career.get("band_name","")) != locked:
   return false
  if int(candidate.career.get("name_chemistry_delta",999)) != delta:
   return false
 if proposed in ["genre","recruit","formed","name"] and (settled or complete):
  return false
 game = candidate
 screen = proposed
 lead_vocal_id = voice
 formed_once = bool(value.get("formed_once",false))
 change_counter = maxi(0,int(value.get("change_counter",0)))
 name_offer = offer
 name_intent = intent
 name_revisions = revisions
 name_locked = locked
 name_delta = delta
 name_settled = settled
 logo = incoming_logo
 palette = incoming_palette
 vibe = incoming_vibe
 identity_complete = complete
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
