extends RefCounted
## C27 isolated opening state; wraps C26 genuine recruitment model and save schema.
## No writes to main game's tour_save.json or band_profile.json.
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Names = preload("res://experiments/playable_flightcase/name_rules.gd")
const IdentityStyle = preload("res://experiments/playable_flightcase/identity_style.gd")
const Audition = preload("res://experiments/playable_flightcase/audition_encounter.gd")
const Workbench = preload("res://experiments/playable_flightcase/song_workbench.gd")
const LOGOS := ["Wordmark","Stamp","Monogram"]
const PALETTES := ["Amber / Charcoal","White / Ink","Red / Black"]
const VIBES := ["Unpolished","Nocturnal","Wry","Atmospheric"]
const SAVE_PATH := "user://c27_opening_draft.json"
const DOUBLE_VOCAL_COST := 5
const BandWeek = preload("res://experiments/playable_flightcase/band_week.gd")
const CareerDates = preload("res://experiments/playable_flightcase/career_dates.gd")
const WorkAvailability = preload("res://experiments/playable_flightcase/situation_core.gd")
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
var identity_style: Dictionary = {}
var _audition_present := false
var _audition_raw: Variant = null
var _audition_busy := false # Shared owner transaction lock: audition and lyric workbench.
var _workbench_serial := 0
var _workbench_transaction: Dictionary = {}
var _opening_extensions: Dictionary = {}
var _game_extensions: Dictionary = {}

func begin_new() -> bool:
 if _audition_busy:return false
 var before:=snapshot()
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
 identity_style = {}
 _audition_present=false
 _audition_raw=null
 _opening_extensions={}
 _game_extensions={}
 return _save_identity_or_restore(before)

func set_genre(value: String) -> bool:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return false
 if screen != "genre" or not Base.genres().has(value):
  return false
 game.genre = value
 change_counter += 1
 return save_draft()

func to_recruit() -> bool:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return false
 if screen != "genre" or not Base.genres().has(game.genre):
  return false
 screen = "recruit"
 return save_draft()

func back_to_genre() -> bool:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return false
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
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):
  return {"ok":false,"message":"Finish or close the saved audition first."}
 if screen != "recruit":
  return {"ok":false,"message":"Finish choosing your genre first."}
 if not can_recruit(id):
  return {"ok":false,"message":"Already selected, full band or not enough talent for the complete lineup."}
 _audition_busy=true
 var before:=snapshot()
 var result: Dictionary = game.recruit(id)
 if result.get("ok",false):
  change_counter += 1
  if not _save_identity_or_restore(before):
   _audition_busy=false
   return {"ok":false,"message":"The invitation could not be saved. Nothing changed; try again."}
 _audition_busy=false
 return result

func remove_member(id: String) -> Dictionary:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):
  return {"ok":false,"message":"Finish or close the saved audition first."}
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
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):
  return {"ok":false,"message":"Finish or close the saved audition first."}
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
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):
  return {"ok":false,"message":"Finish or close the saved audition first."}
 if not ready():
  return {"ok":false,"message":"Still need "+missing()+"."}
 screen = "formed"
 formed_once = true
 save_draft()
 return {"ok":true,"message":"You've got a band. The lineup is locked for the first milestone."}


func start_naming() -> bool:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return false
 if screen != "formed" or not formed_once:
  return false
 var before: Dictionary = snapshot()
 screen = "name"
 return _save_identity_or_restore(before)

func suggested_names() -> Array:
 return Names.suggestions(game.genre)

func name_reactions() -> Array:
 return Names.reactions(game.roster,name_intent,game.genre) if not name_offer.is_empty() else []

func submit_name(value: String,intent: String) -> Dictionary:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return {"ok":false,"message":"Close the saved audition before changing the opening."}
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
 var before: Dictionary = snapshot()
 name_offer = proposed
 name_intent = intent
 change_counter += 1
 if not _save_identity_or_restore(before):
  return {"ok":false,"message":"The name could not be saved. Your idea is still here; try again."}
 return {"ok":true,"message":"The band's given its verdict.","reactions":name_reactions()}

func rethink_name() -> Dictionary:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return {"ok":false,"message":"Close the saved audition before changing the opening."}
 if screen != "name" or name_offer.is_empty() or name_revisions>=1:
  return {"ok":false,"message":"Only one rethink is free."}
 var before: Dictionary = snapshot()
 name_revisions = 1
 name_offer = ""
 change_counter += 1
 if not _save_identity_or_restore(before):
  return {"ok":false,"message":"The rethink could not be saved. Nothing has changed; try again."}
 return {"ok":true,"message":"One more chance to find a name everyone can live with."}

