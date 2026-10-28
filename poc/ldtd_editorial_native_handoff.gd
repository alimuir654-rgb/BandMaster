extends Control
## ISOLATED 04:00 EDITORIAL ART-HANDOFF BENCHMARK. NOT PRODUCTION UI.
## Reuses original authored portrait SVG, existing V4 source-textured button
## states and paper art. Every decision, label and meter is a native Control.
## Does not save, write files, mutate production scripts or claim art approval.
const Model = preload("res://Scripts/recruitment_catalogue_v3.gd")
const FONT_TITLE = preload("res://Art/Fonts/BarlowCondensed-SemiBold.ttf")
const FONT_BODY = preload("res://Art/Fonts/IBMPlexSans-Variable.ttf")
const FONT_MONO = preload("res://Art/Fonts/IBMPlexMono-Regular.ttf")
const SKIN := "res://Art/UI/RecruitmentV4/"
const PORTRAIT_ALEX := "res://docs/visual-proofs/recruitment_portrait_alex_ink_study.svg"
const WHITE := Color("#f7f2e8")
const MUTED := Color("#adb4ab")
const AMBER := Color("#f4ad39")
const INK := Color("#17201e")
const CREAM := Color("#ede6d6")
const GREEN := Color("#a4c27c")
const RED := Color("#d95748")
var genre := "Indie rock"
var role := "Singer"
var candidate_index := 0
var roster: Array = []
var selected_step := 1
var _stage: Control
var _phone := false
var _width := 1280.0
var _height := 720.0

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 get_viewport().size_changed.connect(_render)
 _render()

func _person() -> Dictionary:
 var pool: Array = Model.pool(genre,role)
 if pool.is_empty():
  return {}
 return pool[posmod(candidate_index,pool.size())]

func _remaining() -> int:
 return Model.MAX_TALENT - Model.spent(roster)

func _choose_role(index: int) -> void:
 role = str(Model.ROLE_TABS[index])
 candidate_index = 0
 _render()

func _browse(index: int) -> void:
 candidate_index = posmod(index,6)
 _render()

func _recruit() -> void:
 var person: Dictionary = _person()
 if person.is_empty():
  return
 if Model.contains(roster,str(person["id"])):
  for i in range(roster.size()-1,-1,-1):
   if str(roster[i]["id"])==str(person["id"]):
    roster.remove_at(i)
    break
 elif Model.can_add(roster,person):
  roster.append(person.duplicate(true))
 _render()

func _choose_genre() -> void:
 # A non-persistent, in-scene navigation proof; the existing model remains
 # authoritative for genre-first -> musicians -> name-last gameplay.
 selected_step = 0
 _render()

func _back_to_musicians() -> void:
 selected_step = 1
 _render()

func _frame(parent: Node, x: float,y: float,w: float,h: float,c: Color) -> ColorRect:
 var box := ColorRect.new()
 box.position=Vector2(x,y)
 box.size=Vector2(w,h)
 box.color=c
 box.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(box)
 return box

func _label(parent: Node,s: String,x: float,y: float,w: float,h: float,pt: int=16,c: Color=WHITE,font: Font=FONT_BODY,align: HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT,wrap: bool=false) -> Label:
 var l:=Label.new()
 l.text=s
 l.position=Vector2(x,y)
 l.size=Vector2(w,h)
 l.clip_text=true
 l.horizontal_alignment=align
 l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
 l.add_theme_font_override("font",font)
 l.add_theme_font_size_override("font_size",pt)
 l.add_theme_color_override("font_color",c)
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

func _texture(parent: Node,path: String,x: float,y: float,w: float,h: float,covered: bool=false) -> TextureRect:
 var t:=TextureRect.new()
 t.position=Vector2(x,y)
 t.size=Vector2(w,h)
 t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if covered else TextureRect.STRETCH_SCALE
 t.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if ResourceLoader.exists(path):
  t.texture=load(path)
 else:
  push_error("ART HANDOFF: missing authored texture "+path)
 parent.add_child(t)
 return t

