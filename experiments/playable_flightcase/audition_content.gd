extends RefCounted
## Authored silent rehearsal study, not audio or an earned career song.
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const VERSION := "s83_jack_written_v1"
const PERSON_ID := "cast_jack"
const ROLE := "Guitarist"
const ROOM := "res://Art/Backgrounds/shared/formation.webp"
const PORTRAIT := "res://Art/References/ApprovedCast20261029/previews/cast_jack.png"
const REQUESTS := ["space_for_voice","own_part"]
const FIRST_ID := "jack_four_bars_original_v1"

static func candidate() -> Dictionary:
 return Cast.by_id(PERSON_ID)

static func catalogue_sha() -> String:
 return FileAccess.get_sha256(Cast.DATA_PATH)

static func material_id(request: String = "") -> String:
 return FIRST_ID if request.is_empty() else "jack_four_bars_"+request+"_v1"

static func response_id(request: String) -> String:
 return "jack_response_"+request+"_v1" if request in REQUESTS else ""

static func bars(request: String = "") -> Array:
 var guitar := ["Held D chord","Brushed G chord","Held A chord","Brushed D chord"]
 var events: Array = [["D"],["G"],["A"],["D"]]
 var kinds := ["chord","chord","chord","chord"]
 if request=="space_for_voice":
  guitar=["Rest — leave space","Brushed G chord","Rest — leave space","Brushed D chord"]
  events=[[],["G"],[],["D"]]
  kinds=["rest","chord","rest","chord"]
 elif request=="own_part":
  guitar=["Light D support","Answer: B – A – G","Light A support","Answer: F# – E – D"]
  events=[["D"],["B","A","G"],["A"],["F#","E","D"]]
  kinds=["chord","answer","chord","answer"]
 var result: Array=[]
 for index in range(4):
  result.append({"number":index+1,"vocal":"Vocal phrase" if index in [0,2] else "Gap in the vocal",
   "vocal_present":index in [0,2],"guitar":guitar[index],"events":events[index].duplicate(),"kind":kinds[index]})
 return result

static func voice(phase: String, request: String = "") -> String:
 if phase=="arrival":
  return "I’m Jack. I’ve mostly played rhythm with friends. I want to get a proper original band going."
 if phase=="tryout":
  return "I’ve put a chord under each bar. Have a look at where the vocal sits. What would you ask me to try?"
 if request=="space_for_voice":
  return "I can leave the chord out while the line is there, then bring it back in the gap. That’s where I’m comfortable."
 return "I usually stay behind the voice. If there’s room for it, I’d try this answer between the lines."

static func fingerprint() -> String:
 return JSON.stringify({"version":VERSION,"original":bars(),"space":bars("space_for_voice"),
  "own":bars("own_part"),"arrival":voice("arrival"),"tryout":voice("tryout"),
  "space_voice":voice("response","space_for_voice"),"own_voice":voice("response","own_part")}).sha256_text()

static func public_person() -> Dictionary:
 var person:=candidate()
 var result: Dictionary={}
 for key in ["id","name","age","town","story","strength","friction","ambition"]:
  result[key]=person.get(key,"")
 result["role"]=ROLE
 return result