func lock_name() -> Dictionary:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return {"ok":false,"message":"Close the saved audition before changing the opening."}
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
 var before: Dictionary = snapshot()
 name_locked = name_offer
 name_delta = consequence
 name_settled = true
 screen = "name_milestone"
 change_counter += 1
 if not _save_identity_or_restore(before):
  return {"ok":false,"message":"The name could not be locked on disk. Nothing has been counted; try again."}
 return {"ok":true,"message":"Band name confirmed.","chemistry_delta":name_delta}

func start_identity() -> bool:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return false
 if screen != "name_milestone" or not name_settled:
  return false
 var before: Dictionary = snapshot()
 screen = "identity"
 return _save_identity_or_restore(before)

func set_identity(next_logo: String,next_palette: String,next_vibe: String) -> bool:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return false
 if screen != "identity" or not LOGOS.has(next_logo) or not PALETTES.has(next_palette) or not VIBES.has(next_vibe):
  return false
 var before: Dictionary = snapshot()
 logo = next_logo
 palette = next_palette
 vibe = next_vibe
 return _save_identity_or_restore(before)

func finish_identity(style: Dictionary = {}, look: Dictionary = {}) -> Dictionary:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return {"ok":false,"message":"Close the saved audition before changing the opening."}
 if screen != "identity" or identity_complete or not name_settled:
  return {"ok":false,"message":"Complete the name and design first."}
 var vocalist: Dictionary = _lead_person()
 if vocalist.is_empty() or missing_coverage() != "":
  return {"ok":false,"message":"A complete band and one singer are required."}
 var proposed_style: Dictionary = identity_style.duplicate(true) if style.is_empty() else style.duplicate(true)
 if not proposed_style.is_empty() and not IdentityStyle.valid(proposed_style):
  return {"ok":false,"message":"Choose a valid type direction and ink before applying the look."}
 if not look.is_empty() and (not LOGOS.has(look.get("logo")) or not PALETTES.has(look.get("palette")) or not VIBES.has(look.get("vibe"))):
  return {"ok":false,"message":"Choose a valid mark and attitude before applying the look."}
 var before: Dictionary = snapshot()
 var result: Dictionary = game.launch_with_vocals(lead_vocal_id,vocal_scores(vocalist))
 if not bool(result.get("ok",false)):
  return result
 if not look.is_empty():
  logo=str(look["logo"])
  palette=str(look["palette"])
  vibe=str(look["vibe"])
 game.career["band_name"] = name_locked
 game.career["morale"] = clampi(int(game.career.get("morale",55))+name_delta,0,100)
 game.career["name_chemistry_delta"] = name_delta
 game.career["logo"] = logo
 game.career["palette"] = palette
 game.career["vibe"] = vibe
 game.career[preload("res://experiments/playable_flightcase/band_sound.gd").KEY] = preload("res://experiments/playable_flightcase/band_sound.gd").make(game.genre,name_intent,vibe)
 var starting: Dictionary=WorkAvailability.seed_starting(game.career)
 if not starting.get("ok",false):
  _rollback_identity(before)
  return {"ok":false,"message":str(starting.get("message","The known commitments could not be recorded."))}
 game.career=starting.state.duplicate(true)
 if not game.career.has(CareerDates.KEY):game.career[CareerDates.KEY]=CareerDates.initial(WorkAvailability.Starting.SOURCE)
 identity_style = proposed_style
 if not identity_style.is_empty():
  game.career[IdentityStyle.KEY] = identity_style.duplicate(true)
 # The selected actor's band-member morale is not multiplied by number of UI visits.
 for member in game.career.get("members",[]):
  member["morale"] = clampi(int(member.get("morale",55))+name_delta,0,100)
 identity_complete = true
 screen = "complete"
 if not _save_identity_or_restore(before):
  return {"ok":false,"message":"The band identity could not be saved. Nothing has been counted; your look is still ready to retry."}
 return {"ok":true,"message":"The band identity is locked. Head to your first practice."}

