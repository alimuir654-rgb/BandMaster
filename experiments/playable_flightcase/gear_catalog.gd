extends RefCounted
## Owned shop additions. The original five offers/rules remain authoritative.
## No inventory is created by browsing and no historic personal kit is invented.
const Original = preload("res://Scripts/gear_shop.gd")
const SERVICE_COST = Original.SERVICE_COST
const SERVICE_GAIN = Original.SERVICE_GAIN
const UNKNOWN_CONDITION = Original.UNKNOWN_CONDITION
const PREMIUM := [
 {"id":"shop_guitar_new","name":"NEW ELECTRIC GUITAR","type":"GUITARS","price":450,"readiness":5,"condition":100,"description":"A new six-string electric. A serious purchase for the band's road case.","stock":"NEW"},
 {"id":"shop_bass_new","name":"NEW BASS GUITAR","type":"BASS","price":500,"readiness":5,"condition":100,"description":"A new four-string bass, bought for the band rather than borrowed for a night.","stock":"NEW"},
 {"id":"shop_cymbals_new","name":"NEW CYMBAL SET","type":"DRUMS","price":300,"readiness":4,"condition":100,"description":"A new set of cymbals and stands for the drummer's setup.","stock":"NEW"}
]

static func items() -> Array:
 var result: Array=Original.ITEMS.duplicate(true)
 result.append_array(PREMIUM.duplicate(true))
 return result

static func premium_for(id: String) -> Dictionary:
 for raw in PREMIUM:
  if str(raw["id"])==id:return raw.duplicate(true)
 return {}

static func item_for(id: String) -> Dictionary:
 var old: Dictionary=Original.item_for(id)
 return old if not old.is_empty() else premium_for(id)

static func compatible(id: String, member: Dictionary) -> bool:
 var role: String=str(member.get("role","")).to_lower()
 match id:
  "shop_guitar_new":return role.contains("guitar")
  "shop_bass_new":return role.contains("bass")
  "shop_cymbals_new":return role.contains("drum")
 return Original.compatible(id,member)

static func record(state: Dictionary, id: String) -> Dictionary:
 return Original.record(state,id)

static func holder_index(state: Dictionary, entry: Dictionary) -> int:
 return Original.holder_index(state,entry)

static func buy(state: Dictionary, id: String) -> Dictionary:
 var item: Dictionary=premium_for(id)
 if item.is_empty():return Original.buy(state,id)
 var owned: Variant=state.get("owned_equipment",[])
 var saved: Variant=state.get("gear_records",{})
 if not owned is Array or not saved is Dictionary:return {"ok":false,"message":"The equipment records could not be read."}
 if owned.has(id):return {"ok":false,"message":"You already own this piece of equipment."}
 var price: int=int(item["price"])
 if int(state.get("cash",0))<price:return {"ok":false,"message":"You need £%d to buy %s." % [price,item["name"]]}
 var next: Dictionary=state.duplicate(true)
 var inventory: Array=owned.duplicate(true)
 inventory.append(id)
 next["owned_equipment"]=inventory
 var records: Dictionary=saved.duplicate(true)
 records[id]={"condition":100,"holder_index":-1,"provenance":"Bought new from the music shop, day %d" % int(state.get("tour_day",1)),"repairs":0,"purchase_day":int(state.get("tour_day",1))}
 next["gear_records"]=records
 next["cash"]=int(state.get("cash",0))-price
 next["tour_day"]=int(state.get("tour_day",1))+1
 next["gear"]=maxi(int(state.get("gear",0)),0)+1
 next["readiness"]=clampi(int(state.get("readiness",0))+int(item["readiness"]),0,100)
 return {"ok":true,"state":next,"message":"Picked up %s for £%d. %s" % [item["name"],price,item["description"]]}

static func assign(state: Dictionary, id: String, member_index: int) -> Dictionary:
 if premium_for(id).is_empty():return Original.assign(state,id,member_index)
 if record(state,id).is_empty():return {"ok":false,"message":"The band does not own that equipment."}
 var roster: Array=state.get("members",[])
 if member_index<0 or member_index>=roster.size() or not roster[member_index] is Dictionary:return {"ok":false,"message":"Choose a current band member."}
 var member: Dictionary=roster[member_index]
 if str(member.get("life_status","active"))!="active" or not compatible(id,member):return {"ok":false,"message":"That instrument is not suitable for this active musician."}
 if holder_index(state,record(state,id))==member_index:return {"ok":false,"message":"This musician already carries that equipment."}
 var next: Dictionary=state.duplicate(true)
 var records: Dictionary=next.get("gear_records",{}).duplicate(true)
 var entry: Dictionary=record(state,id)
 entry["holder_index"]=member_index
 entry["holder_name"]=str(member.get("name",""))
 entry["holder_role"]=str(member.get("role",""))
 entry["holder_id"]=str(member.get("candidate_id",member.get("id","")))
 records[id]=entry
 next["gear_records"]=records
 return {"ok":true,"state":next,"message":"%s now carries %s. No time or money spent." % [str(member.get("name","Musician")),str(item_for(id)["name"])]}

static func service(state: Dictionary, id: String) -> Dictionary:
 var result: Dictionary=Original.service(state,id)
 if not premium_for(id).is_empty() and bool(result.get("ok",false)):
  result["message"]="Serviced %s. Condition is now %d/100." % [str(item_for(id)["name"]),int(record(result["state"],id).get("condition",UNKNOWN_CONDITION))]
 return result

static func readiness_penalty(state: Dictionary) -> int:
 return Original.readiness_penalty(state)

static func after_show(state: Dictionary) -> Dictionary:
 return Original.after_show(state)
