extends "res://tests/song57_craft_fairness.gd"
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=")
 if not _check(work_root.is_absolute_path() and ProjectSettings.globalize_path(Owner.SAVE_PATH).begins_with(work_root+"/"),"isolated owner saves"):_finish();return
 if "--baseline" in OS.get_cmdline_user_args():
  var old: Array=_integration(false)
  _check(old.size()==2,"genuine prior full completed songs")
  var file=FileAccess.open(work_root+"/baseline-songs.json",FileAccess.WRITE);file.store_string(JSON.stringify(old,"",true,true));file.close();_finish();return
 _selection_guards()
 for scenario in ["try","keep","dismiss","overwrite","switch"]:_song(scenario)
 var legacy: Variant=_decode(FileAccess.get_file_as_string(work_root+"/baseline-songs.json"))
 _check(legacy is Array and legacy.size()==2,"actual baseline completed fixtures")
 if legacy is Array:
  for snapshot in legacy:
   var before: PackedByteArray=var_to_bytes(snapshot)
   _check(Workbench.finished(snapshot).items.size()==1,"old completed song and identity valid")
   _check(var_to_bytes(snapshot)==before,"legacy validation does not invent contributions")
   var file=FileAccess.open(Owner.SAVE_PATH,FileAccess.WRITE);file.store_string(JSON.stringify(snapshot,"",true,true));file.close()
   var restored=Owner.new()
   _check(restored.load_draft() and restored.game.career.song_catalogue==snapshot.game.career.song_catalogue,"real legacy owner reload exact")
 _finish()

func _begin() -> bool:
 if not _check(_fixture() and _available(),"original formation/availability"):return false
 return _check(owner.begin_workbench("A retained idea",0,owner.workbench_expected(),Mixing.recipe({"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"})).ok,"real original begin")

func _selection_guards() -> void:
 if not _begin():return
 for id in ["", "cast_jack", "unknown"]:
  var before: Dictionary=owner.snapshot()
  var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
  _check(not owner.workbench_action("select_collaborator",owner.workbench_expected(),{"candidate_id":id}).ok,"invalid collaborator refused "+id)
  _check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"invalid selection no write")
 var snapshot: Dictionary=owner.snapshot()
 for mode in ["inactive","duplicate","unknown_present"]:
  var changed: Dictionary=snapshot.duplicate(true)
  if mode=="inactive":changed.game.career.members[2].life_status="away"
  elif mode=="duplicate":changed.game.career.members[1].candidate_id="cast_casey"
  else:changed.game.career.members[2].candidate_id="invented"
  var before: PackedByteArray=var_to_bytes(changed)
  _check(not Workbench.checkpoint(changed,"select_collaborator",Workbench.expected(changed),{"candidate_id":"invented" if mode=="unknown_present" else "cast_casey"}).ok,"inactive/duplicate/unknown canonical collaborator held")
  _check(var_to_bytes(changed)==before,"invalid pure checkpoint leaves input exact")
 var before: Dictionary=owner.snapshot()
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 _check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"actual free-save blocker")
 _check(not owner.workbench_action("select_collaborator",owner.workbench_expected(),{"candidate_id":"cast_casey"}).ok,"free selection real save failure")
 _check(DirAccess.remove_absolute(blocker)==OK,"remove isolated blocker")
 _check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"free failure full owner/disk rollback")
 _check(owner.workbench_action("select_collaborator",owner.workbench_expected(),{"candidate_id":"cast_casey"}).ok,"free selection retry")
 var old_game: Dictionary=before.game.duplicate(true);old_game.career.erase(Workbench.KEY)
 var new_game: Dictionary=owner.snapshot().game.duplicate(true);new_game.career.erase(Workbench.KEY)
 _check(Workbench._exact(old_game,new_game),"free selection no game/day/cash/Finance/relationship effects")
 var restored=Owner.new()
 _check(restored.load_draft() and restored.workbench_view().project.target.respondent_ref.candidate_id=="cast_casey","selected second nonleader survives real save/load")

