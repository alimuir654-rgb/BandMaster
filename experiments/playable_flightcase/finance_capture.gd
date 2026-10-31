extends "res://experiments/playable_flightcase/career_capture.gd"
## SCRATCH S47 only. Root executes a pinned copied runtime, never production IO.
## Normal journeys use actual Input. Clearly marked terminal-defense calls below
## exercise retained UI guards directly; they are NOT claimed as mouse journeys.
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const S47_SAFE_ROOT := "/workspace/work/business/s47/"
var genuine_clear_air_commits: int = 0
var prepared_zero_closings: int = 0

func wait_idle(want_desk: bool = false) -> bool:
 var until: int = Time.get_ticks_msec()+5000
 while Time.get_ticks_msec()<until:
  var pane: Control = desk() if want_desk else practice()
  var busy_name: String = "busy" if want_desk else "session_busy"
  if pane!=null and not bool(pane.get(busy_name)) and named("SessionTransition")==null:
   await frames(3)
   return true
  await process_frame
 return verify(false,"bounded saved-action presentation settles")

func spawn_owner() -> void:
 screen=RootUI.new()
 screen.name="S47FinanceActualNativeQA"
 screen.setup=model
 screen.showing_menu=false
 screen.reduced_motion=true
 root.add_child(screen)
 await frames(4)

func first_fold_finance(cash: int, terminal: bool) -> bool:
 var balance: Label = named("FinanceBalance") as Label
 var status: Label = named("FinanceStatus") as Label
 var title: Label = named("FinanceTitle") as Label
 if not verify(desk()!=null and str(desk().get("page"))=="finance" and balance!=null and status!=null and title!=null,"actual finance page and named native money/status exist"): return false
 if not verify(balance.text=="£%d" % cash and inside(balance) and inside(status) and status.get_theme_font_size("font_size")>=16,"MoneyStatus: actual balance and full16px status initially visible inside all clips"): return false
 if not verify((title.text=="BAND HAS FOLDED")==terminal and Finance.is_over(model.game.career)==terminal,"terminal heading agrees with saved finance state"): return false
 return check_fixed_layout()

func finance_scroll() -> bool:
 var before: Dictionary = guard()
 var scroll: ScrollContainer = named("CareerScroll") as ScrollContainer
 if not verify(scroll!=null,"finance ledger has actual native scroll"): return false
 var bar: VScrollBar = scroll.get_v_scroll_bar()
 if bar.max_value>bar.page:
  # Native scrollbar sits outside the content clip; do not use inside(bar).
  if bar.has_focus(): await key(KEY_TAB,true)
  for attempt in range(64):
   if bar.has_focus(): break
   await key(KEY_TAB)
  if not verify(bar.has_focus() and bar.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bar.get_global_rect()),"genuine Tab reaches visible finance history scrollbar"): return false
  await key(KEY_END)
  await frames(3)
  if not verify(bar.has_focus() and scroll.scroll_vertical==roundi(bar.max_value-bar.page),"genuine End reveals final ledger content without leaving scrollbar"): return false
  await key(KEY_HOME)
  await frames(3)
  if not verify(bar.has_focus() and scroll.scroll_vertical==0,"genuine Home restores first-fold finance summary"): return false
 return unchanged(before,"finance ledger native Tab/End/Home")

func saved_roundtrip(label: String) -> bool:
 var before: Dictionary = guard()
 var expected: Dictionary = model.snapshot().duplicate(true)
 # Original JSON restore intentionally normalises integral career numbers.
 expected["game"]["career"]=model.game._restore_integral_numbers(expected["game"]["career"])
 var loaded = Model.new()
 if not verify(loaded.load_draft(),"actual scratch-disk load succeeds: "+label): return false
 if not verify(loaded.snapshot()==expected,"strict full original-model load roundtrip: "+label): return false
 return unchanged(before,"independent actual disk load "+label)

func initial_and_purchase() -> bool:
 if not verify(not model.game.career.has(Finance.KEY),"fresh legacy-compatible C27 career has no invented historic ledger"): return false
 if not await free_action("CareerDeskAction") or not await free_action("CareerHome_finance"): return false
 if not first_fold_finance(250,false) or not verify(not model.game.career.has(Finance.KEY),"finance inspection does not migrate or save the career"): return false
 if not await capture("finance-initial") or not await finance_scroll(): return false
 if not await free_action("CareerFinanceBackAction") or not await free_action("CareerNav_gear"): return false
 if not verify(str(desk().get("selected_item"))=="amp","actual original default shop selection is65-pound amp"): return false
 var before: Dictionary = guard()
 var original: Dictionary = Bridge.gear_action(model.game.career.duplicate(true),"buy","amp",-1)
 if not verify(bool(original.get("ok",false)),"pure original amp purchase expectation succeeds"): return false
 var expected: Dictionary = Finance.apply(model.game.career,original["state"],"gear:buy")
 if not verify(bool(expected.get("ok",false)),"accounting wraps original purchase without changing its gameplay result"): return false
 if not await activate("GearBuyAction") or not await wait_idle(true): return false
 if not verify(model.game.career==expected["state"] and model.saves==int(before.saves)+1 and model.loads==before.loads,"one genuine65-pound equipment purchase commits exact original-plus-finance state once"): return false
 var account: Dictionary = Finance.view(model.game.career)
 if not verify(int(model.game.career.cash)==185 and int(model.game.career.tour_day)==2 and int(account.totals.outgoing.Equipment)==65 and int(account.closing_balance)==185 and int(account.opening_balance)==250,"actual purchase ledger reconciles250 minus65 equals185"): return false
 evidence.append({"kind":"genuine native purchase","original_action":"GearBuyAction","cash_before":250,"cash_after":185,"equipment_outgoing":65,"saves":1,"day_after":2})
 if not await free_action("CareerReceiptContinueAction") or not await free_action("CareerNav_home") or not await free_action("CareerHome_finance"): return false
 if not first_fold_finance(185,false) or not await capture("finance-populated") or not await finance_scroll() or not await saved_roundtrip("after actual amp purchase"): return false
 return true

