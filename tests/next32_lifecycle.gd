extends "res://tests/next32_visual.gd"
func mount_animated() -> void:
 if is_instance_valid(scene):scene.free()
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=false;scene._formation_armed=true;root.add_child(scene);await settle()
func run() -> void:
 if not check(make_band(["cast_jack","cast_zoe","cast_casey"],"cast_jack","NIGHT BUS CLUB"),"real lifecycle fixture"):finish_lifecycle();return
 var snapshot: Dictionary=owner.snapshot()
 await mount_animated()
 var moment=scene.find_child("FormationMoment",true,false)
 check(moment!=null and moment._material=="dark","normal motion uses actual new cue family")
 moment.cancel();check(not moment._audio.playing and moment._poster.modulate.a==1.0 and owner.snapshot()==snapshot,"skip/cancel makes complete information immediately available without settlement")
 await mount_animated();moment=scene.find_child("FormationMoment",true,false)
 AudioServer.set_bus_mute(0,true);await create_timer(0.15).timeout
 check(not moment._audio.playing and owner.snapshot()==snapshot,"mute stops presentation without spending")
 AudioServer.set_bus_mute(0,false)
 await mount_animated();moment=scene.find_child("FormationMoment",true,false)
 moment._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not moment._audio.playing and moment._poster.modulate.a==1.0 and owner.snapshot()==snapshot,"focus loss cancels tween and cue; no auto resume")
 await mount_animated();moment=scene.find_child("FormationMoment",true,false)
 scene.hide();await settle();check(not moment._audio.playing and owner.snapshot()==snapshot,"hidden celebration stops")
 await mount_animated();moment=scene.find_child("FormationMoment",true,false)
 var old_size: Vector2i=root.size;root.size=old_size+Vector2i(8,4);await create_timer(0.15).timeout
 check(scene.find_child("FormationMoment",true,false)==null and owner.snapshot()==snapshot,"resize cancels without replay or settlement")
 root.size=old_size;await settle()
 await mount_animated();await tap("CompletedMenuAction");check(scene.showing_menu and scene.find_child("FormationMoment",true,false)==null and owner.snapshot()==snapshot,"actual Menu immediately stops reveal without changing band")
 check(FormationSound.choose([],"Dark","Unpolished")=="dark" and FormationSound.choose([],"Dreamy","Unpolished")=="space" and FormationSound.choose([],"Raw","Unpolished")=="guitar90","confirmed direction selects coherent single family")
 # Unsupported legacy genre gets no newly substituted indie performance.
 var poster:=Control.new();scene.add_child(poster)
 var unsupported=load("res://experiments/playable_flightcase/formation_moment.gd").new();scene.add_child(unsupported)
 unsupported.begin(poster,"Punk",true,func():return true,owner.game.roster,"Raw","Unpolished")
 check(unsupported._material=="" and unsupported._audio==null,"legacy othergenre never gets wrong indie cue")
 unsupported.free()
 await capture("lifecycle-menu")
 finish_lifecycle()
func finish_lifecycle() -> void:
 print("NEXT32_LIFECYCLE "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null;await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)
