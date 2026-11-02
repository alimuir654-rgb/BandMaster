extends RefCounted
## Pure, versioned room feedback and one contextual live intent. No IO or clocks.
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")
const VERSION := 1
const WARM_ROOM := 42
const INTENTS := ["moment","moving"]

static func whole(value: Variant, low: int = 0, high: int = 2147483647) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=float(low) and float(value)<=float(high)

static func canonical(value: Variant) -> Variant:
 # String dictionary keys survive schema1 JSON. Values retain scalar types and
 # every unknown field; dictionary insertion order never changes a fingerprint.
 if value is Dictionary:
  var names: Array = value.keys()
  names.sort_custom(func(a: Variant,b: Variant) -> bool:return str(a)<str(b))
  var rows: Array=[]
  for key in names:rows.append([str(key),canonical(value[key])])
  return ["dictionary",rows]
 if value is Array:
  var rows: Array=[]
  for item in value:rows.append(canonical(item))
  return ["array",rows]
 return [typeof(value),value]

static func fingerprint(value: Variant) -> String:
 return var_to_bytes(canonical(value)).hex_encode().sha256_text()

static func capture(state: Dictionary, plan: Dictionary) -> Dictionary:
 var checked: Dictionary=Core.validate(state)
 if not bool(checked.get("ok",false)):return checked
 if not whole(state.get("readiness",null),0,100) or not whole(plan.get("intensity",null),0,100):return {"ok":false,"message":"The band's preparation cannot be read safely."}
 var roster: Variant=state.get("members")
 if not roster is Array:return {"ok":false,"message":"The live line-up cannot be read safely."}
 var players: Array=[]
 var actor: Dictionary={}
 for index in range(roster.size()):
  var person: Variant=roster[index]
  if not person is Dictionary:return {"ok":false,"message":"A live musician cannot be read safely."}
  if str(person.get("life_status","active"))!="active":continue
  if not whole(person.get("fatigue",0),0,100):return {"ok":false,"message":"A live musician's preparation cannot be read safely."}
  var id: String=str(person.get("candidate_id",person.get("id","")))
  var item: Dictionary={"slot":index,"key":"slot:%d:%s" % [index,fingerprint(person).left(16)],"candidate_id":id,"name":str(person.get("name","Bandmate")),"role":str(person.get("role","Musician")),"snapshot":person.duplicate(true),"fatigue":int(person.get("fatigue",0))}
  var agreement: Dictionary=checked["core"].get("agreements",{}).get(id,{"excluded":0,"kept":0,"broken":0})
  item["pressure"]=clampi(int(agreement.get("broken",0))+int(agreement.get("excluded",0))-int(agreement.get("kept",0)),0,3) if not id.is_empty() else 0
  item["history"]=agreement.duplicate(true)
  item["recorded_history"]=not id.is_empty() and checked["core"].get("agreements",{}).has(id)
  players.append(item)
  if actor.is_empty() or int(item["fatigue"])>int(actor["fatigue"]):actor=item.duplicate(true)
 if actor.is_empty():return {"ok":false,"message":"There is no active musician for tonight's set."}
 return {"ok":true,"context":{"version":VERSION,"readiness":int(state["readiness"]),"intensity":int(plan["intensity"]),"players":players,"actor":actor}}

static func context_valid(raw: Variant) -> bool:
 if not raw is Dictionary or raw.get("version")!=VERSION or not whole(raw.get("readiness"),0,100) or not whole(raw.get("intensity"),0,100) or not raw.get("players") is Array or not raw.get("actor") is Dictionary:return false
 var actor: Dictionary=raw["actor"]
 if not whole(actor.get("slot"),0) or not whole(actor.get("fatigue"),0,100) or not whole(actor.get("pressure"),0,3) or not actor.get("key") is String or not actor.get("snapshot") is Dictionary:return false
 return not actor["key"].is_empty() and actor["key"]=="slot:%d:%s" % [int(actor["slot"]),fingerprint(actor["snapshot"]).left(16)]

static func song_step(song: Dictionary, context: Dictionary) -> int:
 return clampi(floori((float(song["quality"])-50.0)/15.0)+floori((float(context["readiness"])-50.0)/15.0)-floori(maxf(0.0,float(context["intensity"])-float(context["readiness"]))/20.0),-6,6)

