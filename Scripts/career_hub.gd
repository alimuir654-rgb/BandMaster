extends Control

const UI = preload("res://Scripts/ui_theme.gd")
const Actions = preload("res://Scripts/career_actions.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Members = preload("res://Scripts/member_management.gd")
const SAVE_PATH := "user://tour_save.json"
const TABS := ["HOME","GIGS","GEAR","BAND","ACTIONS","SCENE"]
const ART := {
 "HOME":"res://Art/uk_street_banner.svg",
 "GIGS":"res://Art/uk_gigs_banner.svg",
 "GEAR":"res://Art/uk_gear_banner.svg",
 "BAND":"res://Art/uk_band_banner.svg",
 "ACTIONS":"res://Art/uk_actions_banner.svg",
 "SCENE":"res://Art/uk_scene_banner.svg"
}
var save_data: Dictionary = {}
var tab := "HOME"
var message := ""
var content: VBoxContainer

func _ready() -> void:
 _load()
 _render()

func _load() -> void:
 if not FileAccess.file_exists(SAVE_PATH):
  push_error("CareerHub requires a career save.")
  return
 var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
 if file == null:
  return
 var parsed = JSON.parse_string(file.get_as_text())
 file.close()
 if parsed is Dictionary:
  save_data = parsed
 if not save_data.has("career_extra") or not save_data["career_extra"] is Dictionary:
  save_data["career_extra"] = {}
 if not save_data.has("band") or not save_data["band"] is Dictionary:
  save_data["band"] = {"name":"The Feedback","members":[]}
 var extra: Dictionary = save_data["career_extra"]
 for key in ["songs","fans","gear","buzz","press","demos"]:
  if not extra.has(key):
   extra[key] = 0
 for key in ["opportunities_seen","opportunities_resolved","action_counters"]:
  if not extra.has(key):
   extra[key] = {}
 for key in ["owned_equipment","gig_history"]:
  if not extra.has(key):
   extra[key] = []

func _save() -> void:
 if save_data.is_empty():
  return
 save_data["current_event"] = "aftershow"
 save_data["pending_next"] = ""
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  push_error("Cannot save career")
  return
 file.store_string(JSON.stringify(save_data,"\t"))
 file.close()

func _extra() -> Dictionary:
 return save_data.get("career_extra",{})

func _num(key: String) -> int:
 if _extra().has(key):
  return int(_extra().get(key,0))
 return int(save_data.get(key,0))

func _label(parent: Node, value: String, size: int = 17, colour: Color = UI.WHITE) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",colour)
 parent.add_child(label)
 return label

func _card(title: String, description: String = "") -> VBoxContainer:
 var frame := PanelContainer.new()
 frame.add_theme_stylebox_override("panel",UI.style(UI.PANEL))
 content.add_child(frame)
 var body := VBoxContainer.new()
 body.add_theme_constant_override("separation",9)
 frame.add_child(body)
 _label(body,title,19,UI.AMBER)
 if not description.is_empty():
  _label(body,description,15,UI.WHITE)
 return body

func _action(parent: Node, name: String, callback: Callable, primary: bool = false) -> void:
 var button := UI.button(name,primary)
 parent.add_child(button)
 button.pressed.connect(callback)

func _progress(parent: Node, name: String, value: int, maximum: int = 100) -> void:
 var row := HBoxContainer.new()
 parent.add_child(row)
 var label := _label(row,name + "  %d" % value,13,UI.MUTED)
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var bar := ProgressBar.new()
 bar.custom_minimum_size = Vector2(165,20)
 bar.max_value = maxi(1,maximum)
 bar.value = clampi(value,0,int(bar.max_value))
 bar.show_percentage = false
 row.add_child(bar)

func _render() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var background := ColorRect.new()
 background.color = UI.BG
 add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroll := ScrollContainer.new()
 add_child(scroll)
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.offset_bottom = -94
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 var margin := MarginContainer.new()
 margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 margin.add_theme_constant_override("margin_left",18)
 margin.add_theme_constant_override("margin_right",18)
 margin.add_theme_constant_override("margin_top",18)
 margin.add_theme_constant_override("margin_bottom",24)
 scroll.add_child(margin)
 content = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",14)
 margin.add_child(content)
 _header()
 _hero()
 if not message.is_empty():
  _card("LATEST ACTIVITY",message)
 match tab:
  "HOME": _home()
  "GIGS": _gigs()
  "GEAR": _gear()
  "BAND": _band()
  "ACTIONS": _actions()
  "SCENE": _scene()
 _action(content,"SAVE & MAIN MENU",_menu)
 _bottom_nav()

func _header() -> void:
 _label(content,"LIVIN' THE DREAM   /   BRITISH GRASSROOTS",12,UI.AMBER)
 var row := HBoxContainer.new()
 content.add_child(row)
 var band_data: Dictionary = save_data.get("band",{})
 var title := _label(row,str(band_data.get("name","Unknown Band")),27)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.size_flags_stretch_ratio = 4
 var day := _label(row,"DAY %d" % _num("tour_day"),15,UI.AMBER)
 day.size_flags_horizontal = Control.SIZE_SHRINK_END
 var stats := GridContainer.new()
 stats.columns = 3
 content.add_child(stats)
 for entry in ["CASH £%d" % _num("cash"),"FANS %d" % _num("fans"),"REP %d" % _num("reputation")]:
  var panel := PanelContainer.new()
  panel.add_theme_stylebox_override("panel",UI.style(UI.ALT,10))
  panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  stats.add_child(panel)
  _label(panel,entry,14,UI.WHITE)

func _hero() -> void:
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",UI.style(UI.ALT))
 content.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",8)
 panel.add_child(stack)
 var image_path: String = str(ART.get(tab,""))
 if ResourceLoader.exists(image_path):
  var picture := TextureRect.new()
  picture.texture = load(image_path)
  picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  picture.custom_minimum_size.y = 200
  picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
  stack.add_child(picture)
 _label(stack,tab + "  /  THE UK INDEPENDENT SCENE",20,UI.WHITE)

func _home() -> void:
 var fans := _num("fans")
 var rep := _num("reputation")
 var missing: Dictionary = {}
 for venue in Gigs.VENUES:
  if fans < int(venue["min_fans"]) or rep < int(venue["min_rep"]):
   missing = venue
   break
 if not missing.is_empty():
  var body := _card("NEXT: " + str(missing["city"]),
   "Unlock %s: %d more fans, %d more reputation." % [str(missing["venue"]),maxi(0,int(missing["min_fans"])-fans),maxi(0,int(missing["min_rep"])-rep)])
  _action(body,"BOOK A HOMETOWN GIG",func() -> void: _switch("GIGS"),true)
 else:
  _card("REGIONAL CIRCUIT UNLOCKED","All current UK venues are available.")
 _opportunities()
 var pulse := _card("BAND PULSE","Your next show depends on preparation and morale.")
 for key in ["readiness","morale","van_health"]:
  _progress(pulse,key.to_upper().replace("_"," "),_num(key))
 var quick := _card("NEXT MOVES","Choose how to spend the day.")
 _action(quick,"BOOK A GIG",func() -> void: _switch("GIGS"),true)
 _action(quick,"WRITE A SONG",func() -> void: _do_action("songwrite"))
 _action(quick,"REHEARSE — £15",func() -> void: _do_action("rehearse"))

func _gigs() -> void:
 var summary := _card("BOOK A BRITISH GIG","Decide on a performance style. Travel costs and van wear still apply.")
 _progress(summary,"VAN",_num("van_health"))
 for venue in Gigs.VENUES:
  var key: String = str(venue["id"])
  if _num("fans") < int(venue["min_fans"]) or _num("reputation") < int(venue["min_rep"]):
   _card(str(venue["city"]) + "  /  LOCKED","Need %d fans and %d reputation." % [int(venue["min_fans"]),int(venue["min_rep"])])
   continue
  var box := _card(str(venue["venue"]) + "  /  " + str(venue["city"]),"Fee £%d  ·  Travel £%d" % [int(venue["fee"]),int(venue["travel"])])
  _action(box,"TIGHT SET",func() -> void: _book(key,"tight"),true)
  _action(box,"WILD SET",func() -> void: _book(key,"wild"))
  _action(box,"WIN THE CROWD",func() -> void: _book(key,"crowd"))
 _action(content,"REPAIR VAN — £45",_repair)

func _gear() -> void:
 var owned: Array = _extra().get("owned_equipment",[])
 _card("OWNED EQUIPMENT","%d pieces bought." % owned.size())
 for item in Gear.ITEMS:
  var key: String = str(item["id"])
  var box := _card(str(item["name"]),str(item["description"]))
  if owned.has(key):
   _label(box,"OWNED",14,UI.AMBER)
  else:
   _action(box,"BUY  £%d" % int(item["price"]),func() -> void: _buy(key),true)

func _band() -> void:
 var band_data: Dictionary = save_data.get("band",{})
 var members: Array = band_data.get("members",[])
 if members.is_empty():
  _card("THE BAND","No musicians recorded.")
 for i in range(members.size()):
  if not members[i] is Dictionary:
   continue
  var member: Dictionary = members[i]
  var index := i
  var box := _card(str(member.get("name","Musician")) + "  /  " + str(member.get("role","")) ,str(member.get("trait","")))
  for key in ["skill","morale","loyalty","fatigue"]:
   _progress(box,key.to_upper(),int(member.get(key,50)))
  _action(box,"TALK",func() -> void: _member(index,"chat"),true)
  _action(box,"COACH — £10",func() -> void: _member(index,"coach"))
  _action(box,"GIVE A BREAK",func() -> void: _member(index,"break"))

func _actions() -> void:
 for key in Actions.labels().keys():
  var id: String = str(key)
  var cfg: Dictionary = Actions.labels()[id]
  var box := _card(str(cfg["label"]),"£%d  /  one day" % int(cfg.get("cost",0)))
  _action(box,"DO THIS",func() -> void: _do_action(id),true)

func _scene() -> void:
 _opportunities()
 var box := _card("LOCAL PRESS","Build a following through promotion and publicity.")
 _progress(box,"BUZZ",_num("buzz"))
 _progress(box,"PRESS",_num("press"))
 _action(box,"PRINT POSTERS — £25",func() -> void: _do_action("promo"),true)
 _action(box,"PITCH LOCAL PRESS — £10",func() -> void: _do_action("press"))

func _opportunities() -> void:
 for event_id in Opportunities.pending(_extra()):
  var id: String = str(event_id)
  var event: Dictionary = Opportunities.get_event(id)
  var box := _card(str(event.get("title","OPPORTUNITY")),str(event.get("intro","")))
  for choice in event.get("choices",[]):
   var choice_id: String = str(choice.get("id",""))
   _action(box,str(choice.get("label","CHOOSE")),func() -> void: _choose(id,choice_id),true)

func _bottom_nav() -> void:
 var panel := PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 panel.offset_top = -90
 panel.add_theme_stylebox_override("panel",UI.style(UI.PANEL,0))
 add_child(panel)
 var bar := GridContainer.new()
 bar.columns = 6
 bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_child(bar)
 for tab_id in TABS:
  var target: String = tab_id
  var button := UI.button(target,target == tab)
  button.custom_minimum_size.y = 60
  button.add_theme_font_size_override("font_size",12)
  bar.add_child(button)
  button.pressed.connect(func() -> void: _switch(target))

func _switch(next_tab: String) -> void:
 tab = next_tab
 _render()

func _state() -> Dictionary:
 var state: Dictionary = _extra().duplicate(true)
 for key in ["cash","tour_day","morale","reputation","readiness","tension","van_health"]:
  state[key] = _num(key)
 state["band_name"] = str(save_data.get("band",{}).get("name","The Band"))
 state["members"] = save_data.get("band",{}).get("members",[]).duplicate(true)
 state["relationships"] = save_data.get("relationships",{}).duplicate(true)
 return state

func _apply(updated: Dictionary) -> void:
 for key in ["cash","tour_day","morale","reputation","readiness","tension","van_health"]:
  if updated.has(key):
   save_data[key] = updated[key]
 if updated.has("members"):
  var band_data: Dictionary = save_data["band"]
  band_data["members"] = updated["members"]
 if updated.has("relationships"):
  save_data["relationships"] = updated["relationships"]
 var extra: Dictionary = _extra()
 for key in updated.keys():
  if not ["cash","tour_day","morale","reputation","readiness","tension","van_health","members","relationships","band_name"].has(key):
   extra[key] = updated[key]

func _finish(result: Dictionary) -> void:
 message = str(result.get("message","Action unavailable"))
 if result.get("ok",false) == true:
  _apply(result["state"])
  _save()
 _render()

func _do_action(id: String) -> void:
 _finish(Actions.resolve(_state(),id))

func _book(id: String,approach: String) -> void:
 _finish(Gigs.play(_state(),id,approach))

func _buy(id: String) -> void:
 _finish(Gear.buy(_state(),id))

func _member(index: int, action: String) -> void:
 _finish(Members.resolve(_state(),index,action))

func _choose(event_id: String,choice_id: String) -> void:
 _finish(Opportunities.resolve(_state(),event_id,choice_id))

func _repair() -> void:
 if _num("cash") < 45:
  message = "You need £45 to repair the van."
  _render()
  return
 save_data["cash"] = _num("cash") - 45
 save_data["tour_day"] = _num("tour_day") + 1
 save_data["van_health"] = mini(100,_num("van_health") + 30)
 message = "The garage gets the van back on the road."
 _save()
 _render()

func _menu() -> void:
 _save()
 get_tree().change_scene_to_file("res://main_menu.tscn")
