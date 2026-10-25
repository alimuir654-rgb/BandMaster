extends RefCounted
# Second-hand gear: authoritative per-item condition, holder and provenance.
# Legacy owned_equipment IDs remain valid; unknown history is never invented.
const ITEMS := [
 {"id":"amp","name":"USED COMBO AMP","type":"AMPLIFICATION","price":65,"readiness":5,"condition":77,"description":"Scratched cabinet; surprisingly warm sound."},
 {"id":"mics","name":"PAIR OF STAGE MICS","type":"VOCALS","price":38,"readiness":3,"condition":86,"description":"No-one has to share the singer's microphone."},
 {"id":"pedals","name":"SECOND-HAND EFFECTS PEDALS","type":"GUITARS","price":52,"readiness":4,"condition":69,"description":"A shoebox of pedals. Most of the knobs work."},
 {"id":"drums","name":"RECONDITIONED DRUM KIT","type":"DRUMS","price":120,"readiness":9,"condition":91,"description":"A local rehearsal studio is selling its old kit."},
 {"id":"pa","name":"SMALL PORTABLE PA","type":"LIVE SOUND","price":165,"readiness":11,"condition":83,"description":"For community halls, DIY nights and tiny venues."}
]
const SERVICE_COST := 25
const SERVICE_GAIN := 25
const UNKNOWN_CONDITION := -1

static func item_for(item_id: String) -> Dictionary:
 for item in ITEMS:
  if str(item["id"]) == item_id:
   return item
 return {}

static func compatible(item_id: String, member: Dictionary) -> bool:
 var role := str(member.get("role","")).to_lower()
 match item_id:
  "amp": return role.contains("guitar") or role.contains("bass")
  "mics": return role.contains("vocal") or role.contains("sing")
  "pedals": return role.contains("guitar") or role.contains("bass")
  "drums": return role.contains("drum")
  "pa": return role.contains("vocal") or role.contains("sing")
 return false

static func record(state: Dictionary, item_id: String) -> Dictionary:
 if not (state.get("owned_equipment",[]) as Array).has(item_id):
  return {}
 var saved = state.get("gear_records",{})
 if saved is Dictionary and saved.get(item_id) is Dictionary:
  var entry: Dictionary = saved[item_id].duplicate(true)
  entry["condition"] = clampi(int(entry.get("condition",UNKNOWN_CONDITION)),UNKNOWN_CONDITION,100)
  return entry
 return {"condition":UNKNOWN_CONDITION,"holder_index":-1,"provenance":"Acquired before equipment records began","repairs":0}

static func buy(state: Dictionary, item_id: String) -> Dictionary:
 var found := item_for(item_id)
 if found.is_empty():
  return {"ok":false,"message":"Unknown equipment."}
 var owned: Array = state.get("owned_equipment", [])
 if owned.has(item_id):
  return {"ok":false,"message":"You already own this piece of equipment."}
 var price := int(found["price"])
 if int(state.get("cash",0)) < price:
  return {"ok":false,"message":"You need £%d to buy %s." % [price,found["name"]]}
 var next := state.duplicate(true)
 var inventory: Array = owned.duplicate(true)
 inventory.append(item_id)
 next["owned_equipment"] = inventory
 var records: Dictionary = next.get("gear_records",{}).duplicate(true)
 records[item_id] = {"condition":int(found["condition"]),"holder_index":-1,"provenance":"Bought second-hand from the music shop, day %d" % int(state.get("tour_day",1)),"repairs":0,"purchase_day":int(state.get("tour_day",1))}
 next["gear_records"] = records
 next["cash"] = int(state.get("cash",0)) - price
 next["tour_day"] = int(state.get("tour_day",1)) + 1
 next["gear"] = maxi(int(state.get("gear",0)),0) + 1
 next["readiness"] = clampi(int(state.get("readiness",0)) + int(found["readiness"]),0,100)
 return {"ok":true,"state":next,"message":"Picked up %s for £%d. %s" % [found["name"],price,found["description"]]}

static func assign(state: Dictionary, item_id: String, member_index: int) -> Dictionary:
 if record(state,item_id).is_empty():
  return {"ok":false,"message":"The band does not own that equipment."}
 var roster: Array = state.get("members",[])
 if member_index < 0 or member_index >= roster.size() or not roster[member_index] is Dictionary:
  return {"ok":false,"message":"Choose a current band member."}
 var member: Dictionary = roster[member_index]
 if str(member.get("life_status","active")) != "active" or not compatible(item_id,member):
  return {"ok":false,"message":"That instrument is not suitable for this active musician."}
 var next := state.duplicate(true)
 var records: Dictionary = next.get("gear_records",{}).duplicate(true)
 var entry := record(state,item_id)
 entry["holder_index"] = member_index
 records[item_id] = entry
 next["gear_records"] = records
 return {"ok":true,"state":next,"message":"%s now carries %s. No time or money spent." % [str(member.get("name","Musician")),str(item_for(item_id).get("name",item_id))]}

static func service(state: Dictionary, item_id: String) -> Dictionary:
 var entry := record(state,item_id)
 if entry.is_empty():
  return {"ok":false,"message":"The band does not own that equipment."}
 if int(state.get("cash",0)) < SERVICE_COST:
  return {"ok":false,"message":"Servicing costs £%d." % SERVICE_COST}
 var old := int(entry.get("condition",UNKNOWN_CONDITION))
 if old >= 100:
  return {"ok":false,"message":"This equipment is already in excellent condition."}
 var next := state.duplicate(true)
 var records: Dictionary = next.get("gear_records",{}).duplicate(true)
 entry["condition"] = 80 if old == UNKNOWN_CONDITION else mini(100,old+SERVICE_GAIN)
 entry["repairs"] = int(entry.get("repairs",0)) + 1
 entry["last_service_day"] = int(state.get("tour_day",1))
 records[item_id] = entry
 next["gear_records"] = records
 next["cash"] = int(state.get("cash",0)) - SERVICE_COST
 next["tour_day"] = int(state.get("tour_day",1)) + 1
 return {"ok":true,"state":next,"message":"Serviced %s. Condition is now %d/100." % [str(item_for(item_id).get("name",item_id)),int(entry["condition"])]}

static func readiness_penalty(state: Dictionary) -> int:
 var penalty := 0
 for item_id in state.get("owned_equipment",[]):
  var entry := record(state,str(item_id))
  if int(entry.get("holder_index",-1)) < 0:
   continue
  var roster: Array = state.get("members",[])
  var index := int(entry["holder_index"])
  if index >= roster.size() or not roster[index] is Dictionary or str(roster[index].get("life_status","active")) != "active":
   continue
  var condition := int(entry.get("condition",UNKNOWN_CONDITION))
  if condition >= 0 and condition < 35:
   penalty -= 5
 return maxi(-15,penalty)

static func after_show(state: Dictionary) -> Dictionary:
 # Called only from a successful single-settlement gig.
 var next := state.duplicate(true)
 var records: Dictionary = next.get("gear_records",{}).duplicate(true)
 for item_id in next.get("owned_equipment",[]):
  var entry := record(state,str(item_id))
  var index := int(entry.get("holder_index",-1))
  var roster: Array = state.get("members",[])
  if index < 0 or index >= roster.size() or not roster[index] is Dictionary or str(roster[index].get("life_status","active")) != "active":
   continue
  var condition := int(entry.get("condition",UNKNOWN_CONDITION))
  if condition >= 0:
   entry["condition"] = maxi(0,condition-3)
   records[str(item_id)] = entry
 next["gear_records"] = records
 return next
