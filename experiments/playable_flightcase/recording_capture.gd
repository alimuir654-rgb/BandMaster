extends "res://experiments/playable_flightcase/career_capture.gd"
## SCRATCH S54 native integration. Root alone copies/runs an exact runtime.
## --baseline uses only the old canonical Songbook and no new static preload.
const S54_ROOT := "/workspace/work/overnight-20261101/s54/"
const OriginalRecording = preload("res://Scripts/recording_career.gd")
var rules: Variant
var trace: Array = []
var baseline_only := false
var fixture_snapshot: Dictionary = {}
var old_mouse_emulation := false
var old_touch_emulation := false

func verify(ok: bool, message: String) -> bool:
 checks += 1
 if not ok:
  failures.append(message)
  push_error("S54_RECORDING_NATIVE "+message)
 return ok

func wait_desk() -> bool:
 var until: int=mini(deadline,Time.get_ticks_msec()+4500)
 while Time.get_ticks_msec()<until:
  if desk()!=null and not bool(desk().get("busy")) and not is_instance_valid(desk().get("_overlay")):
   await frames(3)
   return true
  await process_frame
 return verify(false,"actual recording transition releases busy within4.5 seconds")

func wait_practice() -> bool:
 var acknowledged: Dictionary={}
 var until: int=mini(deadline,Time.get_ticks_msec()+4500)
 while Time.get_ticks_msec()<until:
  var beat: Control=named("SessionTransition")
  if beat!=null and str(beat.get("focus_kind"))=="day" and not bool(beat.get("_closing")):
   var identity: int=beat.get_instance_id()
   if not acknowledged.has(identity) and named("SkipSessionBeatAction")!=null:
    acknowledged[identity]=true
    if not await free_action("SkipSessionBeatAction"):return false
  if practice()!=null and not bool(practice().get("session_busy")):
   await frames(3)
   return true
  await process_frame
 return verify(false,"actual held DAY is acknowledged before practice navigation")

func prepare_catalogue() -> bool:
 if not make_fixture():return false
 # Explicit original-model setup ONLY: twelve writes are NOT native UI claims.
 for song in range(4):
  for step in range(3):
   var result: Dictionary=model.game.write_session(str(Workshop.IDEAS[song%3]),str(Workshop.FORMS[song%3]),"QA RECORDING ORIGINAL %d" % [song+1],song%3)
   if not fixture_step("original model write %d/%d" % [song+1,step+1],result):return false
 if not verify(model.game.career.song_catalogue.size()==4 and int(model.game.career.tour_day)==13 and int(model.game.career.cash)==250,"same four real originals/day13/cash250 fixture, no direct clock/budget edits"):return false
 if not fixture_step("save exact original-model catalogue before owner UI",model.save_draft()):return false
 fixture_snapshot=model.snapshot().duplicate(true)
 trace.append({"kind":"explicit fixture, not native writing","original_model_write_calls":12,"snapshot":fixture_snapshot,"snapshot_sha256":JSON.stringify(fixture_snapshot).sha256_text()})
 return true

func continue_saved_owner() -> bool:
 screen=RootUI.new()
 screen.name="S54RecordingActualNativeQA"
 screen.setup=model
 screen.showing_menu=true
 screen.reduced_motion=not OS.get_cmdline_user_args().has("--normal")
 root.add_child(screen)
 await frames(4)
 var before: Dictionary=guard()
 if not await activate("ContinueAction","enter"):return false
 if not unchanged(before,"real initial menu Continue",1) or not await wait_practice():return false
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice():return false
 practice_id=practice().get_instance_id() if practice()!=null else 0
 if not await free_action("CareerDeskAction"):return false
 if not verify(desk()!=null and desk().get("game")==model.game,"owner Career shares actual restored game"):return false
 return await free_action("CareerNav_songs","enter")

func open_recording() -> bool:
 if not verify(named("CareerRecordingAction")!=null,"Songs fixed decision dock exposes actual CUT A DEMO entry"):return false
 if not await settled(named("CareerRecordingAction")) or not await free_action("CareerRecordingAction"):return false
 return verify(str(desk().get("page"))=="recording","real Songbook action opens owned recording page")

