extends SceneTree
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Recipe=preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Bank=preload("res://experiments/playable_flightcase/recorded_steady.gd")
const Audio=preload("res://experiments/playable_flightcase/mixing_audio.gd")
const Sound=preload("res://experiments/playable_flightcase/band_sound.gd")
var owner
var checks:=0
var failures: Array=[]
var selected: Dictionary={}

func _init() -> void:call_deferred("run")
func check(ok: bool,words: String) -> bool:
 checks+=1
 if not ok:failures.append(words);push_error(words)
 return ok

func fail_save(action: Callable,words: String) -> void:
 var before: Dictionary=owner.snapshot()
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject failure "+words)
 var result: Variant=action.call()
 check(result is Dictionary and not result.get("ok",true),"failure reported "+words)
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"atomic rollback "+words)
 check(DirAccess.remove_absolute(blocker)==OK,"remove isolated fixture "+words)

func run() -> void:
 owner=Owner.new()
 if not check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"genuine opening"):finish();return
 fail_save(func():return owner.begin_audition("cast_jack","Guitarist",true),"start straight in tryout")
 check(owner.begin_audition("cast_jack","Guitarist",true).ok and owner.audition_view().phase=="tryout","one action reaches real tryout")
 check(owner.audition_action("request",owner.audition_expected(),"space_for_voice").ok and owner.audition_view().phase=="response","requested change remains meaningful")
 var response_token: Dictionary=owner.audition_expected()
 fail_save(func():return owner.resolve_audition_response("invite",response_token),"invite from response")
 check(owner.resolve_audition_response("invite",response_token).ok,"invite directly beside response")
 var invited: Dictionary=owner.snapshot()
 check(not owner.resolve_audition_response("invite",response_token).ok and owner.snapshot()==invited,"double/stale invite never spends again")
 check(owner.audition_view("cast_jack").heard and owner.game.roster.size()==1,"character hearing retained with same player")
 check(owner.begin_audition("cast_zoe","Bassist",true).ok,"second distinct audition")
 check(owner.audition_action("request",owner.audition_expected(),"own_part").ok,"second authored adjustment")
 fail_save(func():return owner.resolve_audition_response("pass",owner.audition_expected()),"pass from response")
 var budget: int=owner.remaining()
 check(owner.resolve_audition_response("pass",owner.audition_expected()).ok and owner.remaining()==budget,"passing spends no talent")
 check(owner.recruit("cast_zoe").ok and owner.recruit("cast_casey").ok,"original recruitment compatibility")
 fail_save(func():return owner.choose_vocal("cast_jack"),"lead voice")
 check(owner.choose_vocal("cast_jack").ok,"inline lead voice uses original cost")
 fail_save(func():return owner.remove_member("cast_zoe"),"remove member")
 fail_save(func():return owner.confirm_lineup(true),"lineup direct to naming")
 check(owner.confirm_lineup(true).ok and owner.screen=="name" and owner.formed_once,"no formation bridge on fresh route")
 var naming: Dictionary=owner.snapshot()
 var legacy=Owner.new();var old: Dictionary=naming.duplicate(true);old.screen="formed"
 check(legacy.restore(old) and legacy.start_naming() and legacy.screen=="name","legacy formed phase still resumable")
 check(owner.submit_name("NIGHT BUS CLUB","Raw").ok,"ask band uses original reactions")
 check(not owner.name_reactions().is_empty(),"real name reactions retained")
 fail_save(func():return owner.lock_name(true),"lock direct to design")
 check(owner.lock_name(true).ok and owner.screen=="identity" and owner.name_settled,"name and look use direct saved transition")
 var identity: Dictionary=owner.snapshot();old=identity.duplicate(true);old.screen="name_milestone"
 legacy=Owner.new();check(legacy.restore(old) and legacy.start_identity(),"legacy name milestone still resumable")
 check(not owner.lock_name(true).ok and owner.snapshot()==identity,"name consequence locked once")
 check(owner.set_identity("Wordmark","Amber / Charcoal","Unpolished") and owner.finish_identity().ok and owner.start_playing(),"original one-time band launch")
 var reload=Owner.new();check(reload.load_draft() and reload.snapshot()==owner.snapshot(),"new route reloads existing schema")
 check(Bank.HOOKS.size()==8 and Bank.HOOKS.slice(0,2)==["steady_early_v1","steady_later_v1"],"eight families keep original stable IDs")
 selected=Recipe.recipe(Sound.read(owner.game.career),1);selected.hook="rehearsal_03_v1";selected.shape="build"
 check(Recipe.valid(selected) and Recipe.label(selected,"pace")=="~102 BPM","new bank honestly marks estimated tempo")
 var entry: Dictionary=Bank.entry(selected)
 if not check(not entry.is_empty() and entry.frames==451765,"new source exact frame count"):finish();return
 var used: Dictionary=Bank.consume(owner.game.career,selected.merged({"stage":0},true),"new-song")
 check(used.ok and used.state[Bank.USES].records.size()==3,"new family consumed per instrumentalist")
 check(not Bank.available(used.state,selected.merged({"stage":0},true),"different-song"),"new family unavailable after use")
 check(Bank.available(used.state,selected,"new-song"),"bound song keeps new source")
 var host:=Control.new();root.add_child(host)
 var audio=Audio.new();audio.live_audition=true;audio.configure(func():return {"allowed":true,"recipe":selected});host.add_child(audio)
 AudioServer.set_bus_mute(0,false)
 check(audio.request_play(15.0),"102 BPM final-bar seek starts")
 var position: float=audio._recorded_player.get_playback_position()
 check(absf(position-15.0*60.0/102.0)<0.04,"seek uses source tempo rather than100BPM")
 audio.stop();check(audio.request_play(10.0),"102 BPM middle seek")
 check(absf(audio._recorded_beat()-10.0)<0.07,"all recorded clocks agree on beat")
 audio._shape()
 check(absf(audio._recorded_player.stream.get_sync_stream_volume(2)-linear_to_db(0.5))<0.7,"102 BPM entrance uses same clock")
 audio.stop();check(audio.request_play(13.0),"102 BPM final-bar tone fixture")
 var before_position: float=audio._recorded_player.get_playback_position()
 var change_started: int=Time.get_ticks_usec()
 selected.tone="biting";audio.notify_controls_changed()
 while audio.playing and audio._active.tone!="biting" and Time.get_ticks_usec()-change_started<500000:await process_frame
 var elapsed: float=(Time.get_ticks_usec()-change_started)/1000000.0
 check(audio.playing and audio._active.tone=="biting" and elapsed<0.25,"new source final-bar live tone remains responsive")
 check(absf(audio._recorded_player.get_playback_position()-before_position-elapsed)<0.09,"tone retains102BPM position")
 audio.stop();check(audio.request_play(15.6),"new source terminal seek")
 await create_timer(0.5).timeout
 check(not audio.playing,"new source plays once and stops at own duration")
 host.queue_free();await process_frame
 finish()

func finish() -> void:
 print("AUDIO_CREATION_TEST "+JSON.stringify({"checks":checks,"failures":failures,"listening":false,"device_tested":false}))
 quit(0 if failures.is_empty() else 1)
