extends Control
## One earned presentation after a successful identity save. No owner writes.
const AudioPart=preload("res://experiments/playable_flightcase/audition_audio.gd")
const EXAMPLES="res://experiments/playable_flightcase/audio/genre_examples.json"
var _poster: Control
var _context: Callable
var _audio
var _tween: Tween
var _active := false
var _poll := 0.0
var _material := ""

func begin(poster: Control, genre: String, reduced: bool, context: Callable) -> void:
 name="FormationMoment"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_mode=Control.FOCUS_NONE
 _poster=poster
 _context=context
 _active=true
 if not reduced:
  _poster.modulate.a=0.0
  _tween=create_tween()
  _tween.tween_property(_poster,"modulate:a",1.0,1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 var catalogue: Variant=JSON.parse_string(FileAccess.get_file_as_string(EXAMPLES)) if FileAccess.file_exists(EXAMPLES) else null
 if catalogue is Dictionary and catalogue.get("schema_version")==1 and catalogue.get("content_version")=="genre_examples_v1" and catalogue.get("genres") is Dictionary:
  var id: Variant=catalogue.genres.get(genre,"")
  if id is String:_material=id
 if not _material.is_empty():
  _audio=AudioPart.new()
  _audio.controls_visible=false
  _audio.manifest_path=EXAMPLES
  _audio.configure(_audio_context)
  _audio.set_clip(_material)
  add_child(_audio)
  call_deferred("_start_audio")

func _allowed() -> bool:
 return _active and is_visible_in_tree() and _context.is_valid() and bool(_context.call())

func _audio_context() -> Dictionary:
 return {"allowed":_allowed(),"material_id":_material,"content_version":"genre_examples_v1"}

func _start_audio() -> void:
 if _allowed() and is_instance_valid(_audio):_audio.request_play()

func cancel() -> void:
 _active=false
 if _tween!=null and _tween.is_valid():_tween.kill()
 if is_instance_valid(_poster):_poster.modulate.a=1.0
 if is_instance_valid(_audio):_audio.release_stream()

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