func start_playing() -> bool:
 if _audition_busy or Audition.locked(snapshot()) or Workbench.preplay_held(snapshot()):return false
 if screen != "complete" or not identity_complete or game.phase != "play":
  return false
 var before: Dictionary = snapshot()
 screen = "play"
 return _save_identity_or_restore(before)

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
 var saved_game:=_game_extensions.duplicate(true)
 saved_game.merge(game.snapshot(),true)
 var result: Dictionary = _opening_extensions.duplicate(true)
 result.merge({"schema_version":1,"screen":screen,"game":saved_game,
  "lead_vocal_id":lead_vocal_id,"formed_once":formed_once,"change_counter":change_counter,
  "name_offer":name_offer,"name_intent":name_intent,"name_revisions":name_revisions,
  "name_locked":name_locked,"name_delta":name_delta,"name_settled":name_settled,
  "logo":logo,"palette":palette,"vibe":vibe,"identity_complete":identity_complete},true)
 if not identity_style.is_empty():
  result[IdentityStyle.KEY] = identity_style.duplicate(true)
 if _audition_present:result[Audition.KEY]=_copy_extension(_audition_raw)
 return result

func restore(value: Dictionary) -> bool:
 if _audition_busy:return false
 _audition_busy=true
 var restored: bool=_restore_owned(value)
 _audition_busy=false
 return restored

func _restore_owned(value: Dictionary) -> bool:
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
 var incoming_style: Dictionary = {}
 if value.has(IdentityStyle.KEY):
  if not IdentityStyle.valid(value[IdentityStyle.KEY]): return false
  incoming_style=(value[IdentityStyle.KEY] as Dictionary).duplicate(true)
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
  if candidate.career.has(IdentityStyle.KEY) and not IdentityStyle.valid(candidate.career[IdentityStyle.KEY]): return false
  if not incoming_style.is_empty() and candidate.career.get(IdentityStyle.KEY,{})!=incoming_style: return false
  if incoming_style.is_empty() and candidate.career.has(IdentityStyle.KEY): return false
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
 identity_style = incoming_style
 _retain_extensions(value)
 var saved_people: Array=raw.get("roster",[])
 for index in range(mini(saved_people.size(),game.roster.size())):
  var canonical: Dictionary=game.person_by_id(str(game.roster[index].get("id","")))
  for key in saved_people[index]:
   if not canonical.has(key):game.roster[index][key]=_copy_extension(saved_people[index][key])
 return true

func _copy_extension(value: Variant) -> Variant:
 return value.duplicate(true) if value is Dictionary or value is Array else value

func _retain_extensions(value: Dictionary) -> void:
 _opening_extensions=value.duplicate(true)
 for key in ["schema_version","screen","game","lead_vocal_id","formed_once","change_counter","name_offer","name_intent","name_revisions","name_locked","name_delta","name_settled","logo","palette","vibe","identity_complete",IdentityStyle.KEY,Audition.KEY]:
  _opening_extensions.erase(key)
 _game_extensions=(value.get("game",{}) as Dictionary).duplicate(true)
 for key in ["schema_version","genre","roster","phase","career"]:_game_extensions.erase(key)
 _audition_present=value.has(Audition.KEY)
 _audition_raw=_copy_extension(value.get(Audition.KEY))

func _rollback_identity(before: Dictionary) -> void:
 # This is our own validated in-memory snapshot, not untrusted save input.
 # Restore exact roster numeric types too; Game.restore canonicalises them.
 var original: Dictionary = before["game"]
 game.genre=str(original["genre"])
 game.roster=(original["roster"] as Array).duplicate(true)
 game.phase=str(original["phase"])
 game.career=(original["career"] as Dictionary).duplicate(true)
 for field in ["screen","lead_vocal_id","formed_once","change_counter","name_offer","name_intent","name_revisions","name_locked","name_delta","name_settled","logo","palette","vibe","identity_complete"]:
  set(field,before[field])
 identity_style=(before.get(IdentityStyle.KEY,{}) as Dictionary).duplicate(true)
 _retain_extensions(before)

func audition_view(candidate_id: String="cast_jack") -> Dictionary:
 return Audition.view(snapshot(),candidate_id)

func audition_expected() -> Dictionary:
 return Audition.expected(snapshot())

func _finish_audition(before: Dictionary,result: Dictionary) -> Dictionary:
 if not result.get("ok",false):
  _rollback_identity(before)
  return {"ok":false,"message":str(result.get("message","This audition choice is unavailable.")),"changed":false}
 _audition_present=true
 _audition_raw=(result["wrapper"] as Dictionary).duplicate(true)
 if not _save_draft_owned():
  _rollback_identity(before)
  return {"ok":false,"message":"The audition could not be saved. Nothing changed; try again.","changed":false}
 var candidate_id: String=str(_audition_raw["active"].get("candidate_id",_audition_raw["last_result"].get("candidate_id","cast_jack")))
 return {"ok":true,"message":str(result.get("message","")),"changed":true,"candidate_id":candidate_id,"view":audition_view(candidate_id),"expected":audition_expected()}

