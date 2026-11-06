extends Node
## Owned illustration of a finite saved/local recipe. No career/model/save methods.
const Recipe = preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Approval = preload("res://experiments/playable_flightcase/audition_audio.gd")
const PARTS := ["main","answer","bass","kit"]
signal status_changed
var playing := false
var manifest_path := Recipe.MANIFEST
var _context: Callable
var _manifest: Dictionary={}
var _players: Array[AudioStreamPlayer]=[]
var _buses: Array[String]=[]
var _active: Dictionary={}
var _entry_active: Dictionary={}
var _poll := 0.0
var _last_status := ""

func configure(context: Callable) -> void:
 _context=context

func _ready() -> void:
 add_to_group("SavedArrangementAudio")
 if FileAccess.file_exists(manifest_path):
  var parser:=JSON.new()
  if parser.parse(FileAccess.get_file_as_string(manifest_path))==OK and parser.data is Dictionary:_manifest=parser.data
 for part in PARTS:
  var player:=AudioStreamPlayer.new()
  player.name="MixStem_"+part
  add_child(player);_players.append(player)
 _players[0].finished.connect(stop)

func muted() -> bool:
 var master: int=AudioServer.get_bus_index("Master")
 return master<0 or AudioServer.is_bus_mute(master)

func current_recipe() -> Dictionary:
 if not is_inside_tree() or not _context.is_valid():return {}
 var ancestor: Node=get_parent()
 while ancestor!=null:
  if ancestor is CanvasItem and not ancestor.is_visible_in_tree():return {}
  ancestor=ancestor.get_parent()
 var context: Dictionary=_context.call()
 return context.recipe.duplicate(true) if context.get("allowed",false) and Recipe.valid(context.get("recipe")) else {}

func _entry(value: Dictionary) -> Dictionary:
 if not Recipe.audio_supported(value) or _manifest.get("schema_version")!=1 or _manifest.get("content_version")!=Recipe.VERSION or not _manifest.get("scenarios") is Dictionary:return {}
 var entry: Variant=_manifest.scenarios.get(Recipe.scenario_key(value))
 if not entry is Dictionary or not entry.get("parts") is Dictionary or entry.parts.size()!=4 or not Recipe.whole(entry.get("frames"),1,100000000) or entry.get("sample_rate")!=48000:return {}
 var tempo: int=Recipe.TEMPOS[Recipe.VALUES[1].find(value.pace)]
 if entry.get("tempo")!=tempo or not (entry.get("music_seconds") is int or entry.get("music_seconds") is float):return {}
 if not is_finite(float(entry.music_seconds)) or absf(float(entry.music_seconds)-32.0*60.0/tempo)>0.001:return {}
 if absf(float(entry.frames)/48000.0-float(entry.music_seconds)-2.4)>0.001:return {}
 for part in PARTS:
  var material: Variant=entry.parts.get(part)
  if not material is Dictionary or not Approval.entry_approved(material):return {}
  var path: String=str(material.get("path",""))
  if not path.begins_with("res://experiments/playable_flightcase/audio/producer/mixing_desk_v1/") or not ResourceLoader.exists(path):return {}
  if not material.get("sha256") is String or material.sha256.length()!=64:return {}
  if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=material.sha256:return {}
 return entry

func available() -> bool:
 return not _entry(current_recipe()).is_empty()

func hint() -> String:
 var value: Dictionary=current_recipe()
 if muted():return "Sound is off. The written idea and session remain available."
 if not Recipe.valid(value):return "Review the current song direction."
 if not Recipe.audio_supported(value):return "This style has written ideas; there isn't a matching demo yet."
 if _entry(value).is_empty():return "Demo unavailable. You can read the direction and continue writing."
 return "Instrumental sketch of this direction · not a recording of your musicians."

func _new_bus(name: String,send: String) -> int:
 AudioServer.add_bus()
 var index: int=AudioServer.bus_count-1
 AudioServer.set_bus_name(index,name)
 AudioServer.set_bus_send(index,send)
 _buses.append(name)
 return index

func _create_buses(value: Dictionary) -> void:
 var prefix: String="Mixing-%d-" % get_instance_id()
 var main: int=_new_bus(prefix+"sum","Master")
 var amplify:=AudioEffectAmplify.new()
 amplify.volume_db=float(_manifest.get("master_gain_db",0.0))+float(_manifest.get("stage_post_gain_db",{}).get(str(int(value.stage)),0.0))
 AudioServer.add_bus_effect(main,amplify)
 var limiter:=AudioEffectLimiter.new()
 limiter.ceiling_db=-3.0
 limiter.threshold_db=-6.0
 AudioServer.add_bus_effect(main,limiter)
 for i in range(PARTS.size()):
  var index: int=_new_bus(prefix+PARTS[i],prefix+"sum")
  var pan:=AudioEffectPanner.new()
  pan.pan=-0.22 if i==0 else (0.22 if i==1 else 0.0)
  AudioServer.add_bus_effect(index,pan)
  if i<2:
   if value.tone=="biting":
    var drive:=AudioEffectDistortion.new()
    drive.mode=AudioEffectDistortion.MODE_ATAN
    drive.drive=0.18;drive.pre_gain=2.0;drive.post_gain=-2.5
    AudioServer.add_bus_effect(index,drive)
   var filter:=AudioEffectLowPassFilter.new()
   filter.cutoff_hz={"warm":1800.0,"gritty":3600.0,"biting":5200.0}[value.tone]
   filter.resonance=0.5
   AudioServer.add_bus_effect(index,filter)
  _players[i].bus=prefix+PARTS[i]

