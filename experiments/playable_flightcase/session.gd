extends RefCounted
## C26 isolated gameplay: reuse genuine recruitment, songwriting, rehearsal rules.
## This code never touches production career saves or replaces catalogue identities.
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const SAVE_PATH := "user://c26_playable_sandbox.json"
var genre: String = ""
var roster: Array = []
var phase: String = "recruit"
var career: Dictionary = {}

func _init() -> void:
 genre = str(Base.genres()[0])

func choices(role: String) -> Array:
 if not Base.ROLE_TABS.has(role):
  return []
 var list: Array = Cast.pool(genre,role)
 for person in Base.people():
  if str(person["id"]) in ["alex","nia_griffiths"] and (person["roles"] as Array).has(role):
   list.push_front(person.duplicate(true))
 return list

func person_by_id(id: String) -> Dictionary:
 for person in Cast.combined_people():
  if str(person.get("id","")) == id:
   return person.duplicate(true)
 return {}

func spent() -> int:
 return Base.spent(roster)
func remaining() -> int:
 return Base.MAX_TALENT-spent()
func can_start() -> bool:
 return Base.viable(roster)

func recruit(id: String) -> Dictionary:
 if phase != "recruit":
  return {"ok":false,"message":"The band is already formed."}
 var person: Dictionary = person_by_id(id)
 if person.is_empty():
  return {"ok":false,"message":"Unknown candidate."}
 if Base.contains(roster,id):
  return {"ok":false,"message":"Already in the band."}
 if roster.size() >= 6:
  return {"ok":false,"message":"Six members is the limit."}
 var price: int = Base.incremental_cost(roster,person)
 if not Base.can_add(roster,person):
  return {"ok":false,"message":"Need %d talent; only %d left." % [price,remaining()]}
 var updated: Array = roster.duplicate(true)
 updated.append(person)
 roster = updated
 return {"ok":true,"message":"Recruited %s for %d talent." % [str(person["name"]),price],"charged":price,"remaining":remaining()}

func remove_member(id: String) -> Dictionary:
 if phase != "recruit":
  return {"ok":false,"message":"Use band management after the first rehearsal."}
 var index := -1
 for i in range(roster.size()):
  if str(roster[i].get("id","")) == id:
   index = i
 if index < 0:
  return {"ok":false,"message":"Not recruited."}
 var before := spent()
 var updated: Array = roster.duplicate(true)
 var removed: Dictionary = updated[index]
 updated.remove_at(index)
 roster = updated
 return {"ok":true,"message":"Removed %s. %d talent returned." % [str(removed["name"]),before-spent()],"refunded":before-spent()}

func _member(person: Dictionary,index: int) -> Dictionary:
 var roles: Array = person.get("roles",["Singer"])
 var role: String = str(person.get("primary_role",roles[0]))
 var stats: Array = Base.stats_for(person,role)
 var total := 0
 for value in stats:
  total += int(value)
 var raw_risk: Dictionary = person.get("rehearsal_risk",{})
 var stable_risk := {"missed_preparation":maxi(0,int(raw_risk.get("missed_preparation",0))),
  "creative_friction":maxi(0,int(raw_risk.get("creative_friction",0)))}
 var collaboration := clampi(int(person.get("collaboration",7)),1,10)
 var trait_name: String = str(person.get("personality","Creative"))
 if bool(person.get("wildcard",false)):
  trait_name = "Restless" if role == "Singer" else "Perfectionist"
 elif trait_name in ["Steady","Dependable"]:
  trait_name = "Reliable"
 return {"id":index,"candidate_id":str(person["id"]),"name":str(person["name"]),
  "role":role,"trait":trait_name,"skill":clampi(roundi(float(total)/6.0*10.0),1,100),
  "loyalty":clampi(40+collaboration*5,0,100),"morale":55,"fatigue":5,
  "life_status":"active","rehearsal_risk":stable_risk}

func launch() -> Dictionary:
 if phase != "recruit":
  return {"ok":false,"message":"The band has already started."}
 if not can_start():
  return {"ok":false,"message":"Still need: "+Base.missing(roster)}
 return _commit_formation("",[])

func launch_with_vocals(lead_id: String,vocal_scores: Array) -> Dictionary:
 # An opening-journey-only option: selected instrumentalist may also sing.
 # Canonical Base.viable remains intact for all previous C26 callers.
 if phase != "recruit":
  return {"ok":false,"message":"The band has already started."}
 var roles: Array = Base.coverage(roster)
 if roster.size()<3 or roster.size()>6 or Base.spent(roster)>Base.MAX_TALENT:
  return {"ok":false,"message":"A valid band needs 3-6 musicians within budget."}
 if not roles.has("Guitarist") or not roles.has("Bassist") or not roles.has("Drummer"):
  return {"ok":false,"message":"Guitar, bass and drums are all required."}
 if not Base.contains(roster,lead_id) or vocal_scores.size()!=6:
  return {"ok":false,"message":"Choose one selected musician for lead vocals."}
 return _commit_formation(lead_id,vocal_scores)

