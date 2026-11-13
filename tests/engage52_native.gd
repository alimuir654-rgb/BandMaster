extends "res://tests/band_stories_visual.gd"
const Recording52=preload("res://experiments/playable_flightcase/recording_rules.gd")
const Radio52=preload("res://experiments/playable_flightcase/radio_visit_rules.gd")

func mount() -> void:
 if is_instance_valid(scene):scene.free()
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;scene._career_landing=false
 root.add_child(scene);await settle()

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not check(fresh(),"fresh actual band"):finish();return
 var recipe: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 if not check(owner.begin_workbench("LAST TRAIN HOME",0,owner.workbench_expected(),recipe).ok,"actual writing draft"):finish();return
 await mount()
 await capture("writing-entry")
 var desk=scene.find_child("MixingDesk",true,false)
 if not check(desk!=null,"real writing room"):finish();return
 await reveal(desk.find_child("MixingResponse_keep",true,false));await capture("writing-replies")
 if not baseline:
  var before: Dictionary=owner.snapshot()
  await tap("MixingResponse_keep")
  var kept: Button=desk.find_child("MixingResponse_keep",true,false)
  check(kept.button_pressed and kept.text.begins_with("✓ "),"writing choice visibly latched")
  check(owner.snapshot()==before,"considering reply remains free")
  await capture("writing-selected")
 scene.free();scene=null;await settle()
 owner=Owner.new();check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"actual audition fixture")
 check(owner.begin_audition("cast_arjun","Guitarist",true).get("ok",false),"real Arjun audition")
 await mount()
 if owner.audition_view().get("phase")=="arrival":
  if not await tap("AuditionStartTryout"):finish();return
 if not check(owner.audition_view().get("phase")=="tryout","observed audition tryout phase"):finish();return
 await capture("audition-tryout")
 if not baseline:
  await tap("AuditionPlayFirst")
  var encounter=scene.find_child("AuditionEncounter",true,false)
  var ideas=encounter.find_child("CharacterRecordedIdeas",true,false)
  check(ideas!=null and ideas.playing and not encounter._audio.playing,"Arjun current recording plays; old sampler never starts")
  await tap("AuditionStopTakes");check(not ideas.playing,"stop owns new Arjun recording")
 await tap("AuditionRequestSpace");await capture("audition-response")
 scene.free();scene=null;await settle()
 if not check(fresh(),"fresh career conversations") or not await write_original():finish();return
 await mount();scene._open_career_desk();await settle()
 await tap("PosterNav_gigs");await tap("BookingVenue_local");await capture("promoter-opening")
 if not baseline:
  var before: Dictionary=owner.snapshot()
  await tap("BookingPromoterQuestion")
  check(scene.find_child("BookingPromoterAside",true,false).is_visible_in_tree() and owner.snapshot()==before,"free character side question answers without save/economy effects")
  await capture("promoter-side-question")
 await tap("BookingPitch_fit");await capture("promoter-answer")
 await tap("BookingOffer_guarantee");await capture("promoter-counteroffer")
 scene.free();scene=null;await settle();await mount();scene._open_career_desk();await settle()
 await tap("PosterNav_band");await tap("CareerTalk_cast_jack");await capture("musician-opening")
 await failure_action("ChatReply_write_together","musician")
 await tap("ChatReply_write_together");await capture("musician-reply")
 if not baseline:
  var reply: Control=scene.find_child("MusicianChatSavedReply",true,false)
  var scroll: ScrollContainer=scene._career_view._scroll
  check(scroll.get_global_rect().encloses(reply.get_global_rect()),"actual newly saved musician reply immediately visible")
 var saved=Owner.new();check(saved.load_draft() and saved.snapshot()==owner.snapshot(),"new dialogue survives strict reload")
 scene.free();scene=null;await settle()
 # Second finished original uses the existing paid model/attendance/finance.
 for stage in range(3):
  for day in range(7):
   if Situation.inspect_writing(owner.game.career).get("can_write",false):break
   if not await advance_day():finish();return
  var before: Dictionary=owner.game.career.duplicate(true)
  var made: Dictionary=owner.game.write_session("Riff","Verse / Chorus","AFTER THE DOORS",0)
  if not check(made.get("ok",false),"second real original"):finish();return
  var tracked: Dictionary=Situation.after_action(before,owner.game.career)
  var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:create")
  if not check(accounted.get("ok",false),"original composition accounting"):finish();return
  owner.game.career=accounted.state;check(owner.save_draft(),"save second original")
 var ids: Array=[]
 for song in Recording52.songs(owner.game.career):ids.append(song.id)
 var recorded: Dictionary=Recording52.record(owner.game.career,ids)
 if not check(recorded.get("ok",false),"actual two-track demo"):finish();return
 var released: Dictionary=Recording52.release(recorded.state,str(recorded.demo_id),Recording52.fingerprint(recorded.session),int(recorded.session_index))
 if not check(released.get("ok",false),"actual released demo"):finish();return
 owner.game.career=released.state;check(owner.save_draft(),"save released demo")
 await mount();scene._open_career_desk();await settle()
 var host=scene._career_view
 host.promotion_selection={"id":released.demo_id,"fingerprint":Recording52.fingerprint(released.session),"index":int(released.session_index)}
 host.recording_mode="visit";host._navigate("recording");await settle();await capture("radio-before")
 if not await tap("StudioStartAction"):finish();return
 if not check(Radio52.active(owner.game.career).get("phase")=="arrival","observed radio arrival"):finish();return
 if not await tap("StudioContinueAction") or not await tap("StudioContinueAction"):finish();return
 if not check(Radio52.active(owner.game.career).get("phase")=="question1","observed first radio question"):finish();return
 await capture("radio-question")
 await failure_action("StudioChoice_craft","radio")
 await tap("StudioChoice_craft");await capture("radio-reaction")
 await tap("StudioContinueAction");await tap("StudioChoice_invite");await tap("StudioContinueAction");await capture("radio-wrap")
 finish()

func finish() -> void:
 print("ENGAGE52_NATIVE "+JSON.stringify({"viewport":str(root.size),"baseline":baseline,"checks":checks,"failures":failures,"physical_Android":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
