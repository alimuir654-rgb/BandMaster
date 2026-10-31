extends "res://experiments/playable_flightcase/career_capture.gd"
## SCRATCH S46 native integration template. Root alone runs a pinned runtime.
## Inherits canonical real Input, pressed counters and ALL-ancestor clipping.
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Brief = preload("res://Scripts/live_night_briefing.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const S46_SAFE_ROOT := "/workspace/work/unify/s46/"
var live_evidence: Array = []
var modal_evidence: Array = []

func wait_practice_idle() -> bool:
 var until: int=Time.get_ticks_msec()+3000
 while practice()!=null and bool(practice().get("session_busy")) and Time.get_ticks_msec()<until: await process_frame
 return verify(practice()!=null and not bool(practice().get("session_busy")),"actual practice presentation completes without model work")

func exact_live_snapshot(before: Dictionary, career: Dictionary) -> Dictionary:
 var expected: Dictionary=before.duplicate(true)
 expected.game.career=career.duplicate(true)
 return expected

func open_live_from_home() -> bool:
 if desk()==null or not desk().is_visible_in_tree():
  if not await free_action("CareerDeskAction"): return false
 if str(desk().get("page"))!="home":
  if not await free_action("CareerNav_home","enter"): return false
 if not await free_action("CareerHomeLiveAction"): return false
 return verify(str(desk().get("page"))=="gigs" and desk().get("game")==model.game,"real current-band Home route opens original live-career page")

func plan_choice(node_name: String, field: String, value: String, names: Array) -> bool:
 var target:=named(node_name) as Button
 if not verify(target!=null,"actual local planning option exists "+node_name): return false
 # Establish real target focus/reveal BEFORE measuring continuity of selection.
 if not await tab_to(target) or not await settled(target): return false
 var before:=guard()
 var scroll:=named("CareerScroll") as ScrollContainer
 var offset: int=scroll.scroll_vertical
 var identities: Dictionary={}
 for option_name in names:
  var option:=named(str(option_name))
  if not verify(option!=null,"every original planning choice remains available"): return false
  identities[str(option_name)]=option.get_instance_id()
 if not await activate(node_name,"enter"): return false
 if not unchanged(before,"local offer/approach selection "+value): return false
 for option_name in identities:
  var option:=named(str(option_name))
  if not verify(option!=null and option.get_instance_id()==int(identities[option_name]),"local planning updates existing native choice in place"): return false
 return verify(str(desk().get(field))==value and named(node_name).has_focus() and scroll==named("CareerScroll") and scroll.scroll_vertical==offset,"free local plan keeps selected focus and exact existing scroll")

func live_scroll_roundtrip() -> bool:
 var before:=guard()
 var scroll:=named("CareerScroll") as ScrollContainer
 if not verify(scroll!=null and scroll.follow_focus,"live dossier uses existing focus-follow native scroll"): return false
 var bar:=scroll.get_v_scroll_bar()
 if bar.is_visible_in_tree() and bar.max_value>bar.page:
  if bar.has_focus(): await key(KEY_TAB,true)
  var steps:=0
  while not bar.has_focus() and steps<64:
   await key(KEY_TAB)
   steps+=1
  if not verify(bar.has_focus() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bar.get_global_rect()),"genuine Tab reaches visible native live scroll chrome"): return false
  await key(KEY_END)
  if not verify(scroll.scroll_vertical==roundi(bar.max_value-bar.page),"native End reaches live dossier end"): return false
  await key(KEY_HOME)
  if not verify(scroll.scroll_vertical==0,"native Home restores live dossier start"): return false
 return unchanged(before,"free native live Tab/Home/End")

