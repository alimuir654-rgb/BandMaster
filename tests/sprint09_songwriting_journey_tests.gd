extends SceneTree
# Four real scene changes, one authoritative composition commit and disk reload.
const SAVE_PATH := "user://tour_save.json"
const SIZES := [Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720)]
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var existed := FileAccess.file_exists(SAVE_PATH)
 var original := FileAccess.get_file_as_string(SAVE_PATH) if existed else ""
 var fixture := {
  "band":{"name":"Journey Test","genre":"indie","members":[
   {"name":"Jo","role":"Guitarist","life_status":"active","trait":"Creative","skill":55,"fatigue":12,"loyalty":60,"morale":60},
   {"name":"Lee","role":"Drummer","life_status":"active","trait":"Reliable","skill":58,"fatigue":10,"loyalty":65,"morale":62}
  ]},
  "cash":180,"tour_day":7,"morale":61,"reputation":20,"readiness":65,"tension":12,"van_health":90,
  "relationships":{"0_1":60},
  "career_extra":{"songs":1,"fans":20,"owned_equipment":[],"gig_history":[],"career_journal":[],"action_counters":{},
   "song_draft_progress":2,
   "current_song_draft":{"title":"NEW ORIGINAL","idea":"Riff","form":"Slow Build","leader":"Jo","sessions":[
    {"day":5,"leader":"Jo","idea":"Riff","form":"Loose Jam"},{"day":6,"leader":"Lee","idea":"Lyric","form":"Slow Build"}
   ]},
   "song_catalogue":[{"title":"NEON ON THE PLATFORM","lead_writer":"Lee","origin":"Lyric","arrangement":"Slow Build","quality":76,"written_day":4}]
  }
 }
 var packed: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(packed != null,"CareerHub loads")
 if packed != null:
  for size in SIZES:
   _write(JSON.stringify(fixture))
   get_root().size = size
   var ui: Control = packed.instantiate()
   get_root().add_child(ui)
   ui.tab = "ACTIONS"
   ui.action_view = "JAM"
   ui._render()
   await process_frame
   await process_frame
   var open_button := _button(ui,"OPEN THE WRITING DESK")
   _check(open_button != null,"journey entry available "+str(size))
   if open_button != null:
    open_button.pressed.emit()
    await process_frame
    var journey := ui.find_child("SongwritingJourney",true,false)
    _check(journey != null,"four-scene journey opens "+str(size))
    if journey != null:
     _check(journey.stage == 0 and _has_text(journey,"THE SPARK"),"spark scene "+str(size))
     _check(_art(journey),"spark art imported "+str(size))
     _check(int(ui.save_data.get("tour_day",0)) == 7,"opening journey free "+str(size))
     var concept := journey.find_child("JourneyConceptInput",true,false) as LineEdit
     var title := journey.find_child("JourneyTitleInput",true,false) as LineEdit
     _check(concept != null and title != null,"concept and title editable "+str(size))
     if concept != null:
      concept.text = "A last train and an unfinished promise"
     if title != null:
      title.text = "NEW ORIGINAL"
     # Two quick activations must not skip a screen during the fade.
     journey._go(1)
     journey._go(2)
     _check(journey.stage == 0,"transition blocks double activation "+str(size))
     await create_timer(0.6).timeout
     _check(journey.stage == 1 and _has_text(journey,"FIND THE SOUND"),"vibe scene after fade "+str(size))
     _check(_art(journey),"vibe art imported "+str(size))
     journey.reduced_motion = true
     var vibe := journey.find_child("JourneyVibeChoice",true,false) as OptionButton
     var form := journey.find_child("JourneyFormChoice",true,false) as OptionButton
     if vibe != null:
      vibe.select(2)
      vibe.item_selected.emit(2)
      _check(_has_text(journey,"The drummer counts in fast"),"vibe choice changes authored scene response "+str(size))
     if form != null:
      form.select(1)
     journey._go(2)
     _check(journey.stage == 2 and _has_text(journey,"IN THE ROOM"),"jam scene "+str(size))
     _check(_art(journey),"jam art imported "+str(size))
     _check(journey.find_child("JourneyLeadPortrait",true,false) != null and journey.find_child("JourneyBandmateMoment",true,false) != null,"musician portrait and authored voice "+str(size))
     journey._go(3)
     _check(journey.stage == 3 and _has_text(journey,"THE SONGSHEET"),"review scene "+str(size))
     _check(_art(journey),"sleeve art imported "+str(size))
     _check(int(ui.save_data.get("tour_day",0)) == 7,"all four scenes are navigation only "+str(size))
     journey._commit()
     await process_frame
     await process_frame
     var state: Dictionary = ui._state()
     var songs: Array = state.get("song_catalogue",[])
     _check(int(state.get("tour_day",0)) == 8 and songs.size() == 2,"one day and one song after commit "+str(size))
     if songs.size() == 2:
      var song: Dictionary = songs[1]
      _check(str(song.get("title","")) == "NEW ORIGINAL","title persisted "+str(size))
      _check(str(song.get("lyrical_concept","")) == "A last train and an unfinished promise","lyric concept persisted "+str(size))
      _check(str(song.get("vibe","")) == "Urgent and loud","vibe persisted "+str(size))
      _check(str(song.get("arrangement","")) == "Slow Build","arrangement persisted "+str(size))
      _check(song.get("writing_sessions",[]).size() == 3,"three genuine sessions "+str(size))
     var disk = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
     _check(disk is Dictionary and int(disk.get("tour_day",0)) == 8,"committed disk save "+str(size))
     if disk is Dictionary:
      _check(disk.get("career_extra",{}).get("song_catalogue",[]).size() == 2,"song survives disk reload "+str(size))
     var next := _button(ui,"CONTINUE")
     if next != null:
      next.pressed.emit()
      await process_frame
   ui.free()
   await process_frame
   print("SPRINT A ART JOURNEY %dx%d checked" % [size.x,size.y])
 if existed:
  _write(original)
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
 if failures == 0:
  print("SPRINT A SONGWRITING JOURNEY PASSED")
 quit(0 if failures == 0 else 1)

func _art(root: Node) -> bool:
 var art := root.find_child("JourneyArtwork",true,false) as TextureRect
 return art != null and art.texture != null

func _button(root: Node, needle: String) -> BaseButton:
 var stack: Array[Node] = [root]
 while not stack.is_empty():
  var node: Node = stack.pop_back()
  if node is BaseButton and str(node.text).contains(needle):
   return node
  for child in node.get_children():
   stack.append(child)
 return null

func _has_text(root: Node, needle: String) -> bool:
 if root is Label and str(root.text).contains(needle):
  return true
 for child in root.get_children():
  if _has_text(child,needle):
   return true
 return false

func _write(value: String) -> void:
 var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file != null:
  file.store_string(value)
  file.close()

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT A JOURNEY FAILURE: "+reason)
