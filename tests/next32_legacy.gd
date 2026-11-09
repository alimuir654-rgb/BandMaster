extends SceneTree
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Encounter=preload("res://experiments/playable_flightcase/audition_encounter.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok:failures.append(label);push_error(label)
 return ok
func _init() -> void:call_deferred("run")
func run() -> void:
 var list_path: String=""
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--fixtures="):list_path=arg.trim_prefix("--fixtures=")
 if not check(FileAccess.file_exists(list_path),"explicit immutable V22 fixture list"):done();return
 var paths: Variant=JSON.parse_string(FileAccess.get_file_as_string(list_path))
 if not check(paths is Array and not paths.is_empty(),"bounded V22 fixtures"):done();return
 for path in paths:
  var owner=Owner.new()
  var bytes: PackedByteArray=FileAccess.get_file_as_bytes(path)
  var raw: Variant=JSON.parse_string(bytes.get_string_from_utf8())
  if not check(raw is Dictionary and not raw.game.has("talent_policy"),"actual V22 absence "+path):continue
  raw=owner.game._restore_integral_numbers(raw)
  if not check(owner.restore(raw),"actual V22 accepted "+path):continue
  check(not owner.snapshot().game.has("talent_policy") and owner.game.spent()==Owner.Base.spent(owner.game.roster),"actual V22 legacy quotes retained")
  check(not Encounter.validate(owner.snapshot()).held and Journey.validate(owner.game.career).ok,"old audition/gig guards unchanged")
  var before: Dictionary=owner.snapshot()
  check(owner.save_draft(),"save only isolated copy of V22 fixture")
  var copy=Owner.new()
  check(copy.load_draft() and copy.snapshot()==before,"actual V22 whole strict re-save/reload")
  check(FileAccess.get_file_as_bytes(path)==bytes,"immutable original V22 fixture unchanged")
 done()
func done() -> void:
 print("NEXT32_LEGACY "+JSON.stringify({"checks":checks,"failures":failures,"fixture_origin":"isolated V22 QA saves, not owner production save","physical_device":false}))
 quit(0 if failures.is_empty() else 1)