func finish_live_receipt(before: Dictionary, expected: Dictionary, tag: String="") -> bool:
 if not await wait_receipt() or not check_receipt(before,expected.state): return false
 var receipt: Dictionary=desk().get("receipt")
 var note:=named("CareerReceiptNote") as Label
 if not verify(str(receipt.get("kind",""))=="live" and not note.text.strip_edges().is_empty(),"live receipt has actual native core copy; journal remains separate"): return false
 var authored: String=str(expected.message) if expected.has("message") else str(Night.stage(expected.state).get("detail",""))
 if not verify(note.text==authored,"core live receipt retains exact original authored result or stage detail"): return false
 if not await complete_note(false,tag): return false
 var loaded:=Model.new()
 if not verify(loaded.load_draft() and loaded.snapshot()==model.snapshot(),"actual live saved settlement reloads exactly"): return false
 if not await free_action("CareerReceiptContinueAction","enter"): return false
 await frames(3)
 return verify(not bool(desk().get("receipt_open")) and str(desk().get("page"))=="gigs","existing receipt Continue returns to current live page without settlement")

func commit_live(verb: String, choice: String="", tag: String="") -> bool:
 var before: Dictionary=model.game.career.duplicate(true)
 var snapshot: Dictionary=model.snapshot()
 var expected: Dictionary=Live.resolve(before,verb,choice,false)
 if not verify(bool(expected.get("ok",false)),"original live bridge permits "+verb): return false
 var save_count: int=model.saves
 if not await activate("LiveMainAction"): return false
 if not verify(model.snapshot()==exact_live_snapshot(snapshot,expected.state) and model.saves==save_count+1,"one real live input settles exact original rules and owner save: "+verb): return false
 if not await finish_live_receipt(before,expected,tag): return false
 if not verify(model.saves==save_count+1,"live presentation/disclosure never saves again"): return false
 live_evidence.append({"verb":verb,"choice":choice,"before":before,"after":model.game.career.duplicate(true),"save_delta":model.saves-save_count})
 return true

func live_menu_roundtrip() -> bool:
 var before:=guard()
 if not await activate("CareerMenuAction"): return false
 if not verify(bool(screen.get("showing_menu")),"native career Menu opens actual root menu") or not unchanged(before,"live Menu"): return false
 if not await activate("ContinueAction"): return false
 if not unchanged(before,"actual live-career Continue",1): return false
 if desk()!=null and desk().is_visible_in_tree():
  return verify(str(desk().get("page"))=="gigs","show-day Continue may safely route directly to live")
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice_idle(): return false
 return await open_live_from_home()

func write_three_actual_sessions() -> bool:
 if not await free_action("LiveWriteAction") or not await wait_practice_idle(): return false
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice_idle(): return false
 if not await free_action("PracticeMode_create") or not await type_pending_title(): return false
 for index in range(3):
  var pane:=practice()
  var before: Dictionary=model.game.career.duplicate(true)
  var snapshot: Dictionary=model.snapshot()
  var trial:=Game.new()
  if not verify(trial.restore(model.game.snapshot()),"independent original practice oracle restores genuine game"): return false
  var result: Dictionary=trial.write_session(str(Workshop.IDEAS[int(pane.get("idea_index"))]),str(Workshop.FORMS[int(pane.get("form_index"))]),str(pane.get("song_title")),int(pane.get("leader_index")))
  if not verify(bool(result.get("ok",false)),"original practice permits genuine writing session"): return false
  var expected: Dictionary=Live.after_practice(before,trial.career)
  var save_count: int=model.saves
  if not await activate("WriteAction") or not await wait_practice_idle(): return false
  if not verify(model.snapshot()==exact_live_snapshot(snapshot,expected) and model.saves==save_count+1 and int(model.game.career.tour_day)==index+2,"actual Write plus original pending-gig post-chain advances one day/save exactly"): return false
  live_evidence.append({"verb":"write","session":index+1,"before":before,"after":model.game.career.duplicate(true),"save_delta":model.saves-save_count})
  if not await free_action("RecapToggleAction") or not await wait_practice_idle(): return false
 return verify(int(model.game.career.get("songs",0))==1 and (model.game.career.get("song_catalogue",[]) as Array).size()==1 and Live.show_day(model.game.career),"three actual saved writes finish one original and reach booked show day")

