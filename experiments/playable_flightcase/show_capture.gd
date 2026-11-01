extends "res://experiments/playable_flightcase/career_capture.gd"
## SCRATCH S53. Root alone copies and executes an exact runtime / ONE GL.
## Real Input only; no emitted UI signals or direct UI action-handler calls.
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Replay = preload("res://experiments/playable_flightcase/show_replay.gd")
const S53_ROOT := "/workspace/work/overnight-20261101/s53/"
var trace: Array = []
var save_absolute := ""
var backup_absolute := ""
var original_bytes := PackedByteArray()
var backup_pending := false
var old_mouse_emulation := false
var old_touch_emulation := false

func verify(ok: bool, message: String) -> bool:
 checks += 1
 if not ok:
  failures.append(message)
  push_error("S53_SHOW_NATIVE "+message)
 return ok

func expected_snapshot(before: Dictionary, career: Dictionary) -> Dictionary:
 var result: Dictionary=before.duplicate(true)
 result["game"]["career"]=career.duplicate(true)
 return result

func oracle(verb: String, choice: String="") -> Dictionary:
 var before: Dictionary=model.game.career.duplicate(true)
 var disk: Dictionary=files()
 var plan: Dictionary=desk().get("show_draft").duplicate(true) if verb=="soundcheck" else {}
 var result: Dictionary=Live.resolve(before,verb,choice,false,plan)
 if not verify(model.game.career==before and files()==disk,"pure UI-integration oracle preserves model and actual files"):return {"ok":false}
 if not bool(result.get("ok",false)):return result
 var accounted: Dictionary=Finance.apply(before,result["state"],"live:"+verb)
 if not bool(accounted.get("ok",false)):return accounted
 result["state"]=accounted["state"]
 return result

func check_fixed_layout() -> bool:
 if desk()==null or not desk().is_visible_in_tree():return true
 var managed: bool=Flow.managed(model.game.career) and str(desk().get("page"))=="gigs" and not bool(desk().get("receipt_open"))
 if not managed:return super.check_fixed_layout()
 # The new managed journey deliberately hides old CareerNavigation.
 var nav: Control=desk().find_child("CareerNavigation",true,false) as Control
 if not verify(nav!=null and not nav.visible,"managed show deliberately suppresses old navigation"):return false
 var dock: Control=named("CareerDecisionDock")
 if not verify(dock!=null,"actual managed fixed decision dock exists"):return false
 for raw in dock.find_children("*","Button",true,false):
  var button: Button=raw as Button
  if button.is_visible_in_tree():
   if not verify(inside(button) and button.size.x>=48 and button.size.y>=48,"managed fixed action stays physical48 and in ALL clips: "+str(button.name)) or not text_fits(button):return false
 if Flow.phase(model.game.career)=="soundcheck":
  for id in ["ShowApproachControl","ShowIntensityControl"]:
   var control: Control=named(id)
   if not verify(control!=null and inside(control) and control.size.x>=48 and control.size.y>=48,"original hardware stays wholly visible in fixed soundcheck housing"):return false
 return true

func wait_desk() -> bool:
 var until: int=mini(deadline,Time.get_ticks_msec()+4000)
 while Time.get_ticks_msec()<until:
  if desk()!=null and not bool(desk().get("busy")) and not is_instance_valid(desk().get("_overlay")):
   await frames(3)
   return true
  await process_frame
 return verify(false,"actual career presentation/phase releases busy within four seconds")

func wait_practice() -> bool:
 var acknowledged: Dictionary={}
 var until: int=mini(deadline,Time.get_ticks_msec()+4500)
 while Time.get_ticks_msec()<until:
  var beat: Control=named("SessionTransition")
  if beat!=null and str(beat.get("focus_kind"))=="day":
   var identity: int=beat.get_instance_id()
   if not acknowledged.has(identity) and not bool(beat.get("_closing")) and named("SkipSessionBeatAction")!=null:
    acknowledged[identity]=true
    if not await free_action("SkipSessionBeatAction","pointer"):return false
  if practice()!=null and not bool(practice().get("session_busy")):
   await frames(3)
   return true
  await process_frame
 return verify(false,"held DAY is acknowledged through actual action before practice idle")

