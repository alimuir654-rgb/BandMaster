extends Range
## An actual discrete input over separate material layers, never a passive meter.
const SOURCE = preload("res://experiments/playable_flightcase/art/mixing_desk/controls_atlas.png")
const FONT = preload("res://experiments/playable_flightcase/fonts/identity/BarlowCondensed-SemiBold.ttf")
signal gesture_started
signal gesture_finished
var field := ""
var caption := ""
var kind := "rotary"
var labels: Array=[]
var locked := false
var _mode := ""
var _device := 0
var _finger := -1
var _start := Vector2.ZERO
var _start_value := 0.0
var _moved := false
var _pieces: Dictionary={}

func configure(key: String,title: String,style: String,words: Array) -> void:
 field=key;caption=title;kind=style;labels=words.duplicate()
 name="Mixing_"+field
 min_value=0;max_value=maxi(0,labels.size()-1);step=1
 custom_minimum_size=Vector2(144,110 if kind=="switch" else (168 if kind=="fader" else 158))
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 set_meta("musical_axis",field)
 set_meta("finite_detents",labels.size())
 set_meta("source","res://experiments/playable_flightcase/art/mixing_desk/controls_atlas.png")

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_PASS
 focus_mode=Control.FOCUS_ALL
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 value_changed.connect(func(_next: float):_update_caption();queue_redraw())
 focus_entered.connect(queue_redraw)
 focus_exited.connect(func():cancel_gesture();queue_redraw())
 resized.connect(func():cancel_gesture();queue_redraw())
 _update_caption()

func _update_caption() -> void:
 if labels.is_empty():return
 tooltip_text=caption+": "+str(labels[int(value)])+". "+" / ".join(labels)+". Tap or drag; arrow keys change the focused control."

func set_locked(next: bool) -> void:
 locked=next
 if locked:cancel_gesture()
 focus_mode=Control.FOCUS_NONE if locked else Control.FOCUS_ALL
 queue_redraw()

func _piece(id: String,region: Rect2) -> Texture2D:
 if not _pieces.has(id):
  var source:=AtlasTexture.new()
  source.atlas=SOURCE;source.region=region
  _pieces[id]=source
 return _pieces[id]

func input_rect() -> Rect2:
 if kind=="switch":return Rect2(size.x*0.5-63,29,126,48)
 if kind=="fader":return Rect2(size.x*0.5-32,34,64,84)
 return Rect2(size.x*0.5-47,28,94,94)

func _begin(point: Vector2,mode: String,device: int,finger: int=-1) -> void:
 if locked or not _mode.is_empty() or not input_rect().has_point(point):return
 _mode=mode;_device=device;_finger=finger;_start=point;_start_value=value;_moved=false
 grab_focus();gesture_started.emit()
 if kind=="fader":_drag(point)
 queue_redraw()

func _drag(point: Vector2) -> void:
 if point.distance_to(_start)>4:_moved=true
 if kind=="fader":
  value=roundf(clampf((112.0-point.y)/72.0,0.0,1.0)*max_value)
 elif kind=="rotary":value=roundf(clampf(_start_value+(_start.y-point.y)/44.0,min_value,max_value))
 queue_redraw()

func _release(point: Vector2) -> void:
 if _mode.is_empty():return
 if input_rect().has_point(point) and not _moved and kind in ["rotary","switch"]:value=fmod(value+1,max_value+1)
 cancel_gesture()

func cancel_gesture() -> void:
 if _mode.is_empty():return
 _mode="";_finger=-1;_moved=false
 gesture_finished.emit();queue_redraw()

func _gui_input(event: InputEvent) -> void:
 if locked:return
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT and event.pressed and input_rect().has_point(event.position):
   # A raw touch can also produce a mouse press. Reserve the same hardware
   # rectangle so the ancestor scroll never arms a second, emulated gesture.
   if event.device>=0:_begin(event.position,"mouse",event.device)
   accept_event()
 elif event is InputEventScreenTouch:
  if event.pressed and _mode.is_empty() and input_rect().has_point(event.position):
   _begin(event.position,"touch",event.device,event.index);accept_event()
 elif event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_LEFT,KEY_DOWN:value-=1
   KEY_RIGHT,KEY_UP:value+=1
   KEY_HOME:value=min_value
   KEY_END:value=max_value
   KEY_SPACE,KEY_ENTER,KEY_KP_ENTER:value=fmod(value+1,max_value+1)
   _:return
  accept_event()

