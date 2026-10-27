extends Control
## Owner-approved composition experiment. All state local, no FileAccess/DirAccess.
const Model = preload("res://Scripts/recruitment_catalogue_v3.gd")
const Formation = preload("res://Scripts/formation_catalogue.gd")
const Portrait = preload("res://Scripts/member_portrait.gd")
const Meter = preload("res://poc/ldtd_recruitment_meter.gd")
const C_BG := Color("#0E1014")
const C_PANEL := Color("#1A1E23")
const C_SOFT := Color("#272B30")
const C_LINE := Color("#49484A")
const C_GOLD := Color("#EFBB60")
const C_WHITE := Color("#F5F2EA")
const C_MUTED := Color("#B4B3B0")
const C_PAPER := Color("#E8DDCB")
const C_INK := Color("#302924")

var step: int = 0
var genre: String = "Indie rock"
var role: String = "Singer"
var candidate_index: int = 0
var roster: Array = []
var band_name: String = ""
var completed: bool = false
var _wide: bool = true
var _current: Dictionary = {}
var _body_scroll: ScrollContainer
var _footer: VBoxContainer
var _name_entry: LineEdit

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _wide = get_viewport_rect().size.x >= 900.0
 get_viewport().size_changed.connect(_viewport_changed)
 _render()

func _viewport_changed() -> void:
 var wide_now := get_viewport_rect().size.x >= 900.0
 if wide_now != _wide:
  _wide = wide_now
  _render()

func _touch_factor() -> float:
 # Godot mobile canvas scaling can make a 50-unit button <44 physical pixels.
 # Scale hit targets and native lettering by actual window-to-logical ratio.
 var win := DisplayServer.window_get_size()
 return clampf(get_viewport_rect().size.x / float(maxi(win.x,1)),1.0,2.2)

func _minimum_hit_height(proposed: float) -> float:
 return maxf(proposed,ceilf(47.0*_touch_factor()))

func _style(fill: Color, radius: int=8, stroke: Color=C_LINE) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color=fill
 s.set_corner_radius_all(radius)
 s.set_border_width_all(1)
 s.border_color=stroke
 s.set_content_margin_all(9)
 return s

func _label(parent: Node, s: String, font_size: int=15, colour: Color=C_WHITE, wrap: bool=false) -> Label:
 var l := Label.new()
 l.text=s
 l.add_theme_color_override("font_color",colour)
 l.add_theme_font_size_override("font_size",maxi(font_size,ceili(float(font_size)*minf(_touch_factor(),1.5))))
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
 parent.add_child(l)
 return l

func _button(parent: Node, s: String, action: Callable, selected: bool=false, disabled: bool=false, height: float=50.0) -> Button:
 var b := Button.new()
 b.text=s
 b.custom_minimum_size.y=_minimum_hit_height(height)
 b.focus_mode=Control.FOCUS_ALL
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.disabled=disabled
 var fill := C_GOLD if selected else C_SOFT
 var fg := C_INK if selected else C_WHITE
 b.add_theme_stylebox_override("normal",_style(fill,6,C_GOLD if selected else C_LINE))
 b.add_theme_stylebox_override("hover",_style(fill.lightened(0.08),6,C_GOLD))
 b.add_theme_stylebox_override("pressed",_style(fill.darkened(0.12),6,C_GOLD))
 b.add_theme_stylebox_override("disabled",_style(Color("#1A1D21"),6,Color("#30353A")))
 var focus := _style(Color.TRANSPARENT,6,C_GOLD)
 focus.set_border_width_all(2)
 b.add_theme_stylebox_override("focus",focus)
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
  b.add_theme_color_override(key,fg)
 b.add_theme_color_override("font_disabled_color",Color("#777E84"))
 b.add_theme_font_size_override("font_size",maxi(14,ceili(14.0*minf(_touch_factor(),1.65))))
 b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 b.pressed.connect(action)
 parent.add_child(b)
 return b

func _panel(parent: Node, fill: Color=C_PANEL, minimum: Vector2=Vector2.ZERO) -> VBoxContainer:
 var wrapper := PanelContainer.new()
 wrapper.add_theme_stylebox_override("panel",_style(fill,8))
 wrapper.custom_minimum_size=minimum
 wrapper.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(wrapper)
 var inner := VBoxContainer.new()
 inner.add_theme_constant_override("separation",8)
 wrapper.add_child(inner)
 return inner

