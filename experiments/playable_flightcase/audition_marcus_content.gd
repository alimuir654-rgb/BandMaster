extends RefCounted
## Newly authored drum sketch; no performance or skill-rating claim.
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const VERSION := "s114_marcus_drums_written_v1"
const PERSON_ID := "cast_marcus"
const ROLE := "Drummer"
const ROOM := "res://Art/Backgrounds/shared/formation.webp"
const PORTRAIT := "res://Art/References/ApprovedCast20261029/previews/cast_marcus.png"
const REQUESTS := ["space_for_voice","own_part"]
const FIRST_ID := "marcus_four_bars_original_v1"
const HATS := [0.0,0.5,1.0,1.5,2.0,2.5,3.0,3.5]
const SNARE := [1.0,3.0]

static func candidate() -> Dictionary:
 return Cast.by_id(PERSON_ID)

static func catalogue_sha() -> String:
 return FileAccess.get_sha256(Cast.DATA_PATH)

static func material_id(request: String="") -> String:
 return FIRST_ID if request.is_empty() else "marcus_four_bars_"+request+"_v1"

static func response_id(request: String) -> String:
 return "marcus_response_"+request+"_v1" if request in REQUESTS else ""

static func bars(request: String="") -> Array:
 var vocal_kick: Array=[0.0,1.5,2.0]
 var gap_kick: Array=[0.0,2.0,2.75]
 var vocal_part: String="Closed hats on 1, 1&, 2, 2&, 3, 3&, 4, 4&; snare on 2, 4; kick on 1, 2&, 3"
 var gap_part: String="Closed hats on 1, 1&, 2, 2&, 3, 3&, 4, 4&; snare on 2, 4; kick on 1, 3, 3¾"
 if request=="space_for_voice" or request=="own_part":
  vocal_kick=[0.0,2.0]
  vocal_part="Closed hats on 1, 1&, 2, 2&, 3, 3&, 4, 4&; snare on 2, 4; kick on 1, 3"
 if request=="own_part":
  gap_kick=[0.0,1.5,3.5]
  gap_part="Closed hats on 1, 1&, 2, 2&, 3, 3&, 4, 4&; snare on 2, 4; kick on 1, 2&, 4&"
 var result: Array=[]
 for index in range(4):
  var vocal_present: bool=index in [0,2]
  var lanes: Dictionary={"closed_hat":HATS.duplicate(),"snare":SNARE.duplicate(),"kick":(vocal_kick if vocal_present else gap_kick).duplicate()}
  var events: Array=[]
  var beats: Array=[]
  var gates: Array=[]
  for lane in ["closed_hat","snare","kick"]:
   for beat in lanes[lane]:
    events.append(lane)
    beats.append(float(beat))
    gates.append(0.1)
  result.append({"number":index+1,"vocal":"Vocal phrase" if vocal_present else "Gap in the vocal","vocal_present":vocal_present,"part":vocal_part if vocal_present else gap_part,"events":events,"beats":beats,"gates":gates,"lanes":lanes,"kind":"drums"})
 return result

static func voice(phase: String,request: String="") -> String:
 if phase=="arrival":return "I’m Marcus. Show me where the line sits and I’ll find a groove around it."
 if phase=="tryout":return "The kick gives it a little push, but the backbeat stays put. Does that leave the line enough room?"
 if request=="space_for_voice":return "I’ll take the extra kick out while the vocal is there and keep that movement between the lines."
 return "I’d simplify the sung bars, then answer with these two kick accents in the gaps. Let’s run it before we lock it in."

static func fingerprint() -> String:
 return JSON.stringify({"version":VERSION,"original":bars(),"space":bars("space_for_voice"),"own":bars("own_part"),"arrival":voice("arrival"),"tryout":voice("tryout"),"space_voice":voice("response","space_for_voice"),"own_voice":voice("response","own_part")}).sha256_text()

static func public_person() -> Dictionary:
 var person:=candidate()
 var result: Dictionary={}
 for key in ["id","name","age","town","story","strength","friction","ambition"]:result[key]=person.get(key,"")
 result["role"]=ROLE
 return result