func full_snapshot(career: Dictionary, before: Dictionary) -> Dictionary:
 var expected: Dictionary=before.duplicate(true)
 expected["game"]["career"]=career.duplicate(true)
 return expected

func song_key(id: String) -> String:
 return id.replace(":","_")

func draft_ids() -> Array:
 return desk().get("recording_ids").duplicate()

func initial_recording_fold() -> bool:
 if width!=390:return true
 var first: Button=named("RecordingSong_original_1") as Button
 var scroll: ScrollContainer=named("CareerScroll") as ScrollContainer
 # No Tab, scroll, ensure-visible or input before this FIRST-FOLD measurement.
 if not verify(first!=null and scroll!=null and scroll.scroll_vertical==0,"initial phone recording plan starts at top with actual first original"):return false
 return await settled(first) and verify(inside(first) and first.size.x>=48 and first.size.y>=48,"initial phone first ADD is wholly inside every clip at physical48")

func selected_order_context() -> bool:
 var before: Dictionary=guard()
 var scroll: ScrollContainer=named("CareerScroll") as ScrollContainer
 if not verify(scroll!=null,"selected-order context uses actual CareerScroll"):return false
 var bar: VScrollBar=scroll.get_v_scroll_bar()
 if bar.is_visible_in_tree() and bar.max_value>bar.page:
  for attempt in range(64):
   if bar.has_focus():break
   await key(KEY_TAB)
  if not verify(bar.has_focus() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bar.get_global_rect()) and scroll.get_global_rect().encloses(bar.get_global_rect()),"genuine Tab reaches actual selected-order scrollbar chrome"):return false
  await key(KEY_HOME)
  if not verify(bar.has_focus() and scroll.scroll_vertical==0,"genuine Home restores selected-order context at zero"):return false
 else:
  if not verify(scroll.scroll_vertical==0,"nonoverflowing selected-order context already starts at zero"):return false
 await frames(3)
 await RenderingServer.frame_post_draw
 var prior_y: float=-INF
 var selected: Array=draft_ids()
 var facts: Array=[]
 for index in range(selected.size()):
  var title: Label=named("RecordingTitle_"+song_key(str(selected[index]))) as Label
  if not verify(title!=null and title.text.begins_with("%d. " % [index+1]) and title.get_global_rect().position.y>prior_y,"actual native titles follow exact selected draft order: "+str(selected[index])):return false
  prior_y=title.get_global_rect().position.y
  facts.append({"id":selected[index],"label_text":title.text,"global_rect":str(title.get_global_rect()),"inside":inside(title)})
 if not verify(not selected.is_empty() and inside(named("RecordingTitle_"+song_key(str(selected[0])))),"first selected title is actually visible in restored context"):return false
 trace.append({"case":"actual selected order after native Tab/Home","scroll_vertical":scroll.scroll_vertical,"draft_ids":selected,"native_titles":facts})
 return await capture("recording-selected-order-context") and unchanged(before,"real Tab/Home selected-order context")

