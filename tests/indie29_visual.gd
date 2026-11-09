extends "res://tests/band_stories_visual.gd"
const Bank=preload("res://experiments/playable_flightcase/recorded_steady.gd")
const Splash=preload("res://experiments/playable_flightcase/splash_audio.gd")

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 owner=Owner.new();check(owner.begin_new(),"title owner")
 Splash.attempted=false
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=true;root.add_child(scene);await settle()
 var cue=scene.find_child("StartupCue",true,false)
 check(cue!=null,"title uses original startup owner")
 check(not cue._allowed() or cue.playing,"allowed title cue starts through original lifecycle")
 print("TITLE_CUE "+JSON.stringify({"allowed":cue._allowed(),"playing":cue.playing}))
 await capture("title")
 scene.hide();await settle();check(not cue.playing,"hidden title stops cue");scene.free();scene=null
 check(owner.set_genre("Indie rock") and owner.to_recruit(),"genuine indie recruitment")
 await mount()
 var people: Array=[["cast_jack","Guitarist"],["cast_ryan","Guitarist"],["cast_arjun","Guitarist"],["cast_bex","Guitarist"],["cast_hannah","Bassist"],["cast_zoe","Bassist"],["cast_ben","Bassist"],["cast_ellis","Drummer"],["cast_marcus","Drummer"],["cast_casey","Drummer"]]
 for person_data in people:
  await person(person_data[0],person_data[1])
  var desk=scene.find_child("CharacterRecordedIdeas",true,false)
  if not check(desk!=null and desk.candidate_id==person_data[0] and desk.role==person_data[1],"canonical assigned musician "+person_data[0]):finish();return
  var before: Dictionary=owner.snapshot()
  if not await tap("CharacterIdea_0"):finish();return
  check(desk.playing,"first independent recorded idea "+person_data[0])
  var first=desk._player.stream
  await tap("CharacterIdea_1")
  check(desk.playing and desk._player.stream!=first,"different source passage "+person_data[0])
  first=null
  await capture("idea-"+person_data[0])
  AudioServer.set_bus_mute(0,true);await settle();check(not desk.playing,"mute stops newidea");AudioServer.set_bus_mute(0,false)
  await tap("CharacterIdea_0");await tap("CharacterIdeaStop")
  check(not desk.playing and owner.snapshot()==before,"free character listening never spends/consumes "+person_data[0])
 scene.free();scene=null
 check(fresh(),"canonical playing band")
 var take: Dictionary=Recipe.recipe(Sound.read(owner.game.career));take.hook="indie29_dark_06"
 check(owner.begin_workbench("New indie idea",0,owner.workbench_expected(),take).get("ok",false),"new family draft in existing songwriting owner")
 await mount();scene._career_landing=false;scene._render();await settle()
 var desk=scene.find_child("MixingDesk",true,false)
 check(desk!=null,"existing main writing workbench")
 await tap("MixingBankMore");await tap("MixingRecorded_31");await capture("bank-last")
 await tap("MixingBankMore");await capture("selected-new-bank")
 var before: Dictionary=owner.snapshot()
 await tap("MixingHear");check(desk._audio.playing,"new song bank actually plays")
 check(desk._audio._recorded_player.stream is AudioStreamSynchronized,"matched parts share one audio clock")
 desk._audio.stop();check(owner.snapshot()==before,"new bank preview remains free")
 finish()

func finish() -> void:
 print("INDIE29_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 var stopped: int=Time.get_ticks_usec()
 while Time.get_ticks_usec()-stopped<150000:await process_frame
 quit(0 if failures.is_empty() else 1)
