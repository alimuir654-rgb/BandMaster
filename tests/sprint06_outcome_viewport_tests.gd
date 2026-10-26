extends SceneTree
# Populated mobile outcome + scrapbook journey, with a deliberately long report.
const SAVE_PATH := "user://tour_save.json"
const SIZES := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var original := FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
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
 _check(packed != null,"CareerHub exists")
 if packed != null:
  for size in SIZES:
   _write(JSON.stringify(fixture))
   get_root().size = size
   var ui: Control = packed.instantiate()
   get_root().add_child(ui)
   ui.tab = "BAND"
   ui._render()
   await process_frame
   await process_frame
   var opener := _button(ui,"HEAR BOTH SIDES")
   _check(opener != null,"band incident opens at "+str(size))
   if opener != null:
    opener.pressed.emit()
    await process_frame
    var choice := _button(ui,"LET BOTH BE HEARD")
    _check(choice != null,"decision present at "+str(size))
    if choice != null:
     choice.pressed.emit()
     await process_frame
     await process_frame
     var scroll: ScrollContainer = ui.find_child("DecisionResultScroll",true,false)
     var footer: Control = ui.find_child("DecisionResultFooter",true,false)
     var continue_button := _button(ui,"CONTINUE")
     var scrapbook_button := _button(ui,"VIEW IN SCRAPBOOK")
     _check(scroll != null and footer != null,"scroll and fixed footer at "+str(size))
     _check(continue_button != null and scrapbook_button != null,"both outcome actions at "+str(size))
     if continue_button != null:
      _check(continue_button.custom_minimum_size.y >= 44.0 and continue_button.focus_mode == Control.FOCUS_ALL,"accessible continue at "+str(size))
      var rect := continue_button.get_global_rect()
      _check(rect.position.y >= 0 and rect.end.y <= ui.get_viewport_rect().size.y,"continue remains visible in viewport at "+str(size))
     if scrapbook_button != null:
      _check(scrapbook_button.custom_minimum_size.y >= 44.0,"scrapbook target >=44 at "+str(size))
      _check(scrapbook_button.get_global_rect().end.y <= ui.get_viewport_rect().size.y,"scrapbook remains visible at "+str(size))
      scrapbook_button.pressed.emit()
      await process_frame
      await process_frame
      _check(ui.tab == "SCENE" and ui.scene_view == "HISTORY" and ui.scrapbook_filter == "BAND","directly opens band scrapbook at "+str(size))
      _check(ui.find_child("PairMemento",true,false) != null,"saved note displayed at "+str(size))
      _check(int(ui.save_data.get("tour_day",0)) == 8 and int(ui.save_data.get("relationships",{}).get("0_1",0)) == 50,"navigation does not charge another day or trust at "+str(size))
      var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
      _check(saved is Dictionary and int(saved.get("tour_day",0)) == 8,"disk save unchanged by navigation at "+str(size))
     # Simulate unusually verbose narrative content, including a full illustrated
     # note, to verify the footer is independent of the scrollable report.
     var same: Dictionary = ui._state()
     var long_text := "A detailed backstage report with a meaningful choice and its consequences. ".repeat(45)
     ui._show_decision_result(same,same,long_text,"story:long")
     await process_frame
     await process_frame
     var long_scroll: ScrollContainer = ui.find_child("DecisionResultScroll",true,false)
     var long_continue := _button(ui,"CONTINUE")
     _check(long_scroll != null and long_continue != null,"long report renders at "+str(size))
     if long_scroll != null and long_continue != null:
      _check(long_continue.get_global_rect().end.y <= ui.get_viewport_rect().size.y,"long report never hides primary action at "+str(size))
      if size.x <= 720:
       _check(long_scroll.get_v_scroll_bar().max_value > long_scroll.size.y,"long report scrolls at "+str(size))
     if long_continue != null:
      long_continue.pressed.emit()
      await create_timer(0.25).timeout
   ui.free()
   print("SPRINT06 OUTCOME %dx%d checked" % [size.x,size.y])
 if existed:
  _write(original)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT 06 OUTCOME VIEWPORTS PASSED")
 quit(0 if failures == 0 else 1)

func _button(root: Node,needle: String) -> BaseButton:
 var stack: Array[Node] = [root]
 while not stack.is_empty():
  var current: Node = stack.pop_back()
  if current is BaseButton and str(current.text).contains(needle):
   return current
  for child in current.get_children():
   stack.append(child)
 return null

func _write(content: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file != null:
  file.store_string(content)
  file.close()

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT 06 OUTCOME FAILURE: "+reason)
