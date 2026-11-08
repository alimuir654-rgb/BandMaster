extends SceneTree
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Recipe=preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Bank=preload("res://experiments/playable_flightcase/recorded_steady.gd")
const Sound=preload("res://experiments/playable_flightcase/band_sound.gd")
const Rules=preload("res://experiments/playable_flightcase/song_workbench.gd")
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")
const Live=preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance=preload("res://experiments/playable_flightcase/finance_policy.gd")
const Audio=preload("res://experiments/playable_flightcase/mixing_audio.gd")
var owner
var checks:=0
var failures: Array=[]
var selected: Dictionary={}
var allowed:=true

func _init() -> void:
 call_deferred("run")

func check(ok: bool,message: String) -> bool:
 checks+=1
 if not ok:failures.append(message);push_error(message)
 return ok

func fixture() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not owner.recruit(id):return false
 return owner.choose_vocal("cast_jack") and owner.confirm_lineup() and owner.start_naming() and owner.submit_name("QA UNIFIED BAND","Raw") and owner.lock_name() and owner.start_identity() and owner.set_identity("Wordmark","Amber / Charcoal","Unpolished") and owner.finish_identity() and owner.start_playing()

func take(hook: String,stage: int=0) -> Dictionary:
 var value: Dictionary=Recipe.recipe(Sound.read(owner.game.career),stage)
 value.hook=hook
 return value

func trial(value: Dictionary) -> bool:
 var result: Dictionary=owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":value,"title":"Steady at last","leader_index":0})
 if not check(result.ok,"real local trial: "+str(result)):return false
 var project: Dictionary=owner.workbench_view().project
 var offer: Dictionary=Recipe.offer(project.fragment.producer_recipe,project.target.respondent_ref)
 return check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"keep","offer_id":offer.offer_id}).ok,"real considered response")

func paid(fail_save: bool=false) -> Dictionary:
 var ticket: Dictionary=owner.begin_workbench_commit(owner.workbench_expected())
 if not check(ticket.ok,"real paid ticket: "+str(ticket)):return {"ok":false}
 var p: Dictionary=ticket.prepared
 var result: Dictionary=owner.game.write_session_prepared(p.args.idea,p.args.form,p.args.title,p.args.leader_index,p)
 if not check(result.ok,"original session") or not check(owner.complete_workbench_original(ticket.transaction_id,result).ok,"original reconciliation"):return {"ok":false}
 var tracked: Dictionary=Situation.after_action(ticket.before_game.career,owner.game.career)
 if not check(tracked.ok,"situation accounting"):return {"ok":false}
 owner.game.career=Live.after_practice(ticket.before_game.career,tracked.state)
 var accounted: Dictionary=Finance.apply(ticket.before_game.career,owner.game.career,"practice:create")
 if not check(accounted.ok,"finance once"):return {"ok":false}
 owner.game.career=accounted.state
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 if fail_save:check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject real save failure")
 var finished: Dictionary=owner.finish_workbench_commit(ticket.transaction_id)
 if fail_save:check(DirAccess.remove_absolute(blocker)==OK,"remove only harness blocker")
 return finished

func next_available_evening() -> bool:
 for _day in range(7):
  if Situation.inspect_writing(owner.game.career).get("can_write",false):return true
  var before: Dictionary=owner.game.career.duplicate(true)
  var attendance: Dictionary=Situation.inspect_rehearsal(before)
  if not attendance.ok:return false
  var jam: Dictionary=owner.game.informal_practice(attendance.attendee_indices)
  if not check(jam.ok,"public informal practice on blocked evening"):return false
  var tracked: Dictionary=Situation.after_action(before,owner.game.career)
  if not tracked.ok:return false
  owner.game.career=Live.after_practice(before,tracked.state)
  var accounted: Dictionary=Finance.apply(before,owner.game.career,"practice:jam")
  if not accounted.ok:return false
  owner.game.career=accounted.state
  if not owner.save_draft():return false
 return false

