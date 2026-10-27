extends SceneTree
## Actual-render screenshot and first-fold gate for Tour Planning Sprint 03.
const Worlds = preload("res://Scripts/scene_world_theme.gd")
const Itinerary = preload("res://Scripts/tour_itinerary.gd")

func _initialize() -> void:
 call_deferred("_capture")

func _capture() -> void:
 var moment := "day"
 var width := 390
 var height := 844
 var output := "screenshots/tour-journey-day-390x844.png"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--moment="):
   moment = arg.trim_prefix("--moment=")
  elif arg.begins_with("--width="):
   width = int(arg.trim_prefix("--width="))
  elif arg.begins_with("--height="):
   height = int(arg.trim_prefix("--height="))
  elif arg.begins_with("--output="):
   output = arg.trim_prefix("--output=")
 if not ["day","arrival"].has(moment) or width < 320 or height < 600:
  push_error("JOURNEY CAPTURE: invalid args")
  quit(1)
  return
 get_root().size = Vector2i(width,height)
 DisplayServer.window_set_size(Vector2i(width,height))
 var packed: PackedScene = load("res://poc/tour_planning_journey.tscn")
 if packed == null:
  push_error("JOURNEY CAPTURE: scene load failed")
  quit(1)
  return
 var view: Control = packed.instantiate()
 get_root().add_child(view)
 view.choose_plan(Itinerary.OVERNIGHT)
 view.toggle_van()
 if moment == "arrival":
  view.review_journey()
  view.confirm_journey()
 for frame in range(18):
  await process_frame
 var phase := "dusk" if moment == "arrival" else "day"
 var primary: Button = view.find_child("JourneyPrimary",true,false)
 var case: Control = view.find_child("JourneyRoadCase",true,false)
 var latch: Button = view.find_child("JourneyVanLatch",true,false)
 var ticket: Label = view.find_child("JourneyTicketVenue",true,false)
 var summary: Label = view.find_child("JourneyPreview",true,false)
 if view.phase != phase or primary == null or case == null or latch == null or ticket == null or summary == null:
  push_error("JOURNEY CAPTURE: required UI or phase missing")
  quit(1)
  return
 if ticket.text != "THE CELLAR STAGE":
  push_error("JOURNEY CAPTURE: ticket did not reflect engine venue")
  quit(1)
  return
 var pixel_scale := float(DisplayServer.window_get_size().x)/float(view.get_viewport_rect().size.x)
 if primary.custom_minimum_size.y*pixel_scale < 44.0 or latch.custom_minimum_size.y*pixel_scale < 44.0:
  push_error("JOURNEY CAPTURE: touch target below 44px")
  quit(1)
  return
 if primary.get_global_rect().end.y*pixel_scale > float(height)-10.0:
  push_error("JOURNEY CAPTURE: primary action below first fold")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
 get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
 var margin: Control = case.get_node_or_null("MarginContainer")
 var stack: Control = margin.get_child(0) if margin != null and margin.get_child_count()>0 else null
 print("JOURNEY CONTAINERS: case="+str(case.get_global_rect())+" margin="+str(margin.get_global_rect() if margin != null else "NONE")+" stack="+str(stack.get_global_rect() if stack != null else "NONE")+" latch="+str(latch.get_global_rect()))
 print("JOURNEY GEOMETRY: moment=%s viewport=%dx%d latch_bottom=%.1f case_bottom=%.1f primary_bottom=%.1f" % [moment,width,height,latch.get_global_rect().end.y,case.get_global_rect().end.y,primary.get_global_rect().end.y])
 if latch.get_global_rect().end.y > case.get_global_rect().end.y-2.0:
  push_error("JOURNEY CAPTURE: van control clipped")
  quit(1)
  return
 if moment == "arrival" and (not summary.text.contains("SHOW NOT PLAYED") or int(view.demo_state["cash"]) != 135):
  push_error("JOURNEY CAPTURE: arrival falsely spent cash")
  quit(1)
  return
 for frame in range(4):
  await process_frame
 var img := get_root().get_texture().get_image()
 var expected: Color = Worlds.palette("tour",phase)["bg"]
 var actual: Color = img.get_pixel(3,3)
 if absf(actual.r-expected.r)>0.12 or absf(actual.g-expected.g)>0.12 or absf(actual.b-expected.b)>0.12:
  push_error("JOURNEY CAPTURE: phase backdrop mismatch")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
 var err := img.save_png(ProjectSettings.globalize_path(output))
 view.queue_free()
 if err != OK or img.get_width()<width or img.get_height()<height:
  push_error("JOURNEY CAPTURE: PNG save/size failed")
  quit(1)
  return
 print("JOURNEY CAPTURE PASSED: "+output)
 quit(0)
