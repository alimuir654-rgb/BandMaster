extends Node
## One startup attempt per process, after device mute is loaded. No save calls.
const MANIFEST := "res://experiments/playable_flightcase/audio/splash_cue.json"
static var attempted := false
var owner_root: Control
var playing := false
var _player: AudioStreamPlayer

func _ready() -> void:
 name="StartupCue"
 _player=AudioStreamPlayer.new()
 _player.bus="Master"
 add_child(_player)
 _player.finished.connect(stop)
 if attempted:return
 attempted=true
 owner_root.visibility_changed.connect(_visibility_changed)
 get_window().size_changed.connect(stop)
 call_deferred("_start_if_current")

func _allowed() -> bool:
 var bus:=AudioServer.get_bus_index("Master")
 return is_instance_valid(owner_root) and owner_root.is_visible_in_tree() and owner_root.showing_menu and not owner_root.settings_open and get_window().has_focus() and bus>=0 and not AudioServer.is_bus_mute(bus)

func _start_if_current() -> void:
 if not is_inside_tree() or not _allowed() or not FileAccess.file_exists(MANIFEST):return
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(MANIFEST))!=OK or not parser.data is Dictionary:return
 var entry: Dictionary=parser.data
 if entry.get("schema_version")!=1 or entry.get("owner_listening_accepted")!=true:return
 var path: String=str(entry.get("path",""))
 if not path.begins_with("res://") or not ResourceLoader.exists(path):return
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=entry.get("sha256",""):return
 var stream=load(path)
 if not stream is AudioStream or not _allowed():return
 _player.stream=stream
 _player.play()
 playing=true

func stop() -> void:
 if is_instance_valid(_player):_player.stop()
 playing=false

func _visibility_changed() -> void:
 if not owner_root.is_visible_in_tree():stop()

func _process(_delta: float) -> void:
 if playing and not _allowed():stop()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:stop()

func _exit_tree() -> void:
 stop()
