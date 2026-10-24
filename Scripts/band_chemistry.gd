extends RefCounted
# Interpersonal consequences of creative work; deterministic and save-compatible.
const TRAIT_EFFECTS := {
 "reliable":{"rehearse":2,"songwrite":0,"stress":-1},
 "ambitious":{"rehearse":2,"songwrite":1,"stress":2},
 "creative":{"rehearse":0,"songwrite":3,"stress":0},
 "laid-back":{"rehearse":0,"songwrite":1,"stress":-2},
 "perfectionist":{"rehearse":3,"songwrite":2,"stress":3},
 "restless":{"rehearse":-1,"songwrite":2,"stress":3}
}
static func work(state: Dictionary, action: String) -> Dictionary:
 var next := state.duplicate(true)
 if not ["rehearse","songwrite"].has(action) or not next.has("members"):
  return next
 var participants := 0
 var bonus := 0
 var strain := 0
 for member in next.get("members",[]):
  if not member is Dictionary or str(member.get("life_status","active")) != "active":
   continue
  participants += 1
  var trait := str(member.get("trait","")).to_lower()
  var effects: Dictionary = TRAIT_EFFECTS.get(trait,{})
  bonus += int(effects.get(action,0))
  strain += int(effects.get("stress",0))
  var fatigue_delta := 6 if action == "rehearse" else 3
  member["fatigue"] = clampi(int(member.get("fatigue",0)) + fatigue_delta,0,100)
  member["skill"] = clampi(int(member.get("skill",50)) + (2 if action == "rehearse" else 0),0,100)
  member["morale"] = clampi(int(member.get("morale",50)) + (1 if action == "songwrite" else -1),0,100)
 if participants == 0:
  return next
 next["readiness"] = clampi(int(next.get("readiness",0)) + bonus,0,100)
 next["tension"] = clampi(int(next.get("tension",0)) + int(strain / maxi(1,participants)),0,100)
 var counters: Dictionary = next.get("band_work_counters",{}).duplicate(true)
 counters[action] = int(counters.get(action,0)) + 1
 next["band_work_counters"] = counters
 if int(counters[action]) == 1:
  var journal: Array = next.get("career_journal",[]).duplicate(true)
  journal.append({"id":"work:"+action,"day":int(next.get("tour_day",1)),"title":"IN THE REHEARSAL ROOM" if action == "rehearse" else "THE FIRST WRITING SESSION","text":"The line-up begins finding its sound together.","kind":"band"})
  while journal.size() > 80:
   journal.pop_front()
  next["career_journal"] = journal
 return next
