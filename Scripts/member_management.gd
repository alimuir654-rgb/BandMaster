extends RefCounted
# Member actions are deterministic, do not depend on gender, and never mutate input.
const OPTIONS := {
 "chat":{"label":"HEAR THEM OUT","cost":0,"morale":9,"loyalty":5,"fatigue":-3,"tension":-4,"relationship":4},
 "coach":{"label":"ONE-TO-ONE PRACTICE","cost":10,"morale":-2,"loyalty":2,"skill":4,"fatigue":8,"readiness":3},
 "break":{"label":"GIVE THEM A BREAK","cost":0,"morale":8,"loyalty":3,"fatigue":-15,"tension":-3}
}

static func resolve(state: Dictionary, member_index: int, option_id: String) -> Dictionary:
 var members: Array = state.get("members",[])
 if member_index < 0 or member_index >= members.size() or not OPTIONS.has(option_id):
  return {"ok":false,"message":"Member action unavailable."}
 if not members[member_index] is Dictionary:
  return {"ok":false,"message":"Member data unavailable."}
 var rule: Dictionary = OPTIONS[option_id]
 if int(state.get("cash",0)) < int(rule["cost"]):
  return {"ok":false,"message":"Not enough money for this conversation or session."}
 var next := state.duplicate(true)
 var roster: Array = next["members"]
 var member: Dictionary = roster[member_index]
 for key in ["morale","loyalty","skill","fatigue"]:
  member[key] = clampi(int(member.get(key,50)) + int(rule.get(key,0)),0,100)
 next["cash"] = int(next.get("cash",0)) - int(rule["cost"])
 next["tour_day"] = int(next.get("tour_day",1)) + 1
 next["readiness"] = clampi(int(next.get("readiness",0)) + int(rule.get("readiness",0)),0,100)
 next["tension"] = clampi(int(next.get("tension",0)) + int(rule.get("tension",0)),0,100)
 var relations: Dictionary = next.get("relationships",{}).duplicate(true)
 for key in relations:
  if str(key).begins_with("%d_" % member_index) or str(key).ends_with("_%d" % member_index):
   relations[key] = clampi(int(relations[key]) + int(rule.get("relationship",0)),0,100)
 next["relationships"] = relations
 return {"ok":true,"state":next,"message":"%s: %s. Day %d." % [str(member.get("name","Musician")),str(rule["label"]),int(next["tour_day"])]}
