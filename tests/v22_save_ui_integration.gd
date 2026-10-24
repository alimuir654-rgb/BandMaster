extends SceneTree
# Simulate the live CareerHub UI and its actual user:// save path.
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const SAVE_PATH := "user://tour_save.json"
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var original_exists := FileAccess.file_exists(SAVE_PATH)
 var original_text := ""
 if original_exists:
  var old := FileAccess.open(SAVE_PATH,FileAccess.READ)
  if old != null:
   original_text = old.get_as_text()
   old.close()
 var fixture := {
  "band":{"name":"The Checkout Test","members":[{"name":"Jo","role":"Drummer","trait":"Reliable","skill":45,"fatigue":0,"loyalty":65,"morale":60},{"name":"Alex","role":"Guitarist","trait":"Creative","skill":50,"fatigue":0,"loyalty":60,"morale":60}]},
  "cash":140,"tour_day":1,"morale":60,"reputation":12,"readiness":40,"tension":10,"van_health":75,
  "current_event":"aftershow","pending_next":"","relationships":{"0_1":50},
  "career_extra":{"songs":0,"fans":0,"gig_history":[],"career_journal":[],"action_counters":{}}
 }
 _write(JSON.stringify(fixture))
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(scene != null,"career hub scene loads")
 if scene != null:
  var ui: Node = scene.instantiate()
  get_root().add_child(ui)
  var initial: Dictionary = ui._state()
  _check(Calendar.pending(initial).is_empty(),"new career starts without booking")
  ui._finish(Calendar.book(initial,"local"))
  _check(int(Calendar.pending(ui._state()).get("day",0)) == 4,"booking committed to UI state")
  ui.free()

  ui = scene.instantiate()
  get_root().add_child(ui)
  _check(int(Calendar.pending(ui._state()).get("day",0)) == 4,"booking survives file reload")
  ui._finish(Practice.resolve(ui._state(),"create"))
  _check(int(ui._state().get("song_draft_progress",0)) == 1,"draft progress is saved with booking")
  ui.free()

  ui = scene.instantiate()
  get_root().add_child(ui)
  _check(int(ui._state().get("tour_day",0)) == 2,"reloaded day advances")
  _check(int(Calendar.pending(ui._state()).get("day",0)) == 4,"booking remains while preparing")
  _check(int(ui._state().get("song_draft_progress",0)) == 1,"real rehearsal draft survives reload")
  ui._finish(Actions.resolve(ui._state(),"rest"))
  ui._finish(Actions.resolve(ui._state(),"rest"))
  _check(int(ui._state().get("tour_day",0)) == 4,"show day reached after two further actions")
  ui._finish(Calendar.perform(ui._state()),"gig:local")
  _check(Calendar.pending(ui._state()).is_empty(),"performed show cleared from UI")
  ui.free()

  ui = scene.instantiate()
  get_root().add_child(ui)
  _check(Calendar.pending(ui._state()).is_empty(),"completed booking stays cleared after reload")
  _check(ui._state().get("gig_history",[]).size() == 1,"gig history persisted")
  ui.free()
 if original_exists:
  _write(original_text)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("V22 SAVE AND UI INTEGRATION PASSED")
 quit(0 if failures == 0 else 1)

func _write(data: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  _check(false,"save file is writable")
  return
 file.store_string(data)
 file.close()

func _check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error("V22 INTEGRATION FAILURE: "+label)
