extends SceneTree
# Captures real CareerHub UI using the Godot renderer, not a visual mockup.
const SAVE_PATH := "user://tour_save.json"

func _initialize() -> void:
 call_deferred("_capture")

func _capture() -> void:
 var args := OS.get_cmdline_user_args()
 var output := "screenshots/bandmaster-home.png"
 var tab := "HOME"
 var genre := "indie"
 var show_sleeve := false
 var journey_stage := -1
 var width := 390
 var height := 844
 for arg in args:
  if arg.begins_with("--output="):
   output = arg.trim_prefix("--output=")
  elif arg.begins_with("--tab="):
   tab = arg.trim_prefix("--tab=")
  elif arg == "--sleeve":
   show_sleeve = true
  elif arg.begins_with("--journey-stage="):
   journey_stage = int(arg.trim_prefix("--journey-stage="))
  elif arg.begins_with("--genre="):
   genre = arg.trim_prefix("--genre=")
  elif arg.begins_with("--width="):
   width = int(arg.trim_prefix("--width="))
  elif arg.begins_with("--height="):
   height = int(arg.trim_prefix("--height="))
 if width < 320 or height < 600 or not ["HOME","BAND","ACTIONS","GIGS","GEAR","SCENE"].has(tab) or not ["indie","punk","metal","electronic"].has(genre) or (show_sleeve and tab != "ACTIONS") or journey_stage > 3 or journey_stage < -1 or (journey_stage >= 0 and tab != "ACTIONS") or (journey_stage >= 0 and show_sleeve):
  push_error("SCREENSHOT FAILURE: Invalid capture parameters")
  quit(1)
  return
 var original_exists := FileAccess.file_exists(SAVE_PATH)
 var original := ""
 if original_exists:
  original = FileAccess.get_file_as_string(SAVE_PATH)
 var fixture := {
  "band":{"name":"The Night Shift","members":[
   {"name":"Jo","role":"Drummer","trait":"Reliable","skill":65,"fatigue":12,"loyalty":78,"morale":70},
   {"name":"Alex","role":"Guitarist","trait":"Creative","skill":72,"fatigue":18,"loyalty":80,"morale":76},
   {"name":"Sam","role":"Vocalist","trait":"Ambitious","skill":69,"fatigue":9,"loyalty":68,"morale":75}
  ]},
  "cash":285,"tour_day":12,"morale":74,"reputation":24,"readiness":75,"tension":12,"van_health":82,
  "current_event":"aftershow","pending_next":"","relationships":{"0_1":84,"0_2":76,"1_2":80},
  "career_extra":{"songs":2,"fans":42,"gig_history":[],"career_journal":[],"action_counters":{},
   "song_draft_progress":1,"current_song_draft":{"title":"NEON AT CLOSING TIME","idea":"Riff","form":"Slow Build","leader":"Alex","sessions":[{"day":11,"idea":"Riff","form":"Slow Build","leader":"Alex"}]},
   "song_catalogue":[
    {"title":"AFTER THE LAST BUS","lead_writer":"Alex","credited_writers":["Alex","Jo"],"origin":"Riff","arrangement":"Slow Build","quality":77,"written_day":8,
     "writing_sessions":[{"day":5,"leader":"Alex","idea":"Riff","form":"Loose Jam"},{"day":6,"leader":"Jo","idea":"Groove","form":"Slow Build"},{"day":7,"leader":"Alex","idea":"Riff","form":"Slow Build"}]},
    {"title":"FRIDAY AGAIN","lead_writer":"Sam","origin":"Lyric","arrangement":"Verse / Chorus","quality":66,"written_day":10,
     "writing_sessions":[{"day":8,"leader":"Sam","idea":"Lyric","form":"Verse / Chorus"}]}
   ]}
 }
 fixture["band"]["genre"] = genre
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file == null:
  push_error("SCREENSHOT FAILURE: Cannot create isolated fixture")
  quit(1)
  return
 file.store_string(JSON.stringify(fixture))
 file.close()
 get_root().size = Vector2i(width,height)
 DisplayServer.window_set_size(Vector2i(width,height))
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 if scene == null:
  push_error("SCREENSHOT FAILURE: CareerHub missing")
  _restore(original_exists,original)
  quit(1)
  return
 var ui: Control = scene.instantiate()
 get_root().add_child(ui)
 ui.tab = tab
 ui._render()
 if show_sleeve:
  ui._open_song_sleeve(fixture["career_extra"]["song_catalogue"][0],1)
 if journey_stage >= 0:
  ui._open_songwriting_journey()
  var journey := ui.find_child("SongwritingJourney",true,false)
  if journey == null:
   push_error("SCREENSHOT FAILURE: Songwriting journey did not open")
   ui.queue_free()
   _restore(original_exists,original)
   quit(1)
   return
  journey.reduced_motion = true
  for step in range(journey_stage):
   journey._go(step+1)
  if journey.stage != journey_stage or journey.find_child("JourneyArtwork",true,false) == null:
   push_error("SCREENSHOT FAILURE: Journey scene or illustration missing")
   ui.queue_free()
   _restore(original_exists,original)
   quit(1)
   return
 for frame in range(18):
  await process_frame
 var image := get_root().get_texture().get_image()
 var directory := output.get_base_dir()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
 var result := image.save_png(ProjectSettings.globalize_path(output))
 ui.queue_free()
 _restore(original_exists,original)
 if result != OK or image.get_width() < 320:
  push_error("SCREENSHOT FAILURE: Unable to export viewport")
  quit(1)
  return
 print("BANDMASTER SCREENSHOT SAVED: "+output)
 quit(0)

func _restore(existed: bool, data: String) -> void:
 if existed:
  var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
  if file != null:
   file.store_string(data)
   file.close()
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