func show_day_routes() -> bool:
 # The new title is deliberately blank. This input is a FREE route, not Write.
 var before:=guard()
 var title:=named("SongTitle") as LineEdit
 if not verify(title!=null,"show-day practice retains actual native writing field"): return false
 if not inside(title) and not await tab_to(title): return false
 if not await settled(title): return false
 await pointer(title.get_global_rect().get_center())
 await key(KEY_A,false,true)
 await key(KEY_BACKSPACE)
 if not verify(title.text.is_empty(),"genuine native typing clears the next song title") or not unchanged(before,"empty show-day pending title"): return false
 if not await free_action("WriteAction"): return false
 if not verify(desk()!=null and desk().is_visible_in_tree() and str(desk().get("page"))=="gigs","blank-title show-day Write routes before any practice resolver"): return false
 if not await free_action("CareerNav_gear"): return false
 var blocked:=guard()
 if not await activate("GearBuyAction","pointer",true) or not unchanged(blocked,"native show-day gear Buy is disabled with zero pressed"): return false
 return await open_live_from_home()

func live_dialog() -> Control:
 return desk().get("_live_dialog") as Control if desk()!=null else null

func check_live_dialog(dialog: Control) -> bool:
 if not verify(dialog!=null and str(dialog.name)=="LiveConfirmDialog" and bool(dialog.get("is_open")),"actual original framed warning is open"): return false
 var panel:=dialog.get("panel") as Control
 if not verify(panel!=null and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"live warning panel stays wholly inside native window"): return false
 for name in ["LiveKeepAction","LiveConfirmAction"]:
  var action:=named(name) as Button
  if not await settled(action) or not text_fits(action): return false
 return verify(root.gui_get_focus_owner()!=null and dialog.is_ancestor_of(root.gui_get_focus_owner()),"meaningful native focus remains inside live warning")

func dismiss_and_resize_warnings() -> bool:
 var before:=guard()
 if not await activate("LiveMainAction"): return false
 var dialog:=live_dialog()
 if not await check_live_dialog(dialog): return false
 if not verify(named("LiveKeepAction").has_focus(),"original framed warning begins on safe KEEP action"): return false
 var accepted: Array=[]
 dialog.completed.connect(func(value: bool): accepted.append(value))
 var dialog_id: int=dialog.get_instance_id()
 var alternate:=Vector2i(1280,720) if width<900 else Vector2i(390,844)
 var desk_id: int=desk().get_instance_id()
 for target in [alternate,Vector2i(width,height)]:
  root.size=target
  DisplayServer.window_set_size(target)
  await frames(4)
  if not verify(live_dialog()!=null and live_dialog().get_instance_id()==dialog_id and desk().get_instance_id()==desk_id and accepted.is_empty(),"native resize retains original pending warning with no implicit answer"): return false
  if not await check_live_dialog(dialog) or not unchanged(before,"resize pending live confirmation"): return false
  await key(KEY_TAB)
  if not verify(root.gui_get_focus_owner()!=null and dialog.is_ancestor_of(root.gui_get_focus_owner()),"native Tab remains within pending live warning"): return false
  await key(KEY_TAB,true)
  if not verify(root.gui_get_focus_owner()!=null and dialog.is_ancestor_of(root.gui_get_focus_owner()),"native ShiftTab remains within pending live warning"): return false
  modal_evidence.append({"window":str(root.size),"dialog_id":dialog_id,"desk_id":desk_id,"focused":str(root.gui_get_focus_owner().name)})
 await key(KEY_ESCAPE)
 await frames(3)
 var current_main:=named("LiveMainAction")
 var escaped_dialog:=live_dialog()
 if not verify(accepted==[false] and (escaped_dialog==null or not bool(escaped_dialog.get("is_open"))) and named("LiveConfirmAction")==null and current_main!=null and current_main.has_focus(),"real Escape cancels once and restores current semantic live action focus"): return false
 if not unchanged(before,"Escape live confirmation"): return false
 if not await activate("LiveMainAction") or not await check_live_dialog(live_dialog()): return false
 var kept: Array=[]
 live_dialog().completed.connect(func(value: bool): kept.append(value))
 if not await activate("LiveKeepAction"): return false
 await frames(3)
 current_main=named("LiveMainAction")
 var kept_dialog:=live_dialog()
 if not verify(kept==[false] and (kept_dialog==null or not bool(kept_dialog.get("is_open"))) and named("LiveConfirmAction")==null and current_main!=null and current_main.has_focus(),"real KEEP cancels once and restores current live action focus"): return false
 return unchanged(before,"native KEEP live confirmation")

