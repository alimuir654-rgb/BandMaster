extends "res://tests/next32_gig_visual.gd"
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
const Bank=preload("res://experiments/playable_flightcase/recorded_steady.gd")
var native_music_verified:=false
var native_missing_fx_verified:=false
func write_original() -> bool:
 var recipe: Dictionary=Recipe.recipe(Sound.read(owner.game.career));recipe.hook="indie29_guitar90_01"
 if not check(owner.begin_workbench("THE LAST TRAIN",0,owner.workbench_expected(),recipe).ok,"actual recorded draft for gig"):return false
 for stage in range(3):
  for _day in range(8):
   if Situation.inspect_writing(owner.game.career).get("can_write",false):break
   if not await advance_day():return false
  recipe.stage=stage
  var tried: Dictionary=owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":recipe,"title":"THE LAST TRAIN","leader_index":0})
  if not check(tried.ok,"real recorded musical trial stage "+str(stage)):return false
  var project: Dictionary=owner.workbench_view().project
  var offer: Dictionary=Recipe.offer(project.fragment.producer_recipe,project.target.respondent_ref)
  if not check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"keep","offer_id":offer.offer_id}).ok,"real band direction response"):return false
  var ticket: Dictionary=owner.begin_workbench_commit(owner.workbench_expected())
  if not check(ticket.ok,"real write ticket"):return false
  var p: Dictionary=ticket.prepared
  var written: Dictionary=owner.game.write_session_prepared(p.args.idea,p.args.form,p.args.title,p.args.leader_index,p)
  if not check(written.ok and owner.complete_workbench_original(ticket.transaction_id,written).ok,"original paid recorded session"):return false
  var tracked: Dictionary=Situation.after_action(ticket.before_game.career,owner.game.career)
  if not check(tracked.ok,"original situation chain"):return false
  var finance: Dictionary=Finance.apply(ticket.before_game.career,Live.after_practice(ticket.before_game.career,tracked.state),"practice:create")
  if not check(finance.ok,"one original writing ledger"):return false
  owner.game.career=finance.state
  if not check(owner.finish_workbench_commit(ticket.transaction_id).ok,"one original paid save"):return false
 return check(owner.game.career.song_catalogue.size()==1 and not Crowd.Song.recipe(owner.game.career.song_catalogue[0]).is_empty(),"genuine frozen recorded song for current set")
func failure_action(button: String,label: String) -> void:
 var audio=scene._career_view._gig_audio
 var starts: int=audio.starts
 await super.failure_action(button,label)
 check(audio.starts==starts,"failedsave emits no new audio event "+label)
func act(name: String) -> bool:
 if not await super.act(name):return false
 var career=scene._career_view
 var visit: Dictionary=Journey.active(owner.game.career)
 if visit.get("phase")=="performing":
  await settle()
  var audio=career._gig_audio
  check(audio._music.playing and audio._music._recorded_player.stream is AudioStreamSynchronized,"actual main-app saved arrangement plays in sync on stage")
  check(audio._recipe==Crowd.Song.recipe(visit.plan.song_snapshots[visit.cursor]),"main-app player uses exact pinned arrangement")
  native_music_verified=audio._music.playing
  native_missing_fx_verified=not audio.effect_available and not audio._crowd.playing
  check(native_missing_fx_verified,"unavailable crowd files remain silent, not substituted")
  var starts: int=audio.starts
  var stable: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
  career._render();await settle()
  check(career._gig_audio==audio and audio._music.playing and audio.starts==starts,"free main-app redraw keeps the same active player")
  await capture("saved-music-playing")
  # Explicit malformed in-memory counterexample: no write or original-file edit.
  owner.game.career[Journey.KEY].active.source_hash="invalid-current-source"
  career._render();await create_timer(0.15).timeout
  check(not career._gig_presentation_valid and not audio.playing(),"held source redraw interrupts cached music")
  owner.game.career=stable.game.career.duplicate(true);career._render();await settle()
  check(not audio.playing() and audio.starts==starts,"restoring held source cannot automatically replay")
  check(owner.snapshot()==stable and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"held-source inspection restores exact state with disk unchanged")
  scene._home();await settle();scene._continue();await settle();scene._open_career_desk("gigs");await settle()
  check(not scene._career_view._gig_audio.playing(),"actual Menu Continue does not replay a spent stage cue")
 if visit.get("phase")=="after_set":
  var photo: TextureRect=scene.find_child("JourneyPlaceImage",true,false)
  check(photo!=null and photo.get_meta("crowd_variant","")==Crowd.live(visit),"actual stage picture follows saved room state")
 if name=="JourneyWrapAction":
  var receipt: Dictionary=Flow.last_receipt(owner.game.career)
  var photo: TextureRect=scene.find_child("ShowScenePlate",true,false)
  check(photo!=null and photo.get_meta("crowd_variant","")==Crowd.finale(receipt),"actual final crowd picture follows original saved verdict")
  check(career._gig_audio.event_kind==("cheer" if receipt.success else "boo"),"final sound intent derives only from saved wrap")
 return true
func finish_next_gig() -> void:
 print("CROWD34_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"primary_gig_actions":primary_taps,"actual_saved_music_verified":native_music_verified,"missing_crowd_fx_honest":native_missing_fx_verified,"listening":false,"physical_device":false}))
 if is_instance_valid(scene):scene.free()
 owner=null;await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)