func select_and_resize() -> bool:
 var before: Dictionary=guard()
 var catalogue: Array=rules.songs(model.game.career)
 if not verify(catalogue.size()==4,"all four actual IDs available for selection"):return false
 var selected: Array=[]
 for index in range(3):
  var id: String=str(catalogue[index].id)
  if not await free_action("RecordingSong_"+song_key(id),"pointer" if index%2==0 else "enter"):return false
  selected.append(id)
  if not verify(draft_ids()==selected,"native add follows exact song identity/order"):return false
 var fourth: String="RecordingSong_"+song_key(str(catalogue[3].id))
 if not await activate(fourth,"enter",true) or not unchanged(before,"three-song selection cap"):return false
 if not verify(draft_ids()==selected,"disabled fourth choice cannot alter selected IDs"):return false
 if not await free_action("RecordingDown_"+song_key(str(selected[0])),"space"):return false
 selected=[selected[1],selected[0],selected[2]]
 if not verify(draft_ids()==selected,"actual DOWN swaps exact full song IDs"):return false
 # Exercise legal two-track selection, then restore three with actual controls.
 var last: String=str(selected[2])
 if not await free_action("RecordingSong_"+song_key(last),"enter"):return false
 if not verify(draft_ids()==selected.slice(0,2) and bool(rules.preview(model.game.career,draft_ids()).get("ok",false)),"two original tracks form a valid unsaved plan"):return false
 if not await free_action("RecordingSong_"+song_key(last),"space"):return false
 if not verify(draft_ids()==selected,"re-added third original restores exact selected order"):return false
 var owner_id: int=desk().get_instance_id()
 var original: Vector2i=root.size
 var alternate: Vector2i=Vector2i(1280,720) if original.x<900 else Vector2i(390,844)
 for size in [alternate,original]:
  root.size=size;DisplayServer.window_set_size(size);await frames(5)
  if not verify(desk()!=null and desk().get_instance_id()==owner_id and draft_ids()==selected,"real resize retains owner and selected ID order"):return false
  if not await settled(named("RecordingMainAction")) or not check_fixed_layout() or not unchanged(before,"free recording draft real resize"):return false
  if not await capture("recording-plan-resized" if size==alternate else "recording-plan"):return false
 if width==390:
  screen.set_meta("safe_area_test_sample",{"screen_safe_rect":Rect2(0,28,width,height-52),"viewport_to_screen":Transform2D.IDENTITY})
  screen.call("_refresh_safe_area")
  await frames(5)
  var safe_rect: Rect2=Rect2(0,28,width,height-52)
  var primary: Control=named("RecordingMainAction")
  if not await settled(primary) or not verify(safe_rect.encloses(primary.get_global_rect()) and safe_rect.encloses(named("CareerDecisionDock").get_global_rect()),"simulated camera28/navigation24 safe area contains actual recording footer"):return false
  if not verify((named("CareerScroll") as Control).size.y>0 and draft_ids()==selected,"safe reflow keeps positive content and exact unsaved plan"):return false
  if not check_fixed_layout() or not unchanged(before,"engine safe-inset fixture, not physical-device verification") or not await capture("recording-plan-safe-insets"):return false
  screen.remove_meta("safe_area_test_sample");screen.call("_refresh_safe_area");await frames(5)
  if not unchanged(before,"safe inset reset") or not await settled(named("RecordingMainAction")):return false
 return await selected_order_context()

func native_touch(id: String) -> bool:
 var button: Button=named(id) as Button
 if not verify(button!=null,"actual native touch target exists"):return false
 if not inside(button) and not await tab_to(button):return false
 if not await settled(button) or not text_fits(button):return false
 var presses: Array[int]=[0]
 var counter: Callable=func():presses[0]+=1
 button.pressed.connect(counter)
 var point: Vector2=button.get_global_rect().get_center()
 for down in [true,false]:
  var event:=InputEventScreenTouch.new()
  event.window_id=root.get_window_id();event.index=54;event.position=point;event.pressed=down
  Input.parse_input_event(event);await process_frame
 if is_instance_valid(button) and button.pressed.is_connected(counter):button.pressed.disconnect(counter)
 return verify(presses[0]==1,"indexed ScreenTouch produces exactly one native recording callback")

func finish_receipt(tag: String) -> bool:
 if not await wait_desk():return false
 var note: Label=named("CareerReceiptNote") as Label
 if not verify(note!=null and named("CareerReceiptContinueAction")!=null,"record/release receipt has actual native note and fixed Continue"):return false
 var before: Dictionary=guard()
 var text: String=note.text
 var size_before: Vector2=note.size
 var continue_rect: Rect2=named("CareerReceiptContinueAction").get_global_rect()
 if not verify(text==str(desk().get("receipt").get("text","")) and note.get_theme_font_size("font_size")>=16,"complete recorded original text uses readable native note"):return false
 if not bool(screen.reduced_motion):
  if not verify(note.has_method("is_revealing") and bool(note.call("is_revealing")),"normal fresh recording receipt actually reveals after saved transition"):return false
  var partial_until: int=mini(deadline,Time.get_ticks_msec()+450)
  await RenderingServer.frame_post_draw
  while note.visible_characters<=0 and bool(note.call("is_revealing")) and Time.get_ticks_msec()<partial_until:await process_frame
  if not verify(note.visible_characters>0 and note.visible_characters<text.length() and bool(note.call("is_revealing")),"normal saved note has actual visible partial text before local completion"):return false
  trace.append({"case":"normal saved recording note partial","tag":tag,"visible_characters":note.visible_characters,"full_text":text,"font_size":note.get_theme_font_size("font_size"),"content_size":str(note.size)})
  if not await capture(tag+"-partial"):return false
 if not await capture(tag+"-initial"):return false
 if note.has_method("is_revealing") and bool(note.call("is_revealing")):
  if not await tab_to(note):return false
  await key(KEY_SPACE)
 if not verify(note.visible_characters==-1 and note.text==text and note.size==size_before and named("CareerReceiptContinueAction").get_global_rect()==continue_rect,"note completion keeps full authored text/content size and fixed Continue bounds"):return false
 if not await capture(tag+"-complete") or not unchanged(before,"recording receipt completion/capture"):return false
 if not await free_action("CareerReceiptContinueAction","enter"):return false
 await frames(4)
 return verify(str(desk().get("page"))=="recording" and str(desk().get("recording_mode"))=="archive","real receipt Continue opens saved recording archive")

