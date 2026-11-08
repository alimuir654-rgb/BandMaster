extends "res://tests/recorded_steady_visual.gd"
## Isolated actual Playtest entry and source-backed activity fixtures.
const Recording=preload("res://experiments/playable_flightcase/recording_rules.gd")
const Radio=preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const Promotion=preload("res://experiments/playable_flightcase/promotion_rules.gd")
const Booking=preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Live=preload("res://experiments/playable_flightcase/live_bridge.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")
const Calendar=preload("res://Scripts/gig_calendar.gd")
const Finance=preload("res://experiments/playable_flightcase/finance_policy.gd")
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")
var scene
var base: Dictionary={}
var coverage: Array=[]

func settle() -> void:
 for _i in range(4):await process_frame

func mounted(career: Dictionary={}) -> void:
 if is_instance_valid(scene):scene.free();scene=null
 owner=Owner.new();check(owner.restore(base),"restore isolated actual band")
 if not career.is_empty():owner.game.career=career.duplicate(true)
 check(owner.save_draft(),"save isolated fixture")
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;scene._career_landing=true
 root.add_child(scene);await settle()
 check(is_instance_valid(scene._career_view),"actual entry opens career")

func snapshot_case(label: String) -> void:
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 await capture(label)
 var buttons: Array=[]
 for raw in scene.find_children("*","Button",true,false):
  if raw.is_visible_in_tree():buttons.append({"name":str(raw.name),"text":raw.text,"rect":str(raw.get_global_rect()),"disabled":raw.disabled})
 var desk: Control=scene._career_view
 coverage.append({"case":label,"page":str(desk.page) if is_instance_valid(desk) else "opening","buttons":buttons})
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"capture/navigation never settles "+label)

func page_case(label: String,page: String,options: Dictionary={}) -> void:
 var desk: Control=scene._career_view
 desk.page=page;desk.receipt_open=false;desk._scroll_position=0
 for key in options:desk.set(key,options[key])
 desk._render();await settle()
 await snapshot_case(label)

func run() -> void:
 if not check(not output.is_empty() and fixture(),"actual formation fixture"):finish_audit();return
 if not check(await catalogue_fixture(),"canonical current paid catalogue"):finish_audit();return
 base=owner.snapshot().duplicate(true)
 if "--radio-only" in OS.get_cmdline_user_args():
  await radio_cases();finish_audit();return
 await mounted()
 scene._home();await settle();await snapshot_case("title")
 scene._toggle_settings();await settle();await snapshot_case("settings")
 scene._settings_sheet.close_sheet();scene._continue();await settle()
 await page_case("home","home")
 await page_case("activities","home",{"poster_activities_open":true})
 await page_case("gear","gear")
 await page_case("gear-catalogue","gear",{"catalogue_open":true})
 await page_case("band","band")
 await page_case("songbook","songs")
 await page_case("calendar","calendar")
 await page_case("finance","finance")
 await page_case("goal-direction","goal_focus")
 await page_case("situation","situation")
 await page_case("band-moment","band_moment")
 await page_case("offstage","offstage")
 await page_case("recording","recording",{"recording_mode":"select"})
 await page_case("archive-empty","recording",{"recording_mode":"archive"})
 await page_case("radio-entry","recording",{"recording_mode":"radio"})
 await page_case("gig-booking","gigs")
 await activate("BookingVenue_local");await snapshot_case("gig-booking-agreement-draft")
 await mounted()
 scene._return_from_career("tighten");await settle();await snapshot_case("rehearsal")
 await mounted()
 var take: Dictionary=Recipe.recipe(Sound.read(owner.game.career));take.hook="dgad_03_v1"
 if not check(owner.begin_workbench("NIGHT BUS IDEA",0,owner.workbench_expected(),take).ok,"real recorded writing draft"):finish_audit();return
 scene._career_landing=false;scene._render();await settle();await snapshot_case("writing-recorded")
 var desk: Control=scene.find_child("MixingDesk",true,false)
 desk._choose_foundation(0);await settle();await snapshot_case("writing-composed")
 if not baseline:await writing_inputs(desk)
 await radio_cases()
 await gig_cases()
 await legacy_gig_cases()
 finish_audit()

