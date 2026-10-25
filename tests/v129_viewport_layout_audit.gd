extends SceneTree
# Live Godot layout inspection at actual viewport geometry, not source-string ordering.
const SAVE_PATH := "user://tour_save.json"
const VIEWPORTS := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
const TARGETS := [
 {"tab":"HOME","label":"REHEARSE"},
 {"tab":"ACTIONS","label":"WRITE & REHEARSE"},
 {"tab":"GIGS","label":"FIND A VENUE"},
 {"tab":"GEAR","label":"BUY EQUIPMENT"},
 {"tab":"SCENE","label":"PROMOTE"},
]
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existing := FileAccess.file_exists(SAVE_PATH)
 var previous := ""
 if existing:
  previous = FileAccess.get_file_as_string(SAVE_PATH)
 var fixture := {
  "band":{"name":"Viewport Test","members":[{"name":"Jo","role":"Drummer","trait":"Reliable","skill":55,"fatigue":5,"loyalty":75,"morale":65},{"name":"Sam","role":"Bassist","trait":"Calm","skill":55,"fatigue":5,"loyalty":75,"morale":65}]},
  "cash":250,"tour_day":1,"morale":65,"reputation":12,"readiness":55,"tension":12,"van_health":80,
  "relationships":{"0_1":55},"career_extra":{"songs":1,"fans":12,"gig_history":[],"career_journal":[],"action_counters":{}}
 }
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 _check(file!=null,"fixture writable")
 if file != null:
  file.store_string(JSON.stringify(fixture))
  file.close()
  var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
  _check(packed!=null,"CareerHub can load")
  if packed!=null:
   for viewport in VIEWPORTS:
    get_root().size = viewport
    for target in TARGETS:
     var ui: Control = packed.instantiate()
     get_root().add_child(ui)
     ui.tab = str(target["tab"])
     ui._render()
     await process_frame
     await process_frame
     var scroll: ScrollContainer = ui.career_scroll
     var visible := _first_fold_buttons(scroll)
     var wanted := str(target["label"])
     var found := false
     for caption in visible:
      if caption.to_upper().contains(wanted):
       found = true
     # Audit evidence is explicit: no synthetic claim that a control is visible.
     print("FIRST_FOLD %dx%d %s buttons=%s target=%s visible=%s" % [viewport.x,viewport.y,str(target["tab"]),JSON.stringify(visible),wanted,str(found)])
     _check(not visible.is_empty(),str(viewport)+" "+str(target["tab"])+" has no first-fold controls")
     if str(target["tab"]) in ["HOME","ACTIONS","GIGS","SCENE"]:
      _check(found,str(viewport)+" "+str(target["tab"])+" primary action below first fold")
     ui.free()
 if existing:
  _write(previous)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("V129 VIEWPORT LAYOUT AUDIT PASSED")
 quit(0 if failures==0 else 1)

func _first_fold_buttons(root: Control) -> Array[String]:
 var result: Array[String] = []
 if root == null:
  return result
 var viewport_rect := root.get_global_rect()
 var remaining: Array[Node] = [root]
 while not remaining.is_empty():
  var node: Node = remaining.pop_back()
  if node is BaseButton:
   var button := node as BaseButton
   var rect := button.get_global_rect()
   if not button.disabled and button.visible and viewport_rect.intersects(rect):
    var caption: String = str(button.get("text"))
    if caption.is_empty():
     caption = button.tooltip_text
    result.append(caption)
  for child in node.get_children():
   remaining.append(child)
 return result

func _write(value: String) -> void:
 var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if f != null:
  f.store_string(value)
  f.close()

func _check(condition: bool,why: String) -> void:
 if not condition:
  failures+=1
  push_error("V129 VIEWPORT FAILURE: "+why)
