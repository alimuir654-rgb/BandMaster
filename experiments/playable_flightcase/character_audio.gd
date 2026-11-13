extends VBoxContainer
## Independent recorded ideas, never answers to the fingerprinted written exercise.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const PackedPcm=preload("res://experiments/playable_flightcase/packed_pcm.gd")
const NEW_MANIFEST="res://experiments/playable_flightcase/audio/recorded_indie39/characters.json"
const MANIFEST="res://experiments/playable_flightcase/audio/character_indie29/manifest.json"
var paper:=false
var candidate_id: String
var role: String
var context: Callable
var _player: AudioStreamPlayer
var _materials: Array=[]
var _registry: Dictionary={}
var playing:=false

static func attach(parent: Node,id: String,instrument: String,current: Callable,on_paper: bool=false) -> void:
 var source: String=NEW_MANIFEST if instrument in ["Singer","Keyboardist"] else MANIFEST
 if not FileAccess.file_exists(source):return
 var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
 if not data is Dictionary or data.get("schema_version")!=1:return
 var entry: Variant=data.get("characters",{}).get(id)
 if not entry is Dictionary or entry.get("role")!=instrument:return
 var view=load("res://experiments/playable_flightcase/character_audio.gd").new()
 view.paper=on_paper
 view.candidate_id=id;view.role=instrument;view.context=current;view._materials=entry.materials.duplicate();view._registry=data.materials
 parent.add_child(view)

func _ready() -> void:
 name="CharacterRecordedIdeas"
 add_to_group("recorded_character_ideas")
 add_theme_constant_override("separation",6)
 _player=AudioStreamPlayer.new();_player.bus="Master";add_child(_player);_player.finished.connect(stop)
 var heading: Label=Poster.label("A DIFFERENT IDEA",18,Poster.INK if paper else Poster.PAPER);add_child(heading)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);add_child(row)
 for i in range(_materials.size()):
  var action: Button=Poster.button("HEAR IDEA %d" % (i+1));action.name="CharacterIdea_%d" % i
  action.custom_minimum_size.y=48;action.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  action.pressed.connect(_play.bind(str(_materials[i])));row.add_child(action)
 var action: Button=Poster.button("STOP");action.name="CharacterIdeaStop";action.custom_minimum_size.y=48;action.pressed.connect(stop);add_child(action)
 tooltip_text="A separate recorded sketch, not a performed response to the written try-out. AI-generated Suno audio."
 visibility_changed.connect(func():
  if not is_visible_in_tree():stop())
 get_window().size_changed.connect(stop)

func _allowed() -> bool:
 return is_inside_tree() and is_visible_in_tree() and context.is_valid() and bool(context.call()) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))

func _play(material: String) -> void:
 stop()
 if not _allowed() or material not in _materials:return
 var entry: Dictionary=_registry.get(material,{})
 var path: String=str(entry.get("path",""))
 var new_source: bool=role in ["Singer","Keyboardist"]
 var prefix: String="res://experiments/playable_flightcase/audio/recorded_indie39/" if new_source else "res://experiments/playable_flightcase/audio/character_indie29/"
 if not path.begins_with(prefix) or not PackedPcm.exists(path):return
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=entry.get("sha256"):return
 var authority: String="owner_approved_nina_20261111" if candidate_id=="cast_nina" else ("owner_approved_first_excerpt_pairs_20261110" if new_source else "owner_request_20261109")
 var revised: bool=candidate_id in ["cast_arjun","cast_casey"] and entry.get("integration_authority")=="owner_requested_audio_revision_20261111"
 if (entry.get("integration_authority")!=authority and not revised) or entry.get("integration_review_accepted")!=true:return
 var stream=PackedPcm.stream(path,int(entry.get("frames",0)),str(entry.get("pcm_sha256","")),str(entry.get("sha256",""))) if path.ends_with(".wav") else load(path)
 if not stream is AudioStream:return
 var top: Node=self
 while top.get_parent() is Control:top=top.get_parent()
 for player in top.find_children("*","AudioStreamPlayer",true,false):
  if player!=_player and player.get_parent().has_method("stop"):player.get_parent().call("stop")
 _player.stream=stream;_player.play();playing=true

func stop() -> void:
 if is_instance_valid(_player):_player.stop();_player.stream=null
 playing=false

func _process(_delta: float) -> void:
 if playing and not _allowed():stop()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:stop()

func _exit_tree() -> void:
 stop()
