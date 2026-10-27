extends Control
## Art-direction-first V4 road-case recruitment proof. NEVER use old UI helpers.
## Input and model remain native; physical visual surfaces are source-backed images.
## No FileAccess, DirAccess, save writes, scene transitions or synthetic band money.
const Model = preload("res://Scripts/recruitment_catalogue_v3.gd")
const Formation = preload("res://Scripts/formation_catalogue.gd")
const Meter = preload("res://poc/ldtd_recruitment_meter.gd")
const ART := "res://Art/UI/RecruitmentV4/"
const PHOTO := "res://Art/Portraits/indie/"
const TRANSPORT := "res://bandmaster_premium_controls_lab/assets/transport_studio_"
const FONT_TITLE := preload("res://Art/Fonts/BarlowCondensed-SemiBold.ttf")
const FONT_BODY := preload("res://Art/Fonts/IBMPlexSans-Variable.ttf")
const FONT_MONO := preload("res://Art/Fonts/IBMPlexMono-Regular.ttf")
const WHITE := Color("#F7F1E7")
const CREAM := Color("#E3C9A0")
const AMBER := Color("#FFC573")
const MUTED := Color("#BCB7AD")
const INK := Color("#292420")
const GREEN := Color("#34633B")
const RED := Color("#9B3430")
var step := 0
var genre := "Indie rock"
var role := "Singer"
var candidate_index := 0
var roster: Array = []
var band_name := ""
var completed := false
var selected: Dictionary = {}
var _stage: Control
var _landscape := true
var _view_w := 1600.0
var _view_h := 900.0
var _mobile_scroll := 0
var _last_focus: String = ""
var genre_page := 0

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 get_viewport().size_changed.connect(_render)
 _render()

func _node(parent: Node, x: float, y: float, w: float, h: float) -> Control:
 var n := Control.new()
 n.position = Vector2(x,y)
 n.size = Vector2(w,h)
 n.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(n)
 return n

func _art(parent: Node, path: String, x: float, y: float, w: float, h: float, tint: Color=Color.WHITE) -> TextureRect:
 var n := TextureRect.new()
 n.position=Vector2(x,y)
 n.size=Vector2(w,h)
 n.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 n.stretch_mode=TextureRect.STRETCH_SCALE
 n.mouse_filter=Control.MOUSE_FILTER_IGNORE
 n.modulate=tint
 if ResourceLoader.exists(path):
  n.texture=load(path)
 else:
  push_error("V4 missing art asset: "+path)
 parent.add_child(n)
 return n

