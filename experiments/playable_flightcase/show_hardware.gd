extends "res://components/control_atlas/bandmaster_premium_dashboard_poc/studio_control.gd"
## S53 SCRATCH candidate. Original artwork/base implementation remain unchanged.
## This control edits a FREE HOST DRAFT only. No resolver, save, cost or time.
## The host must not rebuild/free/commit from level_changed; update preview in place.
## Fixed non-scrolling housing: the whole native control owns a deliberate press.

const APPROACH_CROP := Rect2(60,74,310,265)
const INTENSITY_CROP := Rect2(111,84,147,598)
const APPROACH_CENTRE := Vector2(155,147)
const POINTER_NONE := 0
const POINTER_MOUSE := 1
const POINTER_TOUCH := 2

var _role := "approach"
var _pointer_kind := POINTER_NONE
var _touch_owner := -1
var _touch_device := 0
var _gesture_start_level := 0.0
var _gesture_screen_origin := Vector2.ZERO
var _gesture_screen_travel := 1.0
var _disposed := false
var _changing_interaction := false
var _owner_window: Window

func _init() -> void:
 control_kind="focus"
 custom_minimum_size=Vector2(180,180)
 level=50.0
 set_process(false)
 set_process_input(false)

func configure(role: String, initial: float=50.0) -> bool:
 # Configure before add_child: parent _ready must load the correct source layers.
 if _disposed or is_inside_tree() or role not in ["approach","intensity"] or not is_finite(initial):
  return false
 _role=role
 control_kind="focus" if role=="approach" else "vertical"
 custom_minimum_size=Vector2(180,180) if role=="approach" else Vector2(100,190)
 hydrate_level(initial)
 return true

func _ready() -> void:
 super._ready()
 _sync_interaction()
 focus_entered.connect(queue_redraw)
 focus_exited.connect(queue_redraw)
 _owner_window=get_window()
 if _owner_window!=null:
  _owner_window.focus_exited.connect(_on_window_focus_exited)
 queue_redraw()

func get_role() -> String:
 return _role

func is_gesture_owned() -> bool:
 return _pointer_kind!=POINTER_NONE

func _normalise(value: float) -> float:
 var bounded: float=clampf(value,0.0,100.0)
 return float(roundi(bounded/50.0)*50) if _role=="approach" else float(roundi(bounded))

func hydrate_level(value: float) -> void:
 # Direct assignment suppresses EVERY level_changed callback, even midgesture.
 # Hydration replaces the draft and invalidates any stale pointer release.
 if _disposed or not is_finite(value): return
 _clear_ownership()
 level=_normalise(value)
 queue_redraw()

func set_level(value: float) -> void:
 if _disposed or not is_finite(value): return
 # Preserve original clamping/change-only signal API after role quantisation.
 super.set_level(_normalise(value))

func set_read_only(value: bool) -> void:
 if _disposed: return
 read_only=value
 _sync_interaction()
 if value: cancel_gesture()

func _sync_interaction() -> void:
 _changing_interaction=true
 mouse_filter=Control.MOUSE_FILTER_PASS if read_only else Control.MOUSE_FILTER_STOP
 focus_mode=Control.FOCUS_NONE if read_only else Control.FOCUS_ALL
 mouse_default_cursor_shape=Control.CURSOR_ARROW if read_only else Control.CURSOR_POINTING_HAND
 # Wheel never changes this control; preserve ordinary parent wheel routing.
 mouse_force_pass_scroll_events=true
 _changing_interaction=false
 queue_redraw()

func _source_crop() -> Rect2:
 return APPROACH_CROP if _role=="approach" else INTENSITY_CROP

func get_visual_rect() -> Rect2:
 var source: Rect2=_source_crop()
 if size.x<=0.0 or size.y<=0.0: return Rect2()
 var scale: float=minf(size.x/source.size.x,size.y/source.size.y)
 var fitted: Vector2=source.size*scale
 return Rect2((size-fitted)/2.0,fitted)