func open_live() -> bool:
 if desk()==null or not desk().is_visible_in_tree():
  # Saved outcomes start expanded both initially and after genuine Continue.
  if named("RecapToggleAction")!=null:
   if not await free_action("RecapToggleAction") or not await wait_practice():return false
  if not await free_action("CareerDeskAction"):return false
 if str(desk().get("page"))!="gigs":
  if str(desk().get("page"))!="home" and not await free_action("CareerNav_home"):return false
  if not await free_action("CareerHomeLiveAction"):return false
 return verify(str(desk().get("page"))=="gigs" and desk().get("game")==model.game,"real current owner Home route opens same-band live desk")

func read_receipt(tag: String) -> bool:
 if not await wait_desk():return false
 var note: Label=named("CareerReceiptNote") as Label
 if not verify(note!=null and named("CareerReceiptContinueAction")!=null,"saved receipt has actual note and fixed Continue"):return false
 var receipt: Dictionary=desk().get("receipt")
 var data: Dictionary=receipt.get("show_receipt",{})
 var expected: String=str(data.get("message","")) if not data.is_empty() else str(receipt.get("text",""))
 if not verify(note.text==expected and note.get_theme_font_size("font_size")>=16,"receipt preserves full authored saved text with legible native font"):return false
 var before: Dictionary=guard()
 if not data.is_empty():
  for field in ["fans","reputation","morale","tension","readiness"]:
   var value: Label=named("ShowOutcome_"+str(field)) as Label
   var effect: Dictionary=data.get("effects",{}).get(field,{})
   if not verify(value!=null and inside(value) and value.get_theme_font_size("font_size")>=16 and value.text=="%s  %d → %d  (%+d)" % [str(field).to_upper(),int(effect.get("before",0)),int(effect.get("after",0)),int(effect.get("delta",0))],"saved exact factual effect is printed16 in first fold: "+str(field)):return false
  var cost: Label=named("ShowReceiptExpenses") as Label
  var expenses: Dictionary=data.get("expenses",{})
  if not verify(cost!=null and inside(cost) and cost.text=="FEE £%d · TRAVEL £%d · SESSION £%d" % [int(data.get("settled_fee",0)),int(expenses.get("travel_paid",0)),int(expenses.get("session_paid",0))],"actual fee/travel/session costs visible before handwritten narrative"):return false
  if not await capture(tag+"-initial"):return false
 if note.has_method("is_revealing") and bool(note.call("is_revealing")):
  for i in range(64):
   if note.has_focus():break
   await key(KEY_TAB)
  if not verify(note.has_focus(),"real Tab reaches actual long saved note"):return false
  await key(KEY_SPACE)
 if not verify(note.visible_characters==-1 and note.text==expected,"native note completion retains complete saved text"):return false
 if not await capture(tag):return false
 if not unchanged(before,"saved receipt read/capture"):return false
 return await free_action("CareerReceiptContinueAction","enter")

func commit(verb: String, choice: String="", method: String="pointer") -> bool:
 var before: Dictionary=guard()
 var expected: Dictionary=oracle(verb,choice)
 if not verify(bool(expected.get("ok",false)),"exact live/Finance UI oracle permits "+verb):return false
 if method=="touch":
  if not await native_touch_button("LiveMainAction"):return false
 elif not await activate("LiveMainAction",method):return false
 if not verify(model.snapshot()==expected_snapshot(before.snapshot,expected.state) and model.saves==int(before.saves)+1 and model.loads==before.loads,"one real input applies exact original/owned/Finance career and one owner save: "+verb):return false
 trace.append({"verb":verb,"input":method,"save_delta":model.saves-int(before.saves),"before":before.snapshot.game.career,"after":model.game.career.duplicate(true)})
 if verb=="book_flow":return await read_receipt("booked-preparation")
 return await wait_desk()

