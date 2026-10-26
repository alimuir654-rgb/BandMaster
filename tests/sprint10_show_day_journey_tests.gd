extends SceneTree
# Populated five-place gig journey: real state, disk persistence and once-only settlement.
const SAVE_PATH := "user://tour_save.json"
const SIZES := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
const Journey = preload("res://Scripts/show_day_journey.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var original := FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
 var fixture := {
  "band":{"name":"Night Drive","genre":"indie","members":[
   {"name":"Jo","role":"Guitarist","life_status":"active","trait":"Creative","skill":65,"fatigue":10,"loyalty":65,"morale":65},
   {"name":"Lee","role":"Drummer","life_status":"active","trait":"Reliable","skill":65,"fatigue":12,"loyalty":70,"morale":65},
   {"name":"Sam","role":"Bassist","life_status":"active","trait":"Calm","skill":60,"fatigue":65,"loyalty":60,"morale":60}
  ]},
  "cash":250,"tour_day":7,"morale":75,"reputation":25,"readiness":80,"tension":12,"van_health":90,
  "relationships":{"0_1":55},
  "career_extra":{"songs":2,"fans":40,"owned_equipment":["amp"],"gear_records":{"amp":{"condition":72,"holder_index":-1,"provenance":"Test shop","repairs":0}},"gig_history":[],"career_journal":[],"action_counters":{},
   "booked_show":{"venue_id":"bristol","venue":"The Copper Fox","city":"BRISTOL","day":7,"approach":"tight","session_drummer":false,"travel_plan":"drive_home"},
   "gig_night_phase":"arrival"}
 }
 var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(packed != null,"CareerHub loads")
 if packed != null:
  for size in SIZES:
   _write(JSON.stringify(fixture))
   get_root().size = size
   var ui: Control = packed.instantiate()
   get_root().add_child(ui)
   ui.tab = "GIGS"
   ui._render()
   await process_frame
   await process_frame
   ui._open_show_day_journey()
   await process_frame
   var view := ui.find_child("ShowDayJourney",true,false)
   _check(view != null,"journey opens "+str(size))
   if view != null:
    view.reduced_motion = true
    var planes := view.find_child("ShowJourneyScenePlanes",true,false)
    _check(planes != null,"show journey planes exist "+str(size))
    if planes != null:
     _check((planes is HBoxContainer) == (size.x >= 960),"cinematic show split only in landscape "+str(size))
    _check((view.find_child("ShowJourneyStoryPanel",true,false) != null) == (size.x >= 960),"landscape show reading surface "+str(size))
    for step in range(5):
     _check(Journey.current_step(ui._state()) == step,"correct step "+str(step)+" "+str(size))
     _check(_art(view),"real art loaded for step "+str(step)+" "+str(size))
     var next := view.find_child("ShowJourneyNext",true,false) as Button
     _check(next != null and next.custom_minimum_size.y >= 44 and next.focus_mode == Control.FOCUS_ALL,"accessible next "+str(step)+" "+str(size))
     if step == 0:
      var load_button := _button(view,"LOAD WITH JO")
      _check(load_button != null and load_button.custom_minimum_size.y >= 44,"real loading crew decision accessible "+str(size))
      view._assign_loading_gear("amp",0)
      _check(int(ui._state().get("gear_records",{}).get("amp",{}).get("holder_index",-1)) == 0,"crew equipment assignment persisted in game state "+str(size))
      _check(int(ui._state().get("tour_day",0)) == 7 and int(ui._state().get("cash",0)) == 250,"loading gear costs no day or cash "+str(size))
      var loading_disk = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
      _check(loading_disk is Dictionary and int(loading_disk.get("career_extra",{}).get("gear_records",{}).get("amp",{}).get("holder_index",-1)) == 0,"gear loading saved to disk "+str(size))
      view._assign_loading_gear("amp",0)
      _check(int(ui._state().get("gear_records",{}).get("amp",{}).get("holder_index",-1)) == 0,"repeat loading cannot mutate owner "+str(size))
     if step == 1:
      view._replan(Tour.OVERNIGHT)
      _check(str(ui._state().get("booked_show",{}).get("travel_plan","")) == Tour.OVERNIGHT,"overnight plan persisted "+str(size))
      _check(int(ui._state().get("cash",0)) == 250,"replan costs nothing "+str(size))
     if step == 3:
      _check(view.find_child("ShowJourneyNext",true,false).disabled,"backstage decision blocks premature showtime "+str(size))
      view._resolve_incident("rest")
      print("SPRINT B ILLNESS STATE ",JSON.stringify({"phase":ui._state().get("gig_night_phase",""),"resolved":ui._state().get("illness_resolved_booking",""),"status":view.status_message}))
      _check(str(ui._state().get("illness_resolved_booking","")) == "bristol:7","backstage resolution recorded "+str(size))
      view._choose_approach("crowd")
      _check(str(ui._state().get("booked_show",{}).get("approach","")) == "crowd","live set decision saved "+str(size))
     if step < 4:
      view._advance()
      await process_frame
      _check(int(ui._state().get("tour_day",0)) == 7 and int(ui._state().get("cash",0)) == 250,"scene change spends no day/cash "+str(step)+" "+str(size))
    _check(Journey.ready_to_perform(ui._state()),"showtime unlocks after soundcheck "+str(size))
    var disk = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    _check(disk is Dictionary and str(disk.get("career_extra",{}).get("gig_night_phase","")) == "stage","stage survives disk save "+str(size))
    _check(disk is Dictionary and int(disk.get("career_extra",{}).get("show_journey_progress",{}).get("step",-1)) == 4,"journey progress persists "+str(size))
    ui._perform_gig()
    await process_frame
    var after: Dictionary = ui._state()
    _check(after.get("booked_show",{}).is_empty(),"show booking settled "+str(size))
    _check(after.get("gig_history",[]).size() == 1,"one real gig recorded "+str(size))
    _check(int(after.get("tour_day",0)) > 7,"gig costs scheduled days once "+str(size))
    _check(str(after.get("gig_history",[]).back().get("travel_plan","")) == Tour.OVERNIGHT,"travel settlement uses chosen plan "+str(size))
    var settled_cash := int(after.get("cash",0))
    ui._perform_gig()
    await process_frame
    _check(ui._state().get("gig_history",[]).size() == 1 and int(ui._state().get("cash",0)) == settled_cash,"second performance cannot settle again "+str(size))
    var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    _check(saved is Dictionary and saved.get("career_extra",{}).get("gig_history",[]).size() == 1,"gig result survives disk save "+str(size))
   ui.free()
   await process_frame
   print("SPRINT B SHOW DAY %dx%d checked" % [size.x,size.y])
 if existed:
  _write(original)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT B SHOW DAY JOURNEY PASSED")
 quit(0 if failures == 0 else 1)

func _button(root: Node, needle: String) -> Button:
 var nodes: Array[Node] = [root]
 while not nodes.is_empty():
  var current: Node = nodes.pop_back()
  if current is Button and str(current.text).contains(needle):
   return current
  for child in current.get_children():
   nodes.append(child)
 return null

func _art(root: Node) -> bool:
 var art := root.find_child("ShowJourneyArtwork",true,false) as TextureRect
 return art != null and art.texture != null

func _write(value: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file != null:
  file.store_string(value)
  file.close()

func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT B SHOW DAY FAILURE: "+why)