static func intent_effect(context: Dictionary, vibe: int, intent: String) -> Dictionary:
 var actor: Dictionary=context["actor"]
 var fatigue: int=int(actor["fatigue"])
 var pressure: int=int(actor["pressure"])
 var intensity: int=int(context["intensity"])
 if intent=="moment":
  return {"vibe":2 if vibe>=WARM_ROOM else -2,"fatigue":-mini(4,maxi(0,ceili((float(fatigue)-30.0)/15.0))),"tension":-mini(2,pressure) if fatigue>=50 else 0}
 if intent=="moving":
  return {"vibe":clampi(floori((float(context["readiness"])-45.0)/10.0)-floori(maxf(0.0,float(fatigue)-45.0)/15.0),-3,4),"fatigue":mini(4,1+floori(maxf(0.0,float(intensity)-35.0)/25.0)),"tension":mini(3,pressure+maxi(0,floori((float(fatigue)-45.0)/15.0)))}
 return {"vibe":0,"fatigue":0,"tension":0}

static func feedback(plan: Dictionary, context: Dictionary, cursor: int, intent: String = "") -> Dictionary:
 var songs: Array=plan.get("song_snapshots",[])
 var vibe: int=40
 var neutral: int=40
 var records: Array=[]
 var effect: Dictionary={"vibe":0,"fatigue":0,"tension":0}
 for index in range(cursor):
  var step: int=song_step(songs[index],context)
  vibe=clampi(vibe+step,0,100)
  neutral=clampi(neutral+step,0,100)
  records.append({"song_id":str(songs[index]["id"]),"vibe":vibe,"kind":"modelled_song_response"})
  if index==0 and songs.size()>=2 and not intent.is_empty():
   effect=intent_effect(context,vibe,intent)
   vibe=clampi(vibe+int(effect["vibe"]),0,100)
 return {"vibe":vibe,"neutral_vibe":neutral,"records":records,"intent_effect":effect}

static func apply(before: Dictionary, after: Dictionary, active: Dictionary) -> Dictionary:
 var context: Dictionary=active.get("context",{})
 if not context_valid(context):return {"ok":false,"message":"The saved live context is incomplete."}
 var intent: String=str(active.get("intent",""))
 var modeled: Dictionary=feedback(active["plan"],context,int(active["cursor"]),intent)
 var effect: Dictionary=modeled["intent_effect"]
 var difference: int=int(modeled["vibe"])-int(modeled["neutral_vibe"])
 var fans: int=clampi(signi(difference)*floori(absf(float(difference))/2.0),-3,3) if not intent.is_empty() else 0
 var result: Dictionary=after.duplicate(true)
 var actor: Dictionary=context["actor"]
 var slot: int=int(actor["slot"])
 if not result.get("members") is Array or slot>=result["members"].size() or not result["members"][slot] is Dictionary:return {"ok":false,"message":"The live line-up changed before settlement."}
 var changes: Dictionary={}
 for entry in [["fans",fans,2147483647],["tension",int(effect["tension"]),100]]:
  var key: String=str(entry[0])
  if not whole(result.get(key,0),0,int(entry[2])):return {"ok":false,"message":"The show result cannot be adjusted safely."}
  var old: int=int(result.get(key,0))
  var current: int=clampi(old+int(entry[1]),0,int(entry[2]))
  if current!=old:result[key]=current
  changes[key]={"before":old,"after":current,"delta":current-old}
 var member: Dictionary=result["members"][slot].duplicate(true)
 if not whole(member.get("fatigue",0),0,100):return {"ok":false,"message":"The musician's show result cannot be adjusted safely."}
 var previous: int=int(member.get("fatigue",0))
 var current: int=clampi(previous+int(effect["fatigue"]),0,100)
 if current!=previous:
  member["fatigue"]=current
  result["members"][slot]=member
 changes["member_fatigue"]={"slot":slot,"participant_key":str(actor["key"]),"before":previous,"after":current,"delta":current-previous}
 return {"ok":true,"state":result,"actual_effects":changes,"feedback":modeled}
