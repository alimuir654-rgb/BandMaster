extends "res://tests/polish_feedback_visual.gd"
const Chat=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
const Booking=preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")

func fresh() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not owner.recruit(id).get("ok",false):return false
 return owner.choose_vocal("cast_jack").get("ok",false) and owner.confirm_lineup(true).get("ok",false) and owner.submit_name("NIGHT BUS CLUB","Raw").get("ok",false) and owner.lock_name(true).get("ok",false) and owner.finish_identity().get("ok",false) and owner.start_playing()

func write_original() -> bool:
 for _stage in range(3):
  for _day in range(7):
   if Situation.inspect_writing(owner.game.career).get("can_write",false):break
   if not await advance_day():return false
  var before: Dictionary=owner.game.career.duplicate(true)
  var written: Dictionary=owner.game.write_session("Riff","Verse / Chorus","THE LAST TRAIN",0)
  if not check(written.get("ok",false),"actual original composition"):return false
  var tracked: Dictionary=Situation.after_action(before,owner.game.career)
  if not tracked.get("ok",false):return false
  var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:create")
  if not accounted.get("ok",false):return false
  owner.game.career=accounted.state
  if not owner.save_draft():return false
 return check(owner.game.career.get("song_catalogue",[]).size()==1,"genuine finished original for actual set")