func _draw() -> void:
 if _disposed or size.x<=0.0 or size.y<=0.0: return
 var target: Rect2=get_visual_rect()
 var crop: Rect2=_source_crop()
 var scale: float=target.size.x/crop.size.x
 if _role=="approach":
  draw_texture_rect_region(F_BASE,target,crop)
  var lit_count: int=clampi(roundi(level*float(ring_layers.size())/100.0),0,ring_layers.size())
  for index in range(lit_count):
   draw_texture_rect_region(ring_layers[index],target,crop)
  var centre: Vector2=target.position+APPROACH_CENTRE*scale
  draw_set_transform(centre,deg_to_rad(-135.0+level*2.7),Vector2(scale,scale))
  draw_texture(DIAL_POINTER,-DIAL_POINTER.get_size()/2.0)
  draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
 else:
  draw_texture_rect_region(V_BASE,target,crop)
  var cap_top: float=lerpf(416.0,6.0,level/100.0)
  if level>0.0:
   var from: Vector2=target.position+Vector2(84.0,cap_top+122.0)*scale
   var to: Vector2=target.position+Vector2(84.0,546.0)*scale
   draw_line(from,to,Color(highlight,0.32),9.0*scale,true)
   draw_line(from,to,highlight,4.0*scale,true)
  var cap_position: Vector2=target.position+Vector2(26.0,cap_top)*scale
  draw_texture_rect(V_CAP,Rect2(cap_position,Vector2(V_CAP.get_size())*scale),false)
 if has_focus() and not read_only:
  draw_rect(Rect2(Vector2.ZERO,size),Color(highlight,0.85),false,2.0)

func _screen_position(local_position: Vector2) -> Vector2:
 return get_screen_transform()*local_position

func _begin_owned(kind: int, index: int, local_position: Vector2, device: int = 0) -> void:
 if _disposed or read_only or is_gesture_owned(): return
 _pointer_kind=kind
 set_process(kind==POINTER_MOUSE)
 set_process_input(kind==POINTER_TOUCH)
 _touch_owner=index
 _touch_device=device
 _gesture_start_level=level
 _gesture_screen_origin=_screen_position(local_position)
 var fit: Rect2=get_visual_rect()
 var local_travel: float=fit.size.y
 if _role=="intensity":
  local_travel=410.0*fit.size.y/INTENSITY_CROP.size.y
 var transform: Transform2D=get_screen_transform()
 _gesture_screen_travel=maxf(48.0,(transform*Vector2(0,local_travel)-transform*Vector2.ZERO).length())
 dragging=true
 drag_start=local_position
 start_level=level
 grab_focus()

func _level_at(local_position: Vector2) -> float:
 var delta: float=_screen_position(local_position).y-_gesture_screen_origin.y
 return _normalise(_gesture_start_level-delta*100.0/_gesture_screen_travel)

func _clear_ownership() -> void:
 set_process(false)
 set_process_input(false)
 _pointer_kind=POINTER_NONE
 _touch_owner=-1
 _touch_device=0
 dragging=false

func cancel_gesture() -> void:
 if _disposed: return
 _rollback_owned()

func _rollback_owned() -> void:
 # Snapshot/clear FIRST. Synchronous notification may make the host react.
 # No deferred callback/tween exists; an unowned cancellation emits nothing.
 if not is_gesture_owned(): return
 var restored: float=_normalise(_gesture_start_level)
 var changed: bool=not is_equal_approx(level,restored)
 _clear_ownership()
 level=restored
 queue_redraw()
 if changed:
  level_changed.emit(level)

func _finish_owned(local_position: Vector2) -> void:
 var requested: float=_level_at(local_position)
 _clear_ownership()
 # Emit LAST; host updates only its free draft. Release cannot hit a button.
 set_level(requested)

