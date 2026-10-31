extends Control
signal lineup_confirmed
signal back_requested
## C26 player-facing isolated scene. Existing photographic flightcase controls,
## original inert meters and genuine career rules; no flattened clickable mockup.
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Recap = preload("res://experiments/playable_flightcase/rehearsal_recap.gd")
const RehearsalPress = preload("res://experiments/playable_flightcase/rehearsal_press.gd")
const SessionTransition = preload("res://experiments/playable_flightcase/session_transition.gd")
var game = Game.new()
var onboarding_state = null
var opening_owner = null
var role: String = "Singer"
var selected_index := 2
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
 get_viewport().size_changed.connect(_rebuild)
 visibility_changed.connect(_on_visibility_changed)
 _rebuild()

func _clear() -> void:
 for child in get_children():
  if is_instance_valid(_session_overlay) and child==_session_overlay:
   continue
  remove_child(child)
  child.queue_free()

func _label(content: String, points: int = 16) -> Label:
 var label: Label = Kit.label(content,look,points)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return label

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
 var button: Button = Kit.button(title,look,family)
 button.pressed.connect(action)
 return button

func _rebuild() -> void:
 if not is_inside_tree():
  return
 _clear()
 var size_now: Vector2 = get_viewport_rect().size
 var mobile: bool = size_now.x < 840 or size_now.x < size_now.y
 var bg := TextureRect.new()
 bg.texture = load("res://components/control_atlas/art/case_surface.png")
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_SCALE
 bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bg.modulate = Color(0.52,0.57,0.61)
 add_child(bg)
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
 var title := _label("LIVIN' THE DREAM",26 if not mobile else 21)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title)
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
 var status := _label(display_message,14)
 status.name = "StatusMessage"
 status.custom_minimum_size.y = 32
 status.add_theme_color_override("font_color",Color("f0c78b"))
 root_box.add_child(status)
 if onboarding_state != null and game.phase == "recruit":
  var back := _button("‹  CHANGE GENRE",func(): back_requested.emit(),"tab")
  back.name = "RecruitBackAction"
  root_box.add_child(back)
 if game.phase == "recruit":
  _recruit_page(root_box,mobile)
 else:
  _practice_page(root_box,mobile)
 if is_instance_valid(_session_overlay):
  move_child(_session_overlay,get_child_count()-1)