func begin_audition(candidate_id: String,role: String) -> Dictionary:
 if _audition_busy or Workbench.preplay_held(snapshot()):return {"ok":false,"message":"An audition choice is already being saved.","changed":false}
 _audition_busy=true
 var before:=snapshot()
 var result:=_finish_audition(before,Audition.begin(before,candidate_id,role))
 _audition_busy=false
 return result

func audition_action(action: String,expected: Dictionary,request: String="") -> Dictionary:
 if _audition_busy or Workbench.preplay_held(snapshot()):return {"ok":false,"message":"An audition choice is already being saved.","changed":false}
 _audition_busy=true
 var before:=snapshot()
 var result:=_finish_audition(before,Audition.checkpoint(before,action,expected,request))
 _audition_busy=false
 return result

func invite_audition(expected: Dictionary) -> Dictionary:
 if _audition_busy or Workbench.preplay_held(snapshot()):return {"ok":false,"message":"An audition choice is already being saved.","changed":false}
 _audition_busy=true
 var before:=snapshot()
 var prepared:=Audition.prepare_invite(before,expected)
 var result: Dictionary
 if not prepared.get("ok",false):
  result=_finish_audition(before,prepared)
 else:
  var available_before:=remaining()
  var original: Dictionary=game.recruit(str(prepared["candidate_id"]))
  if original.get("ok",false):change_counter+=1
  var completed:=Audition.complete_invite(before,snapshot(),expected,original,available_before,remaining())
  result=_finish_audition(before,completed)
 _audition_busy=false
 return result

func _save_identity_or_restore(before: Dictionary) -> bool:
 var written: bool=_save_draft_owned() if _audition_busy else save_draft()
 if written:return true
 _rollback_identity(before)
 return false

func save_draft() -> bool:
 if _audition_busy:return false
 _audition_busy=true
 var saved: bool=_save_draft_owned()
 _audition_busy=false
 return saved

func _save_draft_owned() -> bool:
 # The old valid draft remains intact until a complete replacement is ready.
 var temporary: String = SAVE_PATH+".identity-tmp"
 var file := FileAccess.open(temporary,FileAccess.WRITE)
 if file == null:
  return false
 file.store_string(JSON.stringify(snapshot(),"  ",true,_audition_present or game.career.has(Workbench.KEY) or game.career.has(CareerDates.KEY)))
 file.flush()
 var written: bool = file.get_error()==OK
 file.close()
 if not written:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
  return false
 var replaced: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(SAVE_PATH))
 if replaced!=OK:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
 return replaced==OK

func load_draft() -> bool:
 if _audition_busy:return false
 _audition_busy=true
 var loaded: bool=_load_draft_owned()
 _audition_busy=false
 return loaded

func _load_draft_owned() -> bool:
 if not FileAccess.file_exists(SAVE_PATH):
  return false
 var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
 if not parsed is Dictionary:
  return false
 var normalised: Variant = game._restore_integral_numbers(parsed)
 return _restore_owned(normalised as Dictionary) if normalised is Dictionary else false

func has_valid_draft() -> bool:
 var trial = get_script().new()
 return trial.load_draft()


func workbench_view() -> Dictionary:
 return Workbench.view(snapshot())

func workbench_expected() -> Dictionary:
 return Workbench.expected(snapshot())

func _workbench_result(ok: bool,changed: bool,message: String) -> Dictionary:
 return {"ok":ok,"changed":changed,"message":message,"view":workbench_view(),"expected":workbench_expected()}

func _finish_workbench_free(before: Dictionary,result: Dictionary) -> Dictionary:
 if not result.get("ok",false):
  _rollback_identity(before)
  return _workbench_result(false,false,str(result.get("message","This saved sketch needs review.")))
 if not result.get("changed",false):return _workbench_result(true,false,str(result.get("message","")))
 var outside_before: Dictionary=before.duplicate(true)
 var outside_after: Dictionary=(result["state"] as Dictionary).duplicate(true)
 outside_before.game.career.erase(Workbench.KEY)
 outside_after.game.career.erase(Workbench.KEY)
 if not Workbench._exact(outside_before,outside_after):
  _rollback_identity(before)
  return _workbench_result(false,false,"A free sketch cannot change the original career.")
 game.career=(result.state.game.career as Dictionary).duplicate(true)
 var producer: bool=game.career.get(Workbench.KEY,{}).get("project",{}).get("fragment",{}).has("producer_recipe")
 if not _save_draft_owned():
  _rollback_identity(before)
  return _workbench_result(false,false,"The take could not be saved. The previous band and your local direction are retained; try again." if producer else "The sketch could not be saved. The previous band and your local words are retained; try again.")
 return _workbench_result(true,true,str(result.get("message","")))

