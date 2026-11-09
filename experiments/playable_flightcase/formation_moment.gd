extends Control
## One earned presentation after a successful identity save. No owner writes.
const AudioPart=preload("res://experiments/playable_flightcase/formation_sound.gd")
var _poster: Control
var _context: Callable
var _audio
var _tween: Tween
var _active := false
var _poll := 0.0
var _material := ""

func begin(poster: Control, genre: String, reduced: bool, context: Callable, roster: Array=[], intent: String="Raw", vibe: String="Unpolished") -> void:
 name="FormationMoment"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_mode=Control.FOCUS_NONE
 _poster=poster
 _context=context
 _active=true
 if not reduced:
  _poster.modulate.a=0.0
  _tween=create_tween()
  _tween.tween_property(_poster,"modulate:a",1.0,0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 if genre!="Indie rock":return # Legacy other-genres never receive an indie cue.
 _audio=AudioPart.new()
 _audio.configure(roster,intent,vibe,_allowed)
 add_child(_audio)
 _material=_audio.family

func _allowed() -> bool:
 return _active and is_visible_in_tree() and _context.is_valid() and bool(_context.call())

func cancel() -> void:
 _active=false
 if _tween!=null and _tween.is_valid():_tween.kill()
 if is_instance_valid(_poster):_poster.modulate.a=1.0
 if is_instance_valid(_audio):_audio.stop()

func _process(delta: float) -> void:
 if not _active:return
 _poll+=delta
 if _poll<0.1:return
 _poll=0.0
 if not _allowed():cancel()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:cancel()
 if what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():cancel()

func _exit_tree() -> void:
 cancel()