func _recruit_page(root_box: VBoxContainer, mobile: bool) -> void:
 var tabs := GridContainer.new()
 tabs.columns = 3 if mobile else 5
 tabs.add_theme_constant_override("h_separation",5)
 tabs.add_theme_constant_override("v_separation",4)
 root_box.add_child(tabs)
 var covered_roles: Array = Base.coverage(game.roster)
 for name in Base.ROLE_TABS:
  var item: Button = _button(str(name).to_upper(),_change_role.bind(str(name)),"tab")
  item.name = "RoleTab_"+str(name)
  item.toggle_mode = true
  item.button_pressed = str(name)==role
  var covered: bool = covered_roles.has(name)
  if str(name)=="Singer" and onboarding_state!=null:
   covered = not str(onboarding_state.lead_vocal_id).is_empty()
  if covered:
   for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
    item.add_theme_color_override(state,Color("a8ddb5"))
   item.tooltip_text = "Covered in your lineup."
  tabs.add_child(item)
 var choices: Array = game.choices(role)
 if choices.is_empty():
  root_box.add_child(_label("No candidates for this role."))
  return
 selected_index = clampi(selected_index,0,choices.size()-1)
 var person: Dictionary = choices[selected_index]
 var scroll := ScrollContainer.new()
 scroll.name = "RecruitProfileScroll"
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
 root_box.add_child(scroll)
 var content: BoxContainer = _box() if mobile else HBoxContainer.new()
 if not mobile:
  content.add_theme_constant_override("separation",12)
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 var detail := _box()
 detail.custom_minimum_size.x = 0 if mobile else 390
 content.add_child(_panel(detail,"portrait"))
 var browse := HBoxContainer.new()
 browse.add_theme_constant_override("separation",6)
 detail.add_child(browse)
 var previous: Button = _button("‹",_move_candidate.bind(-1),"browse")
 previous.name = "RecruitPreviousAction"
 previous.custom_minimum_size.x = 48
 previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 browse.add_child(previous)
 var name := _label("%s  •  %s" % [str(person["name"]).to_upper(),role.to_upper()],19)
 name.name = "RecruitCandidateName"
 name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 browse.add_child(name)
 var following: Button = _button("›",_move_candidate.bind(1),"browse")
 following.name = "RecruitNextAction"
 following.custom_minimum_size.x = 48
 following.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 browse.add_child(following)
 # Phone decisions need the six stats as well as the authored trade-offs.
 # Use the same source art at a compact display size beside the six readouts;
 # desktop has room for the original large portrait in that arrangement.
 var phone_profile: bool = get_viewport_rect().size.x<600
 var wide_profile: bool = get_viewport_rect().size.x>=1000
 var profile: BoxContainer = HBoxContainer.new() if wide_profile or phone_profile else _box()
 profile.add_theme_constant_override("separation",8 if phone_profile else (12 if wide_profile else 8))
 profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 detail.add_child(profile)
 var image_path := str(person.get("portrait_preview",""))
 if image_path.is_empty() or not ResourceLoader.exists(image_path):
  profile.add_child(_label("ARCHIVE PROFILE  •  PORTRAIT PROVISIONAL",13))
 else:
  var image := TextureRect.new()
  image.name = "RecruitPortrait"
  image.texture = load(image_path)
  image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  image.custom_minimum_size = Vector2(80,79) if phone_profile else Vector2(210,205)
  image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
  image.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
  image.mouse_filter = Control.MOUSE_FILTER_IGNORE
  image.focus_mode = Control.FOCUS_NONE
  profile.add_child(image)
 var meter_rows := _box()
 profile.add_child(meter_rows)
 var stats: Array = Base.stats_for(person,role)
 var captions: Array = Base.labels_for(role)
 for i in range(stats.size()):
  var line := HBoxContainer.new()
  line.name = "RecruitStatRow"+str(i)
  line.add_theme_constant_override("separation",4 if phone_profile else 8)
  meter_rows.add_child(line)
  var label := _label(str(captions[i]).to_upper(),13)
  label.custom_minimum_size.x = 90
  line.add_child(label)
  var meter := Kit.PassiveMeter.new(look,int(stats[i]))
  meter.name = "PassiveMeter"+str(i)
  if phone_profile:
   meter.custom_minimum_size.x = 80
  line.add_child(meter)
  var numeric_value := _label(str(int(stats[i])),14)
  numeric_value.custom_minimum_size.x = 18 if phone_profile else 24
  line.add_child(numeric_value)
 var cost := Base.incremental_cost(game.roster,person)
 var recruited := Base.contains(game.roster,str(person["id"]))
 var action: Button = _button("REMOVE FROM BAND" if recruited else "RECRUIT  •  %d TALENT" % cost,_remove.bind(str(person["id"])) if recruited else _recruit.bind(str(person["id"])))
 action.name = "RecruitAction" if not recruited else "RemoveAction"
 action.disabled = false if recruited else not (bool(onboarding_state.can_recruit(str(person["id"]))) if onboarding_state != null else Base.can_add(game.roster,person))
 # Keep the complete original dossier and all passive meters available.
 var aside := _box()
 aside.custom_minimum_size.x = 0 if mobile else 320
 aside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_child(_panel(aside,"panel"))
 aside.add_child(_label("THE PERSON",19))
 aside.add_child(_label("%s • %s" % [str(person.get("town","UK")),str(person.get("personality","Musician"))],15))
 aside.add_child(_label(str(person.get("story","An aspiring musician looking for a band.")),14))
 aside.add_child(_label("STRENGTH • "+str(person.get("strength","Still developing")),14))
 aside.add_child(_label("FRICTION • "+str(person.get("friction","Unknown")),14))
 if person.has("collaboration"):
  aside.add_child(_label("RELIABILITY %d/10   COLLABORATION %d/10" % [int(person["reliability"]),int(person["collaboration"])],14))
 aside.add_child(_label("YOUR BAND",18))
 for member in game.roster:
  aside.add_child(_label("• %s   %s" % [str(member["name"]),str(member.get("primary_role",(member["roles"] as Array)[0]))],14))
 if onboarding_state != null:
  aside.add_child(_label("LEAD VOCALS  •  ASSIGN ONE BAND MEMBER",16))
  for member in game.roster:
   if onboarding_state.vocal_scores(member).size() == 6:
    var chosen: bool = str(onboarding_state.lead_vocal_id) == str(member["id"])
    var extra: int = 0 if (member["roles"] as Array).has("Singer") else 5
    var vocal: Button = _button(("✓  " if chosen else "") + str(member["name"]) + ("  +%d TALENT" % extra if extra > 0 else "  INCLUDED"),_choose_vocal.bind(str(member["id"])),"tab")
    vocal.name = "VocalAssign_"+str(member["id"])
    vocal.disabled = chosen
    aside.add_child(vocal)
  aside.add_child(_label("Fifth member +6, sixth +12 additional. Vocalist doubling an instrument adds 5. Talent points buy ability and options, not cash.",13))
  aside.add_child(_label("TALENT USED %d/200  •  %s" % [200-int(onboarding_state.remaining()),"READY" if bool(onboarding_state.ready()) else str(onboarding_state.missing())],14))
 else:
  aside.add_child(_label("TALENT USED %d/200  •  %s" % [game.spent(),"READY" if game.can_start() else Base.missing(game.roster)],14))
 var start: Button = _button("COMPLETE THE LINEUP" if onboarding_state != null else "START YOUR FIRST PRACTICE",_launch)
 start.name = "StartAction"
 start.disabled = not (bool(onboarding_state.ready()) if onboarding_state != null else game.can_start())
 # The actual authored trade-offs stay beside the decision, even while the
 # portrait, stats and full dossier scroll. These are metadata, not new effects.
 var context := _box()
 context.name = "RecruitDecisionContext"
 context.add_theme_constant_override("separation",4)
 context.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mobile else Control.SIZE_SHRINK_CENTER
 if not mobile:
  context.custom_minimum_size.x = 760.0
 root_box.add_child(context)
 var strength := _label("STRENGTH  •  "+str(person.get("strength","Still developing")),16)
 strength.name = "RecruitStrength"
 context.add_child(strength)
 var friction := _label("FRICTION  •  "+str(person.get("friction","Unknown")),16)
 friction.name = "RecruitFriction"
 context.add_child(friction)
 var available: int = int(onboarding_state.remaining()) if onboarding_state != null else game.remaining()
 var budget_text: String
 if recruited:
  budget_text = "IN YOUR BAND  •  %d TALENT AVAILABLE" % available
 elif game.roster.size()>=6:
  budget_text = "BAND FULL  •  6/6 MEMBERS  •  %d TALENT AVAILABLE" % available
  action.text = "BAND FULL"
  action.tooltip_text = budget_text
 elif available<cost:
  budget_text = "NEED %d MORE TALENT  •  %d AVAILABLE" % [cost-available,available]
 else:
  budget_text = "%d TALENT  •  %d AVAILABLE  •  %d AFTER RECRUIT" % [cost,available,available-cost]
 var affordability := _label(budget_text,16)
 affordability.name = "RecruitAffordability"
 affordability.add_theme_color_override("font_color",Color("f0c78b"))
 context.add_child(affordability)
 # One native action row also fits the ready phone: the budget line retains
 # exact cost while short labels leave room for the existing Complete action.
 var dock := HBoxContainer.new()
 dock.name = "RecruitDecisionDock"
 dock.add_theme_constant_override("separation",8)
 dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 context.add_child(dock)
 action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 dock.add_child(action)
 if not start.disabled:
  start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  if mobile:
   if not recruited and game.roster.size()<6:
    action.text = "RECRUIT"
   elif recruited:
    action.text = "REMOVE"
   start.text = "COMPLETE LINEUP"
  dock.add_child(start)
 else:
  # Hidden disabled actions were never parented; release their controls and
  # source-backed style resources instead of leaking one on each rebuild.
  start.free()
  var covered: Array = Base.coverage(game.roster)
  if onboarding_state!=null and str(onboarding_state.lead_vocal_id).is_empty() and game.roster.size()>=3 and covered.has("Guitarist") and covered.has("Bassist") and covered.has("Drummer"):
   var route: Button = _button("LEAD VOCALS ›",_show_vocal_choices,"tab")
   route.name = "LeadVocalRoute"
   route.tooltip_text = "Choose a bandmate for lead vocals before completing the lineup. A separate singer is optional."
   route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   if mobile:
    action.text = "REMOVE" if recruited else ("RECRUIT" if game.roster.size()<6 else "BAND FULL")
   dock.add_child(route)

