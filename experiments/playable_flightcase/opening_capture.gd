extends SceneTree
## Captures are native GL/Mesa/Xvfb pixels, never flattened mockup art.
const UI = preload("res://experiments/playable_flightcase/opening_ui.gd")
var failures: Array[String] = []
func _init() -> void:
 call_deferred("take")
func _draw_screen(name: String,w: int,h: int) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var img: Image = root.get_texture().get_image()
 var dest := "/tmp/c27-%s-%dx%d.png" % [name,w,h]
 if img == null or img.is_empty() or img.get_width()!=w or img.get_height()!=h:
  failures.append("invalid "+name+" image dimensions")
 elif img.save_png(dest)!=OK:
  failures.append("could not save "+dest)
func click_action(button: Button) -> void:
 if button==null or button.disabled:
  failures.append("missing or disabled action")
  return
 for layout_attempt in range(5):
  if button.is_inside_tree() and button.get_global_rect().size.x>=44 and button.get_global_rect().size.y>=44:
   break
  await process_frame
 if not button.is_inside_tree() or button.get_global_rect().size.x<44 or button.get_global_rect().size.y<44:
  failures.append("action has no settled physical geometry: "+button.name)
  return
 # Real controls can sit below the first fold on 390px phones. Scroll the
 # actual in-scene ScrollContainer rather than faking a pressed signal.
 var ancestor: Node = button.get_parent()
 while ancestor != null:
  if ancestor is ScrollContainer:
   (ancestor as ScrollContainer).ensure_control_visible(button)
   await process_frame
   await process_frame
  ancestor = ancestor.get_parent()
 var point := button.get_global_rect().get_center()
 var viewport_size := root.size
 print("C30_NATIVE_ACTION ",button.name," rect=",button.get_global_rect()," point=",point," viewport=",viewport_size)
 if point.x < 0 or point.y < 0 or point.x >= viewport_size.x or point.y >= viewport_size.y:
  failures.append("action remains offscreen after scroll: "+button.name)
  return
 var press := InputEventMouseButton.new()
 press.button_index = MOUSE_BUTTON_LEFT
 press.position = point
 press.global_position = point
 press.pressed = true
 Input.parse_input_event(press)
 await process_frame
 var release := InputEventMouseButton.new()
 release.button_index = MOUSE_BUTTON_LEFT
 release.position = point
 release.global_position = point
 release.pressed = false
 Input.parse_input_event(release)
 await process_frame
 await process_frame
 await process_frame