func native_touch_button(id: String) -> bool:
 var button: Button=named(id) as Button
 if not await settled(button) or not text_fits(button):return false
 var presses: Array[int]=[0]
 var counter: Callable=func():presses[0]+=1
 button.pressed.connect(counter)
 var point: Vector2=button.get_global_rect().get_center()
 for down in [true,false]:
  var event:=InputEventScreenTouch.new()
  event.window_id=root.get_window_id();event.index=53;event.position=point;event.pressed=down
  Input.parse_input_event(event)
  await process_frame
 if is_instance_valid(button) and button.pressed.is_connected(counter):button.pressed.disconnect(counter)
 return verify(presses[0]==1,"actual indexed ScreenTouch generates exactly one native Button callback")

func prepare_three_days() -> bool:
 if not await free_action("LiveWriteAction") or not await wait_practice():return false
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice():return false
 if not await free_action("PracticeMode_create") or not await type_pending_title():return false
 for index in range(3):
  var before: Dictionary=guard()
  var pane: Control=practice()
  var original:=Game.new()
  if not verify(original.restore(model.game.snapshot()),"restore original practice oracle before genuine preparation"):return false
  var result: Dictionary=original.write_session(str(Workshop.IDEAS[int(pane.get("idea_index"))]),str(Workshop.FORMS[int(pane.get("form_index"))]),str(pane.get("song_title")),int(pane.get("leader_index")))
  if not verify(bool(result.get("ok",false)),"original preparation write is available"):return false
  var expected: Dictionary=Finance.apply(before.snapshot.game.career,Live.after_practice(before.snapshot.game.career,original.career),"practice:create")
  if not verify(bool(expected.get("ok",false)),"original preparation post-chain accounts for exactly one day"):return false
  if not await activate("WriteAction") or not await wait_practice():return false
  if not verify(model.snapshot()==expected_snapshot(before.snapshot,expected.state) and model.saves==int(before.saves)+1,"genuine preparation Write advances original model/Finance and saves once"):return false
  if not await free_action("RecapToggleAction") or not await wait_practice():return false
 return verify(model.game.career.song_catalogue.size()==4 and Live.show_day(model.game.career),"three native prep writes add fourth actual original and reach booked show day")

func scroll_end() -> bool:
 var scroll: ScrollContainer=named("CareerScroll") as ScrollContainer
 if not verify(scroll!=null,"actual content scroll exists"):return false
 var bar: VScrollBar=scroll.get_v_scroll_bar()
 if bar.is_visible_in_tree() and bar.max_value>bar.page:
  for attempt in range(64):
   if bar.has_focus():break
   await key(KEY_TAB)
  if not verify(bar.has_focus() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bar.get_global_rect()) and scroll.get_global_rect().encloses(bar.get_global_rect()),"genuine Tab reaches visible scrollbar in its native chrome"):return false
  await key(KEY_END);await frames(3);await RenderingServer.frame_post_draw
  return verify(absf(scroll.scroll_vertical-(bar.max_value-bar.page))<=1,"real native End reaches settled content end")
 return true