func _transport(parent: Node, caption: String, action: Callable) -> TextureButton:
 var wrap := VBoxContainer.new()
 wrap.custom_minimum_size.x=80
 parent.add_child(wrap)
 var b := TextureButton.new()
 b.toggle_mode=false
 b.focus_mode=Control.FOCUS_ALL
 b.ignore_texture_size=true
 b.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
 b.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 b.flip_h=caption=="PREVIOUS"
 b.custom_minimum_size=Vector2(maxf(76.0,ceilf(58.0*_touch_factor())),_minimum_hit_height(53.0))
 var base := "res://bandmaster_premium_controls_lab/assets/transport_studio_"
 b.texture_normal=load(base+"idle.png")
 b.texture_hover=load(base+"hover.png")
 b.texture_pressed=load(base+"pressed.png")
 b.texture_disabled=load(base+"disabled.png")
 b.pressed.connect(action)
 wrap.add_child(b)
 var txt := _label(wrap,caption,11,C_MUTED)
 txt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 return b

func _render() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var bg := ColorRect.new()
 bg.color=C_BG
 bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var bounds := MarginContainer.new()
 bounds.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var padding := 18 if _wide else 10
 for side in ["left","right","top","bottom"]:
  bounds.add_theme_constant_override("margin_"+side,padding)
 add_child(bounds)
 var page := VBoxContainer.new()
 page.add_theme_constant_override("separation",10)
 bounds.add_child(page)
 _header(page)
 _body_scroll=ScrollContainer.new()
 _body_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _body_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 page.add_child(_body_scroll)
 var body := VBoxContainer.new()
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",12)
 _body_scroll.add_child(body)
 match step:
  0: _choose_genre(body)
  1: _recruitment(body)
  _: _name_step(body)
 _build_footer(page)

func _header(parent: Node) -> void:
 var top := HBoxContainer.new()
 top.add_theme_constant_override("separation",12)
 parent.add_child(top)
 var words := VBoxContainer.new()
 words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 top.add_child(words)
 _label(words,"LIVIN' THE DREAM  /  NEW BAND",12,C_GOLD)
 _label(words,["01  FIND YOUR SOUND","02  RECRUIT YOUR MUSICIANS","03  GIVE THE BAND A NAME"][step],23 if _wide else 19,C_WHITE)
 var step_text := _label(top,"%d / 3" % (step+1),13,C_MUTED)
 step_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var line := HSeparator.new()
 parent.add_child(line)

func _choose_genre(parent: Node) -> void:
 var intro := _panel(parent)
 _label(intro,"Choose your genre before meeting the musicians.",18,C_WHITE,true)
 _label(intro,"Different scenes attract different people. The singer who fits punk may not be the one you meet in synth-pop.",14,C_MUTED,true)
 var wrap := GridContainer.new()
 wrap.columns=3 if _wide else 2
 wrap.add_theme_constant_override("h_separation",10)
 wrap.add_theme_constant_override("v_separation",10)
 parent.add_child(wrap)
 for entry in Model.genres():
  var value := str(entry)
  var btn := _button(wrap,value,func() -> void: _select_genre(value),value==genre,false,60)
  btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var description := _panel(parent)
 _label(description,str(Formation.GENRES[genre]["description"]),17,C_WHITE,true)
 _label(description,"STRENGTH  "+str(Formation.GENRES[genre]["strength"]),13,C_GOLD)
 _label(description,"TRADE-OFF  "+str(Formation.GENRES[genre]["challenge"]),13,C_MUTED)

func _select_genre(value: String) -> void:
 if value == genre:
  return
 if not roster.is_empty():
  # Going back after recruitment is destructive; require explicit confirmation.
  var dialog := ConfirmationDialog.new()
  dialog.title="Changing genre will reset the lineup"
  dialog.dialog_text="Choosing a new scene clears musicians already selected. Continue?"
  add_child(dialog)
  dialog.confirmed.connect(func() -> void:
   genre=value
   roster.clear()
   candidate_index=0
   role="Singer"
   _render()
  )
  dialog.canceled.connect(dialog.queue_free)
  dialog.confirmed.connect(dialog.queue_free)
  dialog.popup_centered()
  return
 genre=value
 candidate_index=0
 role="Singer"
 _render()

func _set_role(value: String) -> void:
 if not Model.ROLE_TABS.has(value):
  return
 role=value
 candidate_index=0
 _render()

func _pool() -> Array:
 return Model.pool(genre,role)

func _selected() -> Dictionary:
 var candidates := _pool()
 if candidates.is_empty():
  return {}
 candidate_index=posmod(candidate_index,candidates.size())
 return candidates[candidate_index]

func _move_candidate(delta: int) -> void:
 var candidates := _pool()
 if candidates.is_empty():
  return
 candidate_index=posmod(candidate_index+delta,candidates.size())
 _render()

