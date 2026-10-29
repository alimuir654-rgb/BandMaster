extends SceneTree
## Genuine GL/Mesa/Xvfb native screenshots; not source reference composites.
const UI = preload("res://experiments/playable_flightcase/ui.gd")
var failures: Array[String] = []
func _init() -> void:
 call_deferred("run_capture")
func run_capture() -> void:
 var w := maxi(320,int(OS.get_environment("CAPTURE_WIDTH")))
 var h := maxi(480,int(OS.get_environment("CAPTURE_HEIGHT")))
 DisplayServer.window_set_size(Vector2i(w,h))
 root.size = Vector2i(w,h)
 var screen := UI.new()
 root.add_child(screen)
 screen.size = Vector2(w,h)
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var outfile := "/tmp/c26-flightcase-recruit-%dx%d.png" % [w,h]
 var image: Image = root.get_texture().get_image()
 if image == null or image.is_empty() or image.get_width() != w or image.get_height() != h:
  failures.append("invalid rendered surface")
 elif image.save_png(outfile) != OK:
  failures.append("PNG save failed")
 var recruit: Button = screen.find_child("RecruitAction",true,false)
 if recruit == null or recruit.disabled:
  failures.append("recruit action absent")
 elif w >= 720:
  var original := screen.game.spent()
  var point := recruit.get_global_rect().get_center()
  var press := InputEventMouseButton.new()
  press.position = point
  press.global_position = point
  press.button_index = MOUSE_BUTTON_LEFT
  press.pressed = true
  Input.parse_input_event(press)
  await process_frame
  var release := InputEventMouseButton.new()
  release.position = point
  release.global_position = point
  release.button_index = MOUSE_BUTTON_LEFT
  release.pressed = false
  Input.parse_input_event(release)
  await process_frame
  if screen.game.spent()<=original:
   failures.append("real pointer activation failed")
 var meter := screen.find_child("PassiveMeter0",true,false)
 if meter == null or meter.focus_mode != Control.FOCUS_NONE or meter.mouse_filter != Control.MOUSE_FILTER_IGNORE:
  failures.append("passive meter wrongly interactive")
 var snapshot := screen.game.snapshot()
 for id in ["cast_maya","cast_jack","cast_zoe","cast_dan","cast_casey"]:
  if not screen.game.roster.any(func(p):return str(p["id"])==id):
   screen.game.recruit(id)
 if not screen.game.can_start() or not screen.game.launch().get("ok",false):
  failures.append("could not start model-backed first practice")
 else:
  screen.call("_rebuild")
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  var practice: Image = root.get_texture().get_image()
  var practice_out := "/tmp/c26-flightcase-practice-%dx%d.png" % [w,h]
  if practice == null or practice.is_empty() or practice.save_png(practice_out)!=OK:
   failures.append("practice screenshot failed")
 print("C26_RENDER_RESULT ",JSON.stringify({"width":w,"height":h,"failures":failures,"recruit":outfile,"source_pixels_not_source_screenshot":true}))
 quit(0 if failures.is_empty() else 1)
