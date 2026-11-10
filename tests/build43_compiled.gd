extends SceneTree
## External harness: all preloads resolve against the actual exported APK payload ZIP.
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Recipe=preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Bank=preload("res://experiments/playable_flightcase/recorded_steady.gd")
const New=preload("res://experiments/playable_flightcase/recorded_vocal_keys.gd")
const Sound=preload("res://experiments/playable_flightcase/band_sound.gd")
const Rules=preload("res://experiments/playable_flightcase/song_workbench.gd")
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")
const Live=preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance=preload("res://experiments/playable_flightcase/finance_policy.gd")
const Audio=preload("res://experiments/playable_flightcase/mixing_audio.gd")
const Song=preload("res://experiments/playable_flightcase/song_audio.gd")
var owner
var checks:=0
var failures: Array=[]
var selected: Dictionary={}
var allowed:=true
var packaged:=false
func _init() -> void:
 call_deferred("run")

func check(ok: bool,message: String) -> bool:
 checks+=1
 if not ok:failures.append(message);push_error(message)
 return ok

func fixture() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_tom","cast_ben","cast_ellis","cast_maya","cast_freya"]:
  var result: Dictionary=owner.recruit(id)
  if not result.get("ok",false):print("FORMATION "+str(result));return false
 return owner.choose_vocal("cast_maya").get("ok",false) and owner.confirm_lineup(true).get("ok",false) and owner.submit_name("SOURCE WINDOW","Raw").get("ok",false) and owner.lock_name(true).get("ok",false) and owner.finish_identity().get("ok",false) and owner.start_playing()
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
 packaged=FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot")
 if not check(packaged,"actual exported binary project payload"):await finish();return
 if not check(fixture(),"actual compiled funded owner"):await finish();return
 var stable: Dictionary=owner.snapshot()
 for hook in Bank.HOOKS:
  var value: Dictionary=take(hook,2)
  if hook in New.HOOKS:value=New.select(value,hook)
  check(Recipe.valid(value),"compiled canonical source "+hook)
  var entry: Dictionary=Bank.entry(value)
  if not check(not entry.is_empty(),"packaged actual source manifest "+hook):await finish();return
  for part in entry.parts:
   var stream=New.stream(entry.parts[part],int(entry.frames)) if value.version==5 else Bank.stream(entry.parts[part],int(entry.frames))
   check(stream!=null,"actual packaged PCM identity "+hook+"/"+str(part))
  selected=value;selected.shape="burst"
  var audio=Audio.new();audio.configure(func():return {"allowed":allowed,"recipe":selected});root.add_child(audio)
  check(audio.request_play(),"actual compiled source playback "+hook)
  check(audio._recorded_player.stream.stream_count==(5 if value.version==5 else 3),"packaged synchronized stream count "+hook)
  audio.free();await process_frame
 check(owner.snapshot()==stable,"packaged source inspection free")
 for hook in [Bank.STEADY_HOOKS[0],New.HOOKS[0]]:
  check(fixture(),"fresh isolated compiled paid fixture")
  var value: Dictionary=take(hook)
  if hook in New.HOOKS:value=New.select(value,hook)
  var wrong: Dictionary=New.select(value,New.HOOKS[1]);var before: Dictionary=owner.snapshot()
  check(not owner.begin_workbench("Steady at last",0,owner.workbench_expected(),wrong).ok and owner.snapshot()==before,"compiled wrong performer source refused atomically")
  if not check(owner.begin_workbench("Steady at last",0,owner.workbench_expected(),value).ok,"actual compiled draft begins"):await finish();return
  for stage in range(3):
   if not check(next_available_evening(),"compiled original availability"):await finish();return
   value.stage=stage
   if not await trial(value):await finish();return
   before=owner.snapshot()
   check(not paid(true).ok and owner.snapshot()==before,"actual compiled filesystem failure rolls back")
   if not check(paid().ok,"actual compiled paid save"):await finish();return
   var restored=Owner.new();check(restored.load_draft() and restored.snapshot()==owner.snapshot(),"compiled strict typed reload");restored=null
  var songs: Array=owner.game.career.song_catalogue
  check(songs.size()==1 and Song.recipe(songs[0]).hook==hook,"actual compiled saved song has frozen source")
  check(not Bank.available(owner.game.career,take(hook),"another-project"),"compiled once-only source ledger")
  if value.version==5:
   selected=Song.recipe(songs[0]);var audio=Audio.new();audio.live_audition=true;audio.configure(func():return {"allowed":allowed,"recipe":selected});root.add_child(audio)
   check(audio.request_play(),"compiled saved voice plays")
   var stream=audio._recorded_player.stream.get_sync_stream(0);var volume: float=audio._recorded_player.stream.get_sync_stream_volume(0)
   selected.energy="open";selected.shape="burst";audio.notify_controls_changed();await process_frame
   check(audio._recorded_player.stream.get_sync_stream(0)==stream and audio._recorded_player.stream.get_sync_stream_volume(0)==volume,"compiled backing change retains identical vocal and level")
   AudioServer.set_bus_mute(0,true);await create_timer(0.15).timeout;check(not audio.playing,"compiled mute releases playback");AudioServer.set_bus_mute(0,false);audio.free();stream=null
 await finish()
func finish() -> void:
 print("BUILD43_COMPILED_MODEL "+JSON.stringify({"checks":checks,"failures":failures,"compiled_payload":packaged,"physical_device":false,"listening":false}))
 owner=null;await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)
