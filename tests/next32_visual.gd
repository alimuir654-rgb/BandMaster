extends "res://tests/character_consequence_visual.gd"
const Portraits=preload("res://experiments/playable_flightcase/formation_portraits.gd")
const FormationSound=preload("res://experiments/playable_flightcase/formation_sound.gd")
const Press=preload("res://experiments/playable_flightcase/band_identity_press.gd")
func make_band(ids: Array,voice: String,name_text: String) -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ids:
  if not owner.recruit(id).ok:return false
 return owner.choose_vocal(voice).ok and owner.confirm_lineup(true).ok and owner.submit_name(name_text,"Raw").ok and owner.lock_name(true).ok and owner.set_identity("Wordmark","Amber / Charcoal","Unpolished") and owner.finish_identity().ok
func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 var entries: Dictionary=Portraits.entries();check(entries.size()==18,"all18 exact IDs registered")
 for id in entries:
  check(entries[id].gaze_review=="direct_camera" and entries[id].expression_review=="closed_mouth_no_smile","source-reviewed face direction "+id)
 for count in [3,6]:
  var ids: Array=["cast_jack","cast_zoe","cast_casey"] if count==3 else ["cast_ellis","cast_dan","cast_ben","cast_freya","cast_nina","cast_tom"]
  if not check(make_band(ids,"cast_jack" if count==3 else "cast_nina","NIGHT BUS CLUB" if count==3 else "THE LAST BUS HOME"),"real funded formation "+str(count)):finish_next();return
  if is_instance_valid(scene):scene.free()
  scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;scene._formation_armed=true;root.add_child(scene);await settle()
  var before: Dictionary=owner.snapshot()
  var press=scene.find_child("CompletedBandPrint",true,false)
  check(press!=null and press.uses_full_length() and press.visible_ids().size()==count,"real new selected full-length group "+str(count))
  var regions: Dictionary=press.source_regions()
  for id in ids:
   check(regions[id].texture.begins_with("res://experiments/playable_flightcase/art/identity/next32_cast_"),"new registry supersedes special bypass "+id)
   var photo: Control=scene.find_child("IdentityPortrait_"+id,true,false)
   check(photo.get_parent().get_global_rect().grow(1).encloses(photo.get_global_rect()),"full figure contained "+id)
  var primary: Control=scene.find_child("StartPlayAction",true,false)
  check(root.get_visible_rect().encloses(primary.get_global_rect()),"primary in viewport "+str(count))
  await capture("band-"+str(count))
  check(owner.snapshot()==before,"reveal has no gameplay settlement "+str(count))
  var moment=scene.find_child("FormationMoment",true,false)
  check(moment!=null and moment._material==FormationSound.choose(owner.game.roster,"Raw","Unpolished"),"selected coherent cue "+str(count))
  check(not moment._audio.playing or moment._audio.family in ["dark","space","guitar90"],"bounded dedicated cue player")
  if count==3:
   moment.cancel();check(not moment._audio.playing and press.modulate.a==1,"skip/cancel settles picture and releases audio")
   await tap("CompletedMenuAction")
   check(scene.showing_menu,"Menu safely leaves celebration")
  else:
   await tap("StartPlayAction");check(owner.screen=="play","truthful primary enters actual main game")
 # Source-only atlas compositions cover all18 IDs, including non-affordable trios.
 # These are presentation proofs, not claims that those rosters can be hired.
 for group in [["cast_ryan","cast_arjun","cast_tom"],["cast_bex","cast_ben","cast_hannah"],["cast_ellis","cast_marcus","cast_maya"],["cast_lily","cast_nina","cast_sam"],["cast_dan","cast_freya","cast_oscar"]]:
  if is_instance_valid(scene):scene.free();scene=null
  var roster: Array=[]
  for id in group:roster.append(owner.game.person_by_id(id))
  var bg:=ColorRect.new();bg.color=Color("171714");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
  var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for edge in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+edge,20)
  root.add_child(margin)
  var press=Press.new();margin.add_child(press)
  press.configure(roster,group[0],"CAST PORTRAIT PROOF","Wordmark","White / Ink","Unpolished",root.size.x,"complete",{},"",Vector2(root.size)-Vector2(40,40))
  await capture("portraits-"+str(group[0]).trim_prefix("cast_"))
  margin.free();bg.free()
 finish_next()
func finish_next() -> void:
 print("NEXT32_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)