func day_action() -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var attendance: Dictionary=Situation.inspect_rehearsal(before)
 if not attendance.get("ok",false):return false
 var jam: Dictionary=owner.game.informal_practice(attendance.attendee_indices)
 if not check(jam.ok,"canonical free jam day: "+str(jam.get("message",""))):return false
 var tracked: Dictionary=Situation.after_action(before,owner.game.career)
 if not check(tracked.ok,"canonical day situation accounting"):return false
 var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:jam")
 if not check(accounted.ok,"canonical day finance once"):return false
 owner.game.career=accounted.state
 return owner.save_draft()

func available_evening() -> bool:
 for _day in range(7):
  if Situation.inspect_writing(owner.game.career).get("can_write",false):return true
  if not day_action():return false
 return false

func catalogue_fixture() -> bool:
 for number in range(3):
  if not available_evening():return false
  var value: Dictionary=Recipe.recipe(Sound.read(owner.game.career));value.hook=Recipe.HOOKS[number]
  var title: String="POSTER ORIGINAL %d" % (number+1)
  var begun: Dictionary=owner.begin_workbench(title,0,owner.workbench_expected(),value)
  if not check(begun.ok,"canonical writing begin: "+str(begun)):return false
  for stage in range(3):
   if not available_evening():return false
   value.stage=stage
   var trial: Dictionary=owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":value,"title":title,"leader_index":0})
   if not check(trial.ok,"canonical producer trial"):return false
   var project: Dictionary=owner.workbench_view().project
   var offer: Dictionary=Recipe.offer(project.fragment.producer_recipe,project.target.respondent_ref)
   if not check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"keep","offer_id":offer.offer_id}).ok,"canonical reply"):return false
   var ticket: Dictionary=owner.begin_workbench_commit(owner.workbench_expected())
   if not check(ticket.ok,"canonical paid ticket"):return false
   var prepared: Dictionary=ticket.prepared
   var result: Dictionary=owner.game.write_session_prepared(prepared.args.idea,prepared.args.form,prepared.args.title,prepared.args.leader_index,prepared)
   if not check(result.ok and owner.complete_workbench_original(ticket.transaction_id,result).ok,"canonical writing reconciliation"):return false
   var tracked: Dictionary=Situation.after_action(ticket.before_game.career,owner.game.career)
   if not check(tracked.ok,"canonical writing situation"):return false
   var accounted: Dictionary=Finance.apply(ticket.before_game.career,Live.after_practice(ticket.before_game.career,tracked.state),"practice:create")
   if not check(accounted.ok,"canonical writing finance"):return false
   owner.game.career=accounted.state
   if not check(owner.finish_workbench_commit(ticket.transaction_id).ok,"canonical final writing save"):return false
 return available_evening()

func result_state(result: Dictionary,label: String) -> bool:
 if not check(result.get("ok",false),label+": "+str(result.get("message",""))):return false
 owner.game.career=result.state
 return true

func radio_cases() -> void:
 await mounted()
 if not result_state(Recording.record(owner.game.career,["original:1","original:2","original:3"]),"canonical recording"):return
 var session: Dictionary=Recording.sessions(owner.game.career)[0]
 var recorded: Dictionary=owner.game.career.duplicate(true)
 await mounted(recorded);await page_case("archive-recorded","recording",{"recording_mode":"archive"})
 if not result_state(Recording.release(owner.game.career,session.id,Recording.fingerprint(session),0),"canonical release"):return
 session=Recording.sessions(owner.game.career)[0]
 var released: Dictionary=owner.game.career.duplicate(true)
 var selection: Dictionary={"id":session.id,"fingerprint":Recording.fingerprint(session),"index":0}
 await page_case("archive-released","recording",{"recording_mode":"archive"})
 await page_case("radio-ready","recording",{"recording_mode":"radio","promotion_selection":selection})
 if not await activate("StudioStartAction"):return
 check(Radio.locked(owner.game.career),"native studio begin saves checkpoint")
 for _beat in range(7):
  var visit: Dictionary=Radio.active(owner.game.career)
  await page_case("radio-"+str(visit.phase),"recording",{"recording_mode":"visit","promotion_selection":selection})
  if visit.phase=="question1":
   await activate("StudioCancelAction");await snapshot_case("radio-cancel-confirm")
   await activate("StudioCancelKeepAction")
  if visit.phase=="arrival":await failed_action("StudioContinueAction","radio-save-error")
  var action: String="StudioFinishAction" if visit.phase=="wrap_ready" else ("StudioChoice_craft" if visit.phase=="question1" else ("StudioChoice_invite" if visit.phase=="question2" else "StudioContinueAction"))
  if not await activate(action):return
  if is_instance_valid(scene._career_view._overlay):scene._career_view._overlay.finish_now();await settle()
  if visit.phase=="wrap_ready":await snapshot_case("radio-saved-receipt")

 await page_case("radio-stale-selection-held","recording",{"recording_mode":"radio","promotion_selection":selection})
 await page_case("archive-radio-complete","recording",{"recording_mode":"archive"})
 if not await activate("RecordingRadio_0"):return
 var fresh: Dictionary=scene._career_view.promotion_selection
 check(Promotion.selection(owner.game.career,fresh.id,fresh.fingerprint,fresh.index).get("completed",false),"actual refreshed archive opens completed radio campaign")
 await snapshot_case("radio-saved")
 await activate("PromotionDetailsAction")
 for question in ["focus","invitation"]:
  var answer: Label=scene.find_child("StudioSavedAnswer_"+question,true,false) as Label
  check(answer!=null and answer.is_visible_in_tree() and not answer.text.is_empty(),"actual saved transcript answer "+question)
 scene._career_view._scroll.scroll_vertical=100000;await settle();await snapshot_case("radio-saved-transcript")

