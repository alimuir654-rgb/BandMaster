extends "res://experiments/playable_flightcase/career_capture.gd"
## SCRATCH S49. Root alone executes exact copied source with fresh XDG data.
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Review = preload("res://experiments/playable_flightcase/review_policy.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const S49_SAFE_ROOT := "/workspace/work/business/s49/"
var review_evidence: Array = []
var first_poor_record: Dictionary = {}

func expected_snapshot(before: Dictionary, career: Dictionary) -> Dictionary:
 var expected: Dictionary = before.duplicate(true)
 expected["game"]["career"]=career.duplicate(true)
 return expected

func expected_live(verb: String, choice: String="") -> Dictionary:
 var before: Dictionary = model.game.career.duplicate(true)
 var disk: Dictionary = files()
 var result: Dictionary = Live.resolve(before,verb,choice,false)
 if not verify(before==model.game.career and files()==disk,"pure current live/review oracle never mutates live career or files"): return {"ok":false}
 if not bool(result.get("ok",false)): return result
 var accounted: Dictionary = Finance.apply(before,result["state"],"live:"+verb)
 if not bool(accounted.get("ok",false)): return accounted
 result["state"]=accounted["state"]
 if str(result.get("message","")).is_empty():result["message"]=str(Night.stage(result["state"]).get("detail","The next stage is ready."))
 return result

func spawn_owner(reduced: bool=false) -> void:
 screen=RootUI.new()
 screen.name="S49ReviewActualNativeQA"
 screen.setup=model
 screen.showing_menu=false
 screen.reduced_motion=reduced
 root.add_child(screen)
 await frames(4)

func wait_practice_idle() -> bool:
 var until: int = Time.get_ticks_msec()+5000
 while Time.get_ticks_msec()<until:
  if practice()!=null and not bool(practice().get("session_busy")):
   await frames(3)
   return true
  await process_frame
 return verify(false,"actual practice presentation finishes within five seconds")

func open_live() -> bool:
 if desk()==null or not desk().is_visible_in_tree():
  if not await free_action("CareerDeskAction"): return false
 if str(desk().get("page"))=="gigs": return true
 if str(desk().get("page"))!="home":
  if not await free_action("CareerNav_home"): return false
 if not await free_action("CareerHomeLiveAction"): return false
 return verify(str(desk().get("page"))=="gigs","genuine Home route opens current saved live desk")

func choose_offer(id: String, method: String="pointer") -> bool:
 if not await free_action("LiveOffer_"+id,method): return false
 return verify(str(desk().get("live_offer"))==id,"actual current selected promoter plan is "+id)

func choose_approach(id: String) -> bool:
 if not await free_action("LiveApproach_"+id,"enter"): return false
 return verify(str(desk().get("live_approach"))==id,"genuine free soundcheck plan is "+id)

func saved_roundtrip(label: String) -> bool:
 var before: Dictionary = guard()
 var expected: Dictionary = model.snapshot().duplicate(true)
 expected["game"]["career"]=model.game._restore_integral_numbers(expected["game"]["career"])
 var loaded = Model.new()
 if not verify(loaded.load_draft() and loaded.snapshot()==expected,"actual full C27 disk roundtrip "+label): return false
 return unchanged(before,"independent saved load "+label)

func effective_clip(control: Control) -> Rect2:
 var area: Rect2 = Rect2(Vector2.ZERO,Vector2(root.size))
 var ancestor: Node = control.get_parent()
 while ancestor!=null:
  if ancestor is Control and (ancestor as Control).clip_contents:
   var clip: Rect2 = (ancestor as Control).get_global_rect()
   if ancestor is ScrollContainer:
    var scroll: ScrollContainer = ancestor as ScrollContainer
    var horizontal: HScrollBar = scroll.get_h_scroll_bar()
    var vertical: VScrollBar = scroll.get_v_scroll_bar()
    if horizontal.is_visible_in_tree():clip.size.y=maxf(0.0,minf(clip.end.y,horizontal.get_global_rect().position.y)-clip.position.y)
    if vertical.is_visible_in_tree():clip.size.x=maxf(0.0,minf(clip.end.x,vertical.get_global_rect().position.x)-clip.position.x)
   area=area.intersection(clip)
  ancestor=ancestor.get_parent()
 return area

func native_read_receipt(note: Label, tag: String) -> bool:
 var before: Dictionary = guard()
 var scroll: ScrollContainer = named("CareerScroll") as ScrollContainer
 if not verify(scroll!=null and note!=null,"long saved receipt uses actual native scroll and full Label"): return false
 var bar: VScrollBar = scroll.get_v_scroll_bar()
 if bar.is_visible_in_tree() and bar.max_value>bar.page:
  if bar.has_focus():await key(KEY_TAB,true)
  for attempt in range(64):
   if bar.has_focus():break
   await key(KEY_TAB)
  if not verify(bar.has_focus() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bar.get_global_rect()),"genuine Tab reaches rendered receipt scrollbar"): return false
  await key(KEY_END)
  await frames(3)
  if not verify(scroll.scroll_vertical==roundi(bar.max_value-bar.page),"genuine End reads actual receipt content end"): return false
  var rect: Rect2 = note.get_global_rect()
  var last_line_edge: Rect2 = Rect2(Vector2(rect.position.x,rect.end.y-1.0),Vector2(rect.size.x,1.0))
  if not verify(effective_clip(note).encloses(last_line_edge),"native End reveals the saved full note's final line inside all clips"): return false
  if not tag.is_empty() and not await capture(tag+"-reading-end"): return false
  await key(KEY_HOME)
  await frames(3)
  if not verify(scroll.scroll_vertical==0,"genuine Home restores saved receipt start"): return false
 return unchanged(before,"actual native receipt reading")