func _recruitment(parent: Node) -> void:
 var top := HBoxContainer.new()
 parent.add_child(top)
 var g := _label(top,genre.to_upper()+"  /  "+str(roster.size())+" RECRUITED",14,C_GOLD)
 g.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var tabs_scroll := ScrollContainer.new()
 tabs_scroll.custom_minimum_size.y=_minimum_hit_height(60.0)+10.0
 tabs_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 tabs_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 parent.add_child(tabs_scroll)
 var tabs := HBoxContainer.new()
 tabs.add_theme_constant_override("separation",7)
 tabs_scroll.add_child(tabs)
 for r in Model.ROLE_TABS:
  var selected_role := str(r)
  _button(tabs,str(r).to_upper()+"S",func() -> void: _set_role(selected_role),role==selected_role,false,49).custom_minimum_size.x=110
 _current=_selected()
 if _current.is_empty():
  _label(parent,"No candidates for this role in this genre.",16,C_WHITE)
  return
 var nav := HBoxContainer.new()
 nav.add_theme_constant_override("separation",10)
 parent.add_child(nav)
 _transport(nav,"PREVIOUS",func() -> void: _move_candidate(-1))
 var head := VBoxContainer.new()
 head.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 head.alignment=BoxContainer.ALIGNMENT_CENTER
 nav.add_child(head)
 _label(head,"%d OF 6   •   %s" % [candidate_index+1,role.to_upper()],12,C_MUTED)
 _label(head,str(_current["name"]),23 if _wide else 20,C_WHITE)
 var subroles: Array=_current["roles"]
 _label(head," / ".join(PackedStringArray(subroles))+"  •  "+str(_current["town"]),12,C_GOLD)
 _transport(nav,"NEXT",func() -> void: _move_candidate(1))
 var content: BoxContainer = HBoxContainer.new() if _wide else VBoxContainer.new()
 content.add_theme_constant_override("separation",12)
 parent.add_child(content)
 if _wide:
  _candidate_rail(content)
 _portrait_and_stats(content)
 _character_notes(content)

func _candidate_rail(parent: Node) -> void:
 var rail := _panel(parent,C_PANEL,Vector2(166,0))
 rail.get_parent().size_flags_horizontal=0
 for i in range(6):
  var p: Dictionary=_pool()[i]
  var chosen := candidate_index==i
  _button(rail,("● " if Model.contains(roster,str(p["id"])) else "")+str(p["name"]),func() -> void: _choose_index(i),chosen,false,60)

func _choose_index(index: int) -> void:
 candidate_index=index
 _render()

func _portrait_and_stats(parent: Node) -> void:
 var center := _panel(parent,C_PANEL,Vector2(350,0) if _wide else Vector2.ZERO)
 center.get_parent().size_flags_stretch_ratio=1.5
 var portrait_box := PanelContainer.new()
 portrait_box.custom_minimum_size.y=310.0 if _wide else maxf(175.0,185.0*_touch_factor())
 portrait_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 portrait_box.add_theme_stylebox_override("panel",_style(Color("#17191C"),6,Color("#6E6152")))
 center.add_child(portrait_box)
 var holder := CenterContainer.new()
 portrait_box.add_child(holder)
 var photo := Portrait.new()
 photo.custom_minimum_size=Vector2(270,300) if _wide else Vector2(240,300)
 photo.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 photo.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 photo.set_character(Model.portrait_id(_current),str(_current["name"]),"indie")
 holder.add_child(photo)
 var id := Model.portrait_id(_current)
 if not ResourceLoader.exists("res://Art/Portraits/indie/"+id+".webp"):
  _label(center,"PROFILE ID CARD  •  PHOTO ART PENDING",11,C_MUTED)
 else:
  _label(center,"SOURCE PORTRAIT  /  IDENTITY VERIFIED",11,C_MUTED)
 var keys := Model.labels_for(role)
 var vals := Model.stats_for(_current,role)
 for i in range(6):
  var line := HBoxContainer.new()
  line.add_theme_constant_override("separation",8)
  center.add_child(line)
  var k := _label(line,str(keys[i]),13,C_WHITE)
  k.custom_minimum_size.x=105
  k.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  var meter := Meter.new()
  meter.value=int(vals[i])
  meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  line.add_child(meter)
  var value := _label(line,"%d / 10" % int(vals[i]),12,C_MUTED)
  value.custom_minimum_size.x=41
  value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

