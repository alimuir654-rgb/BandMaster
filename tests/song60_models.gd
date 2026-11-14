extends "res://tests/song59_cowriting.gd"
func _selection_guards() -> void:
 super._selection_guards()
 if not _begin():return
 var before: Dictionary=owner.snapshot()
 var recipe: Dictionary=owner.workbench_view().project.fragment.producer_recipe.duplicate(true)
 var payload: Dictionary={"recipe":recipe,"title":"SWAPPED — ÉCHO","leader_index":1,"collaborator_id":"cast_jack","decision":{}}
 _check(owner.save_mixing_sketch(owner.workbench_expected(),payload).ok,"pending lead Zoe and formerlead partner Jack save together")
 var target: Dictionary=owner.workbench_view().project.target
 _check(target.leader_ref.candidate_id=="cast_zoe" and target.respondent_ref.candidate_id=="cast_jack","atomic swapped canonical people")
 var a: Dictionary=before.game.duplicate(true);a.career.erase(Workbench.KEY)
 var b: Dictionary=owner.snapshot().game.duplicate(true);b.career.erase(Workbench.KEY)
 _check(Workbench._exact(a,b),"empty-response free save alters only optional wrapper")
 var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var desired: Dictionary=Workbench._target(owner.game.career,"SWAPPED — ÉCHO",0,"cast_zoe").target
 var offer: Dictionary=Producer.offer(recipe,desired.respondent_ref)
 var chosen: Dictionary=recipe.duplicate(true);chosen[offer.field]=offer.value
 payload={"recipe":chosen,"title":"SWAPPED — ÉCHO","leader_index":0,"collaborator_id":"cast_zoe","decision":{"choice":"try","base_recipe":recipe,"offer_id":offer.offer_id}}
 var raw: PackedByteArray=var_to_bytes(payload)
 var ticket: Dictionary=owner.begin_workbench_commit(owner.workbench_expected(),payload)
 _check(ticket.ok,"pending swap reverse prepares atomically through existing owner")
 if ticket.ok:_check(owner.abort_workbench_commit(ticket.transaction_id,"QA cancellation").get("ok",true)==false,"original abort retains cancellation semantics")
 _check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"cancel pending swap restores full owner/disk")
 _check(var_to_bytes(payload)==raw,"preparation never mutates caller local payload")
 payload.collaborator_id="cast_jack"
 _check(not owner.begin_workbench_commit(owner.workbench_expected(),payload).ok,"new self-partner invalid no silent substitution")
 _check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"invalid local pair no save")
 # Four-field legacy payload remains valid with its saved selected target.
 payload={"recipe":recipe,"title":"SWAPPED — ÉCHO","leader_index":1,"decision":{}}
 _check(owner.save_mixing_sketch(owner.workbench_expected(),payload).ok,"old four-field mixing payload remains compatible")