func note_content_rect(note: Label) -> Rect2:
 var rect: Rect2 = note.get_global_rect()
 var ancestor: Node = note.get_parent()
 while ancestor!=null:
  if ancestor is ScrollContainer:
   var scroll: ScrollContainer = ancestor as ScrollContainer
   rect.position+=Vector2(scroll.scroll_horizontal,scroll.scroll_vertical)
  ancestor=ancestor.get_parent()
 return rect

func complete_receipt(before: Dictionary, expected: Dictionary, tag: String="", natural: bool=false) -> bool:
 if not await wait_receipt(): return false
 var note: Label = named("CareerReceiptNote") as Label
 var next_action: Button = named("CareerReceiptContinueAction") as Button
 var receipt: Dictionary = desk().get("receipt")
 if not verify(note!=null and note.text==str(expected["message"]) and note.get_theme_font_size("font_size")>=16 and note.visible_characters_behavior==TextServer.VC_CHARS_AFTER_SHAPING,"actual partial note retains exact full original-plus-factual-review text and native16px shaping"): return false
 if not verify(next_action!=null and inside(next_action) and next_action.size.y>=48 and int(receipt.day_before)==int(before.tour_day) and int(receipt.day_after)==int(expected.state.tour_day) and int(receipt.cash_before)==int(before.cash) and int(receipt.cash_after)==int(expected.state.cash),"fixed native Continue and receipt cash/day match one saved action"): return false
 var protected: Dictionary = guard()
 var full: String = note.text
 var rect: Rect2 = note_content_rect(note)
 var global_before: Rect2 = note.get_global_rect()
 var footer_rect: Rect2 = next_action.get_global_rect()
 if not tag.is_empty() and not await capture(tag+"-partial"): return false
 if natural:
  var until: int = Time.get_ticks_msec()+4500
  while bool(note.call("is_revealing")) and Time.get_ticks_msec()<until:await process_frame
 else:
  # Actual automatically restored note focus or bounded native Tab only. A long
  # text Label need not fit wholly inside its legitimate scrolling container.
  for attempt in range(64):
   if note.has_focus():break
   await key(KEY_TAB)
  if not verify(note.has_focus(),"real native focus reaches current saved Ink note"): return false
  await key(KEY_SPACE)
 review_evidence.append({"case":"saved note reserved content geometry","tag":tag,"global_before":str(global_before),"global_after":str(note.get_global_rect()),"content_before":str(rect),"content_after":str(note_content_rect(note)),"fixed_continue_before":str(footer_rect),"fixed_continue_after":str(next_action.get_global_rect())})
 if not verify(not bool(note.call("is_revealing")) and note.visible_characters==-1 and note.text==full and note_content_rect(note)==rect and next_action.get_global_rect()==footer_rect and inside(next_action),"natural/local-Space completion preserves full text, reserved content geometry and fixed Continue through native scrolling"): return false
 if not unchanged(protected,"saved note completion never advances/spends/saves"): return false
 if not tag.is_empty() and not await capture(tag+"-full"): return false
 if not await native_read_receipt(note,tag): return false
 return await saved_roundtrip("after actual live receipt")

