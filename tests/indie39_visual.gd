extends "res://tests/polish_feedback_visual.gd"
const New=preload("res://experiments/playable_flightcase/recorded_vocal_keys.gd")
func person(id: String,role_name: String) -> void:
 await super.person(id,role_name)
 if role_name=="Singer":
  if not await tap("AuditionSeparateSingerAction"):return
  var view=scene._recruit_view
  var choices: Array=owner.game.choices(role_name)
  for i in choices.size():
   if choices[i].id==id:view.selected_index=i;break
  view._rebuild();await settle()
func new_band() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_tom","cast_ben","cast_ellis","cast_maya","cast_freya"]:
  if not owner.recruit(id).get("ok",false):return false
 return owner.choose_vocal("cast_maya").get("ok",false) and owner.confirm_lineup(true).get("ok",false) and owner.submit_name("SOURCE WINDOW","Raw").get("ok",false) and owner.lock_name(true).get("ok",false) and owner.finish_identity().get("ok",false) and owner.start_playing()
func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 owner=Owner.new();check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"actual recruitment")
 await mount()
 for pair in [["cast_maya","Singer"],["cast_freya","Keyboardist"],["cast_lily","Singer"],["cast_dan","Keyboardist"],["cast_sam","Singer"],["cast_oscar","Keyboardist"]]:
  await person(pair[0],pair[1])
  var idea=scene.find_child("CharacterRecordedIdeas",true,false)
  if not check(idea!=null and idea.candidate_id==pair[0],"actual character source "+pair[0]):await finish_new();return
  var before: Dictionary=owner.snapshot()
  if not await tap("CharacterIdea_0"):await finish_new();return
  check(idea.playing,"actual approved character playback "+pair[0])
  await capture("character-"+pair[0])
  await tap("CharacterIdeaStop")
  check(not idea.playing and owner.snapshot()==before,"free listening never changes state")
 await person("cast_nina","Singer")
 check(scene.find_child("CharacterRecordedIdeas",true,false)==null,"Nina has no substituted voice")
 scene.free();scene=null;await settle()
 if not check(new_band(),"funded actual five-person new band"):await finish_new();return
 var base: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 if not check(owner.begin_workbench("A PLACE FOR THE SONG",0,owner.workbench_expected(),base).ok,"actual writing draft"):await finish_new();return
 await mount();scene._career_landing=false;scene._render();await settle()
 if not await tap("MixingBankMore"):await finish_new();return
 var choice: Button=scene.find_child("MixingRecorded_32",true,false)
 check(choice!=null and not choice.disabled,"actual matching pair available")
 var other: Button=scene.find_child("MixingRecorded_33",true,false)
 check(other!=null and other.disabled and other.tooltip_text.contains("singer"),"different pair unavailable with explanation")
 if not await tap("MixingRecorded_32"):await finish_new();return
 await capture("bank-selected")
 await tap("MixingBankMore")
 var desk=scene.find_child("MixingDesk",true,false)
 check(desk._recipe.version==5 and desk._controls.tone.locked,"new source selected, recorded tone locked")
 var before: Dictionary=owner.snapshot()
 if not await tap("MixingHear"):await finish_new();return
 check(desk._audio.playing and desk._audio._recorded_player.stream.stream_count==5,"actual workbench five-stream audition")
 check(owner.snapshot()==before,"arrangement preview free")
 await capture("writing-approved-source")
 AudioServer.set_bus_mute(0,true);await create_timer(0.2).timeout
 check(not desk._audio.playing,"mute releases native new source")
 AudioServer.set_bus_mute(0,false)
 # Save the actual native local recipe through the original atomic owner API.
 var saved: Dictionary=owner.save_mixing_sketch(owner.workbench_expected(),desk._payload())
 check(saved.ok,"original owner saves actual local version5 sketch")
 var fresh=Owner.new();check(fresh.load_draft() and fresh.snapshot()==owner.snapshot(),"actual native sketch exact reload");fresh=null
 await finish_new()
func finish_new() -> void:
 print("INDIE39_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"new_listening":false}))
 if is_instance_valid(scene):scene.free();scene=null
 owner=null;await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)