func controls_and_setlist() -> bool:
 var before: Dictionary=guard()
 var approach: Control=named("ShowApproachControl")
 var intensity: Control=named("ShowIntensityControl")
 if not await settled(approach) or not await settled(intensity):return false
 var a_id: int=approach.get_instance_id();var i_id: int=intensity.get_instance_id()
 var old_preview: String=str((named("ShowPolicyPreview") as Label).text)
 if not await tab_to(approach):return false
 await key(KEY_END);await key(KEY_HOME);await key(KEY_RIGHT)
 if not await tab_to(intensity):return false
 await key(KEY_HOME);await key(KEY_END)
 if not verify(str(desk().get("show_draft").get("approach"))=="crowd" and int(desk().get("show_draft").get("intensity"))==100,"real rotary/fader keys choose crowd and all-out draft"):return false
 if not verify(str((named("ShowPolicyPreview") as Label).text)!=old_preview and named("ShowApproachControl").get_instance_id()==a_id and named("ShowIntensityControl").get_instance_id()==i_id,"meaningful modifier preview updates in place without rebuilding original hardware"):return false
 if not unchanged(before,"free actual hardware draft edits"):return false
 var selected: Array=desk().get("show_draft").get("song_ids",[]).duplicate()
 for id in selected:
  if not await free_action("ShowSong_"+str(id).replace(":","_"),"enter"):return false
 if not verify(desk().get("show_draft").get("song_ids",[]).is_empty() and named("ShowNoOriginalsWarning")!=null,"zero selected originals exposes honest underprepared warning"):return false
 if not await scroll_end() or not await capture("soundcheck-zero-originals"):return false
 var catalogue: Array=model.game.career.song_catalogue
 if not verify(catalogue.size()==4,"actual completed catalogue supplies four IDs, not assumed three"):return false
 for index in range(3):
  if not await free_action("ShowSong_"+str(catalogue[index].id).replace(":","_"),"pointer"):return false
 var fourth: String="ShowSong_"+str(catalogue[3].id).replace(":","_")
 if not await activate(fourth,"enter",true):return false
 if not unchanged(before,"setlist zero/three/cap selection remains unsaved"):return false
 var order: Array=desk().get("show_draft").get("song_ids",[]).duplicate()
 if not verify(order.size()==3,"three real completed originals selected"):return false
 if not await free_action("ShowDown_"+str(order[0]).replace(":","_"),"space"):return false
 var expected: Array=[order[1],order[0],order[2]]
 if not verify(desk().get("show_draft").get("song_ids")==expected,"real DOWN changes exact selected ID order"):return false
 if not await free_action("ShowShoutoutAction","enter"):return false
 if not verify(desk().get("show_draft").get("shoutout")=="thankvenue" and desk().get("show_draft").get("shoutout_venue_id")==Calendar.pending(model.game.career).venue_id,"native shout-out names only actual booked venue"):return false
 return await capture("soundcheck-three-originals")

func hold_and_resize(tag: String) -> bool:
 var before: Dictionary=guard()
 await create_timer(2.10).timeout
 if not unchanged(before,"held "+tag+" never automatically settles or saves"):return false
 var original: Vector2i=root.size
 var alternate: Vector2i=Vector2i(1280,720) if original.x<900 else Vector2i(390,844)
 root.size=alternate;DisplayServer.window_set_size(alternate);await frames(5)
 if not check_fixed_layout() or not unchanged(before,"actual root resize during held "+tag):return false
 if not await capture(tag+"-resized"):return false
 root.size=original;DisplayServer.window_set_size(original);await frames(5)
 return unchanged(before,"restore original held viewport "+tag)

func dialog() -> Control:
 return desk().get("_live_dialog") as Control

func stage_cancel() -> bool:
 var before: Dictionary=guard()
 if not await activate("LiveMainAction"):return false
 var warning: Control=dialog()
 if not verify(warning!=null and bool(warning.get("is_open")),"actual final stage warning opens before resolution"):return false
 var outcomes: Array=[]
 warning.completed.connect(func(value: bool):outcomes.append(value))
 if not await capture("stage-final-warning"):return false
 if not await activate("LiveKeepAction","pointer"):return false
 return verify(outcomes==[false] and dialog()==null,"actual NOT YET cancels final confirmation once") and unchanged(before,"stage NOT YET")

func restore_save() -> bool:
 if not backup_pending:return true
 if not verify(save_absolute.begins_with(S53_ROOT) and backup_absolute.begins_with(S53_ROOT),"save recovery confined to fresh S53 scratch"):return false
 if not verify(FileAccess.file_exists(backup_absolute) and FileAccess.get_file_as_bytes(backup_absolute)==original_bytes,"original exact bytes remain in backup"):return false
 if DirAccess.dir_exists_absolute(save_absolute):
  if not verify(DirAccess.remove_absolute(save_absolute)==OK,"remove only deliberate EMPTY failed-save directory"):return false
 if not verify(not FileAccess.file_exists(save_absolute) and not DirAccess.dir_exists_absolute(save_absolute),"never overwrite unexpected save recovery destination"):return false
 if not verify(DirAccess.rename_absolute(backup_absolute,save_absolute)==OK,"rename exact original save back"):return false
 backup_pending=false
 return verify(FileAccess.get_file_as_bytes(Model.SAVE_PATH)==original_bytes,"actual original save bytes restored before retry")

