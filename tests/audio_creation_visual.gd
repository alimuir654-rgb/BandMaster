extends "res://tests/recorded_steady_visual.gd"
var scene

func settle() -> void:
 for _i in range(3):await process_frame

func tap(node_name: String) -> bool:
 var button: Button=scene.find_child(node_name,true,false) as Button
 if not check(button!=null and button.is_visible_in_tree() and not button.disabled,"action available "+node_name):return false
 button.pressed.emit()
 await settle()
 return true

func person(id: String,role_name: String) -> void:
 var view: Control=scene._recruit_view
 view._change_role(role_name)
 var choices: Array=owner.game.choices(role_name)
 for i in range(choices.size()):
  if choices[i].id==id:view.selected_index=i;break
 view._rebuild();await settle()

func audition(id: String,role_name: String,label: String) -> bool:
 await person(id,role_name)
 if not await tap("AuditionAction"):return false
 if not check(owner.audition_view().phase=="tryout","direct tryout "+id):return false
 if label=="guitar":
  await capture("audition-first")
  await tap("AuditionBiography")
  check(scene.find_child("AuditionBiographyBody",true,false).visible,"biography remains available")
  await tap("AuditionBiography")
 if not await tap("AuditionRequestSpace"):return false
 check(owner.audition_view().phase=="response","real adjusted response "+id)
 check(scene.find_child("AuditionReview",true,false)==null,"no invitation bridge "+id)
 if label=="guitar":
  var before: Dictionary=owner.snapshot()
  await tap("AuditionPriorToggle")
  await tap("AuditionPriorToggle")
  check(owner.snapshot()==before,"original comparison does not write")
  check(scene.find_child("AuditionBiography",true,false).get_theme_color("font_color").r>0.7,"quiet action ink readable on dark poster")
  await capture("audition-response")
 return await tap("AuditionInvite")

func run() -> void:
 owner=Owner.new()
 if not check(not output.is_empty() and owner.begin_new(),"isolated new band"):quit(1);return
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true
 root.add_child(scene);await settle()
 await tap("Genre_Indie_rock")
 await tap("GenreNextAction")
 check(owner.screen=="recruit","native recruitment entry")
 await capture("recruit")
 if not await audition("cast_jack","Guitarist","guitar"):finish_flow();return
 var voices: OptionButton=scene.find_child("RecruitLeadVoice",true,false) as OptionButton
 if check(voices!=null,"lead voice in same workspace"):
  if voices.has_method("show_popup"):
   voices.call("show_popup");await settle();await capture("lead-voice")
   voices.get_popup().hide()
  for i in range(voices.item_count):
   if voices.get_item_metadata(i)=="cast_jack":voices.select(i);voices.item_selected.emit(i);break
 await settle()
 check(owner.lead_vocal_id=="cast_jack","inline voice saved")
 if not await audition("cast_zoe","Bassist","bass"):finish_flow();return
 if not await audition("cast_marcus","Drummer","drums"):finish_flow();return
 check(owner.game.roster.size()==3 and owner.ready(),"real three-person lineup ready")
 if not await tap("ReviewLineupAction"):finish_flow();return
 await capture("lineup")
 if not await tap("StartAction"):finish_flow();return
 check(owner.screen=="name" and scene.find_child("FreeBandName",true,false)!=null,"lineup directly opens naming")
 var field: LineEdit=scene.find_child("FreeBandName",true,false)
 field.text="NIGHT BUS CLUB";field.text_changed.emit(field.text)
 if not await tap("NameSubmitAction"):finish_flow();return
 check(owner.name_reactions().size()==3,"all actual bandmates react")
 check(scene.find_child("FreeBandName",true,false).get_theme_color("font_uneditable_color").r<0.3,"confirmed name readable on paper")
 await capture("name-reactions")
 if not await tap("NameLockAction"):finish_flow();return
 check(owner.screen=="identity","name directly opens look design")
 await capture("design")
 if not await tap("IdentityFinishAction"):finish_flow();return
 check(owner.screen=="complete" and owner.identity_complete,"one final band poster")
 await capture("final-band")
 if not await tap("StartPlayAction"):finish_flow();return
 check(owner.screen=="play","native launch into existing career")
 var take: Dictionary=Recipe.recipe(Sound.read(owner.game.career));take.hook="rehearsal_03_v1"
 check(owner.begin_workbench("Night bus idea",0,owner.workbench_expected(),take).ok,"new saved family in existing workbench")
 scene._career_landing=false;scene._render();await settle()
 var desk: Control=scene.find_child("MixingDesk",true,false)
 check(desk!=null and desk._bank_more.text.contains("REHEARSAL 03"),"collapsed bank shows selected saved family")
 var before: Dictionary=owner.snapshot()
 await capture("bank-collapsed")
 await tap("MixingBankMore")
 check(desk.find_child("MixingRecorded_7",true,false).is_visible_in_tree(),"all eight families discoverable")
 await capture("bank-open")
 await tap("MixingBankMore")
 check(owner.snapshot()==before,"bank browsing does not spend or consume")
 await tap("MixingHear")
 check(desk._audio.playing,"new recorded source plays in main app")
 desk._audio.stop()
 finish_flow()

func finish_flow() -> void:
 print("AUDIO_CREATION_VISUAL "+JSON.stringify({"viewport":str(root.size),"checks":checks,"failures":failures,"actual_entry":"opening.tscn","physical_device":false}))
 scene.free();scene=null;owner=null
 # AudioServer processes a just-issued stop on its mixing thread. Do not quit
 # in the same frame and misreport its pending playback resources as UI leaks.
 var stopped: int=Time.get_ticks_usec()
 while Time.get_ticks_usec()-stopped<100000:await process_frame
 call_deferred("quit",0 if failures.is_empty() else 1)
