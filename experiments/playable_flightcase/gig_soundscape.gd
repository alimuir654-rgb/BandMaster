extends Node
## Presentation owner, retained across redraws. Only saved-event dispatch starts it.
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
const Music=preload("res://experiments/playable_flightcase/mixing_audio.gd")
const PREFIX="res://experiments/playable_flightcase/audio/crowd37/"
const CREDITS="res://experiments/playable_flightcase/audio/crowd37_credits.txt"
const SOURCES={"entrance":"2479","song":"2486","courtesy":"3521","cheer":"35748"}
var manifest_path: String=PREFIX+"manifest.json"
var event_id: String=""
var event_kind: String=""
var starts: int=0
var effect_available:=false
var _source_token: String=""
var _context: Callable
var _recipe: Dictionary={}
var _seen: Array[String]=[]
var _music
var _crowd: AudioStreamPlayer
var _fade: Tween
var _queued:=0
var _elapsed:=0.0
var _poll:=0.0
func configure(context: Callable) -> void:_context=context
func _ready() -> void:
 name="GigSoundscape"
 _music=Music.new();_music.configure(_music_context);add_child(_music)
 _crowd=AudioStreamPlayer.new();_crowd.bus="Master";add_child(_crowd)
 _crowd.finished.connect(_release_effect)
 get_window().size_changed.connect(stop)
func _allowed() -> bool:
 if not is_inside_tree() or not _context.is_valid():return false
 var view: Dictionary=_context.call();var master: int=AudioServer.get_bus_index("Master")
 return view.get("allowed",false) and view.get("identity","")==event_id and not event_id.is_empty() and not _source_token.is_empty() and view.get("source_token","")==_source_token and get_window().has_focus() and master>=0 and not AudioServer.is_bus_mute(master)
func _music_context() -> Dictionary:return {"allowed":_allowed(),"recipe":_recipe}
func on_saved(before: Dictionary,after: Dictionary,action: String) -> void:
 var event: Dictionary=Crowd.saved_event(before,after,action)
 if event.is_empty():return
 var key: String=str(event.id)
 if _seen.has(key):return
 stop();_seen.append(key)
 if _seen.size()>48:_seen.pop_front()
 event_id=key;event_kind=str(event.kind);_recipe=event.recipe.duplicate(true)
 if _context.is_valid():_source_token=str(_context.call().get("source_token",""))
 # A muted/hidden event is spent. Never start later when permission returns.
 if not _allowed():return
 _queued+=1
 call_deferred("_start_once",_queued,key)
func _effect_stream(kind: String) -> AudioStream:
 if not FileAccess.file_exists(manifest_path):return null
 var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
 if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("content_version")!="crowd37" or raw.get("authority")!="owner_approved_table_20261110" or not raw.get("effects") is Dictionary:return null
 # The old applause/boo shortlist was rejected. No legacy or negative-cue fallback.
 if kind not in SOURCES:return null
 var entry: Variant=raw.effects.get(kind)
 if not entry is Dictionary or entry.get("integration_review_accepted")!=true or entry.get("owner_source_listening_accepted")!=true or entry.get("authority")!="owner_approved_table_20261110" or entry.get("source_id")!=SOURCES[kind]:return null
 if not entry.get("sha256") is String or entry.sha256.length()!=64 or not entry.get("source_sha256") is String or entry.source_sha256.length()!=64:return null
 if entry.get("license")!=("CC-BY-4.0" if kind=="cheer" else "CC0-1.0"):return null
 if kind=="cheer":
  if entry.get("attribution_path")!=CREDITS or not FileAccess.file_exists(CREDITS) or FileAccess.get_sha256(CREDITS)!=entry.get("attribution_sha256"):return null
 var path: String=str(entry.get("path",""))
 if path!=PREFIX+kind+".ogg" or not ResourceLoader.exists(path):return null
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=entry.get("sha256"):return null
 var stream=load(path)
 if not stream is AudioStream or stream.get_length()<=0 or stream.get_length()>9.0:return null
 return stream
func _start_once(serial: int,key: String) -> void:
 if serial!=_queued or key!=event_id or not _allowed():return
 starts+=1;_elapsed=0.0
 if not _recipe.is_empty():_music.request_play()
 var effect: AudioStream=_effect_stream("entrance" if event_kind=="entrance" else event_kind)
 effect_available=effect!=null
 if effect!=null:
  _crowd.stream=effect;_crowd.volume_db=-55.0;_crowd.play()
  _fade=create_tween()
  # Fade a room reaction in, then below the actual arrangement and away.
  _fade.tween_property(_crowd,"volume_db",-19.0 if _music.playing else -13.0,0.30)
  # Preserve a fuller approved end-of-show reaction; other cues stay brief.
  var hold_limit: float=4.8 if event_kind=="cheer" else 2.4
  _fade.tween_interval(minf(hold_limit,maxf(0.0,effect.get_length()-1.2)))
  _fade.tween_property(_crowd,"volume_db",-55.0,0.85)
  _fade.tween_callback(_release_effect)
func _release_effect() -> void:
 if is_instance_valid(_crowd):_crowd.stop();_crowd.stream=null
func stop() -> void:
 _queued+=1
 if _fade!=null and _fade.is_valid():_fade.kill()
 _fade=null
 if is_instance_valid(_music):_music.stop()
 _release_effect();event_id="";_source_token="";_recipe={};effect_available=false
func playing() -> bool:return is_instance_valid(_music) and _music.playing or is_instance_valid(_crowd) and _crowd.playing
func _process(delta: float) -> void:
 _elapsed+=delta;_poll+=delta
 if _poll<0.05:return
 _poll=0.0
 if not event_id.is_empty() and not _allowed():stop()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:stop()
func _exit_tree() -> void:stop()
