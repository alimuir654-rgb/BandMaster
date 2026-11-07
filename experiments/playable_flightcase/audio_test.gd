extends SceneTree
const Feedback = preload("res://experiments/playable_flightcase/ui_audio.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures.append(label)
  push_error("AUDIO FAILURE: " + label)

func wait_ms(milliseconds: int) -> void:
 var until := Time.get_ticks_msec() + milliseconds
 while Time.get_ticks_msec() < until:
  await process_frame

func run() -> void:
 # This script runs in the separately assembled candidate test project.
 var existed := FileAccess.file_exists(Feedback.SETTINGS_PATH)
 var previous := FileAccess.get_file_as_bytes(Feedback.SETTINGS_PATH) if existed else PackedByteArray()
 var prior_master := AudioServer.is_bus_mute(0)
 DirAccess.make_dir_recursive_absolute("/tmp/bandmaster-audio-evidence")
 var hashes: Array[int] = []
 for cue in Feedback.CUES:
  var stream: AudioStreamWAV = Feedback.make_stream(cue)
  var pcm: PackedByteArray = stream.data
  var count := pcm.size() / 2
  var peak := 0
  var max_step := 0
  var last := 0
  for i in count:
   var sample := pcm.decode_s16(i * 2)
   peak = maxi(peak,absi(sample))
   max_step = maxi(max_step,absi(sample-last))
   last = sample
  check(stream.mix_rate == 22050 and not stream.stereo,"small mono PCM " + cue)
  check(stream.get_length() > 0.04 and stream.get_length() <= 0.21,"bounded duration " + cue)
  check(pcm.decode_s16(0) == 0 and pcm.decode_s16(pcm.size()-2) == 0,"zero endpoints " + cue)
  check(peak > 500 and peak < 7300,"audible with safe headroom " + cue)
  check(max_step < 4000,"no discontinuous sample jumps " + cue)
  check(pcm == Feedback.make_stream(cue).data,"deterministic original samples " + cue)
  hashes.append(hash(pcm))
  check(stream.save_to_wav("/tmp/bandmaster-audio-evidence/" + cue + ".wav") == OK,"export review sample " + cue)
 check(hashes[0] != hashes[1] and hashes[1] != hashes[2] and hashes[0] != hashes[2],"three distinct cues")
 check(Feedback.make_stream("unknown") == null,"unknown cue rejected")
 var service: Node = Feedback.shared(self)
 check(service == Feedback.shared(self),"one shared service")
 check(service.get_child_count() == Feedback.VOICES,"bounded player pool")
 check(service.set_muted(false) == OK,"unmute persists")
 check(service.play_cue("click"),"cue starts")
 check(not service.play_cue("confirm"),"rapid input suppressed")
 await wait_ms(80)
 check(service.play_cue("confirm"),"input allowed after cooldown")
 # Even when the cooldown expires, occupied voices must not be stolen/cut.
 for player in service.get_children():
  player.stream = Feedback.make_stream("confirm")
  player.play()
 await wait_ms(80)
 check(not service.play_cue("back"),"full pool drops cue without truncation")
 check(service.set_muted(true) == OK,"mute persists")
 check(not service.play_cue("click"),"muted cue rejected")
 for player in service.get_children():
  check(not player.playing,"mute stops ringing tails")
 root.remove_child(service)
 service.free()
 await wait_ms(250)
 service = Feedback.shared(self)
 check(service.muted and AudioServer.is_bus_mute(0),"service recreation restores mute")
 service.set_muted(false)
 var button := Button.new()
 root.add_child(button)
 service.bind_button(button)
 service.bind_button(button)
 check(button.pressed.get_connections().size() == 1,"binding idempotent")
 button.disabled = true
 button.pressed.emit()
 for player in service.get_children():
  check(not player.playing,"disabled activation silent")
 button.disabled = false
 button.mouse_entered.emit()
 button.focus_entered.emit()
 for player in service.get_children():
  check(not player.playing,"hover and focus silent")
 button.pressed.emit()
 check(service.get_child(0).playing,"activation triggers cue")
 button.queue_free()
 await process_frame
 check(service.get_child(0).playing,"cue survives button removal")
 service.set_muted(true)
 root.remove_child(service)
 service.free()
 await wait_ms(250)
 if existed:
  var file := FileAccess.open(Feedback.SETTINGS_PATH, FileAccess.WRITE)
  file.store_buffer(previous)
  file.close()
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(Feedback.SETTINGS_PATH))
 AudioServer.set_bus_mute(0, prior_master)
 print("AUDIO_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"engine":Engine.get_version_info().string}))
 quit(0 if failures.is_empty() else 1)
