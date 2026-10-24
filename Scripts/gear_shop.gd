extends RefCounted
# Named British second-hand equipment. The former abstract 'gear' tally remains compatible.
const ITEMS := [
 {"id":"amp","name":"USED COMBO AMP","type":"AMPLIFICATION","price":65,"readiness":5,"description":"Scratched cabinet; surprisingly warm sound."},
 {"id":"mics","name":"PAIR OF STAGE MICS","type":"VOCALS","price":38,"readiness":3,"description":"No-one has to share the singer's microphone."},
 {"id":"pedals","name":"SECOND-HAND EFFECTS PEDALS","type":"GUITARS","price":52,"readiness":4,"description":"A shoebox of pedals. Most of the knobs work."},
 {"id":"drums","name":"RECONDITIONED DRUM KIT","type":"DRUMS","price":120,"readiness":9,"description":"A local rehearsal studio is selling its old kit."},
 {"id":"pa","name":"SMALL PORTABLE PA","type":"LIVE SOUND","price":165,"readiness":11,"description":"For community halls, DIY nights and tiny venues."}
]

static func buy(state: Dictionary, item_id: String) -> Dictionary:
 var found: Dictionary = {}
 for item in ITEMS:
  if item["id"] == item_id:
   found = item
   break
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
 next["cash"] = int(state.get("cash",0)) - price
 next["tour_day"] = int(state.get("tour_day",1)) + 1
 next["gear"] = maxi(int(state.get("gear",0)),0) + 1
 next["readiness"] = clampi(int(state.get("readiness",0)) + int(found["readiness"]),0,100)
 return {"ok":true,"state":next,"message":"Picked up %s for £%d. %s" % [found["name"],price,found["description"]]}