func request_play() -> bool:
 stop()
 var value: Dictionary=current_recipe()
 var entry: Dictionary=_entry(value)
 if muted() or entry.is_empty():status_changed.emit();return false
 var streams: Array[AudioStream]=[]
 for part in PARTS:
  var stream: AudioStream=load(str(entry.parts[part].path)) as AudioStream
  if stream==null or absf(stream.get_length()-float(entry.frames)/48000.0)>0.01:return false
  streams.append(stream)
 _active=value.duplicate(true);_entry_active=entry.duplicate(true)
 _create_buses(value)
 set_meta("start_process_frame",Engine.get_process_frames())
 set_meta("playing_stage",int(value.stage))
 set_meta("scenario_key",Recipe.scenario_key(value))
 set_meta("source_frames",int(entry.frames))
 for i in range(PARTS.size()):
  _players[i].stream=streams[i]
  var initial: float=1.0
  if value.shape=="build":initial=0.32 if i==0 and int(value.stage)==0 else (1.0 if i==0 else 0.0)
  _players[i].volume_db=float(_manifest.get("part_gain_db",{}).get(PARTS[i],0.0))+(linear_to_db(initial) if initial>0 else -80.0)
  if i==0 or (i==1 and int(value.stage)==2) or (i>=2 and int(value.stage)>=1):_players[i].play()
 playing=true
 _shape()
 for other in get_tree().get_nodes_in_group("SavedArrangementAudio"):
  if other!=self and other.has_method("stop"):other.stop()
 status_changed.emit()
 return true

func _shape() -> void:
 if not playing or _active.is_empty():return
 var seconds: float=maxf(0,_players[0].get_playback_position())
 var beat: float=seconds*float(_entry_active.tempo)/60.0
 var build: bool=_active.shape=="build"
 var stage: int=int(_active.stage)
 for i in range(PARTS.size()):
  var gain: float=1.0
  if i==1 and stage<2:gain=0
  if i>=2 and stage<1:gain=0
  if build:
   if i==0 and stage==0:
    # A restrained opening phrase, then the same riff arrives in full.
    gain*=lerpf(0.32,1.0,clampf((beat-4.0)/8.0,0,1))
   elif i==1:gain*=clampf((beat-16.0)/4.0,0,1)
   elif i==2:gain*=clampf((beat-4.0)/4.0,0,1)
   elif i==3:gain*=clampf((beat-8.0)/4.0,0,1)
  var base: float=float(_manifest.get("part_gain_db",{}).get(PARTS[i],0.0))
  _players[i].volume_db=base+(linear_to_db(gain) if gain>0.0001 else -80.0)

func stop() -> void:
 for player in _players:
  if is_instance_valid(player):player.stop();player.stream=null;player.bus="Master"
 playing=false;_active={};_entry_active={}
 for i in range(_buses.size()-1,-1,-1):
  var index: int=AudioServer.get_bus_index(_buses[i])
  if index>0:AudioServer.remove_bus(index)
 _buses.clear()
 status_changed.emit()

func _process(delta: float) -> void:
 if playing:_shape()
 _poll+=delta
 if _poll<0.15:return
 _poll=0
 var value: Dictionary=current_recipe()
 if playing and (muted() or value!=_active or _entry(value).is_empty()):stop()
 var status: String=str(playing)+":"+str(muted())+":"+str(not _entry(value).is_empty())
 if status!=_last_status:_last_status=status;status_changed.emit()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:stop()

func _exit_tree() -> void:
 stop()

static func attach_controls(parent: Node,value: Dictionary,context: Callable) -> void:
 var C=preload("res://experiments/playable_flightcase/career_components.gd")
 var row:=HBoxContainer.new();row.name="SavedMixingArrangement";row.add_theme_constant_override("separation",8);parent.add_child(row)
 var audio=load("res://experiments/playable_flightcase/mixing_audio.gd").new()
 audio.configure(func():return {"allowed":bool(context.call()),"recipe":value.duplicate(true)})
 row.add_child(audio)
 var play: Button=C.button("PLAY SAVED TAKE")
 var stop_button: Button=C.button("STOP")
 row.add_child(play);row.add_child(stop_button)
 var refresh: Callable=func():
  if not is_instance_valid(play) or not is_instance_valid(audio):return
  play.disabled=audio.muted() or not audio.available();play.text="SOUND OFF" if audio.muted() else ("PLAY SAVED TAKE" if audio.available() else "WRITTEN DIRECTION")
  play.tooltip_text=audio.hint();stop_button.disabled=not audio.playing
 audio.status_changed.connect(refresh)
 play.pressed.connect(audio.request_play);stop_button.pressed.connect(audio.stop)
 row.resized.connect(audio.stop)
 row.visibility_changed.connect(func():
  if not row.is_visible_in_tree():audio.stop())
 refresh.call()