func finish_receipt() -> bool:
 if not await free_action("CareerReceiptContinueAction","enter"): return false
 await frames(4)
 return verify(not bool(desk().get("receipt_open")) and str(desk().get("page"))=="gigs","actual Continue returns to live desk without another settlement")

func commit_live(verb: String, choice: String="", tag: String="") -> bool:
 var before: Dictionary = guard()
 var expected: Dictionary = expected_live(verb,choice)
 if not verify(bool(expected.get("ok",false)),"current original live/review/finance command permits "+verb): return false
 if not await activate("LiveMainAction"): return false
 if not verify(model.snapshot()==expected_snapshot(before.snapshot,expected.state) and model.saves==int(before.saves)+1 and model.loads==before.loads,"one actual live input commits exact original/review/finance state once: "+verb): return false
 if not await complete_receipt(before.snapshot.game.career,expected,tag) or not await finish_receipt(): return false
 return verify(model.saves==int(before.saves)+1,"live presentation/reading/Continue never re-saves: "+verb)

func commit_practice(kind: String) -> bool:
 var before: Dictionary = guard()
 var original = Game.new()
 if not verify(original.restore(model.game.snapshot()),"original practice oracle restores exact current game"): return false
 var pane: Control = practice()
 var result: Dictionary
 if kind=="create":
  result=original.write_session(str(Workshop.IDEAS[int(pane.get("idea_index"))]),str(Workshop.FORMS[int(pane.get("form_index"))]),str(pane.get("song_title")),int(pane.get("leader_index")))
 else:result=original.rehearse()
 if not verify(bool(result.get("ok",false)),"original resolver permits actual "+kind): return false
 var posted: Dictionary = Live.after_practice(before.snapshot.game.career,original.career)
 var expected: Dictionary = Finance.apply(before.snapshot.game.career,posted,"practice:"+kind)
 if not verify(bool(expected.get("ok",false)),"actual practice expectation reconciles finance"): return false
 if not await activate("WriteAction" if kind=="create" else "RehearseAction") or not await wait_practice_idle(): return false
 if not verify(model.snapshot()==expected_snapshot(before.snapshot,expected.state) and model.saves==int(before.saves)+1,"one genuine "+kind+" applies exact original effect and saves once"): return false
 review_evidence.append({"kind":"GENUINE native practice","action":kind,"before":before.snapshot.game.career,"after":model.game.career.duplicate(true),"save_delta":1})
 if not await free_action("RecapToggleAction") or not await wait_practice_idle(): return false
 return verify(model.saves==int(before.saves)+1,"practice Continue adds no second save")

func prepare_first_show() -> bool:
 if not await open_live() or not await choose_offer("standard") or not await commit_live("book","standard"): return false
 if not await free_action("LiveWriteAction") or not await wait_practice_idle(): return false
 if not await free_action("PracticeMode_create") or not await type_pending_title(): return false
 for index in range(3):
  if not await commit_practice("create"): return false
 if not verify(int(model.game.career.songs)==1 and int(model.game.career.tour_day)==4 and Live.show_day(model.game.career),"three genuine writes finish one original and reach first scheduled showday4"): return false
 if not await open_live() or not await commit_live("advance") or not await choose_approach("wild") or not await commit_live("soundcheck","wild"): return false
 return verify(str(Night.stage(model.game.career).phase)=="stage","actual arrival and chosen WILD soundcheck reach the stage")