func check_song_links(session: Dictionary, ids: Array, catalogue: Array) -> bool:
 var snapshots: Array=[]
 for id in ids:
  for song in catalogue:
   if str(song.id)==str(id):snapshots.append(song.duplicate(true))
 var expected: Dictionary={"version":1,"song_ids":ids.duplicate(),"snapshots":snapshots}
 return verify(session.get("song_links_v1")==expected and snapshots.size()==ids.size(),"archive owns exact ordered source IDs and FULL original creative snapshots")

func recording_commit() -> bool:
 var before: Dictionary=guard()
 var ids: Array=draft_ids()
 var catalogue: Array=model.game.career.song_catalogue.duplicate(true)
 var expected: Dictionary=rules.record(model.game.career,ids)
 if not verify(bool(expected.get("ok",false)) and expected.get("closing_balances")==[190,190] and str(expected.get("finance_action"))=="recording:record","pure selected-recording oracle accounts original £60/two days/one Finance"):return false
 if not unchanged(before,"pure recording oracle"):return false
 if width==390:
  if not recording_block_save(Model.SAVE_PATH):return false
  if not await activate("RecordingMainAction") or not await wait_desk():return false
  if not recording_assert_failed_save_rollback():return false
  if not await capture("recording-failed-save"):return false
  if not recording_restore_save() or not recording_assert_restored_files():return false
  if not verify(draft_ids()==ids,"failed save preserves current unsaved recording plan for one retry"):return false
  before=guard()
 var button: Button=named("RecordingMainAction") as Button
 if not await settled(button):return false
 var point: Vector2=button.get_global_rect().get_center()
 if not await activate("RecordingMainAction","enter"):return false
 if not verify(model.snapshot()==full_snapshot(expected.state,before.snapshot) and model.saves==int(before.saves)+1 and model.loads==before.loads,"one real recording input applies exact Rules/Finance state and one owner save"):return false
 await pointer(point)
 if not verify(model.snapshot()==full_snapshot(expected.state,before.snapshot) and model.saves==int(before.saves)+1,"rapid second native pointer cannot repeat paid record settlement"):return false
 var session: Dictionary=expected.session
 if not check_song_links(session,ids,catalogue) or not verify(model.game.career.song_catalogue==catalogue and int(model.game.career.cash)==190 and int(model.game.career.tour_day)==15,"record keeps entire creative catalogue and exact budget/day"):return false
 trace.append({"verb":"record","input":"Enter plus blocked rapid pointer","before":before.snapshot.game.career,"after":model.game.career.duplicate(true),"save_delta":model.saves-int(before.saves),"song_ids":ids,"session":session})
 if not await finish_receipt("recording-saved-receipt"):return false
 if not verify(rules.sessions(model.game.career).size()==1 and rules.sessions(model.game.career)[0]==session,"native archive reads exact durable session"):return false
 return await capture("recording-archive-unreleased")

