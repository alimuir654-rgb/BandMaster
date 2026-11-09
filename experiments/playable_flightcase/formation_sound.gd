extends Node
## One same-family six-second preview, chosen from direction then actual lineup.
const MANIFEST="res://experiments/playable_flightcase/audio/formation_next32/manifest.json"
var family: String=""
var playing:=false
var _context: Callable
var _player: AudioStreamPlayer
static func choose(roster: Array,intent: String,vibe: String) -> String:
 if intent=="Dark" or vibe=="Nocturnal":return "dark"
 if intent=="Dreamy" or vibe=="Atmospheric":return "space"
 for person in roster:
  if person.get("id") in ["cast_bex","cast_casey"]:return "dark"
 for person in roster:
  if person.get("id")=="cast_arjun":return "space"
 return "guitar90"
func configure(roster: Array,intent: String,vibe: String,context: Callable) -> void:
 family=choose(roster,intent,vibe);_context=context
func _ready() -> void:
 _player=AudioStreamPlayer.new();_player.bus="Master";add_child(_player)
 _player.finished.connect(stop)
 call_deferred("_start")
func _allowed() -> bool:
 var bus: int=AudioServer.get_bus_index("Master")
 return is_inside_tree() and _context.is_valid() and bool(_context.call()) and get_window().has_focus() and bus>=0 and not AudioServer.is_bus_mute(bus)
func _start() -> void:
 if not _allowed() or not FileAccess.file_exists(MANIFEST):return
 var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
 if not raw is Dictionary or raw.get("content_version")!="formation_next32" or not raw.get("materials") is Dictionary:return
 var entry: Variant=raw.materials.get(family)
 if not entry is Dictionary or entry.get("same_family_only")!=true or entry.get("integration_review_accepted")!=true or entry.get("integration_authority")!="owner_approved_LOOK31_direction":return
 var path: String=str(entry.get("path",""))
 if not path.begins_with("res://experiments/playable_flightcase/audio/formation_next32/") or not ResourceLoader.exists(path):return
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=entry.get("sha256"):return
 var stream=load(path)
 if not stream is AudioStream or not _allowed():return
 _player.stream=stream;_player.play();playing=true
func stop() -> void:
 if is_instance_valid(_player):_player.stop();_player.stream=null
 playing=false
func _process(_delta: float) -> void:
 if playing and not _allowed():stop()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:stop()
func _exit_tree() -> void:stop()
