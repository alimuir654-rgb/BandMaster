extends Node
## Candidate-only feedback. No autoload, external samples, music or save changes.
## The service lives outside rebuilt UI so navigation cannot truncate a cue.
const NODE_NAME := "CandidateUIAudio"
const SETTINGS_PATH := "user://c27_audio_settings.cfg"
const RATE := 22050
const VOICES := 2
const COOLDOWN_MS := 70
const CUES := ["click", "confirm", "back"]

var muted := false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last_play_ms := -COOLDOWN_MS

static func shared(tree: SceneTree) -> Node:
 var service: Node = tree.root.get_node_or_null(NodePath(NODE_NAME))
 if service == null:
  service = load("res://experiments/playable_flightcase/ui_audio.gd").new()
  service.name = NODE_NAME
  tree.root.add_child(service)
 return service

func _ready() -> void:
 for cue in CUES:
  _streams[cue] = make_stream(cue)
 for index in VOICES:
  var player := AudioStreamPlayer.new()
  player.name = "Voice%d" % index
  player.volume_db = -6.0
  player.process_mode = Node.PROCESS_MODE_ALWAYS
  add_child(player)
  _players.append(player)
 var settings := ConfigFile.new()
 if settings.load(SETTINGS_PATH) == OK:
  var saved: Variant = settings.get_value("audio", "muted", false)
  if saved is bool:
   muted = saved
  AudioServer.set_bus_mute(0, muted)
 else:
  muted = AudioServer.is_bus_mute(0)

func bind_button(button: Button, cue: String = "click") -> void:
 if button.has_meta("candidate_audio_bound"):
  return
 button.set_meta("candidate_audio_bound", true)
 button.pressed.connect(_on_pressed.bind(button, cue))
 # Hover and keyboard focus intentionally stay silent.

func _on_pressed(button: Button, cue: String) -> void:
 if not button.disabled:
  play_cue(cue)

func play_cue(cue: String) -> bool:
 if muted or AudioServer.is_bus_mute(0) or not _streams.has(cue):
  return false
 var now := Time.get_ticks_msec()
 if now - _last_play_ms < COOLDOWN_MS:
  return false
 for player in _players:
  if not player.playing:
   player.stream = _streams[cue]
   player.play()
   _last_play_ms = now
   return true
 return false

func set_muted(value: bool) -> Error:
 muted = value
 AudioServer.set_bus_mute(0, value)
 if value:
  for player in _players:
   player.stop()
 var settings := ConfigFile.new()
 settings.set_value("audio", "muted", muted)
 return settings.save(SETTINGS_PATH)

static func make_stream(cue: String) -> AudioStreamWAV:
 if cue not in CUES:
  return null
 var seconds := 0.065 if cue == "click" else 0.20
 var count := int(RATE * seconds)
 var bytes := PackedByteArray()
 bytes.resize(count * 2)
 var random := RandomNumberGenerator.new()
 random.seed = 2718
 for index in count:
  var t := float(index) / RATE
  var sample := 0.0
  if cue == "click":
   # Damped low hardware tap with a brief soft contact transient.
   sample = sin(TAU * 185.0 * t) * exp(-t * 85.0) * 0.16
   sample += random.randf_range(-1.0, 1.0) * exp(-t * 420.0) * 0.04
  else:
   # A short rising/falling interval; no looping bed or generated song.
   var first := 659.25 if cue == "confirm" else 440.0
   var second := 880.0 if cue == "confirm" else 329.63
   sample = sin(TAU * first * t) * exp(-t * 40.0) * 0.13
   var delayed := t - 0.065
   if delayed > 0.0:
    sample += sin(TAU * second * delayed) * exp(-delayed * 38.0) * minf(delayed / 0.003, 1.0) * 0.13
  # Exact zero endpoints and 3ms/10ms ramps prevent PCM edge clicks.
  var edge := minf(minf(t / 0.003, float(count - 1 - index) / RATE / 0.01), 1.0)
  bytes.encode_s16(index * 2, int(clampf(sample * edge, -0.22, 0.22) * 32767.0))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = RATE
 stream.stereo = false
 stream.data = bytes
 return stream
