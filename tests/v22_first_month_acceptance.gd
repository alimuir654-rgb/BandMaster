extends SceneTree
# Full scripted-intro-to-first-month scenario, including chapter claims.
const Handoff = preload("res://Scripts/opening_handoff.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Chapters = preload("res://Scripts/career_chapters.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
var failures := 0

func _initialize() -> void:
 var save: Dictionary = {"current_event":"aftershow","pending_next":"","tour_day":8,"rehearsal_number":3,
  "cash":135,"morale":62,"readiness":55,"reputation":15,"tension":12,"van_health":75,
  "decisions":{"rehearsal_1":"write","rehearsal_2":"drill","rehearsal_3":"bond","first_gig":"connect"},
  "career_extra":{"songs":0,"fans":12,"gig_history":[],"career_journal":[],"action_counters":{}},
  "band":{"name":"The Circuit","members":[{"name":"Jo","role":"Drummer","trait":"Reliable","skill":50,"morale":60,"loyalty":65,"fatigue":5},{"name":"Alex","role":"Guitarist","trait":"Creative","skill":50,"morale":60,"loyalty":65,"fatigue":5}]},
  "relationships":{"0_1":55}}
 save = Handoff.migrate(save)
 var state: Dictionary = save["career_extra"].duplicate(true)
 for key in ["tour_day","cash","morale","readiness","reputation","tension","van_health"]:
  state[key] = save[key]
 state["members"] = save["band"]["members"].duplicate(true)
 state["relationships"] = save["relationships"].duplicate(true)
 state["band_name"] = save["band"]["name"]
 _check(state.get("gig_history",[]).size() == 1,"intro gig carried over")
 var ticks := 0
 while int(state.get("tour_day",0)) <= 30 and ticks < 80:
  var before := state.duplicate(true)
  var objective: Dictionary = Chapters.progress(state)
  var output: Dictionary = {}
  var source := ""
  var show: Dictionary = Calendar.pending(state)
  if bool(objective.get("ready",false)) and not bool(objective.get("done",false)):
   output = Chapters.claim(state,str(objective["id"]))
  elif not show.is_empty() and int(show.get("day",0)) == int(state.get("tour_day",0)):
   output = Calendar.perform(state)
   source = "gig:"+str(show.get("venue_id",""))
  elif int(state.get("songs",0)) < 3:
   output = Practice.resolve(state,"create")
  elif int(state.get("readiness",0)) < 70:
   output = Practice.resolve(state,"tighten")
  elif show.is_empty():
   output = Calendar.book(state,"local")
  else:
   output = Actions.resolve(state,"rest")
  _check(bool(output.get("ok",false)),"first month step at day %d" % int(state.get("tour_day",0)))
  if not bool(output.get("ok",false)):
   break
  state = Life.refresh(Calendar.expire(Story.observe(before,output["state"],source)))
  var restored = JSON.parse_string(JSON.stringify(state))
  _check(restored is Dictionary,"JSON roundtrip")
  if restored is Dictionary:
   state = restored
  _check(int(state.get("cash",0)) >= 0,"cash safe")
  _check(int(state.get("tour_day",0)) >= int(before.get("tour_day",0)),"time never reverses")
  _check(state.get("gig_history",[]).size() >= 1,"intro gig persists")
  ticks += 1
 _check(int(state.get("tour_day",0)) > 30,"career advances through first month")
 _check(int(state.get("songs",0)) >= 3,"first month can finish three originals")
 _check(state.get("gig_history",[]).size() >= 2,"first month includes subsequent scheduled show")
 var claimed: Dictionary = state.get("career_chapters_claimed",{})
 _check(claimed.has("find_sound"),"opening writing milestone reachable")
 _check(claimed.has("first_crowd"),"intro gig counts to first crowd milestone")
 _check(claimed.has("local_noise"),"local scene milestone reachable")
 _check(int(state.get("song_draft_progress",0)) <= 2,"draft progress bounded")
 print("FIRST MONTH RESULT day=",state.get("tour_day")," songs=",state.get("songs")," gigs=",state.get("gig_history",[]).size()," chapters=",claimed.keys())
 if failures == 0:
  print("V22 FIRST MONTH ACCEPTANCE PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, reason: String) -> void:
 if not ok:
  failures += 1
  push_error("FIRST MONTH ACCEPTANCE FAILURE: "+reason)
