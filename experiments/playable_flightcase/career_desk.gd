extends Control
## Existing career systems, current band, shared presentation and ONE owner save.
## Browsing/inspection never dispatches a model or writes a file.
signal practice_requested(activity: String)
signal menu_requested
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Bridge = preload("res://experiments/playable_flightcase/career_bridge.gd")
const Beat = preload("res://experiments/playable_flightcase/career_beat.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Gear = preload("res://experiments/playable_flightcase/gear_catalog.gd")
const Songs = preload("res://Scripts/songbook_presentation.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const LiveRules = preload("res://experiments/playable_flightcase/live_bridge.gd")
const LiveDesk = preload("res://experiments/playable_flightcase/live_desk.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const LiveBrief = preload("res://Scripts/live_night_briefing.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const FinanceDesk = preload("res://experiments/playable_flightcase/finance_desk.gd")
const Offstage = preload("res://experiments/playable_flightcase/offstage_rules.gd")
const OffstageDesk = preload("res://experiments/playable_flightcase/offstage_desk.gd")
const ShowFlow = preload("res://experiments/playable_flightcase/show_flow.gd")
const ShowDesk = preload("res://experiments/playable_flightcase/show_desk.gd")
const ShowReplay = preload("res://experiments/playable_flightcase/show_replay.gd")
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const BookingDesk = preload("res://experiments/playable_flightcase/gig_booking_desk.gd")
const Journey = preload("res://experiments/playable_flightcase/gig_journey.gd")
const JourneyDesk = preload("res://experiments/playable_flightcase/gig_journey_desk.gd")
const RecordingDesk = preload("res://experiments/playable_flightcase/recording_desk.gd")
const RadioVisit = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const RadioDesk = preload("res://experiments/playable_flightcase/radio_visit_desk.gd")
const CalendarDesk = preload("res://experiments/playable_flightcase/calendar_desk.gd")
const IdentityStyle = preload("res://experiments/playable_flightcase/identity_style.gd")
const BandMark = preload("res://experiments/playable_flightcase/band_mark.gd")
const BandPoster = preload("res://experiments/playable_flightcase/band_poster_view.gd")
const Launcher = preload("res://experiments/playable_flightcase/career_launcher.gd")
const GearPress = preload("res://experiments/playable_flightcase/gear_press.gd")
const Direction = preload("res://experiments/playable_flightcase/career_direction.gd")
const DirectionCard = preload("res://experiments/playable_flightcase/direction_card.gd")
const GoalFocus = preload("res://experiments/playable_flightcase/goal_focus_rules.gd")
const BandMoment = preload("res://experiments/playable_flightcase/band_moment_desk.gd")
const Situation = preload("res://experiments/playable_flightcase/situation_core.gd")
const SituationDesk = preload("res://experiments/playable_flightcase/situation_desk.gd")
var game
var situation_member_id := ""
var situation_kind := "unknown"
var situation_expected: Dictionary = {}
var band_moment_context: Dictionary = {}
var band_moment_phase := "intro"
var band_moment_epoch := 0
var _focus_picker_open := false
var _focus_draft := ""
var _focus_expected: Dictionary = {}
var _focus_picker_epoch := 0
var _focus_owner_id := 0
var _focus_return_page := "home"
var _focus_return_receipt := false
var opening_owner
var reduced_motion := false
var page := "home"
var selected_item := "amp"
var catalogue_open := false
var busy := false
var notice := ""
var receipt: Dictionary = {}
var receipt_open := false
var _fresh_receipt := false
var _overlay: Control
var _scroll: ScrollContainer
var _pending_focus := ""
var _scroll_position := 0
var _render_generation := 0
var live_offer := "standard"
var live_approach := "tight"
var live_hire_session := false
var live_context_id := ""
var _live_dialog: Control
var _band_poster_id := 0
var _live_confirm_verb := ""
var _live_confirm_id := ""
var _live_confirm_phase := ""
var show_draft: Dictionary = {}
var show_context_id := ""
var _show_step_epoch := 0
var _journey_fresh := false
var booking_draft: Dictionary={}
var booking_expected: Dictionary={}
var booking_origin: Dictionary={}
var booking_step := "rooms"
var offstage_activity := "watch_gig"
var offstage_mode := "outing"
var offstage_choice := "careful"
var recording_ids: Array = []
var recording_mode := "select"
var promotion_selection: Dictionary = {}
var show_receipt_details_open := false
var goal_notice := ""

func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 resized.connect(_render)
 visibility_changed.connect(_visibility_changed)
 _render()

func open_home() -> void:
 if busy or is_instance_valid(_live_dialog):
  return
 _focus_picker_open=false
 _focus_picker_epoch+=1
 page = "finance" if Finance.is_over(game.career) else "home"
 if not Finance.is_over(game.career) and RadioVisit.locked(game.career):
  page="recording"
  recording_mode="visit"
 receipt_open = false
 goal_notice = ""
 catalogue_open = false
 notice = ""
 _scroll_position = 0
 if is_instance_valid(_scroll):
  _scroll.scroll_vertical = 0
 show()
 _render()

func _visibility_changed() -> void:
 if not is_visible_in_tree():
  _show_step_epoch+=1
  if is_instance_valid(_overlay):
   _overlay.abort()
   _overlay.queue_free()
  _overlay = null
  busy = false
  _fresh_receipt = false
  if is_instance_valid(_live_dialog):
   _live_dialog.queue_free()
  _live_dialog = null

func _exit_tree() -> void:
 if is_instance_valid(_overlay):
  _overlay.abort()
 busy = false

func _box(gap: int = 8) -> VBoxContainer:
 var result := VBoxContainer.new()
 result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 result.add_theme_constant_override("separation",gap)
 return result

func _button(text: String, name: String, action: Callable, primary: bool = false) -> Button:
 var result: Button = C.button(text,"flightcase","action" if primary else "tab")
 result.name = name
 # Preserve native taps while allowing a parent ScrollContainer to cancel
 # a button press when the same finger becomes a vertical drag.
 result.mouse_filter = Control.MOUSE_FILTER_PASS
 result.disabled = busy
 result.pressed.connect(action)
 return result

func _paper(parent: Node, compact: bool) -> VBoxContainer:
 var panel := PanelContainer.new()
 # The paper is decorative; stopping here hides touch drags from the scroll.
 panel.mouse_filter = Control.MOUSE_FILTER_PASS
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_theme_stylebox_override("panel",C.sheet(compact))
 parent.add_child(panel)
 var body := _box(8)
 panel.add_child(body)
 return body

func _copy(parent: Node, value: String, points: int = 16, muted: bool = false) -> Label:
 var result: Label = C.paper_label(value,points,muted)
 result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(result)
 return result

func _render() -> void:
 if not is_inside_tree():
  return
 if game!=null and Finance.is_over(game.career):
  page = "finance"
  receipt_open = false
 elif game!=null and RadioVisit.locked(game.career):
  page="recording"
  recording_mode="visit"
  receipt_open=false
 elif game!=null and (Journey.locked(game.career) or (Booking.modern(game.career) and LiveRules.show_day(game.career))) and page not in ["calendar","finance","band","songs"]:
  page="gigs"
  receipt_open=false
 _render_generation += 1
 var focus: Control = get_viewport().gui_get_focus_owner()
 if not busy and not is_instance_valid(_live_dialog) and is_instance_valid(focus) and is_ancestor_of(focus) and _pending_focus.is_empty():
  _pending_focus = str(focus.name)
 if is_instance_valid(_scroll):
  _scroll_position = _scroll.scroll_vertical
 for child in get_children():
  if is_instance_valid(_overlay) and child==_overlay:
   continue
  if is_instance_valid(_live_dialog) and child==_live_dialog:
   continue
  remove_child(child)
  child.queue_free()
 add_child(C.background())
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 var compact: bool = size.x<840 or size.x<size.y
 for side in ["left","top","right","bottom"]:
  margin.add_theme_constant_override("margin_"+side,12 if compact else 20)
 add_child(margin)
 var shell := _box(8)
 shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
 margin.add_child(shell)
 if game==null or opening_owner==null:
  shell.add_child(C.label("Open a saved band to use the career desk.",20))
  return
 _header(shell)
 var nav := HBoxContainer.new()
 nav.name = "CareerNavigation"
 nav.add_theme_constant_override("separation",5)
 nav.visible = page!="home" and page!="band_moment" and not (page=="gigs" and ShowFlow.managed(game.career) and not receipt_open) and not (page=="recording" and RadioVisit.locked(game.career))
 shell.add_child(nav)
 for entry in [["home","DESK"],["gear","SHOP"],["band","BAND"],["songs","SONGS"]]:
  var destination: String = str(entry[0])
  var option: Button = C.button(str(entry[1]),"flightcase","tab",true)
  option.name = "CareerNav_"+destination
  option.set_pressed_no_signal((page==destination or (page=="recording" and destination=="songs") or (page=="calendar" and destination=="home")) and not receipt_open)
  option.disabled = busy or Finance.is_over(game.career) or RadioVisit.locked(game.career)
  option.pressed.connect(_navigate.bind(destination))
  nav.add_child(option)
 var journey: bool=page=="gigs" and not receipt_open and JourneyDesk.active(self)
 var soundcheck: bool = page=="gigs" and not receipt_open and ShowFlow.managed(game.career) and ShowFlow.phase(game.career)=="soundcheck" and (not journey or str(Journey.active(game.career).get("phase",""))=="soundcheck")
 var content: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
 content.size_flags_vertical = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",12)
 shell.add_child(content)
 if soundcheck and not journey:
  ShowDesk.controls(self,content,compact)
 _scroll = ScrollContainer.new()
 _scroll.name = "CareerScroll"
 _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.follow_focus = true
 _scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
 _scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 _scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_child(_scroll)
 var inset := MarginContainer.new()
 inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for side in ["left","right","top","bottom"]:
  inset.add_theme_constant_override("margin_"+side,14)
 _scroll.add_child(inset)
 var body := _box(12)
 inset.add_child(body)
 if receipt_open and not receipt.is_empty():
  _receipt_page(body,compact)
 elif page=="gear":
  _gear_page(body,compact)
 elif page=="band":
  _band_page(body,compact)
 elif page=="band_moment":
  BandMoment.render(self,body,compact)
 elif page=="situation":
  SituationDesk.render(self,body,compact)
 elif page=="songs":
  _songs_page(body,compact)
 elif page=="recording":
  RecordingDesk.render(self,body,compact)
 elif page=="goal_focus":
  DirectionCard.chooser(self,body,compact)
 elif page=="calendar":
  CalendarDesk.render(self,body,compact)
 elif page=="gigs":
  if journey:JourneyDesk.render(self,body,compact)
  elif BookingDesk.active(self):BookingDesk.render(self,body,compact)
  else:LiveDesk.render(self,body,compact)
 elif page=="finance":
  FinanceDesk.render(self,body,compact)
 elif page=="offstage":
  OffstageDesk.render(self,body,compact)
 else:
  _home_page(body,compact)
 _decision_dock(shell,compact)
 if page=="gigs" and not receipt_open:
  LiveDesk.refresh_plans(self)
 elif page=="offstage" and not receipt_open:
  OffstageDesk.refresh_plans(self)
 _scroll.set_deferred("scroll_vertical",_scroll_position)
 if is_instance_valid(_live_dialog):
  move_child(_live_dialog,get_child_count()-1)
 elif is_instance_valid(_overlay):
  move_child(_overlay,get_child_count()-1)
 elif not busy and is_visible_in_tree() and not _pending_focus.is_empty():
  if page=="gigs" and not receipt_open and JourneyDesk.active(self):call_deferred("_journey_restore_focus",_pending_focus,_render_generation)
  else:call_deferred("_restore_focus",_pending_focus)

func _header(parent: Node) -> void:
 var row := HBoxContainer.new()
 row.custom_minimum_size.y=70.0 if size.y<800 and size.x>size.y else 80.0
 row.add_theme_constant_override("separation",12)
 parent.add_child(row)
 row.add_child(C.brand(38.0 if size.y<800 and size.x>size.y else 44.0))
 var words := _box(2)
 words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(words)
 var name_label := BandMark.new()
 name_label.configure(str(game.career.get("band_name","YOUR BAND")),str(game.career.get("logo","Wordmark")),IdentityStyle.effective(game.career.get(IdentityStyle.KEY,{}),str(game.career.get("palette",""))),28 if size.y<800 and size.x>size.y else 32,true,true,(JourneyDesk.active(self) or (page=="gigs" and (BookingDesk.active(self) or Booking.modern(game.career)))) and not receipt_open)
 name_label.name = "CareerBandName"
 name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 name_label.max_lines_visible = 1 if (JourneyDesk.active(self) or (page=="gigs" and (BookingDesk.active(self) or Booking.modern(game.career)))) and not receipt_open else 2
 words.add_child(name_label)
 var funds: Label = C.label("DAY %d  •  £%d" % [int(game.career.get("tour_day",1)),int(game.career.get("cash",0))],16)
 funds.name = "CareerDayCash"
 words.add_child(funds)

func _navigate(destination: String) -> void:
 if busy or is_instance_valid(_live_dialog) or destination not in ["home","gear","band","songs","gigs","finance","offstage","recording","calendar","goal_focus","band_moment","situation"]:
  return
 if Finance.is_over(game.career):
  destination = "finance"
 elif RadioVisit.locked(game.career):
  destination="recording"
  recording_mode="visit"
 elif (Journey.locked(game.career) or (Booking.modern(game.career) and LiveRules.show_day(game.career))) and destination not in ["calendar","finance","band","songs"]:
  destination="gigs"
 if destination!="goal_focus":
  _focus_picker_open=false
  _focus_picker_epoch+=1
 page = destination
 receipt_open = false
 goal_notice = ""
 catalogue_open = destination=="gear"
 notice = ""
 _scroll_position = 0
 if is_instance_valid(_scroll):
  _scroll.scroll_vertical = 0
 _pending_focus = RecordingDesk.focus_name(self) if destination=="recording" else ("LiveMainAction" if destination=="gigs" else ("OffstageMainAction" if destination=="offstage" else "CareerNav_"+destination))
 if destination=="gigs" and JourneyDesk.active(self):
  _pending_focus="JourneyHeldNote"
 if destination=="home":
  _pending_focus = "CareerHomePracticeAction"
 if destination=="calendar":
  _pending_focus = "CareerCalendarBackAction"
 _render()

func _restore_focus(control_name: String) -> void:
 if busy or not is_visible_in_tree():
  return
 var target: Control = find_child(control_name,true,false) as Control
 if target==null:
  return
 var generation: int = _render_generation
 if is_instance_valid(_scroll) and _scroll.is_ancestor_of(target):
  # Bound one-shot callbacks disconnect when this owner is freed. An awaited
  # instance method can otherwise resume after destruction and log an ERROR.
  _restore_focus_wait(control_name,generation,2)
 else:
  _apply_restored_focus(control_name,generation,false)

func _restore_focus_wait(control_name: String, generation: int, remaining: int) -> void:
 if not is_inside_tree() or generation!=_render_generation:return
 if remaining<=0:
  _apply_restored_focus(control_name,generation,true)
  return
 var tree: SceneTree=get_tree()
 if tree==null:return
 var callback: Callable=_restore_focus_wait.bind(control_name,generation,remaining-1)
 if not tree.process_frame.is_connected(callback):tree.process_frame.connect(callback,CONNECT_ONE_SHOT)

func _apply_restored_focus(control_name: String, generation: int, respect_existing: bool) -> void:
 if not is_inside_tree() or generation!=_render_generation or busy or not is_visible_in_tree():return
 var target: Control=find_child(control_name,true,false) as Control
 if target==null:return
 if respect_existing:
  var current_focus: Control = get_viewport().gui_get_focus_owner()
  if current_focus!=null and current_focus!=target and is_ancestor_of(current_focus):
   _pending_focus = ""
   return
 if target!=null and target.is_visible_in_tree() and target.focus_mode!=Control.FOCUS_NONE:
  target.grab_focus()
  if is_instance_valid(_scroll) and _scroll.is_ancestor_of(target):
   _scroll.ensure_control_visible(target)
 _pending_focus = ""

func _home_page(parent: Node, compact: bool) -> void:
 var body := _paper(parent,compact)
 _copy(body,"YOUR CAREER DESK",26)
 _copy(body,str(game.genre).to_upper()+"  /  "+str(game.career.get("vibe","Unpolished")),14,true)
 DirectionCard.goal(self,body,compact)
 if Booking.modern(game.career) and bool(Booking.validate(game.career).get("ok",false)):
  var agreement: Dictionary=Booking.terms(game.career)
  var line: Label=_copy(body,"%s · DAY %d · %d career day(s) reserved · next available DAY %d" % [agreement["venue_snapshot"]["venue"],int(agreement["day"]),int(agreement["tariff"]["duration"]),int(agreement["next_available_day"])],16)
  line.name="CareerSavedShowAgreement"
 Launcher.render(self,body,compact)
 var grid := GridContainer.new()
 grid.columns = 1 if compact else 2
 grid.add_theme_constant_override("h_separation",20)
 grid.add_theme_constant_override("v_separation",8)
 body.add_child(grid)
 for entry in [["READINESS","readiness"],["BAND MORALE","morale"],["TENSION","tension"]]:
  var block := _box(2)
  grid.add_child(block)
  _copy(block,str(entry[0]),13,true)
  var value: int = int(game.career.get(str(entry[1]),0))
  var reading: HBoxContainer = C.meter(value,"notepaper")
  block.add_child(reading)
  if str(entry[1])=="tension":
   # Tension is the one status where less is better. Keep the original meter
   # art/value inert and truthful; encode the meaning in native ink and copy.
   var number: Label = reading.get_node("CareerMeterValue") as Label
   number.add_theme_color_override("font_color",Color("326346") if value<35 else (Color("805817") if value<65 else Color("943e31")))
   var meaning: String = "CALM" if value<35 else ("ON EDGE" if value<65 else "HIGH TENSION")
   var caption: Label = C.paper_label(meaning+" • lower means calmer",16)
   caption.name = "CareerTensionMeaning"
   block.add_child(caption)
 _copy(body,"%d FINISHED ORIGINALS  •  %d FANS" % [int(game.career.get("songs",0)),int(game.career.get("fans",0))],16)

func _gear_page(parent: Node, compact: bool) -> void:
 if Gear.item_for(selected_item).is_empty():
  selected_item = "amp"
 var dossier_parent: Node = parent
 if not compact:
  var columns := HBoxContainer.new()
  columns.add_theme_constant_override("separation",20)
  parent.add_child(columns)
  var list := _box()
  list.size_flags_stretch_ratio = 1.0
  columns.add_child(list)
  dossier_parent = _box()
  (dossier_parent as Control).size_flags_stretch_ratio = 2.0
  columns.add_child(dossier_parent)
  # The wide shelf scrolls independently, so a long illustrated stock list
  # does not push the selected item's price and photograph out of view.
  var shelf := ScrollContainer.new()
  shelf.name = "GearShelfScroll"
  shelf.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
  shelf.follow_focus = true
  shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  shelf.size_flags_vertical = Control.SIZE_EXPAND_FILL
  shelf.custom_minimum_size.y = clampf(size.y-300.0,260.0,640.0)
  shelf.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
  list.add_child(shelf)
  var shelf_body := _box()
  shelf.add_child(shelf_body)
  _catalogue(shelf_body,compact)
 if compact and catalogue_open:
  _catalogue(parent,compact)
  return
 var body := _paper(dossier_parent,compact)
 var index := 0
 for n in range(Gear.items().size()):
  if str(Gear.items()[n]["id"])==selected_item:
   index = n
 var browse := HBoxContainer.new()
 browse.add_theme_constant_override("separation",6)
 body.add_child(browse)
 var previous := _button("‹","GearPreviousAction",_step_item.bind(-1))
 previous.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 browse.add_child(previous)
 var chooser := _button("%d / %d  •  CATALOGUE" % [index+1,Gear.items().size()],"GearCatalogueAction",_toggle_catalogue)
 browse.add_child(chooser)
 var following := _button("›","GearNextAction",_step_item.bind(1))
 following.size_flags_horizontal = Control.SIZE_SHRINK_END
 browse.add_child(following)
 var item: Dictionary = Gear.item_for(selected_item)
 body.add_child(GearPress.image(selected_item,128.0 if compact else 180.0))
 var title := _copy(body,str(item["name"]),24)
 title.name = "GearItemTitle"
 _copy(body,str(item["type"]),13,true)
 _copy(body,str(item["description"]),16)
 var owned: bool = (game.career.get("owned_equipment",[]) as Array).has(selected_item)
 _copy(body,("OWNED EQUIPMENT  •  SERVICE £%d / 1 DAY" % Gear.SERVICE_COST) if owned else ("£%d ASKING PRICE" % int(item["price"])),14,true)
 if owned:
  var record: Dictionary = Gear.record(game.career,selected_item)
  var condition: int = int(record.get("condition",-1))
  _copy(body,"CONDITION  /  "+("UNKNOWN — SERVICE TO ASSESS" if condition<0 else "%d / 100" % condition),18)
  _copy(body,str(record.get("provenance","History not recorded")),14,true)
  _copy(body,"REPAIRS  /  %d" % int(record.get("repairs",0)),14,true)
  var holder: int = Gear.holder_index(game.career,record)
  var members: Array = game.career.get("members",[])
  _copy(body,"CARRIED BY  /  "+(str(members[holder].get("name","Musician")) if holder>=0 else "SHARED ROAD CASE"),16)
  var any_available := false
  for member_index in range(members.size()):
   var member: Dictionary = members[member_index]
   if holder==member_index or str(member.get("life_status","active"))!="active" or not Bridge.compatible(game.career,selected_item,member_index):
    continue
   any_available = true
   var assign := _button("ASSIGN TO "+str(member.get("name","Musician")).to_upper()+"  •  FREE","GearAssign_"+str(member_index),_commit_gear.bind("assign",member_index))
   assign.disabled = busy or Bridge.show_day(game.career)
   body.add_child(assign)
  if not any_available:
   _copy(body,"No other compatible active musician is available for this item.",14,true)
 else:
  _copy(body,("NEW CONDITION" if str(item.get("stock",""))=="NEW" else "SECOND-HAND CONDITION")+"  /  %d / 100" % int(item["condition"]),16)
  _copy(body,"Choose your purchase when ready. Browsing is free.",14,true)
 if not notice.is_empty():
  _copy(body,notice,16)
 if owned:
  _road_cases(dossier_parent,compact)

func _catalogue(parent: Node, compact: bool) -> void:
 GearPress.catalogue(self,parent,compact)

func _choose_item(id: String) -> void:
 if busy or Gear.item_for(id).is_empty():
  return
 selected_item = id
 catalogue_open = false
 notice = ""
 _scroll_position = 0
 if is_instance_valid(_scroll): _scroll.scroll_vertical = 0
 _pending_focus = "GearCatalogueAction"
 _render()

func _step_item(delta: int) -> void:
 if busy:
  return
 var index := 0
 for n in range(Gear.items().size()):
  if str(Gear.items()[n]["id"])==selected_item: index=n
 var next_index := posmod(index+delta,Gear.items().size())
 selected_item = str(Gear.items()[next_index]["id"])
 notice = ""
 _scroll_position = 0
 if is_instance_valid(_scroll): _scroll.scroll_vertical=0
 _pending_focus = "GearNextAction" if delta>0 else "GearPreviousAction"
 _render()

func _toggle_catalogue() -> void:
 if busy:
  return
 if size.x>=840 and size.x>size.y:
  _pending_focus = "GearChoice_"+selected_item
  call_deferred("_restore_focus",_pending_focus)
  return
 catalogue_open = not catalogue_open
 _scroll_position=0
 if is_instance_valid(_scroll): _scroll.scroll_vertical=0
 _pending_focus = "GearChoice_"+selected_item if catalogue_open else "GearCatalogueAction"
 _render()

func _road_cases(parent: Node, compact: bool) -> void:
 GearPress.inventory(self,parent,compact)

func _band_page(parent: Node, compact: bool) -> void:
 BandMoment.entries(self,parent)
 parent.add_child(_button("LIFE OUTSIDE THE BAND","CareerSituationAction",_open_situation))
 parent.add_child(_button("VIEW BAND POSTER","CareerBandPosterAction",_open_band_poster,true))
 var body := _paper(parent,compact)
 _copy(body,"THE PEOPLE IN YOUR BAND",24)
 var dossiers := GridContainer.new()
 dossiers.name = "CareerMemberDossiers"
 dossiers.columns = 1 if compact else (3 if size.x>=1220 else 2)
 dossiers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 dossiers.add_theme_constant_override("h_separation",20)
 dossiers.add_theme_constant_override("v_separation",18)
 body.add_child(dossiers)
 var members: Array = game.career.get("members",[])
 for index in range(members.size()):
  var person: Dictionary = members[index]
  var dossier := _box(8)
  dossiers.add_child(dossier)
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",12)
  dossier.add_child(row)
  var source: Dictionary = Cast.by_id(str(person.get("candidate_id","")))
  var path: String = str(source.get("portrait_preview",""))
  if not path.is_empty() and ResourceLoader.exists(path):
   var photo := TextureRect.new()
   photo.name = "CareerPortrait_"+str(person.get("candidate_id",""))
   photo.texture = load(path)
   photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   photo.custom_minimum_size = Vector2(72,76)
   photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
   row.add_child(photo)
  var details := _box(3)
  row.add_child(details)
  _copy(details,str(person.get("name","Musician")),21)
  _copy(details,str(person.get("role","")),16,true)
  if str(game.career.get("lead_vocal_candidate_id",""))==str(person.get("candidate_id","")):
   _copy(details,"LEAD VOCALS",14,true)
  _copy(details,str(person.get("life_status","active")).capitalize(),14,true)
  for stat in [["SKILL","skill"],["MORALE","morale"],["FATIGUE","fatigue"],["LOYALTY","loyalty"]]:
   var values := HBoxContainer.new()
   values.add_theme_constant_override("separation",8)
   dossier.add_child(values)
   var label := _copy(values,str(stat[0]),13,true)
   label.custom_minimum_size.x=68
   label.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
   var meter := C.meter(int(person.get(str(stat[1]),0)),"notepaper")
   meter.name = "CareerMemberStat_"+str(index)+"_"+str(stat[1])
   values.add_child(meter)
 _road_cases(parent,compact)

func _open_situation() -> void:
 if busy or is_instance_valid(_live_dialog) or game==null:return
 if Finance.is_over(game.career) or RadioVisit.locked(game.career):
  _navigate("home")
  return
 var checked: Dictionary=Situation.validate(game.career)
 if not checked.ok:
  notice=str(checked.message)
  _render()
  return
 var rows: Array=Situation.members(game.career)
 var id: String=""
 for row in rows:
  if row.editable:id=str(row.id);break
 if id.is_empty():
  notice="Outside-band context cannot be attributed without a stable musician identity. The existing biography is retained."
  _render()
  return
 _navigate("situation")
 _situation_pick_member(id)

func _situation_pick_member(id: String) -> void:
 if busy or page!="situation" or is_instance_valid(_live_dialog):return
 for row in Situation.members(game.career):
  if row.id==id and row.editable:
   situation_member_id=id
   situation_kind=str(row.kind)
   situation_expected=game.career.duplicate(true)
   notice=""
   _pending_focus="SituationMember_"+id
   _render()
   return

func _situation_pick_kind(kind: String) -> void:
 if busy or page!="situation" or not kind in Situation.KINDS:return
 situation_kind=kind
 _pending_focus="SituationContext_"+kind
 _render()

func _situation_save() -> void:
 if busy or page!="situation" or is_instance_valid(_live_dialog) or game==null or not is_inside_tree() or not is_visible_in_tree():return
 if Finance.is_over(game.career) or RadioVisit.locked(game.career) or Bridge.show_day(game.career):
  notice="Finish the current show or visit before recording a new availability agreement."
  _render()
  return
 busy=true
 var before: Dictionary=game.snapshot().duplicate(true)
 var result: Dictionary=Situation.set_context(game.career,situation_member_id,situation_kind,situation_expected)
 if result.get("ok",false) and result.get("changed",false):
  game.career=result.state.duplicate(true)
  if not bool(opening_owner.save_draft()):
   game.restore(before)
   result={"ok":false,"message":"The context could not be saved. The whole previous career and pending choices are retained; you can retry."}
 busy=false
 notice=str(result.get("message","The context could not be saved."))
 if result.get("ok",false):situation_expected=game.career.duplicate(true)
 _pending_focus="SituationSaveContextAction"
 _render()

func _open_band_poster() -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog) or game==null:return
 busy=true
 var view:=BandPoster.new()
 view.configure(game.career,reduced_motion)
 _live_dialog=view
 _band_poster_id=view.get_instance_id()
 view.closed.connect(_band_poster_done.bind(true,_band_poster_id))
 view.aborted.connect(_band_poster_done.bind(false,_band_poster_id))
 view.tree_exited.connect(_band_poster_done.bind(false,_band_poster_id))
 add_child(view)

func _band_poster_done(user_closed: bool, id: int) -> void:
 if id!=_band_poster_id:return
 var view: Control=_live_dialog
 _band_poster_id=0
 _live_dialog=null
 busy=false
 if is_instance_valid(view) and view.is_inside_tree() and not view.is_queued_for_deletion():view.queue_free()
 if not is_inside_tree() or not is_visible_in_tree():return
 _pending_focus="CareerBandPosterAction" if user_closed else ""
 if user_closed:_render()
 else:call_deferred("_refresh_after_band_poster")

func _refresh_after_band_poster() -> void:
 if not is_inside_tree() or not is_visible_in_tree() or busy or is_instance_valid(_live_dialog):return
 _pending_focus=""
 _render()

func _songs_page(parent: Node, compact: bool) -> void:
 var body := _paper(parent,compact)
 _copy(body,"YOUR SONGBOOK",26)
 var draft: Dictionary = game.career.get("current_song_draft",{})
 if not draft.is_empty():
  _copy(body,"SAVED WRITING DRAFT",14,true)
  _copy(body,str(draft.get("title","UNTITLED")),21)
  var sessions: Variant = draft.get("sessions",[])
  var count: int = sessions.size() if sessions is Array else int(game.career.get("song_draft_progress",0))
  _copy(body,"SESSION %d / 3  •  %s" % [count,str(draft.get("leader","The band"))],16)
  _copy(body,str(draft.get("idea",""))+"  /  "+str(draft.get("form","")),16,true)
 var entries: Array = Songs.entries(game.career)
 if entries.is_empty():
  _copy(body,"Your first original takes three saved writing sessions. The band can keep developing its current idea in the practice room.",16)
 for song in entries:
  _copy(body,"%02d  /  %s" % [int(song["number"]),str(song["title"])],22)
  _copy(body,str(song["writer"]),16)
  _copy(body,str(song["arrangement"])+"  •  "+str(song["verdict"]),16,true)
  _copy(body,"LIVE RECEPTION  /  "+str(song["reception"]),14,true)
 body.add_child(_button("BACK TO WRITING  ›","CareerSongPracticeAction",_practice.bind("create"),true))

func _decision_dock(parent: Node, compact: bool) -> void:
 var dock := _box(5)
 dock.name = "CareerDecisionDock"
 dock.custom_minimum_size.x = minf(900.0,maxf(280.0,size.x-(24 if compact else 40)))
 dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_CENTER
 parent.add_child(dock)
 if receipt_open:
  var return_copy: String = "BACK TO THE LIVE DESK  ›" if str(receipt.get("kind","gear"))=="live" else "BACK TO THE MUSIC SHOP  ›"
  if str(receipt.get("kind","gear"))=="offstage":
   return_copy = "PREPARE FOR YOUR SHOW  ›" if str(receipt.get("return_page","offstage"))=="gigs" else "BACK TO LIFE OFFSTAGE  ›"
  elif str(receipt.get("kind","gear"))=="recording":
   return_copy = "BACK TO YOUR RECORDINGS  ›"
  elif str(receipt.get("kind","gear"))=="band_moment":
   return_copy="BACK TO YOUR BAND  ›"
  dock.add_child(_button(return_copy,"CareerReceiptContinueAction",_close_receipt,true))
 elif page=="gigs":
  if JourneyDesk.active(self):JourneyDesk.dock(self,dock,compact)
  elif BookingDesk.active(self):BookingDesk.dock(self,dock)
  else:LiveDesk.dock(self,dock,compact)
 elif page=="finance" and not Finance.is_over(game.career):
  dock.add_child(_button("BACK TO THE CAREER DESK  ›","CareerFinanceBackAction",_navigate.bind("home"),true))
 elif page=="offstage":
  OffstageDesk.dock(self,dock,compact)
 elif page=="recording":
  RecordingDesk.dock(self,dock,compact)
 elif page=="goal_focus":
  DirectionCard.chooser_dock(self,dock)
 elif page=="band_moment":
  BandMoment.dock(self,dock)
 elif page=="situation":
  SituationDesk.dock(self,dock)
 elif page=="finance" and RadioVisit.locked(game.career):
  RadioDesk.recovery_dock(self,dock)
 elif page=="calendar":
  var calendar_live := _button("OPEN THE LIVE DESK  ›","CareerCalendarLiveAction",_navigate.bind("gigs"))
  var calendar_view: Dictionary = CalendarDesk.summary(game.career)
  var calendar_booking: Dictionary = calendar_view["booking"]
  calendar_live.disabled = busy or not bool(calendar_view["today_valid"]) or (bool(calendar_booking["present"]) and not bool(calendar_booking["valid"]))
  dock.add_child(calendar_live)
  dock.add_child(_button("BACK TO THE CAREER DESK  ›","CareerCalendarBackAction",_navigate.bind("home"),true))
 elif page=="songs":
  dock.add_child(_button("CUT A DEMO  ›","CareerRecordingAction",_navigate.bind("recording"),true))
 elif page=="gear":
  if compact and catalogue_open:
   dock.add_child(_button("BACK TO THE CAREER DESK","GearCloseCatalogueAction",_navigate.bind("home")))
  else:
   var item: Dictionary = Gear.item_for(selected_item)
   var owned: bool = (game.career.get("owned_equipment",[]) as Array).has(selected_item)
   var fee: int = Gear.SERVICE_COST if owned else int(item["price"])
   var description: String = "SERVICE & ASSESS" if owned else "BUY EQUIPMENT"
   var funds: int = int(game.career.get("cash",0))
   var commitment: Label = C.label(("£%d  •  1 DAY  •  £%d AFTER" % [fee,funds-fee]) if funds>=fee else ("£%d AVAILABLE  •  NEED £%d MORE" % [funds,fee-funds]),16)
   commitment.name = "CareerCommitment"
   dock.add_child(commitment)
   var action := _button(description+"  •  £%d" % fee,"GearServiceAction" if owned else "GearBuyAction",_commit_gear.bind("service" if owned else "buy",-1),true)
   action.disabled = busy or int(game.career.get("cash",0))<fee or Bridge.show_day(game.career) or (owned and int(Gear.record(game.career,selected_item).get("condition",-1))>=100)
   dock.add_child(action)
   if Bridge.show_day(game.career):
    dock.add_child(C.label("Tonight's gig comes first. Finish the booking before another activity.",14))
   elif int(game.career.get("cash",0))<fee:
    dock.add_child(C.label("Need £%d more." % (fee-int(game.career.get("cash",0))),14))
   elif owned and int(Gear.record(game.career,selected_item).get("condition",-1))>=100:
    dock.add_child(C.label("Already in excellent condition.",14))
 var navigation := HBoxContainer.new()
 navigation.visible=not (page=="recording" and RadioVisit.locked(game.career))
 navigation.add_theme_constant_override("separation",8)
 dock.add_child(navigation)
 var goal: Dictionary=_goal_direction() if (page=="home" and not receipt_open) or (receipt_open and receipt.get("show_receipt") is Dictionary and not receipt["show_receipt"].is_empty()) else {}
 var guided: bool=bool(goal.get("ok",false)) and not str(goal.get("route","")).is_empty()
 var practice_action: Button=_button(str(goal["route_label"]),"CareerGoalPreparationAction",_goal_preparation.bind(str(goal["route"]))) if guided else _button("‹ PRACTICE","CareerPracticeAction",_practice.bind(""))
 practice_action.disabled = busy or Finance.is_over(game.career) or RadioVisit.locked(game.career) or Journey.locked(game.career) or (Booking.modern(game.career) and LiveRules.show_day(game.career))
 navigation.add_child(practice_action)
 navigation.add_child(_button("MAIN MENU","CareerMenuAction",_menu))

func _commit_gear(verb: String, member_index: int = -1) -> void:
 if busy or receipt_open or game==null or opening_owner==null:
  return
 if not _finance_guard():return
 busy = true
 var before: Dictionary = game.career.duplicate(true)
 var result: Dictionary = Bridge.gear_action(before,verb,selected_item,member_index)
 if not bool(result.get("ok",false)):
  busy=false
  notice=str(result.get("message","Action unavailable."))
  _render()
  return
 var accounted: Dictionary = Finance.apply(before,result["state"],"gear:"+verb)
 if not bool(accounted.get("ok",false)):
  busy=false
  notice=str(accounted.get("message","The accounts could not be reconciled."))
  _render()
  return
 game.career = accounted["state"]
 if not bool(opening_owner.save_draft()):
  game.career=before
  busy=false
  notice="The change could not be saved. Your previous band state is retained."
  _render()
  return
 var after: Dictionary = game.career
 receipt={"verb":verb,"item":selected_item,"item_name":str(Gear.item_for(selected_item).get("name",selected_item)),"text":str(result.get("message","Saved.")),"day_before":int(before.get("tour_day",1)),"day_after":int(after.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(after.get("cash",0)),"readiness_before":int(before.get("readiness",0)),"readiness_after":int(after.get("readiness",0))}
 receipt["changes"] = []
 for field in ["readiness","morale","tension","reputation","fans"]:
  if int(before.get(field,0))!=int(after.get(field,0)):
   receipt["changes"].append({"label":field.to_upper(),"before":int(before.get(field,0)),"after":int(after.get(field,0))})
 # Surface existing original narrative consequences without inventing events.
 var old_ids: Array = []
 for entry in before.get("career_journal",[]):
  if entry is Dictionary: old_ids.append(str(entry.get("id","")))
 for entry in after.get("career_journal",[]):
  if entry is Dictionary and not old_ids.has(str(entry.get("id",""))):
   receipt["text"] += "\n\n"+str(entry.get("title","CAREER NOTE"))+"\n"+str(entry.get("text",""))
 receipt_open=true
 _fresh_receipt=true
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 var overlay := Beat.new()
 overlay.heading_copy="THE MUSIC SHOP" if verb!="assign" else "THE ROAD CASE"
 var days: int = int(receipt.day_after)-int(receipt.day_before)
 overlay.detail_copy="SAVED  •  %d DAY%s  •  £%d SPENT" % [days,"" if days==1 else "S",int(receipt.cash_before)-int(receipt.cash_after)]
 overlay.configure("report" if days==0 else "gear",{"metrics":{"tour_day":{"before":receipt.day_before,"after":receipt.day_after}}},reduced_motion,"flightcase",int(receipt.day_after),int(receipt.cash_after))
 _overlay=overlay
 overlay.covered.connect(_present_receipt)
 overlay.finished.connect(_finish_receipt)
 add_child(overlay)

func _present_receipt() -> void:
 _render()

func _finish_receipt() -> void:
 if is_instance_valid(_overlay):
  remove_child(_overlay)
  _overlay.queue_free()
 _overlay=null
 busy=false
 _pending_focus="CareerReceiptContinueAction" if receipt.has("show_receipt") else "CareerReceiptNote"
 _render()
 var note: Label = find_child("CareerReceiptNote",true,false) as Label
 if note!=null and _fresh_receipt:
  note.call_deferred("begin",reduced_motion)
 _fresh_receipt=false

func _receipt_page(parent: Node, compact: bool) -> void:
 if str(receipt.get("kind",""))=="band_moment":
  BandMoment.receipt(self,parent,compact)
  return
 if str(receipt.get("kind",""))=="recording":
  RecordingDesk.receipt(self,parent,compact)
  return
 if receipt.get("show_receipt") is Dictionary and not receipt["show_receipt"].is_empty():
  ShowDesk.receipt(self,parent,compact,receipt["show_receipt"])
  return
 var body := _paper(parent,compact)
 var live: bool = str(receipt.get("kind","gear"))=="live"
 var offstage: bool = str(receipt.get("kind","gear"))=="offstage"
 _copy(body,"LIFE OFFSTAGE" if offstage else ("THE LIVE JOURNAL" if live else "THE MUSIC SHOP RECORD"),16,true)
 _copy(body,str(receipt.get("title","OFFSTAGE")) if offstage else (str(receipt.get("title","LIVE TONIGHT")) if live else str(receipt.get("item_name","EQUIPMENT"))),25)
 _copy(body,"DAY %d → %d   •   £%d → £%d" % [int(receipt.get("day_before",1)),int(receipt.get("day_after",1)),int(receipt.get("cash_before",0)),int(receipt.get("cash_after",0))],16,true)
 var note: Label = Ink.new()
 note.name="CareerReceiptNote"
 note.text=str(receipt.get("text","Saved."))
 note.add_theme_font_size_override("font_size",16)
 note.add_theme_color_override("font_color",Color("29241f"))
 if _fresh_receipt:note.visible_characters=0
 body.add_child(note)
 var record: Dictionary = {} if live or offstage else Gear.record(game.career,str(receipt.get("item","")))
 if not record.is_empty():
  var condition: int = int(record.get("condition",-1))
  _copy(body,"CONDITION  /  "+("UNKNOWN" if condition<0 else "%d / 100" % condition),18)
  _copy(body,str(record.get("provenance","")),14,true)
 for change in receipt.get("changes",[]):
  _copy(body,"%s  %d → %d" % [str(change["label"]),int(change["before"]),int(change["after"])],16)
 for entry in receipt.get("journal_entries",[]):
  _copy(body,str(entry.get("title","JOURNAL")),16,true)
  _copy(body,str(entry.get("text","")),16)

func _close_receipt() -> void:
 if busy:return
 show_receipt_details_open=false
 if str(receipt.get("kind","gear"))=="offstage":page=str(receipt.get("return_page","offstage"))
 elif str(receipt.get("kind","gear"))=="band_moment":page="band"
 elif str(receipt.get("kind","gear"))=="recording":
  page="recording"
  recording_mode="archive"
 receipt_open=false
 _fresh_receipt=false
 _pending_focus="BandMomentSavedAction" if page=="band" and str(receipt.get("kind",""))=="band_moment" else ("RecordingSelectAction" if page=="recording" else (LiveDesk.focus_name(self) if page=="gigs" else (OffstageDesk.focus_name(self) if page=="offstage" else "GearCatalogueAction")))
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _render()

func _band_moment_present(result: Dictionary, before: Dictionary) -> void:
 receipt={"kind":"band_moment","title":str(result.get("moment",{}).get("title","REHEARSAL CONVERSATION")),"text":str(result.get("message","Saved.")),"moment":result["moment"].duplicate(true),"day_before":int(before.get("tour_day",1)),"day_after":int(game.career.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(game.career.get("cash",0))}
 receipt_open=true
 _fresh_receipt=true
 band_moment_context["details"]=false
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 var overlay:=Beat.new()
 overlay.heading_copy="THE NEXT REHEARSAL"
 overlay.detail_copy="DECISION SAVED  •  1 DAY  •  NO DIRECT CASH COST"
 overlay.configure("gear",{"metrics":{"tour_day":{"before":receipt.day_before,"after":receipt.day_after}}},reduced_motion,"flightcase",int(receipt.day_after),int(receipt.cash_after))
 _overlay=overlay
 overlay.covered.connect(_present_receipt)
 overlay.finished.connect(_finish_receipt)
 add_child(overlay)

func _recording_present(result: Dictionary, before: Dictionary, verb: String) -> void:
 # The pure rules and the ONE owner save have already succeeded.
 var after: Dictionary=game.career
 receipt={"kind":"recording","verb":verb,"title":"LOCAL RADIO RESPONSE" if verb=="radio" else ("DEMO RECORDED" if verb=="record" else "RELEASED LOCALLY"),"text":str(result.get("message","Saved.")),"session":result.get("session",{}).duplicate(true),"day_before":int(before.get("tour_day",1)),"day_after":int(after.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(after.get("cash",0)),"changes":[]}
 for field in ["readiness","fans","press","buzz"]:
  if int(before.get(field,0))!=int(after.get(field,0)):
   receipt["changes"].append({"label":field.to_upper(),"before":int(before.get(field,0)),"after":int(after.get(field,0))})
 if verb=="radio":
  for field in ["reputation","morale"]:
   if int(before.get(field,0))!=int(after.get(field,0)):
    receipt["changes"].append({"label":field.to_upper(),"before":int(before.get(field,0)),"after":int(after.get(field,0))})
 receipt_open=true
 _fresh_receipt=true
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 var overlay:=Beat.new()
 overlay.heading_copy="THE LOCAL RADIO RESPONSE" if verb=="radio" else ("THE DEMO IS ON TAPE" if verb=="record" else "OUT IN THE LOCAL SCENE")
 var days: int=int(receipt.day_after)-int(receipt.day_before)
 overlay.detail_copy="SAVED  •  %d DAY%s  •  £%d SPENT" % [days,"" if days==1 else "S",int(receipt.cash_before)-int(receipt.cash_after)]
 overlay.configure("recording",{"metrics":{"tour_day":{"before":receipt.day_before,"after":receipt.day_after}}},reduced_motion,"flightcase",int(receipt.day_after),int(receipt.cash_after))
 _overlay=overlay
 overlay.covered.connect(_present_receipt)
 overlay.finished.connect(_finish_receipt)
 add_child(overlay)

func _practice(activity: String) -> void:
 if Journey.locked(game.career):
  _navigate("gigs")
  return
 if RadioVisit.locked(game.career):
  _navigate("recording")
  return
 if Finance.is_over(game.career):
  _navigate("finance")
  return
 if not busy and not is_instance_valid(_live_dialog):practice_requested.emit(activity)

func _goal_direction() -> Dictionary:
 var view: Dictionary=Direction.current(game.career)
 if not bool(view["ok"]):return view
 var booking: Dictionary=Direction.booking_guard(game.career)
 if not bool(booking["ok"]):
  view["ok"]=false
  view["message"]=str(booking["message"])
  view["route"]=""
  view["route_label"]=""
  view["route_hint"]=""
 elif bool(booking["due"]):
  view["route"]="gigs"
  view["route_label"]="OPEN LIVE DESK"
  view["route_hint"]="YOUR BOOKING COMES FIRST"
 return view

func _goal_focus_priority() -> bool:
 if Finance.is_over(game.career):
  _navigate("finance")
  return false
 if RadioVisit.locked(game.career):
  _navigate("recording")
  return false
 var booking: Dictionary=Direction.booking_guard(game.career)
 if not bool(booking["ok"]):
  goal_notice=str(booking["message"])
  _render()
  return false
 if bool(booking["due"]):
  _navigate("gigs")
  return false
 return true

func _goal_focus_open(expected_generation: int) -> void:
 if not is_inside_tree() or not is_visible_in_tree() or busy or is_instance_valid(_live_dialog) or game==null or opening_owner==null or expected_generation!=_render_generation:return
 var relevant: bool=(page=="home" and not receipt_open) or (receipt_open and receipt.get("show_receipt") is Dictionary and not receipt["show_receipt"].is_empty())
 if not relevant or not _goal_focus_priority():return
 _focus_return_page=page
 _focus_return_receipt=receipt_open
 _focus_expected=game.career.duplicate(true)
 _focus_owner_id=get_instance_id()
 _focus_picker_epoch+=1
 _focus_picker_open=true
 var selected: Dictionary=GoalFocus.validate(game.career)
 var suggested: Dictionary=Direction.current(game.career)
 _focus_draft=str(selected.get("chapter_id",""))
 if _focus_draft.is_empty() and bool(suggested.get("ok",false)) and not bool(suggested.get("done",false)):_focus_draft=str(suggested.get("id",""))
 page="goal_focus"
 receipt_open=false
 goal_notice=""
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _pending_focus="GoalFocusChoice_"+_focus_draft if not _focus_draft.is_empty() else "GoalFocusBackAction"
 _render()

func _goal_focus_context(epoch: int, generation: int) -> bool:
 return is_inside_tree() and is_visible_in_tree() and not busy and not is_instance_valid(_live_dialog) and game!=null and opening_owner!=null and page=="goal_focus" and not receipt_open and _focus_picker_open and epoch==_focus_picker_epoch and generation==_render_generation and get_instance_id()==_focus_owner_id

func _goal_focus_select(id: String, epoch: int, generation: int) -> void:
 if not _goal_focus_context(epoch,generation) or not _goal_focus_priority():return
 if game.career!=_focus_expected:
  goal_notice="The band changed while you were choosing. Go back and open the chooser again."
  _render()
  return
 var preview: Dictionary=GoalFocus.choose(game.career,id)
 if not bool(preview["ok"]):
  goal_notice=str(preview["message"])
  _render()
  return
 _focus_draft=id
 goal_notice=""
 _pending_focus="GoalFocusChoice_"+id
 _render()

func _goal_focus_close() -> void:
 _focus_picker_open=false
 _focus_picker_epoch+=1
 page=_focus_return_page
 receipt_open=_focus_return_receipt
 _pending_focus="GoalFocusOpenAction"
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _render()

func _goal_focus_back(epoch: int, generation: int) -> void:
 if not _goal_focus_context(epoch,generation):return
 if not _goal_focus_priority():return
 _goal_focus_close()

func _goal_focus_commit(clear: bool, epoch: int, generation: int) -> void:
 if not _goal_focus_context(epoch,generation) or not _goal_focus_priority():return
 if game.career!=_focus_expected:
  goal_notice="The band changed while you were choosing. Go back and open the chooser again."
  _render()
  return
 busy=true
 var before: Dictionary=game.career.duplicate(true)
 var result: Dictionary=GoalFocus.clear(before) if clear else GoalFocus.choose(before,_focus_draft)
 if not bool(result["ok"]):
  busy=false
  goal_notice=str(result["message"])
  _render()
  return
 if bool(result["changed"]):
  game.career=result["state"]
  if not bool(opening_owner.save_draft()):
   game.career=before
   busy=false
   goal_notice="Your focus could not be saved. The previous band state is retained; you can retry."
   _pending_focus="GoalFocusClearAction" if clear else "GoalFocusCommitAction"
   _render()
   return
 busy=false
 goal_notice=str(result["message"])
 _goal_focus_close()

func _goal_preparation(expected_route: String) -> void:
 # This is free navigation, not a preparation resolver or a chapter claim.
 if busy or is_instance_valid(_live_dialog) or game==null:return
 if Finance.is_over(game.career):
  _navigate("finance")
  return
 if RadioVisit.locked(game.career):
  _navigate("recording")
  return
 var booking: Dictionary=Direction.booking_guard(game.career)
 if not bool(booking["ok"]):
  goal_notice=str(booking["message"])
  _render()
  return
 if bool(booking["due"]):
  _navigate("gigs")
  return
 var view: Dictionary=Direction.current(game.career)
 if not bool(view["ok"]) or str(view["route"]).is_empty() or expected_route!=str(view["route"]):
  goal_notice="The next step changed. Review the current goal."
  _render()
  return
 goal_notice=""
 if expected_route in ["create","tighten"]:_practice(expected_route)
 elif expected_route in ["gigs","calendar"]:_navigate(expected_route)

func _toggle_show_details() -> void:
 if busy or is_instance_valid(_live_dialog) or not receipt_open or not receipt.get("show_receipt") is Dictionary or receipt["show_receipt"].is_empty():return
 show_receipt_details_open=not show_receipt_details_open
 _pending_focus="ShowReceiptDetailsAction"
 _render()

func _menu() -> void:
 if not busy and not is_instance_valid(_live_dialog):menu_requested.emit()

func _select_live_offer(offer: String) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog):return
 live_offer = offer
 LiveDesk.refresh_plans(self)

func _select_live_approach(approach: String) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog):return
 live_approach = approach
 LiveDesk.refresh_plans(self)

func _toggle_live_session() -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog):return
 live_hire_session = not live_hire_session
 if live_hire_session:live_offer="standard"
 LiveDesk.refresh_plans(self)

func _ask_live_confirmation(verb: String) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog):return
 var booking: Dictionary = Calendar.pending(game.career)
 if booking.is_empty() or verb not in ["perform","cancel"]:return
 var dialog: Control = Kit.dialog("TAKE THE STAGE?" if verb=="perform" else "CANCEL THIS BOOKING?","","flightcase")
 dialog.name = "LiveConfirmDialog"
 if verb=="perform":
  var venue: Dictionary = Gigs.get_venue(str(booking.get("venue_id","local")))
  dialog.set("body_text","Play tonight's set at %s. The show uses %d day(s). Travel and any hired drummer are charged, then the venue pays its fee. The fee depends on your set and how the show goes." % [str(booking.get("venue","the venue")),int(venue.get("days",1))])
  if ShowFlow.managed(game.career):
   var plan: Dictionary=booking.get(ShowFlow.FLOW_KEY,{}).get("plan",{})
   dialog.set("body_text",str(dialog.get("body_text"))+" %d completed originals are selected." % plan.get("song_ids",[]).size()+(" Without your own material, the payout may be disappointing even under a guarantee." if plan.get("song_ids",[]).is_empty() else ""))
  dialog.set("confirm_text","START THE SHOW")
  dialog.set("cancel_text","NOT YET")
 else:
  var charge: int = mini(Calendar.CANCELLATION_FEE,int(game.career.get("cash",0)))
  dialog.set("body_text","Cancel %s? The cancellation costs £%d and may damage the promoter's confidence in the band. No day is used." % [str(booking.get("venue","this booking")),charge])
  dialog.set("confirm_text","CANCEL BOOKING")
  dialog.set("cancel_text","KEEP BOOKING")
 _live_dialog=dialog
 _live_confirm_verb=verb
 _live_confirm_id=ShowFlow.booking_id(booking) if ShowFlow.managed(game.career) else ""
 _live_confirm_phase=ShowFlow.phase(game.career) if ShowFlow.managed(game.career) else ""
 dialog.completed.connect(_live_confirmation_completed)
 add_child(dialog)
 (dialog.get("confirm_button") as Button).name="LiveConfirmAction"
 (dialog.get("cancel_button") as Button).name="LiveKeepAction"
 dialog.call("open_modal")

func _live_confirmation_completed(accepted: bool) -> void:
 var dialog: Control = _live_dialog
 var verb: String = _live_confirm_verb
 var expected_id: String = _live_confirm_id
 var expected_phase: String = _live_confirm_phase
 _live_confirm_id=""
 _live_confirm_phase=""
 _live_dialog=null
 _live_confirm_verb=""
 if is_instance_valid(dialog):dialog.queue_free()
 if accepted:
  _commit_live(verb,"",false,expected_id,expected_phase)
 else:
  _pending_focus="LiveMainAction"
  call_deferred("_restore_focus",_pending_focus)

func _commit_live(verb: String, choice: String = "", hire: bool = false, expected_id: String = "", expected_phase: String = "") -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog) or game==null or opening_owner==null:return
 if not _finance_guard():return
 if verb=="soundcheck" and _show_gesture_active():return
 if not expected_id.is_empty() and (expected_id!=ShowFlow.booking_id(Calendar.pending(game.career)) or expected_phase!=ShowFlow.phase(game.career)):
  notice="The booking has changed. Review the current show before committing."
  _render()
  return
 busy=true
 var before: Dictionary = game.career.duplicate(true)
 var old_booking: Dictionary = Calendar.pending(before)
 var result: Dictionary = LiveRules.resolve(before,verb,choice,hire,show_draft.duplicate(true) if verb=="soundcheck" and ShowFlow.managed(before) else {})
 if not bool(result.get("ok",false)):
  busy=false
  notice=str(result.get("message","Action unavailable."))
  _render()
  return
 var accounted: Dictionary = Finance.apply(before,result["state"],"live:"+verb)
 if not bool(accounted.get("ok",false)):
  busy=false
  notice=str(accounted.get("message","The accounts could not be reconciled."))
  _render()
  return
 game.career=accounted["state"]
 if not bool(opening_owner.save_draft()):
  game.career=before
  busy=false
  notice="The change could not be saved. Your previous band state is retained."
  _render()
  return
 if verb in ["book","book_flow"]:
  show_context_id=""
  show_draft={}
  live_context_id=""
  live_approach="tight"
 var after: Dictionary = game.career
 if ShowFlow.managed(before) and verb in ["depart","advance","soundcheck","incident"]:
  receipt_open=false
  notice=str(result.get("message","")) if verb=="incident" else ""
  _scroll_position=0
  if is_instance_valid(_scroll):_scroll.scroll_vertical=0
  _pending_focus="LiveMainAction"
  _render()
  _release_show_step.call_deferred()
  return
 var booking: Dictionary = Calendar.pending(after)
 var title: String = str((old_booking if not old_booking.is_empty() else booking).get("venue","THE LIVE CIRCUIT"))
 var text: String = str(result.get("message",""))
 if text.is_empty():
  var brief: Dictionary = Night.stage(after)
  text=str(brief.get("detail","The next stage is ready."))
 receipt={"kind":"live","verb":verb,"title":title,"text":text,"day_before":int(before.get("tour_day",1)),"day_after":int(after.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(after.get("cash",0)),"changes":[],"journal_entries":[]}
 for field in ["readiness","morale","tension","reputation","fans"]:
  if int(before.get(field,0))!=int(after.get(field,0)):
   receipt["changes"].append({"label":field.to_upper(),"before":int(before.get(field,0)),"after":int(after.get(field,0))})
 var prior_entries: Array = before.get("career_journal",[])
 for entry in after.get("career_journal",[]):
  if entry is Dictionary and not prior_entries.has(entry):receipt["journal_entries"].append(entry.duplicate(true))
 if verb=="perform" and ShowFlow.managed(before):
  show_receipt_details_open=false
  receipt["show_receipt"]=ShowFlow.last_receipt(after)
 receipt_open=true
 _fresh_receipt=true
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 if receipt.has("show_receipt"):
  var replay := ShowReplay.new()
  replay.configure(receipt["show_receipt"],reduced_motion,{"band_name":after.get("band_name",""),"logo":after.get("logo","Wordmark"),"palette":after.get("palette",""),IdentityStyle.KEY:after.get(IdentityStyle.KEY,{})})
  _overlay=replay
  replay.covered.connect(_present_receipt)
  replay.finished.connect(_finish_receipt)
  add_child(replay)
  return
 var days: int = int(receipt.day_after)-int(receipt.day_before)
 var cash_delta: int = int(receipt.cash_after)-int(receipt.cash_before)
 var money: String = "£%d GAINED" % cash_delta if cash_delta>0 else "£%d SPENT" % -cash_delta
 var overlay := Beat.new()
 overlay.heading_copy="THE SHOW IS IN THE BOOKS" if verb=="perform" else "THE LIVE CIRCUIT"
 overlay.detail_copy="%d DAY%s  •  %s" % [days,"" if days==1 else "S",money]
 overlay.configure("report" if days==0 else "gig",{"metrics":{"tour_day":{"before":receipt.day_before,"after":receipt.day_after}}},reduced_motion,"flightcase",int(receipt.day_after),int(receipt.cash_after))
 _overlay=overlay
 overlay.covered.connect(_present_receipt)
 overlay.finished.connect(_finish_receipt)
 add_child(overlay)

func _finance_guard() -> bool:
 var commitment: Dictionary=Booking.guard_commitment(game.career,"career",0)
 if not bool(commitment.get("ok",false)):
  notice=str(commitment["message"])
  page="gigs"
  receipt_open=false
  _render()
  return false
 if Journey.locked(game.career):
  notice="Finish or cancel tonight's saved booking before another commitment."
  page="gigs"
  receipt_open=false
  _render()
  return false
 if RadioVisit.locked(game.career):
  notice="Resume or cancel the unfinished radio visit before another commitment."
  page="finance" if Finance.is_over(game.career) else "recording"
  recording_mode="visit"
  receipt_open=false
  _render()
  return false
 var permitted: Dictionary = Finance.guard(game.career)
 if bool(permitted.get("ok",false)):return true
 notice=str(permitted.get("message","The band has folded."))
 page="finance"
 receipt_open=false
 _render()
 return false

func _select_offstage_activity(activity: String) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog) or activity not in Offstage.ORDER:return
 offstage_activity=activity
 OffstageDesk.refresh_plans(self)