func perform_failed_save_then_retry() -> bool:
 var before: Dictionary=guard()
 var expected: Dictionary=oracle("perform")
 if not verify(bool(expected.get("ok",false)),"exact original/owned/review/Finance performance oracle succeeds"):return false
 save_absolute=ProjectSettings.globalize_path(Model.SAVE_PATH);backup_absolute=save_absolute+".s53-probe-backup"
 original_bytes=FileAccess.get_file_as_bytes(Model.SAVE_PATH)
 if not verify(save_absolute.begins_with(S53_ROOT) and not original_bytes.is_empty() and not FileAccess.file_exists(backup_absolute) and not DirAccess.dir_exists_absolute(backup_absolute),"failure injection uses only current fresh C27 save and unused backup"):return false
 if not await free_action("LiveMainAction"):return false
 if not verify(DirAccess.rename_absolute(save_absolute,backup_absolute)==OK,"preserve original save before real failing write"):return false
 backup_pending=true
 if not verify(DirAccess.make_dir_absolute(save_absolute)==OK,"real empty SAVE_PATH directory blocks FileAccess WRITE"):return false
 var outcomes: Array=[]
 dialog().completed.connect(func(value: bool):outcomes.append(value))
 var input_ok: bool=await activate("LiveConfirmAction","enter")
 var rollback_ok: bool=verify(outcomes==[true] and model.snapshot()==before.snapshot and model.saves==int(before.saves)+1,"accepted real failed save attempts once and rolls WHOLE career/Finance/receipt state back")
 rollback_ok=verify(not bool(desk().get("busy")) and not bool(desk().get("receipt_open")) and not is_instance_valid(desk().get("_overlay")) and str(desk().get("notice")).contains("could not be saved"),"failed save exposes notice with no ghost success/replay/busy") and rollback_ok
 var restored: bool=restore_save()
 if not input_ok or not rollback_ok or not restored:return false
 if not await saved_reload("failed-save restored baseline"):return false
 desk().set("reduced_motion",false);screen.set("reduced_motion",false)
 if not await free_action("LiveMainAction"):return false
 var confirm: Button=named("LiveConfirmAction") as Button
 if not await settled(confirm) or not text_fits(confirm):return false
 var pressed: Array[int]=[0];var accepted: Array=[]
 confirm.pressed.connect(func():pressed[0]+=1)
 dialog().completed.connect(func(value: bool):accepted.append(value))
 var point: Vector2=confirm.get_global_rect().get_center()
 for down in [true,false,true,false]:
  var event:=InputEventMouseButton.new();event.window_id=root.get_window_id();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
  Input.parse_input_event(event)
 await frames(3)
 if not verify(pressed[0]==1 and accepted==[true],"two real physical clicks create one pressed/accepted confirmation"):return false
 if not verify(model.snapshot()==expected_snapshot(before.snapshot,expected.state) and model.saves==int(before.saves)+2,"one retry settles exact oracle once after one failed save attempt"):return false
 var after: Dictionary=model.game.career
 if not verify(int(Finance.view(after).seq)==int(Finance.view(before.snapshot.game.career).seq)+1 and after.gig_history.size()==before.snapshot.game.career.get("gig_history",[]).size()+1,"Finance and original gig history settle once, never on failed attempt"):return false
 var saved: Dictionary=Flow.last_receipt(after)
 if not verify(not saved.is_empty() and saved.plan.song_ids.size()==3 and saved.originals_played==3,"durable receipt pins actual committed three-original plan and outcome"):return false
 trace.append({"case":"real failed save and one retry","failed_attempts":1,"successful_attempts":1,"pressed":pressed[0],"accepted":accepted,"receipt":saved,"finance_before":Finance.view(before.snapshot.game.career),"finance_after":Finance.view(after)})
 return await replay_and_read(saved)