func failure_action(button: String,label: String) -> void:
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"isolated native failure "+label)
 await tap(button)
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"whole native memory/disk rollback "+label)
 await capture(label+"-save-error")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated blocker "+label)

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not check(fresh(),"canonical actual band"):finish();return
 if not await write_original():finish();return
 await mount();await tap("PosterNav_band");await tap("CareerTalk_cast_jack")
 check(scene._career_view.page=="musician_chat","real Band→Talk entry")
 await capture("chat-opening")
 var before: Dictionary=owner.snapshot()
 await tap("ChatTopic_time")
 check(owner.snapshot()==before,"topic/reading free")
 await failure_action("ChatReply_agree_evening","chat")
 await tap("ChatReply_agree_evening")
 check(Chat.record(owner.game.career,"cast_jack").plan.status=="pending","native reply saves actual plan")
 await capture("chat-agreed")
 before=owner.snapshot();await tap("ChatNextStep")
 check(is_instance_valid(scene._practice_view) and scene._practice_view.is_visible_in_tree() and owner.snapshot()==before,"next step opens actual actionable rehearsal without resolving it")
 await capture("chat-next-rehearsal")
 for _evening in range(4):
  if 0 in Situation.inspect_rehearsal(owner.game.career).get("attendee_indices",[]):break
  await tap("PracticeMode_jam");await tap("InformalPracticeAction")
  await settle()
  if is_instance_valid(scene._practice_view._session_overlay):await tap("SkipSessionBeatAction")
  check(Chat.record(owner.game.career,"cast_jack").plan.status=="pending","quiet evening does not pretend to be the promised rehearsal")
  await tap("RecapToggleAction");await tap("SkipSessionBeatAction")
  print("MODE_BEFORE "+JSON.stringify({"kind":scene._practice_view.practice_activity,"busy":scene._practice_view.session_busy,"recap":scene._practice_view.recap_expanded}))
  await tap("PracticeMode_tighten")
  print("MODE_AFTER "+JSON.stringify({"kind":scene._practice_view.practice_activity,"busy":scene._practice_view.session_busy,"recap":scene._practice_view.recap_expanded}))
  await capture("practice-mode-transition")
 if not check(0 in Situation.inspect_rehearsal(owner.game.career).get("attendee_indices",[]),"real quiet evening leads to available rehearsal"):finish();return
 if not await tap("RehearseAction"):finish();return
 var practice=scene._practice_view
 await settle()
 if is_instance_valid(practice._session_overlay):await tap("SkipSessionBeatAction")
 check(Chat.record(owner.game.career,"cast_jack").plan.status=="kept","native actual paid practice fulfils promise")
 if "--chat-only" in OS.get_cmdline_user_args():await capture("chat-paid-result");finish();return
 scene._open_career_desk();await settle()
 scene._career_view._navigate("band");await settle();await tap("CareerTalk_cast_jack")
 await capture("chat-kept")
 var durable=Owner.new();check(durable.load_draft() and durable.snapshot()==owner.snapshot(),"actual chat/practice reload")
 scene._home();await settle();scene._continue();await settle()
 scene._open_career_desk();await settle();scene._career_view._navigate("gigs");await settle()
 await tap("BookingVenue_local")
 before=owner.snapshot();await tap("BookingPitch_crowd")
 print("PITCH_TRACE "+JSON.stringify({"pitch":scene._career_view.booking_pitch,"draft":scene._career_view.booking_draft,"notice":scene._career_view.notice,"generation":scene._career_view._render_generation}))
 await capture("promoter-pitch")
 await tap("BookingOffer_guarantee")
 print("ASK_TRACE "+JSON.stringify({"pitch":scene._career_view.booking_pitch,"draft":scene._career_view.booking_draft,"notice":scene._career_view.notice,"generation":scene._career_view._render_generation}))
 check(owner.snapshot()==before,"negotiation preview is free")
 var career=scene._career_view
 if not check(career.booking_draft.offer_id=="guestlist" and career.booking_draft.get(Circuit.BILL,{}).get("slot")=="opening","new band gets opening-slot counteroffer"):await capture("promoter-missing");finish();return
 await reveal(scene.find_child("BookingPromoterReply",true,false));await capture("promoter-counteroffer")
 await tap("BookingCommitAction");await tap("BookingKeepEditingAction")
 check(owner.snapshot()==before,"declining confirmation is free")
 await tap("BookingCommitAction")
 await failure_action("BookingConfirmAction","booking")
 check(career.booking_draft.has(Circuit.BILL),"booking failure keeps negotiation draft")
 await tap("BookingCommitAction");await tap("BookingConfirmAction")
 check(Booking.terms(owner.game.career).has(Circuit.BILL),"actual booking freezes bill")
 await capture("booking-saved")
 for _day in range(3):check(await advance_day(),"canonical day to actual show")
 career._navigate("gigs");await settle();await tap("JourneyMainAction");await tap("JourneyMainAction")
 check(Journey.active(owner.game.career).get("phase")=="soundcheck","actual agreed trip to soundcheck")
 await tap("JourneyMainAction")
 if not check(Journey.active(owner.game.career).get("phase")=="backstage","real backstage boundary"):finish();return
 await reveal(scene.find_child("SceneAdvice_glass_arcade",true,false));await capture("higher-band-advice")
 await failure_action("SceneAdvice_glass_arcade","advice")
 if not await tap("SceneAdvice_glass_arcade"):finish();return
 check(Journey.active(owner.game.career).get(Circuit.ENCOUNTER,{}).get("advice",{}).get("band_id")=="glass_arcade","actual advice saved inside journey")
 before=owner.snapshot();scene._home();await settle();scene._continue();await settle();scene._open_career_desk();await settle()
 check(owner.snapshot()==before and Journey.validate(owner.game.career).ok,"Menu/resume preserves advice and exact checkpoint")
 await tap("JourneyMainAction");await tap("JourneyMainAction");await tap("JourneyFinishSongAction")
 if not check(Journey.active(owner.game.career).get("phase")=="after_set","genuine selected original finished"):finish();return
 await reveal(scene.find_child("SceneHelp_northbound_static",true,false));await capture("support-another-band")
 await failure_action("SceneHelp_northbound_static","support")
 if not await tap("SceneHelp_northbound_static"):finish();return
 await tap("JourneyMainAction");await tap("JourneyMainAction")
 before=owner.snapshot();await failure_action("JourneyWrapAction","wrap")
 await tap("JourneyWrapAction")
 check(owner.game.career.get(Circuit.KEY,{}).get("bands",{}).get("northbound_static",{}).get("supported")==1,"support contact applied exactly once at wrap")
 check(owner.game.career.tour_day==before.game.career.tour_day+1,"original one-day settlement retained")
 await capture("saved-night")
 durable=Owner.new();check(durable.load_draft() and durable.snapshot()==owner.snapshot(),"scene contacts/dialogue/receipt exact reload")
 finish()

func finish() -> void:
 print("BAND_STORIES_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
