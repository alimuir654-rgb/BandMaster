extends "res://tests/song57_craft_fairness.gd"
# Uses the genuine original owner and rollback/retry/duplicate/reload proof.
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=")
 if not _check(work_root.is_absolute_path() and ProjectSettings.globalize_path(Owner.SAVE_PATH).begins_with(work_root+"/"),"isolated actual owner save"):_finish();return
 var baseline: bool="--baseline" in OS.get_cmdline_user_args()
 var snapshots: Array=_integration(false)
 _check(snapshots.size()==2,"two complete producer/mixing songs")
 for snapshot in snapshots:
  var song: Dictionary=snapshot.game.career.song_catalogue[-1]
  var extension: Dictionary=song[Workbench.FRAGMENT_KEY]
  if baseline:
   _check(not extension.has("composition_identity_v1"),"actual baseline has no new identity")
   continue
  var identity: Dictionary=extension.get("composition_identity_v1",{})
  _check(identity.get("policy")=="song_identity_v1" and identity.get("song_id")==song.id,"new canonical song identity")
  _check(identity.get("writing_sessions",[]).size()==3,"three paid writing role receipts, not inferred credits")
  _check(identity.writing_sessions[0].leader=={"candidate_id":"cast_jack"} and identity.writing_sessions[0].respondent=={"candidate_id":"cast_zoe"},"canonical cast identities instead of numeric slots")
  var renamed: Dictionary=snapshot.duplicate(true)
  renamed.game.career.song_catalogue[-1].title="SAME TITLE / renamed ☾"
  _check(Workbench.finished(renamed).items.size()==1 and renamed.game.career.song_catalogue[-1][Workbench.FRAGMENT_KEY].composition_identity_v1==identity,"rename retains identity")
  for key in ["song_id","composition_id","revision_id","material_sha256","policy"]:
   var bad: Dictionary=snapshot.duplicate(true)
   bad.game.career.song_catalogue[-1][Workbench.FRAGMENT_KEY].composition_identity_v1[key]="forged"
   _check(Workbench.finished(bad).items.is_empty(),"reject forged identity field "+key)
  var bad: Dictionary=snapshot.duplicate(true)
  bad.game.career.song_catalogue[-1][Workbench.FRAGMENT_KEY].composition_identity_v1.writing_sessions[0].leader.candidate_id="cast_casey"
  _check(Workbench.finished(bad).items.is_empty(),"reject forged writing actor")
  for malformed in [null,42,{}, {"leader_ref":{}}, {"leader_ref":{"candidate_id":42},"respondent_ref":{}}]:
   var broken: Dictionary=extension.duplicate(true)
   broken.paid_receipts[0].target=malformed
   _check(Callable(Workbench,"_composition_identity").call(str(song.id),broken).is_empty(),"malformed source target safely rejected")
  for invalid_id in ["", "other:1", "original:0", "original:-1", "original:01", "original:1.0", "original:1000000000", "original:"+"9".repeat(1000)]:
   _check(Callable(Workbench,"_composition_identity").call(invalid_id,extension).is_empty(),"noncanonical song ID rejected "+invalid_id)
  for invalid_id in ["", "original:1", "workbench:0", "workbench:01", "workbench:1000000000"]:
   var broken: Dictionary=extension.duplicate(true);broken.project_id=invalid_id
   _check(Callable(Workbench,"_composition_identity").call(str(song.id),broken).is_empty(),"noncanonical project ID rejected "+invalid_id)
  var no_person: Dictionary=extension.duplicate(true)
  no_person.paid_receipts[0].target.respondent_ref={}
  _check(Callable(Workbench,"_composition_identity").call(str(song.id),no_person).writing_sessions[0].respondent=={"none":true},"no respondent remains explicitly none")
  no_person.paid_receipts[0].target.respondent_ref=extension.paid_receipts[0].target.respondent_ref.duplicate(true)
  no_person.paid_receipts[0].target.respondent_ref.candidate_id=""
  _check(Callable(Workbench,"_composition_identity").call(str(song.id),no_person).writing_sessions[0].respondent=={"untracked":true},"legacy nonempty actor remains unknown")
  var shifted: Dictionary=extension.duplicate(true)
  for row in shifted.paid_receipts:
   row.target.leader_ref.slot=5;row.target.respondent_ref.slot=4
   row.target.leader_ref.name="renamed person"
  _check(Callable(Workbench,"_composition_identity").call(str(song.id),shifted)==identity,"slot/name do not define canonical actor or composition")
  var changed: Dictionary=extension.duplicate(true)
  changed.fragment.lines[0].text+=" changed"
  _check(Callable(Workbench,"_composition_identity").call(str(song.id),changed).is_empty(),"invalid material safely refused")
  changed=extension.duplicate(true)
  var different_recipe: Dictionary=changed.fragment.producer_recipe.duplicate(true)
  different_recipe.stage=0
  changed.fragment.merge(Producer.material(different_recipe),true)
  var different_identity: Dictionary=Callable(Workbench,"_composition_identity").call(str(song.id),changed)
  _check(not different_identity.is_empty() and different_identity.get("revision_id")==str(identity.composition_id)+":material:"+different_identity.get("material_sha256","") and different_identity.get("revision_id")!=identity.revision_id,"valid material change has different revision")
  _check(Callable(Workbench,"_composition_identity").call("original:999",extension).song_id!=identity.song_id,"same-title other song never joins by title")
 if baseline:
  var file=FileAccess.open(work_root+"/baseline-songs.json",FileAccess.WRITE)
  file.store_string(JSON.stringify(snapshots,"",true,true));file.close()
 else:
  var old: Variant=_decode(FileAccess.get_file_as_string(work_root+"/baseline-songs.json"))
  _check(old is Array and old.size()==2,"real baseline completed song fixtures")
  if old is Array:
   for snapshot in old:
    var before: PackedByteArray=var_to_bytes(snapshot)
    _check(Workbench.finished(snapshot).items.size()==1,"genuine prechange completed song readable")
    _check(var_to_bytes(snapshot)==before,"legacy read never backfills identity")
    var file=FileAccess.open(Owner.SAVE_PATH,FileAccess.WRITE)
    file.store_string(JSON.stringify(snapshot,"",true,true));file.close()
    var restored=Owner.new()
    _check(restored.load_draft() and restored.game.career.song_catalogue==snapshot.game.career.song_catalogue,"actual owner reload preserves genuine legacy songs")
 _finish()