func _character_notes(parent: Node) -> void:
 var notes := _panel(parent,C_PAPER,Vector2(310,0) if _wide else Vector2.ZERO)
 notes.get_parent().size_flags_stretch_ratio=1.15
 _label(notes,"PERSONNEL FILE  /  "+str(_current["name"]).to_upper(),15,C_INK)
 _label(notes,str(_current["story"]),15,C_INK,true)
 var line := HSeparator.new()
 notes.add_child(line)
 _label(notes,"STRENGTH  +  "+str(_current["strength"]),13,Color("#245A3A"),true)
 _label(notes,"WATCH OUT  −  "+str(_current["friction"]),13,Color("#A33C2D"),true)
 _label(notes,"TEMPERAMENT  /  "+str(_current["personality"]),13,C_INK)
 _label(notes,"TROUBLE RISK  /  "+str(_current["trouble"]).to_upper(),13,C_INK)
 _label(notes,"BACKGROUND  /  %d PREVIOUS BANDS   •   %d YEARS PLAYING" % [int(_current["bands"]),int(_current["experience_years"])],13,C_INK)
 _label(notes,"AGE %d   /   %s   /   %s" % [int(_current["age"]),str(_current["town"]),str(_current["gender"])],13,C_INK)
 _label(notes,"LOOKING FOR  /  "+str(_current["ambition"]),13,C_INK,true)
 _label(notes,"TALENT COST  /  %d POINTS" % Model.cost(_current),16,Color("#725015"))

func _member_action() -> void:
 if _current.is_empty():
  return
 var id := str(_current["id"])
 if Model.contains(roster,id):
  for i in range(roster.size()-1,-1,-1):
   if str(roster[i]["id"])==id:
    roster.remove_at(i)
    break
 elif Model.can_add(roster,_current):
  roster.append(_current.duplicate(true))
 _render()

func _name_step(parent: Node) -> void:
 var panel := _panel(parent)
 _label(panel,"The sound is taking shape. What will you call yourselves?",19,C_WHITE,true)
 _label(panel,"%d members  •  %s  •  %d points used" % [roster.size(),genre,Model.spent(roster)],14,C_GOLD)
 _name_entry=LineEdit.new()
 _name_entry.placeholder_text="Your band's name"
 _name_entry.text=band_name
 _name_entry.max_length=36
 _name_entry.custom_minimum_size.y=55
 _name_entry.text_changed.connect(func(value: String) -> void: band_name=value)
 panel.add_child(_name_entry)
 for p in roster:
  _label(panel,str(p["name"])+"   /   "+", ".join(PackedStringArray(p["roles"])),14,C_WHITE)
 if completed:
  var success := _panel(parent,C_PAPER)
  _label(success,"LINEUP CREATED IN THE PROTOTYPE",19,C_INK)
  _label(success,"This is a safe, local-state preview. Your existing saves and career have not been changed.",14,C_INK,true)

func _continue() -> void:
 if step==0:
  step=1
 elif step==1:
  if not Model.viable(roster):
   return
  step=2
 else:
  if band_name.strip_edges().is_empty() or not Model.viable(roster):
   return
  band_name=band_name.strip_edges()
  completed=true
 _render()

func _back() -> void:
 if step>0:
  step-=1
  completed=false
  _render()

func _build_footer(parent: Node) -> void:
 var dock := _panel(parent,Color("#171B20"))
 var info := HBoxContainer.new()
 dock.add_child(info)
 var summary_text := ("%d / 6 MEMBERS   •   %d / %d TALENT POINTS" % [roster.size(),Model.spent(roster),Model.MAX_TALENT]) if _wide else ("%d/6  •  %d/200 PTS" % [roster.size(),Model.spent(roster)])
 var summary := _label(info,summary_text,14,C_GOLD)
 summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var available := Model.MAX_TALENT-Model.spent(roster)
 _label(info,"%d LEFT" % available,14,C_WHITE)
 if step==1:
  var slots := _label(dock,"LINEUP: "+("  /  ".join(PackedStringArray(roster.map(func(p): return str(p["name"])))) if not roster.is_empty() else "No members selected yet"),12,C_MUTED)
  slots.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  var missing := Model.missing(roster)
  _label(dock,("READY TO NAME THE BAND" if Model.viable(roster) else "STILL NEED: "+missing),12,C_MUTED,true)
 var actions := HBoxContainer.new()
 actions.add_theme_constant_override("separation",8)
 dock.add_child(actions)
 if step>0:
  _button(actions,"BACK",func() -> void: _back(),false,false,50).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if step==1:
  var person_selected := Model.contains(roster,str(_current.get("id","")))
  var allowed := Model.can_add(roster,_current)
  _button(actions,"REMOVE" if person_selected else "ADD  •  %d PTS" % Model.cost(_current),func() -> void: _member_action(),not person_selected,not person_selected and not allowed,50).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var label := "MEET THE MUSICIANS" if step==0 else ("NAME YOUR BAND" if step==1 else ("FINISHED" if completed else "CONFIRM NAME"))
 var blocked := (step==1 and not Model.viable(roster)) or (step==2 and (band_name.strip_edges().is_empty() or completed))
 _button(actions,label,func() -> void: _continue(),step!=1,blocked,50).size_flags_horizontal=Control.SIZE_EXPAND_FILL