func gig_cases() -> void:
 await mounted()
 var state: Dictionary=owner.game.career.duplicate(true)
 var request: Dictionary={"venue_id":"local","offer_id":"standard","travel_plan":"drive_home","session_drummer":false,"day":int(state.tour_day)+3}
 var booked: Dictionary=Live.book_selected(state,request,Booking.expected(state))
 if not check(booked.ok,"canonical modern booking: "+str(booked.get("message",""))):return
 if not result_state(Finance.apply(state,booked.state,"live:book"),"canonical booking accounting"):return
 await page_case("gig-agreement","gigs")
 for _day in range(3):
  if not day_action():return
 if not result_state(Journey.begin(owner.game.career,Flow.booking_id(Calendar.pending(owner.game.career))),"canonical journey begin"):return
 for _beat in range(19):
  var visit: Dictionary=Journey.active(owner.game.career)
  var phase: String=str(visit.phase)
  await page_case("gig-"+phase+("-"+str(visit.cursor) if phase=="performing" else ""),"gigs")
  var result: Dictionary
  if phase=="soundcheck":
   if not baseline:await soundcheck_inputs()
   await failed_action("JourneyMainAction","gig-save-error")
  if phase=="backstage":
   await activate("JourneyShowOptionsAction");await snapshot_case("gig-options")
   await activate("JourneyShowOptionsCloseAction")
  if phase=="wrap_ready":
   if not await activate("JourneyWrapAction"):return
   check(not Flow.last_receipt(owner.game.career).is_empty(),"native wrap writes saved show receipt")
   await snapshot_case("gig-saved-receipt")
   return
  if phase in ["set_out","travel","arrival","load_in"]:
   if not result_state(Journey.checkpoint(owner.game.career,"advance",Journey.expected(owner.game.career)),"canonical fixture gig "+phase):return
  else:
   var action: String="JourneyFinishSongAction" if phase=="performing" else ("JourneyChoiceMomentAction" if phase=="choice" else "JourneyMainAction")
   if not await activate(action):return
 check(false,"journey bounded coverage terminates")

func failed_action(node_name: String,label: String) -> void:
 var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 if not check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"isolated failure injection"):return
 await activate(node_name)
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"whole owner and disk roll back "+label)
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated test blocker")
 await snapshot_case(label)

func legacy_gig_cases() -> void:
 await mounted()
 var before: Dictionary=owner.game.career.duplicate(true)
 var booked: Dictionary=Live.resolve(before,"book_flow","standard")
 if not check(booked.ok,"canonical legacy booking: "+str(booked.get("message",""))):return
 if not result_state(Finance.apply(before,booked.state,"live:book"),"canonical legacy accounts"):return
 await page_case("legacy-gig-preparation","gigs")
 for _day in range(7):
  if Journey.eligible(owner.game.career):break
  if not day_action():return
 if not result_state(Journey.begin(owner.game.career,Flow.booking_id(Calendar.pending(owner.game.career))),"canonical legacy journey"):return
 if not result_state(Journey.checkpoint(owner.game.career,"arrive_soundcheck",Journey.expected(owner.game.career)),"canonical legacy arrival"):return
 await page_case("legacy-gig-soundcheck","gigs")
 if not baseline:
  var control: Control=scene._career_view.find_child("ShowApproachControl",true,false)
  scene._career_view._scroll.ensure_control_visible(control);await settle();await snapshot_case("legacy-gig-controls")