func _song(scenario: String) -> void:
 if not _begin():return
 var initial: Dictionary=owner.workbench_view().project
 var recipe: Dictionary=initial.fragment.producer_recipe.duplicate(true)
 _check(owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":recipe,"title":"A retained idea","leader_index":0}).ok,"legacy first collaborator trial")
 var old_offer: Dictionary=Producer.offer(recipe,initial.target.respondent_ref)
 _check(owner.workbench_action("select_collaborator",owner.workbench_expected(),{"candidate_id":"cast_casey"}).ok,"explicit second collaborator selected")
 _check(not owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"try","offer_id":old_offer.offer_id}).ok,"changed collaborator invalidates previous trial/offer")
 for stage in range(3):
  if not _check(_available(),"genuinely available writing day"):return
  if scenario=="switch" and stage==1:
   _check(owner.workbench_action("select_collaborator",owner.workbench_expected(),{"candidate_id":"cast_zoe"}).ok,"later paid session can explicitly choose another collaborator")
  recipe=owner.workbench_view().project.fragment.producer_recipe.duplicate(true);recipe.stage=stage
  if scenario=="overwrite" and stage>0:recipe.energy="open" if stage==1 else "full"
  _check(owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":recipe,"title":"A retained idea","leader_index":0}).ok,"fresh selected collaborator trial")
  var project: Dictionary=owner.workbench_view().project
  _check(project.target.respondent_ref.candidate_id==("cast_zoe" if scenario=="switch" and stage>=1 else "cast_casey"),"actual selected person retained across free/paid stages")
  var offer: Dictionary=Producer.offer(recipe,project.target.respondent_ref)
  var choice: String="try" if (stage==0 and scenario in ["try","overwrite","switch"]) or (stage==1 and scenario=="switch") else ("dismiss" if scenario=="dismiss" else "keep")
  _check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":choice,"offer_id":offer.offer_id}).ok,"explicit exact response")
  project=owner.workbench_view().project
  _check(project.paid_receipts.size()==stage,"free response has no paid contribution history")
  if stage==2:
   var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
   _check(not _paid(true).ok,"real final save fails")
   _check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"paid failure restores selection/history/full state")
  if not _check(_paid().ok,"one original paid stage commits"):return
  var saved: Dictionary=owner.snapshot();var saved_disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
  _check(not owner.finish_workbench_commit(last_transaction).ok,"duplicate settlement denied")
  _check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==saved_disk,"duplicate creates no credit/day/cash/save")
  var restored=Owner.new()
  _check(restored.load_draft() and restored.snapshot()==owner.snapshot(),"actual full typed owner reload")
  owner=restored
 var song: Dictionary=owner.game.career.song_catalogue[-1]
 var extension: Dictionary=song[Workbench.FRAGMENT_KEY]
 _check(Workbench.finished(owner.snapshot()).items.size()==1,"finished full new extension valid")
 _check(extension.co_writing_v1.retained.size()==(2 if scenario=="switch" else (1 if scenario=="try" else 0)),"only actual retained adoption credited; no declined/resurrected credit "+scenario)
 if scenario=="switch":
  var actual: Dictionary={}
  for item in extension.co_writing_v1.retained:actual[item.field]=item.candidate_id
  _check(actual=={"energy":"cast_casey","groove":"cast_zoe"},"separate actual people own only their adopted fields")
 if scenario=="try":
  var kept: Dictionary=extension.co_writing_v1.retained[0]
  _check(kept.candidate_id=="cast_casey" and kept.field=="energy" and kept.stage==0 and kept.value==song[Workbench.FRAGMENT_KEY].fragment.producer_recipe.energy,"retained specific person/change/paid stage")
 _check(extension.co_writing_v1.revision_id==extension.composition_identity_v1.revision_id and extension.co_writing_v1.song_id==song.id,"contribution bound to canonical song/revision")
 for bad in [{},null,{"policy":"unknown_future"}]:
  var damaged: Dictionary=owner.snapshot();damaged.game.career.song_catalogue[-1][Workbench.FRAGMENT_KEY].co_writing_v1=bad
  _check(Workbench.finished(damaged).items.is_empty(),"malformed/unknown contribution extension held")
 for mode in ["wrong_song","drop_event","partial_target","drop_snapshot"]:
  var bad: Dictionary=owner.snapshot()
  var ext: Dictionary=bad.game.career.song_catalogue[-1][Workbench.FRAGMENT_KEY]
  if mode=="wrong_song":ext.co_writing_v1.song_id="original:999"
  if mode=="drop_event":
   for row in ext.paid_receipts:row.erase("co_write_v1")
   for row in ext.project_snapshot.paid_receipts:row.erase("co_write_v1")
   ext.erase("co_writing_v1")
  if mode=="partial_target":
   ext.paid_receipts[0].target.erase("collaborator_policy")
   ext.project_snapshot.paid_receipts[0].target.erase("collaborator_policy")
  if mode=="drop_snapshot":ext.erase("co_writing_v1")
  _check(Workbench.finished(bad).items.is_empty(),"known metadata cannot downgrade/crossbind: "+mode)
 var renamed: Dictionary=owner.snapshot();renamed.game.career.song_catalogue[-1].title="A NEW TITLE"
 _check(Workbench.finished(renamed).items.size()==1,"renaming preserves saved contributions")
