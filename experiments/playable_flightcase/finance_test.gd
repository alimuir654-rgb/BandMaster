extends SceneTree
## Independent numeric contracts. Root alone runs in fresh isolated S47 XDG.
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Opening = preload("res://experiments/playable_flightcase/opening_state.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const SAFE := "/workspace/work/business/s47/"
var checks:=0
var failures: Array[String]=[]
var protected_initial: Dictionary={}

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> bool:
 checks+=1
 if not ok: failures.append(message);push_error("S47_FINANCE_TEST "+message)
 return ok
func pure(before: Dictionary, after: Dictionary, action: String, flows: Array=[], closes: Array=[]) -> Dictionary:
 var a:=before.duplicate(true)
 var b:=after.duplicate(true)
 var rows:=flows.duplicate(true)
 var days:=closes.duplicate(true)
 var result: Dictionary=Finance.apply(before,after,action,flows,closes)
 check(before==a and after==b and flows==rows and closes==days,"apply never mutates any caller input: "+action)
 return result
func rejected(before: Dictionary, after: Dictionary, flows: Array=[], closes: Array=[]) -> void:
 var result:=pure(before,after,"invalid",flows,closes)
 check(not bool(result.get("ok",false)) and result.get("state",{})==before,"invalid finance result rejects with exact original state")
func protected_files() -> Dictionary:
 var result: Dictionary={}
 for path in ["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  result[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return result
func data(state: Dictionary) -> Dictionary: return state.get("finance_v1",{})
func amount(state: Dictionary, direction: String, category: String) -> int: return int(data(state).get("totals",{}).get(direction,{}).get(category,0))

func boundaries() -> void:
 var legacy: Dictionary={"cash":0,"tour_day":100,"unknown":{"keep":[7,8]}}
 var untouched:=legacy.duplicate(true)
 var view: Dictionary=Finance.view(legacy)
 check(legacy==untouched and not legacy.has("finance_v1"),"read-only view never migrates or saves caller")
 check(int(view.opening_day)==100 and int(view.opening_balance)==0 and int(view.broke_days)==0 and view.history.is_empty() and not Finance.is_over(legacy),"legacy zero-cash day100 gets no invented historic streak/income")
 var state: Dictionary={"cash":0,"tour_day":1,"unknown":{"keep":[7,8]}}
 for index in range(13):
  var after:=state.duplicate(true);after.tour_day=int(state.tour_day)+1
  var result:=pure(state,after,"clear_air")
  if not check(bool(result.get("ok",false)),"zero-cash elapsed day is a valid recorded action"): return
  state=result.state
  check(int(data(state).broke_days)==index+1 and not Finance.is_over(state),"each actual elapsed day1..13 counts once; still playable")
 check(int(state.tour_day)==14 and int(data(state).broke_days)==13,"thirteen completed days end at careerday14")
 var no_day:=pure(state,state,"assign")
 check(bool(no_day.ok) and int(data(no_day.state).broke_days)==13 and not Finance.is_over(no_day.state),"zero-day zero-cash action never ages streak")
 var rescued:=state.duplicate(true);rescued.cash=1
 var rescue_now:=pure(state,rescued,"reward")
 check(bool(rescue_now.ok) and int(data(rescue_now.state).broke_days)==0 and amount(rescue_now.state,"income","Other")==1,"positive SAME-DAY receipt breaks consecutive zero run")
 rescued.tour_day=int(state.tour_day)+1
 var rescue_close:=pure(state,rescued,"gig")
 check(bool(rescue_close.ok) and int(data(rescue_close.state).broke_days)==0 and not Finance.is_over(rescue_close.state),"positive cash on fourteenth closing day rescues before zero-day audit")
 var after14:=state.duplicate(true);after14.tour_day=int(state.tour_day)+1
 var terminal:=pure(state,after14,"clear_air")
 check(bool(terminal.ok) and int(data(terminal.state).broke_days)==14 and Finance.is_over(terminal.state) and int(data(terminal.state).ended_day)==15,"EXACT fourteenth completed zero day ends once on day15")
 check(not bool(Finance.guard(terminal.state).get("ok",true)),"terminal guard rejects further gameplay")
 var later:=terminal.state.duplicate(true);later.cash=20;later.tour_day=16
 rejected(terminal.state,later)
 var replay:=pure(state,terminal.state,"clear_air")
 check(bool(replay.ok) and replay.state==terminal.state,"replaying already-accounted result never adds ledger, zero day or terminal event")
 var second: Dictionary={"cash":0,"tour_day":1}
 for index in range(40):
  var free:=pure(second,second,"assign")
  if not bool(free.get("ok",false)): check(false,"free same-day action remains legal");return
  second=free.state
 check(int(data(second).broke_days)==0 and int(second.tour_day)==1,"forty no-day commits cannot become forty broke days")
 var multi: Dictionary={"cash":0,"tour_day":1}
 var multi_after:=multi.duplicate(true);multi_after.tour_day=4
 rejected(multi,multi_after)
 var closes:=pure(multi,multi_after,"three_days",[],[0,0,0])
 check(bool(closes.ok) and int(data(closes.state).broke_days)==3,"explicit three-day schedule counts THREE days, not one click")
 var too_late:=state.duplicate(true);too_late.tour_day=16;too_late.cash=10
 rejected(state,too_late,[{"direction":"income","category":"Other","amount":10}],[0,10])
 var in_time:=pure(state,too_late,"rescue_first",[{"direction":"income","category":"Other","amount":10}],[10,10])
 check(bool(in_time.ok) and not Finance.is_over(in_time.state) and int(data(in_time.state).broke_days)==0,"cash before lethal closing prevents later zero-day loss")

func ledger_and_invalid() -> void:
 var state: Dictionary={"cash":1000,"tour_day":1,"unknown":{"keep":[7,8]}}
 for index in range(85):
  var after:=state.duplicate(true);after.cash=int(state.cash)-1;after.tour_day=int(state.tour_day)+1
  var result:=pure(state,after,"gear:service")
  if not check(bool(result.get("ok",false)),"independent £1/day accounting fixture succeeds"): return
  state=result.state
 check(int(state.cash)==915 and int(data(state).opening_balance)==1000 and amount(state,"outgoing","Equipment")==85 and amount(state,"income","Other")==0,"all-time independent total1000−85=915 reconciles")
 check(data(state).history.size()==80 and int(data(state).seq)==85,"history cap80 never truncates all-time85 transactions/totals")
 check(state.unknown=={"keep":[7,8]},"original unknown nested career fields survive finance")
 var view:=Finance.view(state);view.history.clear()
 check(data(state).history.size()==80,"view exposes a deep copy, never caller aliases")
 var before: Dictionary={"cash":10,"tour_day":5}
 rejected(before,{"cash":-1,"tour_day":6})
 rejected({"cash":-1,"tour_day":5},before)
 rejected(before,{"cash":9.5,"tour_day":6})
 rejected(before,{"cash":10,"tour_day":4})
 rejected(before,{"cash":10,"tour_day":5.5})
 rejected(before,{"cash":9,"tour_day":6},[{"direction":"income","category":"Other","amount":1}])
 rejected(before,{"cash":9,"tour_day":6},[{"direction":"outgoing","category":"Imaginary","amount":1}])
 rejected(before,{"cash":9,"tour_day":6},[{"direction":"outgoing","category":"Other","amount":-1}])
 rejected(before,{"cash":9,"tour_day":6},[{"direction":"outgoing","category":"Other","amount":1.5}])
 rejected(before,{"cash":9,"tour_day":6},["not a cashflow"])
 rejected(before,{"cash":10,"tour_day":7},[],[0])
 rejected(before,{"cash":10,"tour_day":7},[],[10,-1])
 rejected(before,{"cash":10,"tour_day":7},[],[10,0])
 var checkpoint:=state.duplicate(true);checkpoint.finance_v1.closing_balance=1
 rejected(checkpoint,checkpoint)
 var malformed:=before.duplicate(true);malformed["finance_v1"]={"version":999}
 rejected(malformed,malformed)
 var corrupt:=state.duplicate(true);corrupt.finance_v1.broke_days=-1
 rejected(corrupt,corrupt)
 var split:=pure({"cash":100,"tour_day":1},{"cash":107,"tour_day":2},"sale",[{"direction":"income","category":"Music sales","amount":12},{"direction":"outgoing","category":"Other","amount":5}])
 check(bool(split.ok) and amount(split.state,"income","Music sales")==12 and amount(split.state,"outgoing","Other")==5,"gross12income/5outgoing is retained despite net7; opening100 is not income")

func original_gig_cashflow() -> void:
 for start_cash in [0,2]:
  var before: Dictionary={"cash":start_cash,"tour_day":7,"readiness":100,"morale":100,"tension":0,"songs":3,"fans":0,"reputation":0,"members":[{"role":"Drummer","life_status":"active"},{"role":"Guitarist","life_status":"active"}],"booked_show":{"venue_id":"local","venue":"The Lantern Room","city":"HOMETOWN","day":7,"approach":"tight","session_drummer":false,"travel_plan":"drive_home"},"gig_night_phase":"stage","promoter_offer":{"venue_id":"local","offer_id":"standard"}}
  var actual: Dictionary=Live.resolve(before,"perform")
  if not check(bool(actual.get("ok",false)),"protected original live resolver produces genuine local settlement"): return
  check(int(actual.state.cash)==35 and int(actual.state.gig_history.back().fee)==35 and int(actual.state.gig_history.back().travel_cost)==5,"actual full local fee35; nominal history travel tariff5 even when cash0/2")
  var result:=pure(before,actual.state,"live:perform")
  check(bool(result.ok) and amount(result.state,"income","Gig fees")==35 and amount(result.state,"outgoing","Travel")==start_cash,"ledger uses actual local travel0/2, NEVER nominal5, and grossfee35")
  check(int(data(result.state).opening_balance)+35-start_cash==35,"original gig gross entries reconcile exactly to actual closing35")

func save_roundtrip() -> void:
 var model:=Opening.new()
 check(model.begin_new() and model.set_genre("Indie rock") and model.to_recruit(),"real C27 formation starts")
 for id in ["cast_jack","cast_zoe","cast_casey"]: check(bool(model.recruit(id).get("ok",false)),"real canonical candidate recruited")
 check(bool(model.choose_vocal("cast_jack").get("ok",false)) and bool(model.confirm_lineup().get("ok",false)),"real canonical lead and lineup")
 check(model.start_naming() and bool(model.submit_name("QA FINANCE BAND","Raw").get("ok",false)) and bool(model.lock_name().get("ok",false)) and model.start_identity() and model.set_identity("Wordmark","Amber / Charcoal","Unpolished") and bool(model.finish_identity().get("ok",false)) and model.start_playing(),"real identity finishes before isolated finance save")
 var before: Dictionary=model.game.career.duplicate(true)
 var after:=before.duplicate(true);after.cash=245;after.tour_day=2;after["unknown_finance_sentinel"]={"keep":[3,4]}
 var applied:=pure(before,after,"test_cost")
 if not check(bool(applied.get("ok",false)),"valid additive accounting result for real C27"): return
 model.game.career=applied.state
 var snapshot: Dictionary=model.snapshot()
 check(model.save_draft(),"real original owner save writes additive finance under unchanged schema1")
 var loaded:=Opening.new()
 check(loaded.load_draft() and loaded.snapshot()==snapshot and int(loaded.snapshot().schema_version)==1 and str(loaded.screen)=="play" and str(loaded.game.phase)=="play","actual C27 disk reload preserves exact finance/unknowns without fake bankrupt phase")
 check(int(data(loaded.game.career).opening_balance)==250 and amount(loaded.game.career,"outgoing","Other")==5,"actual saved ledger retains opening250/cost5")

func run() -> void:
 var path:=ProjectSettings.globalize_path("user://")
 if not check(path.begins_with(SAFE),"strict fresh S47 isolated userdata guard"): quit(1);return
 for item in [Opening.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  if not check(not FileAccess.file_exists(item),"fresh isolated path "+item): quit(1);return
 protected_initial=protected_files()
 boundaries();ledger_and_invalid();original_gig_cashflow();save_roundtrip()
 check(protected_files()==protected_initial,"all legacy3/C26 bytes remain untouched")
 print("S47_FINANCE_TEST_RESULT ",JSON.stringify({"pass":failures.is_empty(),"checks":checks,"errors":failures,"engine":Engine.get_version_info(),"user_data":path,"method":"independent numeric boundary/gross-ledger expectations; protected original local settlement; real C27 schema1 save/load; no native/device claim"}))
 quit(0 if failures.is_empty() else 1)
