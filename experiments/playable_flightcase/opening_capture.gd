extends SceneTree
## Captures are native GL/Mesa/Xvfb pixels, never flattened mockup art.
const UI = preload("res://experiments/playable_flightcase/opening_ui.gd")
const Group = preload("res://experiments/playable_flightcase/band_lineup.gd")
const Poster = preload("res://experiments/playable_flightcase/band_formed_poster.gd")
const IdentityPress = preload("res://experiments/playable_flightcase/band_identity_press.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const ApprovedCast = preload("res://experiments/character_cast/catalogue.gd")
const Recap = preload("res://experiments/playable_flightcase/rehearsal_recap.gd")
const RehearsalScreen = preload("res://experiments/playable_flightcase/ui.gd")
const Game = preload("res://experiments/playable_flightcase/session.gd")
const OpeningModel = preload("res://experiments/playable_flightcase/opening_state.gd")
const RecruitBase = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
# Owner-protected passive meter PNG bytes from the verified 33f checkpoint.
const METER_SHA256 := [
 "d6f65ba3beec7a872e476383714c830b69234f190af219c9ba330d12c7a509b3",
 "5cee77d2f5c552b1e2a49916451b06c6e1974510cdc64b799cb34b4e68674770",
 "d9fb9ee0bfada2f00c20f03f54f1f3f276c69de285f5c93c454b3f8b57310c34",
 "f7c76def283b5ced820a6e7fb438d31e36b3b6d795df028204bd86f8294a33e1",
 "7909c750f2873aede2a18167b8bec01a034b804dabfb6857e27592f94487dff8",
 "798be62f2cabc0861d00a549bcb96fe6a913ff04559da200e0db104c239c8f28",
 "e779694ac1097605130127250e810518f3e4d2d0ee0432b36630377a8cd34497",
 "b1c2cf23627dbea16cd8aed671af2ccc5afe01c3162e0716b770a205b1459e04",
 "f2377576fa2cada0de19217cd4c2168c6eb1d9d04751d84edde840b05a6a4aed",
 "55af8861e00b8ff7a5dca6fed6c348529722241422b4a9b2ae4b8aeec5209688",
 "fe655bc9b7b7221f6479e8f5764db38c8f14498fc5990691e2234094d2f1be04",
]
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
# Real ui_accept input, deliberately separate from the retained pointer proof.
func _recap_key(keycode: int) -> void:
 var down := InputEventKey.new()
 down.keycode = keycode
 down.physical_keycode = keycode
 down.pressed = true
 Input.parse_input_event(down)
 await process_frame
 var up := InputEventKey.new()
 up.keycode = keycode
 up.physical_keycode = keycode
 up.pressed = false
 Input.parse_input_event(up)
 await process_frame
 await process_frame
 await process_frame

func _recap_save_bytes() -> Dictionary:
 var state: Dictionary = {}
 for path in ["user://c26_playable_sandbox.json","user://c27_opening_draft.json","user://band_profile.json","user://tour_save.json"]:
  state[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return state

func _check_practice_layout(screen: Control,w: int,h: int,exercise_choices: bool) -> void:
 var bounds := Rect2(0,0,w,h)
 var practice_scroll: ScrollContainer = screen.find_child("PracticeScroll",true,false) as ScrollContainer
 var frame: Control = screen.find_child("PracticeFrame",true,false) as Control
 var budget: Label = screen.find_child("BudgetLabel",true,false) as Label
 if practice_scroll==null or frame==null or budget==null:
  failures.append("S40 practice layout missing named form, frame or budget")
  return
 if frame.get_global_rect().position.x<0 or frame.get_global_rect().end.x>float(w):
  failures.append("S40 practice frame overflows viewport horizontally")
 if not budget.text.contains("£"+str(int(screen.setup.game.career.get("cash",0)))) or not bounds.encloses(budget.get_global_rect()):
  failures.append("S40 practice cash/header is clipped or not the actual balance")
 for action_name in ["WriteAction","RehearseAction","ClearAirAction"]:
  var action: Button = screen.find_child(action_name,true,false) as Button
  if action==null or not bounds.encloses(action.get_global_rect()) or action.size.x<44 or action.size.y<44:
   failures.append("S40 practice action is not a first-fold physical target: "+action_name)
  elif practice_scroll.get_global_rect().intersects(action.get_global_rect()):
   failures.append("S40 practice action overlaps its scrolling form: "+action_name)
 if not exercise_choices:
  return
 var before: Dictionary = screen.setup.snapshot()
 var saves: Dictionary = _recap_save_bytes()
 for spec in [["PracticeIdeaChoices","idea_index",["Riff","Lyric","Groove"]],["PracticeArrangementChoices","form_index",["Verse / Chorus","Slow Build","Loose Jam"]]]:
  var choices: Control = screen.find_child(str(spec[0]),true,false) as Control
  if choices==null:
   failures.append("S40 practice choice group missing: "+str(spec[0]))
   continue
  var owner: Node = choices
  while owner!=null and owner.get_script()!=RehearsalScreen:
   owner = owner.get_parent()
  var buttons: Array[Node] = choices.find_children("*","Button",true,false)
  if buttons.size()!=3 or owner==null:
   failures.append("S40 practice choices lost original three options or owner")
   continue
  for index in [1,2,0]:
   var button: Button = buttons[index] as Button
   var skin: StyleBox = button.get_theme_stylebox("normal")
   var text_width: float = button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
   if button.text!=str(spec[2][index]) or button.clip_text or text_width>button.size.x-skin.get_minimum_size().x+1.0 or button.get_global_rect().position.x<0 or button.get_global_rect().end.x>float(w):
    failures.append("S40 practice option label clips or changed: "+button.text)
   await click_action(button)
   var selected: int = 0
   for peer in buttons:
    if (peer as Button).button_pressed:
     selected += 1
   if selected!=1 or not button.button_pressed or int(owner.get(str(spec[1])))!=index:
    failures.append("S40 real practice option click failed exclusive actual selection: "+button.text)
 if screen.setup.snapshot()!=before or _recap_save_bytes()!=saves:
  failures.append("S40 practice option browsing mutated career or save bytes")
 practice_scroll.scroll_vertical = 0
 await process_frame
 await process_frame
 print("S40_PRACTICE_LAYOUT ",JSON.stringify({"width":w,"height":h,"cash":budget.text,"choice_round_trip":true,"fixed_actions":3}))

func _recruit_person(pane) -> Dictionary:
 var choices: Array = pane.game.choices(str(pane.role))
 var index: int = int(pane.selected_index)
 return choices[index] if index>=0 and index<choices.size() else {}

func _check_recruit_context(pane,w: int,h: int,tag: String) -> void:
 var person := _recruit_person(pane)
 if person.is_empty():
  failures.append("S40 "+tag+" selected candidate is not canonical")
  return
 var viewport := Rect2(0,0,w,h)
 var context: Control = pane.find_child("RecruitDecisionContext",true,false)
 var dock: Control = pane.find_child("RecruitDecisionDock",true,false)
 var strength: Label = pane.find_child("RecruitStrength",true,false)
 var friction: Label = pane.find_child("RecruitFriction",true,false)
 var affordability: Label = pane.find_child("RecruitAffordability",true,false)
 var header: Label = pane.find_child("BudgetLabel",true,false)
 var candidate_name: Label = pane.find_child("RecruitCandidateName",true,false)
 var profile_bounds: ScrollContainer = pane.find_child("RecruitProfileScroll",true,false)
 var expected_identity: String = "%s  •  %s" % [str(person.name).to_upper(),str(pane.role).to_upper()]
 if candidate_name==null or candidate_name.text!=expected_identity:
  failures.append("S40 "+tag+" candidate name/role is not the full canonical identity")
 elif profile_bounds==null or candidate_name.get_global_rect().position.x<profile_bounds.get_global_rect().position.x or candidate_name.get_global_rect().end.x>profile_bounds.get_global_rect().end.x:
  failures.append("S40 "+tag+" candidate name/role escapes profile width")
 elif str(person.id) in ["cast_maya","cast_bex","cast_sam"] and candidate_name.get_line_count()!=1:
  failures.append("S40 "+tag+" short candidate identity/long role wraps despite fixed browse allocation")
 for arrow_name in ["RecruitPreviousAction","RecruitNextAction"]:
  var arrow: Button = pane.find_child(arrow_name,true,false)
  if arrow==null or arrow.get_global_rect().size.x<44.0 or arrow.get_global_rect().size.x>50.0:
   failures.append("S40 "+tag+" browse chevron width competes with candidate identity: "+arrow_name)
 if context==null or dock==null or strength==null or friction==null or affordability==null or header==null:
  failures.append("S40 "+tag+" recruitment trade-off context missing")
  return
 if strength.text!="STRENGTH  •  "+str(person.get("strength","Still developing")) or friction.text!="FRICTION  •  "+str(person.get("friction","Unknown")):
  failures.append("S40 "+tag+" full authored candidate trade-offs changed or were truncated")
 for label in [strength,friction,affordability]:
  if label.get_theme_font_size("font_size")!=16 or not label.is_visible_in_tree() or not viewport.encloses(label.get_global_rect()):
   failures.append("S40 "+tag+" 16px decision text is not fully visible in first fold: "+str(label.name))
 if strength.get_global_rect().end.y>friction.get_global_rect().position.y or friction.get_global_rect().end.y>affordability.get_global_rect().position.y or affordability.get_global_rect().end.y>dock.get_global_rect().position.y:
  failures.append("S40 "+tag+" trade-off text overlaps the next line/action row")
 if not viewport.encloses(context.get_global_rect()) or (w>=840 and w>=h and context.size.x>762.0):
  failures.append("S40 "+tag+" decision context exceeds viewport/bounded desktop width")
 var available: int = int(pane.onboarding_state.remaining()) if pane.onboarding_state!=null else pane.game.remaining()
 var cost: int = RecruitBase.incremental_cost(pane.game.roster,person)
 var recruited: bool = RecruitBase.contains(pane.game.roster,str(person.id))
 var expected: String
 if recruited:
  expected = "IN YOUR BAND  •  %d TALENT AVAILABLE" % available
 elif pane.game.roster.size()>=6:
  expected = "BAND FULL  •  6/6 MEMBERS  •  %d TALENT AVAILABLE" % available
 elif cost>available:
  expected = "NEED %d MORE TALENT  •  %d AVAILABLE" % [cost-available,available]
 else:
  expected = "%d TALENT  •  %d AVAILABLE  •  %d AFTER RECRUIT" % [cost,available,available-cost]
 if affordability.text!=expected or header.text!="TALENT %d / 200" % available or not viewport.encloses(header.get_global_rect()):
  failures.append("S40 "+tag+" availability/reservation/post-recruit forecast is incorrect")
 var action: Button = pane.find_child("RemoveAction" if recruited else "RecruitAction",true,false)
 var allowed: bool = bool(pane.onboarding_state.can_recruit(str(person.id))) if pane.onboarding_state!=null else RecruitBase.can_add(pane.game.roster,person)
 if action==null:
  failures.append("S40 "+tag+" recruit/remove decision missing")
 else:
  if action.get_parent()!=dock or action.size.y<44 or not viewport.encloses(action.get_global_rect()) or action.disabled!=(false if recruited else not allowed):
   failures.append("S40 "+tag+" recruit/remove target is hidden, misplaced or wrongly gated")
  if not recruited and pane.game.roster.size()>=6 and action.text!="BAND FULL":
   failures.append("S40 "+tag+" full roster implies a zero-cost recruitment")
 var ready: bool = bool(pane.onboarding_state.ready()) if pane.onboarding_state!=null else pane.game.can_start()
 var start: Button = pane.find_child("StartAction",true,false)
 if ready:
  if start==null or start.get_parent()!=dock or start.size.y<44 or not viewport.encloses(start.get_global_rect()):
   failures.append("S40 "+tag+" ready second action is clipped or misplaced")
  if w<840 or w<h:
   if start!=null and start.text!="COMPLETE LINEUP":
    failures.append("S40 "+tag+" ready mobile completion label is not compact")
   if action!=null and (recruited or pane.game.roster.size()<6) and action.text!=("REMOVE" if recruited else "RECRUIT"):
    failures.append("S40 "+tag+" ready mobile recruit/remove label does not fit shared row")
 var profile: ScrollContainer = pane.find_child("RecruitProfileScroll",true,false)
 var stats: Array = RecruitBase.stats_for(person,str(pane.role))
 for index in range(6):
  var meter: TextureRect = pane.find_child("PassiveMeter"+str(index),true,false)
  var score: int = int(stats[index])
  var path: String = "res://components/control_atlas/art/passive_meter_flightcase_%02d.png" % score
  if meter==null or meter.texture==null or meter.texture.resource_path!=path or int(meter.get("score"))!=score or FileAccess.get_sha256(path)!=METER_SHA256[score]:
   failures.append("S40 "+tag+" original selected passive meter bytes/value changed: "+str(index))
  elif meter.focus_mode!=Control.FOCUS_NONE or meter.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("S40 "+tag+" passive selected stat takes input/focus: "+str(index))
  elif profile==null or not profile.get_global_rect().encloses(meter.get_global_rect()):
   failures.append("S40 "+tag+" first fold still hides selected meter "+str(index))
 print("S40_RECRUIT_CONTEXT ",JSON.stringify({"case":tag,"candidate":person.id,"width":w,"height":h,"cost":cost,"available":available,"ready":ready,"copy":affordability.text}))

func _check_recruit_profile_keyboard(pane,w: int,h: int,tag: String) -> void:
 var scroll: ScrollContainer = pane.find_child("RecruitProfileScroll",true,false)
 if scroll==null:
  failures.append("S40 "+tag+" keyboard dossier scroll missing")
  return
 var before: Dictionary = pane.game.snapshot()
 var files: Dictionary = _recap_save_bytes()
 var bar: VScrollBar = scroll.get_v_scroll_bar()
 if bar.visible:
  var action: Button = pane.find_child("RecruitAction",true,false)
  if action!=null and not action.disabled:
   action.grab_focus()
  if bar.focus_mode!=Control.FOCUS_ALL or not await _tab_to(bar,24):
   failures.append("S40 "+tag+" Tab cannot reach original dossier scrollbar")
  await _recap_key(KEY_HOME)
  if scroll.scroll_vertical!=0:
   failures.append("S40 "+tag+" native Home did not restore the profile start")
 # All six primary stats must be readable immediately. The optional dossier
 # uses the engine's verified Home/End controls; Page Down is unsupported here.
 for index in range(6):
  var meter: Control = pane.find_child("PassiveMeter"+str(index),true,false)
  if meter==null or not scroll.get_global_rect().encloses(meter.get_global_rect()):
   failures.append("S40 "+tag+" initial profile/keyboard Home hides stat "+str(index))
 if bar.visible:
  await _recap_key(KEY_END)
  if scroll.scroll_vertical!=roundi(bar.max_value-bar.page) or not bar.has_focus():
   failures.append("S40 "+tag+" native End did not reach the full dossier with focus retained")
  await _recap_key(KEY_HOME)
  if scroll.scroll_vertical!=0 or not bar.has_focus():
   failures.append("S40 "+tag+" native Home did not restore the dossier with focus retained")
 print("S40_RECRUIT_SCROLL ",JSON.stringify({"case":tag,"width":w,"height":h,"visible_bar":bar.visible,"maximum":roundi(bar.max_value-bar.page),"home":scroll.scroll_vertical}))
 if pane.game.snapshot()!=before or _recap_save_bytes()!=files:
  failures.append("S40 "+tag+" keyboard dossier browsing mutated game/save bytes")

func _draw_recruit_context_fixtures(screen,w: int,h: int) -> void:
 var files: Dictionary = _recap_save_bytes()
 var original: Dictionary = screen.setup.snapshot()
 var cases := [
  {"name":"long_bex","target":"cast_bex","roster":[],"capture":true},
  {"name":"long_sam","target":"cast_sam","roster":[],"capture":true},
  {"name":"ready_trio","target":"cast_casey","roster":["cast_jack","cast_zoe","cast_casey"],"vocal":"cast_jack","capture":true},
  {"name":"fifth_cost","target":"cast_dan","roster":["cast_maya","cast_jack","cast_zoe","cast_casey"]},
  {"name":"sixth_cost","target":"cast_jack","roster":["cast_nina","cast_tom","cast_ben","cast_ellis","cast_dan"]},
  {"name":"vocal_reservation","target":"cast_nina","roster":["cast_maya","cast_jack","cast_zoe","cast_dan","cast_casey"],"vocal":"cast_jack"},
  {"name":"shortfall","target":"cast_bex","roster":["cast_maya","cast_jack","cast_zoe","cast_dan","cast_casey"]},
  {"name":"full_six","target":"cast_maya","roster":["cast_nina","cast_tom","cast_ben","cast_ellis","cast_dan","cast_jack"]},
 ]
 screen.hide()
 for entry in cases:
  var model := OpeningModel.new()
  model.screen = "recruit"
  for pid in entry.roster:
   if not model.game.recruit(pid).get("ok",false):
    failures.append("S40 invalid canonical recruitment fixture "+str(entry.name)+" "+str(pid))
  # Reachable fixture reservation; no recruit/choose_vocal/save_draft call
  # writes the player's sandbox while these read-only states are inspected.
  model.lead_vocal_id = str(entry.get("vocal",""))
  var candidate: Dictionary = model.game.person_by_id(str(entry.target))
  var fixture = RehearsalScreen.new()
  fixture.game = model.game
  fixture.onboarding_state = model
  fixture.last_message = "RECRUITMENT QA FIXTURE  /  NO SAVE"
  fixture.role = str(candidate.get("primary_role",candidate.get("roles",["Singer"])[0]))
  var choices: Array = model.game.choices(fixture.role)
  fixture.selected_index = -1
  for index in range(choices.size()):
   if str(choices[index].get("id",""))==str(entry.target):
    fixture.selected_index = index
  if fixture.selected_index<0:
   failures.append("S40 recruitment fixture candidate absent from actual role "+str(entry.target))
   fixture.free()
   continue
  var before: Dictionary = model.snapshot()
  root.add_child(fixture)
  await process_frame
  await process_frame
  await process_frame
  _check_recruit_context(fixture,w,h,str(entry.name))
  if bool(entry.get("capture",false)):
   await _draw_screen("recruit_"+str(entry.name),w,h)
  if str(entry.name) in ["long_bex","long_sam"]:
   await _check_recruit_profile_keyboard(fixture,w,h,str(entry.name))
  if model.snapshot()!=before or _recap_save_bytes()!=files:
   failures.append("S40 read-only recruitment fixture changed source state/save "+str(entry.name))
  fixture.free()
  await process_frame
 screen.show()
 if screen.setup.snapshot()!=original or _recap_save_bytes()!=files:
  failures.append("S40 recruitment QA fixtures changed the real player's state/save")

func _check_recap_clarity(screen: Control,report: Dictionary,members: Array,w: int,h: int,context: String) -> void:
 var view: Dictionary = Recap.present(report,members)
 var advice: Label = screen.find_child("RecapNextMove",true,false) as Label
 var action: Button = screen.find_child("RecapToggleAction",true,false) as Button
 var scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var viewport := Rect2(0,0,w,h)
 if advice==null or action==null or scroll==null:
  failures.append("S40 "+context+" missing next-move advice or return dock")
  return
 if advice.text!=str(view.get("next_step","")) or advice.text.is_empty():
  failures.append("S40 "+context+" next move does not describe the actual saved outcome")
 if not advice.is_visible_in_tree() or advice.get_theme_font_size("font_size")!=16 or not viewport.encloses(advice.get_global_rect()):
  failures.append("S40 "+context+" canonical 16px next move is not visible in first fold")
 if action.text!="BACK TO PRACTICE  ›" or action.get_global_rect().size.y<44 or not viewport.encloses(action.get_global_rect()):
  failures.append("S40 "+context+" return action is mislabeled, too small or clipped")
 if advice.get_global_rect().end.y>action.get_global_rect().position.y or scroll.get_global_rect().intersects(advice.get_global_rect()) or scroll.get_global_rect().intersects(action.get_global_rect()):
  failures.append("S40 "+context+" next move/return action overlaps report or each other")
 if advice.focus_mode!=Control.FOCUS_NONE or advice.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
  failures.append("S40 "+context+" read-only next move steals input")
 var tablet: bool = w>=600 and w<900 and h>w
 var minimum_reaction: int = 16 if tablet else 14
 var minimum_readout: int = 13 if tablet else 12
 var gallery: ScrollContainer = screen.find_child("RecapMemberGallery",true,false) as ScrollContainer
 for voice in view.get("reactions",[]):
  if not voice is Dictionary:
   continue
  var pid: String = str(voice.get("candidate_id",""))
  var caption: Label = screen.find_child("RecapMember_"+pid,true,false) as Label
  if caption==null or caption.get_theme_font_size("font_size")<minimum_reaction:
   failures.append("S40 "+context+" primary reaction is too small: "+pid)
  elif gallery!=null:
   var lower_edge: float = gallery.get_global_rect().end.y
   if gallery.get_h_scroll_bar().visible:
    lower_edge -= gallery.get_h_scroll_bar().size.y
   if caption.get_global_rect().position.y<gallery.get_global_rect().position.y or caption.get_global_rect().end.y>lower_edge+1.0:
    failures.append("S40 "+context+" readable reaction is vertically clipped: "+pid)
  if caption!=null and view.get("reactions",[]).size()<=3:
   var mood: Label = screen.find_child("RecapMood_"+pid,true,false) as Label
   if not scroll.get_global_rect().encloses(caption.get_global_rect()) or mood==null or not scroll.get_global_rect().encloses(mood.get_global_rect()):
    failures.append("S40 "+context+" primary reaction or morale is outside initial report viewport: "+pid)
  if pid=="cast_casey" and caption!=null:
   var quote: String = str(voice.get("quote",""))
   var full: Label = screen.find_child("RecapFullQuote_"+pid,true,false) as Label
   if full==null or full.text!=str(voice.get("name","Musician"))+" — “"+quote+"”":
    failures.append("S40 "+context+" complete Casey reaction changed")
   if quote.length()>32:
    var lines: PackedStringArray = caption.text.split("\n",false,1)
    if lines.size()!=2 or not lines[1].begins_with("“") or not lines[1].ends_with("…”"):
     failures.append("S40 "+context+" Casey excerpt has no clear truncation marker")
    else:
     var excerpt: String = lines[1].trim_prefix("“").trim_suffix("…”")
     if excerpt.is_empty() or not quote.begins_with(excerpt) or quote.substr(excerpt.length(),1) not in [" ",".",",","!","?"]:
      failures.append("S40 "+context+" Casey excerpt cuts a word instead of retaining a whole phrase")
 for key in ["readiness","morale","tension"]:
  var readout: Label = screen.find_child("RecapBeforeAfter_"+key,true,false) as Label
  var metric: Dictionary = report.get("metrics",{}).get(key,{})
  var expected: String = "%d → %d" % [int(metric.get("before",0)),int(metric.get("after",0))]
  if readout==null or readout.get_theme_font_size("font_size")<minimum_readout or readout.text!=expected:
   failures.append("S40 "+context+" before/after readout is too small or not source-accurate: "+key)
 print("S40_RECAP_CLARITY ",JSON.stringify({"context":context,"width":w,"height":h,"next_move":advice.text,"reaction_min":minimum_reaction,"readout_min":minimum_readout,"return_label":action.text}))

# Exercise the other two relocated actions on disposable copies of the real
# career. Expected effects come from the unchanged authoritative model; neither
# copy has an opening owner or any permission to save.
func _check_practice_dispatch(screen: Control,w: int,h: int) -> void:
 var before: Dictionary = screen.setup.snapshot()
 var saved_files: Dictionary = _recap_save_bytes()
 screen.hide()
 for action_name in ["WriteAction","ClearAirAction"]:
  var trial = Game.new()
  var expected = Game.new()
  if not trial.restore(screen.setup.game.snapshot()) or not expected.restore(screen.setup.game.snapshot()):
   failures.append("S40 practice dispatch could not copy the genuine career")
   continue
  var result: Dictionary = expected.write_session("Riff","Verse / Chorus","THE LAST BUS HOME",0) if action_name=="WriteAction" else expected.clear_air()
  if not result.get("ok",false):
   failures.append("S40 practice dispatch expected model action was invalid")
   continue
  var fixture = RehearsalScreen.new()
  fixture.game = trial
  fixture.recap_expanded = false
  fixture.last_message = "PRACTICE ACTION QA FIXTURE  /  NO SAVE"
  root.add_child(fixture)
  await process_frame
  await process_frame
  await process_frame
  await click_action(fixture.find_child(action_name,true,false) as Button)
  if trial.snapshot()!=expected.snapshot():
   failures.append("S40 relocated practice action differed from one genuine settlement: "+action_name)
  if screen.setup.snapshot()!=before or _recap_save_bytes()!=saved_files:
   failures.append("S40 isolated practice dispatch modified player state or save files")
  print("S40_PRACTICE_DISPATCH ",JSON.stringify({"width":w,"height":h,"action":action_name,"action_count":trial.career.get("action_count",0),"matches_single_model_action":trial.snapshot()==expected.snapshot()}))
  fixture.queue_free()
  await process_frame
  await process_frame
 screen.show()

func _check_recap_keyboard(screen,w: int,h: int) -> void:
 var action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
 var scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
 if action==null or scroll==null or detail==null:
  failures.append("S40 keyboard disclosure controls missing")
  return
 scroll.ensure_control_visible(action)
 await process_frame
 await process_frame
 action.grab_focus()
 await process_frame
 var action_id: int = action.get_instance_id()
 var scroll_id: int = scroll.get_instance_id()
 var detail_id: int = detail.get_instance_id()
 var offset: int = scroll.scroll_vertical
 var before: Dictionary = screen.setup.snapshot()
 var saved_files: Dictionary = _recap_save_bytes()
 if not action.has_focus():
  failures.append("S40 full-breakdown action cannot receive keyboard focus")
 await _recap_key(KEY_ENTER)
 var live_action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
 var live_scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var live_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
 if live_action==null or live_scroll==null or live_detail==null:
  failures.append("S40 Enter destroyed disclosure controls")
  return
 if live_action.get_instance_id()!=action_id or live_scroll.get_instance_id()!=scroll_id or live_detail.get_instance_id()!=detail_id:
  failures.append("S40 Enter rebuilt settled recap instead of revealing it in place")
 if not live_action.has_focus():
  failures.append("S40 Enter lost full-breakdown keyboard focus")
 if absi(live_scroll.scroll_vertical-offset)>1:
  failures.append("S40 Enter reset report scroll position")
 if not live_detail.visible or live_action.text!="HIDE FULL BREAKDOWN":
  failures.append("S40 genuine Enter did not reveal full ledger/update toggle")
 var view: Dictionary = Recap.present(screen.setup.game.career.get("last_rehearsal_outcome",{}),screen.setup.game.career.get("members",[]))
 var last_quote: Label = null
 for voice in view.get("reactions",[]):
  if not voice is Dictionary:
   continue
  var pid: String = str(voice.get("candidate_id",""))
  var full_quote: Label = live_detail.find_child("RecapFullQuote_"+pid,true,false) as Label
  var expected: String = str(voice.get("name","Musician"))+" — “"+str(voice.get("quote",""))+"”"
  if full_quote==null or full_quote.text!=expected or not full_quote.is_visible_in_tree():
   failures.append("S40 expanded ledger lost full authored reaction for "+pid)
  elif full_quote.get_theme_font_size("font_size")<16:
   failures.append("S40 full reaction text too small for "+pid)
  else:
   last_quote = full_quote
 # Actual expanded native pixels show the complete reaction that the compact
 # hero deliberately excerpts. Restore the prior reading position afterward.
 if last_quote!=null:
  live_scroll.ensure_control_visible(last_quote)
  await process_frame
  await process_frame
  await _draw_screen("rehearsal_full_reactions",w,h)
 live_scroll.scroll_vertical = offset
 await process_frame
 await process_frame
 live_action.grab_focus()
 var collapse_offset: int = live_scroll.scroll_vertical
 await _recap_key(KEY_SPACE)
 var closed_action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
 var closed_scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var closed_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
 if closed_action==null or closed_scroll==null or closed_detail==null:
  failures.append("S40 Space destroyed disclosure controls")
 else:
  if closed_action.get_instance_id()!=action_id or closed_scroll.get_instance_id()!=scroll_id or closed_detail.get_instance_id()!=detail_id:
   failures.append("S40 Space rebuilt settled recap instead of collapsing it in place")
  if not closed_action.has_focus():
   failures.append("S40 Space lost full-breakdown keyboard focus")
  if absi(closed_scroll.scroll_vertical-collapse_offset)>1:
   failures.append("S40 Space reset report scroll position")
  if closed_detail.visible or closed_action.text!="FULL BREAKDOWN  ›":
   failures.append("S40 genuine Space did not collapse full ledger/update toggle")
 if screen.setup.snapshot()!=before or _recap_save_bytes()!=saved_files:
  failures.append("S40 keyboard disclosure changed settled gameplay or save bytes")
 print("S40_NATIVE_DISCLOSURE ",JSON.stringify({"width":w,"height":h,"focus_retained":closed_action!=null and closed_action.has_focus(),"scroll_before":offset,"scroll_after":closed_scroll.scroll_vertical if closed_scroll!=null else -1,"full_reactions":view.get("reactions",[]).size()}))

func _tab_to(target: Control, limit: int = 8) -> bool:
 for step in range(limit):
  if target.has_focus():
   return true
  await _recap_key(KEY_TAB)
 return target.has_focus()

# Maximum affordable real C25 roster, genuine resolver, existing report view.
# This labelled native fixture neither overwrites the player's game nor saves.
func _draw_six_member_recap(screen,w: int,h: int) -> void:
 var saved_files: Dictionary = _recap_save_bytes()
 var original_game: Dictionary = screen.setup.snapshot()
 var roster: Array[String] = ["cast_nina","cast_tom","cast_ben","cast_ellis","cast_dan","cast_jack"]
 var game = Game.new()
 for pid in roster:
  if not game.recruit(pid).get("ok",false):
   failures.append("S40 six-member fixture could not recruit actual "+pid)
 if game.spent()!=197 or not game.launch().get("ok",false):
  failures.append("S40 six-member fixture violated actual 197-talent formation")
  return
 if not game.clear_air().get("ok",false):
  failures.append("S40 six-member fixture could not resolve real band meeting")
  return
 var before: Dictionary = game.snapshot()
 var fixture = RehearsalScreen.new()
 fixture.game = game
 fixture.last_message = "SIX-MEMBER QA FIXTURE  /  197 TALENT  /  NO SAVE"
 screen.hide()
 root.add_child(fixture)
 await process_frame
 await process_frame
 await process_frame
 _check_recap_clarity(fixture,game.career.get("last_rehearsal_outcome",{}),game.career.get("members",[]),w,h,"six-member band meeting")
 var gallery: ScrollContainer = fixture.find_child("RecapMemberGallery",true,false) as ScrollContainer
 var footer: Button = fixture.find_child("RecapToggleAction",true,false) as Button
 if gallery==null or footer==null:
  failures.append("S40 six-member report/gallery fixture missing")
 else:
  var bar: HScrollBar = gallery.get_h_scroll_bar()
  var first: Control = fixture.find_child("RecapPortraitCard_"+roster[0],true,false) as Control
  var last: Control = fixture.find_child("RecapPortraitCard_"+roster[-1],true,false) as Control
  if fixture.find_children("RecapPortraitCard_*","VBoxContainer",true,false).size()!=6:
   failures.append("S40 six-member gallery dropped a selected musician")
  var browse_hint: Label = fixture.find_child("RecapBrowseHint",true,false) as Label
  if browse_hint!=null and (browse_hint.get_line_count()!=1 or browse_hint.get_global_rect().size.y>32):
   failures.append("S40 six-member browse hint collapsed into a vertical text column")
  if footer.get_global_rect().size.y<44 or footer.get_global_rect().end.y>float(h):
   failures.append("S40 six-member fixture lost first-fold Continue action")
  for pid in roster:
   var portrait: TextureRect = fixture.find_child("RecapPortrait_"+pid,true,false) as TextureRect
   var caption: Label = fixture.find_child("RecapMember_"+pid,true,false) as Label
   var stripe: ColorRect = fixture.find_child("RecapMoodStripe_"+pid,true,false) as ColorRect
   for passive in [portrait,caption,stripe]:
    if passive==null or passive.focus_mode!=Control.FOCUS_NONE or passive.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
     failures.append("S40 gallery fixture made passive musician data interactive: "+pid)
   var full_quote: Label = fixture.find_child("RecapFullQuote_"+pid,true,false) as Label
   if full_quote==null or full_quote.get_theme_font_size("font_size")<16:
    failures.append("S40 six-member report lost full reaction text: "+pid)
  if bar.visible:
   if bar.focus_mode!=Control.FOCUS_ALL or first==null or last==null:
    failures.append("S40 overflowing gallery has no keyboard scrollbar/endpoint")
   else:
    footer.grab_focus()
    if not await _tab_to(bar):
     failures.append("S40 Tab cannot reach existing overflowing gallery scrollbar")
    await _recap_key(KEY_END)
    var maximum: int = roundi(bar.max_value-bar.page)
    if gallery.scroll_horizontal!=maximum or not gallery.get_global_rect().encloses(last.get_global_rect()):
     failures.append("S40 native End did not reveal final selected musician")
    await _draw_screen("rehearsal_six_members_end",w,h)
    await _recap_key(KEY_HOME)
    if gallery.scroll_horizontal!=0 or not gallery.get_global_rect().encloses(first.get_global_rect()):
     failures.append("S40 native Home did not restore first selected musician")
  else:
   footer.grab_focus()
   for step in range(8):
    await _recap_key(KEY_TAB)
    if bar.has_focus():
     failures.append("S40 hidden gallery scrollbar traps Tab when roster fits")
  await _draw_screen("rehearsal_six_members",w,h)
  var details: Button = fixture.find_child("RecapDetailsToggleAction",true,false) as Button
  var report_scroll: ScrollContainer = fixture.find_child("RehearsalResultScroll",true,false) as ScrollContainer
  var last_quote: Label = fixture.find_child("RecapFullQuote_"+roster[-1],true,false) as Label
  if details==null or report_scroll==null or last_quote==null:
   failures.append("S40 six-member ledger keyboard route missing")
  else:
   details.grab_focus()
   await _recap_key(KEY_ENTER)
   var vertical: VScrollBar = report_scroll.get_v_scroll_bar()
   if vertical.visible:
    if vertical.focus_mode!=Control.FOCUS_ALL or not await _tab_to(vertical):
     failures.append("S40 Tab cannot reach existing expanded-ledger scrollbar")
    await _recap_key(KEY_END)
    if report_scroll.scroll_vertical!=roundi(vertical.max_value-vertical.page) or not report_scroll.get_global_rect().encloses(last_quote.get_global_rect()):
     failures.append("S40 native End did not reveal final full musician reaction")
    await _draw_screen("rehearsal_six_members_ledger_end",w,h)
    await _recap_key(KEY_HOME)
    if report_scroll.scroll_vertical!=0:
     failures.append("S40 native Home did not restore ledger reading position")
   else:
    for step in range(8):
     await _recap_key(KEY_TAB)
     if vertical.has_focus():
      failures.append("S40 hidden vertical scrollbar traps Tab when ledger fits")
   details.grab_focus()
   await _recap_key(KEY_SPACE)
  print("S40_SIX_MEMBER_GALLERY ",JSON.stringify({"width":w,"height":h,"talent":game.spent(),"members":6,"overflow":bar.visible,"scroll_max":roundi(bar.max_value-bar.page),"verdict":game.career.get("last_rehearsal_outcome",{}).get("verdict","")}))
 if game.snapshot()!=before or screen.setup.snapshot()!=original_game or _recap_save_bytes()!=saved_files:
  failures.append("S40 six-member gallery fixture mutated real game or save bytes")
 fixture.free()
 screen.show()
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
 var initial_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
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
   _check_recruit_context(pane,w,h,"actual initial Maya")
   await _check_recruit_profile_keyboard(pane,w,h,"actual initial Maya")
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
    _check_recruit_context(pane,w,h,"actual browsed "+desired_id)
    var before_count: int = screen.setup.game.roster.size()
    var before_spent: int = screen.setup.game.spent()
    var before_available: int = screen.setup.remaining()
    var before_changes: int = screen.setup.change_counter
    var hire_cost: int = RecruitBase.incremental_cost(screen.setup.game.roster,_recruit_person(pane))
    await click_action(pane.find_child("RecruitAction",true,false))
    var confirmed := false
    for member in screen.setup.game.roster:
     if str(member.get("id",""))==desired_id:
      confirmed=true
    if not confirmed:
     failures.append("real recruit pointer did not hire "+desired_id)
     break
    if screen.setup.game.roster.size()!=before_count+1 or screen.setup.game.spent()!=before_spent+hire_cost or screen.setup.remaining()!=before_available-hire_cost or screen.setup.change_counter!=before_changes+1:
     failures.append("S40 real recruit did not charge/change roster exactly once: "+desired_id)
    _check_recruit_context(pane,w,h,"actual recruited "+desired_id)
    if desired_id=="cast_jack":
     await click_action(pane.find_child("RemoveAction",true,false))
     if screen.setup.game.roster.size()!=before_count or screen.setup.game.spent()!=before_spent or screen.setup.remaining()!=before_available or screen.setup.change_counter!=before_changes+2:
      failures.append("S40 genuine Remove did not refund the exact actual recruit once")
     _check_recruit_context(pane,w,h,"actual removed Jack")
     await click_action(pane.find_child("RecruitAction",true,false))
     if screen.setup.game.roster.size()!=before_count+1 or screen.setup.game.spent()!=before_spent+hire_cost or screen.setup.remaining()!=before_available-hire_cost or screen.setup.change_counter!=before_changes+3:
      failures.append("S40 genuine re-recruit lost the exact original cost/one-shot change")
   var vocal_action: Button = null
   for entry in pane.find_children("*","Button",true,false):
    var voice_button: Button = entry as Button
    if voice_button!=null and voice_button.text.to_upper().contains("JACK") and voice_button.text.to_upper().contains("TALENT"):
     vocal_action=voice_button
     break
   await click_action(vocal_action)
   if screen.setup.lead_vocal_id!="cast_jack" or not screen.setup.ready():
    failures.append("real vocalist selection or mandatory trio not ready")
   _check_recruit_context(pane,w,h,"actual ready trio with vocal reservation")
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
   await _check_practice_layout(screen,w,h,true)
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
   await _check_practice_layout(screen,w,h,false)
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
   # S39: the player sees the full SAME saved result, not an invented second action.
   var recap: Control = screen.find_child("RehearsalRecapPanel",true,false) as Control
   var ready_text: Label = screen.find_child("RecapMetric_readiness",true,false) as Label
   var cohesion_text: Label = screen.find_child("RecapMetric_cohesion",true,false) as Label
   var musician_text: Label = screen.find_child("RecapMember_cast_jack",true,false) as Label
   if recap==null or ready_text==null or cohesion_text==null or musician_text==null:
    failures.append("S39 actual native rehearsal recap, exact metrics or named selected musician absent")
   elif not ready_text.text.contains("28") or not musician_text.text.contains("Jack"):
    failures.append("S39 native recital does not show actual saved readiness/selected Jack")
   # S40: real first-fold, character-portrait and signed-result evidence.
   var stage_action: Button = screen.find_child("RecapToggleAction",true,false) as Button
   var score_tile: Label = screen.find_child("RecapHero_readiness",true,false) as Label
   var jack_photo: TextureRect = screen.find_child("RecapPortrait_cast_jack",true,false) as TextureRect
   var zoe_photo: TextureRect = screen.find_child("RecapPortrait_cast_zoe",true,false) as TextureRect
   var casey_photo: TextureRect = screen.find_child("RecapPortrait_cast_casey",true,false) as TextureRect
   if score_tile==null or score_tile.text!="+10":
    failures.append("S40 hero scorecard absent or not sourced from actual rehearsal +10")
   for metric_key in ["readiness","morale","tension"]:
    var tile: PanelContainer = screen.find_child("RecapHeroTile_"+metric_key,true,false) as PanelContainer
    if tile==null or not tile.get_theme_stylebox("panel") is StyleBoxTexture:
     failures.append("S40 scorecard lost its separate source-backed paper: "+metric_key)
    elif tile.mouse_filter!=Control.MOUSE_FILTER_IGNORE or tile.focus_mode!=Control.FOCUS_NONE:
     failures.append("S40 scorecard became interactive: "+metric_key)
   if jack_photo==null or zoe_photo==null or casey_photo==null:
    failures.append("S40 selected Jack Zoe Casey photographs not visible in native journal")
   elif jack_photo.texture==null or jack_photo.texture.get_width()<200:
    failures.append("S40 selected approved preview source missing or wrong resolution")
   if w>=600 and w<900 and h>w:
    var tablet_quote: Label = screen.find_child("RecapMember_cast_jack",true,false) as Label
    if tablet_quote==null or tablet_quote.get_theme_font_size("font_size")<16:
     failures.append("S40 tall-tablet reactions still use phone-sized text")
    for tablet_photo in [jack_photo,zoe_photo,casey_photo]:
     if tablet_photo==null or tablet_photo.get_global_rect().size.x<150 or tablet_photo.get_global_rect().size.x>tablet_photo.texture.get_width():
      failures.append("S40 tablet portrait is undersized or exceeds its honest source detail")
   if stage_action==null or stage_action.get_global_rect().size.y<44 or stage_action.get_global_rect().end.y>float(h)-4.0:
    failures.append("S40 real Continue Practising action not visible in first viewport")
   _check_recap_clarity(screen,report,screen.setup.game.career.get("members",[]),w,h,"three-member rehearsal")
   var detail_action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
   if detail_action==null:
    failures.append("S40 accessible full-breakdown control missing")
   else:
    var before_details: Dictionary = screen.setup.snapshot()
    await click_action(detail_action)
    var expanded_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
    if expanded_detail==null or not expanded_detail.visible:
     failures.append("S40 genuine detail action did not reveal all six saved measures")
    await click_action(screen.find_child("RecapDetailsToggleAction",true,false))
    var collapsed_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
    if collapsed_detail==null or collapsed_detail.visible:
     failures.append("S40 detailed ledger did not collapse")
    if screen.setup.snapshot()!=before_details:
     failures.append("S40 expanding the journal changed settled gameplay")
   await _check_recap_keyboard(screen,w,h)
   var before_ui_only: Dictionary = screen.setup.snapshot()
   var toggle_notes: Button = screen.find_child("RecapToggleAction",true,false) as Button
   if toggle_notes==null:
    failures.append("S39 real recap show/hide button absent")
   else:
    await click_action(toggle_notes)
    if screen.find_child("RehearsalRecapPanel",true,false)!=null:
     failures.append("S39 hide report failed")
    await _check_practice_layout(screen,w,h,false)
    await click_action(screen.find_child("RecapToggleAction",true,false))
    if screen.find_child("RehearsalRecapPanel",true,false)==null:
     failures.append("S39 show report failed")
    if screen.setup.snapshot()!=before_ui_only:
     failures.append("S39 viewing notes mutated the career/settled rehearsal twice")
   await _draw_screen("rehearsal_outcome",w,h)
   var saved_after_rehearsal: Dictionary = screen.setup.snapshot()
   screen.call("_home")
   await process_frame
   await click_action(screen.find_child("ContinueAction",true,false))
   if screen.setup.screen!="play" or screen.setup.snapshot()!=saved_after_rehearsal:
    failures.append("S38 real Continue re-applied or lost the saved rehearsal")
   else:
    var saved_recap: Control = screen.find_child("RehearsalRecapPanel",true,false) as Control
    var restored_name: Label = screen.find_child("RecapMember_cast_jack",true,false) as Label
    if saved_recap==null or restored_name==null or not restored_name.text.contains("Jack"):
     failures.append("S39 saved rehearsal recap missing after genuine menu Continue")
    var restored_header: Label = screen.find_child("StatusMessage",true,false) as Label
    if restored_header==null or not restored_header.text.contains("LAST SESSION") or not restored_header.text.contains("Good progress"):
     failures.append("S39 resumed phase shows stale recruitment text instead of saved rehearsal verdict")
    _check_recap_clarity(screen,screen.setup.game.career.get("last_rehearsal_outcome",{}),screen.setup.game.career.get("members",[]),w,h,"resumed rehearsal")
    await _draw_screen("rehearsal_resumed",w,h)

 await _check_practice_dispatch(screen,w,h)
 await _draw_recruit_context_fixtures(screen,w,h)
 await _draw_six_member_recap(screen,w,h)

 # Deferred frees from the final screen transition must settle before checking
 # controls allocated along the complete recruitment/Continue journey.
 await process_frame
 await process_frame
 var remaining_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 if remaining_orphans>initial_orphans:
  failures.append("S40 journey leaked %d orphan controls" % (remaining_orphans-initial_orphans))
 print("C27_CAPTURE_RESULT ",JSON.stringify({"width":w,"height":h,"orphan_nodes_added":remaining_orphans-initial_orphans,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
