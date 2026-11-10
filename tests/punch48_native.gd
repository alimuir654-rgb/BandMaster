extends "res://tests/feedback47_native.gd"

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not await fixture():await finish();return
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;root.add_child(scene);await settle()
 var identities: Array=[]
 for id in ["cast_bex","cast_ben","cast_casey"]:
  var person: Control=scene.find_child("IdentityPortrait_"+id,true,false)
  check(person!=null and person.get_meta("full_length",false),"full selected figure "+id)
  if person!=null:identities.append(person.get_meta("visible_figure_height"))
 identities.sort()
 check(float(identities.back())-float(identities.front())>20,"varied stature retained")
 await capture("formation")
 await tap("StartPlayAction")
 if scene.find_child("PosterWriteAction",true,false)==null:await tap("PosterActivitiesAction")
 var prompt: Label=scene.find_child("CareerMakePrompt",true,false)
 check(prompt!=null and prompt.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER,"centred Make heading")
 for route in ["create","practice","gigs","recording","promotion","offstage"]:
  var label: Label=scene.find_child("CareerLauncherLabel_"+route,true,false)
  check(label!=null and label.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER,"centred Make text "+route)
 for key in ["CareerDate","CareerMenuAction","PosterNav_home","PosterNav_gigs"]:
  var node: Control=scene.find_child(key,true,false)
  check(node!=null and scene.get_global_rect().encloses(node.get_global_rect()),"persistent home control "+key)
 await capture("make")
 scene.free();await settle()
 owner=Owner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"fresh logo fixture")
 for id in ["cast_bex","cast_ben","cast_casey"]:check(owner.recruit(id).get("ok",false),"logo fixture recruit "+id)
 check(owner.choose_vocal("cast_bex").get("ok",false) and owner.confirm_lineup().get("ok",false),"logo fixture lineup")
 check(owner.start_naming() and owner.submit_name("MUNCH","Raw").get("ok",false) and owner.lock_name().get("ok",false) and owner.start_identity(),"real name and design entry")
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;root.add_child(scene);await settle()
 var before: Dictionary=owner.snapshot()
 await tap("IdentityLayout_cutout")
 var mark: Label=scene.find_child("IdentityLiveMark",true,false)
 var composition: Control=mark.get_node_or_null("MarkComposition")
 check(composition!=null and composition.get_meta("live_glyphs")==5,"five native live MUNCH letter shapes")
 await reveal(mark);await capture("cutout-first")
 await tap("IdentityRecutAction")
 check(owner.snapshot()==before and Style.cut_variant(scene.identity_draft.style)==1,"new cut is a free local draft")
 mark=scene.find_child("IdentityLiveMark",true,false)
 composition=mark.get_node_or_null("MarkComposition")
 check(composition!=null and composition.get_meta("cut_variant")==1,"new variant actually rendered")
 await reveal(mark);await capture("cutout-second")
 var draft: Dictionary=scene.identity_draft.duplicate(true)
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject real failed logo write")
 await tap("IdentityFinishAction")
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk and scene.identity_draft==draft,"failed write retains whole save and generated version")
 check(DirAccess.remove_absolute(blocker)==OK,"remove exact failed-write blocker")
 await tap("IdentityFinishAction")
 check(owner.identity_complete and Style.cut_variant(owner.identity_style)==1,"generated version actually saved")
 var restored=Owner.new()
 check(restored.load_draft() and restored.snapshot()==owner.snapshot(),"strict generated-logo reload")
 restored=null
 await capture("formed-cutout")
 scene.free();scene=null;await settle()
 await glyph_proofs()
 await finish()

func glyph_proofs() -> void:
 var Mark=load("res://experiments/playable_flightcase/band_mark.gd")
 var valid: Dictionary=Style.next_cut(Style.defaults())
 var malformed: Dictionary=valid.duplicate(true);malformed[Style.LAYOUT_KEY].cut_variant=1.0
 check(not Style.valid(malformed),"float variation held")
 malformed[Style.LAYOUT_KEY].cut_variant=-1;check(not Style.valid(malformed),"negative variation held")
 malformed[Style.LAYOUT_KEY].cut_variant=10000;check(not Style.valid(malformed),"future variation held")
 for kind in Style.LAYOUTS:
  var style: Dictionary=Style.with_layout(Style.defaults(),kind)
  var mark=Mark.new();mark.configure("THE MIDNIGHT ÉCHO 東京 COLLECTIVE","Wordmark",style,52,false,true)
  mark.position=Vector2(16,18);mark.size=Vector2(350,160);root.add_child(mark);await settle()
  check(mark.full_name=="THE MIDNIGHT ÉCHO 東京 COLLECTIVE" and not mark.text.is_empty(),"Unicode name retained "+kind)
  if kind=="cutout":
   var composition: Control=mark.get_node_or_null("MarkComposition")
   check(composition!=null,"Unicode cutout keeps shaped non-ASCII words")
  mark.free()
 Mark=null
