extends Control
const IdentityStyle = preload("res://experiments/playable_flightcase/identity_style.gd")
const BandMark = preload("res://experiments/playable_flightcase/band_mark.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const RadioVisit = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const Situation = preload("res://experiments/playable_flightcase/situation_core.gd")
const WorkConflict = preload("res://experiments/playable_flightcase/work_conflict_view.gd")
signal lineup_confirmed
signal back_requested
signal career_requested
## C26 player-facing isolated scene. Existing photographic flightcase controls,
## original inert meters and genuine career rules; no flattened clickable mockup.
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Recap = preload("res://experiments/playable_flightcase/rehearsal_recap.gd")
const RehearsalPress = preload("res://experiments/playable_flightcase/rehearsal_press.gd")
const SessionTransition = preload("res://experiments/playable_flightcase/session_transition.gd")
const InkNote = preload("res://experiments/playable_flightcase/ink_note.gd")
const Shared = preload("res://experiments/playable_flightcase/career_components.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const AUDITION_ROLES := ["Guitarist","Bassist","Drummer","Singer"]
const AUDITION_TITLES := ["GUITARISTS","BASSISTS","DRUMMERS","LEAD VOCALS"]
static var audition_heading_texture: ImageTexture
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
var game = Game.new()
var onboarding_state = null
var opening_owner = null
var role: String = "Guitarist"
var selected_index := 0
var auditioned: Dictionary = {}
var audition_note_id := ""
var vocals_panel := false
var lineup_review := false
var _new_session_notes := false
var idea_index := 0
var form_index := 0
var leader_index := 0
var song_title := "THE LAST BUS HOME"
var last_message := "Build a band. Talent points are separate from your cash."
var recap_expanded := true
var recap_details_expanded := false
var look := "flightcase"
var reduced_motion := false
var session_busy := false
var _session_overlay: Control
var _work_dialog: Control
var _work_expected: Dictionary = {}
var _work_epoch := 0
var practice_activity := "create"

# Phone-only layout wrapper around the same native Kit buttons and selection
# contract. Keep the shared horizontal ChoiceStrip unchanged in other views.
class PracticePhoneChoices extends VBoxContainer:
 signal selection_changed(index: int)
 var selected := 0
 var buttons: Array[Button] = []
 var group := ButtonGroup.new()
 func _init(style: String, labels: PackedStringArray, initial: int) -> void:
  add_theme_constant_override("separation",4)
  size_flags_horizontal = Control.SIZE_EXPAND_FILL
  group.allow_unpress = false
  for index in range(labels.size()):
   var option: Button = Kit.button(labels[index],style,"tab",true)
   option.button_group = group
   buttons.append(option)
   add_child(option)
   option.pressed.connect(select.bind(index))
  if not buttons.is_empty():
   selected = clampi(initial,0,buttons.size()-1)
   buttons[selected].set_pressed_no_signal(true)
 func select(index: int, emit: bool = true) -> void:
  if index<0 or index>=buttons.size() or buttons[index].disabled:
   return
  for current in range(buttons.size()):
   buttons[current].set_pressed_no_signal(current==index)
  if selected==index:
   return
  selected = index
  if emit:
   selection_changed.emit(index)

func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 _hydrate_song_draft()
 resized.connect(_rebuild)
 visibility_changed.connect(_on_visibility_changed)
 _rebuild()

func _clear() -> void:
 for child in get_children():
  if is_instance_valid(_session_overlay) and child==_session_overlay:
   continue
  if is_instance_valid(_work_dialog) and child==_work_dialog:
   continue
  remove_child(child)
  child.queue_free()

func _label(content: String, points: int = 16) -> Label:
 return Shared.label(content,points,look)

func _box() -> VBoxContainer:
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",8)
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return box

func _panel(body: Control, kind := "panel") -> PanelContainer:
 var panel: PanelContainer = Kit.frame(look,kind)
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_child(body)
 return panel

func _button(title: String, action: Callable, family: String = "action") -> Button:
 var button: Button = Shared.button(title,look,family)
 button.pressed.connect(action)
 return button

func _rebuild() -> void:
 if not is_inside_tree():
  return
 var previous_focus: Control = get_viewport().gui_get_focus_owner()
 var focus_name := ""
 var caret := -1
 if not session_busy and is_instance_valid(previous_focus) and is_ancestor_of(previous_focus):
  focus_name = previous_focus.name
  if previous_focus is LineEdit:
   caret = (previous_focus as LineEdit).caret_column
 _clear()
 var size_now: Vector2 = size
 var mobile: bool = size_now.x < 840 or size_now.x < size_now.y
 add_child(Shared.background())
 var outer := MarginContainer.new()
 outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","top","right","bottom"]:
  outer.add_theme_constant_override("margin_"+side,12 if mobile else 20)
 add_child(outer)
 var root_box := _box()
 root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
 outer.add_child(root_box)
 var header := HBoxContainer.new()
 header.add_theme_constant_override("separation",12)
 if game.phase=="recruit":
  var title := _label("AUDITIONS",26 if not mobile else 21)
  title.name = "AuditionsHeading"
  title.custom_minimum_size.y = 44
  _decorate_audition_heading(title)
  title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  header.add_child(title)
 else:
  # Reserve the displayed artwork's actual width, keeping the established
  # header height. The previous wider empty slot crowded short band names.
  var old_brand_height: float=52.0 if mobile else 36.0
  var brand: Control = Shared.brand(26.0 if mobile else 24.0)
  var brand_slot:=Control.new()
  brand_slot.custom_minimum_size=Vector2(brand.custom_minimum_size.x,old_brand_height)
  brand_slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
  header.add_child(brand_slot)
  brand.name = "PracticeBrand"
  brand_slot.add_child(brand)
  brand.position.y=(old_brand_height-brand.custom_minimum_size.y)*0.5
  var name_layout: Label=_label(str(game.career.get("band_name","LIVIN' THE DREAM")),18)
  name_layout.name="PracticeBandNameLayout"
  name_layout.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  name_layout.max_lines_visible=2
  header.add_child(name_layout)
  var band_name := BandMark.new()
  band_name.configure(str(game.career.get("band_name","LIVIN' THE DREAM")),str(game.career.get("logo","Wordmark")),IdentityStyle.effective(game.career.get(IdentityStyle.KEY,{}),str(game.career.get("palette",""))),28 if mobile else 23,true,true,true)
  band_name.name = "PracticeBandName"
  band_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  band_name.max_lines_visible = 1
  name_layout.add_child(band_name)
  band_name.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  name_layout.self_modulate.a=0.0
 var visible_remaining: int = int(onboarding_state.remaining()) if onboarding_state != null else game.remaining()
 var budget := _label("TALENT %d / %d" % [visible_remaining,Base.MAX_TALENT] if game.phase=="recruit" else "DAY %d   £%d" % [int(game.career.get("tour_day",1)),int(game.career.get("cash",0))],16)
 budget.name = "BudgetLabel"
 budget.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 header.add_child(budget)
 root_box.add_child(header)
 var display_message := last_message
 if game.phase=="play" and display_message=="Build a band. Talent points are separate from your cash.":
  var saved_report: Dictionary = game.career.get("last_rehearsal_outcome",{})
  if not saved_report.is_empty():
   display_message = "LAST SESSION  •  " + str(saved_report.get("verdict","Session completed")) + "  •  Notes below."
  else:
   display_message = "Your band is ready. Choose a session."
 if game.phase=="recruit" and display_message=="Build a band. Talent points are separate from your cash.":
  display_message = "Meet the musicians. Auditions cost no time or talent."
 if game.phase=="play" and opening_owner!=null and int(game.career.get("cash",0))==0:
  var account: Dictionary = Finance.view(game.career)
  display_message = "NO CASH  •  %d / 14 completed days  •  Check Finances in the Career Desk" % int(account.get("broke_days",0))
 var status := _label(display_message,14)
 status.name = "StatusMessage"
 status.custom_minimum_size.y = 32
 status.add_theme_color_override("font_color",Color("f0c78b"))
 root_box.add_child(status)
 if game.phase == "recruit":
  _recruit_page(root_box,mobile)
 else:
  _practice_page(root_box,mobile)
 if is_instance_valid(_session_overlay):
  move_child(_session_overlay,get_child_count()-1)
 elif not focus_name.is_empty():
  call_deferred("_restore_practice_focus",focus_name,caret)

func _restore_practice_focus(control_name: String, caret: int = -1) -> void:
 if session_busy or not is_visible_in_tree():
  return
 var control: Control = find_child(control_name,true,false) as Control
 if control!=null and control.is_visible_in_tree():
  control.grab_focus()
  if control is LineEdit and caret>=0:
   (control as LineEdit).caret_column = mini(caret,(control as LineEdit).text.length())

func _hydrate_song_draft() -> void:
 if game.phase!="play":
  return
 var draft: Dictionary = game.career.get("current_song_draft",{})
 if draft.is_empty():
  if not (game.career.get("song_catalogue",[]) as Array).is_empty():
   song_title = ""
  return
 song_title = str(draft.get("title",song_title))
 idea_index = maxi(0,Workshop.IDEAS.find(str(draft.get("idea",Workshop.IDEAS[0]))))
 form_index = maxi(0,Workshop.FORMS.find(str(draft.get("form",Workshop.FORMS[0]))))
 var members: Array = game.career.get("members",[])
 leader_index = 0
 for index in range(members.size()):
  if str(members[index].get("name",""))==str(draft.get("leader","")):
   leader_index = index
   break
 leader_index = clampi(leader_index,0,maxi(0,members.size()-1))

func _decorate_audition_heading(label: Label) -> void:
 var path := "res://experiments/playable_flightcase/art/auditions_heading.png"
 if not ResourceLoader.exists(path):
  return
 var art := TextureRect.new()
 art.name = "AuditionsHeadingInk"
 if audition_heading_texture==null:
  var source: Texture2D = load(path)
  audition_heading_texture = ImageTexture.create_from_image(source.get_image().get_region(Rect2i(27,136,2024,544)))
 art.texture = audition_heading_texture
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 art.focus_mode = Control.FOCUS_NONE
 label.add_child(art)
 art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 label.self_modulate.a = 0.0

func first_audition_candidate_index(for_role: String) -> int:
 var choices: Array = game.choices(for_role)
 for index in range(choices.size()):
  var path: String = str(choices[index].get("portrait_preview",""))
  if not path.is_empty() and ResourceLoader.exists(path):
   return index
 return 0

func first_missing_audition_role() -> String:
 var covered: Array = Base.coverage(game.roster)
 for required in ["Guitarist","Bassist","Drummer"]:
  if not covered.has(required):
   return required
 return "Singer"

func _audition_progress(root_box: VBoxContainer) -> void:
 var progress := HBoxContainer.new()
 progress.name = "AuditionProgress"
 progress.add_theme_constant_override("separation",4)
 var covered: Array = Base.coverage(game.roster)
 for index in range(4):
  var done: bool = covered.has(AUDITION_ROLES[index]) if index<3 else (onboarding_state!=null and not str(onboarding_state.lead_vocal_id).is_empty())
  var caption := _label(("✓ " if done else str(index+1)+" ")+str(["GUITAR","BASS","DRUMS","VOICE"][index]),12)
  caption.name = "AuditionProgress_"+str(AUDITION_ROLES[index])
  caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
  caption.focus_mode = Control.FOCUS_NONE
  caption.add_theme_color_override("font_color",Color("a8ddb5") if done else (Color("f0c78b") if role==str(AUDITION_ROLES[index]) else Color("b6b8b3")))
  progress.add_child(caption)
 root_box.add_child(progress)

func _audition_sheet(root_box: VBoxContainer, mobile: bool) -> VBoxContainer:
 var scroll := ScrollContainer.new()
 scroll.name = "RecruitProfileScroll"
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
 root_box.add_child(scroll)
 var margin := MarginContainer.new()
 margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for side in ["left","right","top","bottom"]:
  margin.add_theme_constant_override("margin_"+side,16)
 scroll.add_child(margin)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
 margin.add_child(center)
 var paper := PanelContainer.new()
 paper.name = "AuditionPaper"
 paper.custom_minimum_size.x = minf(1000.0,maxf(270.0,size.x-(72.0 if mobile else 120.0)))
 paper.add_theme_stylebox_override("panel",Paper.sheet(size.x<600))
 center.add_child(paper)
 var body := _box()
 body.add_theme_constant_override("separation",10)
 paper.add_child(body)
 return body

func _audition_navigation(root_box: VBoxContainer) -> void:
 var navigation := HBoxContainer.new()
 navigation.name = "AuditionNavigation"
 navigation.add_theme_constant_override("separation",8)
 root_box.add_child(navigation)
 var index: int = AUDITION_ROLES.find(role)
 var previous_title: String = "‹  CHANGE GENRE" if index==0 else "‹  "+str(AUDITION_TITLES[maxi(0,index-1)])
 if role=="Keyboardist":
  previous_title = "‹  LINEUP REVIEW"
 elif role=="Singer" and not vocals_panel:
  previous_title = "‹  VOICES"
 var previous: Button = _button(previous_title,_previous_audition,"tab")
 previous.name = "AuditionPreviousStepAction"
 navigation.add_child(previous)
 var following: Button
 if role=="Singer" or role=="Keyboardist":
  following = _button("REVIEW LINEUP  ›",_review_lineup)
  following.name = "ReviewLineupAction"
  following.disabled = not (bool(onboarding_state.ready()) if onboarding_state!=null else game.can_start())
 else:
  following = _button(str(AUDITION_TITLES[index+1])+"  ›",_next_audition)
  following.name = "AuditionNextStepAction"
  following.disabled = not Base.coverage(game.roster).has(role)
 navigation.add_child(following)

func _recruit_page(root_box: VBoxContainer, mobile: bool) -> void:
 _audition_progress(root_box)
 if lineup_review:
  _lineup_review_page(root_box,mobile)
  return
 if vocals_panel and onboarding_state!=null:
  _vocal_audition_page(root_box,mobile)
  return
 var index: int = AUDITION_ROLES.find(role)
 var chapter := _label(("0%d / 04  •  " % (index+1) if index>=0 else "OPTIONAL  •  ")+str(AUDITION_TITLES[index] if index>=0 else "KEYBOARDS"),20)
 chapter.name = "AuditionStepTitle"
 root_box.add_child(chapter)
 var choices: Array = game.choices(role)
 if choices.is_empty():
  root_box.add_child(_label("No candidates for this role."))
  _audition_navigation(root_box)
  return
 selected_index = clampi(selected_index,0,choices.size()-1)
 var person: Dictionary = choices[selected_index]
 var id: String = str(person.id)
 var recruited: bool = Base.contains(game.roster,id)
 var heard: bool = bool(auditioned.get(id,false)) or recruited
 var body: VBoxContainer = _audition_sheet(root_box,mobile)
 var browse := HBoxContainer.new()
 browse.add_theme_constant_override("separation",6)
 body.add_child(browse)
 var previous: Button = _button("‹",_move_candidate.bind(-1),"browse")
 previous.name = "RecruitPreviousAction"
 previous.custom_minimum_size.x = 48
 previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 browse.add_child(previous)
 var candidate_name: Label = _ink("%s  •  %s" % [str(person.name).to_upper(),role.to_upper()],19)
 candidate_name.name = "RecruitCandidateName"
 candidate_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 browse.add_child(candidate_name)
 var following: Button = _button("›",_move_candidate.bind(1),"browse")
 following.name = "RecruitNextAction"
 following.custom_minimum_size.x = 48
 following.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 browse.add_child(following)
 var introduction := HBoxContainer.new()
 introduction.add_theme_constant_override("separation",12)
 body.add_child(introduction)
 var image_path := str(person.get("portrait_preview",""))
 if not image_path.is_empty() and ResourceLoader.exists(image_path):
  var image := TextureRect.new()
  image.name = "RecruitPortrait"
  image.texture = load(image_path)
  image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  image.custom_minimum_size = Vector2(112,116) if mobile else Vector2(190,194)
  image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
  image.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
  image.mouse_filter = Control.MOUSE_FILTER_IGNORE
  image.focus_mode = Control.FOCUS_NONE
  introduction.add_child(image)
 else:
  var archive: Label = _ink("ARCHIVE AUDITION\nNo approved portrait",13,true)
  archive.name = "RecruitArchivePortrait"
  archive.custom_minimum_size = Vector2(112,116) if mobile else Vector2(190,194)
  introduction.add_child(archive)
 var bio := _box()
 if not mobile:
  bio.add_theme_constant_override("separation",6)
 introduction.add_child(bio)
 bio.add_child(_ink(str(person.get("town","UK")),16))
 bio.add_child(_ink(str(person.get("personality","Musician")),16,true))
 bio.add_child(_ink(str(person.get("story","An aspiring musician looking for a band.")),14))
 var stat_grid := GridContainer.new()
 stat_grid.columns = 2 if mobile else 3
 stat_grid.add_theme_constant_override("h_separation",12)
 stat_grid.add_theme_constant_override("v_separation",5)
 if mobile:
  body.add_child(stat_grid)
 else:
  bio.add_child(stat_grid)
 var stats: Array = Base.stats_for(person,role)
 var captions: Array = Base.labels_for(role)
 for i in range(6):
  var field := VBoxContainer.new()
  field.name = "RecruitStatRow"+str(i)
  field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  field.add_theme_constant_override("separation",1)
  stat_grid.add_child(field)
  field.add_child(_ink(str(captions[i]).to_upper(),13))
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",4)
  field.add_child(row)
  var meter := Kit.PassiveMeter.new(look,int(stats[i]))
  meter.name = "PassiveMeter"+str(i)
  if size.x<600:
   meter.custom_minimum_size.x = 80
  row.add_child(meter)
  var score: Label = _ink(str(int(stats[i])),14)
  score.custom_minimum_size.x = 18
  row.add_child(score)
 var strength: Label = _candidate_note("STRENGTH  •  "+str(person.get("strength","Still developing")),"RecruitStrength",heard and audition_note_id==id)
 var friction: Label = _candidate_note("FRICTION  •  "+str(person.get("friction","Unknown")),"RecruitFriction",heard and audition_note_id==id)
 strength.visible = heard
 friction.visible = heard
 var note_host: VBoxContainer = body if mobile else bio
 note_host.add_child(strength)
 note_host.add_child(friction)
 if heard:
  note_host.add_child(_ink("Audition notes • tap a note to reveal it in full.",12,true))
 else:
  note_host.add_child(_ink("Meet the musician, then audition to read what they bring to the room.",16,true))
 if person.has("collaboration"):
  note_host.add_child(_ink("RELIABILITY %d/10  •  COLLABORATION %d/10" % [int(person.reliability),int(person.collaboration)],14,true))
 if role=="Singer" and onboarding_state!=null and recruited:
  var chosen: bool = str(onboarding_state.lead_vocal_id)==id
  var appoint: Button = _button("✓ LEAD VOCALS" if chosen else "CHOOSE "+str(person.name).to_upper()+" FOR LEAD VOCALS",_choose_vocal.bind(id))
  appoint.name = "VocalAssign_"+id
  appoint.disabled = chosen
  body.add_child(appoint)
 var context := _box()
 context.name = "RecruitDecisionContext"
 context.add_theme_constant_override("separation",5)
 context.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mobile else Control.SIZE_SHRINK_CENTER
 if not mobile:
  context.custom_minimum_size.x = 760
 root_box.add_child(context)
 var available: int = int(onboarding_state.remaining()) if onboarding_state!=null else game.remaining()
 var cost: int = Base.incremental_cost(game.roster,person)
 var budget_text: String
 if recruited:
  budget_text = "IN YOUR BAND  •  %d TALENT AVAILABLE" % available
 elif game.roster.size()>=6:
  budget_text = "BAND FULL  •  6/6 MEMBERS  •  %d TALENT AVAILABLE" % available
 elif available<cost:
  budget_text = "NEED %d MORE TALENT  •  %d AVAILABLE" % [cost-available,available]
 else:
  budget_text = "%d TALENT  •  %d AVAILABLE  •  %d AFTER RECRUIT" % [cost,available,available-cost]
 var affordability: Label = _label(budget_text,16)
 affordability.name = "RecruitAffordability"
 affordability.add_theme_color_override("font_color",Color("f0c78b"))
 context.add_child(affordability)
 var dock := HBoxContainer.new()
 dock.name = "RecruitDecisionDock"
 dock.add_theme_constant_override("separation",8)
 context.add_child(dock)
 var audition: Button = _button("READ NOTES" if heard else "AUDITION",_audition_candidate)
 audition.name = "AuditionAction"
 dock.add_child(audition)
 var action: Button = _button("REMOVE" if recruited else "INVITE TO BAND",_remove.bind(id) if recruited else _recruit.bind(id))
 action.name = "RemoveAction" if recruited else "RecruitAction"
 var allowed: bool = bool(onboarding_state.can_recruit(id)) if onboarding_state!=null else Base.can_add(game.roster,person)
 action.disabled = false if recruited else (not heard or not allowed)
 if not recruited and game.roster.size()>=6:
  action.text = "BAND FULL"
 dock.add_child(action)
 audition_note_id = ""
 _audition_navigation(root_box)

func _candidate_note(value: String, node_name: String, animate: bool) -> Label:
 var note: Label = InkNote.new()
 note.name = node_name
 note.text = value
 note.add_theme_font_size_override("font_size",16)
 note.add_theme_color_override("font_color",Color("29241f"))
 note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 if animate:
  note.call_deferred("begin",reduced_motion)
 return note

func _audition_candidate() -> void:
 var items: Array = game.choices(role)
 if items.is_empty():
  return
 var id: String = str(items[selected_index].id)
 auditioned[id] = true
 audition_note_id = id
 _rebuild()
 call_deferred("_reveal_audition_note")

func _reveal_audition_note() -> void:
 # Full note text is shaped before revealing. Wait for the native containers
 # to settle before requesting the existing scroll control to reveal it.
 await get_tree().process_frame
 if not is_inside_tree():
  return
 await get_tree().process_frame
 if not is_inside_tree():
  return
 var scroll: ScrollContainer = find_child("RecruitProfileScroll",true,false) as ScrollContainer
 var note: Control = find_child("RecruitStrength",true,false) as Control
 if scroll!=null and note!=null:
  scroll.ensure_control_visible(note)

func _next_audition() -> void:
 var index: int = AUDITION_ROLES.find(role)
 if index<0 or index>=3 or not Base.coverage(game.roster).has(role):
  return
 _change_role(str(AUDITION_ROLES[index+1]))

func _previous_audition() -> void:
 if role=="Keyboardist":
  _review_lineup()
 elif role=="Singer" and not vocals_panel:
  _show_vocal_choices()
 else:
  var index: int = AUDITION_ROLES.find(role)
  if index<=0:
   back_requested.emit()
  else:
   _change_role(str(AUDITION_ROLES[index-1]))

func _vocal_audition_page(root_box: VBoxContainer, mobile: bool) -> void:
 root_box.add_child(_label("04 / 04  •  WHO TAKES THE MIC?",20))
 var body: VBoxContainer = _audition_sheet(root_box,mobile)
 body.add_child(_ink("YOUR BAND'S VOICES",24))
 body.add_child(_ink("Choose a bandmate to sing, or audition a separate singer. Instrumentalists add 5 talent; a singer's vocals are included.",16,true))
 for member in game.roster:
  var scores: Array = onboarding_state.vocal_scores(member)
  if scores.size()!=6:
   continue
  var chosen: bool = str(onboarding_state.lead_vocal_id)==str(member.id)
  var extra: int = 0 if (member.roles as Array).has("Singer") else 5
  body.add_child(_ink(str(member.name).to_upper()+"  /  "+str(member.get("primary_role","Musician")).to_upper(),20))
  var score_text := PackedStringArray()
  var names: Array = Base.labels_for("Singer")
  for index in range(6):
   score_text.append(str(names[index])+" "+str(int(scores[index])))
  body.add_child(_ink("  •  ".join(score_text),14,true))
  var assign: Button = _button(("✓ " if chosen else "")+str(member.name)+("  +5 TALENT" if extra else "  VOCALS INCLUDED"),_choose_vocal.bind(str(member.id)))
  assign.name = "VocalAssign_"+str(member.id)
  assign.disabled = chosen or game.remaining()<extra
  body.add_child(assign)
 var separate: Button = _button("AUDITION A SEPARATE SINGER  ›",_show_singer_auditions)
 separate.name = "AuditionSeparateSingerAction"
 body.add_child(separate)
 body.add_child(_ink("A separate singer is optional. Your chosen voice is saved only when you select a person.",14,true))
 _audition_navigation(root_box)

func _show_singer_auditions() -> void:
 role = "Singer"
 selected_index = first_audition_candidate_index(role)
 vocals_panel = false
 lineup_review = false
 audition_note_id = ""
 _rebuild()

func _show_vocal_choices() -> void:
 role = "Singer"
 vocals_panel = true
 lineup_review = false
 audition_note_id = ""
 _rebuild()

func _review_lineup() -> void:
 lineup_review = true
 audition_note_id = ""
 _rebuild()

func _lineup_review_page(root_box: VBoxContainer, mobile: bool) -> void:
 root_box.add_child(_label("LINEUP REVIEW",20))
 var body: VBoxContainer = _audition_sheet(root_box,mobile)
 body.add_child(_ink("THIS IS YOUR BAND",24))
 var roster := GridContainer.new()
 roster.columns = 1 if mobile else mini(3,maxi(1,game.roster.size()))
 roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 roster.add_theme_constant_override("h_separation",20)
 roster.add_theme_constant_override("v_separation",10)
 body.add_child(roster)
 for member in game.roster:
  var row: BoxContainer = HBoxContainer.new() if mobile else VBoxContainer.new()
  row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.name = "LineupReviewMember_"+str(member.id)
  row.add_theme_constant_override("separation",8)
  roster.add_child(row)
  var path: String = str(member.get("portrait_preview",""))
  if not path.is_empty() and ResourceLoader.exists(path):
   var portrait := TextureRect.new()
   portrait.name = "LineupReviewPortrait_"+str(member.id)
   portrait.texture = load(path)
   portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   portrait.custom_minimum_size = Vector2(70,73) if mobile else Vector2(96,100)
   portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
   if not mobile:
    portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
   portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
   portrait.focus_mode = Control.FOCUS_NONE
   row.add_child(portrait)
  var identity := _box()
  identity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  identity.add_theme_constant_override("separation",2)
  row.add_child(identity)
  var member_name: Label = _ink(str(member.name),18)
  var member_role: Label = _ink(str(member.get("primary_role","Musician")),14,true)
  if not mobile:
   member_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   member_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  identity.add_child(member_name)
  identity.add_child(member_role)
  if onboarding_state!=null and str(onboarding_state.lead_vocal_id)==str(member.id):
   var lead := _ink("LEAD VOCALS",13)
   if not mobile:
    lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   lead.add_theme_color_override("font_color",Color("376c58"))
   identity.add_child(lead)
  var edit: Button = _button("EDIT",_edit_audition_member.bind(str(member.id)),"tab")
  edit.name = "AuditionEdit_"+str(member.id)
  edit.custom_minimum_size.x = 64
  edit.size_flags_horizontal = Control.SIZE_SHRINK_END if mobile else Control.SIZE_SHRINK_CENTER
  edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  row.add_child(edit)
 var voice: Button = _button("REVISIT LEAD VOCALS",_show_vocal_choices,"tab")
 voice.name = "AuditionEdit_Singer"
 body.add_child(voice)
 var keys: Button = _button("OPTIONAL KEYBOARD AUDITIONS  ›",_change_role.bind("Keyboardist"),"tab")
 keys.name = "AuditionKeysAction"
 body.add_child(keys)
 body.add_child(_ink("Nothing is final until you confirm. Edit any player or change the lead voice; unused talent remains talent.",14,true))
 var context := _box()
 context.name = "RecruitDecisionContext"
 root_box.add_child(context)
 var remaining: int = int(onboarding_state.remaining()) if onboarding_state!=null else game.remaining()
 var budget: Label = _label("%d TALENT AVAILABLE  •  %d/6 MEMBERS" % [remaining,game.roster.size()],16)
 budget.name = "RecruitAffordability"
 context.add_child(budget)
 var dock := HBoxContainer.new()
 dock.name = "RecruitDecisionDock"
 dock.add_theme_constant_override("separation",8)
 context.add_child(dock)
 var back: Button = _button("‹  VOCALS",_show_vocal_choices,"tab")
 back.name = "AuditionPreviousStepAction"
 dock.add_child(back)
 var confirm: Button = _button("CONFIRM THIS LINEUP  ›",_launch)
 confirm.name = "StartAction"
 confirm.disabled = not (bool(onboarding_state.ready()) if onboarding_state!=null else game.can_start())
 dock.add_child(confirm)



func _edit_audition_member(id: String) -> void:
 var member: Dictionary = game.person_by_id(id)
 if member.is_empty():
  return
 role = str(member.get("primary_role",(member.get("roles",["Guitarist"]) as Array)[0]))
 vocals_panel = false
 lineup_review = false
 audition_note_id = ""
 selected_index = 0
 var choices: Array = game.choices(role)
 for index in range(choices.size()):
  if str(choices[index].id)==id:
   selected_index = index
   break
 _rebuild()

func _ink(content: String, points: int = 16, muted: bool = false) -> Label:
 var label: Label = Shared.paper_label(content,points,muted)
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return label

func _select_practice_activity(kind: String) -> void:
 if session_busy or kind not in ["create","tighten","connect"]:
  return
 practice_activity = kind
 _rebuild()
 call_deferred("_restore_practice_focus","PracticeMode_"+kind)

func _practice_back() -> void:
 if not session_busy:
  back_requested.emit()

func _practice_page(root_box: VBoxContainer, mobile: bool) -> void:
 var viewport_width: float = size.x
 var phone: bool = viewport_width<600
 var stacked: bool = mobile or viewport_width<1000
 var saved_report: Dictionary = game.career.get("last_rehearsal_outcome",{})
 if not saved_report.is_empty() and recap_expanded:
  _rehearsal_result_page(root_box,mobile,saved_report)
  return
 var mode_index: int = ["create","tighten","connect"].find(practice_activity)
 var modes := Kit.ChoiceStrip.new(look,PackedStringArray(["WRITE","REHEARSE","CLEAR AIR"]),maxi(0,mode_index))
 modes.name = "PracticeActivityChoices"
 for index in range(3):
  modes.buttons[index].name = "PracticeMode_"+str(["create","tighten","connect"][index])
  modes.buttons[index].tooltip_text = "Preview this session. Time and money are spent only when you start."
 modes.selection_changed.connect(func(index: int): _select_practice_activity(str(["create","tighten","connect"][index])))
 root_box.add_child(modes)
 var scroll := ScrollContainer.new()
 scroll.name = "PracticeScroll"
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
 root_box.add_child(scroll)
 var outside := MarginContainer.new()
 outside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for side in ["left","right","top","bottom"]:
  outside.add_theme_constant_override("margin_"+side,16)
 scroll.add_child(outside)
 var content: BoxContainer = _box() if stacked else HBoxContainer.new()
 content.add_theme_constant_override("separation",18)
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 outside.add_child(content)
 var holder := CenterContainer.new()
 holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
 content.add_child(holder)
 var paper := PanelContainer.new()
 paper.name = "PracticeFrame"
 paper.custom_minimum_size.x = minf(780.0,maxf(270.0,viewport_width-(56.0 if mobile else 480.0)))
 paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 paper.add_theme_stylebox_override("panel",Paper.sheet(phone))
 holder.add_child(paper)
 var body := VBoxContainer.new()
 body.add_theme_constant_override("separation",4)
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 paper.add_child(body)
 if practice_activity=="create":
  _writing_workspace(body)
 else:
  _rehearsal_workspace(body,practice_activity)
 var info := _box()
 info.custom_minimum_size.x = 0 if stacked else 300
 content.add_child(_panel(info))
 if practice_activity=="create":
  _writing_notes(info)
 info.add_child(_label("THE BAND",19))
 for person in game.career.get("members",[]):
  info.add_child(_label("%s  •  %s   morale %d" % [str(person.get("name","")),str(person.get("role","")),int(person.get("morale",0))],16))
 info.add_child(_label("YOUR ORIGINALS",18))
 if game.career.get("song_catalogue",[]).is_empty():
  info.add_child(_label("No finished originals yet. Three writing sessions will complete your first song.",16))
 else:
  for song in game.career.get("song_catalogue",[]):
   info.add_child(_label("%s  •  quality %d\nWritten by %s  •  %s" % [str(song.get("title","UNTITLED")),int(song.get("quality",0)),str(song.get("lead_writer","the band")),str(song.get("arrangement",""))],16))
 if not saved_report.is_empty():
  var reopen: Button = _button("VIEW LAST SESSION  ›",_toggle_recap,"tab")
  reopen.name = "ReopenSessionAction"
  info.add_child(reopen)
 var booking: Dictionary = Calendar.pending(game.career)
 info.add_child(_label("NEXT GOAL: finish an original and prepare the live set. Find the hometown promoter at the career desk." if booking.is_empty() else ("NEXT SHOW: %s  •  DAY %d" % [str(booking.get("venue","The venue")),int(booking.get("day",0))]),14))
 if opening_owner==null:
  info.add_child(_button("SAVE PROGRESS",_save,"tab"))
  info.add_child(_button("LOAD SAVED PROGRESS",_load,"tab"))
 var dock := VBoxContainer.new()
 dock.name = "PracticeDecisionDock"
 dock.add_theme_constant_override("separation",5)
 dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mobile else Control.SIZE_SHRINK_CENTER
 dock.custom_minimum_size.x = minf(900.0,maxf(280.0,viewport_width-(24.0 if mobile else 40.0)))
 root_box.add_child(dock)
 var summary: Label = _label("",16)
 summary.name = "PracticeCommitment"
 dock.add_child(summary)
 var cost: Label = _label("",16)
 cost.name = "PracticeTimeCost"
 cost.add_theme_color_override("font_color",Color("f0c78b"))
 dock.add_child(cost)
 var action: Button
 if practice_activity=="create":
  action = _button("WRITE SESSION",_write)
  action.name = "WriteAction"
 elif practice_activity=="tighten":
  action = _button("START REHEARSAL  •  £15",_rehearse)
  action.name = "RehearseAction"
 else:
  action = _button("CLEAR THE AIR",_connect)
  action.name = "ClearAirAction"
 dock.add_child(action)
 if opening_owner!=null:
  var navigation := HBoxContainer.new()
  navigation.add_theme_constant_override("separation",8)
  dock.add_child(navigation)
  var back: Button = _button("BACK TO MENU",_practice_back,"tab")
  back.name = "PracticeBackAction"
  navigation.add_child(back)
  var career: Button = _button("CAREER DESK  ›",_open_career,"tab")
  career.name = "CareerDeskAction"
  navigation.add_child(career)
 _refresh_practice_commitment()

func _open_career() -> void:
 if not session_busy:
  career_requested.emit()

func _writing_notes(info: VBoxContainer) -> void:
 var progress: int = clampi(int(game.career.get("song_draft_progress",0)),0,2)
 var guidance: Label = _label(str([
  "IDEA: Find the hook and choose the musician to lead it.",
  "DEVELOP: Shape the arrangement. Review the saved session below.",
  "FINISH: Check title, leader and arrangement before completing the original."
 ][progress]),16)
 guidance.name = "WritingStageGuidance"
 info.add_child(guidance)
 info.add_child(_label("SAVED WRITING NOTES",18))
 var draft: Dictionary = game.career.get("current_song_draft",{})
 var sessions: Array = draft.get("sessions",[])
 var lines := PackedStringArray()
 if sessions.is_empty():
  lines.append("No writing sessions recorded yet. Three sessions complete one original.")
 else:
  lines.append("Saved draft: "+str(draft.get("title","UNTITLED")))
  for session in sessions:
   lines.append("DAY %d  •  %s  •  %s  •  %s" % [int(session.get("day",1)),str(session.get("idea","")),str(session.get("form","")),str(session.get("leader",""))])
 var history: Label = _label("\n".join(lines),16)
 history.name = "WritingSavedHistoryLabel"
 info.add_child(history)
 info.add_child(_label("Notes describe saved sessions. The choices above apply when you commit.",14))

func _writing_workspace(body: VBoxContainer) -> void:
 var progress: int = clampi(int(game.career.get("song_draft_progress",0)),0,2)
 body.add_child(_ink("WRITE AN ORIGINAL",22))
 var stage: Label = _ink("SESSION %d OF 3  •  %s" % [progress+1,str(["IDEA","DEVELOP","FINISH"][progress])],16,true)
 stage.name = "WritingStageLabel"
 body.add_child(stage)
 var fields := GridContainer.new()
 fields.columns = 2 if size.x>=1000 else 1
 fields.add_theme_constant_override("h_separation",12)
 fields.add_theme_constant_override("v_separation",6)
 body.add_child(fields)
 var title_field: VBoxContainer = _writing_field(fields,"SONG TITLE")
 var entry := LineEdit.new()
 entry.name = "SongTitle"
 entry.text = song_title
 entry.placeholder_text = "Name your original"
 entry.max_length = 48
 entry.custom_minimum_size.y = 48
 entry.add_theme_font_size_override("font_size",17)
 entry.add_theme_stylebox_override("normal",Paper.scorecard())
 var focus_style: StyleBoxTexture = Kit.skin("notepaper","tab","focus")
 focus_style.draw_center = false
 entry.add_theme_stylebox_override("focus",focus_style)
 entry.add_theme_color_override("font_color",Color("29241f"))
 entry.add_theme_color_override("font_placeholder_color",Color("524536"))
 entry.add_theme_color_override("caret_color",Color("29241f"))
 entry.text_changed.connect(func(value: String):
  song_title = value
  _refresh_practice_commitment())
 title_field.add_child(entry)
 var validation: Label = _ink("",16)
 validation.name = "WritingValidation"
 validation.add_theme_color_override("font_color",Color("954a42"))
 validation.visible = false
 title_field.add_child(validation)
 var leader_field: VBoxContainer = _writing_field(fields,"SESSION LEADER")
 var leader_names := PackedStringArray()
 for person in game.career.get("members",[]):
  leader_names.append(str(person.get("name","Musician")))
 leader_index = clampi(leader_index,0,maxi(0,leader_names.size()-1))
 var lead := Kit.BrowseSelector.new("notepaper",leader_names)
 lead.name = "PracticeLeaderSelector"
 lead.previous.name = "PracticeLeaderPrevious"
 lead.next.name = "PracticeLeaderNext"
 lead.display.clip_text = false
 lead.selected = leader_index
 lead.call("_refresh")
 lead.selection_changed.connect(func(index: int,_item: String):
  leader_index = index
  _refresh_practice_commitment())
 leader_field.add_child(lead)
 var idea_field: VBoxContainer = _writing_field(fields,"IDEA")
 var ideas := Kit.ChoiceStrip.new("notepaper",PackedStringArray(Workshop.IDEAS),idea_index)
 ideas.name = "PracticeIdeaChoices"
 ideas.selection_changed.connect(func(index: int):
  idea_index = index
  _refresh_practice_commitment())
 idea_field.add_child(ideas)
 var arrangement_field: VBoxContainer = _writing_field(fields,"ARRANGEMENT")
 var forms := Kit.BrowseSelector.new("notepaper",PackedStringArray(Workshop.FORMS))
 forms.name = "PracticeArrangementChoices"
 forms.previous.name = "PracticeArrangementPrevious"
 forms.next.name = "PracticeArrangementNext"
 forms.display.clip_text = false
 forms.selected = form_index
 forms.call("_refresh")
 forms.selection_changed.connect(func(index: int,_item: String):
  form_index = index
  _refresh_practice_commitment())
 arrangement_field.add_child(forms)

func _writing_field(fields: GridContainer, title: String) -> VBoxContainer:
 var field := VBoxContainer.new()
 field.add_theme_constant_override("separation",4)
 field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 fields.add_child(field)
 field.add_child(_ink(title,14,true))
 return field

func _rehearsal_workspace(body: VBoxContainer, kind: String) -> void:
 var rule: Dictionary = Practice.FOCUSES[kind]
 body.add_child(_ink("TONIGHT AT REHEARSAL" if kind=="tighten" else "CLEAR THE AIR",22))
 body.add_child(_ink(str(rule.get("description","")),16,true))
 body.add_child(_ink("£15 ROOM HIRE  •  USES 1 DAY" if kind=="tighten" else "NO ROOM FEE  •  USES 1 DAY",16))
 var situation: Dictionary=Situation.inspect_rehearsal(game.career)
 if situation.ok and not situation.plan.is_empty():
  var planned: Label=_ink("AGREED REHEARSAL • DAY %d EVENING • %s" % [int(situation.plan.day),str(situation.plan_status).to_upper()],16)
  planned.name="SituationPracticePlan"
  body.add_child(planned)
 if kind=="tighten" and situation.ok and situation.conflict:
  var names: Array=[]
  for person in situation.absent:names.append(str(person.name))
  var shift: Label=_ink("EVENING WORK SHIFT • "+", ".join(names)+". Review attendance before booking the room.",16,true)
  shift.name="SituationPracticeClash"
  body.add_child(shift)
 var gap := Control.new()
 gap.custom_minimum_size.y = 8
 body.add_child(gap)
 for row in [["readiness","READINESS"],["morale","MORALE"],["tension","TENSION"]]:
  var line: Label = _ink("%s  %d%s" % [str(row[1]),int(game.career.get(str(row[0]),0))," / 100" if str(row[0])=="readiness" else ""],18)
  line.name = "PracticeCurrent_"+str(row[0])
  body.add_child(line)
 body.add_child(_ink("Results depend on the band's actual preparation, traits and relationships.",16,true))

func _refresh_practice_commitment() -> void:
 if game.phase!="play":
  return
 var summary: Label = find_child("PracticeCommitment",true,false) as Label
 var cost: Label = find_child("PracticeTimeCost",true,false) as Label
 if summary==null or cost==null:
  return
 if opening_owner!=null and Finance.is_over(game.career):
  summary.text = "THE BAND HAS FOLDED"
  cost.text = "14 completed days without money  •  Final accounts are saved"
  for control_name in ["WriteAction","RehearseAction","ClearAirAction"]:
   var final_action: Button = find_child(control_name,true,false) as Button
   if final_action!=null:
    final_action.text = "VIEW FINAL ACCOUNTS  ›"
    final_action.disabled = false
  return
 if opening_owner!=null and Live.show_day(game.career):
  summary.text = "TONIGHT'S SHOW  •  THE VENUE IS EXPECTING YOU"
  cost.text = "Open the live desk  •  No session will be started"
  for control_name in ["WriteAction","RehearseAction","ClearAirAction"]:
   var show_action: Button = find_child(control_name,true,false) as Button
   if show_action!=null:
    show_action.text = "GO TO TONIGHT'S SHOW  ›"
    show_action.disabled = false
  return
 if practice_activity=="create":
  var members: Array = game.career.get("members",[])
  var leader_name: String = str(members[leader_index].get("name","Musician")) if leader_index>=0 and leader_index<members.size() else "Choose a leader"
  summary.text = "%s  •  %s  •  %s" % [str(Workshop.IDEAS[idea_index]),str(Workshop.FORMS[form_index]),leader_name]
  var preview: Dictionary = Workshop.develop(game.career,str(Workshop.IDEAS[idea_index]),str(Workshop.FORMS[form_index]),song_title,leader_index)
  cost.text = "Uses 1 day  •  No room fee"
  var validation: Label = find_child("WritingValidation",true,false) as Label
  if validation!=null:
   var empty_title: bool = song_title.strip_edges().is_empty()
   validation.visible = not bool(preview.get("ok",false))
   validation.text = "3–48 characters" if empty_title else str(preview.get("message","Choose a title and session leader."))
   validation.add_theme_color_override("font_color",Color("695c4b") if empty_title else Color("954a42"))
  var write: Button = find_child("WriteAction",true,false) as Button
  if write!=null:
   write.text = "WRITE SESSION %d OF 3" % [clampi(int(game.career.get("song_draft_progress",0)),0,2)+1]
   write.disabled = not bool(preview.get("ok",false))
 elif practice_activity=="tighten":
  summary.text = "Readiness %d/100  •  Morale %d  •  Tension %d" % [int(game.career.get("readiness",0)),int(game.career.get("morale",0)),int(game.career.get("tension",0))]
  cost.text = "Uses 1 day  •  £15 room hire"
  var rehearse: Button = find_child("RehearseAction",true,false) as Button
  if rehearse!=null:
   rehearse.disabled = int(game.career.get("cash",0))<15
   if rehearse.disabled:
    cost.text = "Uses 1 day  •  Needs £15  •  £%d available" % int(game.career.get("cash",0))
 else:
  summary.text = "A band meeting to work on trust and tension."
  cost.text = "Uses 1 day  •  No room fee"

func _rehearsal_result_page(root_box: VBoxContainer, mobile: bool, report: Dictionary) -> void:
 var viewport_size := size
 var tall_tablet: bool = viewport_size.x>=600 and viewport_size.x<900 and viewport_size.y>viewport_size.x
 var short_landscape: bool = viewport_size.x>=900 and viewport_size.y<800
 var scroll := ScrollContainer.new()
 scroll.name = "RehearsalResultScroll"
 scroll.follow_focus = true
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root_box.add_child(scroll)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if tall_tablet:
  # Short reports sit naturally within the tablet; long expanded reports
  # still grow the scroll content and remain readable from its top.
  center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.add_child(center)
 var press: Variant = RehearsalPress.new()
 press.configure(report,game.career.get("members",[]),mobile,recap_details_expanded,tall_tablet,short_landscape,true,_new_session_notes and not reduced_motion)
 press.details_toggled.connect(_toggle_recap_details)
 press.custom_minimum_size.x = minf(850.0,maxf(270.0,size.x-(48.0 if mobile else 88.0)))
 center.add_child(press)
 var dock := VBoxContainer.new()
 dock.name = "RecapDecisionDock"
 dock.add_theme_constant_override("separation",6)
 dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mobile else Control.SIZE_SHRINK_CENTER
 dock.custom_minimum_size.x = minf(760.0,maxf(280.0,viewport_size.x-(48.0 if mobile else 88.0)))
 root_box.add_child(dock)
 # Advice is the existing pure presenter's reading of this saved result.
 # Returning to practice does not spend another day or resolve another action.
 var view: Dictionary = Recap.present(report,game.career.get("members",[]))
 var next_move: Label = _label(str(view.get("next_step","")),16)
 next_move.name = "RecapNextMove"
 next_move.mouse_filter = Control.MOUSE_FILTER_IGNORE
 next_move.focus_mode = Control.FOCUS_NONE
 dock.add_child(next_move)
 var actions := HBoxContainer.new()
 actions.add_theme_constant_override("separation",8)
 dock.add_child(actions)
 var details: Button = _button("HIDE DETAILS" if recap_details_expanded else "DETAILS",_toggle_recap_details,"tab")
 details.name = "RecapDetailsToggleAction"
 details.tooltip_text = "Show the complete session breakdown and every bandmate's full reaction."
 details.icon = RehearsalPress.JournalIcon
 # Reserve the longer expanded label so toggling disclosure cannot move the
 # focused target or its neighbouring Continue action under a pointer.
 details.custom_minimum_size.x = ceilf(details.get_theme_font("font").get_string_size("HIDE DETAILS",HORIZONTAL_ALIGNMENT_LEFT,-1,details.get_theme_font_size("font_size")).x + details.get_theme_stylebox("normal").get_minimum_size().x + details.icon.get_width() + details.get_theme_constant("h_separation"))
 actions.add_child(details)
 var footer: Button = _button("CONTINUE TO DAY %d  ›" % int(game.career.get("tour_day",1)),_toggle_recap)
 footer.name = "RecapToggleAction"
 actions.add_child(footer)

func _toggle_recap_details() -> void:
 var detail: Control = find_child("RecapDetailedBreakdown",true,false) as Control
 var action: Button = find_child("RecapDetailsToggleAction",true,false) as Button
 if detail==null or action==null:
  return
 # Disclosure only: retain the focused native control, report and scroll.
 # Rebuilding here destroys all three and can make keyboard users lose place.
 recap_details_expanded = not recap_details_expanded
 detail.visible = recap_details_expanded
 action.text = "HIDE DETAILS" if recap_details_expanded else "DETAILS"

func _toggle_recap() -> void:
 if session_busy:
  return
 _new_session_notes = false
 var leaving_result: bool = recap_expanded
 recap_expanded = not recap_expanded
 recap_details_expanded = false
 var report: Dictionary = game.career.get("last_rehearsal_outcome",{})
 _begin_session_presentation("day" if leaving_result else "report",report)

func _change_role(value: String) -> void:
 if value not in Base.ROLE_TABS:
  return
 role = value
 selected_index = first_audition_candidate_index(value)
 lineup_review = false
 vocals_panel = value=="Singer" and onboarding_state!=null
 audition_note_id = ""
 _rebuild()
func _move_candidate(delta: int) -> void:
 var items: Array = game.choices(role)
 if items.is_empty():
  return
 audition_note_id = ""
 selected_index = posmod(selected_index+delta,items.size())
 _rebuild()
func _recruit(id: String) -> void:
 if not bool(auditioned.get(id,false)):
  return
 last_message = str(onboarding_state.recruit(id)["message"] if onboarding_state != null else game.recruit(id)["message"])
 _rebuild()
func _remove(id: String) -> void:
 last_message = str(onboarding_state.remove_member(id)["message"] if onboarding_state != null else game.remove_member(id)["message"])
 _rebuild()
func _choose_vocal(id: String) -> void:
 if onboarding_state == null:
  return
 last_message = str(onboarding_state.choose_vocal(id)["message"])
 _rebuild()
func _launch() -> void:
 if onboarding_state != null:
  var result: Dictionary = onboarding_state.confirm_lineup()
  last_message = str(result.get("message",""))
  if bool(result.get("ok",false)):
   lineup_confirmed.emit()
  else:
   _rebuild()
 else:
  last_message = str(game.launch()["message"])
  _rebuild()
func _write() -> void:
 _commit_session("create")
func _outcome_line(result: Dictionary) -> String:
 if not bool(result.get("ok",false)) or not result.has("outcome"):
  return str(result.get("message",""))
 var report: Dictionary = result["outcome"]
 var metrics: Dictionary = report.get("metrics",{})
 var key := "cohesion" if str(report.get("focus",""))=="connect" else "readiness"
 var title := "cohesion" if key=="cohesion" else "set"
 var value: int = int(metrics.get(key,{}).get("delta",0))
 var tension: int = int(metrics.get("tension",{}).get("delta",0))
 return "%s. %s %s; tension %s." % [str(report.get("verdict","Session done")),title,("+" if value>0 else "")+str(value),("+" if tension>0 else "")+str(tension)]

func _rehearse() -> void:
 _commit_session("tighten")
func _connect() -> void:
 _commit_session("connect")

func _commit_session(kind: String, expected: Dictionary = {}) -> void:
 if session_busy:
  return
 if opening_owner!=null and RadioVisit.locked(game.career):
  last_message="Resume or cancel the saved radio visit before another session."
  career_requested.emit()
  return
 if opening_owner!=null and Finance.is_over(game.career):
  last_message = "The band has folded. The final accounts are retained."
  career_requested.emit()
  return
 if opening_owner!=null and Live.show_day(game.career):
  last_message = "Tonight's show comes first. No session has been started."
  career_requested.emit()
  return
 var situation: Dictionary=Situation.inspect_rehearsal(game.career)
 if not situation.ok:
  last_message=str(situation.message)
  _rebuild()
  return
 if not expected.is_empty() and game.snapshot()!=expected:
  last_message="The band changed. Review the rehearsal again."
  _rebuild()
  return
 if kind=="tighten":
  if situation.plan_status=="future":
   last_message="Your rehearsal is agreed for DAY %d EVENING. No day or room fee has been used." % int(situation.plan.day)
   _rebuild()
   return
  if situation.conflict and expected.is_empty():
   _open_work_conflict(situation)
   return
 # Set before the synchronous resolver: rapid pointer/key events cannot queue
 # another legitimate day while this committed result is being presented.
 session_busy = true
 var before_snapshot: Dictionary = game.snapshot().duplicate(true)
 var result: Dictionary
 if kind=="create":
  result = game.write_session(str(["Riff","Lyric","Groove"][idea_index]),str(["Verse / Chorus","Slow Build","Loose Jam"][form_index]),song_title,leader_index)
 elif kind=="tighten":
  result = game.rehearse_attending(situation.attendee_indices)
 else:
  result = game.clear_air()
 if not bool(result.get("ok",false)):
  last_message = _outcome_line(result)
  session_busy = false
  _rebuild()
  return
 if kind!="tighten":
  var tracked: Dictionary=Situation.after_action(before_snapshot.get("career",{}),game.career)
  if not tracked.ok:
   game.restore(before_snapshot)
   session_busy=false
   last_message=str(tracked.message)
   _rebuild()
   return
  game.career=tracked.state
 if opening_owner!=null:
  game.career = Live.after_practice(before_snapshot.get("career",{}),game.career)
  var accounted: Dictionary = Finance.apply(before_snapshot.get("career",{}),game.career,"practice:"+kind)
  if not bool(accounted.get("ok",false)):
   game.restore(before_snapshot)
   session_busy=false
   last_message=str(accounted.get("message","The accounts could not be reconciled."))
   _rebuild()
   return
  game.career=accounted["state"]
  result["state"] = game.career.duplicate(true)
  if game.career.get("last_rehearsal_outcome",{}) is Dictionary:
   result["outcome"] = game.career.get("last_rehearsal_outcome",{}).duplicate(true)
  if not bool(opening_owner.save_draft()):
   game.restore(before_snapshot)
   session_busy = false
   last_message = "The session could not be saved. Your previous band state and pending choices are retained."
   _rebuild()
   return
 last_message = _outcome_line(result)
 recap_expanded = true
 recap_details_expanded = false
 _new_session_notes = true
 if kind=="create" and int(game.career.get("song_draft_progress",0))==0:
  _hydrate_song_draft()
 _begin_session_presentation(kind,result.get("outcome",{}))

func _open_work_conflict(view: Dictionary, notice: String = "") -> void:
 if is_instance_valid(_work_dialog):return
 _work_epoch+=1
 _work_expected=game.snapshot().duplicate(true)
 session_busy=true
 var copy: Dictionary=view.duplicate(true)
 copy["notice"]=notice
 var dialog:=WorkConflict.new()
 dialog.configure(game.career,copy)
 _work_dialog=dialog
 dialog.chosen.connect(_work_choice.bind(_work_epoch))
 dialog.cancelled.connect(_work_back.bind(_work_epoch))
 add_child(dialog)

func _close_work_conflict() -> void:
 var dialog: Control=_work_dialog
 _work_dialog=null
 _work_epoch+=1
 session_busy=false
 if is_instance_valid(dialog):dialog.queue_free()

func _work_back(epoch: int) -> void:
 if epoch!=_work_epoch:return
 _close_work_conflict()
 _work_expected={}
 _rebuild()

func _work_choice(intent: String, epoch: int) -> void:
 if epoch!=_work_epoch or not is_instance_valid(_work_dialog) or not is_visible_in_tree():return
 var before: Dictionary=_work_expected.duplicate(true)
 if game.snapshot()!=before:
  _close_work_conflict()
  last_message="The band changed. Review the current rehearsal again."
  _rebuild()
  return
 if opening_owner!=null and (RadioVisit.locked(game.career) or Finance.is_over(game.career) or Live.show_day(game.career)):
  _close_work_conflict()
  career_requested.emit()
  return
 if intent=="proceed":
  _close_work_conflict()
  _commit_session("tighten",before)
  return
 if intent!="reschedule":return
 var result: Dictionary=Situation.reschedule(game.career,before.career)
 if result.get("ok",false):
  game.career=result.state.duplicate(true)
  var saved: bool=bool(opening_owner.save_draft()) if opening_owner!=null else game.save_sandbox()
  if not saved:
   game.restore(before)
   result={"ok":false,"message":"The rehearsal plan could not be saved. Your previous career and choices are retained."}
 var message: String=str(result.get("message","The rehearsal could not be planned."))
 _close_work_conflict()
 if not result.get("ok",false):
  var current: Dictionary=Situation.inspect_rehearsal(game.career)
  if current.ok:_open_work_conflict(current,message)
 else:
  _work_expected={}
  last_message=message
  _rebuild()

func _begin_session_presentation(kind: String, report: Dictionary) -> void:
 # Navigation/reopening uses the same presentation layer, with no resolver or
 # save call. Only _commit_session may perform those existing operations.
 session_busy = true
 var overlay := SessionTransition.new()
 overlay.configure(kind,report,reduced_motion,look,int(game.career.get("tour_day",1)),int(game.career.get("cash",0)))
 _session_overlay = overlay
 overlay.covered.connect(_present_saved_session)
 overlay.finished.connect(_finish_session_presentation)
 add_child(overlay)

func _present_saved_session() -> void:
 # The only state here is presentation. Rebuild from the already saved result.
 _rebuild()

func _finish_session_presentation() -> void:
 if not session_busy:
  return
 session_busy = false
 var overlay: Control = _session_overlay
 _session_overlay = null
 if is_instance_valid(overlay):
  remove_child(overlay)
  overlay.queue_free()
 if _new_session_notes:
  _new_session_notes = false
  for note in find_children("*","Label",true,false):
   if note.has_meta("fresh_action_note") and note.has_method("begin"):
    note.begin(reduced_motion)
 var next_action: Button = find_child("RecapToggleAction" if recap_expanded else "PracticeMode_"+practice_activity,true,false) as Button
 if opening_owner!=null and Finance.is_over(game.career):
  career_requested.emit()
  return
 if next_action!=null and is_visible_in_tree():
  next_action.grab_focus()

func _on_visibility_changed() -> void:
 if not is_visible_in_tree() and is_instance_valid(_work_dialog):
  _close_work_conflict()
  _work_expected={}
 if not is_visible_in_tree() and is_instance_valid(_session_overlay):
  _session_overlay.finish_now(false)

func _exit_tree() -> void:
 _work_epoch+=1
 if is_instance_valid(_work_dialog):_work_dialog.queue_free()
 _work_dialog=null
 if is_instance_valid(_session_overlay):
  _session_overlay.abort()
 session_busy = false

func _save() -> void:
 if session_busy:
  return
 var okay: bool = bool(opening_owner.save_draft()) if opening_owner != null else game.save_sandbox()
 last_message = "Sandbox saved." if okay else "Sandbox save failed."
 _rebuild()
func _load() -> void:
 if session_busy:
  return
 var okay: bool = bool(opening_owner.load_draft()) if opening_owner != null else game.load_sandbox()
 if okay and opening_owner != null:
  game = opening_owner.game
 if okay:
  recap_expanded = true
  _hydrate_song_draft()
 last_message = "Sandbox restored." if okay else "No valid sandbox save."
 _rebuild()