func _text(parent: Node, content: String, x: float, y: float, w: float, h: float, size_pt: int=17, ink: Color=WHITE, face: Font=FONT_BODY, wrap: bool=false, align: HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 var label := Label.new()
 label.text=content
 label.position=Vector2(x,y)
 label.custom_minimum_size=Vector2.ZERO
 label.clip_text=true
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 label.horizontal_alignment=align
 label.add_theme_font_override("font",face)
 label.add_theme_font_size_override("font_size",size_pt)
 label.add_theme_color_override("font_color",ink)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(label)
 label.size=Vector2(w,h)
 return label

func _plate(parent: Node, caption: String, bounds: Rect2, action: Callable, active: bool=false, enabled: bool=true, finish: String="metal_tab", text_size: int=17) -> TextureButton:
 var b := TextureButton.new()
 b.position=bounds.position
 b.size=bounds.size
 b.ignore_texture_size=true
 b.stretch_mode=TextureButton.STRETCH_SCALE
 b.focus_mode=Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.texture_normal=load(ART+finish+("_selected.svg" if active else "_idle.svg"))
 b.texture_hover=load(ART+finish+"_hover.svg")
 b.texture_pressed=load(ART+finish+"_pressed.svg")
 b.texture_disabled=load(ART+finish+"_disabled.svg")
 b.disabled=not enabled
 b.pressed.connect(action)
 b.focus_entered.connect(func() -> void: b.modulate=Color("#FFE0A7"))
 b.focus_exited.connect(func() -> void: b.modulate=Color.WHITE)
 parent.add_child(b)
 _text(b,caption,8,0,bounds.size.x-16,bounds.size.y,text_size,INK if (active or finish=="amber_key") else WHITE,FONT_TITLE,false,HORIZONTAL_ALIGNMENT_CENTER)
 return b

func _transport(parent: Node, symbol: String, bounds: Rect2, action: Callable, backwards: bool=false) -> TextureButton:
 var b := TextureButton.new()
 b.position=bounds.position
 b.size=bounds.size
 b.focus_mode=Control.FOCUS_ALL
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.ignore_texture_size=true
 b.stretch_mode=TextureButton.STRETCH_SCALE
 b.flip_h=backwards
 b.texture_normal=load(TRANSPORT+"idle.png")
 b.texture_hover=load(TRANSPORT+"hover.png")
 b.texture_pressed=load(TRANSPORT+"pressed.png")
 b.texture_disabled=load(TRANSPORT+"disabled.png")
 b.pressed.connect(action)
 parent.add_child(b)
 _text(b,symbol,0,0,bounds.size.x,bounds.size.y,19,WHITE,FONT_TITLE,false,HORIZONTAL_ALIGNMENT_CENTER)
 return b

func _render() -> void:
 # Compose in physical device pixels. Godot's canvas_items stretch can keep a
 # 720-unit logical viewport when the window is only 390 physical pixels wide.
 # Correct with one root transform, rather than upscaling every button separately.
 var window_size: Vector2i=DisplayServer.window_get_size()
 _view_w=float(window_size.x)
 _view_h=float(window_size.y)
 if _view_w<80.0 or _view_h<80.0:
  return
 var logical_size:Vector2=get_viewport_rect().size
 for child in get_children():
  remove_child(child)
  child.queue_free()
 _landscape=_view_w>=900.0 and _view_w>_view_h
 var canvas := Control.new()
 canvas.position=Vector2.ZERO
 canvas.size=Vector2(_view_w,_view_h)
 canvas.scale=Vector2(logical_size.x/_view_w,logical_size.y/_view_h)
 add_child(canvas)
 _stage=canvas
 # The roadcase is a single integrated authored material, not twelve floating cards.
 _art(canvas,ART+"case_roadcase.svg",0,0,_view_w,_view_h)
 if _landscape:
  _landscape_scene(canvas)
 else:
  _portrait_scene(canvas)

func _current() -> Dictionary:
 var available: Array=Model.pool(genre,role)
 if available.is_empty():
  return {}
 candidate_index=posmod(candidate_index,available.size())
 return available[candidate_index]

func _set_genre(value: String) -> void:
 if value==genre:
  return
 if not roster.is_empty():
  # No silent destruction of musician choices after a genre switch.
  return
 genre=value
 candidate_index=0
 _render()

func _switch_genre_page() -> void:
 genre_page=1-genre_page
 _render()

func _set_role(value: String) -> void:
 role=value
 candidate_index=0
 _mobile_scroll=0
 _render()

func _move(delta: int) -> void:
 candidate_index=posmod(candidate_index+delta,6)
 _render()

func _add_remove() -> void:
 var person: Dictionary=_current()
 if person.is_empty():
  return
 var id: String=str(person["id"])
 if Model.contains(roster,id):
  for i in range(roster.size()-1,-1,-1):
   if str(roster[i]["id"])==id:
    roster.remove_at(i)
    break
 elif Model.can_add(roster,person):
  roster.append(person.duplicate(true))
 _render()

func _next() -> void:
 if step==0:
  step=1
 elif step==1:
  if Model.viable(roster):
   step=2
 else:
  if not band_name.strip_edges().is_empty() and Model.viable(roster):
   completed=true
 _render()

func _back() -> void:
 step=maxi(0,step-1)
 completed=false
 _render()

func _name_edit(value: String) -> void:
 band_name=value
 # Changing a name never changes the same member IDs or model state.

func _portrait_picture(parent: Node,b: Rect2,person: Dictionary) -> void:
 # The real source portraits are often small. Never use a different person's photo.
 var photo_id: String=str(person.get("id",""))
 var path: String=PHOTO+photo_id+".webp"
 _art(parent,ART+"metal_tab_idle.svg",b.position.x-3,b.position.y-3,b.size.x+6,b.size.y+6)
 if ResourceLoader.exists(path):
  var pic:=_art(parent,path,b.position.x,b.position.y,b.size.x,b.size.y)
  pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 else:
  _text(parent,"PORTRAIT\nNOT YET SOURCED",b.position.x+5,b.position.y+b.size.y*0.28,b.size.x-10,b.size.y*.40,21,CREAM,FONT_TITLE,true,HORIZONTAL_ALIGNMENT_CENTER)
 # Do not mislabel ID cards as photographed portraits; source art is placeholder.

func _meters(parent: Node,person: Dictionary,x:float,y:float,w:float,row_h:float) -> void:
 var names: Array=Model.labels_for(role)
 var scores: Array=Model.stats_for(person,role)
 for idx in range(6):
  var yy: float=y+row_h*float(idx)
  var name_w := 125.0 if _landscape else 103.0
  _text(parent,str(names[idx]),x,yy,name_w,row_h-1,15 if _landscape else 13,WHITE,FONT_BODY)
  var meter:=Meter.new()
  meter.position=Vector2(x+name_w+5,yy+4)
  meter.size=Vector2(maxf(55.0,w-name_w-56.0),row_h-8)
  meter.value=int(scores[idx])
  meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
  meter.focus_mode=Control.FOCUS_NONE
  parent.add_child(meter)
  _text(parent,str(scores[idx])+"/10",x+w-49,yy,48,row_h-1,14,CREAM,FONT_MONO,false,HORIZONTAL_ALIGNMENT_RIGHT)

func _dossier(parent: Node,p: Dictionary,b:Rect2,compact:bool=false) -> void:
 _art(parent,ART+"paper_personnel.svg",b.position.x,b.position.y,b.size.x,b.size.y)
 var x:=b.position.x+20.0
 var y:=b.position.y+18.0
 var w:=b.size.x-40.0
 var ratio:=b.size.y/440.0
 _text(parent,"PERSONNEL NOTES   /   "+str(p["name"]).to_upper(),x,y,w,31,21,INK,FONT_TITLE)
 y+=38
 _text(parent,str(p["story"]),x,y,w,102.0*ratio,14,INK,FONT_BODY,true)
 y+=108.0*ratio
 _text(parent,"+ "+str(p["strength"]),x,y,w,50.0*ratio,14,GREEN,FONT_BODY,true)
 y+=54.0*ratio
 _text(parent,"− "+str(p["friction"]),x,y,w,50.0*ratio,14,RED,FONT_BODY,true)
 y+=56.0*ratio
 _text(parent,str(p["personality"]).to_upper()+"  •  TROUBLE: "+str(p["trouble"]).to_upper(),x,y,w,27,14,INK,FONT_TITLE)
 y+=32
 _text(parent,str(p["bands"])+" PRIOR BANDS   /   "+str(p["experience_years"])+" YEARS",x,y,w,26,14,INK,FONT_MONO)
 y+=29
 _text(parent,str(p["age"])+" YEARS OLD   •   "+str(p["town"]),x,y,w,26,14,INK,FONT_MONO)
 y+=29
 if not compact:
  _text(parent,str(p["ambition"]),x,y,w,48,14,INK,FONT_BODY,true)
 _text(parent,"TALENT   "+str(Model.incremental_cost(roster,p))+" POINTS",x,b.position.y+b.size.y-53,w,28,20,INK,FONT_TITLE)

func _landscape_scene(parent: Node) -> void:
 var s:float=minf(_view_w/1600.0,_view_h/900.0)
 var ox:float=(_view_w-1600.0*s)*0.5
 var oy:float=(_view_h-900.0*s)*0.5
 var layout:=_node(parent,ox,oy,1600,900)
 layout.scale=Vector2(s,s)
 _text(layout,"LIVIN' THE DREAM",65,38,310,52,35,AMBER,FONT_TITLE)
 _text(layout,["01 / CHOOSE GENRE","02 / RECRUIT MUSICIANS","03 / NAME YOUR BAND"][step],400,39,820,52,39,WHITE,FONT_TITLE)
 _text(layout,genre.to_upper(),1338,42,178,37,17,CREAM,FONT_MONO,false,HORIZONTAL_ALIGNMENT_RIGHT)
 _text(layout,"GENRE",78,112,205,37,25,AMBER,FONT_TITLE)
 var genres: Array=Model.genres()
 # Two pages of seven genres: each physical key remains at least 48px
 # in the 1280x720 renderer instead of compressing fourteen into tiny pills.
 for idx in range(7):
  var source_idx:int=genre_page*7+idx
  if source_idx>=genres.size():break
  var value:String=str(genres[source_idx])
  var yy:float=154.0+float(idx)*71.0
  _plate(layout,value,Rect2(65,yy,236,63),func() -> void: _set_genre(value),value==genre,roster.is_empty(),"metal_tab",20)
 _plate(layout,"‹ GENRES" if genre_page==1 else "MORE GENRES ›",Rect2(65,663,236,59),func() -> void: _switch_genre_page(),false,true,"metal_tab",19)
 if step==0:
  _text(layout,"CHOOSE THE MUSIC YOU WANT TO MAKE",382,180,900,70,45,WHITE,FONT_TITLE)
  _text(layout,str(Formation.GENRES[genre]["description"]),395,265,950,58,26,CREAM,FONT_BODY,true)
  _text(layout,"STRENGTH  /  "+str(Formation.GENRES[genre]["strength"]),395,367,920,50,21,WHITE,FONT_BODY)
  _text(layout,"CHALLENGE /  "+str(Formation.GENRES[genre]["challenge"]),395,430,920,50,21,WHITE,FONT_BODY)
 elif step==2:
  _text(layout,"A NAME FOR THIS BAND",388,192,950,77,55,WHITE,FONT_TITLE)
  _name_line(layout,388,323,800,75)
  _text(layout,str(roster.size())+" MUSICIANS  /  "+genre.to_upper(),390,410,780,52,23,AMBER,FONT_MONO)
 else:
  _landscape_recruit(layout)
 _roster_dock(layout,1600,900,true)

func _landscape_recruit(layout: Node) -> void:
 # Four fixed visual zones from the owner-approved mockup.
 var roles: Array=Model.ROLE_TABS
 for idx in range(roles.size()):
  var v: String=str(roles[idx])
  _plate(layout,v.to_upper()+"S",Rect2(328+idx*184,104,173,61),func() -> void: _set_role(v),v==role,true,"metal_tab",24)
 var members: Array=Model.pool(genre,role)
 for idx in range(members.size()):
  var p:Dictionary=members[idx]
  var yy:=192.0+idx*86.0
  _plate(layout,("✓ " if Model.contains(roster,str(p["id"])) else "")+str(p["name"]),Rect2(323,yy,194,74),func() -> void: _choose_candidate(idx),idx==candidate_index,true,"metal_tab",20)
 var p:Dictionary=_current()
 selected=p
 if p.is_empty():return
 _text(layout,str(p["name"]).to_upper(),555,185,455,43,31,WHITE,FONT_TITLE)
 _text(layout," / ".join(PackedStringArray(p["roles"]))+"  •  "+str(p["town"]),555,228,455,29,17,AMBER,FONT_BODY)
 _portrait_picture(layout,Rect2(554,263,460,278),p)
 _text(layout,"MUSICAL ATTRIBUTES",552,535,455,30,24,CREAM,FONT_TITLE)
 _meters(layout,p,552,566,468,22.5)
 _dossier(layout,p,Rect2(1040,190,497,528))
 _transport(layout,"◀",Rect2(575,706,86,55),func() -> void: _move(-1),true)
 _transport(layout,"▶",Rect2(676,706,86,55),func() -> void: _move(1))
 var already:bool=Model.contains(roster,str(p["id"]))
 var cost:int=Model.incremental_cost(roster,p)
 _plate(layout,"REMOVE" if already else ("ADD TO BAND  /  "+str(cost)+" POINTS"),Rect2(789,704,735,60),func() -> void: _add_remove(),false,already or Model.can_add(roster,p),"amber_key",24)

func _choose_candidate(idx: int) -> void:
 candidate_index=idx
 _render()

func _roster_dock(layout: Node,w:float,h:float,wide:bool) -> void:
 var y:=790.0 if wide else h-130.0
 if wide:
  _text(layout,"CURRENT LINEUP  /  "+str(roster.size())+" MEMBERS",75,y,420,32,25,WHITE,FONT_TITLE)
  for i in range(6):
   var value: String="EMPTY" if i>=roster.size() else str(roster[i]["name"])
   _text(layout,value,75+i*159,y+39,151,35,17,CREAM if i<roster.size() else MUTED,FONT_TITLE)
  _text(layout,str(Model.MAX_TALENT-Model.spent(roster))+" / "+str(Model.MAX_TALENT)+" TALENT LEFT",1150,y,342,40,25,AMBER,FONT_TITLE,false,HORIZONTAL_ALIGNMENT_RIGHT)
  if step!=1:
   _plate(layout,"BACK",Rect2(1120,715,170,55),func() -> void: _back(),false,true,"metal_tab",23)
   _plate(layout,"CONTINUE",Rect2(1300,715,210,55),func() -> void: _next(),false,(step==0 or not band_name.is_empty()),"amber_key",23)
  elif Model.viable(roster):
   _plate(layout,"NAME BAND",Rect2(1290,725,236,45),func() -> void: _next(),false,true,"amber_key",21)
 else:
  _text(layout,str(roster.size())+" / 6 PEOPLE  •  "+str(Model.MAX_TALENT-Model.spent(roster))+" POINTS LEFT",14,y,300,29,17,AMBER,FONT_TITLE)
  var names:=PackedStringArray(roster.map(func(p): return str(p["name"])))
  _text(layout,("  •  ".join(names) if not names.is_empty() else "YOUR BAND IS STILL EMPTY"),14,y+33,w-28,31,14,WHITE,FONT_BODY)
  if step!=1:
   _plate(layout,"BACK",Rect2(12,h-68,(w-36)/2,51),func() -> void: _back(),false,true,"metal_tab",18)
   _plate(layout,"NEXT",Rect2((w-36)/2+22,h-68,(w-36)/2,51),func() -> void: _next(),false,step==0 or not band_name.is_empty(),"amber_key",18)

func _portrait_scene(parent: Node) -> void:
 var w:float=_view_w
 var h:float=_view_h
 var margin:=12.0
 _text(parent,"LIVIN' THE DREAM",margin,18,w-24,32,27,AMBER,FONT_TITLE)
 _text(parent,["01 / CHOOSE GENRE","02 / RECRUIT YOUR BAND","03 / NAME YOUR BAND"][step],margin,51,w-24,36,28,WHITE,FONT_TITLE)
 if step==0:
  _mobile_genre(parent,w,h)
 elif step==2:
  _text(parent,"MAKE IT YOURS",18,165,w-36,48,35,CREAM,FONT_TITLE)
  _name_line(parent,18,235,w-36,58)
  _text(parent,genre+"  /  "+str(roster.size())+" MEMBERS",18,327,w-36,42,17,WHITE,FONT_BODY)
 else:
  _mobile_recruit(parent,w,h)
 _roster_dock(parent,w,h,false)

func _mobile_genre(parent: Node,w:float,h:float) -> void:
 _text(parent,"THE MUSIC COMES FIRST",18,99,w-36,43,30,CREAM,FONT_TITLE)
 var names:Array=Model.genres()
 for i in range(names.size()):
  var label:String=str(names[i])
  var cols:=2
  var width:float=(w-42.0)/2.0
  var x:float=13.0+float(i%cols)*(width+12.0)
  var y:float=145.0+float(i/cols)*49.0
  _plate(parent,label,Rect2(x,y,width,48),func() -> void: _set_genre(label),label==genre,true,"metal_tab",17)
 _text(parent,str(Formation.GENRES[genre]["description"]),18,h-237,w-36,58,16,WHITE,FONT_BODY,true)
 _plate(parent,"MEET THE MUSICIANS",Rect2(18,h-184,w-36,48),func() -> void: _next(),false,true,"amber_key",23)

func _mobile_recruit(parent: Node,w:float,h:float) -> void:
 _text(parent,genre.to_upper(),13,99,w-26,27,15,AMBER,FONT_MONO)
 # All five role tabs are proper horizontally browsable native inputs, never default tabs.
 var roles: Array=Model.ROLE_TABS
 var active_idx:int=roles.find(role)
 for idx in range(5):
  var v:String=str(roles[idx])
  # First four in phone folded rail; current tab always visible via changing the three-window origin.
  var origin:=clampi(active_idx-1,0,2)
  if idx<origin or idx>=origin+3:continue
  var xx:float=12.0+float(idx-origin)*(w-30.0)/3.0
  _plate(parent,v.to_upper(),Rect2(xx,127,(w-36.0)/3.0,47),func() -> void: _set_role(v),v==role,true,"metal_tab",17)
 var p:Dictionary=_current()
 selected=p
 if p.is_empty():return
 _transport(parent,"◀",Rect2(15,179,56,44),func() -> void: _move(-1),true)
 _text(parent,str(p["name"]).to_upper(),75,178,w-151,34,26,WHITE,FONT_TITLE,false,HORIZONTAL_ALIGNMENT_CENTER)
 _text(parent,str(candidate_index+1)+"/6",75,211,w-151,22,13,CREAM,FONT_MONO,false,HORIZONTAL_ALIGNMENT_CENTER)
 _transport(parent,"▶",Rect2(w-72,179,56,44),func() -> void: _move(1))
 _portrait_picture(parent,Rect2(74,242,w-148,175),p)
 _text(parent,(" / ".join(PackedStringArray(p["roles"]))+"  •  "+str(p["town"])),18,418,w-36,26,15,CREAM,FONT_BODY,false,HORIZONTAL_ALIGNMENT_CENTER)
 _meters(parent,p,17,450,w-34,27)
 _text(parent,str(p["bands"])+" BANDS  •  "+str(p["years_playing"] if p.has("years_playing") else p["experience_years"])+" YRS  •  "+str(p["personality"]),18,617,w-36,30,13,WHITE,FONT_BODY)
 var already:bool=Model.contains(roster,str(p["id"]))
 _plate(parent,"REMOVE" if already else ("ADD  /  "+str(Model.incremental_cost(roster,p))+" PTS"),Rect2(12,655,(w-36)/2,52),func() -> void: _add_remove(),false,already or Model.can_add(roster,p),"amber_key",23)
 # Full biography is scrollable from a genuine paper dossier, never squeezed into tiny print.
 # A second page is available by pressing the clearly labelled dossier control.
 _plate(parent,"PERSON FILE",Rect2((w-36)/2+24,655,(w-36)/2,52),func() -> void: _show_dossier(),false,true,"metal_tab",17)

func _show_dossier() -> void:
 var p:Dictionary=_current()
 if p.is_empty():return
 var dialog:=AcceptDialog.new()
 dialog.title="PERSONNEL FILE / "+str(p["name"])
 dialog.dialog_text= str(p["story"])+"\n\nSTRENGTH: "+str(p["strength"])+"\nWATCH OUT: "+str(p["friction"])+"\n\n"+str(p["bands"])+" PREVIOUS BANDS · "+str(p["experience_years"])+" YEARS EXPERIENCE\nTROUBLE RISK: "+str(p["trouble"])+"\nLOOKING FOR: "+str(p["ambition"])
 add_child(dialog)
 dialog.confirmed.connect(dialog.queue_free)
 dialog.popup_centered_ratio(0.85)

func _name_line(parent: Node,x:float,y:float,w:float,h:float) -> void:
 var field:=LineEdit.new()
 field.position=Vector2(x,y)
 field.size=Vector2(w,h)
 field.placeholder_text="Your band's name"
 field.text=band_name
 field.add_theme_font_override("font",FONT_BODY)
 field.add_theme_font_size_override("font_size",23)
 field.text_changed.connect(_name_edit)
 parent.add_child(field)
