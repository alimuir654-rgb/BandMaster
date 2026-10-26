extends SceneTree
# One continuous persisted band career: finish a real original, book a show,
# advance to the date, travel through all five places, play once, revisit the
# scrapbook and reopen the same save. Formation has its own separate UI gate.
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Journey = preload("res://Scripts/show_day_journey.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
const SAVE_PATH := "user://tour_save.json"
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var previous := FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
 var fixture := {
  "band":{"name":"The Night Shift","genre":"indie","members":[
   {"name":"Jo","role":"Guitarist","life_status":"active","trait":"Creative","skill":65,"fatigue":10,"loyalty":65,"morale":65},
   {"name":"Lee","role":"Drummer","life_status":"active","trait":"Reliable","skill":65,"fatigue":12,"loyalty":70,"morale":65},
   {"name":"Sam","role":"Bassist","life_status":"active","trait":"Calm","skill":60,"fatigue":10,"loyalty":60,"morale":60}
  ]},
  "cash":400,"tour_day":7,"morale":75,"reputation":25,"readiness":80,"tension":12,"van_health":90,
  "relationships":{"0_1":55},
  "career_extra":{"songs":1,"fans":40,"owned_equipment":[],"gig_history":[],"career_journal":[],"action_counters":{},
   "song_draft_progress":2,
   "current_song_draft":{"title":"LAST TRAIN HOME","idea":"Riff","form":"Slow Build","leader":"Jo","sessions":[
    {"day":5,"leader":"Jo","idea":"Riff","form":"Loose Jam"},{"day":6,"leader":"Lee","idea":"Lyric","form":"Slow Build"}
   ]},
   "song_catalogue":[{"title":"OLD SONG","lead_writer":"Lee","quality":70,"written_day":4}]}
 }
 _write(JSON.stringify(fixture))
 var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(packed != null,"CareerHub loads")
 if packed != null:
  var ui: Control = packed.instantiate()
  get_root().add_child(ui)
  ui._open_songwriting_journey()
  await process_frame
  var writing := ui.find_child("SongwritingJourney",true,false)
  _check(writing != null,"writing journey starts")
  if writing != null:
   writing.reduced_motion = true
   var title := writing.find_child("JourneyTitleInput",true,false) as LineEdit
   if title != null:
    title.text = "LAST TRAIN HOME"
   writing._go(1)
   writing._go(2)
   writing._go(3)
   writing._commit()
   await process_frame
  _check(int(ui._state().get("songs",0)) == 2,"original completed through writing journey")
  _check(int(ui._state().get("tour_day",0)) == 8,"songwriting costs exactly one day")
  _check(ui._state().get("song_catalogue",[]).size() == 2,"real song persisted")
  ui._finish(Calendar.book(ui._state(),"local"))
  var show: Dictionary = Calendar.pending(ui._state())
  _check(not show.is_empty(),"promoter booking committed")
  var due := int(show.get("day",0))
  _check(due > 8,"booking is in future")
  var guard := 0
  while int(ui._state().get("tour_day",0)) < due and guard < 10:
   ui._finish(Actions.resolve(ui._state(),"rest"))
   guard += 1
  _check(int(ui._state().get("tour_day",0)) == due,"arrived on booked show date")
  ui.tab = "GIGS"
  ui._render()
  ui._open_show_day_journey()
  await process_frame
  var road := ui.find_child("ShowDayJourney",true,false)
  _check(road != null,"show-day journey opens")
  if road != null:
   road.reduced_motion = true
   for step in range(5):
    _check(Journey.current_step(ui._state()) == step,"show journey step "+str(step))
    if step == 3:
     # Resolve only an actually triggered incident; no fabricated drama.
     var real_incident = Backstage.incident(ui._state())
     if not real_incident.is_empty():
      road._resolve_incident(str(real_incident.get("options",[])[0].get("id","rest")))
    if step < 4:
     road._advance()
     await process_frame
   _check(Journey.ready_to_perform(ui._state()),"showtime unlocks")
   ui._perform_gig()
   await process_frame
  var after := ui._state()
  _check(after.get("gig_history",[]).size() == 1,"show settles once")
  _check(Calendar.pending(after).is_empty(),"booking cleared")
  var settled_cash := int(after.get("cash",0))
  ui._perform_gig()
  _check(ui._state().get("gig_history",[]).size() == 1 and int(ui._state().get("cash",0)) == settled_cash,"no duplicate payout")
  ui.tab = "SCENE"
  ui.scene_view = "HISTORY"
  ui._render()
  await process_frame
  _check(ui.find_child("CareerWorldArtwork",true,false) != null,"scrapbook scene has its own artwork")
  ui.free()
  await process_frame
  var restored: Control = packed.instantiate()
  get_root().add_child(restored)
  _check(restored._state().get("gig_history",[]).size() == 1,"show history survives restart")
  _check(restored._state().get("song_catalogue",[]).size() == 2,"song survives restart")
  _check(Calendar.pending(restored._state()).is_empty(),"booking remains cleared on reload")
  restored.free()
 if existed:
  _write(previous)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT C CONTINUOUS CAREER JOURNEY PASSED")
 quit(0 if failures == 0 else 1)

func _write(value: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file != null:
  file.store_string(value)
  file.close()

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT C CAREER FAILURE: "+reason)
