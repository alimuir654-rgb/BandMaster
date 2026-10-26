extends SceneTree
# Populated band intervention: first-fold action, focus, safe back, one-time commit.
const SAVE_PATH := "user://tour_save.json"
const VIEWPORTS := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var had_save := FileAccess.file_exists(SAVE_PATH)
 var original := FileAccess.get_file_as_string(SAVE_PATH) if had_save else ""
 var fixture := {
  "band":{"name":"Rehearsal Test","genre":"indie","members":[
   {"name":"Jo","role":"Guitarist","life_status":"active","trait":"Proud","skill":55,"fatigue":22,"loyalty":60,"morale":58},
   {"name":"Lee","role":"Drummer","life_status":"active","trait":"Thoughtful","skill":55,"fatigue":28,"loyalty":64,"morale":60}
  ]},
  "cash":180,"tour_day":7,"morale":59,"reputation":20,"readiness":61,"tension":18,"van_health":85,
  "relationships":{"0_1":38},
  "career_extra":{"songs":2,"fans":25,"owned_equipment":[],"gig_history":[],"career_journal":[],"action_counters":{}}
 }
 var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(packed != null,"CareerHub scene available")
 if packed != null:
  for size in VIEWPORTS:
   _write(JSON.stringify(fixture))
   get_root().size = size
   var ui: Control = packed.instantiate()
   get_root().add_child(ui)
   ui.tab = "BAND"
   ui._render()
   await process_frame
   await process_frame
   var opener := _find_button(ui,"HEAR BOTH SIDES")
   _check(opener != null,"pair decision visible at "+str(size))
   if opener != null:
    _check(opener.custom_minimum_size.y >= 44.0,"first-fold action tap target at "+str(size))
    var r: Rect2 = opener.get_global_rect()
    _check(r.position.y < float(size.y),"pair decision starts in first fold at "+str(size))
    opener.pressed.emit()
    await process_frame
    var sheet := ui.find_child("SceneSheet",true,false)
    _check(sheet != null,"focused scene opens at "+str(size))
    _check(ui.find_child("PairIncidentIdentity",true,false) != null,"named pair strip at "+str(size))
    var choice := _find_button(ui,"LET BOTH BE HEARD")
    var back := _find_button(ui,"BACK TO THE BAND")
    _check(choice != null and back != null,"choice and safe back at "+str(size))
    if choice != null:
     _check(choice.custom_minimum_size.y >= 44.0,"choice touch target at "+str(size))
    if back != null:
     back.pressed.emit()
     await process_frame
     _check(int(ui.save_data["tour_day"]) == 7 and int(ui.save_data["relationships"]["0_1"]) == 38,"cancel costs nothing at "+str(size))
    var again := _find_button(ui,"HEAR BOTH SIDES")
    if again != null:
     again.pressed.emit()
     await process_frame
     var confirm := _find_button(ui,"LET BOTH BE HEARD")
     if confirm != null:
      confirm.pressed.emit()
      await process_frame
      _check(int(ui.save_data["tour_day"]) == 8,"commit costs one day at "+str(size))
      _check(int(ui.save_data["relationships"]["0_1"]) == 50,"pair trust persists at "+str(size))
      _check(_find_button(ui,"HEAR BOTH SIDES") == null,"same pair case no longer offered at "+str(size))
      var disk = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
      _check(disk is Dictionary and int(disk.get("tour_day",0)) == 8,"commit persisted on disk at "+str(size))
    print("PAIR_VIEWPORT %dx%d action=%s sheet=%s" % [size.x,size.y,str(opener != null),str(sheet != null)])
   ui.free()
 if had_save:
  _write(original)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT 03 PAIR VIEWPORTS PASSED")
 quit(0 if failures == 0 else 1)

func _find_button(root: Node,fragment: String) -> BaseButton:
 var queue: Array[Node] = [root]
 while not queue.is_empty():
  var node: Node = queue.pop_back()
  if node is BaseButton and str(node.get("text")).contains(fragment):
   return node
  for child in node.get_children():
   queue.append(child)
 return null

func _write(value: String) -> void:
 var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if f != null:
  f.store_string(value)
  f.close()

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("PAIR VIEWPORT FAILURE: "+reason)