func begin_workbench(title: String,leader_index: int,expected: Dictionary,recipe: Dictionary={}) -> Dictionary:
 if _audition_busy:return _workbench_result(false,false,"A band action is already being saved.")
 _audition_busy=true
 var before:=snapshot()
 var result:=_finish_workbench_free(before,Workbench.begin(before,title,leader_index,expected,recipe))
 _audition_busy=false
 return result

func workbench_action(action: String,expected: Dictionary,payload: Dictionary={}) -> Dictionary:
 if _audition_busy:return _workbench_result(false,false,"A band action is already being saved.")
 _audition_busy=true
 var before:=snapshot()
 var result:=_finish_workbench_free(before,Workbench.checkpoint(before,action,expected,payload))
 _audition_busy=false
 return result

func begin_workbench_commit(expected: Dictionary) -> Dictionary:
 var fail: Dictionary={"ok":false,"changed":false,"message":"A band action is already being saved.","transaction_id":"","prepared":{},"before_game":{}}
 if _audition_busy:return fail
 _audition_busy=true
 var before:=snapshot()
 var prepared:=Workbench.prepare_paid(before,expected)
 if not prepared.ok:
  _audition_busy=false
  fail.message=prepared.message
  return fail
 var attendance: Dictionary=WorkAvailability.guard_writing(game.career)
 if not attendance.get("ok",false):
  _audition_busy=false
  fail.message=str(attendance.get("message","Review the band's available evening."))
  return fail
 _workbench_serial+=1
 var ticket: String="workbench-tx:%d" % _workbench_serial
 _workbench_transaction={"id":ticket,"before":before.duplicate(true),"prepared":prepared.prepared.duplicate(true),"completion":{},"original_result":{},"phase":"prepared"}
 return {"ok":true,"changed":false,"message":"","transaction_id":ticket,"prepared":prepared.prepared.duplicate(true),"before_game":(before.game as Dictionary).duplicate(true)}

func agree_band_week(expected: Dictionary) -> Dictionary:
 var fail: Dictionary={"ok":false,"changed":false,"message":"A band action is already being saved."}
 if _audition_busy:return fail
 _audition_busy=true
 var before: Dictionary=snapshot()
 var result: Dictionary=BandWeek.apply(before,expected)
 if not result.get("ok",false) or not result.get("changed",false):
  _audition_busy=false
  return {"ok":bool(result.get("ok",false)),"changed":false,"message":str(result.get("message","Review the proposed week."))}
 var next: Dictionary=result.state
 if not BandWeek.outside_equal(before,next):
  _audition_busy=false
  return {"ok":false,"changed":false,"message":"A free working-week agreement cannot change the rest of the band."}
 game.career=next.game.career.duplicate(true)
 if not _save_draft_owned():
  _rollback_identity(before)
  _audition_busy=false
  return {"ok":false,"changed":false,"message":"The week could not be saved. Your whole previous band and choices are retained; try again."}
 _audition_busy=false
 return {"ok":true,"changed":true,"message":str(result.message)}

func set_member_context(expected: Dictionary,id: String,kind: String) -> Dictionary:
 var fail: Dictionary={"ok":false,"changed":false,"message":"The band changed. Reopen the known circumstances before saving."}
 if _audition_busy:return fail
 _audition_busy=true
 var before: Dictionary=snapshot()
 if not BandWeek.schema_ok(before) or not BandWeek.exact(before,expected) or screen!="play" or game.phase!="play" or Audition.locked(before) or Workbench.preplay_held(before) or BandWeek.Finance.is_over(game.career) or BandWeek.Radio.locked(game.career) or (game.career.has(Workbench.KEY) and not Workbench.validate(before).get("ok",false)):
  _audition_busy=false;return fail
 var result: Dictionary=WorkAvailability.set_context(game.career,id,kind,before.game.career)
 if not result.get("ok",false) or not result.get("changed",false):
  _audition_busy=false;return {"ok":bool(result.get("ok",false)),"changed":false,"message":str(result.get("message","Review the known circumstances."))}
 var proposed: Dictionary=before.duplicate(true);proposed.game.career=result.state.duplicate(true)
 var a: Dictionary=before.duplicate(true);var b: Dictionary=proposed.duplicate(true)
 a.game.career.erase(WorkAvailability.KEY);b.game.career.erase(WorkAvailability.KEY)
 if not BandWeek.exact(a,b):
  _audition_busy=false;return fail
 game.career=result.state.duplicate(true)
 if not _save_draft_owned():
  _rollback_identity(before);_audition_busy=false
  return {"ok":false,"changed":false,"message":"The change could not be saved. Your whole previous band and pending choice are retained; try again."}
 _audition_busy=false
 return {"ok":true,"changed":true,"message":str(result.message)}