func _select_offstage_response(choice: String) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog):return
 var pending: Array = Offstage.pending(game.career)
 if pending.is_empty():return
 for option in Offstage.response_options(game.career,str(pending[0].get("id",""))):
  if str(option.get("id",""))==choice and choice!="decline":
   offstage_choice=choice
   OffstageDesk.refresh_plans(self)
   return

func _offstage_show(mode: String) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog):return
 offstage_mode="invite" if mode=="invite" and not Offstage.pending(game.career).is_empty() else "outing"
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _pending_focus=OffstageDesk.focus_name(self)
 _render()

func _commit_offstage(action: String, id: String = "", choice: String = "") -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog) or game==null or opening_owner==null:return
 if action=="respond" and id==Offstage.PROMOTER and choice=="accept":
  var handoff: Dictionary=Offstage.booking_handoff(game.career,id)
  if not bool(handoff.get("ok",false)):
   notice=str(handoff.get("message","The introduction changed."))
   _render()
   return
  _open_booking(handoff["origin"])
  return
 if not _finance_guard():return
 busy=true
 var before: Dictionary = game.career.duplicate(true)
 var result: Dictionary
 if action=="outing":result=Offstage.outing(before,id)
 elif action=="respond":result=Offstage.respond(before,id,choice)
 else:result={"ok":false,"message":"Unknown offstage action."}
 if not bool(result.get("ok",false)):
  busy=false
  notice=str(result.get("message","That offstage action is unavailable."))
  _render()
  return
 var accounted: Dictionary = Finance.apply(before,result["state"],str(result.get("finance_action","social:"+action)))
 if not bool(accounted.get("ok",false)):
  busy=false
  notice=str(accounted.get("message","The accounts could not be reconciled."))
  _render()
  return
 game.career=accounted["state"]
 if not bool(opening_owner.save_draft()):
  game.career=before
  busy=false
  notice="The change could not be saved. Your previous band state is retained."
  _render()
  return
 var after: Dictionary = game.career
 var pending: Array = Offstage.pending(after)
 if not pending.is_empty():
  offstage_mode="invite"
  offstage_choice="accept" if str(pending[0].get("id",""))==Offstage.PROMOTER else "careful"
 else:offstage_mode="outing"
 receipt={"kind":"offstage","verb":action,"title":str(result.get("title","LIFE OFFSTAGE")),"text":str(result.get("message","Saved.")),"return_page":str(result.get("return_page","offstage")),"day_before":int(before.get("tour_day",1)),"day_after":int(after.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(after.get("cash",0)),"changes":[]}
 for field in ["readiness","morale","tension","reputation","fans","buzz","press"]:
  if int(before.get(field,0))!=int(after.get(field,0)):
   receipt["changes"].append({"label":field.to_upper(),"before":int(before.get(field,0)),"after":int(after.get(field,0))})
 receipt_open=true
 _fresh_receipt=true
 notice=""
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 var days: int = int(receipt.day_after)-int(receipt.day_before)
 var overlay := Beat.new()
 overlay.heading_copy="LIFE OFFSTAGE"
 overlay.detail_copy="SAVED  •  %d DAY%s  •  £%d SPENT" % [days,"" if days==1 else "S",int(receipt.cash_before)-int(receipt.cash_after)]
 overlay.configure("report" if days==0 else "offstage",{"metrics":{"tour_day":{"before":receipt.day_before,"after":receipt.day_after}}},reduced_motion,"flightcase",int(receipt.day_after),int(receipt.cash_after))
 _overlay=overlay
 overlay.covered.connect(_present_receipt)
 overlay.finished.connect(_finish_receipt)
 add_child(overlay)

func _release_show_step() -> void:
 # Presentation only; the phase is already saved. No resolver/save here.
 if not is_inside_tree() or not is_visible_in_tree():
  busy=false
  return
 var epoch: int=_show_step_epoch
 await get_tree().create_timer(0.15 if not reduced_motion else 0.0).timeout
 if not is_inside_tree() or epoch!=_show_step_epoch:return
 busy=false
 _render()

func _sync_show_draft() -> void:
 if not ShowFlow.managed(game.career):return
 var booking: Dictionary=Calendar.pending(game.career)
 var id: String=ShowFlow.booking_id(booking)
 if show_context_id==id and not show_draft.is_empty():return
 show_context_id=id
 var marker: Dictionary=booking.get(ShowFlow.FLOW_KEY,{})
 show_draft=marker.get("plan",{}).duplicate(true) if bool(marker.get("plan_committed",false)) else ShowFlow.default_plan(game.career)

func _show_edit(field: String, value: Variant) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog) or ShowFlow.phase(game.career)!="soundcheck":return
 if field not in ["approach","intensity","shoutout"]:return
 if field=="shoutout" and _show_gesture_active():
  ShowDesk.refresh(self)
  return
 _sync_show_draft()
 show_draft[field]=value
 if field=="shoutout":
  show_draft["shoutout_venue_id"]=str(Calendar.pending(game.career).get("venue_id","")) if value=="thankvenue" else ""
  var button: Button=find_child("ShowShoutoutAction",true,false) as Button
  if button!=null:button.set_pressed_no_signal(value=="thankvenue")
 ShowDesk.refresh(self)

