extends Label
## Presentation-only reveal for notes from an already committed, saved action.
## Usage: assign the COMPLETE text and existing native theme/font colours, add
## this node to the visible tree, then call begin(reduced_motion). Never call a
## resolver or save routine from started/finished. Reopened/restored notes should
## simply retain their default full text without calling begin again.
##
## Focus remains on this note after completion. Do not move focus to a commit or
## Continue button from finished: the user must make a separate navigation input.
## Test visible partial -> monotonic -> full glyphs, constant text/rects, local
## tap/Enter/Space completion without key fallthrough, reduced-motion immediate
## full copy, repeated begin/finish, and teardown without a late finished signal.

signal started
signal finished

const NotesStyle = preload("res://experiments/playable_flightcase/notes_style.gd")

const CHARACTERS_PER_SECOND := 48.0
const MAX_DURATION_SECONDS := 4.0
const WRITING_HINT := "Writing saved notes. Tap this note, or focus it and press Enter or Space, to show all."
const COMPLETE_HINT := "Saved action notes."
const TAP_SLOP_PIXELS := 12.0

var _revealing := false
var _motion: Tween
var _epoch := 0
var _touch_index := -1
var _touch_epoch := -1
var _touch_origin := Vector2.ZERO
var _touch_dragged := false
var _mouse_pending := false
var _mouse_epoch := -1
var _mouse_origin := Vector2.ZERO
var _mouse_dragged := false

func _init() -> void:
 add_theme_font_size_override("font_size",16)
 autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 # BEFORE_SHAPING omits unrevealed text from wrapping and size calculations.
 # Keep the complete paragraph shaped so the paper and controls never reflow.
 visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
 visible_characters = -1
 mouse_filter = Control.MOUSE_FILTER_PASS
 focus_mode = Control.FOCUS_ALL
 tooltip_text = COMPLETE_HINT

func _ready() -> void:
 # Caller colours/text are already assigned. Enforce the legible note style
 # after caller overrides; preserve the c58 reveal and gesture implementation.
 add_to_group("bandmaster_notes")
 NotesStyle.apply(self)

func begin(reduced_motion: bool = false) -> void:
 if not is_inside_tree() or is_queued_for_deletion():
  return
 _epoch += 1
 _clear_pointer_gesture()
 var current_epoch: int = _epoch
 _kill_tween()
 _revealing = true
 visible_characters = 0
 tooltip_text = WRITING_HINT
 started.emit()
 # A listener may explicitly finish or free the note during started.
 if not _revealing or current_epoch != _epoch:
  return
 if reduced_motion or text.is_empty() or not is_inside_tree() or not is_visible_in_tree():
  finish_now()
  return
 var duration: float = clampf(float(text.length()) / CHARACTERS_PER_SECOND,0.12,MAX_DURATION_SECONDS)
 _motion = create_tween()
 _motion.set_trans(Tween.TRANS_LINEAR)
 _motion.tween_property(self,"visible_characters",text.length(),duration)
 _motion.finished.connect(_on_tween_finished.bind(current_epoch))

func finish_now() -> void:
 var was_revealing: bool = _revealing
 _epoch += 1
 _revealing = false
 _clear_pointer_gesture()
 _kill_tween()
 visible_characters = -1
 tooltip_text = COMPLETE_HINT
 if was_revealing:
  finished.emit()

func is_revealing() -> bool:
 return _revealing

func _on_tween_finished(current_epoch: int) -> void:
 if _revealing and current_epoch == _epoch:
  finish_now()

func _kill_tween() -> void:
 if _motion != null and _motion.is_valid():
  _motion.kill()
 _motion = null

func _gui_input(event: InputEvent) -> void:
 # Local GUI input only. No _input/_unhandled_input hook or global shortcuts.
 if event is InputEventKey and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
  # Consume release and echoes too. Finishing must not activate another action.
  accept_event()
  if event.pressed and not event.echo:
   finish_now()
 elif event is InputEventScreenTouch:
  if event.pressed and _revealing:
   if _touch_index<0:
    _touch_index = event.index
    _touch_epoch = _epoch
    _touch_origin = get_screen_transform()*event.position
    _touch_dragged = false
    _mouse_pending = false
   elif event.index!=_touch_index:
    # A second finger cannot complete the first finger's pending tap.
    _touch_dragged = true
  elif not event.pressed and event.index==_touch_index:
   var complete: bool = _revealing and _touch_epoch==_epoch and not _touch_dragged and not event.canceled and Rect2(Vector2.ZERO,size).has_point(event.position)
   _clear_pointer_gesture()
   if complete:
    grab_focus()
    finish_now()
    accept_event()
  # Down/drag must reach ScrollContainer; deciding on down blocked scrolling.
 elif event is InputEventScreenDrag and event.index==_touch_index:
  if (get_screen_transform()*event.position).distance_to(_touch_origin)>TAP_SLOP_PIXELS:
   _touch_dragged = true
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  # Touch-emulated mouse (-1) belongs to the touch path. Internal releases
  # (-2, e.g. lost window focus) cancel capture; neither is a deliberate tap.
  if event.device<0:
   if event.device!=-1:
    _clear_pointer_gesture()
   return
  if event.canceled:
   _clear_pointer_gesture()
   return
  if event.pressed and _revealing:
   _mouse_pending = true
   _mouse_epoch = _epoch
   _mouse_origin = get_screen_transform()*event.position
   _mouse_dragged = false
  elif not event.pressed and _mouse_pending:
   var complete: bool = _revealing and _mouse_epoch==_epoch and not _mouse_dragged and Rect2(Vector2.ZERO,size).has_point(event.position)
   _clear_pointer_gesture()
   if complete:
    grab_focus()
    finish_now()
    accept_event()
 elif event is InputEventMouseMotion and _mouse_pending:
  if (get_screen_transform()*event.position).distance_to(_mouse_origin)>TAP_SLOP_PIXELS:
   _mouse_dragged = true

func _clear_pointer_gesture() -> void:
 _touch_index = -1
 _touch_epoch = -1
 _touch_dragged = false
 _mouse_pending = false
 _mouse_epoch = -1
 _mouse_dragged = false

func _notification(what: int) -> void:
 if what==NOTIFICATION_SCROLL_BEGIN or what==NOTIFICATION_RESIZED:
  _clear_pointer_gesture()
 elif what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
  _clear_pointer_gesture()

func _exit_tree() -> void:
 # Teardown never signals successful presentation or dispatches gameplay.
 _epoch += 1
 _revealing = false
 _clear_pointer_gesture()
 _kill_tween()
 visible_characters = -1
 tooltip_text = COMPLETE_HINT
