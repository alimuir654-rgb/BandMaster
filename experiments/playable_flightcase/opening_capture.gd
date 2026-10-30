extends SceneTree
## Captures are native GL/Mesa/Xvfb pixels, never flattened mockup art.
const UI = preload("res://experiments/playable_flightcase/opening_ui.gd")
var failures: Array[String] = []
func _init() -> void:
 call_deferred("take")
func _draw_screen(name: String,w: int,h: int) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var img: Image = root.get_texture().get_image()
 var dest := "/tmp/c27-%s-%dx%d.png" % [name,w,h]
 if img == null or img.is_empty() or img.get_width()!=w or img.get_height()!=h:
  failures.append("invalid "+name+" image dimensions")
 elif img.save_png(dest)!=OK:
  failures.append("could not save "+dest)
func click_action(button: Button) -> void:
 if button==null or button.disabled:
  failures.append("missing or disabled action")
  return
 var point := button.get_global_rect().get_center()
 var press := InputEventMouseButton.new()
 press.button_index = MOUSE_BUTTON_LEFT
 press.position = point
 press.global_position = point
 press.pressed = true
 Input.parse_input_event(press)
 await process_frame
 var release := InputEventMouseButton.new()
 release.button_index = MOUSE_BUTTON_LEFT
 release.position = point
 release.global_position = point
 release.pressed = false
 Input.parse_input_event(release)
 await process_frame
func take() -> void:
 var w := maxi(320,int(OS.get_environment("CAPTURE_WIDTH")))
 var h := maxi(480,int(OS.get_environment("CAPTURE_HEIGHT")))
 DisplayServer.window_set_size(Vector2i(w,h))
 root.size = Vector2i(w,h)
 var screen = UI.new()
 root.add_child(screen)
 screen.size = Vector2(w,h)
 # Ensure title always renders with empty draft, independent of the runner's saved state.
 screen.setup.screen = "menu"
 screen.showing_menu = true
 screen.call("_render")
 await _draw_screen("title",w,h)
 var new_action: Button = screen.find_child("NewBandAction",true,false)
 if new_action==null:
  failures.append("New Band button missing")
 else:
  print("C27_MENU_BUTTON rect=",new_action.get_global_rect()," viewport=",Vector2(w,h))
  await click_action(new_action)
 # The preceding native opening-state test saves a draft to this isolated sandbox.
 # New correctly requires confirmation; test the actual original C21 modal.
 await process_frame
 var confirmation: Control = null
 for node in screen.get_children():
  if node is Control and node.has_method("open_modal") and bool(node.get("is_open")):
   confirmation = node
   break
 if confirmation != null:
  print("C27_NEW_CONFIRM_REQUIRED true; real pointer confirming overwrite")
  var accept_button: Button = confirmation.get("confirm_button")
  if accept_button == null:
   failures.append("new draft confirmation button missing")
  else:
   await click_action(accept_button)
   await process_frame
 else:
  print("C27_NEW_CONFIRM_REQUIRED false, stage=",screen.setup.screen)
 if screen.setup.screen!="genre":
  failures.append("New Band did not open genre via pointer")
 else:
  await _draw_screen("genre",w,h)
 var next_action: Button = screen.find_child("GenreNextAction",true,false)
 if next_action==null:
  failures.append("Genre Next missing")
 else:
  await click_action(next_action)
 if screen.setup.screen!="recruit":
  failures.append("Genre Next did not open recruit via pointer")
 else:
  await _draw_screen("recruit",w,h)
  var meter: Control = screen.find_child("PassiveMeter0",true,false)
  if meter == null or meter.focus_mode!=Control.FOCUS_NONE or meter.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("meter focus/input regression")
 print("C27_CAPTURE_RESULT ",JSON.stringify({"width":w,"height":h,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
