extends RefCounted
# Rehearsal-room decisions with differentiated outcomes and band chemistry.
const Actions = preload("res://Scripts/career_actions.gd")
const FOCUSES := {
 "tighten":{"label":"DRILL THE LIVE SET","action":"rehearse","description":"Improve the set. Perfectionists thrive; restless members tire of repetition."},
 "create":{"label":"WRITE TOGETHER","action":"songwrite","description":"Finish an original song. Creative members flourish, and the setlist grows."},
 "connect":{"label":"CLEAR THE AIR","action":"rest","description":"Talk, share ideas and ease tensions. Rebuild trust before the next show."}
}
static func resolve(state: Dictionary, focus: String) -> Dictionary:
 if not FOCUSES.has(focus):
  return {"ok":false,"message":"Unknown practice-room focus."}
 var rule: Dictionary = FOCUSES[focus]
 var action_id := str(rule["action"])
 var outcome: Dictionary = Actions.resolve(state,action_id)
 if not bool(outcome.get("ok",false)):
  return outcome
 var next: Dictionary = outcome["state"]
 var roster: Array = next.get("members",[])
 var active: Array = []
 for i in range(roster.size()):
  if roster[i] is Dictionary and str(roster[i].get("life_status","active")) == "active":
   active.append(i)
 var reaction := ""
 for index in active:
  var musician: Dictionary = roster[index]
  var trait := str(musician.get("trait","")).to_lower()
  var shift := 0
  match focus:
   "tighten":
    if trait.contains("perfectionist") or trait.contains("control freak") or trait.contains("reliable"):
     shift = 3
    elif trait.contains("restless") or trait.contains("chaos") or trait.contains("unreliable"):
     shift = -3
   "create":
    if trait.contains("creative") or trait.contains("genius") or trait.contains("chaos"):
     shift = 4
    elif trait.contains("perfectionist") or trait.contains("control freak"):
     shift = -1
   "connect":
    shift = 3
  musician["morale"] = clampi(int(musician.get("morale",55)) + shift,0,100)
  if focus == "connect":
   musician["loyalty"] = clampi(int(musician.get("loyalty",60)) + 3,0,100)
 if focus == "connect" and active.size() >= 2:
  var relations: Dictionary = next.get("relationships",{}).duplicate(true)
  for i in range(active.size()):
   for j in range(i+1,active.size()):
    var first := int(active[i])
    var second := int(active[j])
    var pair := "%d_%d" % [mini(first,second),maxi(first,second)]
    relations[pair] = clampi(int(relations.get(pair,50)) + 6,0,100)
  next["relationships"] = relations
  next["tension"] = clampi(int(next.get("tension",0))-5,0,100)
 if focus == "tighten":
  reaction = "The set sounds sharper. Some musicians thrive on discipline; others need space."
 elif focus == "create":
  reaction = "The band finds new ideas together. Creative sparks can divide opinion."
 else:
  reaction = "A proper conversation brings people closer and makes rehearsal feel possible again."
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"room:%s:%d" % [focus,int(next.get("tour_day",1))],"day":int(next.get("tour_day",1)),"title":str(rule["label"]),"text":reaction,"kind":"band"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 outcome["state"] = next
 outcome["message"] = reaction
 return outcome
