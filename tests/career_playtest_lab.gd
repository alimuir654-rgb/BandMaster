extends SceneTree
const Actions = preload("res://Scripts/career_actions.gd")
const Story = preload("res://Scripts/career_story.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Members = preload("res://Scripts/member_management.gd")
var failures := 0

func _initialize() -> void:
 var strategies := ["writer","gig_first","rehearsal","promoter","balanced","random"]
 for strategy in strategies:
  var state := _initial()
  for day in range(120):
   var previous := state.duplicate(true)
   var id := _decision(strategy,day,state)
   var outcome: Dictionary
   if id == "gig":
    outcome = Gigs.play(state,"local","tight")
   else:
    outcome = Actions.resolve(state,id)
   _check(bool(outcome.get("ok",false)),strategy+" action "+id+" day "+str(day))
   if not outcome.get("ok",false):
    break
   state = Story.observe(previous,outcome["state"],"gig:local" if id == "gig" else id)
   _check(int(state.get("cash",0)) >= 0,"non-negative cash")
   _check(int(state.get("tour_day",1)) > int(previous.get("tour_day",0)),"days advance")
   _check(int(state.get("morale",0)) >= 0 and int(state.get("morale",0)) <= 100,"bounded morale")
   _check(int(state.get("readiness",0)) >= 0 and int(state.get("readiness",0)) <= 100,"bounded readiness")
   _check(state.get("career_journal",[]).size() <= Story.MAX_HISTORY,"bounded journal")
   _check(previous.get("career_journal",[]).size() <= state.get("career_journal",[]).size(),"journal monotonic")
  print("PLAYTEST ",strategy,": day=",state.get("tour_day")," cash=",state.get("cash")," songs=",state.get("songs")," fans=",state.get("fans")," moments=",state.get("career_journal",[]).size())
 _check(Story.record(_initial(),"nonexistent").get("career_journal",[]).is_empty(),"unknown milestones ignored")
 var initial := _initial()
 var first := Story.record(initial,"first_song")
 var second := Story.record(first,"first_song")
 _check(first.get("career_journal",[]).size() == 1,"milestone recorded")
 _check(second.get("career_journal",[]).size() == 1,"milestone idempotent")
 _check(initial.get("career_journal",[]).is_empty(),"immutable journal")
 var encoded := JSON.stringify(first)
 var decoded = JSON.parse_string(encoded)
 _check(decoded is Dictionary and decoded.get("career_journal",[]).size() == 1,"journal JSON save compatibility")
 if failures == 0:
  print("CAREER PLAYTEST LAB PASSED: 6 x 120 turns")
 quit(0 if failures == 0 else 1)

func _initial() -> Dictionary:
 return {"cash":120,"tour_day":1,"morale":60,"tension":10,"readiness":40,"van_health":80,"reputation":20,"fans":12,"songs":0,"buzz":0,"press":0,"career_journal":[],"opportunities_seen":{},"action_counters":{}}

func _decision(strategy: String, turn: int, state: Dictionary) -> String:
 var cash := int(state.get("cash",0))
 if strategy == "writer":
  return "songwrite" if turn % 4 != 0 else "gig"
 if strategy == "gig_first":
  return "gig"
 if strategy == "rehearsal":
  return "rehearse" if cash >= 15 and turn % 3 != 0 else "gig"
 if strategy == "promoter":
  return "promo" if cash >= 25 and turn % 3 != 0 else "gig"
 if strategy == "balanced":
  if cash < 25:
   return "gig"
  return ["songwrite","rehearse","promo","gig","rest"][turn % 5]
 var options := ["songwrite","rehearse","promo","press","rest","gig"]
 var selected: String = options[(turn * 17 + 3) % options.size()]
 if selected == "promo" and cash < 25 or selected == "rehearse" and cash < 15 or selected == "press" and cash < 10:
  return "gig"
 return selected

func _check(ok: bool, description: String) -> void:
 if not ok:
  failures += 1
  push_error("PLAYTEST FAILURE: "+description)
