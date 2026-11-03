extends RefCounted
## Authored guitar exercise; not an earned song or a musical rating.
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const VERSION := "s100_arjun_written_v1"
const PERSON_ID := "cast_arjun"
const ROLE := "Guitarist"
const ROOM := "res://Art/Backgrounds/shared/formation.webp"
const PORTRAIT := "res://Art/References/ApprovedCast20261029/previews/cast_arjun.png"
const REQUESTS := ["space_for_voice","own_part"]
const FIRST_ID := "arjun_four_bars_original_v1"

static func candidate() -> Dictionary:
 return Cast.by_id(PERSON_ID)

static func catalogue_sha() -> String:
 return FileAccess.get_sha256(Cast.DATA_PATH)

static func material_id(request: String="") -> String:
 return FIRST_ID if request.is_empty() else "arjun_four_bars_"+request+"_v1"

static func response_id(request: String) -> String:
 return "arjun_response_"+request+"_v1" if request in REQUESTS else ""

static func bars(request: String="") -> Array:
 var parts: Array=["Picked Dadd9; upper F#–G–F#–D","G6 voicing; picked E–B–G–D","A6 voicing; picked F#–C#–A–E","D voicing; F#–E resolves to D"]
 var events: Array=[["D","A","E","F#","G","F#","D"],["G","B","D","G","B","E","E","B","G","D","D","E"],["A","E","A","C#","F#","F#","C#","A","E","E","F#","D"],["D","A","D","F#","E","D","A","D","F#"]]
 var kinds: Array=["picked","picked","picked","chord"]
 if request=="space_for_voice":
  parts=["Rest — leave space","G6 voicing in the gap","Rest — leave space","D chord in the gap"]
  events=[[],["G","B","D","E"],[],["D","A","D","F#"]]
  kinds=["rest","chord","rest","chord"]
 elif request=="own_part":
  parts=["Light D support","Answer: E–F#–G–F#–D","Light A support","Short answer: F#–E–D"]
  events=[["D"],["E","F#","G","F#","D"],["A"],["F#","E","D"]]
  kinds=["chord","answer","chord","answer"]
 var result: Array=[]
 for index in range(4):
  result.append({"number":index+1,"vocal":"Vocal phrase" if index in [0,2] else "Gap in the vocal","vocal_present":index in [0,2],"guitar":parts[index],"events":events[index].duplicate(),"kind":kinds[index]})
 return result

static func voice(phase: String,request: String="") -> String:
 if phase=="arrival":return "I’m Arjun. I like finding different voicings around a song. Let’s see what leaves room for the rest of the band."
 if phase=="tryout":return "I’ve used some higher notes over D, G and A. Does that sit around the vocal, or is it getting too busy?"
 if request=="space_for_voice":return "Fair. I’ll keep those upper notes out while the line is there, then let the chord speak in the gap."
 return "I’d move the little rising line into the gap, then answer it with a shorter ending. Tell me if it starts crowding the song."

static func fingerprint() -> String:
 return JSON.stringify({"version":VERSION,"original":bars(),"space":bars("space_for_voice"),"own":bars("own_part"),"arrival":voice("arrival"),"tryout":voice("tryout"),"space_voice":voice("response","space_for_voice"),"own_voice":voice("response","own_part")}).sha256_text()

static func public_person() -> Dictionary:
 var person:=candidate()
 var result: Dictionary={}
 for key in ["id","name","age","town","story","strength","friction","ambition"]:result[key]=person.get(key,"")
 result["role"]=ROLE
 return result
