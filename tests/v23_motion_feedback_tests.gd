extends SceneTree
const Motion = preload("res://Scripts/career_motion.gd")
const SAVE_PATH := "user://tour_save.json"
var failures := 0
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var original := ""
 var existed := FileAccess.file_exists(SAVE_PATH)
 if existed:
  var previous := FileAccess.open(SAVE_PATH,FileAccess.READ)
  if previous != null:
   original = previous.get_as_text()
   previous.close()
 var save := {"band":{"name":"The UI Test","members":[{"name":"Jo","role":"Drummer"},{"name":"Alex","role":"Guitarist"}]},"cash":120,"tour_day":1,"readiness":50,"morale":60,"reputation":10,"tension":10,"van_health":80,"current_event":"aftershow","pending_next":"","career_extra":{"fans":10,"songs":0,"gig_history":[],"career_journal":[]}}
 _write(JSON.stringify(save))
 var before := {"cash":120,"tour_day":1,"fans":10}
 var after := {"cash":100,"tour_day":2,"fans":14}
 var changes: Array = Motion.changes(before,after)
 _check(changes.size() == 3,"three correct stat deltas")
 _check(Motion.delta_text(changes[0]) == "DAY  +1","positive day delta")
 _check(Motion.delta_text(changes[1]) == "CASH  -20","negative cash delta")
 _check(Motion.headline("gig:local",true) == "THE NIGHT IS YOURS","gig headline")
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(scene != null,"scene load")
 if scene != null:
  var ui: Node = scene.instantiate()
  get_root().add_child(ui)
  var updated: Dictionary = ui._state().duplicate(true)
  updated["cash"] = 105
  updated["tour_day"] = 2
  ui._finish({"ok":true,"state":updated,"message":"A day at the studio."})
  _check(ui.get_node_or_null("DecisionOverlay") != null,"outcome is shown as a distinct overlay")
  _check(ui.find_child("DecisionContinue",true,false) != null,"outcome requires a deliberate continue")
  _check(int(ui._state().get("cash",0)) == 105,"save state applied before animation")
  ui.free()
 var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
 _check(saved is Dictionary and int(saved.get("cash",0)) == 105,"result persisted even when transition interrupted")
 if existed:
  _write(original)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("V23 MOTION AND DECISION FEEDBACK PASSED")
 quit(0 if failures == 0 else 1)
func _write(contents: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  _check(false,"save path writable")
  return
 file.store_string(contents)
 file.close()
func _check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error("V23 MOTION FAILURE: "+label)