func activate(node_name: String) -> bool:
 var button: Button=scene.find_child(node_name,true,false) as Button
 if not check(button!=null and button.is_visible_in_tree() and not button.disabled,"native action available "+node_name):return false
 var connections: Array=button.pressed.get_connections()
 var retained: Callable=connections[0].callable if not connections.is_empty() else Callable()
 button.pressed.emit();await settle()
 # Retained one-shot callbacks must reject a second request after re-render.
 if node_name in ["StudioFinishAction","JourneyWrapAction"] and retained.is_valid():
  var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
  retained.call();await settle()
  check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"once-only retained "+node_name)
 return true

func click(control: Control) -> void:
 var point: Vector2=root.get_final_transform()*control.get_global_transform_with_canvas()*(control.size/2)
 print("POINTER_PROOF "+JSON.stringify({"node":str(control.name),"window_point":str(point),"viewport_transform":str(root.get_final_transform()),"logical_rect":str(control.get_global_rect())}))
 for down in [true,false]:
  var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
  Input.parse_input_event(event);await process_frame
 await settle()

func writing_inputs(desk: Control) -> void:
 var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 desk._choose("tone",0)
 var tone: Control=desk._controls.tone
 desk._scroll.ensure_control_visible(tone);await settle()
 await click(tone._choices[2])
 check(desk._recipe.tone=="biting","actual pointer selects paper tone")
 await click(tone._choices[2])
 check(tone._choices[2].button_pressed,"repeated selected click retains paper selection")
 tone.grab_focus()
 var key:=InputEventKey.new();key.keycode=KEY_HOME;key.pressed=true;Input.parse_input_event(key);await settle()
 key=InputEventKey.new();key.keycode=KEY_HOME;key.pressed=false;Input.parse_input_event(key);await settle()
 check(desk._recipe.tone=="warm","actual keyboard selects paper tone")
 desk._busy=true;desk._refresh();await click(tone._choices[2])
 check(desk._recipe.tone=="warm","disabled paper choice rejects pointer")
 desk._busy=false;desk._refresh()
 desk._bank_more.pressed.emit();await settle();await snapshot_case("writing-bank-open")
 desk._bank_more.pressed.emit();desk._scroll.scroll_vertical=0;await settle()
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"paper choices remain local and free")

func soundcheck_inputs() -> void:
 var host: Control=scene._career_view
 var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var control: Control=host.find_child("ShowIntensityControl",true,false)
 control.hydrate_level(27)
 check(control.level==27 and host.show_draft.intensity==50,"silent exact legacy intensity hydration")
 host._scroll.ensure_control_visible(control);await settle()
 await click(control._choices[1])
 check(control.level==28 and host.show_draft.intensity==28,"native paper intensity preserves exact 0–100 values")
 control.set_read_only(true);await click(control._choices[1])
 check(control.level==28,"read-only soundcheck cannot edit")
 control.set_read_only(false)
 var approach: Control=host.find_child("ShowApproachControl",true,false)
 host._scroll.ensure_control_visible(approach);await settle();await click(approach._choices[1])
 check(host.show_draft.approach=="crowd","native paper approach maps to original draft")
 await snapshot_case("gig-soundcheck-controls")
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"soundcheck draft costs no day and saves nothing")

func finish_audit() -> void:
 var report: Dictionary={"viewport":str(root.size),"checks":checks,"failures":failures,"coverage":coverage,"actual_entry":"opening.tscn","physical_device":false}
 if not output.is_empty():
  var file=FileAccess.open(output+"-coverage.json",FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify(report," "))
 print("POSTER_AUDIT "+JSON.stringify({"viewport":str(root.size),"checks":checks,"failures":failures,"screens":coverage.size()}))
 if is_instance_valid(scene):scene.free();scene=null
 owner=null
 var stopped: int=Time.get_ticks_usec()
 while Time.get_ticks_usec()-stopped<100000:await process_frame
 call_deferred("quit",0 if failures.is_empty() else 1)
