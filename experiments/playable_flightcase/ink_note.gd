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

const CHARACTERS_PER_SECOND := 48.0
const MAX_DURATION_SECONDS := 4.0
const WRITING_HINT := "Writing saved notes. Tap this note, or focus it and press Enter or Space, to show all."
const COMPLETE_HINT := "Saved action notes."

var _revealing := false
var _motion: Tween
var _epoch := 0

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

func begin(reduced_motion: bool = false) -> void:
 _epoch += 1
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
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and _revealing:
  accept_event()
  if event.pressed:
   grab_focus()
   finish_now()
 elif event is InputEventScreenTouch and _revealing:
  accept_event()
  if event.pressed:
   grab_focus()
   finish_now()

func _exit_tree() -> void:
 # Teardown never signals successful presentation or dispatches gameplay.
 _epoch += 1
 _revealing = false
 _kill_tween()
 visible_characters = -1
 tooltip_text = COMPLETE_HINT
