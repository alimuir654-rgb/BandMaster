extends "res://tests/song57_craft_fairness.gd"
class CountedOwner extends Owner:
 var save_calls: int=0
 var probing: bool=false
 var reentrant_refused: bool=true
 func _save_draft_owned() -> bool:
  save_calls+=1
  if probing:
   reentrant_refused=reentrant_refused and not save_draft() and not restore(snapshot()) and not call("rehearse_song",{},{},call("song_rehearsal_expected")).ok
  return super._save_draft_owned()

func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=")
 if not _check(work_root.is_absolute_path() and ProjectSettings.globalize_path(Owner.SAVE_PATH).begins_with(work_root+"/"),"isolated save path"):_finish();return
 var originals: Array=_integration(false)
 if not _check(originals.size()==2,"two genuine original completed-song fixtures"):_finish();return
 if "--baseline" in OS.get_cmdline_user_args():
  var file=FileAccess.open(work_root+"/baseline-songs.json",FileAccess.WRITE);file.store_string(JSON.stringify(originals,"",true,true));file.close()
  _legacy_rehearsal(originals[0]);_finish();return
 var Preparation=load("res://experiments/playable_flightcase/song_preparation.gd")
 for original in originals:
  _linked(original,Preparation)
 var baseline: Variant=_decode(FileAccess.get_file_as_string(work_root+"/baseline-songs.json"))
 for original in baseline:
  owner=Owner.new();_check(owner.restore(original),"genuine baseline original restored")
  _check(not owner.game.career.has(Preparation.KEY),"legacy load does not backfill rehearsal")
  var ref: Dictionary=Workbench.finished(owner.snapshot()).items[0].reference
  var identity: Dictionary=Preparation.target(owner.snapshot(),ref).identity
  _check(not Preparation.evidence(owner.game.career,identity,"cast_jack").known,"unrecorded legacy knowledge unknown")
 _finish()

func _legacy_rehearsal(original: Dictionary) -> void:
 owner=Owner.new();_check(owner.restore(original) and _available(),"original owner restore and earned availability")
 var before: Dictionary=owner.snapshot()
 var attendance: Dictionary=Situation.inspect_rehearsal(owner.game.career)
 var result: Dictionary=owner.game.rehearse_attending(attendance.attendee_indices,{"focus":"precision","effort":"steady"})
 _check(result.ok,"actual legacy rehearsal succeeds")
 if not result.ok:return
 owner.game.career=Live.after_practice(before.game.career,owner.game.career)
 var accounted: Dictionary=Finance.apply(before.game.career,owner.game.career,"practice:tighten")
 _check(accounted.ok,"legacy finance reconciliation")
 if accounted.ok:owner.game.career=accounted.state
 _check(owner.save_draft(),"legacy owner save")
 _check(owner.game.career.action_count==before.game.career.action_count+1 and owner.game.career.cash==before.game.career.cash-15,"original cost and action once")
 _check(not owner.game.career.has("song_preparation_v1"),"ordinary practice creates no invented song history")

