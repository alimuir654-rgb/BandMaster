extends SceneTree
# Sprint C: every destination must be an actual distinct illustrated world.
# The test checks instantiated textures and the cinematic landscape composition;
# screenshot crops and artistic quality remain separate human review gates.
const SAVE_PATH := "user://tour_save.json"
const SIZES := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
const WORLDS := {
 "HOME":"studio.webp","GIGS":"03-arrival.svg","GEAR":"gear-workshop.svg",
 "BAND":"band-room.svg","ACTIONS":"02-vibe.svg","SCENE":"scene-streets.svg"
}
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var previous := FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
 var fixture := {
  "band":{"name":"Art Review","genre":"indie","members":[
   {"name":"Jo","role":"Guitarist","life_status":"active","trait":"Creative","skill":60,"fatigue":5,"loyalty":70,"morale":65},
   {"name":"Lee","role":"Drummer","life_status":"active","trait":"Reliable","skill":62,"fatigue":5,"loyalty":70,"morale":65}
  ]},
  "cash":250,"tour_day":1,"morale":65,"reputation":15,"readiness":70,"tension":10,"van_health":90,
  "relationships":{"0_1":60},
  "career_extra":{"songs":1,"fans":20,"owned_equipment":[],"gig_history":[],"career_journal":[],"action_counters":{}}
 }
 var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(packed != null,"CareerHub loads")
 if packed != null:
  for size in SIZES:
   get_root().size = size
   _write(JSON.stringify(fixture))
   var ui: Control = packed.instantiate()
   get_root().add_child(ui)
   await process_frame
   for target in WORLDS:
    ui.tab = str(target)
    if target == "ACTIONS":
     ui.action_view = "JAM"
    ui._render()
    await process_frame
    var art := ui.find_child("CareerWorldArtwork",true,false) as TextureRect
    _check(art != null and art.texture != null,"illustrated "+str(target)+" at "+str(size))
    if art != null and art.texture != null:
     _check(art.texture.resource_path.ends_with(str(WORLDS[target])),"correct art "+str(target)+" at "+str(size))
     _check(art.mouse_filter == Control.MOUSE_FILTER_IGNORE,"background cannot steal input")
    var environment := _environment(ui)
    _check(environment != null and str(environment.scene_id) != "DEFAULT","distinct environment "+str(target))
    _check(int(ui._state().get("tour_day",0)) == 1 and int(ui._state().get("cash",0)) == 250,"tab travel is free")
   ui._open_songwriting_journey()
   await process_frame
   var song := ui.find_child("SongwritingJourney",true,false)
   var planes := ui.find_child("JourneyScenePlanes",true,false)
   _check(song != null and planes != null,"song journey renders")
   if planes != null:
    _check((planes is HBoxContainer) == (size.x >= 960),"song layout responds to aspect")
   if song != null:
    song.queue_free()
   await process_frame
   ui.free()
   await process_frame
   print("SPRINT C WORLD TONE %dx%d checked" % [size.x,size.y])
 if existed:
  _write(previous)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT C WORLD TONE PASSED")
 quit(0 if failures == 0 else 1)

func _environment(root: Node) -> Node:
 for child in root.get_children():
  if child.get_script() != null and str(child.get_script().resource_path).ends_with("scene_environment.gd"):
   return child
 return null

func _write(value: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file != null:
  file.store_string(value)
  file.close()

func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT C WORLD FAILURE: "+why)