func perform_once() -> bool:
 var before: Dictionary=model.game.career.duplicate(true)
 var snapshot: Dictionary=model.snapshot()
 var expected: Dictionary=Live.resolve(before,"perform")
 if not verify(bool(expected.get("ok",false)),"complete original performance oracle is valid"): return false
 var save_count: int=model.saves
 if not await free_action("LiveMainAction") or not await check_live_dialog(live_dialog()): return false
 if not await capture("live-stage-warning"): return false
 var count: Array=[]
 live_dialog().completed.connect(func(value: bool): count.append(value))
 var point: Vector2=named("LiveConfirmAction").get_global_rect().get_center()
 if not await activate("LiveConfirmAction","enter"): return false
 if not verify(bool(desk().get("busy")) and named("SessionTransition")!=null,"actual committed live presentation owns input before repeated pointer"): return false
 # Genuine second physical input at the committing point while presentation owns UI.
 await pointer(point)
 if not verify(count==[true] and model.snapshot()==exact_live_snapshot(snapshot,expected.state) and model.saves==save_count+1,"real confirm plus rapid second pointer settles original gig once"): return false
 if not verify((model.game.career.get("gig_history",[]) as Array).size()==1 and int(model.game.career.tour_day)==5,"one real show adds one history entry and advances to day five"): return false
 if not await finish_live_receipt(before,expected,"live-result"): return false
 if not verify(model.saves==save_count+1,"performance note/Continue never re-settle or save"): return false
 live_evidence.append({"verb":"perform","before":before,"after":model.game.career.duplicate(true),"save_delta":model.saves-save_count,"callbacks":count})
 return true

func check_last_show() -> bool:
 var summary: Dictionary=Brief.last_show(model.game.career)
 var history: Array=model.game.career.get("gig_history",[])
 if not verify(not summary.is_empty() and history.size()==1 and history.back() is Dictionary,"original saved last-show briefing and exactly one record exist"): return false
 var record: Dictionary=history.back()
 var terms: Dictionary=Promoter.OFFERS.get(str(summary.terms),{})
 var exact: Dictionary={
  "LiveLastShowVenue":str(summary.venue),
  "LiveLastShowFee":"FEE RECEIVED £%d  •  %s" % [int(summary.fee),"GOOD RECEPTION" if bool(summary.success) else "A TOUGH NIGHT"],
  "LiveLastShowFacts":"RECORDED DAY %d  •  %d ORIGINALS" % [int(record.day),int(summary.originals)],
  "LiveLastShowTerms":"AGREEMENT  /  "+str(terms.get("label",str(summary.terms)))
 }
 for node_name in exact:
  var label:=named(str(node_name)) as Label
  if not verify(label!=null and label.text==str(exact[node_name]),"native saved last-show copy equals actual original record/Brief: "+str(node_name)): return false
 return verify(int(model.game.career.tour_day)==5,"reopening result cannot re-settle saved show")