func _key(parent: Node,name_id: String,caption: String,x: float,y: float,w: float,h: float,action: Callable,active: bool=false,amber: bool=false,pt: int=15) -> TextureButton:
 var key:=TextureButton.new()
 key.name=name_id
 key.position=Vector2(x,y)
 key.size=Vector2(w,h)
 key.ignore_texture_size=true
 key.stretch_mode=TextureButton.STRETCH_SCALE
 key.focus_mode=Control.FOCUS_ALL
 key.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 var family: String="amber_key" if amber else "metal_tab"
 key.texture_normal=load(SKIN+family+("_selected.svg" if active else "_idle.svg"))
 key.texture_hover=load(SKIN+family+"_hover.svg")
 key.texture_pressed=load(SKIN+family+"_pressed.svg")
 key.texture_disabled=load(SKIN+family+"_disabled.svg")
 key.pressed.connect(action)
 key.focus_entered.connect(func() -> void: key.modulate=Color("#ffdda4"))
 key.focus_exited.connect(func() -> void: key.modulate=Color.WHITE)
 parent.add_child(key)
 _label(key,caption,7,0,w-14,h,pt,INK if amber or active else WHITE,FONT_TITLE,HORIZONTAL_ALIGNMENT_CENTER)
 return key

func _meter(parent: Node,tag: String,value: int,x: float,y: float,track_width: float,phone: bool=false) -> void:
 # Six source-driven, read-only indicator bars. No input, drag or focus.
 var rail:=Control.new()
 rail.name="Meter_"+tag
 rail.position=Vector2(x,y)
 rail.size=Vector2((track_width+118.0),20.0)
 rail.focus_mode=Control.FOCUS_NONE
 rail.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(rail)
 _label(rail,tag.to_upper(),0,0,phone and 101.0 or 93.0,19,phone and 11 or 12,MUTED,FONT_MONO)
 var offset:=110.0 if phone else 98.0
 _frame(rail,offset,5,track_width,10,Color("#3d4944"))
 var color:=RED if value<=3 else (AMBER if value<=6 else GREEN)
 if value>0:
  _frame(rail,offset,5,track_width*float(value)/10.0,10,color)
 _label(rail,str(value).pad_zeros(2),offset+track_width+6,0,25,19,phone and 12 or 13,WHITE,FONT_MONO)

func _render() -> void:
 var physical: Vector2i=DisplayServer.window_get_size()
 if physical.x<100 or physical.y<100:
  return
 _width=float(physical.x)
 _height=float(physical.y)
 _phone=_width<600.0
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var logical: Vector2=get_viewport_rect().size
 var base_w:=390.0 if _phone else 1280.0
 var base_h:=844.0 if _phone else 720.0
 var stage:=Control.new()
 stage.name="EditorialNativeStage"
 stage.position=Vector2.ZERO
 stage.size=Vector2(base_w,base_h)
 stage.scale=Vector2(logical.x/base_w,logical.y/base_h)
 stage.mouse_filter=Control.MOUSE_FILTER_PASS
 add_child(stage)
 _stage=stage
 _frame(stage,0,0,base_w,base_h,Color("#0b1011"))
 _frame(stage,6,6,base_w-12,base_h-12,Color("#111919"))
 _frame(stage,6,6,base_w-12,6,AMBER)
 if _phone:
  _phone_scene(stage)
 else:
  _desktop_scene(stage)

