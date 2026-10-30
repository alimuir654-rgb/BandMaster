extends SceneTree
## Captures are native GL/Mesa/Xvfb pixels, never flattened mockup art.
const UI = preload("res://experiments/playable_flightcase/opening_ui.gd")
const Group = preload("res://experiments/playable_flightcase/band_lineup.gd")
const Poster = preload("res://experiments/playable_flightcase/band_formed_poster.gd")
const IdentityPress = preload("res://experiments/playable_flightcase/band_identity_press.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const ApprovedCast = preload("res://experiments/character_cast/catalogue.gd")
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
# S37: native proof of source-backed saved lineup and Unicode name.
func _check_identity_press(screen: Control, component_name: String, expected_name: String, logo: String) -> void:
 var proof: Variant = screen.find_child(component_name,true,false)
 if proof==null:
  failures.append("S37 missing identity component "+component_name)
  return
 if proof.mouse_filter!=Control.MOUSE_FILTER_IGNORE or proof.focus_mode!=Control.FOCUS_NONE:
  failures.append("S37 identity artwork stole input/focus: "+component_name)
 if proof.visible_ids()!=["cast_jack","cast_zoe","cast_casey"]:
  failures.append("S37 selected group changed: "+component_name+" "+str(proof.visible_ids()))
 var full_name: Label = proof.find_child("IdentityFullName",true,false) as Label
 var mark: Label = proof.find_child("IdentityLiveMark",true,false) as Label
 if full_name==null or full_name.text!=expected_name:
  failures.append("S37 live full band name lost: "+component_name)
 if mark==null or mark.text.is_empty() or (logo=="Stamp" and not mark.text.begins_with("— ")):
  failures.append("S37 selected logo missing as live text: "+component_name)
 var paper: PanelContainer = proof.find_child("IdentityPressPaper",true,false) as PanelContainer
 if paper==null or not paper.get_theme_stylebox("panel") is StyleBoxTexture:
  failures.append("S37 identity press missing source paper: "+component_name)
 for pid in ["cast_jack","cast_zoe","cast_casey"]:
  var photo: TextureRect = proof.find_child("IdentityPortrait_"+pid,true,false) as TextureRect
  if photo==null or photo.texture==null or photo.texture.get_width()<200 or photo.texture.get_width()>260:
   failures.append("S37 portrait source mismatch: "+component_name+" / "+pid)
  elif photo.focus_mode!=Control.FOCUS_NONE or photo.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("S37 portrait takes input: "+component_name+" / "+pid)
 if component_name!="IdentityPreviewPrint" and proof.find_children("IdentityLeadVocal","Label",true,false).size()!=1:
  failures.append("S37 noncompact identity singer count incorrect")

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
# Source-honest visual-density fixture: this draws an actual Godot poster with
# five/six C25 approved preview portraits, WITHOUT mutating the real player's
# roster, spending talent, triggering milestone flags or writing a save.
func _draw_roster_cover(member_count: int,w: int,h: int) -> void:
 var people: Array = ApprovedCast.people().slice(0,member_count)
 var overlay := Control.new()
 overlay.name = "S36RosterDensityFixture"
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(overlay)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.size = Vector2(w,h)
 var bg := TextureRect.new()
 bg.texture = load("res://components/control_atlas/art/case_surface.png")
 bg.modulate = Color(0.52,0.57,0.61)
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_SCALE
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.add_child(bg)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var centre := CenterContainer.new()
 centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.add_child(centre)
 centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var frame: PanelContainer = Kit.frame("flightcase","panel")
 frame.custom_minimum_size.x = maxf(280.0,minf(760.0,float(w)-(40.0 if w < 720 else 80.0)))
 frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 centre.add_child(frame)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",8)
 frame.add_child(content)
 var poster: Variant = Poster.new()
 poster.name = "S36PosterDensity"
 content.add_child(poster)
 poster.configure(people,str(people[0].get("id","")),float(w))
 if poster.visible_ids().size()!=member_count:
  failures.append("S36 "+str(member_count)+"-person poster lost a real C25 identity")
 var note: Label = Kit.label("ROSTER LAYOUT PROOF  /  NOT A PLAYER SAVE","flightcase",12)
 note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(note)
 content.add_child(Kit.button("NAME THE BAND ›","flightcase","action"))
 content.add_child(Kit.button("BACK TO MENU","flightcase","tab"))
 await process_frame
 await process_frame
 var rect: Rect2 = frame.get_global_rect()
 if rect.position.x < -2.0 or rect.position.y < -2.0 or rect.end.x > float(w)+2.0 or rect.end.y > float(h)+2.0:
  failures.append("S36 "+str(member_count)+"-person poster overflows "+str(w)+"x"+str(h)+": "+str(rect))
 await _draw_screen("milestone1_"+str(member_count)+"members_visual",w,h)
 overlay.queue_free()
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

 # The selected-candidate decision must be in the first fold without scrolling.
 var first_dock: Control = screen.find_child("RecruitDecisionDock",true,false)
 var first_recruit: Button = screen.find_child("RecruitAction",true,false)
 if first_dock == null or first_recruit == null:
  failures.append("first-fold recruitment decision dock or action missing")
 else:
  var recruit_rect: Rect2 = first_recruit.get_global_rect()
  if recruit_rect.size.y < 44.0 or recruit_rect.size.x < 44.0 or recruit_rect.position.y < 0.0 or recruit_rect.position.x < 0.0 or recruit_rect.end.y > float(h) - 4.0 or recruit_rect.end.x > float(w) - 4.0:
   failures.append("recruit action clipped or below first fold: "+str(recruit_rect))
  if first_recruit.get_parent() != first_dock:
   failures.append("recruit action still trapped inside portrait scroll")
  if w >= 840 and w >= h:
   var dock_rect: Rect2 = first_dock.get_global_rect()
   if dock_rect.size.x > 762.0 or absf(dock_rect.get_center().x - float(w)*0.5) > 4.0:
    failures.append("desktop recruit dock should be centred and source-proportionate: "+str(dock_rect))

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
  if ready_action == null:
   failures.append("ready lineup action not revealed in fixed decision dock")
  else:
   var ready_rect: Rect2 = ready_action.get_global_rect()
   if ready_rect.size.y < 44.0 or ready_rect.end.y > float(h) - 4.0:
    failures.append("ready lineup action clipped below first fold: "+str(ready_rect))
  await click_action(ready_action)
  if screen.setup.screen!="formed":
   failures.append("real Complete Lineup click did not reach milestone1")
  else:
   await _draw_screen("milestone1",w,h)
   for density_count in [5,6]:
    await _draw_roster_cover(density_count,w,h)
   var m1: Control = screen.find_child("MilestoneOneStage",true,false)
   var expected_width: float = minf(600.0,float(w) - (40.0 if w<720 else 80.0))
   if m1==null or m1.get_global_rect().size.x < expected_width - 2.0:
    failures.append("milestone1 retained narrow portrait composition")
   # S36: actual source-textured press/flyer treatment, never an image
   # of the whole UI. The player-selected roster is inside this native print.
   var print: Control = screen.find_child("BandFormationPoster",true,false)
   var paper: PanelContainer = screen.find_child("BandPosterPaper",true,false) as PanelContainer
   var headline: Label = screen.find_child("BandPosterHeadline",true,false) as Label
   if print==null or print.focus_mode!=Control.FOCUS_NONE or print.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
    failures.append("S36 noninteractive editorial poster missing or focusable")
   if paper==null or not paper.get_theme_stylebox("panel") is StyleBoxTexture:
    failures.append("S36 printed poster missing original paper texture")
   if headline==null or headline.text!="YOU'VE GOT A BAND.":
    failures.append("S36 editorial milestone lacks exact live headline")
   var m1_button: Button = screen.find_child("MilestoneNextAction",true,false)
   if m1_button==null or m1_button.get_global_rect().end.y > float(h)-4.0 or m1_button.get_global_rect().size.y < 44.0:
    failures.append("S36 Name action obscured by first-issue poster on "+str(w)+"x"+str(h))
   # S35: exact selected IDs and the one real singer must appear in native
   # GL, not merely in the underlying deterministic model.
   var group: Variant = screen.find_child("SelectedBandLineup",true,false)
   if group==null or group.visible_ids()!=["cast_jack","cast_zoe","cast_casey"]:
    failures.append("S35 lineup did not render the real selected three member IDs")
   else:
    for pid in ["cast_jack","cast_zoe","cast_casey"]:
     var photo: TextureRect = group.find_child("LineupPortrait_"+pid,true,false) as TextureRect
     if photo==null or photo.texture==null or photo.texture.get_width()<200 or photo.texture.get_width()>260:
      failures.append("S35 source portrait missing or wrong resolution: "+pid)
     var role_label: Label = group.find_child("LineupRole_"+pid,true,false) as Label
     if role_label==null or role_label.text.is_empty():
      failures.append("S35 selected player role credit missing: "+pid)
    if group.find_children("LineupLeadVocal","Label",true,false).size()!=1:
     failures.append("S35 vocalist badge must appear exactly once")
    for child in group.find_children("*","TextureRect",true,false):
     var image: TextureRect = child as TextureRect
     if image.focus_mode!=Control.FOCUS_NONE or image.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
      failures.append("S35 selected portrait gained unexpected input/focus")
   # Native 4/5/6 pure component proof uses approved IDs only. Construct
   # offscreen; never mutate the actual player roster or saved milestone.
   var all_cast: Array = ApprovedCast.people()
   if all_cast.size()!=18:
    failures.append("S35 canonical approved cast inventory is not 18")
   else:
    for count in [4,5,6]:
     var proof: Variant = Group.new()
     proof.visible = false
     screen.add_child(proof)
     var people: Array = all_cast.slice(0,count)
     var singer: String = str(people[0].get("id",""))
     proof.configure(people,singer,float(w))
     if proof.visible_ids().size()!=count:
      failures.append("S35 responsive lineup count "+str(count)+" did not match roster")
     if proof.find_children("LineupLeadVocal","Label",true,false).size()!=1:
      failures.append("S35 proof roster lead badge not unique at "+str(count))
     for person in people:
      var source_id: String = str(person.get("id",""))
      var face: TextureRect = proof.find_child("LineupPortrait_"+source_id,true,false) as TextureRect
      if face==null or face.texture==null:
       failures.append("S35 proof missing canonical preview for "+source_id)
     proof.queue_free()
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
   _check_identity_press(screen,"NamedMilestonePrint","Side Street","Wordmark")
   var m2_next: Button = screen.find_child("NameMilestoneNextAction",true,false)
   if m2_next==null or m2_next.get_global_rect().size.x<44.0 or m2_next.get_global_rect().end.y>float(h)-4.0:
    failures.append("S37 milestone2 Next action clipped from first fold")
 if screen.setup.screen=="name_milestone":
  await click_action(screen.find_child("NameMilestoneNextAction",true,false))
  if screen.setup.screen!="identity":
   failures.append("real milestone2 Next did not reach logo/vibe")
  else:
   await _draw_screen("identity",w,h)
 if screen.setup.screen=="identity":
  var identity_stage: Control = screen.find_child("IdentityPreviewStage",true,false)
  var expected_identity_width: float = minf(600.0,float(w) - (40.0 if w<720 else 80.0))
  if identity_stage==null or identity_stage.get_global_rect().size.x < expected_identity_width-2.0:
   failures.append("logo/vibe live preview retained narrow portrait frame")
  _check_identity_press(screen,"IdentityPreviewPrint","Side Street","Wordmark")
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
   var updated_preview: Control = screen.find_child("IdentityPreviewStage",true,false)
   if updated_preview==null or updated_preview.get_global_rect().size.x < expected_identity_width-2.0:
    failures.append("logo choice changed preview geometry")
   _check_identity_press(screen,"IdentityPreviewPrint","Side Street","Stamp")
  var finish_button: Button = screen.find_child("IdentityFinishAction",true,false)
  if finish_button==null or finish_button.get_global_rect().size.y<44.0 or finish_button.get_global_rect().end.y>float(h)-4.0:
   failures.append("S37 identity Finish action below first fold")
  await click_action(screen.find_child("IdentityFinishAction",true,false))
  if screen.setup.screen!="complete":
   failures.append("real Finish Identity did not reach completed summary")
  else:
   await _draw_screen("completed_band",w,h)
 if screen.setup.screen=="complete":
  _check_identity_press(screen,"CompletedBandPrint","Side Street","Stamp")
  # A hidden native fixture proves custom Unicode & monogram without changing saves.
  var unicode_press: Variant = IdentityPress.new()
  unicode_press.visible = false
  screen.add_child(unicode_press)
  unicode_press.configure(screen.setup.game.roster,screen.setup.lead_vocal_id,"Échos 雨","Monogram",screen.setup.palette,screen.setup.vibe,float(w),"complete")
  var unicode_full: Label = unicode_press.find_child("IdentityFullName",true,false) as Label
  var unicode_mark: Label = unicode_press.find_child("IdentityLiveMark",true,false) as Label
  if unicode_full==null or unicode_full.text!="Échos 雨" or unicode_mark==null or not unicode_mark.text.contains("É"):
   failures.append("S37 live custom Unicode or monogram broken")
  unicode_press.queue_free()
  # A bounded source-backed identity stage must also bound its associated
  # real progression button at phone, portrait tablet and desktop sizes.
  var practice_button: Button = screen.find_child("StartPlayAction",true,false)
  if practice_button != null:
   var permitted_width: float = minf(780.0,float(w) - (40.0 if w < 720 else 80.0))
   if practice_button.get_global_rect().size.x > permitted_width + 1.0 or practice_button.get_global_rect().end.y>float(h)-4.0:
    failures.append("S37 completed First Practice action clipped or wider than case")
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
  # S38: genuine pointer press of the existing Rehearse button, then
  # verify the saved causal result is restored by the real Continue menu.
  var rehearsal_action: Button = screen.find_child("RehearseAction",true,false)
  if rehearsal_action==null:
   failures.append("S38 rehearsal control missing after actual gameplay handoff")
  else:
   var count_before: int = int(screen.setup.game.career.get("action_count",0))
   await click_action(rehearsal_action)
   var report: Dictionary = screen.setup.game.career.get("last_rehearsal_outcome",{})
   var metrics: Dictionary = report.get("metrics",{})
   if report.get("focus","")!="tighten" or int(screen.setup.game.career.get("action_count",0))!=count_before+1:
    failures.append("S38 genuine Rehearse press did not settle exactly once")
   if int(metrics.get("cash",{}).get("delta",999))!=-15 or not metrics.has("readiness") or not metrics.has("cohesion"):
    failures.append("S38 Rehearse outcome missing actual cost, readiness or social cohesion")
   await _draw_screen("rehearsal_outcome",w,h)
   var saved_after_rehearsal: Dictionary = screen.setup.snapshot()
   screen.call("_home")
   await process_frame
   await click_action(screen.find_child("ContinueAction",true,false))
   if screen.setup.screen!="play" or screen.setup.snapshot()!=saved_after_rehearsal:
    failures.append("S38 real Continue re-applied or lost the saved rehearsal")
   else:
    await _draw_screen("rehearsal_resumed",w,h)

 print("C27_CAPTURE_RESULT ",JSON.stringify({"width":w,"height":h,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
