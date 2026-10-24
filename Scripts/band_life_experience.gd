extends RefCounted
# Player-facing previews; authoritative costs and outcomes remain in gameplay engines.
const Social = preload("res://Scripts/band_social.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Members = preload("res://Scripts/member_management.gd")

static func social_options(state: Dictionary) -> Array:
 var present := 0
 for item in state.get("members",[]):
  if item is Dictionary and str(item.get("life_status","active")) == "active":
   present += 1
 var result: Array = []
 for id in ["dinner","drinks","watch_gig"]:
  var rule: Dictionary = Social.ACTIVITIES[id]
  var cost := int(rule["cost_per_member"])*present
  result.append({"id":id,"title":str(rule["label"]),"story":str(rule["text"]),"cost":cost,"enabled":present>=2 and int(state.get("cash",0))>=cost,"impact":"MORALE %+d   TRUST %+d   BUZZ %+d" % [int(rule["morale"]),int(rule["trust"]),int(rule["buzz"])]})
 return result

static func practice_options(state: Dictionary) -> Array:
 var result: Array = []
 for id in ["tighten","connect"]:
  var rule: Dictionary = Practice.FOCUSES[id]
  var base: Dictionary = Actions.ACTIONS[str(rule["action"])]
  var cost := int(base.get("cost",0))
  result.append({"id":id,"title":str(rule["label"]),"story":str(rule["description"]),"cost":cost,"enabled":int(state.get("cash",0))>=cost,"impact":"1 DAY  /  LIVE READINESS" if id=="tighten" else "1 DAY  /  TRUST & RECOVERY"})
 return result

static func member_options(state: Dictionary, member_index: int) -> Array:
 var roster: Array = state.get("members",[])
 if member_index < 0 or member_index >= roster.size() or not roster[member_index] is Dictionary:
  return []
 var member: Dictionary = roster[member_index]
 var active := str(member.get("life_status","active"))=="active"
 var result: Array = []
 for id in ["chat","coach","break"]:
  var rule: Dictionary = Members.OPTIONS[id]
  var cost := int(rule["cost"])
  var impact := "MORALE %+d   LOYALTY %+d   FATIGUE %+d" % [int(rule.get("morale",0)),int(rule.get("loyalty",0)),int(rule.get("fatigue",0))]
  result.append({"id":id,"title":str(rule["label"]),"cost":cost,"enabled":active and int(state.get("cash",0))>=cost,"impact":impact})
 return result

static func day_context(state: Dictionary) -> Dictionary:
 var active := 0
 var tired := 0
 for member in state.get("members",[]):
  if member is Dictionary and str(member.get("life_status","active"))=="active":
   active += 1
   if int(member.get("fatigue",0))>=70:
    tired += 1
 var lead := "WRITE YOUR NEXT CHAPTER"
 var detail := "Rehearse, spend time together or build an audience. Every decision advances the band's story."
 if tired>0:
  lead = "THE BAND NEEDS BREATHING ROOM"
  detail = "%d musician(s) are exhausted. Rest and time together may help before the next show." % tired
 elif int(state.get("tension",0))>=65:
  lead = "TENSION IN THE ROOM"
  detail = "Not everyone is seeing eye to eye. A rehearsal alone might not solve it."
 return {"title":lead,"detail":detail,"active":active}
