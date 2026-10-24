extends SceneTree
# Scenario-based end-to-end validation for the playable calendar career.
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
var failures := 0
func _initialize() -> void:
 for horizon in [30,90,180]:
  for persona in ["planner","songwriter","reckless"]:
   _simulate(horizon,persona)
 if failures == 0:
  print("V22 CAMPAIGN SIMULATIONS PASSED: 9 scenarios, 30/90/180 days")
 quit(0 if failures == 0 else 1)

func _initial() -> Dictionary:
 return {"cash":120,"tour_day":1,"morale":60,"tension":12,"readiness":35,"van_health":75,"reputation":10,"fans":0,"songs":0,"buzz":0,"press":0,"career_journal":[],"gig_history":[],"action_counters":{},"opportunities_seen":{},"members":[{"name":"Jo","role":"Drummer","trait":"Reliable","skill":45,"fatigue":0,"loyalty":65,"morale":55,"life_status":"active"},{"name":"Alex","role":"Guitarist","trait":"Creative","skill":55,"fatigue":0,"loyalty":70,"morale":60,"life_status":"active"}]}
func _simulate(horizon: int, persona: String) -> void:
 var state := _initial()
 var shows := 0
 var missed := 0
 var actions := 0
 while int(state.get("tour_day",1)) < horizon and actions < 450:
  var old := state.duplicate(true)
  var show: Dictionary = Calendar.pending(state)
  var outcome: Dictionary = {}
  var label := ""
  if show.is_empty():
   outcome = Calendar.book(state,"local","tight")
   label = "book"
  elif int(state.get("tour_day",1)) == int(show.get("day",999)):
   if persona == "reckless" and (shows + missed) % 3 == 0:
    outcome = Actions.resolve(state,"rest")
    label = "miss"
    missed += 1
   else:
    outcome = Calendar.perform(state)
    label = "perform"
    if bool(outcome.get("ok",false)):
     shows += 1
  else:
   var choice := "rest"
   if persona == "planner":
    choice = "rehearse" if int(state.get("cash",0)) >= 15 and int(state.get("readiness",0)) < 80 else "songwrite"
   elif persona == "songwriter":
    choice = "songwrite" if actions % 3 != 0 else "rest"
   elif persona == "reckless":
    choice = "rest"
   outcome = Practice.resolve(state,"create") if choice == "songwrite" else (Practice.resolve(state,"tighten") if choice == "rehearse" else Actions.resolve(state,choice))
   label = choice
  _check(bool(outcome.get("ok",false)),"%s day %d: %s" % [persona,int(state.get("tour_day",1)),label])
  if not bool(outcome.get("ok",false)):
   break
  state = Calendar.expire(Story.observe(old,outcome["state"],"gig:local" if label == "perform" else label))
  state = Life.refresh(state)
  _check(int(state.get("cash",0)) >= 0,"cash cannot become negative")
  _check(int(state.get("song_draft_progress",0)) >= 0 and int(state.get("song_draft_progress",0)) <= 2,"draft progress bounded")
  _check(int(state.get("morale",0)) >= 0 and int(state.get("morale",0)) <= 100,"morale bounded")
  _check(int(state.get("reputation",0)) >= 0 and int(state.get("reputation",0)) <= 100,"reputation bounded")
  _check(int(state.get("tour_day",0)) >= int(old.get("tour_day",0)),"time monotonic")
  _check(state.get("career_journal",[]).size() <= 80,"journal bounded")
  var encoded := JSON.stringify(state)
  var restored = JSON.parse_string(encoded)
  _check(restored is Dictionary,"save roundtrip")
  if restored is Dictionary:
   state = restored
  actions += 1
 _check(int(state.get("tour_day",1)) >= horizon,"persona reaches simulation horizon")
 _check(shows + missed >= 1,"persona encounters live schedule consequences")
 _check(int(state.get("gig_history",[]).size()) == shows,"played gigs match history")
 print("CAMPAIGN ",persona," horizon=",horizon," days=",state.get("tour_day")," shows=",shows," missed=",missed," songs=",state.get("songs")," cash=",state.get("cash"))

func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V22 CAMPAIGN FAILURE: "+detail)