func perform_once(want_success: bool, tag: String) -> bool:
 var before: Dictionary = guard()
 var expected: Dictionary = expected_live("perform")
 if not verify(bool(expected.get("ok",false)),"current exact performance oracle succeeds before actual confirm"): return false
 var history: Array = expected.state.get("gig_history",[])
 if not verify(not history.is_empty() and bool(history.back().success)==want_success,"UNEXECUTED oracle must predict intended poor/good outcome before committing; change method if not"): return false
 if not await free_action("LiveMainAction"): return false
 var dialog: Control = desk().get("_live_dialog") as Control
 if not verify(dialog!=null and bool(dialog.get("is_open")),"actual stage confirmation modal opens before any settlement"): return false
 var callbacks: Array = []
 dialog.completed.connect(func(value: bool):callbacks.append(value))
 if not await settled(named("LiveConfirmAction")): return false
 var point: Vector2 = named("LiveConfirmAction").get_global_rect().get_center()
 if not await activate("LiveConfirmAction","enter"): return false
 await pointer(point)
 if not verify(callbacks==[true] and model.snapshot()==expected_snapshot(before.snapshot,expected.state) and model.saves==int(before.saves)+1,"real confirmation plus repeated physical pointer settle one original show/review/finance/save"): return false
 if not await complete_receipt(before.snapshot.game.career,expected,tag,not want_success) or not await finish_receipt(): return false
 review_evidence.append({"kind":"GENUINE paid original performance","scheduled_day":before.snapshot.game.career.booked_show.day,"completed_day":model.game.career.tour_day,"success":want_success,"review":Review.latest(model.game.career),"callbacks":callbacks,"save_delta":1})
 return true

func check_review(success: bool, sequence: int) -> bool:
 var before: Dictionary = guard()
 var data: Dictionary = Review.view(model.game.career)
 var record: Dictionary = Review.latest(model.game.career)
 var history: Array = model.game.career.get("gig_history",[])
 if not verify(bool(Review.validate(model.game.career).ok) and int(data.seq)==sequence and data.records.size()==sequence and history.size()==sequence and not record.is_empty(),"saved validated review and original show counts agree"): return false
 if not verify(bool(record.success)==success and int(record.seq)==sequence and int(record.settled_fee)==int(history.back().fee) and int(record.completed_day)==int(history.back().day) and int(record.scheduled_day)==(4 if sequence==1 else 8) and int(data.seen_ids[record.id])==sequence,"review facts reference actual settled fee/history and distinct scheduled/completed days"): return false
 for pair in [["LiveReviewHeadline","headline"],["LiveReviewBody","body"]]:
  var label: Label = named(str(pair[0])) as Label
  if not verify(label!=null and label.text==str(record[str(pair[1])]) and label.get_theme_font_size("font_size")>=16,"actual native saved review copy equals persisted fact record: "+str(pair[0])): return false
 var recovery: Label = named("LiveReviewRecovery") as Label
 var policy: Dictionary = Review.eligibility(model.game.career,"local","guarantee")
 if not verify(recovery!=null and recovery.text==str(policy.recovery),"native recovery copy comes from current pure eligibility policy"): return false
 if sequence==1:first_poor_record=record.duplicate(true)
 elif not verify(data.records[0]==first_poor_record,"successful later show preserves original poor report unchanged"):return false
 return unchanged(before,"read-only review facts and labels")

func menu_reload() -> bool:
 var before: Dictionary = guard()
 if not await activate("CareerMenuAction") or not unchanged(before,"review Menu"): return false
 if not await activate("ContinueAction"): return false
 await frames(5)
 if not unchanged(before,"actual saved review Continue",1): return false
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice_idle():return false
 return await open_live()