func _show_song_toggle(id: String) -> void:
 if _show_gesture_active():return
 if busy or receipt_open or is_instance_valid(_live_dialog) or ShowFlow.phase(game.career)!="soundcheck":return
 _sync_show_draft()
 var ids: Array=show_draft.get("song_ids",[]).duplicate()
 if ids.has(id):ids.erase(id)
 elif ids.size()<3:ids.append(id)
 show_draft["song_ids"]=ids
 _pending_focus="ShowSong_"+id.replace(":","_")
 _render()

func _show_song_move(id: String, delta: int) -> void:
 if _show_gesture_active():return
 if busy or receipt_open or is_instance_valid(_live_dialog) or ShowFlow.phase(game.career)!="soundcheck":return
 _sync_show_draft()
 var ids: Array=show_draft.get("song_ids",[]).duplicate()
 var index: int=ids.find(id)
 var destination: int=index+delta
 if index<0 or destination<0 or destination>=ids.size():return
 ids.remove_at(index)
 ids.insert(destination,id)
 show_draft["song_ids"]=ids
 _pending_focus=("ShowUp_" if delta<0 else "ShowDown_")+id.replace(":","_")
 _render()

func _show_last_receipt() -> void:
 if busy or is_instance_valid(_live_dialog):return
 var data: Dictionary=ShowFlow.last_receipt(game.career)
 if data.is_empty():return
 show_receipt_details_open=false
 receipt={"kind":"live","show_receipt":data}
 receipt_open=true
 _fresh_receipt=false
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _render()