func take() -> void:
 var w := maxi(320,int(OS.get_environment("CAPTURE_WIDTH")))
 var h := maxi(480,int(OS.get_environment("CAPTURE_HEIGHT")))
 DisplayServer.window_set_size(Vector2i(w,h))
 root.size = Vector2i(w,h)
 var screen = UI.new()
 root.add_child(screen)
 screen.size = Vector2(w,h)
 # Ensure title always renders with empty draft, independent of the runner's saved state.
 screen.setup.screen = "menu"
 screen.showing_menu = true
 screen.call("_render")
 await _draw_screen("title",w,h)
 var new_action: Button = screen.find_child("NewBandAction",true,false)
 if new_action==null:
  failures.append("New Band button missing")
 else:
  print("C27_MENU_BUTTON rect=",new_action.get_global_rect()," viewport=",Vector2(w,h))
  await click_action(new_action)
 # The preceding native opening-state test saves a draft to this isolated sandbox.
 # New correctly requires confirmation; test the actual original C21 modal.
 await process_frame
 var confirmation: Control = null
 for node in screen.get_children():
  if node is Control and node.has_method("open_modal") and bool(node.get("is_open")):
   confirmation = node
   break
 if confirmation != null:
  print("C27_NEW_CONFIRM_REQUIRED true; real pointer confirming overwrite")
  var accept_button: Button = confirmation.get("confirm_button")
  if accept_button == null:
   failures.append("new draft confirmation button missing")
  else:
   await click_action(accept_button)
   await process_frame
 else:
  print("C27_NEW_CONFIRM_REQUIRED false, stage=",screen.setup.screen)
 if screen.setup.screen!="genre":
  failures.append("New Band did not open genre via pointer")
 else:
  await _draw_screen("genre",w,h)
 var next_action: Button = screen.find_child("GenreNextAction",true,false)
 if next_action==null:
  failures.append("Genre Next missing")
 else:
  await click_action(next_action)
 if screen.setup.screen!="recruit":
  failures.append("Genre Next did not open recruit via pointer")
 else:
  await _draw_screen("recruit",w,h)
  var meter: Control = screen.find_child("PassiveMeter0",true,false)
  if meter == null or meter.focus_mode!=Control.FOCUS_NONE or meter.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("meter focus/input regression")

 # Roster is an explicitly declared deterministic fixture here; the 38 original
 # C27 and expanded end-to-end model tests independently exercise recruit/remove,
 # refunds and vocals. The remaining transitions use actual native mouse events.
 if screen.setup.screen=="recruit":
  # Unlike a model fixture, these are three actual user recruitment choices,
  # including changing role, browsing the cast and appointing lead vocals.
  var pane: Control = null
  for child in screen.get_children():
   if child is Control and child.has_method("_move_candidate") and child.has_method("_change_role"):
    pane = child
    break
  if pane==null:
   failures.append("real recruitment panel missing")
  else:
   for pair in [["Guitarist","cast_jack"],["Bassist","cast_zoe"],["Drummer","cast_casey"]]:
    var desired_role: String = str(pair[0])
    var desired_id: String = str(pair[1])
    var role_tab: Button = null
    for entry in pane.find_children("*","Button",true,false):
     var tab_button: Button = entry as Button
     if tab_button != null and tab_button.text==desired_role.to_upper():
      role_tab=tab_button
      break
    await click_action(role_tab)
    await process_frame
    if str(pane.get("role"))!=desired_role:
     failures.append("real role tab did not select "+desired_role+", observed "+str(pane.get("role")))
     break
    var choices: Array = screen.setup.game.choices(desired_role)
    var found_target := false
    for attempt in range(choices.size()):
     var index: int = int(pane.get("selected_index"))
     if index>=0 and index<choices.size() and str(choices[index].get("id",""))==desired_id:
      found_target = true
      break
     var next_candidate: Button = null
     for entry in pane.find_children("*","Button",true,false):
      var candidate_button: Button = entry as Button
      if candidate_button!=null and candidate_button.text=="›":
       next_candidate=candidate_button
       break
     await click_action(next_candidate)
     await process_frame
    if not found_target:
     failures.append("could not browse to "+desired_id+" in "+desired_role)
     break
    await click_action(pane.find_child("RecruitAction",true,false))
    var confirmed := false
    for member in screen.setup.game.roster:
     if str(member.get("id",""))==desired_id:
      confirmed=true
    if not confirmed:
     failures.append("real recruit pointer did not hire "+desired_id)
     break
   var vocal_action: Button = null
   for entry in pane.find_children("*","Button",true,false):
    var voice_button: Button = entry as Button
    if voice_button!=null and voice_button.text.to_upper().contains("JACK") and voice_button.text.to_upper().contains("TALENT"):
     vocal_action=voice_button
     break
   await click_action(vocal_action)
   if screen.setup.lead_vocal_id!="cast_jack" or not screen.setup.ready():
    failures.append("real vocalist selection or mandatory trio not ready")
  var ready_action: Button = screen.find_child("StartAction",true,false)
  await click_action(ready_action)
  if screen.setup.screen!="formed":
   failures.append("real Complete Lineup click did not reach milestone1")
  else:
   await _draw_screen("milestone1",w,h)
   var m1: Control = screen.find_child("MilestoneOneStage",true,false)
   var expected_width: float = minf(600.0,float(w) - (40.0 if w<720 else 80.0))
   if m1==null or m1.get_global_rect().size.x < expected_width - 2.0:
    failures.append("milestone1 retained narrow portrait composition")
   var m1_next: Button = screen.find_child("MilestoneNextAction",true,false)
   if m1_next==null or m1_next.get_global_rect().size.x<44.0:
    failures.append("milestone1 Next action lacks physical target")
 if screen.setup.screen=="formed":
  await click_action(screen.find_child("MilestoneNextAction",true,false))
  if screen.setup.screen!="name":
   failures.append("real milestone1 Next click did not reach naming")
  else:
   await _draw_screen("naming",w,h)
 if screen.setup.screen=="name":
  var suggestions: Array = screen.setup.suggested_names()
  var first_name: String = str(suggestions[0]["name"]) if not suggestions.is_empty() else ""
  var proposal_button: Button = null
  for entry in screen.find_children("*","Button",true,false):
   var b: Button = entry as Button
   if b!=null and not first_name.is_empty() and b.text.to_upper().contains(first_name.to_upper()):
    proposal_button=b
    break
  await click_action(proposal_button)
  if screen.setup.name_offer.is_empty():
   failures.append("native name proposal pointer did not register")
  else:
   await _draw_screen("name_reactions",w,h)
  var rethink: Button = screen.find_child("NameRethinkAction",true,false)
  await click_action(rethink)
  if screen.setup.name_revisions!=1 or not screen.setup.name_offer.is_empty():
   failures.append("native free rethink did not clear first proposal")
  else:
   await _draw_screen("name_rethink",w,h)
  var input_field: LineEdit = screen.find_child("FreeBandName",true,false)
  if input_field==null:
   failures.append("custom band-name text field missing")
  else:
   input_field.text = "Side Street"
   input_field.text_changed.emit("Side Street")
  await click_action(screen.find_child("NameSubmitAction",true,false))
  if screen.setup.name_offer!="Side Street":
   failures.append("custom typed name not submitted by real button")
  var lock_button: Button = screen.find_child("NameLockAction",true,false)
  await click_action(lock_button)
  if screen.setup.screen!="name_milestone":
   failures.append("real Name Lock did not reach milestone2")
  else:
   await _draw_screen("milestone2",w,h)
   var m2: Control = screen.find_child("MilestoneTwoStage",true,false)
   var expected_width: float = minf(600.0,float(w) - (40.0 if w<720 else 80.0))
   if m2==null or m2.get_global_rect().size.x < expected_width - 2.0:
    failures.append("milestone2 retained narrow portrait composition")
   var m2_next: Button = screen.find_child("NameMilestoneNextAction",true,false)
   if m2_next==null or m2_next.get_global_rect().size.x<44.0:
    failures.append("milestone2 Next action lacks physical target")
 if screen.setup.screen=="name_milestone":
  await click_action(screen.find_child("NameMilestoneNextAction",true,false))
  if screen.setup.screen!="identity":
   failures.append("real milestone2 Next did not reach logo/vibe")
  else:
   await _draw_screen("identity",w,h)
 if screen.setup.screen=="identity":
  var stamp_button: Button = null
  for entry in screen.find_children("*","Button",true,false):
   var b: Button = entry as Button
   if b!=null and b.text.to_upper().contains("STAMP"):
    stamp_button=b
    break
  await click_action(stamp_button)
  if screen.setup.logo!="Stamp":
   failures.append("logo selection pointer did not update preview")
  else:
   await _draw_screen("identity_stamp",w,h)
  await click_action(screen.find_child("IdentityFinishAction",true,false))
  if screen.setup.screen!="complete":
   failures.append("real Finish Identity did not reach completed summary")
  else:
   await _draw_screen("completed_band",w,h)
 if screen.setup.screen=="complete":
  # A bounded source-backed identity stage must also bound its associated
  # real progression button at phone, portrait tablet and desktop sizes.
  var practice_button: Button = screen.find_child("StartPlayAction",true,false)
  if practice_button != null:
   var permitted_width: float = minf(780.0,float(w) - (40.0 if w < 720 else 80.0))
   if practice_button.get_global_rect().size.x > permitted_width + 1.0:
    failures.append("summary action wider than bounded case stage")
  await click_action(practice_button)
  if screen.setup.screen!="play" or screen.setup.game.phase!="play":
   failures.append("real First Practice click did not hand off gameplay")
  else:
   await _draw_screen("practice",w,h)
 if screen.setup.screen=="play":
  var before_resume: Dictionary = screen.setup.snapshot()
  screen.call("_home")
  await process_frame
  var continue_button: Button = screen.find_child("ContinueAction",true,false)
  await click_action(continue_button)
  if screen.setup.screen!="play" or screen.setup.snapshot()!=before_resume:
   failures.append("real Continue failed to restore live gameplay without state loss")
  else:
   await _draw_screen("resumed_practice",w,h)

 print("C27_CAPTURE_RESULT ",JSON.stringify({"width":w,"height":h,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