func _input(event: InputEvent) -> void:
 if _mode.is_empty() or locked:return
 if _mode=="touch" and event.device<0 and (event is InputEventMouseMotion or event is InputEventMouseButton):
  get_viewport().set_input_as_handled();return
 if _mode=="mouse" and event.device==_device:
  if event is InputEventMouseMotion:
   var local: InputEventMouseMotion=make_input_local(event)
   _drag(local.position);get_viewport().set_input_as_handled()
  elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
   var local: InputEventMouseButton=make_input_local(event)
   _release(local.position);get_viewport().set_input_as_handled()
 elif _mode=="touch" and event.device==_device:
  if event is InputEventScreenTouch and event.pressed and event.index!=_finger:
   get_viewport().set_input_as_handled()
  elif event is InputEventScreenDrag and event.index==_finger:
   var local: InputEventScreenDrag=make_input_local(event)
   _drag(local.position);get_viewport().set_input_as_handled()
  elif event is InputEventScreenTouch and event.index==_finger and not event.pressed:
   var local: InputEventScreenTouch=make_input_local(event)
   if event.canceled:cancel_gesture()
   else:_release(local.position)
   get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_EXIT_TREE]:cancel_gesture()
 if what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():cancel_gesture()

func _text(words: String,y: float,points: int=16,color: Color=Color("eee4ce")) -> void:
 var width: float=FONT.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x
 draw_string(FONT,Vector2((size.x-width)*0.5,y),words,HORIZONTAL_ALIGNMENT_LEFT,-1,points,color)

func _draw() -> void:
 if size.x<1 or labels.is_empty():return
 var opacity: float=0.45 if locked else 1.0
 var ink:=Color("eee4ce");ink.a=opacity
 var plate: Texture2D=_piece("plate",Rect2(1030,690,480,165))
 draw_texture_rect(plate,Rect2(6,0,size.x-12,29),false,Color(1,1,1,opacity))
 _text(caption,21,16,Color(0.13,0.09,0.05,opacity))
 var normal: float=value/maxf(1,max_value)
 if kind=="rotary":
  var centre:=Vector2(size.x*0.5,74)
  draw_texture_rect(_piece("knob",Rect2(63,59,449,449)),Rect2(centre-Vector2(44,44),Vector2(88,88)),false,Color(1,1,1,opacity))
  for i in range(labels.size()):
   var angle: float=deg_to_rad(-135+270.0*float(i)/maxf(1,max_value))
   var position: Vector2=centre+Vector2(sin(angle),-cos(angle))*48
   draw_circle(position,2.5,Color("e7b85f") if i==int(value) else Color("665039"))
  var angle: float=deg_to_rad(-135+270*normal)
  var end: Vector2=centre+Vector2(sin(angle),-cos(angle))*31
  var begin: Vector2=centre+Vector2(sin(angle),-cos(angle))*9
  draw_line(begin+Vector2(1,1),end+Vector2(1,1),Color(0,0,0,0.8),5,true)
  draw_line(begin,end,ink,3.5,true)
  _text(str(labels[int(value)]),134,16,ink)
 elif kind=="fader":
  var x: float=size.x*0.5
  draw_style_box(_slot_style(),Rect2(x-7,34,14,84))
  for i in range(labels.size()):
   var y: float=112-float(i)/maxf(1,max_value)*72
   draw_line(Vector2(x-28,y),Vector2(x-15,y),Color("d3bd91"),2,true)
  var cap_y: float=112-normal*72
  draw_texture_rect(_piece("fader",Rect2(1040,175,468,235)),Rect2(x-29,cap_y-13,58,29),false,Color(1,1,1,opacity))
  _text(str(labels[int(value)]),143,16,ink)
 else:
  draw_texture_rect(_piece("housing",Rect2(30,650,480,250)),Rect2(size.x*0.5-64,29,128,49),false,Color(1,1,1,opacity))
  var cap_x: float=lerpf(size.x*0.5-41,size.x*0.5+7,normal)
  draw_texture_rect(_piece("rocker",Rect2(640,590,260,330)),Rect2(cap_x,29,34,48),false,Color(1,1,1,opacity))
  draw_circle(Vector2(size.x*0.5+(-48 if value==0 else 48),53),4,Color("f2b745"))
  _text(str(labels[int(value)]),88,16,ink)
 var alternatives: String=" · ".join(labels) if labels.size()>2 else " ↔ ".join(labels)
 _text(alternatives,108 if kind=="switch" else (165 if kind=="fader" else 156),16,Color(0.78,0.71,0.58,opacity))
 if has_focus():draw_rect(input_rect().grow(2),Color("efc079"),false,2)

func _slot_style() -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("100e0b");style.border_color=Color("89704b")
 style.set_border_width_all(1);style.set_corner_radius_all(6)
 return style