func release_commit() -> bool:
 var before: Dictionary=guard()
 var session: Dictionary=rules.sessions(model.game.career)[0].duplicate(true)
 var expected: Dictionary=rules.release(model.game.career,str(session.id),rules.fingerprint(session),0)
 if not verify(bool(expected.get("ok",false)) and str(expected.get("finance_action"))=="recording:release","pure original release/Finance oracle allows exact selected archive row"):return false
 if not unchanged(before,"pure release oracle"):return false
 if not await native_touch("RecordingRelease_0"):return false
 if not verify(model.snapshot()==full_snapshot(expected.state,before.snapshot) and model.saves==int(before.saves)+1 and model.loads==before.loads,"one genuine touch releases exact recording, original fans/press and one save"):return false
 if not verify(int(model.game.career.cash)==165 and int(model.game.career.tour_day)==16 and expected.session.get("song_links_v1")==session.get("song_links_v1"),"£25/one day release keeps immutable full original identity snapshots"):return false
 trace.append({"verb":"release","input":"indexed ScreenTouch","before":before.snapshot.game.career,"after":model.game.career.duplicate(true),"save_delta":model.saves-int(before.saves),"session":expected.session})
 if not await finish_receipt("recording-release-receipt"):return false
 var released: Button=named("RecordingRelease_0") as Button
 if released!=null:
  var after: Dictionary=guard()
  if not verify(released.disabled,"already-released native action cannot settle again") or not await activate("RecordingRelease_0","pointer",true) or not unchanged(after,"disabled repeated release"):return false
 return await capture("recording-archive-released")

func reload_archive() -> bool:
 var before: Dictionary=guard()
 if not await free_action("CareerMenuAction") or not await activate("ContinueAction","enter"):return false
 if not unchanged(before,"real Menu/Continue reload after recording+release",1) or not await wait_practice():return false
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice():return false
 if not await free_action("CareerDeskAction") or not await free_action("CareerNav_songs") or not await open_recording() or not await free_action("RecordingArchiveAction","space"):return false
 if not verify(rules.sessions(model.game.career)==before.snapshot.game.career.recordings,"actual saved recording archive survives real Menu→Continue"):return false
 return await capture("recording-archive-reloaded")

func legacy_archive_fixture() -> bool:
 # Separate documented read-only migration fixture. Original module creates
 # actual title/quality row; no synthetic IDs, source links or creative history.
 var before: Dictionary=guard()
 var original_state: Dictionary=fixture_snapshot.game.career.duplicate(true)
 original_state["song_catalogue"]=original_state.song_catalogue.slice(0,3)
 var legacy_result: Dictionary=OriginalRecording.record(original_state)
 if not verify(bool(legacy_result.get("ok",false)),"protected original recording module prepares separate legacy title/quality row"):return false
 var legacy: Dictionary=legacy_result.state.recordings.back().duplicate(true)
 if not verify(not legacy.has("song_links_v1") and str(legacy.id)!=str(model.game.career.recordings[0].id),"legacy fixture has only its actual old identity, never fabricated song IDs"):return false
 model.game.career.recordings.append(legacy)
 if not fixture_step("save explicit separate legacy display fixture",model.save_draft()):return false
 trace.append({"kind":"EXPLICIT MODEL-PREPARED LEGACY ARCHIVE DISPLAY, not native record/release","row":legacy})
 if not await free_action("RecordingSelectAction") or not await free_action("RecordingArchiveAction"):return false
 var current: Dictionary=guard()
 var card: Control=named("RecordingSession_1")
 if not verify(card!=null,"original title-only legacy recording has native archive card"):return false
 var legacy_label: Label
 for raw in card.find_children("*","Label",true,false):
  var label: Label=raw as Label
  if label.text.to_upper().contains("LEGACY"):legacy_label=label
 if not verify(legacy_label!=null,"old title-only row is honestly labelled LEGACY"):return false
 if not inside(legacy_label) and not await tab_to(named("RecordingRelease_1")):return false
 if not await capture("recording-archive-legacy"):return false
 return unchanged(current,"legacy archive inspection/capture") and verify(model.game.career.recordings[0]==before.snapshot.game.career.recordings[0] and model.game.career.recordings[1]==legacy,"legacy inspection preserves both original row and new immutable snapshots")

func journey() -> bool:
 if not await continue_saved_owner():return false
 if baseline_only:return await capture("baseline-songbook")
 if not await capture("current-songbook"):return false
 if not await open_recording() or not await initial_recording_fold() or not await capture("recording-empty-plan"):return false
 if not await select_and_resize() or not await recording_commit() or not await release_commit() or not await reload_archive():return false
 return await legacy_archive_fixture()