func run() -> void:
 if not check(fixture(),"genuine public formation fixture"):finish();return
 var untouched: Dictionary=owner.snapshot()
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 for hook in Bank.HOOKS:
  var value: Dictionary=take(hook)
  check(Recipe.valid(value),"new source canonical")
  for axis in ["pace","groove","originality"]:
   var invalid: Dictionary=value.duplicate(true);invalid[axis]=Recipe.VALUES[Recipe.FIELDS.find(axis)][0 if axis=="pace" else 1]
   check(not Recipe.valid(invalid),"reject invented playing: "+axis)
  check(Recipe.written(value).contains("100 BPM") and not Recipe.written(value).contains("answering guitar"),"honest fixed source description")
  var entry: Dictionary=Bank.entry(value)
  if check(not entry.is_empty(),"source manifest available"):
   for part in entry.parts:check(Bank.stream(entry.parts[part])!=null,"exact imported PCM hash: "+hook+"/"+part)
  for stage in range(3):
   value.stage=stage
   var offer: Dictionary=Recipe.offer(value,{"candidate_id":"qa"})
   check(Recipe.request_ok(offer) and Recipe.adjustable(value,offer.field),"NPC offers real source operation")
 check(owner.snapshot()==untouched and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"inspection has no save/economy effects")
 selected=take(Bank.HOOKS[0],1);selected.shape="burst"
 var host:=Control.new();root.add_child(host)
 var audio=Audio.new();audio.live_audition=true
 audio.configure(func():return {"allowed":allowed,"recipe":selected})
 host.add_child(audio)
 AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),false)
 check(audio.request_play(),"real synchronized recorded playback starts")
 var unsupported: Dictionary=selected.duplicate(true);unsupported.brief.genre="Jazz"
 check(not audio.available_for(unsupported),"cached audio never authorises unsupported genre")
 var player: AudioStreamPlayer=audio.get_node("RecordedPhrase")
 check(player.stream is AudioStreamSynchronized and player.stream.stream_count==3,"one clock drives three matched stems")
 check(is_equal_approx(player.stream.get_sync_stream_volume(1),0.0),"stage1 bass joins burst")
 host.hide();await create_timer(0.25).timeout
 check(not audio.playing,"hidden workbench stops")
 host.show();audio.request_play();allowed=false;await create_timer(0.25).timeout
 check(not audio.playing,"stale permission stops")
 allowed=true;audio.request_play();AudioServer.set_bus_mute(0,true);await create_timer(0.25).timeout
 check(not audio.playing,"master mute stops")
 AudioServer.set_bus_mute(0,false)
 selected.stage=0;audio.request_play()
 check(player.stream.get_sync_stream_volume(1)<-70 and player.stream.get_sync_stream_volume(2)<-70,"stage0 only guitar")
 audio.stop();selected.stage=2;audio.request_play(15.0);await create_timer(1.0).timeout
 check(not audio.playing,"recorded phrase ends once without unverified looping")
 audio.request_play(12.5)
 selected.tone="warm";await create_timer(0.25).timeout
 check(audio.playing and audio._active.tone=="warm","tone changes during final recorded bar")
 check(player.get_playback_position()>7.5,"tone change retains phrase position")
 audio.request_play();audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not audio.playing,"focus loss stops")
 check(owner.snapshot()==untouched and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"playback does not consume or save")
 host.queue_free();await process_frame
 var begin: Dictionary=owner.begin_workbench("Steady at last",0,owner.workbench_expected(),take(Bank.HOOKS[0]))
 if not check(begin.ok,"begin through real owner") or not trial(take(Bank.HOOKS[0])):finish();return
 check(not owner.game.career.has(Bank.USES),"free draft and trials do not consume")
 var before: Dictionary=owner.snapshot();var before_disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var failed: Dictionary=paid(true)
 check(not failed.ok and owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==before_disk,"failed final save rolls back whole owner, consumption and existing disk")
 if not check(paid().ok,"same ticket flow retries successfully"):finish();return
 var project_id: String=owner.workbench_view().project.id
 var records: Array=owner.game.career[Bank.USES].records
 check(records.size()==3,"first paid session consumes once per actual instrumentalist")
 check(not Bank.available(owner.game.career,take(Bank.HOOKS[0]),"another-song"),"used phrase unavailable to next song")
 check(Bank.available(owner.game.career,take(Bank.HOOKS[0]),project_id),"current song retains source")
 check(Bank.available(owner.game.career,take(Bank.HOOKS[1]),"another-song"),"other family remains available")
 var changed_roster: Dictionary=owner.game.career.duplicate(true)
 changed_roster.members[0].candidate_id="joining-guitarist"
 changed_roster[Bank.USES].records.append({"candidate_id":"joining-guitarist","hook":Bank.HOOKS[0],"project_id":"their-previous-song"})
 var bound: Dictionary=take(Bank.HOOKS[0],1)
 check(Bank.available(changed_roster,bound,project_id),"replacement who used phrase elsewhere cannot strand bound song")
 check(Bank.consume(changed_roster,bound,project_id).state==changed_roster,"later stages never consume changed roster")
 changed_roster.members=[]
 check(Bank.available(changed_roster,bound,project_id),"bound source retains first-stage cohort after members depart")
 for stage in [1,2]:
  if not check(next_available_evening(),"respect work commitments before stage "+str(stage)) or not trial(take(Bank.HOOKS[0],stage)) or not check(paid().ok,"paid stage "+str(stage)):finish();return
 check(owner.game.career[Bank.USES].records==records,"later stages never duplicate inventory")
 var finished: Dictionary=Rules.finished(owner.snapshot())
 check(finished.ok and finished.items.size()==1,"saved catalogue preserves frozen recipe and craft receipt")
 if not finished.items.is_empty():
  var read: Dictionary=Rules.read_finished(owner.snapshot(),finished.items[0].reference)
  check(read.ok and Recipe.valid(read.fragment.fragment.producer_recipe) and not Bank.entry(read.fragment.fragment.producer_recipe).is_empty(),"finished consumed song still plays")
 var reload=Owner.new()
 check(reload.load_draft() and reload.snapshot()==owner.snapshot(),"unknown career extension survives actual reload without migration")
 var damaged: Dictionary=owner.game.career.duplicate(true);damaged[Bank.USES]={"version":1,"records":"bad"}
 var held: Dictionary=Bank.consume(damaged,take(Bank.HOOKS[1]),"next")
 check(not held.ok and held.state==damaged,"malformed inventory held, never reset")
 check(not Bank.available(owner.game.career,take(Bank.HOOKS[0]),"new-project"),"completed phrase remains consumed")
 finish()

func finish() -> void:
 var result: Dictionary={"checks":checks,"failures":failures,"listening":false,"device_tested":false}
 print("RECORDED_STEADY_TEST "+JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