func _header(stage: Node,phone: bool) -> void:
 if phone:
  _label(stage,"LIVIN' THE DREAM / INDIE ROCK",18,16,355,18,11,AMBER,FONT_MONO)
  _label(stage,"FIND YOUR PEOPLE",18,39,355,34,29,WHITE,FONT_TITLE)
  _label(stage,"TALENT %d / 200  •  %02d OF 06"%[_remaining(),candidate_index+1],18,77,354,18,11,GREEN,FONT_MONO)
  _frame(stage,18,96,355,1,Color("#48534e"))
 else:
  _label(stage,"LIVIN' THE DREAM / 001",34,27,350,20,12,AMBER,FONT_MONO)
  _label(stage,"FIND YOUR PEOPLE",34,52,680,49,39,WHITE,FONT_TITLE)
  _label(stage,"INDIE / POST-PUNK  •  BRISTOL, UK",35,102,650,17,11,MUTED,FONT_MONO)
  _label(stage,"TALENT REMAINING",1025,32,220,18,11,MUTED,FONT_MONO)
  _label(stage,"%d / 200"%_remaining(),1025,52,225,48,34,GREEN,FONT_TITLE)
  _frame(stage,34,119,1211,1,Color("#4b5550"))

func _role_keys(stage: Node,phone: bool) -> void:
 var short:=["SING","GTR","BASS","KEYS","DRUMS"]
 for i in range(5):
  var name_text: String=short[i] if phone else str(Model.ROLE_TABS[i]).to_upper()
  var x: float=17.0+72.0*i if phone else 428.0+124.0*i
  var y: float=108.0 if phone else 130.0
  var w: float=68.0 if phone else 118.0
  _key(stage,"Role_"+str(i),name_text,x,y,w,44.0,Callable(self,"_choose_role").bind(i),str(Model.ROLE_TABS[i])==role,false,phone and 12 or 16)

func _candidate_rail(stage: Node,phone: bool) -> void:
 var pool: Array=Model.pool(genre,role)
 for i in range(6):
  var p: Dictionary=pool[i]
  var caption: String=str(i+1).pad_zeros(2) if phone else (str(i+1).pad_zeros(2)+"  "+str(p["name"]).get_slice(" ",0).to_upper())
  var x: float=18.0+59.0*i if phone else 160.0
  var y: float=182.0 if phone else 190.0+64.0*i
  var w: float=54.0 if phone else 105.0
  var h: float=48.0 if phone else 52.0
  _key(stage,"Candidate_"+str(i),caption,x,y,w,h,Callable(self,"_browse").bind(i),candidate_index==i,false,phone and 13 or 15)

func _portrait(stage: Node,phone: bool,person: Dictionary) -> void:
 var x: float=18.0 if phone else 285.0
 var y: float=241.0 if phone else 188.0
 var w: float=187.0 if phone else 330.0
 var h: float=239.0 if phone else 270.0
 _frame(stage,x-2,y-2,w+4,h+4,Color("#eee5d2"))
 if str(person["id"])=="alex":
  _texture(stage,PORTRAIT_ALEX,x,y,w,h,true)
 else:
  # Explicit source blocker. Never show Alex's face as another candidate.
  _frame(stage,x,y,w,h,Color("#5b665e"))
  _label(stage,"PORTRAIT",x+9,y+h*0.39,w-18,25,phone and 16 or 22,WHITE,FONT_TITLE,HORIZONTAL_ALIGNMENT_CENTER)
  _label(stage,"ART PENDING",x+9,y+h*0.5,w-18,25,phone and 12 or 16,AMBER,FONT_MONO,HORIZONTAL_ALIGNMENT_CENTER)
 _label(stage,"AUDITION 0"+str(candidate_index+1),x+9,y+8,w-18,18,phone and 11 or 12,INK,FONT_MONO)
 if not phone:
  _label(stage,str(person["name"]).to_upper(),x,y+h+4,250,32,27,WHITE,FONT_TITLE)
  _label(stage,role.to_upper(),x+248,y+h+7,85,22,13,AMBER,FONT_TITLE,HORIZONTAL_ALIGNMENT_RIGHT)

