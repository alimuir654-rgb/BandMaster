extends SceneTree
const SAVE_PATH := "user://tour_save.json"
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var previous := FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
 var save := {"band":{"name":"The Test Band","members":[{"name":"Jo","role":"Drummer","trait":"Reliable"}]},"cash":120,"tour_day":1,"readiness":50,"morale":60,"reputation":10,"tension":10,"van_health":80,"current_event":"aftershow","pending_next":"","career_extra":{"fans":10,"songs":0,"gig_history":[],"career_journal":[]}}
 _write(JSON.stringify(save))
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(scene != null,"career scene loads")
 if scene != null:
  var ui: Node = scene.instantiate()
  get_root().add_child(ui)
  ui._switch("BAND")
  ui._display_conversation({"speaker":"Jo","text":"We can make it work.","source":"offline","day":1})
  var button := _find_button(ui,"CLOSE CONVERSATION")
  _check(button != null,"dismiss button exists")
  _check(_find_text(ui,"We can make it work."),"dialogue shown")
  if button != null:
   button.pressed.emit()
   _check(ui._extra().get("last_band_conversation",{}).is_empty(),"conversation dismissed")
   var disk = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
   _check(disk is Dictionary and disk.get("career_extra",{}).get("last_band_conversation",{}).is_empty(),"dismiss persists")
  ui.free()
 if existed:
  _write(previous)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("V24 BACKSTAGE DIALOGUE UI PASSED")
 quit(0 if failures == 0 else 1)

func _find_button(root: Node, caption: String) -> Button:
 if root is Button and root.text == caption:
  return root
 for child in root.get_children():
  var found := _find_button(child,caption)
  if found != null:
   return found
 return null

func _find_text(root: Node, phrase: String) -> bool:
 if root is Label and phrase in root.text:
  return true
 for child in root.get_children():
  if _find_text(child,phrase):
   return true
 return false

func _write(contents: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file != null:
  file.store_string(contents)
  file.close()
 else:
  _check(false,"save writable")

func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 BACKSTAGE FAILURE: "+detail)