func _gui_input(event: InputEvent) -> void:
 if _disposed or read_only: return
 if event is InputEventKey:
  if not has_focus(): return
  var code: int=event.keycode
  if code==KEY_ESCAPE and is_gesture_owned():
   accept_event()
   if event.pressed and not event.echo: cancel_gesture()
   return
  if code not in [KEY_LEFT,KEY_DOWN,KEY_RIGHT,KEY_UP,KEY_HOME,KEY_END]: return
  accept_event()
  if not event.pressed or event.echo: return
  var current: float=_gesture_start_level if is_gesture_owned() else level
  _clear_ownership()
  var step: float=50.0 if _role=="approach" else 1.0
  var target: float=current-step if code in [KEY_LEFT,KEY_DOWN] else current+step
  if code==KEY_HOME: target=0.0
  elif code==KEY_END: target=100.0
  set_level(target)
 elif event is InputEventScreenTouch:
  if event.canceled:
   if _pointer_kind==POINTER_TOUCH and event.index==_touch_owner and event.device==_touch_device:
    accept_event()
    cancel_gesture()
   return
  if event.pressed:
   if is_gesture_owned(): return
   accept_event()
   _begin_owned(POINTER_TOUCH,event.index,event.position,event.device)
  elif _pointer_kind==POINTER_TOUCH and event.index==_touch_owner and event.device==_touch_device:
   accept_event()
   _finish_owned(event.position)
 elif event is InputEventScreenDrag:
  if _pointer_kind!=POINTER_TOUCH or (event.index!=_touch_owner or event.device!=_touch_device): return
  accept_event()
  set_level(_level_at(event.position))
 elif event is InputEventMouseButton:
  if event.button_index!=MOUSE_BUTTON_LEFT: return
  if event.device<0:
   # Raw touch owns device-1 emulation. Device-2 is a canceled/internal release.
   if event.device!=-1 and is_gesture_owned():
    accept_event()
    cancel_gesture()
   return
  if _pointer_kind==POINTER_TOUCH: return
  if event.canceled:
   if _pointer_kind==POINTER_MOUSE:
    accept_event()
    cancel_gesture()
   return
  if event.pressed:
   if is_gesture_owned(): return
   accept_event()
   _begin_owned(POINTER_MOUSE,-1,event.position)
  elif _pointer_kind==POINTER_MOUSE:
   accept_event()
   _finish_owned(event.position)
 elif event is InputEventMouseMotion:
  if event.device<0 or _pointer_kind!=POINTER_MOUSE: return
  accept_event()
  if (event.button_mask&MOUSE_BUTTON_MASK_LEFT)==0: cancel_gesture()
  else: set_level(_level_at(event.position))

func _on_window_focus_exited() -> void:
 cancel_gesture()

func _notification(what: int) -> void:
 if _disposed or _changing_interaction: return
 if what==NOTIFICATION_FOCUS_EXIT or what==NOTIFICATION_RESIZED or what==NOTIFICATION_SCROLL_BEGIN:
  cancel_gesture()
 elif what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
  cancel_gesture()

func _exit_tree() -> void:
 # Synchronous final FREE-DRAFT rollback while the node is still valid.
 # Ownership/disposal are cleared before emission, and no signal can run later.
 _disposed=true
 if is_instance_valid(_owner_window) and _owner_window.focus_exited.is_connected(_on_window_focus_exited):
  _owner_window.focus_exited.disconnect(_on_window_focus_exited)
 _rollback_owned()

func _process(_delta: float) -> void:
 # Godot can update physical mouse state with an INTERNAL release that is not
 # routed to Control._gui_input. Only an owned mouse needs this safety watch.
 if _pointer_kind==POINTER_MOUSE and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  cancel_gesture()

func _input(event: InputEvent) -> void:
 # GUI capture can be removed by engine mouse↔touch emulation sharing an index.
 # A qualified touch press owns its source until matching release/cancel, even
 # when that subsequent event is no longer delivered to Control._gui_input.
 if _disposed or read_only or _pointer_kind!=POINTER_TOUCH or not is_visible_in_tree():return
 if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return
 if event.index!=_touch_owner or event.device!=_touch_device:return
 get_viewport().set_input_as_handled()
 var local: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
 if event is InputEventScreenTouch:
  if event.canceled:cancel_gesture()
  elif not event.pressed:_finish_owned(local)
 else:
  set_level(_level_at(local))
