extends "res://tests/recorded_steady_test.gd"

func run() -> void:
 if not check(fixture(),"genuine current formation fixture"):finish();return
 check(Bank.HOOKS.size()==14 and Bank.DGAD_HOOKS.size()==6,"six new families added to eight existing")
 for hook in Bank.HOOKS:
  var value: Dictionary=take(hook)
  var expected_tempo: int=102 if hook in Bank.REHEARSAL_HOOKS else 100
  var expected_frames: int=451765 if hook in Bank.REHEARSAL_HOOKS else 460800
  check(Bank.tempo(value)==expected_tempo and Bank.frames(value)==expected_frames,"explicit bank clock "+hook)
  check(Bank.rehearsal(value)==(hook in Bank.REHEARSAL_HOOKS),"new source never aliases rehearsal "+hook)
  var entry: Dictionary=Bank.entry(value)
  check(not entry.is_empty() and entry.tempo==expected_tempo and entry.frames==expected_frames,"correct source manifest "+hook)
 check(Bank.bank_for({"hook":"unknown"}).is_empty() and Bank.entry({"hook":"unknown"}).is_empty(),"unknown source fails closed")
 selected=take("dgad_03_v1",1);selected.shape="build"
 check(Recipe.label(selected,"pace")=="~100 BPM" and Recipe.written(selected).contains("9.60 seconds"),"estimated new-source timing displayed honestly")
 var before: Dictionary=owner.snapshot()
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var host:=Control.new();root.add_child(host)
 var audio=Audio.new();audio.live_audition=true;audio.configure(func():return {"allowed":allowed,"recipe":selected});host.add_child(audio)
 AudioServer.set_bus_mute(0,false)
 check(audio.request_play(10.0),"new bank synchronized playback")
 check(absf(audio._recorded_player.get_playback_position()-6.0)<0.04,"100 BPM seek stays distinct from102bank")
 audio._shape()
 check(absf(audio._recorded_player.stream.get_sync_stream_volume(2)-linear_to_db(.5))<.7,"new source entrance uses its own clock")
 audio.stop();check(audio.request_play(13.0),"new source final-bar seek")
 var previous: float=audio._recorded_player.get_playback_position()
 var started: int=Time.get_ticks_usec()
 selected.tone="biting";audio.notify_controls_changed()
 while audio.playing and audio._active.tone!="biting" and Time.get_ticks_usec()-started<500000:await process_frame
 var elapsed: float=(Time.get_ticks_usec()-started)/1000000.0
 check(audio.playing and audio._active.tone=="biting" and elapsed<.25,"DGAD live tone applies withinbounded desktop time")
 check(absf(audio._recorded_player.get_playback_position()-previous-elapsed)<.09,"DGAD live tone keeps position")
 audio.stop();check(audio.request_play(15.6),"DGAD terminal seek")
 var ending: int=Time.get_ticks_usec()
 while audio.playing and Time.get_ticks_usec()-ending<1000000:await process_frame
 check(not audio.playing,"new source ends once without assumedloop")
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"preview never consumes or saves")
 host.free();await process_frame
 finish()
