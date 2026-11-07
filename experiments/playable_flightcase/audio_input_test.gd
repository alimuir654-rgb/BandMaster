extends SceneTree
## Run with a real GL renderer/display in an isolated test project.
const Opening = preload("res://experiments/playable_flightcase/opening_ui.gd")
const Feedback = preload("res://experiments/playable_flightcase/ui_audio.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures.append(label)
  push_error("AUDIO INPUT FAILURE: " + label)

func wait_ms(milliseconds: int) -> void:
 var until := Time.get_ticks_msec() + milliseconds
 while Time.get_ticks_msec() < until:
  await process_frame

func click(button: Button) -> void:
 var point := button.get_global_rect().get_center()
 check(root.get_visible_rect().has_point(point),"target on screen: " + button.name)
 for down in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = point
  event.global_position = point
  event.pressed = down
  Input.parse_input_event(event)
  await process_frame
 await process_frame

func run() -> void:
 var previous_master := AudioServer.is_bus_mute(0)
 var existed := FileAccess.file_exists(Feedback.SETTINGS_PATH)
 var previous := FileAccess.get_file_as_bytes(Feedback.SETTINGS_PATH) if existed else PackedByteArray()
 var draft_before := FileAccess.get_file_as_bytes("user://c27_opening_draft.json")
 DisplayServer.window_set_size(Vector2i(720,1280))
 root.size = Vector2i(720,1280)
 var screen := Opening.new()
 root.add_child(screen)
 await wait_ms(250)
 var service: Node = Feedback.shared(self)
 service.set_muted(false)
 var before: int = service._last_play_ms
 var settings: Button = screen.find_child("SettingsAction",true,false)
 await click(settings)
 check(service._last_play_ms > before,"real pointer starts sound before rebuild")
 check(is_instance_valid(service) and screen.settings_open,"rebuild retains shared audio service")
 await wait_ms(250)
 var sound: Button = screen.find_child("SoundAction",true,false)
 await click(sound)
 check(service.muted and screen.muted and AudioServer.is_bus_mute(0),"real pointer mutes master")
 for player in service.get_children():
  check(not player.playing,"mute drains existing voices")
 sound = screen.find_child("SoundAction",true,false)
 sound.grab_focus()
 await process_frame
 for down in [true,false]:
  var key := InputEventKey.new()
  key.keycode = KEY_SPACE
  key.pressed = down
  Input.parse_input_event(key)
  await process_frame
 await process_frame
 check(not service.muted and not screen.muted,"real keyboard unmutes setting")
 await wait_ms(250)
 before = service._last_play_ms
 settings = screen.find_child("SettingsAction",true,false)
 settings.grab_focus()
 var move := InputEventMouseMotion.new()
 move.position = settings.get_global_rect().get_center()
 Input.parse_input_event(move)
 await process_frame
 check(service._last_play_ms == before,"real hover and focus remain silent")
 for down in [true,false]:
  var key := InputEventKey.new()
  key.keycode = KEY_SPACE
  key.pressed = down
  Input.parse_input_event(key)
  await process_frame
 check(service._last_play_ms > before,"real keyboard starts sound")
 await wait_ms(250)
 before = service._last_play_ms
 var disabled: Button = screen.find_child("ContinueAction",true,false)
 disabled.disabled = true
 await click(disabled)
 check(service._last_play_ms == before,"real disabled click stays silent")
 check(draft_before == FileAccess.get_file_as_bytes("user://c27_opening_draft.json"),"audio inputs preserve gameplay save bytes")
 screen.queue_free()
 await process_frame
 check(is_instance_valid(service),"audio lifetime independent of screen")
 service.set_muted(true)
 root.remove_child(service)
 service.free()
 await wait_ms(250)
 if existed:
  var file := FileAccess.open(Feedback.SETTINGS_PATH,FileAccess.WRITE)
  file.store_buffer(previous)
  file.close()
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(Feedback.SETTINGS_PATH))
 AudioServer.set_bus_mute(0,previous_master)
 print("AUDIO_INPUT_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
