extends Control
## Existing career systems, current band, shared presentation and ONE owner save.
## Browsing/inspection never dispatches a model or writes a file.
signal practice_requested(activity: String)
signal menu_requested
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Bridge = preload("res://experiments/playable_flightcase/career_bridge.gd")
const Beat = preload("res://experiments/playable_flightcase/career_beat.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Songs = preload("res://Scripts/songbook_presentation.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
var game
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

func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 get_viewport().size_changed.connect(_render)
 visibility_changed.connect(_visibility_changed)
 _render()

func open_home() -> void:
 if busy:
  return
 page = "home"
 receipt_open = false
 catalogue_open = false
 notice = ""
 _scroll_position = 0
 show()
 _render()

func _visibility_changed() -> void:
 if not is_visible_in_tree():
  if is_instance_valid(_overlay):
   _overlay.abort()
   _overlay.queue_free()
  _overlay = null
  busy = false
  _fresh_receipt = false

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
 result.disabled = busy
 result.pressed.connect(action)
 return result

func _paper(parent: Node, compact: bool) -> VBoxContainer:
 var panel := PanelContainer.new()
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
 var focus: Control = get_viewport().gui_get_focus_owner()
 if not busy and is_instance_valid(focus) and is_ancestor_of(focus) and _pending_focus.is_empty():
  _pending_focus = str(focus.name)
 if is_instance_valid(_scroll):
  _scroll_position = _scroll.scroll_vertical
 for child in get_children():
  if is_instance_valid(_overlay) and child==_overlay:
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
 shell.add_child(nav)
 for entry in [["home","DESK"],["gear","SHOP"],["band","BAND"],["songs","SONGS"]]:
  var destination: String = str(entry[0])
  var option: Button = C.button(str(entry[1]),"flightcase","tab",true)
  option.name = "CareerNav_"+destination
  option.set_pressed_no_signal(page==destination and not receipt_open)
  option.disabled = busy
  option.pressed.connect(_navigate.bind(destination))
  nav.add_child(option)
 _scroll = ScrollContainer.new()
 _scroll.name = "CareerScroll"
 _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.follow_focus = true
 _scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
 _scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 shell.add_child(_scroll)
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
 elif page=="songs":
  _songs_page(body,compact)
 else:
  _home_page(body,compact)
 _decision_dock(shell,compact)
 _scroll.set_deferred("scroll_vertical",_scroll_position)
 if is_instance_valid(_overlay):
  move_child(_overlay,get_child_count()-1)
 elif not busy and is_visible_in_tree() and not _pending_focus.is_empty():
  call_deferred("_restore_focus",_pending_focus)

func _header(parent: Node) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",12)
 parent.add_child(row)
 row.add_child(C.brand(70.0 if size.y<800 and size.x>size.y else 80.0))
 var words := _box(2)
 words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(words)
 var name_label: Label = C.label(str(game.career.get("band_name","YOUR BAND")),18)
 name_label.name = "CareerBandName"
 name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 name_label.max_lines_visible = 2
 words.add_child(name_label)
 var funds: Label = C.label("DAY %d  •  £%d" % [int(game.career.get("tour_day",1)),int(game.career.get("cash",0))],16)
 funds.name = "CareerDayCash"
 words.add_child(funds)

func _navigate(destination: String) -> void:
 if busy or destination not in ["home","gear","band","songs"]:
  return
 page = destination
 receipt_open = false
 catalogue_open = false
 notice = ""
 _scroll_position = 0
 if is_instance_valid(_scroll):
  _scroll.scroll_vertical = 0
 _pending_focus = "CareerNav_"+destination
 _render()

func _restore_focus(control_name: String) -> void:
 if busy or not is_visible_in_tree():
  return
 var target: Control = find_child(control_name,true,false) as Control
 if target!=null and target.is_visible_in_tree() and target.focus_mode!=Control.FOCUS_NONE:
  target.grab_focus()
  if is_instance_valid(_scroll) and _scroll.is_ancestor_of(target):
   _scroll.ensure_control_visible(target)
 _pending_focus = ""

func _home_page(parent: Node, compact: bool) -> void:
 var body := _paper(parent,compact)
 _copy(body,"YOUR CAREER DESK",26)
 _copy(body,str(game.genre).to_upper()+"  /  "+str(game.career.get("vibe","Unpolished")),14,true)
 _copy(body,"Plan the next move. Your band, songs and equipment stay together.",16)
 var grid := GridContainer.new()
 grid.columns = 1 if compact else 2
 grid.add_theme_constant_override("h_separation",20)
 grid.add_theme_constant_override("v_separation",8)
 body.add_child(grid)
 for entry in [["READINESS","readiness"],["BAND MORALE","morale"],["TENSION","tension"]]:
  var block := _box(2)
  grid.add_child(block)
  _copy(block,str(entry[0]),13,true)
  block.add_child(C.meter(int(game.career.get(str(entry[1]),0)),"notepaper"))
 _copy(body,"%d FINISHED ORIGINALS  •  %d FANS" % [int(game.career.get("songs",0)),int(game.career.get("fans",0))],16)
 var practice := _button("THE PRACTICE ROOM  ›","CareerHomePracticeAction",_practice.bind(""),true)
 body.add_child(practice)
 var routes := GridContainer.new()
 routes.columns = 2 if compact else 3
 routes.add_theme_constant_override("h_separation",8)
 routes.add_theme_constant_override("v_separation",8)
 body.add_child(routes)
 for entry in [["THE MUSIC SHOP","gear"],["MEET YOUR BAND","band"],["YOUR SONGBOOK","songs"]]:
  routes.add_child(_button(str(entry[0])+"  ›","CareerHome_"+str(entry[1]),_navigate.bind(str(entry[1]))))
 # Put the next decisions before the status detail on the phone.
 body.move_child(practice,3)
 body.move_child(routes,4)

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
  _catalogue(list,compact)
 if compact and catalogue_open:
  _catalogue(parent,compact)
  return
 var body := _paper(dossier_parent,compact)
 var index := 0
 for n in range(Gear.ITEMS.size()):
  if str(Gear.ITEMS[n]["id"])==selected_item:
   index = n
 var browse := HBoxContainer.new()
 browse.add_theme_constant_override("separation",6)
 body.add_child(browse)
 var previous := _button("‹","GearPreviousAction",_step_item.bind(-1))
 previous.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 browse.add_child(previous)
 var chooser := _button("%d / %d  •  CATALOGUE" % [index+1,Gear.ITEMS.size()],"GearCatalogueAction",_toggle_catalogue)
 browse.add_child(chooser)
 var following := _button("›","GearNextAction",_step_item.bind(1))
 following.size_flags_horizontal = Control.SIZE_SHRINK_END
 browse.add_child(following)
 var item: Dictionary = Gear.item_for(selected_item)
 var title := _copy(body,str(item["name"]),24)
 title.name = "GearItemTitle"
 _copy(body,str(item["type"]),13,true)
 _copy(body,str(item["description"]),16)
 _copy(body,"£%d ASKING PRICE  •  +%d READINESS ON PURCHASE" % [int(item["price"]),int(item["readiness"])],14,true)
 var owned: bool = (game.career.get("owned_equipment",[]) as Array).has(selected_item)
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
  _copy(body,"SECOND-HAND CONDITION  /  %d / 100" % int(item["condition"]),16)
  _copy(body,"Choose your purchase when ready. Browsing is free.",14,true)
 if not notice.is_empty():
  _copy(body,notice,16)
 if owned:
  _road_cases(dossier_parent,compact)

func _catalogue(parent: Node, compact: bool) -> void:
 var body := _paper(parent,compact)
 _copy(body,"EQUIPMENT CATALOGUE",21)
 _copy(body,"Choose an item to inspect. No time or money is spent.",14,true)
 for item in Gear.ITEMS:
  var id: String = str(item["id"])
  var owned: bool = (game.career.get("owned_equipment",[]) as Array).has(id)
  var text: String = ("✓ " if id==selected_item else "")+str(item["name"])+("  •  OWNED" if owned else "  •  £%d" % int(item["price"]))
  var action := _button(text,"GearChoice_"+id,_choose_item.bind(id))
  action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  action.tooltip_text = str(item["name"])+" — "+str(item["description"])
  body.add_child(action)

func _choose_item(id: String) -> void:
 if busy or Gear.item_for(id).is_empty():
  return
 selected_item = id
 catalogue_open = false
 notice = ""
 _scroll_position = 0
 if is_instance_valid(_scroll): _scroll.scroll_vertical = 0
 _pending_focus = "GearCatalogueAction" if size.x<840 or size.x<size.y else "GearChoice_"+id
 _render()

func _step_item(delta: int) -> void:
 if busy:
  return
 var index := 0
 for n in range(Gear.ITEMS.size()):
  if str(Gear.ITEMS[n]["id"])==selected_item: index=n
 var next_index := posmod(index+delta,Gear.ITEMS.size())
 selected_item = str(Gear.ITEMS[next_index]["id"])
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
 var body := _paper(parent,compact)
 _copy(body,"THE ROAD CASE",21)
 var owned: Array = game.career.get("owned_equipment",[])
 if owned.is_empty():
  _copy(body,"No shop purchases yet. The band's personal instruments are not tracked here.",16,true)
 for id in owned:
  var record: Dictionary = Gear.record(game.career,str(id))
  var holder: int = Gear.holder_index(game.career,record)
  var members: Array = game.career.get("members",[])
  var person: String = str(members[holder].get("name","Musician")) if holder>=0 else "Shared case"
  var condition: int = int(record.get("condition",-1))
  _copy(body,str(Gear.item_for(str(id)).get("name",id)),16)
  _copy(body,person+"  •  "+("Condition unknown" if condition<0 else "Condition %d / 100" % condition),14,true)

func _band_page(parent: Node, compact: bool) -> void:
 var body := _paper(parent,compact)
 _copy(body,"THE PEOPLE IN YOUR BAND",24)
 var members: Array = game.career.get("members",[])
 for index in range(members.size()):
  var person: Dictionary = members[index]
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",12)
  body.add_child(row)
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
   body.add_child(values)
   var label := _copy(values,str(stat[0]),13,true)
   label.custom_minimum_size.x=68
   label.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
   var meter := C.meter(int(person.get(str(stat[1]),0)),"notepaper")
   meter.name = "CareerMemberStat_"+str(index)+"_"+str(stat[1])
   values.add_child(meter)
  _copy(body," ",8)
 _road_cases(parent,compact)

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
  dock.add_child(_button("BACK TO THE MUSIC SHOP  ›","CareerReceiptContinueAction",_close_receipt,true))
 elif page=="gear":
  if compact and catalogue_open:
   dock.add_child(_button("BACK TO SELECTED ITEM","GearCloseCatalogueAction",_toggle_catalogue))
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
 navigation.add_theme_constant_override("separation",8)
 dock.add_child(navigation)
 navigation.add_child(_button("‹ PRACTICE","CareerPracticeAction",_practice.bind("")))
 navigation.add_child(_button("MAIN MENU","CareerMenuAction",_menu))

func _commit_gear(verb: String, member_index: int = -1) -> void:
 if busy or receipt_open or game==null or opening_owner==null:
  return
 busy = true
 var before: Dictionary = game.career.duplicate(true)
 var result: Dictionary = Bridge.gear_action(before,verb,selected_item,member_index)
 if not bool(result.get("ok",false)):
  busy=false
  notice=str(result.get("message","Action unavailable."))
  _render()
  return
 game.career = result["state"]
 if not bool(opening_owner.save_draft()):
  game.career=before
  busy=false
  notice="The change could not be saved. Your previous band state is retained."
  _render()
  return
 var after: Dictionary = game.career
 receipt={"verb":verb,"item":selected_item,"item_name":str(Gear.item_for(selected_item).get("name",selected_item)),"text":str(result.get("message","Saved.")),"day_before":int(before.get("tour_day",1)),"day_after":int(after.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(after.get("cash",0)),"readiness_before":int(before.get("readiness",0)),"readiness_after":int(after.get("readiness",0))}
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
 _pending_focus="CareerReceiptNote"
 _render()
 var note: Label = find_child("CareerReceiptNote",true,false) as Label
 if note!=null and _fresh_receipt:
  note.call_deferred("begin",reduced_motion)
 _fresh_receipt=false

func _receipt_page(parent: Node, compact: bool) -> void:
 var body := _paper(parent,compact)
 _copy(body,"THE MUSIC SHOP RECORD",16,true)
 _copy(body,str(receipt.get("item_name","EQUIPMENT")),25)
 _copy(body,"DAY %d → %d   •   £%d → £%d" % [int(receipt.get("day_before",1)),int(receipt.get("day_after",1)),int(receipt.get("cash_before",0)),int(receipt.get("cash_after",0))],16,true)
 var note: Label = Ink.new()
 note.name="CareerReceiptNote"
 note.text=str(receipt.get("text","Saved."))
 note.add_theme_font_size_override("font_size",16)
 note.add_theme_color_override("font_color",Color("29241f"))
 if _fresh_receipt:note.visible_characters=0
 body.add_child(note)
 var record: Dictionary = Gear.record(game.career,str(receipt.get("item","")))
 if not record.is_empty():
  var condition: int = int(record.get("condition",-1))
  _copy(body,"CONDITION  /  "+("UNKNOWN" if condition<0 else "%d / 100" % condition),18)
  _copy(body,str(record.get("provenance","")),14,true)
 _copy(body,"READINESS  %d → %d" % [int(receipt.get("readiness_before",0)),int(receipt.get("readiness_after",0))],16)

func _close_receipt() -> void:
 if busy:return
 receipt_open=false
 _fresh_receipt=false
 _pending_focus="GearCatalogueAction"
 _scroll_position=0
 if is_instance_valid(_scroll):_scroll.scroll_vertical=0
 _render()

func _practice(activity: String) -> void:
 if not busy:practice_requested.emit(activity)

func _menu() -> void:
 if not busy:menu_requested.emit()