func replay_and_read(saved: Dictionary) -> bool:
 var replay: Control=named("ShowReplay")
 if not verify(replay!=null and bool(desk().get("busy")),"post-save normal replay exists and holds owner busy"):return false
 var before: Dictionary=guard()
 var finished_count: Array[int]=[0]
 replay.finished.connect(func():finished_count[0]+=1)
 var until: int=mini(deadline,Time.get_ticks_msec()+4800)
 while not replay.has_meta("held_for_acknowledgement") and Time.get_ticks_msec()<until:await process_frame
 if not verify(replay.has_meta("held_for_acknowledgement"),"three normal response beats end in deliberate held acknowledgement"):return false
 for index in range(3):
  var text: Label=named("ShowReplayResponseText%d" % index) as Label
  if not verify(text!=null and text.text==str(saved.responses[index].text),"normal replay retains actual saved authored response"):return false
 if not await capture("replay-normal-held") or not await hold_and_resize("replay-held"):return false
 await key(KEY_ESCAPE)
 if not await wait_desk():return false
 if not verify(finished_count[0]==1 and not is_instance_valid(desk().get("_overlay")),"real Escape finishes presentation exactly once"):return false
 if not unchanged(before,"replay hold/resize/Skip"):return false
 if not await read_receipt("saved-show-receipt"):return false
 var reduced: Control=Replay.new()
 reduced.configure(saved,true)
 var done: Array[int]=[0];var covered_count: Array[int]=[0]
 reduced.covered.connect(func():covered_count[0]+=1)
 reduced.finished.connect(func():done[0]+=1;reduced.queue_free())
 desk().add_child(reduced);await frames(4)
 var safe: Dictionary=guard()
 if not verify(covered_count[0]==1 and reduced.has_meta("held_for_acknowledgement"),"same saved receipt reduced presentation is immediately held with one cover"):return false
 for index in range(3):
  if not verify(named("ShowReplayResponseText%d" % index)!=null,"reduced presentation shows all three saved texts without animation"):return false
 if not await capture("replay-reduced-held"):return false
 if not await activate("ShowReplayContinueAction","pointer"):return false
 await frames(3)
 return verify(done[0]==1,"actual reduced acknowledgement finishes once") and unchanged(safe,"reduced saved replay component does not settle/save")

func saved_reload(label: String) -> bool:
 var before: Dictionary=guard()
 var loaded:=Model.new()
 var expected: Dictionary=model.snapshot().duplicate(true)
 expected["game"]["career"]=model.game._restore_integral_numbers(expected["game"]["career"])
 return verify(loaded.load_draft() and loaded.snapshot()==expected,"actual full C27 disk load equals "+label) and unchanged(before,"independent disk load "+label)

func journey() -> bool:
 if not await open_live() or not await capture("unbooked"):return false
 if not await commit("book_flow","standard"):return false
 if not verify(Flow.phase(model.game.career)=="preparation","real new booking begins preparation before showday"):return false
 if not await open_live() or not await prepare_three_days() or not await open_live():return false
 if not verify(Flow.phase(model.game.career)=="travel","actual three prep days reach transport acknowledgement"):return false
 if not await capture("local-lift") or not await commit("depart"):return false
 if not verify(Flow.phase(model.game.career)=="arrival","one native departure reaches arrival without performance"):return false
 if not await capture("arrival") or not await commit("advance","","touch"):return false
 if not verify(Flow.phase(model.game.career)=="soundcheck","actual indexed touch advances arrival to soundcheck"):return false
 if not await controls_and_setlist() or not await commit("soundcheck"):return false
 if not verify(Flow.phase(model.game.career)=="stage","one saved plan reaches held stage"):return false
 if not await capture("held-stage") or not await hold_and_resize("stage-held") or not await stage_cancel():return false
 if not await perform_failed_save_then_retry() or not await saved_reload("settled durable receipt"):return false
 var before: Dictionary=guard()
 if not await activate("CareerMenuAction") or not unchanged(before,"actual Menu after show"):return false
 if not await activate("ContinueAction") or not unchanged(before,"actual Continue reload after show",1):return false
 if not await open_live() or not await free_action("LiveSavedShowAction"):return false
 if not verify(desk().get("receipt").get("show_receipt")==Flow.last_receipt(model.game.career),"actual durable reread uses saved original receipt without replaying settlement"):return false
 return await read_receipt("durable-show-reread")

