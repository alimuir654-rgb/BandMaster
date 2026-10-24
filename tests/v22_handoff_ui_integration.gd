extends SceneTree
# Exercise the real CareerHub load+save migration, not just the pure selector.
const SAVE_PATH := "user://tour_save.json"
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var backup := ""
 if existed:
  var existing := FileAccess.open(SAVE_PATH,FileAccess.READ)
  if existing != null:
   backup = existing.get_as_text()
   existing.close()
 var fixture := {
  "band":{"name":"The Handoff","members":[{"name":"Jo","role":"Drummer"},{"name":"Alex","role":"Guitarist"}]},
  "cash":95,"tour_day":9,"morale":60,"reputation":14,"readiness":55,"tension":15,"van_health":55,
  "rehearsal_number":3,"current_event":"aftershow","pending_next":"",
  "decisions":{"rehearsal_1":"write","rehearsal_2":"drill","rehearsal_3":"bond","first_gig":"safe"},
  "relationships":{"0_1":57},
  "career_extra":{"fans":5,"songs":0,"gig_history":[],"career_journal":[],"action_counters":{}}
 }
 _write(JSON.stringify(fixture))
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(scene != null,"career hub loads")
 if scene != null:
  var hub: Node = scene.instantiate()
  get_root().add_child(hub)
  _check(hub.save_data.get("band",{}).get("name","") == "The Handoff","identity preserved")
  var extra: Dictionary = hub.save_data.get("career_extra",{})
  _check(bool(extra.get("intro_handoff_complete",false)),"handoff performed in live UI")
  _check(extra.get("gig_history",[]).size() == 1,"intro first gig transferred")
  _check(int(extra.get("action_counters",{}).get("rehearse",0)) == 3,"rehearsals preserved")
  hub.free()
  var persisted := _read()
  var migrated_extra: Dictionary = persisted.get("career_extra",{})
  _check(migrated_extra.get("gig_history",[]).size() == 1,"migration persisted to disk")
  hub = scene.instantiate()
  get_root().add_child(hub)
  var second_extra: Dictionary = hub.save_data.get("career_extra",{})
  _check(second_extra.get("gig_history",[]).size() == 1,"second startup does not duplicate intro")
  _check(second_extra.get("career_journal",[]).size() == 1,"intro story remains singular")
  hub.free()
 if existed:
  _write(backup)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("V22 HANDOFF UI INTEGRATION PASSED")
 quit(0 if failures == 0 else 1)

func _read() -> Dictionary:
 var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
 if file == null:
  return {}
 var data = JSON.parse_string(file.get_as_text())
 file.close()
 return data if data is Dictionary else {}

func _write(text_data: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  _check(false,"save writable")
  return
 file.store_string(text_data)
 file.close()

func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("HANDOFF UI FAILURE: "+detail)