func _show_gesture_active() -> bool:
 for name in ["ShowApproachControl","ShowIntensityControl"]:
  var control: Control=find_child(name,true,false) as Control
  if control!=null and control.has_method("is_gesture_owned") and bool(control.is_gesture_owned()):return true
 return false


func _journey_focus_ready(generation: int) -> bool:
 return is_inside_tree() and is_visible_in_tree() and page=="gigs" and not receipt_open and generation==_render_generation and not busy and not is_instance_valid(_live_dialog)

func _journey_restore_focus(control_name: String, generation: int) -> void:
 # A safe modal dismissal may be followed immediately by another modal.
 # Recheck ownership before deferring AND immediately before touching focus.
 if not _journey_focus_ready(generation):return
 _journey_restore_focus_wait(control_name,generation,2)

func _journey_restore_focus_wait(control_name: String, generation: int, remaining: int) -> void:
 if not _journey_focus_ready(generation):return
 if remaining>0:
  var callback: Callable=_journey_restore_focus_wait.bind(control_name,generation,remaining-1)
  if not get_tree().process_frame.is_connected(callback):get_tree().process_frame.connect(callback,CONNECT_ONE_SHOT)
  return
 var target: Control=find_child(control_name,true,false) as Control
 if target==null or not target.is_visible_in_tree() or target.focus_mode==Control.FOCUS_NONE or (target is BaseButton and target.disabled):return
 var current: Control=get_viewport().gui_get_focus_owner()
 if current!=null and current!=target and is_ancestor_of(current):
  _pending_focus=""
  return
 if not _journey_focus_ready(generation):return
 target.grab_focus()
 if is_instance_valid(_scroll) and _scroll.is_ancestor_of(target):_scroll.ensure_control_visible(target)
 _pending_focus=""