func paused_offer_and_recovery() -> bool:
 if not check_review(false,1) or not await menu_reload() or not check_review(false,1): return false
 if not await choose_offer("guarantee","space"): return false
 var before: Dictionary = guard()
 var eligible: Dictionary = Live.booking_eligibility(model.game.career,false,"guarantee")
 var status: Label = named("LiveReviewStatus") as Label
 if not verify(not bool(eligible.ok) and bool(Review.eligibility(model.game.career,"local","guarantee").restricted) and status!=null and status.text==str(eligible.message) and inside(status) and status.get_theme_font_size("font_size")>=16,"selected paused GUARANTEE has exact current policy reason beside fixed action"): return false
 var main: Button = named("LiveMainAction") as Button
 if not verify(main!=null and main.disabled,"new GUARANTEE restriction disables only its committing action"): return false
 if not await activate("LiveMainAction","pointer",true) or not unchanged(before,"genuine disabled GUARANTEE click spends/saves nothing"): return false
 if not await capture("review-poor-guarantee-paused"): return false
 for offer in ["guestlist","standard"]:
  if not await choose_offer(str(offer),"enter"):return false
  if not verify(bool(Live.booking_eligibility(model.game.career,false,str(offer)).ok) and not (named("LiveMainAction") as Button).disabled,"poor show preserves original eligible recovery offer "+str(offer)):return false
 if not await commit_live("book","standard"):return false
 if not await free_action("LiveRehearseAction") or not await wait_practice_idle():return false
 if not await free_action("PracticeMode_tighten"):return false
 for index in range(3):
  if not await commit_practice("tighten"):return false
  var data: Dictionary = Review.view(model.game.career)
  if not verify(int(data.seq)==1 and int(data.last_poor_seq)==1 and int(data.last_success_seq)==0 and bool(Review.eligibility(model.game.career,"local","guarantee").restricted),"genuine rehearsal alone NEVER restores GUARANTEE confidence"):return false
 if not verify(int(model.game.career.tour_day)==8 and Live.show_day(model.game.career),"three actual paid rehearsals reach the second showday8"):return false
 if not await open_live() or not await commit_live("advance") or not await choose_approach("tight") or not await commit_live("soundcheck","tight"):return false
 if not await perform_once(true,"review-success-note") or not check_review(true,2):return false
 if not await menu_reload() or not check_review(true,2) or not await choose_offer("guarantee","space"):return false
 var status_after: Label = desk().find_child("LiveReviewStatus",true,false) as Label
 if not verify(bool(Live.booking_eligibility(model.game.career,false,"guarantee").ok) and not (named("LiveMainAction") as Button).disabled and status_after!=null and not status_after.visible,"only an actual settled successful show restores GUARANTEE and hides stale paused status"):return false
 if not await capture("review-success-guarantee-restored"):return false
 # Real final booking proves the restored plan reaches the original resolver;
 # it is not inferred solely from a presentation label.
 if not await commit_live("book","guarantee"):return false
 if not verify(str(model.game.career.promoter_offer.offer_id)=="guarantee" and (model.game.career.gig_history as Array).size()==2 and int(Review.view(model.game.career).seq)==2,"restored GUARANTEE books genuinely without inventing another performance or review"):return false
 return await capture("review-restored-guarantee-booked")

func journey() -> bool:
 if not await prepare_first_show() or not await perform_once(false,"review-poor-note"):return false
 return await paused_offer_and_recovery()

func run() -> void:
 var started: int = Time.get_ticks_msec()
 if output=="/workspace/work/unify/s45/career-capture":output=S49_SAFE_ROOT+"native"
 var user_dir: String = ProjectSettings.globalize_path("user://")
 var output_path: String = ProjectSettings.globalize_path(output)
 var safe: bool = verify(user_dir.begins_with(S49_SAFE_ROOT) and output_path.begins_with(S49_SAFE_ROOT),"strict fresh S49 XDG/output guard")
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated save path "+path) and safe
 if not safe:
  print("S49_REVIEW_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}));quit(1);return
 output=output_path
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create S49 scratch capture directory"):quit(1);return
 protected_initial=files(true)
 root.size=Vector2i(width,height)
 DisplayServer.window_set_size(root.size)
 root.grab_focus()
 await frames(4)
 var orphan_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 deadline=started+150000
 if make_fixture():
  await spawn_owner(false)
  await journey()
 if not failures.is_empty() and is_instance_valid(screen):await capture("FIRST-FAILURE")
 if is_instance_valid(screen):screen.free()
 screen=null
 await frames(4)
 var orphan_after: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 verify(files(true)==protected_initial,"all genuine review cases preserve original legacy/C26 save files")
 verify(orphan_after<=orphan_before,"native review trees have no orphan growth")
 var result: Dictionary = {"pass":failures.is_empty(),"checks":checks,"errors":failures,"width":width,"height":height,"images":images,"engine":Engine.get_version_info(),"user_data":user_dir,"elapsed_ms":Time.get_ticks_msec()-started,"orphan_before":orphan_before,"orphan_after":orphan_after,"evidence":review_evidence,"method":"Genuine original C27 trio, real STANDARD booking and3actualwrites; WILD poor performance; disabled GUARANTEE with visible exact reason; STANDARD recoverybooking+3actualpaidrehearsals stillrestricted; actualTIGHT successfulshow restoresGuarantee; genuine restoredbooking. All expected mutations use actual original/currentLive plusFinance; true isolateddisk save/load; no seeded scores/reviews/songs/readiness or model-prepared successfulshow."}
 var receipt = FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:push_error("S49_REVIEW could not write result");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close()
 print("S49_REVIEW_RESULT ",JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