func _dossier(stage: Node,phone: bool,person: Dictionary) -> void:
 if phone:
  var x:=208.0
  _texture(stage,SKIN+"paper_personnel.svg",x,241,164,239)
  _label(stage,"PERSONNEL FILE",x+12,252,143,20,12,RED,FONT_MONO)
  _label(stage,str(person["name"]).to_upper(),x+13,278,140,54,24,INK,FONT_TITLE,HORIZONTAL_ALIGNMENT_LEFT,true)
  _label(stage,"%d / %s"%[int(person["age"]),str(person["town"]).to_upper()],x+13,337,139,19,12,INK,FONT_MONO)
  _frame(stage,x+13,365,136,1,Color("#aa9b80"))
  _label(stage,"TALENT COST",x+13,377,140,18,11,RED,FONT_MONO)
  _label(stage,str(Model.cost(person)),x+13,396,140,39,31,INK,FONT_TITLE)
  _label(stage,"POINTS",x+13,433,139,17,12,INK,FONT_MONO)
  _key(stage,"DossierView","VIEW FILE",x+13,452,137,27,Callable(self,"_choose_genre"),false,false,12)
 else:
  _texture(stage,SKIN+"paper_personnel.svg",629,185,397,415)
  _label(stage,"PERSONNEL FILE  /  AUDITION 0"+str(candidate_index+1),655,204,330,21,14,RED,FONT_MONO)
  _label(stage,str(person["name"]).to_upper(),655,233,345,52,39,INK,FONT_TITLE)
  _label(stage,"%d  •  %s  •  %d YEARS ON STAGE"%[int(person["age"]),str(person["town"]).to_upper(),int(person["experience_years"])],655,283,344,21,13,INK,FONT_MONO)
  _frame(stage,655,313,338,1,Color("#9c967f"))
  _label(stage,"THE SOUND",655,326,320,20,12,RED,FONT_MONO)
  _label(stage,str(person["strength"]),655,348,335,56,17,INK,FONT_BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
  _label(stage,"THE GOOD",655,412,330,18,12,Color("#417048"),FONT_MONO)
  _label(stage,str(person["personality"])+" / "+str(person["ambition"]),655,434,333,42,15,INK,FONT_BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
  _label(stage,"THE COMPLICATION",655,483,330,20,12,RED,FONT_MONO)
  _label(stage,str(person["friction"]),655,507,332,48,16,INK,FONT_BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
  _label(stage,"BANDS "+str(person["bands"])+"  /  TROUBLE "+str(person["trouble"]).to_upper(),655,560,335,18,13,INK,FONT_MONO)

func _stats(stage: Node,phone: bool,person: Dictionary) -> void:
 var names: Array=Model.labels_for(role)
 var vals: Array=Model.stats_for(person,role)
 if phone:
  _label(stage,"THE SIX  /  READ-ONLY ATTRIBUTES",19,486,355,22,11,AMBER,FONT_MONO)
  for i in range(6):
   _meter(stage,str(names[i]),int(vals[i]),19,519+25*i,195,true)
 else:
  _label(stage,"THE SIX  /  LIVE ATTRIBUTES",286,495,330,22,12,AMBER,FONT_MONO)
  for i in range(6):
   _meter(stage,str(names[i]),int(vals[i]),286,522+17*i,188,false)

func _recruit_action(stage: Node,phone: bool,person: Dictionary) -> void:
 var already: bool=Model.contains(roster,str(person["id"]))
 var label_text: String="REMOVE "+str(person["name"]).get_slice(" ",0).to_upper() if already else "RECRUIT "+str(person["name"]).get_slice(" ",0).to_upper()
 if phone:
  _key(stage,"RecruitCTA",label_text+"  →",19,673,352,62,Callable(self,"_recruit"),false,true,26)
 else:
  _frame(stage,1040,187,181,343,Color("#1d2826"))
  _label(stage,"THE DECISION",1056,198,155,20,13,AMBER,FONT_MONO)
  _label(stage,str(Model.cost(person)),1056,225,150,62,54,WHITE,FONT_TITLE)
  _label(stage,"POINTS",1058,283,144,19,13,MUTED,FONT_MONO)
  _label(stage,"STRENGTH",1056,316,150,17,12,AMBER,FONT_MONO)
  _label(stage,str(person["strength"]),1056,335,145,64,15,WHITE,FONT_BODY,HORIZONTAL_ALIGNMENT_LEFT,true)
  _label(stage,"TROUBLE RISK",1056,412,150,18,12,MUTED,FONT_MONO)
  _label(stage,str(person["trouble"]).to_upper(),1056,433,150,35,24,RED,FONT_TITLE)
  _key(stage,"RecruitCTA",label_text+"  →",1041,537,180,65,Callable(self,"_recruit"),false,true,24)

func _roster(stage: Node,phone: bool) -> void:
 if phone:
  _frame(stage,19,749,352,79,Color("#202c29"))
  _label(stage,"YOUR LINEUP  /  %d OF 6"%roster.size(),29,755,333,19,12,AMBER,FONT_MONO)
  _label(stage,"NO ONE SIGNED" if roster.is_empty() else str(roster[0]["name"]).to_upper(),29,779,333,24,18,WHITE,FONT_TITLE)
  _label(stage,"GENRE FIRST  •  MEMBERS  •  NAME LAST",29,808,333,14,10,MUTED,FONT_MONO)
 else:
  _frame(stage,35,632,1186,74,Color("#202b28"))
  _label(stage,"YOUR LINEUP",53,640,230,20,12,AMBER,FONT_MONO)
  _label(stage,"NO ONE SIGNED" if roster.is_empty() else str(roster[0]["name"]).to_upper(),53,663,250,27,20,WHITE,FONT_TITLE)
  _label(stage,"%d OF 6 MEMBERS"%roster.size(),302,667,230,18,13,MUTED,FONT_MONO)
  _label(stage,"GENRE FIRST  →  MUSICIANS  →  NAME LAST",566,665,440,19,13,MUTED,FONT_MONO)
  _key(stage,"Previous","‹ PREV",1012,642,98,49,Callable(self,"_browse").bind(candidate_index-1),false,false,16)
  _key(stage,"Next","NEXT ›",1114,642,99,49,Callable(self,"_browse").bind(candidate_index+1),false,false,16)

func _phone_scene(stage: Node) -> void:
 var person: Dictionary=_person()
 _header(stage,true)
 _role_keys(stage,true)
 _label(stage,"SIX "+role.to_upper()+"S / AUDITION",19,158,350,20,12,AMBER,FONT_MONO)
 _candidate_rail(stage,true)
 _portrait(stage,true,person)
 _dossier(stage,true,person)
 _stats(stage,true,person)
 _recruit_action(stage,true,person)
 _roster(stage,true)

func _desktop_scene(stage: Node) -> void:
 var person: Dictionary=_person()
 _header(stage,false)
 _frame(stage,32,138,101,458,Color("#1a2523"))
 _label(stage,"GENRE",43,150,86,20,13,AMBER,FONT_MONO)
 _key(stage,"Genre","INDIE ROCK",39,186,87,50,Callable(self,"_choose_genre"),true,false,13)
 _label(stage,"PUNK",49,258,72,18,12,MUTED,FONT_MONO)
 _label(stage,"ALT POP",49,315,72,18,12,MUTED,FONT_MONO)
 _label(stage,"METAL",49,372,72,18,12,MUTED,FONT_MONO)
 _label(stage,"ELECTRO",49,429,72,18,12,MUTED,FONT_MONO)
 _label(stage,"THE SHORTLIST",159,151,235,20,13,MUTED,FONT_MONO)
 _candidate_rail(stage,false)
 _role_keys(stage,false)
 _portrait(stage,false,person)
 _dossier(stage,false,person)
 _stats(stage,false,person)
 _recruit_action(stage,false,person)
 _roster(stage,false)
