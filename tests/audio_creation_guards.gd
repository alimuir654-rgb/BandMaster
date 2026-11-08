extends "res://tests/recorded_steady_visual.gd"
var scene

func label_contains(node: Node,text: String) -> bool:
 if node is Label and node.text.contains(text):return true
 for child in node.get_children():
  if label_contains(child,text):return true
 return false

func run() -> void:
 owner=Owner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"legacy opening fixture")
 for id in ["cast_jack","cast_zoe","cast_casey"]:check(owner.recruit(id).ok,"legacy recruit "+id)
 check(owner.choose_vocal("cast_jack").ok and owner.confirm_lineup().ok and owner.screen=="formed","legacy formed checkpoint")
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=true;scene.reduced_motion=true;root.add_child(scene)
 await process_frame
 var saved: Dictionary=owner.snapshot()
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject native Continue failure")
 scene._continue();await process_frame
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"failed Continue retains legacy checkpoint")
 check(scene.showing_menu and label_contains(scene,"naming room could not be opened"),"Continue failure visibly explained")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated blocker")
 scene._continue();await process_frame
 check(owner.screen=="name" and scene.find_child("FreeBandName",true,false)!=null,"retry enters naming without bridge")
 check(owner.submit_name("THE LATE RETURN","Raw").ok and owner.lock_name().ok and owner.screen=="name_milestone","legacy approved-name checkpoint")
 scene._home();await process_frame
 saved=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject native design Continue failure")
 scene._continue();await process_frame
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"failed design Continue retains saved name")
 check(label_contains(scene,"design room could not be opened"),"design failure visibly explained")
 check(DirAccess.remove_absolute(blocker)==OK,"remove design fixture blocker")
 scene._continue();await process_frame
 check(owner.screen=="identity" and scene.find_child("IdentityFinishAction",true,false)!=null,"legacy design resumes directly")
 scene.free();scene=null;owner=null
 # Normal motion retains reveal-before-action; revealing cannot spend talent.
 owner=Owner.new();check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"normal motion fixture")
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=false;root.add_child(scene)
 var recruit: Control=scene._recruit_view
 var items: Array=owner.game.choices("Guitarist")
 for i in range(items.size()):
  if items[i].id=="cast_jack":recruit.selected_index=i;break
 recruit._rebuild();await process_frame
 scene.find_child("AuditionAction",true,false).pressed.emit()
 for _i in range(3):await process_frame
 var pending: bool=scene.find_child("AuditionHeldVoice",true,false).is_revealing()
 check(pending,"normal-motion dialogue is actually revealing")
 saved=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 scene.find_child("AuditionRequestSpace",true,false).pressed.emit();await process_frame
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"reveal-only tap cannot change or spend")
 scene.find_child("AuditionRequestSpace",true,false).pressed.emit();await process_frame
 check(owner.audition_view().phase=="response","second deliberate action reaches response once")
 scene.find_child("AuditionHeldVoice",true,false).finish_now()
 scene.find_child("AuditionInvite",true,false).pressed.emit();await process_frame
 check(owner.game.roster.size()==1 and owner.audition_view("cast_jack").heard,"normal-motion invite commits exactly one player")
 recruit=scene._recruit_view;saved=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject profile removal failure")
 recruit._remove("cast_jack");await process_frame
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"failed profile removal preserves owner")
 check(recruit.game==owner.game and recruit.game.roster.size()==1,"profile follows authoritative restored game")
 check(DirAccess.remove_absolute(blocker)==OK,"remove profile blocker")
 print("AUDIO_CREATION_GUARDS "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false}))
 scene.free();scene=null;owner=null
 call_deferred("quit",0 if failures.is_empty() else 1)