func run() -> void:
 var started: int=Time.get_ticks_msec()
 deadline=started+108000
 baseline_only=OS.get_cmdline_user_args().has("--baseline")
 var user_dir: String=ProjectSettings.globalize_path("user://")
 var output_path: String=ProjectSettings.globalize_path(output)
 var safe: bool=verify([Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720),Vector2i(1600,900)].has(Vector2i(width,height)),"one of four actual native profiles")
 safe=verify(user_dir.begins_with(S54_ROOT) and output_path.begins_with(S54_ROOT),"strict fresh S54 userdata/output guard") and safe
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated actual save path "+path) and safe
 if not safe:print("S54_RECORDING_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}));quit(1);return
 output=output_path
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create S54 native output"):quit(1);return
 if not baseline_only:
  # This branch is deliberately after --baseline; old337 has no new module.
  rules=load("res://experiments/playable_flightcase/recording_rules.gd")
  if not verify(rules!=null,"actual candidate recording Rules load only for new journey"):quit(1);return
 old_mouse_emulation=Input.emulate_mouse_from_touch;old_touch_emulation=Input.emulate_touch_from_mouse
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=false
 protected_initial=files(true)
 root.size=Vector2i(width,height);DisplayServer.window_set_size(root.size);root.grab_focus();await frames(4)
 var orphan_before: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 if prepare_catalogue():await journey()
 if _recording_backup_pending:recording_restore_save()
 if not failures.is_empty() and is_instance_valid(screen):await capture("FIRST-FAILURE")
 if is_instance_valid(screen):screen.free()
 screen=null;await frames(4)
 Input.emulate_mouse_from_touch=old_mouse_emulation;Input.emulate_touch_from_mouse=old_touch_emulation
 var orphan_after: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 verify(files(true)==protected_initial,"all original legacy/C26 file byte states unchanged")
 verify(orphan_after<=orphan_before,"zero orphan growth after actual owner teardown")
 verify(Time.get_ticks_msec()-started<115000,"bounded proof below root120-second native runner")
 var result: Dictionary={"pass":failures.is_empty(),"baseline_only":baseline_only,"normal_motion":OS.get_cmdline_user_args().has("--normal"),"checks":checks,"errors":failures,"images":images,"width":width,"height":height,"elapsed_ms":Time.get_ticks_msec()-started,"engine":Engine.get_version_info(),"user_data":user_dir,"save_calls":model.saves if model!=null else 0,"load_calls":model.loads if model!=null else 0,"orphan_before":orphan_before,"orphan_after":orphan_after,"fixture_snapshot_sha256":JSON.stringify(fixture_snapshot).sha256_text(),"trace":trace,"method":"Same original C27+12 original-model-write four-song fixture; genuine initial Menu/Continue and Songs route. Candidate only: real add/remove/order, two/three selection, real window resize, phone safe-area engine fixture, £60/2-day record including real failed-save rollback/retry and rapid pointer, £25/day1 indexed-touch release, receipts/read/reload, separately labelled original-model legacy display. UI expectation uses pure Rules ALREADY Finance-accounted; no second Finance. No physical-device claim."}
 var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:push_error("S54_RECORDING_NATIVE cannot write result");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close();print("S54_RECORDING_NATIVE_RESULT ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
## SCRATCH S54 snippet, not a standalone SceneTree or gameplay journey.
## Paste at top level into the root-owned native probe. Requires model,
## verify(), guard(), files(protected_only=false), and S54_ROOT ending in '/'.
## Pass the actual inherited Model.SAVE_PATH; no hardcoded save filename.
## Root supplies genuine input, UI/receipt checks and the single native retry.
## Always call recording_restore_save() before every test exit/teardown,
## including when recording_block_save() returned false after renaming.
var _recording_save_absolute: String = ""
var _recording_backup_absolute: String = ""
var _recording_original_bytes := PackedByteArray()
var _recording_backup_pending: bool = false
var _recording_failure_before: Dictionary = {}
var _recording_protected_before: Dictionary = {}

func recording_restore_save() -> bool:
 if not _recording_backup_pending:return true
 if not verify(_recording_save_absolute.begins_with(S54_ROOT) and _recording_backup_absolute.begins_with(S54_ROOT),"recording save recovery is confined to fresh S54 scratch"):return false
 if not verify(FileAccess.file_exists(_recording_backup_absolute) and FileAccess.get_file_as_bytes(_recording_backup_absolute)==_recording_original_bytes,"original exact recording-fixture save bytes remain in backup"):return false
 if DirAccess.dir_exists_absolute(_recording_save_absolute):
  # This call refuses nonempty directories. Never recursively delete anything.
  if not verify(DirAccess.remove_absolute(_recording_save_absolute)==OK,"remove only deliberate EMPTY failed-save directory"):return false
 if not verify(not FileAccess.file_exists(_recording_save_absolute) and not DirAccess.dir_exists_absolute(_recording_save_absolute),"never overwrite an unexpected recording-save recovery destination"):return false
 if not verify(DirAccess.rename_absolute(_recording_backup_absolute,_recording_save_absolute)==OK,"rename exact original recording-fixture save back"):return false
 _recording_backup_pending=false
 return verify(FileAccess.get_file_as_bytes(_recording_save_absolute)==_recording_original_bytes,"actual original save bytes are restored before recording retry")

func recording_block_save(save_path: String) -> bool:
 if not verify(not _recording_backup_pending,"no unresolved recording save backup before failure injection"):return false
 _recording_save_absolute=ProjectSettings.globalize_path(save_path)
 _recording_backup_absolute=_recording_save_absolute+".s54-recording-probe-backup"
 if not verify(S54_ROOT.ends_with("/") and _recording_save_absolute.begins_with(S54_ROOT) and _recording_backup_absolute.begins_with(S54_ROOT),"block only a save path inside the exact S54 scratch boundary"):return false
 if not verify(FileAccess.file_exists(_recording_save_absolute) and not DirAccess.dir_exists_absolute(_recording_save_absolute),"recording failure fixture requires a real existing save file"):return false
 _recording_original_bytes=FileAccess.get_file_as_bytes(_recording_save_absolute)
 if not verify(not _recording_original_bytes.is_empty() and not FileAccess.file_exists(_recording_backup_absolute) and not DirAccess.dir_exists_absolute(_recording_backup_absolute),"preserve a nonempty original save and never overwrite a backup"):return false
 _recording_failure_before=guard().duplicate(true)
 _recording_protected_before=files(true).duplicate(true)
 if not verify(DirAccess.rename_absolute(_recording_save_absolute,_recording_backup_absolute)==OK,"preserve the exact original save before a real recording write failure"):return false
 _recording_backup_pending=true
 if not verify(DirAccess.make_dir_absolute(_recording_save_absolute)==OK,"real empty SAVE_PATH directory blocks actual FileAccess WRITE"):return false
 return verify(DirAccess.dir_exists_absolute(_recording_save_absolute),"recording write is blocked by an actual directory at SAVE_PATH")

func recording_assert_failed_save_rollback() -> bool:
 if not verify(_recording_backup_pending and not _recording_failure_before.is_empty(),"rollback observation has an active real save-failure fixture"):return false
 var before: Dictionary=_recording_failure_before
 var ok: bool=verify(model.snapshot()==before.snapshot,"failed recording save restores WHOLE original memory, including Finance and all song links")
 ok=verify(model.saves==int(before.saves)+1 and model.loads==before.loads,"one real failed recording action attempts exactly one owner save and no owner load") and ok
 ok=verify(files(true)==_recording_protected_before,"failed recording save leaves original legacy/C26 file byte states unchanged") and ok
 ok=verify(DirAccess.dir_exists_absolute(_recording_save_absolute) and FileAccess.file_exists(_recording_backup_absolute) and FileAccess.get_file_as_bytes(_recording_backup_absolute)==_recording_original_bytes,"failed recording write preserves its empty blocking directory and exact original backup bytes") and ok
 return ok

func recording_assert_restored_files() -> bool:
 if not verify(not _recording_backup_pending and not _recording_failure_before.is_empty(),"restored-file check follows actual save recovery"):return false
 return verify(files()==_recording_failure_before.files and FileAccess.get_file_as_bytes(_recording_save_absolute)==_recording_original_bytes,"all original save-file byte states are restored before the one native recording retry")
