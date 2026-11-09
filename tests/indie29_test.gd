extends "res://tests/recorded_steady_test.gd"

func run() -> void:
 if not check(fixture(),"canonical indie band"):finish();return
 check(Bank.HOOKS.size()==32 and Bank.INDIE29_HOOKS.size()==18,"18 new sources plus14 retained")
 var previous: Dictionary=owner.snapshot()
 for hook in Bank.INDIE29_HOOKS:
  var value: Dictionary=take(hook)
  check(Recipe.valid(value),"new recipe valid "+hook)
  var entry: Dictionary=Bank.entry(value)
  if not check(not entry.is_empty(),"registered immutable source "+hook):finish();return
  check(absf(float(entry.frames)/48000.0-960.0/float(entry.tempo))<0.00003,"clock frame agreement "+hook)
  for part in entry.parts:
   check(Bank.stream(entry.parts[part],int(entry.frames))!=null,"PCM identity "+hook+" "+str(part))
 check(owner.snapshot()==previous,"bank inspection has no saved consequence")
 for hook in ["indie29_guitar90_01","indie29_space_01","indie29_dark_01"]:
  check(fixture(),"fresh distinct family owner")
  var value: Dictionary=take(hook)
  check(owner.begin_workbench("Steady at last",0,owner.workbench_expected(),value).get("ok",false),"original draft begin")
  if not await trial(value):finish();return
  var before: Dictionary=owner.snapshot()
  var failed: Dictionary=paid(true)
  check(not failed.get("ok",false) and owner.snapshot()==before,"failed original paid seal rolls back whole owner "+hook)
  var result: Dictionary=paid()
  check(result.get("ok",false),"new family paid stage committed "+hook)
  check(not owner.game.career.get(Bank.USES,{}).get("records",[]).is_empty(),"actual person phrase ledger "+hook)
  var reloaded=Owner.new()
  check(reloaded.load_draft() and reloaded.snapshot()==owner.snapshot(),"new family exact typed reload "+hook)
 finish()

func finish() -> void:
 print("INDIE29_TEST "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false,"listening":false}))
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