func _commit_formation(lead_id: String,vocal_scores: Array) -> Dictionary:
 var members: Array = []
 for i in range(roster.size()):
  members.append(_member(roster[i],i))
 career = {"band_name":"The First Practice","genre":genre,"members":members,
  "cash":250,"tour_day":1,"readiness":18,"morale":55,"tension":0,
  "songs":0,"song_catalogue":[],"current_song_draft":{},"song_draft_progress":0,
  "fans":0,"buzz":0,"press":0,"gear":0,"gig_history":[],
  "action_count":0,"action_counters":{},"career_journal":[],"relationships":{}}
 if not lead_id.is_empty():
  career["lead_vocal_candidate_id"] = lead_id
  career["lead_vocal_stats"] = vocal_scores.duplicate()
 phase = "play"
 return {"ok":true,"message":"Band formed. Book your first rehearsal."}

func _apply_risk(result: Dictionary,focus: String) -> Dictionary:
 if not bool(result.get("ok",false)):
  return result
 var next: Dictionary = result["state"]
 var tension_gain := 0
 var lost_readiness := 0
 for person in next.get("members",[]):
  if not person is Dictionary or str(person.get("life_status","active")) != "active":
   continue
  var risk: Dictionary = person.get("rehearsal_risk",{})
  if focus == "create":
   tension_gain += maxi(0,int(risk.get("creative_friction",0)))
  elif focus == "tighten":
   lost_readiness += maxi(0,int(risk.get("missed_preparation",0)))
 if tension_gain > 0:
  next["tension"] = clampi(int(next.get("tension",0))+tension_gain,0,100)
  result["message"] = str(result["message"])+" Creative disagreements add %d tension." % tension_gain
 if lost_readiness > 0:
  next["readiness"] = clampi(int(next.get("readiness",0))-lost_readiness,0,100)
  result["message"] = str(result["message"])+" Missed preparation costs %d readiness." % lost_readiness
 result["state"] = next
 return result

func write_session(idea: String,form: String,title: String,leader_index: int) -> Dictionary:
 if phase != "play":
  return {"ok":false,"message":"Recruit a viable band first."}
 var result: Dictionary = _apply_risk(Practice.compose(career,idea,form,title,leader_index),"create")
 if bool(result.get("ok",false)):
  career = (result["state"] as Dictionary).duplicate(true)
 return result

func rehearse() -> Dictionary:
 if phase != "play":
  return {"ok":false,"message":"Recruit a viable band first."}
 var result: Dictionary = _apply_risk(Practice.resolve(career,"tighten"),"tighten")
 if bool(result.get("ok",false)):
  career = (result["state"] as Dictionary).duplicate(true)
 return result

func clear_air() -> Dictionary:
 if phase != "play":
  return {"ok":false,"message":"Recruit a viable band first."}
 var result: Dictionary = Practice.resolve(career,"connect")
 if bool(result.get("ok",false)):
  career = (result["state"] as Dictionary).duplicate(true)
 return result

func snapshot() -> Dictionary:
 return {"schema_version":1,"genre":genre,"roster":roster.duplicate(true),
  "phase":phase,"career":career.duplicate(true)}

func restore(data: Dictionary) -> bool:
 if int(data.get("schema_version",0)) != 1:
  return false
 var saved_roster: Variant = data.get("roster",[])
 if not saved_roster is Array or saved_roster.size() > 6:
  return false
 var trial: Array = []
 for saved in saved_roster:
  if not saved is Dictionary:
   return false
  var canonical: Dictionary = person_by_id(str(saved.get("id","")))
  if canonical.is_empty() or not Base.can_add(trial,canonical):
   return false
  trial.append(canonical)
 var requested_phase := str(data.get("phase",""))
 var saved_state: Variant = data.get("career",{})
 if requested_phase not in ["recruit","play"] or not saved_state is Dictionary:
  return false
 if requested_phase == "play":
  if not Base.viable(trial):
   var roles: Array = Base.coverage(trial)
   var lead_id: String = str(saved_state.get("lead_vocal_candidate_id",""))
   var vocal_values: Variant = saved_state.get("lead_vocal_stats",[])
   if trial.size()<3 or not roles.has("Guitarist") or not roles.has("Bassist") or not roles.has("Drummer"):
    return false
   if not Base.contains(trial,lead_id) or not vocal_values is Array or vocal_values.size()!=6:
    return false
  var members: Variant = saved_state.get("members",[])
  if not members is Array or members.size() != trial.size():
   return false
  for i in range(trial.size()):
   if not members[i] is Dictionary or str(members[i].get("candidate_id","")) != str(trial[i]["id"]):
    return false
  if int(saved_state.get("cash",-1)) < 0:
   return false
 var incoming_genre := str(data.get("genre",""))
 if not Base.genres().has(incoming_genre):
  return false
 genre = incoming_genre
 roster = trial
 phase = requested_phase
 career = (saved_state as Dictionary).duplicate(true)
 return true

func save_sandbox() -> bool:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  return false
 file.store_string(JSON.stringify(snapshot(),"  "))
 file.close()
 return true

func _restore_integral_numbers(value: Variant) -> Variant:
 # Godot's JSON parser returns 5.0 for an encoded integer 5; this v1
 # sandbox schema uses integers only. Preserve nested career field types.
 if value is Dictionary:
  var result: Dictionary = {}
  for key in value:
   result[key] = _restore_integral_numbers(value[key])
  return result
 if value is Array:
  var result: Array = []
  for entry in value:
   result.append(_restore_integral_numbers(entry))
  return result
 if value is float and absf(value) < 1000000000.0 and value == floor(value):
  return int(value)
 return value

func load_sandbox() -> bool:
 if not FileAccess.file_exists(SAVE_PATH):
  return false
 var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
 return restore(_restore_integral_numbers(value) as Dictionary) if value is Dictionary else false