func _journey_expected() -> Dictionary:
 return Journey.expected(game.career)

func _journey_finish_words() -> bool:
 var scene: Control=find_child("GigJourneyPlace",true,false) as Control
 return scene!=null and bool(scene.call("finish_words"))

func _journey_danger(button: Button) -> void:
 # Destructive action colour; no outcome forecasts or answer-key colours.
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
  button.add_theme_color_override(state,Color("ee8d80"))

func _ask_journey_options(expected: Dictionary, generation: int) -> void:
 if Booking.modern(game.career):
  _ask_booking_options(Booking.expected(game.career),generation,expected)
  return
 if not is_inside_tree() or not is_visible_in_tree() or page!="gigs":return
 if busy or receipt_open or is_instance_valid(_live_dialog) or generation!=_render_generation:return
 if _journey_finish_words():return
 var checked: Dictionary=Journey._owned(game.career,expected)
 if not bool(checked.get("ok",false)):return
 var dialog: Control=Kit.dialog("SHOW OPTIONS","Your place in tonight's show is saved. Return to the show to carry on. Cancelling the booking ends this night and has consequences for the band.","flightcase")
 dialog.name="JourneyShowOptionsDialog"
 dialog.set("confirm_text","CANCEL BOOKING")
 dialog.set("cancel_text","BACK TO SHOW")
 _live_dialog=dialog
 var pinned: Dictionary=expected.duplicate(true)
 dialog.completed.connect(func(cancel_requested: bool):
  _live_dialog=null
  if is_instance_valid(dialog):dialog.queue_free()
  if cancel_requested:_ask_journey_cancel(pinned,generation)
  else:call_deferred("_journey_restore_focus","JourneyShowOptionsAction",generation))
 add_child(dialog)
 var danger: Button=dialog.get("confirm_button") as Button
 danger.name="JourneyCancelBookingOption"
 _journey_danger(danger)
 (dialog.get("cancel_button") as Button).name="JourneyShowOptionsCloseAction"
 dialog.call("open_modal")