func _show_vocal_choices() -> void:
 var scroll: ScrollContainer = find_child("RecruitProfileScroll",true,false) as ScrollContainer
 if scroll==null:
  return
 for member in game.roster:
  var choice: Button = find_child("VocalAssign_"+str(member["id"]),true,false) as Button
  if choice!=null and not choice.disabled:
   scroll.ensure_control_visible(choice)
   choice.grab_focus()
   return

func _practice_page(root_box: VBoxContainer, mobile: bool) -> void:
 var viewport_width: float = get_viewport_rect().size.x
 var phone: bool = viewport_width<600
 var stacked: bool = mobile or viewport_width<1000
 var saved_report: Dictionary = game.career.get("last_rehearsal_outcome",{})
 # The result is a deliberate separate physical press screen, not a long
 # report placed above the controls. The real choice stays in a fixed footer.
 if not saved_report.is_empty() and recap_expanded:
  _rehearsal_result_page(root_box,mobile,saved_report)
  return
 if not saved_report.is_empty():
  var reopen: Button = _button("VIEW LAST SESSION  ›",_toggle_recap,"tab")
  reopen.name = "RecapToggleAction"
  root_box.add_child(reopen)
 var scroll := ScrollContainer.new()
 scroll.name = "PracticeScroll"
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
 root_box.add_child(scroll)
 var content: BoxContainer = _box() if stacked else HBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if not stacked:
  content.add_theme_constant_override("separation",12)
 scroll.add_child(content)
 var actions := _box()
 actions.custom_minimum_size.x = 0 if stacked else 470
 var practice_frame := _panel(actions)
 practice_frame.name = "PracticeFrame"
 content.add_child(practice_frame)
 if opening_owner != null:
  actions.add_child(_button("‹ MENU",func(): back_requested.emit(),"tab"))
 actions.add_child(_label("FIRST PRACTICE",22))
 actions.add_child(_label("SONGS %d  •  READINESS %d/100  •  MORALE %d  •  TENSION %d" % [int(game.career.get("songs",0)),int(game.career.get("readiness",0)),int(game.career.get("morale",0)),int(game.career.get("tension",0))],14))
 actions.add_child(_label("WRITE AN ORIGINAL  •  SESSION %d OF 3" % [int(game.career.get("song_draft_progress",0))+1],18))
 actions.add_child(_label("IDEA",13))
 var idea_labels := PackedStringArray(["Riff","Lyric","Groove"])
 var ideas := Kit.ChoiceStrip.new(look,idea_labels,idea_index)
 ideas.name = "PracticeIdeaChoices"
 ideas.selection_changed.connect(func(index: int): idea_index=index)
 actions.add_child(ideas)
 actions.add_child(_label("ARRANGEMENT",13))
 var form_labels := PackedStringArray(["Verse / Chorus","Slow Build","Loose Jam"])
 var forms: Variant = PracticePhoneChoices.new(look,form_labels,form_index) if phone else Kit.ChoiceStrip.new(look,form_labels,form_index)
 forms.name = "PracticeArrangementChoices"
 forms.selection_changed.connect(func(index: int): form_index=index)
 actions.add_child(forms)
 actions.add_child(_label("SONG TITLE",13))
 var entry := LineEdit.new()
 entry.name = "SongTitle"
 entry.text = song_title
 entry.custom_minimum_size.y = 48
 entry.text_changed.connect(func(value: String): song_title=value)
 entry.add_theme_font_size_override("font_size",17)
 actions.add_child(entry)
 var leader_names := PackedStringArray()
 for p in game.career.get("members",[]):
  leader_names.append(str(p.get("name","Musician")))
 var lead := Kit.BrowseSelector.new(look,leader_names)
 lead.selected = clampi(leader_index,0,maxi(0,leader_names.size()-1))
 lead.call("_refresh")
 lead.selection_changed.connect(func(index: int,_item: String): leader_index=index)
 actions.add_child(_label("SESSION LEADER",13))
 actions.add_child(lead)
 var info := _box()
 info.custom_minimum_size.x = 0 if stacked else 350
 content.add_child(_panel(info))
 info.add_child(_label("THE BAND",19))
 for p in game.career.get("members",[]):
  info.add_child(_label("%s  •  %s   morale %d" % [str(p.get("name","")),str(p.get("role","")),int(p.get("morale",0))],14))
 info.add_child(_label("SETLIST",18))
 if game.career.get("song_catalogue",[]).is_empty():
  info.add_child(_label("No finished original songs. Write three sessions.",14))
 else:
  for song in game.career.get("song_catalogue",[]):
   info.add_child(_label("%s  •  quality %d" % [str(song.get("title","UNTITLED")),int(song.get("quality",0))],14))
 info.add_child(_label("GIG PREP: Build a complete original and rehearse. Booking isn't available in this isolated proof yet.",14))
 info.add_child(_button("SAVE SANDBOX",_save,"tab"))
 info.add_child(_button("LOAD SANDBOX",_load,"tab"))
 # The same authoritative actions stay visible while the form and band notes
 # scroll. No action is duplicated, rerouted or charged by layout changes.
 var dock := GridContainer.new()
 dock.name = "PracticeDecisionDock"
 dock.columns = 1 if phone else 3
 dock.add_theme_constant_override("h_separation",8)
 dock.add_theme_constant_override("v_separation",6)
 dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mobile else Control.SIZE_SHRINK_CENTER
 dock.custom_minimum_size.x = minf(900.0,maxf(280.0,viewport_width-(24.0 if mobile else 40.0)))
 root_box.add_child(dock)
 var write: Button = _button("WRITE SESSION  •  %d/3" % [int(game.career.get("song_draft_progress",0))+1],_write)
 write.name = "WriteAction"
 dock.add_child(write)
 var rehearse: Button = _button("REHEARSE  •  £15",_rehearse)
 rehearse.name = "RehearseAction"
 rehearse.disabled = int(game.career.get("cash",0))<15
 dock.add_child(rehearse)
 var clear_air: Button = _button("CLEAR THE AIR",_connect)
 clear_air.name = "ClearAirAction"
 dock.add_child(clear_air)


