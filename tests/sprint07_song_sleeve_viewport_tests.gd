extends SceneTree
# Real songwriting room -> inspect finished sleeve -> commit new original -> sleeve.
const SAVE_PATH := "user://tour_save.json"
const SIZES := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var original := FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
 var fixture := {
  "band":{"name":"Sleeve Test","genre":"indie","members":[
   {"name":"Jo","role":"Guitarist","life_status":"active","trait":"Creative","skill":55,"fatigue":12,"loyalty":60,"morale":60},
   {"name":"Lee","role":"Drummer","life_status":"active","trait":"Reliable","skill":58,"fatigue":10,"loyalty":65,"morale":62}
  ]},
  "cash":180,"tour_day":7,"morale":61,"reputation":20,"readiness":65,"tension":12,"van_health":90,
  "relationships":{"0_1":60},
  "career_extra":{"songs":1,"fans":20,"owned_equipment":[],"gig_history":[],"career_journal":[],"action_counters":{},
   "song_draft_progress":2,
   "current_song_draft":{"title":"NEW ORIGINAL","idea":"Riff","form":"Slow Build","leader":"Jo","sessions":[
    {"day":5,"leader":"Jo","idea":"Riff","form":"Loose Jam"},{"day":6,"leader":"Lee","idea":"Lyric","form":"Slow Build"}
   ]},
   "song_catalogue":[{"title":"NEON ON THE PLATFORM","lead_writer":"Lee","credited_writers":["Lee","Jo"],"origin":"Lyric","arrangement":"Slow Build","quality":76,"written_day":4,
    "writing_sessions":[{"day":2,"leader":"Lee","idea":"Lyric","form":"Slow Build"},{"day":3,"leader":"Jo","idea":"Riff","form":"Loose Jam"}]}]
  }
 }
 var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(packed != null,"CareerHub scene exists")
 if packed != null:
  for size in SIZES:
   _write(JSON.stringify(fixture))
   get_root().size = size
   var ui: Control = packed.instantiate()
   get_root().add_child(ui)
   ui.tab = "ACTIONS"
   ui.action_view = "JAM"
   ui._render()
   await process_frame
   await process_frame
   var jump := _button(ui,"OPEN THE WRITING DESK")
   _check(jump != null,"writing desk has a named first-fold action at "+str(size))
   if jump != null:
    _check(jump.custom_minimum_size.y >= 44 and jump.focus_mode == Control.FOCUS_ALL,"accessible writing desk jump at "+str(size))
    _check(jump.get_global_rect().position.y < ui.get_viewport_rect().size.y,"writing desk jump in first fold at "+str(size))
    jump.pressed.emit()
    await process_frame
    _check(int(ui.save_data.get("tour_day",0)) == 7,"scroll-to-desk does not consume day at "+str(size))
   var view := _button(ui,"VIEW SLEEVE")
   _check(view != null,"finished song has inspect action at "+str(size))
   if view != null:
    _check(view.custom_minimum_size.y >= 44,"songbook inspect tap target at "+str(size))
    view.pressed.emit()
    await process_frame
    var sheet := ui.find_child("SceneSheet",true,false)
    _check(sheet != null and ui.find_child("SongSleeveArtifact",true,false) != null,"real sleeve opens at "+str(size))
    _check(_has_text(sheet,"CREDIT: Lee, Jo") and _has_text(sheet,"DAY 2"),"credits and writing provenance readable at "+str(size))
    var back := _button(ui,"BACK TO SONGBOOK")
    _check(back != null and back.focus_mode == Control.FOCUS_ALL,"keyboard accessible safe back at "+str(size))
    if back != null:
     back.pressed.emit()
     await process_frame
     _check(int(ui.save_data.get("tour_day",0)) == 7 and int(ui.save_data.get("cash",0)) == 180,"view and back are read-only at "+str(size))
   var title_input := ui.find_child("WorkingTitleInput",true,false) as LineEdit
   _check(title_input != null,"editable draft title exists at "+str(size))
   if title_input != null:
    title_input.text = "NEW ORIGINAL"
   var commit := _button(ui,"COMMIT TO THIS SONG")
   _check(commit != null and not commit.disabled,"third session commit available at "+str(size))
   if commit != null:
    commit.pressed.emit()
    await process_frame
    await process_frame
    var state: Dictionary = ui._state()
    var songs: Array = state.get("song_catalogue",[])
    _check(int(state.get("tour_day",0)) == 8 and songs.size() == 2,"finish charges one day and adds one original at "+str(size))
    if songs.size() == 2:
     var finished: Dictionary = songs[1]
     _check(str(finished.get("title","")) == "NEW ORIGINAL","player's title on completed song at "+str(size))
     _check(finished.get("writing_sessions",[]).size() == 3,"three real writing sessions persisted at "+str(size))
    _check(ui.find_child("SongSleeveArtifact",true,false) != null,"completion displays reusable sleeve at "+str(size))
    _check(_has_text(ui.find_child("DecisionOverlay",true,false),"NEW ORIGINAL"),"completion sleeve shows actual title at "+str(size))
    var disk = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    _check(disk is Dictionary and int(disk.get("tour_day",0)) == 8,"song and day saved to disk at "+str(size))
    if disk is Dictionary:
     _check(disk.get("career_extra",{}).get("song_catalogue",[]).size() == 2,"song persisted to catalogue at "+str(size))
    var next := _button(ui,"CONTINUE")
    if next != null:
     next.pressed.emit()
     await create_timer(0.25).timeout
   ui.free()
   print("SPRINT07 SLEEVE VIEWPORT %dx%d checked" % [size.x,size.y])
 if existed:
  _write(original)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT 07 SONG SLEEVE VIEWPORTS PASSED")
 quit(0 if failures == 0 else 1)

func _button(root: Node, needle: String) -> BaseButton:
 var stack: Array[Node] = [root]
 while not stack.is_empty():
  var current: Node = stack.pop_back()
  if current is BaseButton and str(current.text).contains(needle):
   return current
  for child in current.get_children():
   stack.append(child)
 return null

func _has_text(root: Node, needle: String) -> bool:
 if root == null:
  return false
 if root is Label and str(root.text).contains(needle):
  return true
 for child in root.get_children():
  if _has_text(child,needle):
   return true
 return false

func _write(value: String) -> void:
 var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if f != null:
  f.store_string(value)
  f.close()

func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT 07 SLEEVE VIEWPORT FAILURE: "+why)