func run() -> void:
 var started: int=Time.get_ticks_msec()
 deadline=started+108000
 var user_dir: String=ProjectSettings.globalize_path("user://")
 var output_path: String=ProjectSettings.globalize_path(output)
 var profiles: Array=[Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720),Vector2i(1600,900)]
 var safe: bool=verify(profiles.has(Vector2i(width,height)),"one of four native profiles")
 safe=verify(user_dir.begins_with(S53_ROOT) and output_path.begins_with(S53_ROOT),"strict fresh S53 XDG/output boundary") and safe
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated actual save path "+path) and safe
 if not safe:print("S53_SHOW_NATIVE_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}));quit(1);return
 output=output_path
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create S53 capture output"):quit(1);return
 old_mouse_emulation=Input.emulate_mouse_from_touch;old_touch_emulation=Input.emulate_touch_from_mouse
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=false
 protected_initial=files(true)
 root.size=Vector2i(width,height);DisplayServer.window_set_size(root.size);root.grab_focus();await frames(4)
 var orphan_before: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 if make_fixture():
  # Original writing calls build a documented QA catalogue BEFORE any owner UI.
  # No direct day/quality/songs assignment; these nine calls are not UI claims.
  for song in range(3):
   for step in range(3):
    var original: Dictionary=model.game.write_session(str(Workshop.IDEAS[0]),str(Workshop.FORMS[0]),"QA ORIGINAL %d" % [song+1],0)
    if not verify(bool(original.get("ok",false)),"original nine-write QA catalogue fixture"):break
  if verify(model.game.career.song_catalogue.size()==3 and int(model.game.career.tour_day)==10,"three actual model originals/day10 fixture without direct time edit") and fixture_step("initial isolated C27 save",model.save_draft()):
   trace.append({"fixture":"Canonical C27 trio; nine original model writes BEFORE native owner, one initial fixture disk save. Not claimed as nine native writes.","snapshot":model.snapshot()})
   screen=RootUI.new();screen.name="S53ShowActualNativeQA";screen.setup=model;screen.showing_menu=false;screen.reduced_motion=true;root.add_child(screen);await frames(4)
   await journey()
 if backup_pending:restore_save()
 if not failures.is_empty() and is_instance_valid(screen):await capture("FIRST-FAILURE")
 if is_instance_valid(screen):screen.free()
 screen=null;await frames(4)
 Input.emulate_mouse_from_touch=old_mouse_emulation;Input.emulate_touch_from_mouse=old_touch_emulation
 var orphan_after: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 verify(files(true)==protected_initial,"all legacy/C26 file bytes unchanged")
 verify(orphan_after<=orphan_before,"zero orphan growth after current owner cleanup")
 verify(Time.get_ticks_msec()-started<115000,"bounded native journey completes below root120-second runner")
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"errors":failures,"images":images,"width":width,"height":height,"engine":Engine.get_version_info(),"elapsed_ms":Time.get_ticks_msec()-started,"user_data":user_dir,"save_calls":model.saves if model!=null else 0,"load_calls":model.loads if model!=null else 0,"orphan_before":orphan_before,"orphan_after":orphan_after,"trace":trace,"method":"Fresh actual C27 fixture plus documented nine-model-write catalogue; genuine booking, three native prep writes, transport/touch/arrival, original hardware keys/setlist/shoutout, stage/resize/cancel, real failed disk save+whole rollback+retry, one Finance/performance, normal/reduced replay and durable Menu/Continue/reread. UI expected state uses pure bridge+Finance; independent model-policy proof is separate. No Android device claim."}
 var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:push_error("S53_SHOW_NATIVE cannot write result");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close();print("S53_SHOW_NATIVE_RESULT ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