# The journal is read-only: presentation and visibility never call the
# resolver, generate a second outcome or change the saved band.
func _rehearsal_result_page(root_box: VBoxContainer, mobile: bool, report: Dictionary) -> void:
 var viewport_size := get_viewport_rect().size
 var tall_tablet: bool = viewport_size.x>=600 and viewport_size.x<900 and viewport_size.y>viewport_size.x
 var short_landscape: bool = viewport_size.x>=900 and viewport_size.y<800
 var scroll := ScrollContainer.new()
 scroll.name = "RehearsalResultScroll"
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
 press.configure(report,game.career.get("members",[]),mobile,recap_details_expanded,tall_tablet,short_landscape)
 press.details_toggled.connect(_toggle_recap_details)
 press.custom_minimum_size.x = minf(850.0,maxf(270.0,get_viewport_rect().size.x-(48.0 if mobile else 88.0)))
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
 var footer: Button = _button("BACK TO PRACTICE  ›",_toggle_recap)
 footer.name = "RecapToggleAction"
 dock.add_child(footer)

func _toggle_recap_details() -> void:
 var detail: Control = find_child("RecapDetailedBreakdown",true,false) as Control
 var action: Button = find_child("RecapDetailsToggleAction",true,false) as Button
 if detail==null or action==null:
  return
 # Disclosure only: retain the focused native control, report and scroll.
 # Rebuilding here destroys all three and can make keyboard users lose place.
 recap_details_expanded = not recap_details_expanded
 detail.visible = recap_details_expanded
 action.text = "HIDE FULL BREAKDOWN" if recap_details_expanded else "FULL BREAKDOWN  ›"

