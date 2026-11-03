extends HBoxContainer
## Presentation only. No Game/model/save calls; caller supplies revealed context.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
var manifest_path := "res://experiments/playable_flightcase/audio/audition_clips.json"
var playing := false
var play_button: Button
var stop_button: Button
var _player: AudioStreamPlayer
var _context: Callable
var _material := ""
var _poll := 0.0
var _manifest: Dictionary = {}

func configure(context: Callable) -> void:
 _context=context

func _ready() -> void:
 name="AuditionAudio"
 add_theme_constant_override("separation",8)
 play_button=C.button("PLAY PART")
 play_button.name="AuditionAudioPlay"
 stop_button=C.button("STOP")
 stop_button.name="AuditionAudioStop"
 for button in [play_button,stop_button]:
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.mouse_filter=Control.MOUSE_FILTER_PASS
  add_child(button)
 _player=AudioStreamPlayer.new()
 _player.bus="Master"
 add_child(_player)
 _player.finished.connect(stop)
 play_button.pressed.connect(_play)
 stop_button.pressed.connect(stop)
 if FileAccess.file_exists(manifest_path):
  var parser:=JSON.new()
  if parser.parse(FileAccess.get_file_as_string(manifest_path))==OK and parser.data is Dictionary:
   _manifest=parser.data
 _refresh()

func set_clip(id: String) -> void:
 stop()
 _material=id
 if is_node_ready():_refresh()

func _entry() -> Dictionary:
 if not is_visible_in_tree() or not _context.is_valid():return {}
 var context: Dictionary=_context.call()
 if not context.get("allowed",false) or context.get("material_id","")!=_material:return {}
 if _manifest.get("schema_version")!=1:return {}
 if context.get("content_version","")!=_manifest.get("content_version",""):return {}
 var entries: Dictionary=_manifest.get("materials",{})
 var entry: Dictionary=entries.get(_material,{})
 if not entry.get("owner_listening_accepted",false):return {}
 var path: String=str(entry.get("path",""))
 if not path.begins_with("res://") or not ResourceLoader.exists(path):return {}
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=entry.get("sha256",""):return {}
 return entry

func _muted() -> bool:
 var index:=AudioServer.get_bus_index("Master")
 return index<0 or AudioServer.is_bus_mute(index)

func _refresh() -> void:
 if play_button==null:return
 var available:=not _entry().is_empty()
 play_button.disabled=not available or _muted()
 play_button.text="SOUND MUTED" if _muted() else ("PLAY PART" if available else "NO AUDIO")
 play_button.tooltip_text="Master sound is muted." if _muted() else ("Hear the revealed written part." if available else "Audio is unavailable for this part; the written sketch remains available.")
 stop_button.disabled=not playing

func _play() -> void:
 stop()
 var entry:=_entry()
 if entry.is_empty() or _muted():
  _refresh()
  return
 var stream=load(str(entry["path"]))
 if not stream is AudioStream:
  _refresh()
  return
 _player.stream=stream
 _player.play()
 playing=true
 _refresh()

func stop() -> void:
 if is_instance_valid(_player):_player.stop()
 playing=false
 if is_instance_valid(stop_button):stop_button.disabled=true

func _process(delta: float) -> void:
 if playing and _muted():stop()
 _poll+=delta
 if _poll<0.1:return
 _poll=0.0
 if playing and _entry().is_empty():stop()
 _refresh()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:stop()
 if what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():stop()

func _exit_tree() -> void:
 stop()
