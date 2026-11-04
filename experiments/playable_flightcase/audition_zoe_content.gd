extends RefCounted
## Newly authored bass exercise, not a recording or a skill rating.
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const VERSION := "s112_zoe_bass_written_v1"
const PERSON_ID := "cast_zoe"
const ROLE := "Bassist"
const ROOM := "res://Art/Backgrounds/shared/formation.webp"
const PORTRAIT := "res://Art/References/ApprovedCast20261029/previews/cast_zoe.png"
const REQUESTS := ["space_for_voice","own_part"]
const FIRST_ID := "zoe_four_bars_original_v1"

static func candidate() -> Dictionary:
 return Cast.by_id(PERSON_ID)

static func catalogue_sha() -> String:
 return FileAccess.get_sha256(Cast.DATA_PATH)

static func material_id(request: String="") -> String:
 return FIRST_ID if request.is_empty() else "zoe_four_bars_"+request+"_v1"

static func response_id(request: String) -> String:
 return "zoe_response_"+request+"_v1" if request in REQUESTS else ""

static func bars(request: String="") -> Array:
 var parts: Array=["D2 on 1, 2&, 3, 4&","G2 on 1, 2, 3&, 4&","A2 on 1, 2&, 3, 4&","D2 on 1, 2, 3&, 4&"]
 var events: Array=[["D2","D2","D2","D2"],["G2","G2","G2","G2"],["A2","A2","A2","A2"],["D2","D2","D2","D2"]]
 var beats: Array=[[0.0,1.5,2.0,3.5],[0.0,1.0,2.5,3.5],[0.0,1.5,2.0,3.5],[0.0,1.0,2.5,3.5]]
 var gates: Array=[[0.7,0.4,0.4,0.25],[0.7,0.4,0.4,0.25],[0.7,0.4,0.4,0.25],[0.7,0.4,0.4,0.25]]
 if request=="space_for_voice":
  parts=["Hold D2 for 3.2 beats; no pickup","G2 on 1, 3&, 4&","Hold A2 for 3.2 beats; no pickup","D2 on 1 and 4"]
  events=[["D2"],["G2","G2","G2"],["A2"],["D2","D2"]]
  beats=[[0.0],[0.0,2.5,3.5],[0.0],[0.0,3.0]]
  gates=[[3.2],[0.7,0.4,0.25],[3.2],[0.7,0.25]]
 elif request=="own_part":
  parts=["D2 on 1 and 3","G2 on 1; D2 on 3&; G2 on 4&","A2 on 1 and 3","D2 on 1; A2 on 3&; D2 on 4&"]
  events=[["D2","D2"],["G2","D2","G2"],["A2","A2"],["D2","A2","D2"]]
  beats=[[0.0,2.0],[0.0,2.5,3.5],[0.0,2.0],[0.0,2.5,3.5]]
  gates=[[0.7,0.25],[0.7,0.4,0.25],[0.7,0.25],[0.7,0.4,0.25]]
 var result: Array=[]
 for index in range(4):
  result.append({"number":index+1,"vocal":"Vocal phrase" if index in [0,2] else "Gap in the vocal","vocal_present":index in [0,2],"part":parts[index],"events":events[index].duplicate(),"beats":beats[index].duplicate(),"gates":gates[index].duplicate(),"kind":"bass"})
 return result

static func voice(phase: String,request: String="") -> String:
 if phase=="arrival":return "I’m Zoe. I’ve brought a bass line with a little push before the chord changes. Let’s see where it sits around the vocal."
 if phase=="tryout":return "I like that short pickup. It gives the line a bit of movement without filling the whole bar. What would you change?"
 if request=="space_for_voice":return "I’d miss that little push, but I can try holding the root while the vocal is there. I’ll put the movement in the gaps."
 return "I’d keep the sung bars simple, then use this short fifth-and-return in the gaps. It should still leave somewhere for the next line to land."

static func fingerprint() -> String:
 return JSON.stringify({"version":VERSION,"original":bars(),"space":bars("space_for_voice"),"own":bars("own_part"),"arrival":voice("arrival"),"tryout":voice("tryout"),"space_voice":voice("response","space_for_voice"),"own_voice":voice("response","own_part")}).sha256_text()

static func public_person() -> Dictionary:
 var person:=candidate()
 var result: Dictionary={}
 for key in ["id","name","age","town","story","strength","friction","ambition"]:result[key]=person.get(key,"")
 result["role"]=ROLE
 return result
