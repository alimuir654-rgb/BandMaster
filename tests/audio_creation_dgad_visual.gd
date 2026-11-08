extends "res://tests/recorded_steady_visual.gd"

func run() -> void:
 if not check(not output.is_empty() and fixture(),"isolated genuine formation"):quit(1);return
 var take: Dictionary=Recipe.recipe(Sound.read(owner.game.career));take.hook="dgad_03_v1"
 if not check(owner.begin_workbench("DGAD new source",0,owner.workbench_expected(),take).ok,"new bank enters existing workbench"):quit(1);return
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;scene._career_landing=false;root.add_child(scene)
 for _i in range(5):await process_frame
 var desk: Control=scene.find_child("MixingDesk",true,false)
 if not check(desk!=null,"main app writing room mounted"):quit(1);return
 check(desk._bank_more.text.contains("D–G–A–D 03"),"collapsed selection identifies new bank")
 check(desk._controls.pace.labels[1]=="~100 BPM","new source keeps correct tempo label")
 check(desk._foundations.size()==17,"three legacy plus fourteen recorded choices")
 check(desk._hear.get_global_rect().end.y<=desk.get_viewport_rect().end.y,"playback footer stays inside viewport")
 await capture("collapsed")
 desk._bank_more.pressed.emit()
 await capture("library-top")
 var last: Button=desk.find_child("MixingRecorded_13",true,false)
 check(last.visible,"last new family available in expanded library")
 desk._scroll.ensure_control_visible(last)
 for _i in range(8):await process_frame
 check(desk._scroll.get_global_rect().encloses(last.get_global_rect()),"last family reachable inside scroll viewport")
 await capture("library-bottom")
 last.pressed.emit()
 check(desk._recipe.hook=="dgad_06_v1","last new family selects genuine source")
 desk._bank_more.pressed.emit()
 await capture("selected-last")
 check(desk._bank_more.text.contains("D–G–A–D 06"),"collapsed last choice remains identified")
 desk._hear.pressed.emit()
 check(desk._audio.playing and desk._audio._entry_active.frames==460800,"new source plays exact imported frame count")
 desk._choose("tone",2)
 var started: int=Time.get_ticks_usec()
 while desk._audio.playing and desk._audio._active.tone!="biting" and Time.get_ticks_usec()-started<500000:await process_frame
 check(desk._audio.playing and desk._audio._active.tone=="biting","new source live control wired through main room")
 desk._audio.stop()
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"source choices/preview do not consume or save")
 print("DGAD_VISUAL "+JSON.stringify({"viewport":str(root.size),"checks":checks,"failures":failures,"physical_device":false,"actual_entry":"opening.tscn"}))
 scene.free();scene=null;owner=null
 var ended: int=Time.get_ticks_usec()
 while Time.get_ticks_usec()-ended<100000:await process_frame
 call_deferred("quit",0 if failures.is_empty() else 1)