func live_journey() -> bool:
 if not verify(practice()!=null,"genuine original250/day1 current-band fixture reaches practice"): return false
 if not await open_live_from_home() or not await check_desk_header(): return false
 if not await capture("live-unbooked"): return false
 var offer_names: Array=["LiveOffer_standard","LiveOffer_guarantee","LiveOffer_guestlist"]
 for offer in ["guarantee","guestlist","standard"]:
  if not await plan_choice("LiveOffer_"+offer,"live_offer",offer,offer_names): return false
 if not await commit_live("book","standard"): return false
 if not verify(int(model.game.career.tour_day)==1 and int(model.game.career.cash)==250 and int(model.game.career.booked_show.day)==4,"actual standard booking is free today and schedules day four"): return false
 if not await live_scroll_roundtrip() or not await capture("live-booked"): return false
 if not await live_menu_roundtrip() or not await write_three_actual_sessions() or not await show_day_routes(): return false
 if not await capture("live-arrival"): return false
 if not await commit_live("advance") or not await capture("live-soundcheck"): return false
 var approach_names: Array=["LiveApproach_tight","LiveApproach_wild","LiveApproach_crowd"]
 for approach in ["wild","tight","crowd"]:
  if not await plan_choice("LiveApproach_"+approach,"live_approach",approach,approach_names): return false
 if not await commit_live("soundcheck","crowd"): return false
 if not verify(str(Night.stage(model.game.career).phase)=="stage","one soundcheck commitment chooses original approach and advances stage"): return false
 if not await dismiss_and_resize_warnings() or not await perform_once(): return false
 if not await live_menu_roundtrip() or not check_last_show(): return false
 return await capture("live-reloaded-result")

func run() -> void:
 var started: int=Time.get_ticks_msec()
 var user_dir:=ProjectSettings.globalize_path("user://")
 var output_path:=ProjectSettings.globalize_path(output)
 var supported: Array=[Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720),Vector2i(1600,900)]
 var safe: bool=verify(supported.has(Vector2i(width,height)),"one of four real native profiles")
 safe=verify(user_dir.begins_with(S46_SAFE_ROOT) and output_path.begins_with(S46_SAFE_ROOT),"fresh isolated S46 XDG/output guard") and safe
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated fixture file "+path) and safe
 if not safe:
  print("S46_LIVE_CAPTURE_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}));quit(1);return
 output=output_path
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create S46 native proof output"): quit(1);return
 protected_initial=files(true)
 root.size=Vector2i(width,height)
 DisplayServer.window_set_size(root.size)
 root.grab_focus()
 await frames(4)
 var orphan_before: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 deadline=started+90000
 if make_fixture():
  screen=RootUI.new()
  screen.name="S46LiveActualNativeQA"
  screen.setup=model
  screen.showing_menu=false
  root.add_child(screen)
  await frames(3)
  await live_journey()
 if not failures.is_empty() and is_instance_valid(screen): await capture("FIRST-FAILURE")
 if is_instance_valid(screen): screen.free()
 screen=null
 await frames(4)
 var orphan_after: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 verify(files(true)==protected_initial,"all native live actions preserve legacy3/C26 file bytes")
 verify(orphan_after<=orphan_before,"no orphan growth after all real current-band UI freed")
 verify(Time.get_ticks_msec()-started<=90000,"one native live journey bounded ninety seconds")
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"errors":failures,"images":images,"width":width,"height":height,"engine":Engine.get_version_info(),"elapsed_ms":Time.get_ticks_msec()-started,"user_data":user_dir,"save_calls":model.saves if model!=null else 0,"load_calls":model.loads if model!=null else 0,"orphan_before":orphan_before,"orphan_after":orphan_after,"orphan_growth":orphan_after-orphan_before,"live_commits":live_evidence,"modal_lifecycle":modal_evidence,"method":"genuine current C27 band and original live/practice oracles; inherited native Input/once-pressed/ALL-clipping; real Menu/Continue/write/day/modal/resize; source pinned by external runner; no device claim"}
 var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null: push_error("S46_LIVE_CAPTURE could not write result");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close()
 print("S46_LIVE_CAPTURE_RESULT ",JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
