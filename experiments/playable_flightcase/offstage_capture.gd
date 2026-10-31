extends "res://experiments/playable_flightcase/career_capture.gd"
## SCRATCH. Root alone imports/runs this in fresh S48 XDG data.
const Rules = preload("res://experiments/playable_flightcase/offstage_rules.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const S48_SAFE_ROOT := "/workspace/work/business/s48/"
var fixture_disclosures: Array = []

func expected_snapshot(before: Dictionary, career: Dictionary) -> Dictionary:
 var expected: Dictionary = before.duplicate(true)
 expected["game"]["career"]=career.duplicate(true)
 return expected

func expected_result(kind: String, id: String, choice: String="") -> Dictionary:
 var before: Dictionary = model.game.career.duplicate(true)
 var disk: Dictionary = files()
 var raw: Dictionary = Rules.outing(before,id) if kind=="outing" else Rules.respond(before,id,choice)
 if not verify(model.game.career==before and files()==disk,"pure original-composed offstage expectation never mutates live model or files"): return {"ok":false}
 if not bool(raw.get("ok",false)): return raw
 var accounted: Dictionary = Finance.apply(before,raw["state"],str(raw["finance_action"]))
 if not bool(accounted.get("ok",false)): return accounted
 raw["state"]=accounted["state"]
 return raw

func spawn_owner(reduced: bool=false) -> void:
 screen=RootUI.new()
 screen.name="S48OffstageActualNativeQA"
 screen.setup=model
 screen.showing_menu=false
 screen.reduced_motion=reduced
 root.add_child(screen)
 await frames(4)

func reset_fixture(reduced: bool=false) -> bool:
 if is_instance_valid(screen): screen.free()
 screen=null
 await frames(3)
 if not make_fixture(): return false
 await spawn_owner(reduced)
 return verify(practice()!=null,"genuine saved canonical C27 trio opens practice")

func open_offstage() -> bool:
 if desk()==null or not desk().is_visible_in_tree():
  if not await free_action("CareerDeskAction"): return false
 elif str(desk().get("page"))!="home":
  if not await free_action("CareerNav_home"): return false
 if not await free_action("CareerHome_offstage"): return false
 return verify(str(desk().get("page"))=="offstage","actual Home route opens offstage without spending or saving")

func select_activity(id: String, method: String="pointer") -> bool:
 var cost: int = -1
 for raw in Rules.activities(model.game.career):
  if str(raw.id)==id: cost=int(raw.cost)
 if not verify(cost>=0,"original activity preview exists "+id): return false
 if not await free_action("OffstageOption_"+id,method): return false
 var commitment: Label = named("OffstageCommitment") as Label
 var eligibility: Label = named("OffstageEligibility") as Label
 if not verify(commitment!=null and eligibility!=null and commitment.text.contains("£%d" % cost) and commitment.text.to_upper().contains("1 DAY"),"native preview states exact active-trio cost and one day: "+id): return false
 if not verify(inside(commitment) and commitment.get_theme_font_size("font_size")>=16,"full commitment stays readable inside effective clip"): return false
 return check_fixed_layout()

func select_invite(id: String) -> bool:
 var wanted: Dictionary = {}
 for raw in Rules.pending(model.game.career):
  if str(raw.id)==id: wanted=raw
 var title: Label = named("OffstageInviteTitle") as Label
 return verify(not wanted.is_empty() and title!=null and title.text==str(wanted.title),"actual default invitation pane displays the one pending contact "+id)

func select_response(id: String, choice: String) -> bool:
 if choice in ["accept","decline"]: return select_invite(id)
 var label: String = ""
 for row in Rules.response_options(model.game.career,id):
  if str(row.id)==choice: label=str(row.label)
 if not verify(not label.is_empty(),"original scout response label exists "+choice): return false
 var button: Button
 for node in desk().find_children("*","Button",true,false):
  if node.is_visible_in_tree() and (node as Button).text==label: button=node as Button
 if not verify(button!=null,"native preview control exists for original authored choice "+label): return false
 return await free_action(str(button.name),"space" if choice=="careful" else "enter")

func wait_idle() -> bool:
 var until: int = Time.get_ticks_msec()+5000
 while Time.get_ticks_msec()<until:
  if desk()!=null and not bool(desk().get("busy")) and named("SessionTransition")==null:
   await frames(3)
   return true
  await process_frame
 return verify(false,"offstage presentation settles within five seconds")

func saved_roundtrip(label: String) -> bool:
 var before: Dictionary = guard()
 var expected: Dictionary = model.snapshot().duplicate(true)
 expected["game"]["career"]=model.game._restore_integral_numbers(expected["game"]["career"])
 var loaded = Model.new()
 if not verify(loaded.load_draft() and loaded.snapshot()==expected,"actual full C27 disk roundtrip "+label): return false
 return unchanged(before,"independent actual saved load "+label)

func finish_receipt() -> bool:
 if not await free_action("CareerReceiptContinueAction","enter"): return false
 await frames(4)
 return verify(not bool(desk().get("receipt_open")),"native receipt Continue closes only presentation")

func commit_offstage_native(kind: String, id: String, choice: String="", method: String="pointer", natural: bool=false, tag: String="") -> bool:
 var before: Dictionary = guard()
 var expected: Dictionary = expected_result(kind,id,choice)
 if not verify(bool(expected.get("ok",false)),"actual original rules allow intended offstage action "+kind+" "+id+" "+choice): return false
 var action_name: String = "OffstageDeclineAction" if choice=="decline" else "OffstageMainAction"
 if not await activate(action_name,method): return false
 if not verify(model.snapshot()==expected_snapshot(before.snapshot,expected["state"]) and model.saves==int(before.saves)+1 and model.loads==before.loads,"one genuine offstage input settles exact original-composed state and saves exactly once"): return false
 if not verify(desk()!=null and bool(desk().get("receipt_open")),"saved social/contact action creates its actual receipt"): return false
 var receipt: Dictionary = desk().get("receipt")
 if not verify(str(receipt.get("kind",""))=="offstage" and str(receipt.get("return_page",""))==str(expected["return_page"]),"receipt retains offstage kind and original command return destination"): return false
 if bool(desk().get("reduced_motion")):
  if not await wait_idle(): return false
  var note: Label = named("CareerReceiptNote") as Label
  if not verify(note!=null and note.text==str(expected["message"]) and note.visible_characters==-1 and not bool(note.call("is_revealing")),"reduced-motion receipt is immediately full exact original text"): return false
  if not check_receipt(before.snapshot.game.career,expected["state"]): return false
  if not tag.is_empty() and not await capture(tag+"-full"): return false
 else:
  if not await wait_receipt() or not check_receipt(before.snapshot.game.career,expected["state"]): return false
  var note: Label = named("CareerReceiptNote") as Label
  if not verify(note.text==str(expected["message"]),"partially revealed note retains full original authored copy"): return false
  if not await complete_note(natural,tag): return false
 if not verify(model.snapshot()==expected_snapshot(before.snapshot,expected["state"]) and model.saves==int(before.saves)+1,"Beat/Ink skip or completion never repeats mutation or save"): return false
 evidence.append({"kind":"GENUINE native offstage action","command":kind,"id":id,"choice":choice,"cash_before":before.snapshot.game.career.cash,"cash_after":model.game.career.cash,"day_before":before.snapshot.game.career.tour_day,"day_after":model.game.career.tour_day,"save_delta":1,"return_page":expected.return_page})
 return await saved_roundtrip(kind+" "+id+" "+choice)

func resize_selected() -> bool:
 if not await select_activity("drinks") or not await tab_to(named("OffstageMainAction")): return false
 var before: Dictionary = guard()
 var desk_id: int = desk().get_instance_id()
 var practice_node_id: int = practice().get_instance_id()
 var commitment_text: String = (named("OffstageCommitment") as Label).text
 var alternate: Vector2i = Vector2i(1280,720) if width<900 else Vector2i(390,844)
 for window_size in [alternate,Vector2i(width,height)]:
  root.size=window_size
  DisplayServer.window_set_size(window_size)
  await frames(7)
  var action: Button = named("OffstageMainAction") as Button
  var commitment: Label = named("OffstageCommitment") as Label
  if not verify(desk().get_instance_id()==desk_id and practice().get_instance_id()==practice_node_id and commitment!=null and commitment.text==commitment_text,"real live resize retains actual panes and chosen activity/cost"): return false
  if not await settled(action) or not verify(action.has_focus(),"responsive rebuild restores semantic focused48px offstage commit inside all clips"): return false
  if not check_fixed_layout() or not unchanged(before,"free live offstage resize"): return false
 return true

func menu_reload() -> bool:
 var before: Dictionary = guard()
 if not await activate("CareerMenuAction") or not unchanged(before,"offstage menu"): return false
 if not await activate("ContinueAction"): return false
 await frames(5)
 return unchanged(before,"actual offstage saved Continue",1)

func promoter_journey() -> bool:
 if not await open_offstage(): return false
 var commitment_id: int = named("OffstageCommitment").get_instance_id()
 for index in range(Rules.ORDER.size()):
  if not await select_activity(str(Rules.ORDER[index]),str(["pointer","enter","space"][index])): return false
  if not verify(named("OffstageCommitment").get_instance_id()==commitment_id,"three free native previews update existing commitment in place"): return false
 if not await resize_selected() or not await select_activity("watch_gig") or not await capture("offstage-watch-preview"): return false
 if not await commit_offstage_native("outing","watch_gig","","pointer",true,"offstage-watch-note"): return false
 var account: Dictionary = Finance.view(model.game.career)
 if not verify(int(model.game.career.cash)==235 and int(model.game.career.tour_day)==2 and int(account.totals.outgoing.get("Social",0))==15 and Rules.pending(model.game.career).size()==1,"genuine Watch costs15/one day and records Social15 plus one pending contact"): return false
 if not await finish_receipt() or not select_invite(Rules.PROMOTER): return false
 if not await capture("offstage-promoter-invite"): return false
 if not await commit_offstage_native("respond",Rules.PROMOTER,"accept","enter",false,"offstage-promoter-note"): return false
 var state: Dictionary = model.game.career
 if not verify(int(state.cash)==235 and int(state.tour_day)==2 and int(state.booked_show.day)==5 and (state.get("gig_history",[]) as Array).is_empty(),"actual original STANDARD booking spends0/advances0/booksday5 and invents no performance history"): return false
 if not await finish_receipt() or not verify(str(desk().get("page"))=="gigs","promoter receipt returns to actual booked gigs desk"): return false
 return await capture("offstage-promoter-booked")

func decline_journey() -> bool:
 if not await reset_fixture(true) or not await open_offstage() or not await select_activity("watch_gig"): return false
 if not await commit_offstage_native("outing","watch_gig") or not await finish_receipt() or not select_invite(Rules.PROMOTER): return false
 var before_cash: int = int(model.game.career.cash)
 var before_day: int = int(model.game.career.tour_day)
 if not await commit_offstage_native("respond",Rules.PROMOTER,"decline","space") or not await finish_receipt(): return false
 if not verify(int(model.game.career.cash)==before_cash and int(model.game.career.tour_day)==before_day and Rules.pending(model.game.career).is_empty(),"actual decline consumes invitation with0cash/0days"): return false
 var declined: Dictionary = Rules.view(model.game.career).events[Rules.PROMOTER].duplicate(true)
 if not await menu_reload() or not await open_offstage() or not await select_activity("watch_gig"): return false
 if not await commit_offstage_native("outing","watch_gig") or not await finish_receipt(): return false
 if not verify(Rules.pending(model.game.career).is_empty() and Rules.view(model.game.career).events[Rules.PROMOTER]==declined,"real reload and repeat outing never regenerate declined introduction"): return false
 return await capture("offstage-declined-stays-closed")

func scout_journey() -> bool:
 if not await reset_fixture(true): return false
 # Explicit prepared fixture: original-model encounter/acceptance and threshold
 # seed. No claim those setup actions were clicked or a live show was played.
 var prepared: Dictionary = expected_result("outing","watch_gig")
 if not verify(bool(prepared.get("ok",false)),"model-prepared promoter outing fixture valid"): return false
 model.game.career=prepared.state
 prepared=expected_result("respond",Rules.PROMOTER,"accept")
 if not verify(bool(prepared.get("ok",false)),"model-prepared original promoter acceptance valid"): return false
 model.game.career=prepared.state
 # Remove only the explicitly prepared future booking to test a nonshow outing;
 # instead use original live cancellation so its normal costs/journal are kept.
 var canceled: Dictionary = Live.resolve(model.game.career,"cancel")
 if not verify(bool(canceled.get("ok",false)),"original cancellation prepares unbooked nonshow scout fixture"): return false
 var accounted: Dictionary = Finance.apply(model.game.career,canceled.state,"live:cancel")
 if not verify(bool(accounted.get("ok",false)),"fixture cancellation keeps finance checkpoint consistent"): return false
 model.game.career=accounted.state
 model.game.career["fans"]=25
 model.game.career["reputation"]=10
 if not verify(model.save_draft(),"save explicitly prepared accepted-promoter25fans10rep fixture"): return false
 fixture_disclosures.append({"case":"scout eligibility setup ONLY; not a clicked career journey","preparation":"original Rules Watch + promoter STANDARD accept + original cancellation, exact Finance wrapping; set fans25/reputation10 only","snapshot":model.snapshot()})
 screen.free();screen=null
 await frames(3)
 await spawn_owner(true)
 if not await open_offstage() or not await select_activity("drinks"): return false
 var before_cash: int = int(model.game.career.cash)
 if not await commit_offstage_native("outing","drinks") or not await finish_receipt() or not select_invite(Rules.SCOUT): return false
 if not verify(int(model.game.career.cash)==before_cash-18 and Rules.view(model.game.career).contacts.size()==2 and model.game.roster.size()==3 and model.game.career.members.size()==3,"actual18-pound outing creates business scout contact without adding a musician"): return false
 if not await capture("offstage-scout-invite"): return false
 if not await select_response(Rules.SCOUT,"open") or not await select_response(Rules.SCOUT,"careful") or not await select_response(Rules.SCOUT,"open"): return false
 var before: Dictionary = model.game.career.duplicate(true)
 if not await commit_offstage_native("respond",Rules.SCOUT,"open","pointer") or not await finish_receipt(): return false
 if not verify(int(model.game.career.cash)==int(before.cash) and int(model.game.career.tour_day)==int(before.tour_day)+1 and str(model.game.career.opportunities_resolved.first_feature)=="open","actual original first_feature is0cash/1day and resolves authored open choice once"): return false
 if not verify(int(model.game.career.fans)==int(before.get("fans",0))+15 and int(model.game.career.buzz)==mini(100,int(before.get("buzz",0))+12) and int(model.game.career.tension)==mini(100,int(before.get("tension",0))+5),"original authored feature fans15/buzz12/tension5 retained exactly"): return false
 var resolved: Dictionary = model.game.career.duplicate(true)
 if not await menu_reload() or not await open_offstage(): return false
 if not verify(model.game.career==resolved and Rules.pending(model.game.career).is_empty() and model.game.roster.size()==3,"actual reload never duplicates feature reward or recruits another musician"): return false
 return await capture("offstage-scout-completed")

func defensive_guards() -> bool:
 # Explicit direct stale-handler defense only; not claimed genuine input.
 var before: Dictionary = guard()
 var terminal: Dictionary = model.game.career.duplicate(true)
 var zero: Dictionary = terminal.duplicate(true)
 zero["cash"]=0
 var emptying: Dictionary = Finance.apply(terminal,zero,"test fixture")
 if not verify(bool(emptying.get("ok",false)),"terminal defense same-day zero fixture valid"): return false
 terminal=emptying.state
 var after: Dictionary = terminal.duplicate(true)
 after["tour_day"]=int(terminal.tour_day)+14
 var zeros: Array = []
 for index in range(14): zeros.append(0)
 var closed: Dictionary = Finance.apply(terminal,after,"fixture: fourteen completed zero-cash days",[],zeros)
 if not verify(bool(closed.get("ok",false)),"terminal defense explicit14-close fixture valid"): return false
 model.game.career=closed.state
 var terminal_before: Dictionary = guard()
 desk().call("_commit_offstage","outing","watch_gig","")
 await frames(3)
 if not unchanged(terminal_before,"DIRECT stale offstage terminal handler"): return false
 # Restore the original fixture memory only; these unsaved guard fixtures must
 # not alter the actual saved career or its finance checkpoint.
 model.game.career=before.snapshot.game.career.duplicate(true)
 var booked: Dictionary = Live.resolve(model.game.career,"book","standard",false)
 if not verify(bool(booked.get("ok",false)),"showday defense original STANDARD booking fixture valid"): return false
 model.game.career=booked.state
 model.game.career["tour_day"]=int(model.game.career.booked_show.day)
 var show_before: Dictionary = guard()
 desk().call("_commit_offstage","outing","watch_gig","")
 await frames(3)
 if not unchanged(show_before,"DIRECT stale offstage showday handler before resolver"): return false
 model.game.career=before.snapshot.game.career.duplicate(true)
 return unchanged(before,"discard explicitly unsaved terminal/showday defensive fixtures")

func journey() -> bool:
 return await promoter_journey() and await decline_journey() and await scout_journey() and await defensive_guards()

func run() -> void:
 var started: int = Time.get_ticks_msec()
 if output=="/workspace/work/unify/s45/career-capture": output=S48_SAFE_ROOT+"native"
 var user_dir: String = ProjectSettings.globalize_path("user://")
 var output_path: String = ProjectSettings.globalize_path(output)
 var safe: bool = verify(user_dir.begins_with(S48_SAFE_ROOT) and output_path.begins_with(S48_SAFE_ROOT),"strict fresh S48 user/output guard")
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated fixture path "+path) and safe
 if not safe:
  print("S48_OFFSTAGE_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}));quit(1);return
 output=output_path
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create scratch offstage native directory"): quit(1);return
 protected_initial=files(true)
 root.size=Vector2i(width,height)
 DisplayServer.window_set_size(root.size)
 root.grab_focus()
 await frames(4)
 var orphan_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 deadline=started+120000
 if make_fixture():
  await spawn_owner(false)
  await journey()
 if not failures.is_empty() and is_instance_valid(screen): await capture("FIRST-FAILURE")
 if is_instance_valid(screen): screen.free()
 screen=null
 await frames(4)
 var orphan_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 verify(files(true)==protected_initial,"all offstage cases leave original legacy/C26 saves unchanged")
 verify(orphan_after<=orphan_before,"no orphan growth after all native owners freed")
 var result: Dictionary = {"pass":failures.is_empty(),"checks":checks,"errors":failures,"images":images,"width":width,"height":height,"engine":Engine.get_version_info(),"user_data":user_dir,"elapsed_ms":Time.get_ticks_msec()-started,"orphan_before":orphan_before,"orphan_after":orphan_after,"evidence":evidence,"fixture_disclosures":fixture_disclosures,"visual_diagnostics":visual_diagnostics,"method":"Original-composed Rules plus exact Finance; genuine native mouse/Enter/Space/Tab for core actions; actual C27 IO. Scout threshold and final guard states explicitly model-prepared. Terminal/showday handler calls are defensive direct calls only."}
 var receipt = FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null: push_error("S48_OFFSTAGE could not write result");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close()
 print("S48_OFFSTAGE_RESULT ",JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
