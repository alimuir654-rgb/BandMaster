extends "res://tests/character_consequence_visual.gd"
## Real recruitment workspace, genuine clipped-target input and silent save guards.
func run() -> void:
 owner=Owner.new()
 if not check(not output.is_empty() and owner.begin_new(),"isolated Nina recruitment"):await finish51();return
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true
 root.add_child(scene);await settle()
 await tap("Genre_Indie_rock");await tap("GenreNextAction")
 await person("cast_nina","Singer")
 if not await tap("AuditionSeparateSingerAction"):await finish51();return
 var view: Control=scene._recruit_view
 var choices: Array=owner.game.choices("Singer")
 for i in range(choices.size()):
  if choices[i].id=="cast_nina":view.selected_index=i;break
 view._rebuild();await settle()
 var ideas=scene.find_child("CharacterRecordedIdeas",true,false)
 if not check(ideas!=null and ideas.candidate_id=="cast_nina" and ideas._materials.size()==2,"actual Nina has two approved vocal ideas"):await finish51();return
 var before: Dictionary=owner.snapshot()
 var disk:=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 for index in range(2):
  if not await tap("CharacterIdea_"+str(index)):await finish51();return
  check(ideas.playing and ideas._player.playing,"actual native Nina decoder "+str(index))
  check(ideas._player.stream.get_length()>6 and ideas._player.stream.get_length()<9,"short bounded Nina passage "+str(index))
  await capture("nina-"+("verse" if index==0 else "harmony"))
  await tap("CharacterIdeaStop")
  check(not ideas.playing and ideas._player.stream==null,"stop releases Nina "+str(index))
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"native vocal review has zero save/day/economy effects")
 await finish51()

func finish51() -> void:
 print("PILOT51_NATIVE "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_Android":false,"assistant_listening":false}))
 if is_instance_valid(scene):scene.free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