func _ask_journey_cancel(expected: Dictionary, generation: int) -> void:
 if not is_inside_tree() or not is_visible_in_tree() or page!="gigs":return
 if busy or receipt_open or is_instance_valid(_live_dialog) or generation!=_render_generation:return
 if _journey_finish_words():return
 var checked: Dictionary=Journey._owned(game.career,expected)
 if not bool(checked.get("ok",false)):return
 var fee: int=mini(Calendar.CANCELLATION_FEE,int(game.career.get("cash",0)))
 var dialog: Control=Kit.dialog("CANCEL TONIGHT'S BOOKING?","This ends tonight's saved show. You will not play or receive the show fee. Cancelling costs £%d and damages the promoter's confidence in the band. The booking and your progress through this night will be closed. No career day is used." % fee,"flightcase")
 dialog.name="JourneyConfirmDialog"
 dialog.set("confirm_text","CANCEL SHOW")
 dialog.set("cancel_text","KEEP BOOKING")
 _live_dialog=dialog
 var pinned: Dictionary=expected.duplicate(true)
 dialog.completed.connect(func(accepted: bool):
  _live_dialog=null
  if is_instance_valid(dialog):dialog.queue_free()
  if accepted:_commit_journey("cancel",pinned,{},generation)
  else:call_deferred("_journey_restore_focus","JourneyShowOptionsAction",generation))
 add_child(dialog)
 (dialog.get("confirm_button") as Button).name="JourneyConfirmCancelAction"
 _journey_danger(dialog.get("confirm_button") as Button)
 (dialog.get("cancel_button") as Button).name="JourneyKeepBookingAction"
 dialog.call("open_modal")

