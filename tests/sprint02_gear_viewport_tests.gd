extends SceneTree
# Populated gear screen at the three target viewport sizes.
const SAVE_PATH := "user://tour_save.json"
const VIEWPORTS := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var had_save := FileAccess.file_exists(SAVE_PATH)
 var original := FileAccess.get_file_as_string(SAVE_PATH) if had_save else ""
 var fixture := {
  "band":{"name":"Gear Test","genre":"indie","members":[{"name":"Jo","role":"Guitarist","life_status":"active","trait":"Reliable","skill":55,"fatigue":5,"loyalty":75,"morale":65},{"name":"Lee","role":"Drummer","life_status":"active","trait":"Calm","skill":55,"fatigue":5,"loyalty":75,"morale":65}]},
  "cash":200,"tour_day":5,"morale":65,"reputation":20,"readiness":55,"tension":12,"van_health":80,
  "relationships":{"0_1":55},
  "career_extra":{"songs":2,"fans":25,"owned_equipment":["amp","drums"],"gear_records":{"amp":{"condition":27,"holder_index":0,"holder_name":"Jo","holder_role":"Guitarist","holder_id":"","provenance":"Bought second-hand, day 2","repairs":0},"drums":{"condition":91,"holder_index":-1,"provenance":"Bought second-hand, day 4","repairs":0}},"gig_history":[],"career_journal":[],"action_counters":{}}
 }
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 _check(file != null,"fixture writable")
 if file != null:
  file.store_string(JSON.stringify(fixture))
  file.close()
  var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
  _check(packed != null,"career scene available")
  if packed != null:
   for size in VIEWPORTS:
    get_root().size = size
    var ui: Control = packed.instantiate()
    get_root().add_child(ui)
    ui.tab = "GEAR"
    ui.selected_gear_item = "amp"
    ui._render()
    await process_frame
    await process_frame
    var service: BaseButton = _find_button(ui,"SERVICE & ASSESS")
    _check(service != null,"service control present at "+str(size))
    if service != null:
     _check(service.custom_minimum_size.y >= 44.0,"service target at "+str(size))
     _check(not service.disabled,"service affordable at "+str(size))
    _check(ui.find_child("GearDossierIcon",true,false) != null,"licensed icon rendered at "+str(size))
    var scroll: ScrollContainer = ui.career_scroll
    _check(scroll != null and scroll.size.x <= float(size.x)+2.0,"gear scroll fits viewport "+str(size))
    print("GEAR_VIEWPORT %dx%d service=%s icon=%s" % [size.x,size.y,str(service != null),str(ui.find_child("GearDossierIcon",true,false) != null)])
    ui.free()
 if had_save:
  _write(original)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT 02 GEAR VIEWPORTS PASSED")
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
  push_error("GEAR VIEWPORT FAILURE: "+reason)