func prepare_zero_fixture() -> bool:
 # Separate fixture, not a withdrawal or a continuation of the purchase career.
 if is_instance_valid(screen): screen.free()
 screen=null
 await frames(3)
 if not make_fixture(): return false
 var before: Dictionary = model.game.career.duplicate(true)
 var zero_cash: Dictionary = before.duplicate(true)
 zero_cash["cash"]=0
 var zero: Dictionary = Finance.apply(before,zero_cash,"test fixture")
 if not verify(bool(zero.get("ok",false)),"explicit same-day cash-zero test fixture is valid accounting"): return false
 model.game.career=zero["state"]
 if not verify(int(model.game.career.tour_day)==1 and int(Finance.view(model.game.career).broke_days)==0,"same-day zero fixture does not invent a completed broke day"): return false
 if width!=390:
  var after: Dictionary = model.game.career.duplicate(true)
  after["tour_day"]=14
  var closes: Array = []
  for index in range(13): closes.append(0)
  var seeded: Dictionary = Finance.apply(model.game.career,after,"fixture: thirteen completed zero-cash days",[],closes)
  if not verify(bool(seeded.get("ok",false)),"explicit model-prepared13-closing fixture is accepted"): return false
  model.game.career=seeded["state"]
  prepared_zero_closings=13
  if not verify(int(Finance.view(model.game.career).broke_days)==13 and not Finance.is_over(model.game.career),"prepared13 completed broke days remains playable"): return false
 if not verify(model.save_draft(),"explicit fixture saved to isolated C27 draft only"): return false
 evidence.append({"kind":"MODEL-PREPARED FIXTURE; not actual withdrawal or UI days","action":"test fixture","cash_before":250,"cash_after":0,"same_day":true,"prepared_completed_zero_days":prepared_zero_closings})
 await spawn_owner()
 return verify(practice()!=null and practice().is_visible_in_tree(),"nonterminal zero-cash saved fixture opens actual practice")