func _toggle_recap() -> void:
 if session_busy:
  return
 recap_expanded = not recap_expanded
 recap_details_expanded = false
 _rebuild()

func _change_role(value: String) -> void:
 role = value
 selected_index = 0
 _rebuild()
func _move_candidate(delta: int) -> void:
 var items: Array = game.choices(role)
 selected_index = posmod(selected_index+delta,items.size())
 _rebuild()
func _recruit(id: String) -> void:
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

func _commit_session(kind: String) -> void:
 if session_busy:
  return
 # Set before the synchronous resolver: rapid pointer/key events cannot queue
 # another legitimate day while this committed result is being presented.
 session_busy = true
 var result: Dictionary
 if kind=="create":
  result = game.write_session(str(["Riff","Lyric","Groove"][idea_index]),str(["Verse / Chorus","Slow Build","Loose Jam"][form_index]),song_title,leader_index)
 elif kind=="tighten":
  result = game.rehearse()
 else:
  result = game.clear_air()
 last_message = _outcome_line(result)
 if not bool(result.get("ok",false)):
  session_busy = false
  _rebuild()
  return
 recap_expanded = true
 recap_details_expanded = false
 if opening_owner != null:
  opening_owner.save_draft()
 var overlay := SessionTransition.new()
 overlay.configure(kind,result.get("outcome",{}),reduced_motion,look)
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
 var next_action: Button = find_child("RecapToggleAction",true,false) as Button
 if next_action!=null and is_visible_in_tree():
  next_action.grab_focus()

func _on_visibility_changed() -> void:
 if not is_visible_in_tree() and is_instance_valid(_session_overlay):
  _session_overlay.finish_now()

func _exit_tree() -> void:
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
 last_message = "Sandbox restored." if okay else "No valid sandbox save."
 _rebuild()
