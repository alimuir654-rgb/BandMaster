extends SceneTree
## Metamorphic skill proof and genuine old-source receipts; isolated fixture IO only.
const Producer = preload("res://experiments/playable_flightcase/producer_recipe.gd")
const Mixing = preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Workbench = preload("res://experiments/playable_flightcase/song_workbench.gd")
const Owner = preload("res://experiments/playable_flightcase/opening_state.gd")
const Situation = preload("res://experiments/playable_flightcase/situation_core.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
var checks := 0
var failure_count := 0
var monotonic_failures := 0
var legacy_checked := 0
var failures: Array[String] = []
var work_root := ""
var owner
var last_transaction := ""
var owner_transactions := 0

func _initialize() -> void:
 var args: PackedStringArray=OS.get_cmdline_user_args()
 for arg in args:
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=").simplify_path()
 if not _check(work_root.is_absolute_path(),"explicit isolated work root required"):_finish();return
 if not _check(ProjectSettings.globalize_path(Owner.SAVE_PATH).simplify_path().begins_with(work_root+"/"),"owner save path must be isolated"):_finish();return
 for arg in args:
  if arg.begins_with("--export-legacy="):
   _export_legacy(arg.trim_prefix("--export-legacy="));_finish();return
 _fairness()
 if "--fairness-only" not in args:
  var legacy_path := ""
  for arg in args:
   if arg.begins_with("--legacy="):legacy_path=arg.trim_prefix("--legacy=")
  _legacy(legacy_path)
  _new_receipts()
  _invalid_inputs()
  _integration(false)
 _finish()

func _check(ok: bool,message: String) -> bool:
 checks+=1
 if not ok:
  failure_count+=1
  if failures.size()<24:failures.append(message)
 return ok

func _finish() -> void:
 print("SONG57_RESULT "+JSON.stringify({"ok":failure_count==0,"checks":checks,"failure_count":failure_count,"monotonic_failures":monotonic_failures,"legacy_receipts_checked":legacy_checked,"owner_transactions":owner_transactions,"failures":failures}))
 quit(0 if failure_count==0 else 1)

func _state(skill: int,count: int=3) -> Dictionary:
 var people: Array=[]
 for i in range(count):people.append({"skill":skill,"life_status":"active","candidate_id":"qa:%d" % i})
 return {"members":people,"unknown":{"preserve":[2.25,false]}}

func _recipes() -> Array:
 var recipes: Array=[]
 for i in range(16):recipes.append(Producer.recipe(i))
 var base: Dictionary=Mixing.recipe({"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"},2)
 for tone in Mixing.VALUES[0]:
  for pace in Mixing.VALUES[1]:
   for energy in Mixing.VALUES[2]:
    for complexity in Mixing.VALUES[3]:
     for groove in Mixing.VALUES[4]:
      for shape in Mixing.VALUES[5]:
       for theme in Mixing.VALUES[6]:
        var value: Dictionary=base.duplicate(true)
        value.merge({"tone":tone,"pace":pace,"energy":energy,"originality":complexity,"groove":groove,"shape":shape,"theme":theme},true)
        recipes.append(value)
 return recipes

func _fairness() -> void:
 for value in _recipes():
  var previous := -100
  for skill in range(101):
   var state: Dictionary=_state(skill)
   var before: PackedByteArray=var_to_bytes([state,value])
   var result: Dictionary=Producer.craft(state,value)
   if not _check(result.get("ok",false),"valid recipe/skill accepted"):continue
   _check(var_to_bytes([state,value])==before,"craft must not mutate supplied state or recipe")
   if not _check(int(result.delta)>=previous,"greater skill lowered craft: "+str(skill)+" / "+Producer.summary(value)):
    monotonic_failures+=1
   previous=int(result.delta)
 # A skilled band must be allowed to play the same restrained part deliberately.
 var simple: Dictionary=Producer.recipe(0)
 var novice: Dictionary=Producer.craft(_state(0),simple)
 var expert: Dictionary=Producer.craft(_state(100),simple)
 _check(expert.delta>=novice.delta,"spare capability cannot make the same simple part worse")

func _receipt(value: Dictionary,craft: Dictionary,base: int=70) -> Dictionary:
 return {"model":craft.model,"recipe_sha256":Workbench._hash(value),"song_id":"original:7","base_quality":base,"delta":craft.delta,"final_quality":clampi(base+int(craft.delta),1,100),"context":{"active_skill_sum":craft.active_skill_sum,"active_count":craft.active_count,"capacity":craft.capacity,"demand":craft.demand},"reason":craft.reason}

func _extension(value: Dictionary,receipt: Dictionary) -> Dictionary:
 return {"fragment":{"producer_recipe":value.duplicate(true)},"producer_quality_receipt":receipt.duplicate(true)}

func _safe_path(value: String) -> bool:
 return value.is_absolute_path() and value.simplify_path().begins_with(work_root+"/") and not work_root.is_empty()

func _decode(text: String) -> Variant:
 # The real owner loader restores whole JSON numbers before validation.
 # Bypassing it changes GDScript Array membership for stage/version fields.
 var codec=Owner.new()
 return codec.game._restore_integral_numbers(JSON.parse_string(text))

func _export_legacy(path: String) -> void:
 if not _check(_safe_path(path),"legacy export must stay in isolated proof"):return
 var records: Array=[]
 for value in _recipes():
  for skill in [0,34,35,54,55,74,75,100]:
   var craft: Dictionary=Producer.craft(_state(skill),value)
   if not _check(craft.get("model") in ["producer_raw_craft_v2","mixing_craft_v1"],"fixtures must be created by actual old models"):return
   var receipt: Dictionary=_receipt(value,craft)
   _check(Workbench._producer_receipt_ok(_extension(value,receipt)),"old source accepts own receipt")
   records.append({"recipe":value,"receipt":receipt})
 var file:=FileAccess.open(path,FileAccess.WRITE)
 if not _check(file!=null,"isolated legacy fixture opens"):return
 file.store_string(JSON.stringify({"receipts":records,"snapshots":_integration(true)}));file.close()

func _legacy(path: String) -> void:
 if not _check(_safe_path(path),"legacy read must stay in isolated proof"):return
 var parsed: Variant=_decode(FileAccess.get_file_as_string(path))
 if not _check(parsed is Dictionary and parsed.get("receipts") is Array and parsed.receipts.size()==3584,"complete old-source recipe/threshold fixture set"):return
 var raw_before: PackedByteArray=var_to_bytes(parsed)
 for entry in parsed.receipts:
  if not _check(entry is Dictionary and entry.get("recipe") is Dictionary and entry.get("receipt") is Dictionary,"legacy record shape"):continue
  var extension: Dictionary=_extension(entry.recipe,entry.receipt)
  var before: PackedByteArray=var_to_bytes(extension)
  _check(Workbench._producer_receipt_ok(extension),"genuine old receipt remains valid after JSON reload")
  _check(var_to_bytes(extension)==before,"validation preserves historical quality and recipe data")
  legacy_checked+=1
 _check(var_to_bytes(parsed)==raw_before,"legacy fixtures unchanged byte-for-byte")
 if not _check(parsed.get("snapshots") is Array and parsed.snapshots.size()==2,"two genuine historical finished songs"):return
 for snapshot in parsed.snapshots:
  var finished: Dictionary=Workbench.finished(snapshot)
  if not _check(finished.ok and finished.items.size()==1,"full old song remains available as a finished sketch"):continue
  _check(Workbench.read_finished(snapshot,finished.items[0].reference).ok,"full old sketch can be read")
  var saved=FileAccess.open(Owner.SAVE_PATH,FileAccess.WRITE)
  if not _check(saved!=null,"isolated legacy owner save opens"):continue
  saved.store_string(JSON.stringify(snapshot));saved.close()
  var restored=Owner.new()
  _check(restored.load_draft(),"real owner reload accepts full historical song")
  _check(restored.game.career.song_catalogue==snapshot.game.career.song_catalogue,"real reload preserves original historical songs and scores")

func _new_receipts() -> void:
 for value in _recipes():
  for count in [1,2,6]:
   var craft: Dictionary=Producer.craft(_state(100,count),value)
   var expected: String="mixing_craft_v2" if Mixing.valid(value) else "producer_raw_craft_v3"
   _check(craft.get("model")==expected,"new results use a new model identity")
   for base in [0,70,100]:
    var receipt: Dictionary=_receipt(value,craft,base)
    var extension: Dictionary=_extension(value,receipt)
    _check(Workbench._producer_receipt_ok(extension),"new sealed receipt accepted")
    _check(Workbench._producer_receipt_ok(_decode(JSON.stringify(extension))),"new receipt actual-codec reload accepted")
    for key in ["model","delta","final_quality","recipe_sha256","reason"]:
     var bad: Dictionary=extension.duplicate(true)
     match key:
      "model":bad.producer_quality_receipt.model="unrecognised_future_model"
      "delta":bad.producer_quality_receipt.delta=int(receipt.delta)+1
      "final_quality":bad.producer_quality_receipt.final_quality=int(receipt.final_quality)-1
      "recipe_sha256":bad.producer_quality_receipt.recipe_sha256="changed"
      "reason":bad.producer_quality_receipt.reason="invented"
     _check(not Workbench._producer_receipt_ok(bad),"forged receipt rejected: "+key)
    var incompatible: Dictionary=extension.duplicate(true)
    incompatible.producer_quality_receipt.model="mixing_craft_v1" if Mixing.valid(value) else "producer_raw_craft_v2"
    if int(craft.capacity)>int(craft.demand) and int(craft.delta)>-3:
     _check(not Workbench._producer_receipt_ok(incompatible),"new benefit cannot be smuggled into an old model receipt")

func _invalid_inputs() -> void:
 _check(_decode('{"fraction":2.25,"whole":2.0,"extra":{"flag":false}}')=={"fraction":2.25,"whole":2,"extra":{"flag":false}},"actual loader codec preserves fractions and unknown fields")
 for value in [Producer.recipe(0),Mixing.recipe({"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"})]:
  for skill in [null,true,"50",50.5,-1,101,NAN,INF]:
   _check(not Producer.craft({"members":[{"skill":skill}]},value).get("ok",false),"invalid skill rejected")
  _check(not Producer.craft({"members":[]},value).get("ok",false),"empty performers rejected")
  _check(not Producer.craft({"members":[{"skill":70,"life_status":"away"}]},value).get("ok",false),"absent performers do not grant capability")
  var one: Dictionary=_state(50,1)
  var away: Dictionary=one.duplicate(true)
  away.members.append({"skill":100,"life_status":"away"})
  _check(Producer.craft(one,value)==Producer.craft(away,value),"absent expert changes nothing")

func _fixture() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not owner.recruit(id):return false
 return owner.choose_vocal("cast_jack") and owner.confirm_lineup() and owner.start_naming() and owner.submit_name("QA FAIRNESS BAND","Raw") and owner.lock_name() and owner.start_identity() and owner.set_identity("Wordmark","Amber / Charcoal","Unpolished") and owner.finish_identity() and owner.start_playing()

func _available() -> bool:
 for _day in range(15):
  if Situation.inspect_writing(owner.game.career).get("can_write",false):return true
  var before: Dictionary=owner.game.career.duplicate(true)
  var attendance: Dictionary=Situation.inspect_rehearsal(before)
  if not attendance.ok:return false
  if not owner.game.informal_practice(attendance.attendee_indices).ok:return false
  var tracked: Dictionary=Situation.after_action(before,owner.game.career)
  if not tracked.ok:return false
  owner.game.career=Live.after_practice(before,tracked.state)
  var accounted: Dictionary=Finance.apply(before,owner.game.career,"practice:jam")
  if not accounted.ok:return false
  owner.game.career=accounted.state
  if not owner.save_draft():return false
 return false

func _paid(fail_save: bool=false) -> Dictionary:
 var ticket: Dictionary=owner.begin_workbench_commit(owner.workbench_expected())
 if not _check(ticket.ok,"real paid ticket: "+str(ticket.get("message",""))):return {"ok":false}
 last_transaction=str(ticket.transaction_id)
 var p: Dictionary=ticket.prepared
 var result: Dictionary=owner.game.write_session_prepared(p.args.idea,p.args.form,p.args.title,p.args.leader_index,p)
 if not _check(result.ok,"real original writing") or not _check(owner.complete_workbench_original(ticket.transaction_id,result).ok,"reconcile real original writing"):return {"ok":false}
 var tracked: Dictionary=Situation.after_action(ticket.before_game.career,owner.game.career)
 if not _check(tracked.ok,"existing situation accounting"):return {"ok":false}
 owner.game.career=Live.after_practice(ticket.before_game.career,tracked.state)
 var accounted: Dictionary=Finance.apply(ticket.before_game.career,owner.game.career,"practice:create")
 if not _check(accounted.ok,"existing finance accounting"):return {"ok":false}
 owner.game.career=accounted.state
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 if fail_save and not _check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject actual save failure"):return {"ok":false}
 var finished: Dictionary=owner.finish_workbench_commit(ticket.transaction_id)
 if fail_save:_check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated save blocker")
 if finished.ok:owner_transactions+=1
 return finished

func _integration(legacy: bool) -> Array:
 var snapshots: Array=[]
 for is_mixing in [false,true]:
  if not _check(_fixture(),"public formation fixture"):return snapshots
  var title: String="Simple by choice" if is_mixing else "Space in the riff"
  var recipe: Dictionary=Mixing.recipe({"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"}) if is_mixing else Producer.recipe(0)
  if not _check(_available(),"first genuinely available evening") or not _check(owner.begin_workbench(title,0,owner.workbench_expected(),recipe).ok,"begin through real owner"):return snapshots
  for stage in range(3):
   if not _check(_available(),"respect actual availability"):return snapshots
   recipe.stage=stage
   var trial: Dictionary=owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":recipe,"title":title,"leader_index":0})
   if not _check(trial.ok,"try exact current recipe"):return snapshots
   var project: Dictionary=owner.workbench_view().project
   var offer: Dictionary=Producer.offer(project.fragment.producer_recipe,project.target.respondent_ref)
   if not _check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"keep","offer_id":offer.offer_id}).ok,"retain original considered response"):return snapshots
   if stage==2 and not legacy:
    var before: Dictionary=owner.snapshot()
    var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
    _check(not _paid(true).ok,"actual final save failure reported")
    _check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"failed final save restores full owner and disk")
   if not _check(_paid().ok,"real paid stage commits once"):return snapshots
   var committed: Dictionary=owner.snapshot()
   var committed_disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
   _check(not owner.finish_workbench_commit(last_transaction).ok,"duplicate paid settlement rejected")
   _check(owner.snapshot()==committed and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==committed_disk,"duplicate settlement spends and saves nothing")
  var finished: Dictionary=Workbench.finished(owner.snapshot())
  if not _check(finished.ok and finished.items.size()==1,"full finished-song validation accepts new receipt"):return snapshots
  _check(Workbench.read_finished(owner.snapshot(),finished.items[0].reference).ok,"actual completed sketch readable")
  var song: Dictionary=owner.game.career.song_catalogue[-1]
  var saved: Dictionary=song[Workbench.FRAGMENT_KEY].producer_quality_receipt
  var expected: String=("mixing_craft_v1" if legacy else "mixing_craft_v2") if is_mixing else ("producer_raw_craft_v2" if legacy else "producer_raw_craft_v3")
  _check(saved.model==expected and song.quality==saved.final_quality,"actual sealing uses correct version and quality")
  var reloaded=Owner.new()
  _check(reloaded.load_draft() and reloaded.snapshot()==owner.snapshot(),"actual current owner reload retains complete finished sketch")
  snapshots.append(owner.snapshot())
 return snapshots