func _linked(original: Dictionary,Preparation) -> void:
 owner=CountedOwner.new();_check(owner.restore(original) and _available(),"candidate fixture restore and earned availability")
 # Unknown full-opening extension must survive both successful and failed settlements.
 var extended: Dictionary=owner.snapshot();extended["qa_unknown"]={"fraction":2.25,"flag":false,"nested":[1,2.5]}
 _check(owner.restore(extended) and owner.save_draft(),"unknown owner wrapper fixture")
 var listing: Dictionary=Workbench.finished(owner.snapshot())
 var ref: Dictionary=listing.items[0].reference.duplicate(true)
 var target: Dictionary=Preparation.target(owner.snapshot(),ref)
 _check(target.ok,"canonical current version target")
 var direction: Dictionary={"focus":"precision","effort":"steady"}
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var expected: String=owner.call("song_rehearsal_expected")
 var initial_calls: int=owner.save_calls
 owner.probing=true
 _check(not owner.call("rehearse_song",ref,direction,"stale").ok,"stale expected refuses before spending")
 var stale: Dictionary=ref.duplicate(true);stale.fragment_sha256="wrong"
 _check(not owner.call("rehearse_song",stale,direction,expected).ok,"stale material reference refused")
 _check(not owner.call("rehearse_song",ref,{"focus":"unknown","effort":"steady"},expected).ok,"invalid intent refused")
 _check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"refusal preserves entire owner and disk")
 _check(owner.save_calls==initial_calls,"stale/invalid calls never save")
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 _check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"real filesystem blocker")
 var failed: Dictionary=owner.call("rehearse_song",ref,direction,expected)
 _check(not failed.ok and Workbench._exact(owner.snapshot(),before),"failed actual rehearsal rolls whole wrapper back")
 _check(FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"failed save disk unchanged")
 _check(owner.save_calls==initial_calls+1 and owner.reentrant_refused,"one failed save call; reentrant owner operations refused")
 _check(DirAccess.remove_absolute(blocker)==OK,"remove only QA blocker")
 var result: Dictionary=owner.call("rehearse_song",ref,direction,expected)
 _check(result.ok,"same expected retry settles once: "+str(result.get("message")))
 if not result.ok:return
 var saved: Dictionary=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 _check(saved.game.career.cash==before.game.career.cash-15 and saved.game.career.tour_day==before.game.career.tour_day+1 and saved.game.career.action_count==before.game.career.action_count+1,"linked original cash/day/action exactly once")
 _check(saved.qa_unknown==before.qa_unknown,"unknown wrapper retained")
 _check(not owner.call("rehearse_song",ref,direction,expected).ok and Workbench._exact(owner.snapshot(),saved) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"duplicate stale commit no effects")
 _check(owner.save_calls==initial_calls+2 and owner.reentrant_refused,"retry one save; duplicate zero saves; reentrancy guarded")
 var receipt: Dictionary=result.result.song_preparation_receipt
 _check(receipt.participants==result.result.outcome.attendance.attendee_ids,"receipt actual attendance canonical IDs")
 for person in saved.game.career.members:
  var evidence: Dictionary=Preparation.evidence(saved.game.career,target.identity,person.candidate_id)
  _check(evidence.known==receipt.participants.has(person.candidate_id),"absent member gains no evidence")
  if evidence.known:_check(evidence.sessions.size()==1,"one actual session only")
 var restored=Owner.new();_check(restored.load_draft() and Workbench._exact(restored.snapshot(),saved),"real typed owner reload exact")
 # Compare linked outcome to unchanged original owner, same state/people/direction.
 var plain=Owner.new();_check(plain.restore(before),"matched ordinary owner restore")
 var attendance: Dictionary=Situation.inspect_rehearsal(plain.game.career)
 var ordinary: Dictionary=plain.game.rehearse_attending(attendance.attendee_indices,direction)
 _check(ordinary.ok,"matched original rehearsal")
 plain.game.career=Live.after_practice(before.game.career,plain.game.career)
 var accounted: Dictionary=Finance.apply(before.game.career,plain.game.career,"practice:tighten")
 _check(accounted.ok,"matched original finance")
 if accounted.ok:plain.game.career=accounted.state
 var actual: Dictionary=saved.game.career.duplicate(true);actual.erase(Preparation.KEY)
 _check(Workbench._exact(actual,plain.game.career),"all original rehearsal effects byte/type exact, only optional evidence added")
 # Explicit negative identity fixtures, never claimed earned songs or revisions.
 var other: Dictionary=target.identity.duplicate(true);other.song_id="original:999"
 _check(not Preparation.evidence(saved.game.career,other,"cast_jack").known,"another song same display name cannot inherit")
 other=target.identity.duplicate(true);other.revision_id+="changed"
 _check(not Preparation.evidence(saved.game.career,other,"cast_jack").known,"untracked changed revision not falsely fully prepared")
 _check(Preparation.evidence(saved.game.career,target.identity,receipt.participants[0]).known,"return exact old version retains actual record")
 _check(not Preparation.evidence(saved.game.career,target.identity,"replacement:bass").known,"replacement candidate cannot inherit slot evidence")
 var duplicate: Dictionary=saved.duplicate(true);duplicate.game.career.song_catalogue.append(duplicate.game.career.song_catalogue[0].duplicate(true))
 _check(not Preparation.target(duplicate,ref).ok,"duplicate canonical song ID refuses ambiguous selection")
 var malformed: Dictionary=saved.game.career[Preparation.KEY].duplicate(true);malformed.receipts[0].participants.append(malformed.receipts[0].participants[0])
 _check(not Preparation.valid(malformed),"duplicate participant receipt invalid")
 malformed=saved.game.career[Preparation.KEY].duplicate(true);malformed.receipts.append(malformed.receipts[0].duplicate(true))
 _check(not Preparation.valid(malformed),"duplicate action receipt invalid")
 # Actual Monday full session followed by Tuesday partial attendance. No date edits.
 owner=restored
 var first_count: int=owner.game.career[Preparation.KEY].receipts.size()
 var monday: Dictionary=owner.call("rehearse_song",ref,{"focus":"listening","effort":"push"},owner.call("song_rehearsal_expected"))
 _check(monday.ok,"next earned day rehearsal original alternate direction")
 var prior: Dictionary=owner.snapshot()
 var actual_attendance: Dictionary=Situation.inspect_rehearsal(prior.game.career)
 _check(actual_attendance.attendee_indices.size()==2,"genuine Tuesday partial attendance fixture")
 var subset: Dictionary=owner.call("rehearse_song",ref,direction,owner.call("song_rehearsal_expected"))
 _check(subset.ok,"actual partial rehearsal settles")
 if subset.ok:
  var row: Dictionary=subset.result.song_preparation_receipt
  _check(row.participants.size()==2 and not row.participants.has("cast_jack"),"absent Jack has no new preparation record")
  _check(Preparation.evidence(owner.game.career,target.identity,"cast_jack").sessions.size()==first_count+1,"absent member retains earlier knowledge without new session")
  _check(Preparation.evidence(owner.game.career,target.identity,"cast_zoe").sessions.size()==first_count+2,"present member records actual additional session")
 # Saved malformed optional ledger rejects structurally. Also execute selected malformed-owner refusals.
 var healthy: Dictionary=owner.snapshot()
 for key in ["direction","song_id","composition_id","revision_id","completed_day","attendance_id"]:
  for value in [null,42,"bad",[],{}]:
   var bad: Dictionary=healthy.duplicate(true);bad.game.career[Preparation.KEY].receipts[0][key]=value
   _check(not Preparation.valid(bad.game.career[Preparation.KEY]),"malformed ledger rejects "+key+"/"+str(typeof(value)))
 # Cosmetic rename does not change the canonical version or erase knowledge.
 var renamed: Dictionary=healthy.duplicate(true);renamed.game.career.song_catalogue[0].title="A DIFFERENT NAME"
 var rename_ref: Dictionary=Workbench.finished(renamed).items[0].reference
 _check(Preparation.target(renamed,rename_ref).identity==target.identity,"cosmetic rename preserves version identity")
 _check(Preparation.evidence(renamed.game.career,target.identity,"cast_jack").known,"rename keeps existing preparation")
 # A second actual distinctly titled original; duplicate titles are forbidden by original Workshop.
 _check(owner.restore(healthy) and _available(),"genuine second song start availability")
 var recipe: Dictionary=Producer.recipe(0)
 var title: String="A DIFFERENT ACTUAL SONG"
 if not _check(owner.begin_workbench(title,0,owner.workbench_expected(),recipe).ok,"second distinct-title original begins"):return
 for stage in range(3):
  _check(_available(),"second song actual writing availability")
  recipe.stage=stage
  _check(owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":recipe,"title":title,"leader_index":0}).ok,"second song actual recipe")
  var project: Dictionary=owner.workbench_view().project
  var offer: Dictionary=Producer.offer(project.fragment.producer_recipe,project.target.respondent_ref)
  _check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"keep","offer_id":offer.offer_id}).ok,"second song considered response")
  _check(_paid().ok,"second song original paid stage")
 var second: Dictionary=Workbench.finished(owner.snapshot()).items[-1].reference
 var second_target: Dictionary=Preparation.target(owner.snapshot(),second)
 _check(second_target.ok and second_target.identity.song_id!=target.identity.song_id,"actual originals have distinct canonical IDs")
 _check(not Preparation.evidence(owner.game.career,second_target.identity,"cast_zoe").known,"genuine second song has no invented preparation")
 var collision: Dictionary=owner.snapshot();collision.game.career.song_catalogue[-1].title=collision.game.career.song_catalogue[0].title
 var colliding_ref: Dictionary=Workbench.finished(collision).items[-1].reference
 _check(Preparation.target(collision,colliding_ref).identity==second_target.identity,"explicit synthetic same-title collision remains second canonical song")
 _check(not Preparation.evidence(collision.game.career,second_target.identity,"cast_zoe").known,"same displayed title never grants other song history")
 # Explicit malformed optional ledger through real owner, not only leaf validation.
 var good: Dictionary=owner.snapshot()
 for bad_value in [42,{"policy":"unsupported_future","receipts":[]}]:
  var bad: Dictionary=good.duplicate(true);bad.game.career[Preparation.KEY]=bad_value
  var guarded=CountedOwner.new();_check(guarded.restore(bad),"unknown optional schema preserved on load")
  var raw: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
  var selected: Dictionary=Workbench.finished(guarded.snapshot()).items[0].reference
  _check(not guarded.call("rehearse_song",selected,direction,guarded.call("song_rehearsal_expected")).ok,"unsupported preparation owner refuses")
  _check(Workbench._exact(guarded.snapshot(),bad) and guarded.save_calls==0 and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==raw,"unsupported data preserved; no action or save")