func _workbench_ticket(ticket: String) -> bool:
 return _audition_busy and not ticket.is_empty() and _workbench_transaction.get("id")==ticket

func _abort_workbench_owned(message: String) -> Dictionary:
 # Only this owner may clean up its retained in-flight snapshot. Public
 # reentrant finish/abort calls cannot interrupt the actual writer.
 _rollback_identity(_workbench_transaction.before)
 _workbench_transaction={}
 _audition_busy=false
 return _workbench_result(false,false,message)

func abort_workbench_commit(transaction_id: String,message: String) -> Dictionary:
 if not _workbench_ticket(transaction_id):return _workbench_result(false,false,"That saved-session ticket is no longer active.")
 if _workbench_transaction.get("phase") in ["sealing","saving"]:return _workbench_result(false,false,"This session is already being saved.")
 return _abort_workbench_owned(message)

func complete_workbench_original(transaction_id: String,original_result: Dictionary) -> Dictionary:
 if not _workbench_ticket(transaction_id):return {"ok":false,"changed":false,"message":"That saved-session ticket is no longer active."}
 if _workbench_transaction.get("phase")!="prepared" or not _workbench_transaction.completion.is_empty():return {"ok":false,"changed":false,"message":"The original session has already been checked."}
 var completed:=Workbench.complete_original(_workbench_transaction.before,snapshot(),_workbench_transaction.prepared,original_result)
 if not completed.ok:
  var failed:=abort_workbench_commit(transaction_id,completed.message)
  return {"ok":false,"changed":false,"message":failed.message}
 _workbench_transaction.completion=completed.completion.duplicate(true)
 _workbench_transaction.original_result=original_result.duplicate(true)
 _workbench_transaction.phase="original_checked"
 return {"ok":true,"changed":false,"message":""}

func finish_workbench_commit(transaction_id: String) -> Dictionary:
 if not _workbench_ticket(transaction_id):return _workbench_result(false,false,"That saved-session ticket is no longer active.")
 if _workbench_transaction.get("phase") in ["sealing","saving"]:return _workbench_result(false,false,"This session is already being saved.")
 if _workbench_transaction.completion.is_empty():return _abort_workbench_owned("The original session has not been checked; nothing was saved.")
 _workbench_transaction.phase="sealing"
 var before: Dictionary=_workbench_transaction.before
 var sealed:=Workbench.seal_paid(before,snapshot(),_workbench_transaction.prepared,_workbench_transaction.completion,_workbench_transaction.original_result)
 if not sealed.ok:return _abort_workbench_owned(sealed.message)
 game.career=(sealed.state.game.career as Dictionary).duplicate(true)
 _workbench_transaction.phase="saving"
 if not _save_draft_owned():
  var producer: bool=_workbench_transaction.before.game.career.get(Workbench.KEY,{}).get("project",{}).get("fragment",{}).has("producer_recipe")
  return _abort_workbench_owned("The session could not be saved. Your whole previous band and direction are retained; try again." if producer else "The session could not be saved. Your whole previous band and words are retained; try again.")
 var original: Dictionary=_workbench_transaction.original_result.duplicate(true)
 original.state=game.career.duplicate(true)
 original["co_writing_message"]=str(sealed.message)
 if game.career.get("last_rehearsal_outcome") is Dictionary:original.outcome=game.career.last_rehearsal_outcome.duplicate(true)
 var reference: Dictionary=game.career.get(Workbench.KEY,{}).get("last_result",{}).get("finished_ref",{}).duplicate(true) if int(_workbench_transaction.prepared.stage)==2 else {}
 _workbench_transaction={}
 _audition_busy=false
 var result:=_workbench_result(true,true,str(sealed.message))
 result["result"]=original
 result["finished_ref"]=reference
 return result