func clear_air_to_terminal() -> bool:
 if not await free_action("PracticeMode_connect"): return false
 # Retain actual original UI owners before the terminal action for guard checks.
 var retained_practice: Control = practice()
 if not await free_action("CareerDeskAction") or not await free_action("CareerPracticeAction"): return false
 var retained_desk: Control = desk()
 var count: int = 14 if width==390 else 1
 for index in range(count):
  var before: Dictionary = guard()
  var before_day: int = int(model.game.career.tour_day)
  var before_account: Dictionary = Finance.view(model.game.career)
  # Derive the entire expected effect from the unmodified original resolver.
  var original = Game.new()
  if not verify(original.restore(model.game.snapshot()),"original resolver clone restores before genuine free session"): return false
  var action: Dictionary = original.clear_air()
  if not verify(bool(action.get("ok",false)),"original free ClearAir resolver accepts current saved state"): return false
  var expected: Dictionary = Finance.apply(model.game.career,original.career,"practice:connect")
  if not verify(bool(expected.get("ok",false)),"expected finance wraps one original free session"): return false
  if not await activate("ClearAirAction") or not await wait_idle(): return false
  genuine_clear_air_commits+=1
  if not verify(model.game.career==expected["state"] and model.saves==int(before.saves)+1 and model.loads==before.loads,"each genuine ClearAir settles and saves exactly once with exact original-plus-finance effect"): return false
  var account: Dictionary = Finance.view(model.game.career)
  if not verify(int(model.game.career.cash)==0 and int(model.game.career.tour_day)==before_day+1 and int(account.broke_days)==int(before_account.broke_days)+1,"genuine free session adds one completed zero-cash day"): return false
  evidence.append({"kind":"genuine native ClearAirAction","number":genuine_clear_air_commits,"day_before":before_day,"day_after":int(model.game.career.tour_day),"broke_days":int(account.broke_days),"saves":1})
  if index<count-1:
   if not verify(not Finance.is_over(model.game.career) and desk()!=null and not desk().is_visible_in_tree(),"band remains playable until14th completed broke day"): return false
   if not await free_action("RecapToggleAction"): return false
   var returning: Dictionary = guard()
   if not await wait_idle() or not unchanged(returning,"presentation-only Continue to next day settles"): return false
 if not verify(Finance.is_over(model.game.career) and int(Finance.view(model.game.career).broke_days)==14 and int(model.game.career.tour_day)==15 and int(Finance.view(model.game.career).ended_day)==15,"exact14th zero-cash close folds the band on day15"): return false
 if not verify(desk()!=null and desk().is_visible_in_tree() and not practice().is_visible_in_tree(),"terminal saved action automatically opens final accounts"): return false
 if not first_fold_finance(0,true) or not await capture("finance-terminal") or not await finance_scroll() or not await saved_roundtrip("terminal final accounts"): return false
 var protected: Dictionary = guard()
 for id in ["CareerNav_home","CareerNav_gear","CareerNav_band","CareerNav_songs","CareerPracticeAction"]:
  var button: Button = named(id) as Button
  if not verify(button!=null and button.disabled,"terminal gameplay/navigation action is disabled: "+id): return false
  if not await activate(id,"pointer",true) or not unchanged(protected,"terminal actual disabled pointer "+id): return false
 # Explicit defensive-call tests, not substituted for the genuine actions above.
 if not verify(is_instance_valid(retained_practice) and is_instance_valid(retained_desk),"retained pre-terminal UI owners are still actual nodes"): return false
 retained_practice.call("_commit_session","connect")
 await frames(2)
 if not unchanged(protected,"DIRECT stale practice guard before resolver"): return false
 retained_desk.call("_commit_gear","buy",-1)
 await frames(2)
 if not unchanged(protected,"DIRECT stale gear guard before resolver"): return false
 retained_desk.call("_commit_live","book")
 await frames(2)
 if not unchanged(protected,"DIRECT stale live guard before resolver"): return false
 if not await free_action("CareerMenuAction"): return false
 var menu_guard: Dictionary = guard()
 if not await activate("ContinueAction"): return false
 await frames(5)
 if not unchanged(menu_guard,"real terminal Continue reload",1): return false
 if not verify(Finance.is_over(model.game.career) and desk()!=null and desk().is_visible_in_tree() and not practice().is_visible_in_tree(),"actual Continue reload preserves terminal state and routes to finance"): return false
 return first_fold_finance(0,true)

func run() -> void:
 # Parent _init parses --out/--size and dispatches this override deferred.
 if output=="/workspace/work/unify/s45/career-capture": output=S47_SAFE_ROOT+"finance-capture"
 var user_dir: String = ProjectSettings.globalize_path("user://")
 var output_path: String = ProjectSettings.globalize_path(output)
 var safe: bool = verify(user_dir.begins_with(S47_SAFE_ROOT) and output_path.begins_with(S47_SAFE_ROOT),"strict fresh S47 XDG/output guard")
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path),"fresh isolated fixture path "+path) and safe
 if not safe:
  print("S47_FINANCE_CAPTURE_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}));quit(1);return
 output=output_path
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create S47 scratch native capture directory"):
  quit(1);return
 protected_initial=files(true)
 root.size=Vector2i(width,height)
 DisplayServer.window_set_size(root.size)
 root.grab_focus()
 await frames(4)
 var orphan_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 deadline=Time.get_ticks_msec()+110000
 if make_fixture():
  await spawn_owner()
  if await initial_and_purchase():
   if await prepare_zero_fixture():
    await clear_air_to_terminal()
 if not failures.is_empty() and is_instance_valid(screen): await capture("FIRST-FAILURE")
 if is_instance_valid(screen): screen.free()
 await frames(3)
 var orphan_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 verify(orphan_after<=orphan_before,"actual S47 finance UI teardown has no orphan growth")
 verify(files(true)==protected_initial,"S47 finance proof leaves original legacy/C26 saves absent and unchanged")
 var result: Dictionary = {"pass":failures.is_empty(),"checks":checks,"errors":failures,"width":width,"height":height,"engine":Engine.get_version_info(),"user_data":user_dir,"images":images,"evidence":evidence,"genuine_clear_air_commits":genuine_clear_air_commits,"model_prepared_zero_closings":prepared_zero_closings,"save_calls_current_fixture":model.saves if model!=null else 0,"load_calls_current_fixture":model.loads if model!=null else 0,"orphan_before":orphan_before,"orphan_after":orphan_after,"orphan_growth":orphan_after-orphan_before,"method":"Actual isolated C27 IO and genuine native pointer/Tab/Home/End. Purchase then a separately prepared zero-cash fixture. Phone14 genuine free sessions; otherprofiles13 disclosed model-prepared closings plus1 genuine session. Terminal direct UI-handler calls are explicit defensive tests, not claimed UI actions.","clip_method":"inherited448a all clipping ancestors minus visible scrollbar area"}
 var receipt = FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:
  push_error("S47_FINANCE_CAPTURE could not write result");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close()
 print("S47_FINANCE_CAPTURE_RESULT ",JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