func _commit_journey(action: String, expected: Dictionary, payload: Dictionary = {}, generation: int = -1) -> void:
 if not is_inside_tree() or not is_visible_in_tree() or page!="gigs":return
 if busy or receipt_open or is_instance_valid(_live_dialog) or game==null or opening_owner==null:return
 if generation>=0 and generation!=_render_generation:return
 if _journey_finish_words():return
 if action=="soundcheck" and _show_gesture_active():return
 var permitted: Dictionary=Finance.guard(game.career)
 if not bool(permitted.get("ok",false)) or RadioVisit.locked(game.career):return
 # This is the only journey dispatcher. Busy is set before model or save.
 busy=true
 var before: Dictionary=game.career.duplicate(true)
 var result: Dictionary
 var finance_action: String=""
 match action:
  "begin":result=Journey.begin(before,str(payload.get("booking_id","")))
  "wrap":
   result=LiveRules.wrap_journey(before,expected)
   finance_action="live:perform"
  "cancel":
   result=LiveRules.cancel_journey(before,expected)
   finance_action="live:cancel"
  "incident":
   result=LiveRules.journey_incident(before,expected,str(payload.get("choice","")))
   finance_action="live:incident"
  _:result=Journey.checkpoint(before,action,expected,show_draft.duplicate(true) if action=="soundcheck" else payload)
 if not bool(result.get("ok",false)):
  busy=false
  notice=str(result.get("message","The saved night could not advance."))
  _render()
  return
 if not bool(result.get("changed",true)):
  busy=false
  return
 var candidate: Dictionary=result["state"]
 if not finance_action.is_empty():
  var accounted: Dictionary=Finance.apply(before,candidate,finance_action,result.get("flows",[]),result.get("closing_balances",[]))
  if not bool(accounted.get("ok",false)):
   busy=false
   notice=str(accounted.get("message","The show accounts could not be reconciled."))
   _render()
   return
  candidate=accounted["state"]
  if action=="incident":
   # The original incident keeps its accounting contract. Pin its completed
   # finance metadata too, instead of holding a pre-accounting fingerprint.
   var rebased: Dictionary=Journey.rebase_owned_action(before,candidate,expected)
   if not bool(rebased.get("ok",false)):
    busy=false
    notice=str(rebased.get("message","The saved soundcheck changed."))
    _render()
    return
   candidate=rebased["state"]
 game.career=candidate
 if not bool(opening_owner.save_draft()):
  # Only career was installed. Restoring its WHOLE deep copy also restores
  # the phase, cursor, finance, promises and every unknown career field.
  game.career=before
  busy=false
  notice="The night could not be saved. Your whole previous band state is retained. Try again."
  _render()
  return
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 notice=""
 page="gigs"
 if action=="wrap":
  var saved: Dictionary=ShowFlow.last_receipt(game.career)
  receipt={"kind":"live","verb":"perform","show_receipt":saved,"title":str(saved.get("venue","THE SHOW")),"day_before":int(before.get("tour_day",1)),"day_after":int(game.career.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(game.career.get("cash",0))}
  receipt_open=true
  _fresh_receipt=false
  show_receipt_details_open=false
  # The set has already been lived. Never replay or settle it a second time.
  busy=false
  _pending_focus="CareerReceiptContinueAction"
  _render()
  return
 if action=="cancel":
  receipt_open=false
  busy=false
  notice=str(result.get("message","The booking was cancelled."))
  _pending_focus="CareerHome_gigs"
  _render()
  return
 _journey_fresh=true
 _pending_focus="JourneyHeldNote"
 # Hold duplicate input through one native frame after replacing the scene.
 # This callback only releases presentation busy; it never saves/resolves.
 _render()
 _release_journey_input.call_deferred(_render_generation)

func _release_journey_input(generation: int) -> void:
 if not is_inside_tree():return
 await get_tree().process_frame
 if not is_inside_tree():return
 if generation!=_render_generation:
  _release_journey_input.call_deferred(_render_generation)
  return
 busy=false
 for name in ["JourneyMainAction","JourneyFinishSongAction","JourneyChoiceMomentAction","JourneyChoiceMovingAction","JourneyWrapAction","JourneyShowOptionsAction","CareerMenuAction"]:
  var control: Button=find_child(name,true,false) as Button
  if control!=null:control.disabled=false
 for node in find_children("JourneyIncident_*","Button",true,false):
  (node as Button).disabled=false
 if str(Journey.active(game.career).get("phase",""))=="soundcheck":
  var action: Button=find_child("JourneyMainAction",true,false) as Button
  if action!=null:action.disabled=not bool(ShowFlow.check_plan(game.career,show_draft).get("ok",false))
 if is_visible_in_tree() and not _pending_focus.is_empty():
  call_deferred("_journey_restore_focus",_pending_focus,generation)


func _booking_session_needed() -> bool:
 var count: int=0;var drummer: bool=false
 for member in game.career.get("members",[]):
  if member is Dictionary and str(member.get("life_status","active"))=="active":
   count+=1
   if str(member.get("role","")).to_lower().contains("drum"):drummer=true
 return not (count>=2 and drummer)

func _sync_booking_draft() -> void:
 if not booking_draft.is_empty():return
 booking_expected=Booking.expected(game.career)
 var options: Dictionary=Booking.options(game.career)
 booking_draft={"venue_id":"local","day":int(options.get("first_day",0)),"offer_id":"standard","travel_plan":"drive_home","session_drummer":_booking_session_needed()}
 booking_step="rooms"

func _open_booking(origin: Dictionary = {}) -> void:
 if busy or receipt_open or is_instance_valid(_live_dialog):return
 booking_draft={}
 booking_expected={}
 booking_origin=origin.duplicate(true)
 _sync_booking_draft()
 page="gigs"
 notice=""
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _pending_focus="BookingVenue_local"
 _render()

func _booking_input_ready(generation: int) -> bool:
 return is_inside_tree() and is_visible_in_tree() and page=="gigs" and not receipt_open and not busy and not is_instance_valid(_live_dialog) and generation==_render_generation

func _booking_select(field: String,value: Variant,expected: Dictionary,generation: int) -> void:
 if not _booking_input_ready(generation) or expected!=booking_expected:return
 if expected!=Booking.expected(game.career):
  notice="The band changed. Review current rooms and dates."
  _render()
  return
 if field not in ["venue_id","day","offer_id","travel_plan","session_drummer"]:return
 if field=="venue_id" and (not value is String or not Booking.VENUES.has(value)):return
 if field=="day" and (not Booking.whole(value,1) or int(value)<int(game.career.get("tour_day",1))+3 or int(value)>int(game.career.get("tour_day",1))+14):return
 if field=="offer_id" and value not in ["standard","guarantee","guestlist"]:return
 if field=="travel_plan" and value not in ["drive_home","overnight"]:return
 if field=="session_drummer" and not value is bool:return
 booking_draft[field]=value
 if field=="venue_id":
  booking_draft["travel_plan"]="drive_home"
  booking_step="date"
 if booking_draft["venue_id"]!="local" or booking_draft["offer_id"]!="standard":booking_origin={}
 notice=""
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _pending_focus="BookingDay_%d" % int(booking_draft["day"]) if booking_step=="date" else "BookingReviewAction"
 _render()

func _booking_go(step: String,generation: int) -> void:
 if not _booking_input_ready(generation) or step not in ["trip","review"]:return
 var prepared: Dictionary=LiveRules.prepare_booking(game.career,booking_draft,booking_expected)
 if not bool(prepared.get("ok",false)):
  notice=str(prepared.get("message","Review the agreement."))
  _render()
  return
 booking_step=step
 notice=""
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _pending_focus="BookingTrip_"+str(booking_draft["travel_plan"]) if step=="trip" else "BookingCommitAction"
 _render()

func _booking_back(generation: int) -> void:
 if not _booking_input_ready(generation):return
 if booking_step=="rooms":
  _navigate("offstage" if not booking_origin.is_empty() else "home")
  return
 booking_step=str({"date":"rooms","trip":"date","review":"trip"}.get(booking_step,"rooms"))
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _render()

func _ask_booking_commit(generation: int) -> void:
 if not _booking_input_ready(generation):return
 var prepared: Dictionary=LiveRules.prepare_booking(game.career,booking_draft,booking_expected)
 if not bool(prepared.get("ok",false)):
  notice=str(prepared.get("message","Review the agreement."))
  _render()
  return
 var q: Dictionary=prepared["quote"]
 var dialog: Control=Kit.dialog("CONFIRM THIS SHOW?","%s in %s, DAY %d. The trip reserves %d career day(s); next available DAY %d. £0 now. Trip/session costs £%d at final wrap. The fee is settled after the show." % [q["venue"],q["city"],int(q["day"]),int(q["duration"]),int(q["next_available_day"]),int(q["total_cost"])],"flightcase")
 dialog.name="BookingConfirmDialog"
 dialog.set("confirm_text","BOOK THE SHOW")
 dialog.set("cancel_text","KEEP EDITING")
 var request: Dictionary=booking_draft.duplicate(true)
 var expected: Dictionary=booking_expected.duplicate(true)
 var origin: Dictionary=booking_origin.duplicate(true)
 _live_dialog=dialog
 dialog.completed.connect(func(accepted: bool):
  _live_dialog=null
  if is_instance_valid(dialog):dialog.queue_free()
  if accepted:_commit_booking(request,expected,origin,generation)
  else:call_deferred("_journey_restore_focus","BookingCommitAction",generation))
 add_child(dialog)
 (dialog.get("confirm_button") as Button).name="BookingConfirmAction"
 (dialog.get("cancel_button") as Button).name="BookingKeepEditingAction"
 dialog.call("open_modal")

func _commit_booking(request: Dictionary,expected: Dictionary,origin: Dictionary,generation: int) -> void:
 if not _booking_input_ready(generation):return
 busy=true
 var before: Dictionary=game.career.duplicate(true)
 if not origin.is_empty():
  var handoff: Dictionary=Offstage.booking_handoff(before,str(origin.get("event_id","")))
  if not bool(handoff.get("ok",false)) or Booking.fingerprint(origin)!=Booking.fingerprint(handoff.get("origin")):
   busy=false
   notice="The promoter introduction changed. Review it again before booking."
   _render()
   return
 var finance_action: String="live:book"
 var result: Dictionary=LiveRules.book_selected(before,request,expected)
 if bool(result.get("ok",false)) and not origin.is_empty():
  var attached: Dictionary=Offstage.attach_booking_acceptance(before,result["state"],origin)
  if bool(attached.get("ok",false)):
   result["state"]=attached["state"]
   finance_action=str(attached["finance_action"])
  else:result=attached
 if not bool(result.get("ok",false)):
  busy=false
  notice=str(result.get("message","The booking was retained for review."))
  _render()
  return
 var accounted: Dictionary=Finance.apply(before,result["state"],finance_action)
 if not bool(accounted.get("ok",false)):
  busy=false
  notice=str(accounted.get("message","The booking accounts could not be saved."))
  _render()
  return
 game.career=accounted["state"]
 if not bool(opening_owner.save_draft()):
  game.career=before
  busy=false
  notice="The booking could not be saved. The previous band and pending introduction are retained. Try again."
  _render()
  return
 booking_draft={}
 booking_expected={}
 booking_origin={}
 busy=false
 notice="BOOKING SAVED · "+str(result.get("message",""))
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _pending_focus="BookingPrepareAction"
 _render()

func _ask_booking_options(expected: Dictionary,generation: int,journey_expected: Dictionary = {}) -> void:
 if not _booking_input_ready(generation) or expected!=Booking.expected(game.career):return
 if _journey_finish_words():return
 var quote: Dictionary=LiveRules.cancellation_quote(game.career,expected,journey_expected)
 if not bool(quote.get("ok",false)):
  notice=str(quote.get("message","Review the current show agreement."))
  _render()
  return
 var dialog: Control=Kit.dialog("SHOW OPTIONS","Your place in the show is saved. Cancelling ends this booking and has consequences for the band.","flightcase")
 dialog.name="JourneyShowOptionsDialog"
 dialog.set("confirm_text","CANCEL THIS SHOW")
 dialog.set("cancel_text","BACK TO SHOW")
 _live_dialog=dialog
 dialog.completed.connect(func(cancel_requested: bool):
  _live_dialog=null
  if is_instance_valid(dialog):dialog.queue_free()
  if cancel_requested:_ask_booking_cancel(expected,journey_expected,generation)
  else:call_deferred("_journey_restore_focus","JourneyShowOptionsAction",generation))
 add_child(dialog)
 var danger: Button=dialog.get("confirm_button") as Button
 danger.name="JourneyCancelBookingOption"
 _journey_danger(danger)
 (dialog.get("cancel_button") as Button).name="JourneyShowOptionsCloseAction"
 dialog.call("open_modal")

func _ask_booking_cancel(expected: Dictionary,journey_expected: Dictionary,generation: int) -> void:
 if not _booking_input_ready(generation):return
 var quote: Dictionary=LiveRules.cancellation_quote(game.career,expected,journey_expected)
 if not bool(quote.get("ok",false)):
  notice=str(quote.get("message","The saved show changed."))
  _render()
  return
 var t: Dictionary=Booking.terms(game.career)
 var dialog: Control=Kit.dialog("CANCEL THIS SHOW?","%s · DAY %d. Cancelling now pays £%d from your current cash and uses %d career day(s). You will not play or receive the show fee. The promoter and band will remember this commitment. Unpaid quoted costs are waived; no debt is created." % [t["venue_snapshot"]["venue"],int(t["day"]),int(quote["total_paid"]),int(quote["days"])],"flightcase")
 dialog.name="JourneyConfirmDialog"
 dialog.set("confirm_text","CANCEL SHOW")
 dialog.set("cancel_text","KEEP BOOKING")
 _live_dialog=dialog
 dialog.completed.connect(func(accepted: bool):
  _live_dialog=null
  if is_instance_valid(dialog):dialog.queue_free()
  if accepted:_commit_booking_terminal("cancel",expected,journey_expected,generation)
  else:call_deferred("_journey_restore_focus","JourneyShowOptionsAction",generation))
 add_child(dialog)
 var danger: Button=dialog.get("confirm_button") as Button
 danger.name="JourneyConfirmCancelAction"
 _journey_danger(danger)
 (dialog.get("cancel_button") as Button).name="JourneyKeepBookingAction"
 dialog.call("open_modal")

func _commit_booking_terminal(action: String,expected: Dictionary,journey_expected: Dictionary,generation: int) -> void:
 if not _booking_input_ready(generation) or action not in ["cancel","expire"]:return
 busy=true
 var before: Dictionary=game.career.duplicate(true)
 var result: Dictionary=LiveRules.cancel_selected(before,expected,journey_expected) if action=="cancel" else LiveRules.expire_selected(before,expected)
 if not bool(result.get("ok",false)):
  busy=false
  notice=str(result.get("message","The saved agreement could not be closed."))
  _render()
  return
 var accounted: Dictionary=Finance.apply(before,result["state"],"live:cancel" if action=="cancel" else "live:expire",result.get("flows",[]),result.get("closing_balances",[]))
 if not bool(accounted.get("ok",false)):
  busy=false
  notice=str(accounted.get("message","The closing accounts need review."))
  _render()
  return
 game.career=accounted["state"]
 if not bool(opening_owner.save_draft()):
  game.career=before
  busy=false
  notice="The closed booking could not be saved. Your whole previous band and night are retained. Try again."
  _render()
  return
 receipt={"kind":"live","verb":action,"title":"BOOKING CANCELLED" if action=="cancel" else "MISSED COMMITMENT","text":str(result.get("message","The booking is closed.")),"day_before":int(before["tour_day"]),"day_after":int(game.career["tour_day"]),"cash_before":int(before["cash"]),"cash_after":int(game.career["cash"]),"terminal_receipt":result.get("terminal_receipt",{}),"changes":[]}
 for field in ["reputation","morale"]:
  if int(before.get(field,0))!=int(game.career.get(field,0)):receipt["changes"].append({"label":field.to_upper(),"before":int(before.get(field,0)),"after":int(game.career.get(field,0))})
 receipt_open=true
 _fresh_receipt=false
 busy=false
 notice=""
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _pending_focus="CareerReceiptContinueAction"
 _render()


func _ask_booking_missed(expected: Dictionary,generation: int) -> void:
 if not _booking_input_ready(generation):return
 var quote: Dictionary=Booking.expire_quote(game.career,expected)
 if not bool(quote.get("ok",false)):
  notice=str(quote.get("message","The missed agreement changed."))
  _render()
  return
 var t: Dictionary=Booking.terms(game.career)
 var dialog: Control=Kit.dialog("CLOSE THE MISSED BOOKING?","%s on DAY %d was missed. Closing this commitment now pays £%d from current cash and uses %d career day(s). No show fee is received. The promoter and band will remember this commitment." % [t["venue_snapshot"]["venue"],int(t["day"]),int(quote["total_paid"]),int(quote["days"])],"flightcase")
 dialog.name="BookingMissedConfirmDialog"
 dialog.set("confirm_text","CLOSE BOOKING")
 dialog.set("cancel_text","REVIEW AGAIN")
 _live_dialog=dialog
 dialog.completed.connect(func(accepted: bool):
  _live_dialog=null
  if is_instance_valid(dialog):dialog.queue_free()
  if accepted:_commit_booking_terminal("expire",expected,{},generation)
  else:call_deferred("_journey_restore_focus","BookingAcknowledgeMissedAction",generation))
 add_child(dialog)
 var danger: Button=dialog.get("confirm_button") as Button
 danger.name="BookingMissedConfirmAction"
 _journey_danger(danger)
 (dialog.get("cancel_button") as Button).name="BookingKeepMissedAction"
 dialog.call("open_modal")
