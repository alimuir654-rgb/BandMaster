extends SceneTree
## SONG55 fixture reused for SONG56: real retained UI/owner and deterministic QA setup.
## Setup uses original model APIs; it is not a claim of a human writing a song.
## Event/reveal helpers follow character_consequence_visual and band_stories_visual.
## Both variants include SONG55; common facts/disclosure/scroll checks run on both.
## Only SONG56-specific card/meter checks are candidate-only.
const Owner = preload("res://experiments/playable_flightcase/opening_state.gd")
const Recordings = preload("res://experiments/playable_flightcase/recording_rules.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Journey = preload("res://experiments/playable_flightcase/gig_journey.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Situation = preload("res://experiments/playable_flightcase/situation_core.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const LONG_TITLE := "THE LAST TRAIN — ÉCHO APRÈS LA PLUIE"
var owner
var scene
var output := ""
var work_root := ""
var baseline := false
var fixture_only := false
var baseline_defects: Array[String]=[]
var checks := 0
var failures: Array[String] = []
var images: Array = []
var trace: Array = []
var deadline := 0
var fixture_hash := ""

func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=")
  if arg=="--baseline":baseline=true
  if arg=="--fixture-only":fixture_only=true
 call_deferred("run")

func check(ok: bool, message: String) -> bool:
 checks+=1
 if not ok:
  failures.append(message)
  push_error("SONG55_NATIVE "+message)
 return ok

func step(result: Variant, message: String) -> bool:
 if result is Dictionary and not bool(result.get("ok",false)):print("SONG55_QA_SETUP_REJECTION "+JSON.stringify(result))
 return check(bool(result.get("ok",false)) if result is Dictionary else bool(result),"QA setup: "+message)

func file_state() -> Dictionary:
 var result: Dictionary={}
 for path in [Owner.SAVE_PATH,Owner.SAVE_PATH+".identity-tmp","user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  result[path]={"exists":FileAccess.file_exists(path),"directory":DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"bytes":FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()}
 return result

func guard() -> Dictionary:
 return {"snapshot":owner.snapshot().duplicate(true),"files":file_state()}

func unchanged(before: Dictionary, label: String) -> bool:
 return check(owner.snapshot()==before["snapshot"] and file_state()==before["files"],label+" preserves whole owner and exact save bytes")

func settle(count: int=5) -> void:
 for _i in range(count):
  if Time.get_ticks_msec()>deadline:
   check(false,"bounded native deadline");return
  await process_frame

func named(name: String, allow_hidden: bool=false) -> Control:
 if not is_instance_valid(scene):return null
 for raw in scene.find_children(name,"Control",true,false):
  var control: Control=raw
  if control.is_visible_in_tree():return control
  if allow_hidden and control.get_parent() is CanvasItem and control.get_parent().is_visible_in_tree():return control
 return null

func clipped_rect(control: Control) -> Rect2:
 var rect: Rect2=control.get_global_rect().intersection(control.get_viewport_rect())
 var parent: Node=control.get_parent()
 while parent!=null:
  if parent is ScrollContainer or (parent is Control and parent.clip_contents):rect=rect.intersection(parent.get_global_rect())
  parent=parent.get_parent()
 return rect

func reveal(control: Control) -> bool:
 if not check(control!=null and control.is_visible_in_tree(),"visible native reveal target"):return false
 var parent: Node=control.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(control)
  parent=parent.get_parent()
 # Observe completed layout; never emit pressed/toggled signals to make a test pass.
 await settle()
 return check(clipped_rect(control).size.x>4 and clipped_rect(control).size.y>4,"reveal has a visible clipped area")

func activate(name: String, keyboard: bool=false) -> bool:
 var target: Button=named(name) as Button
 if not check(target!=null and not target.disabled,"real enabled target "+name):return false
 if not await reveal(target):return false
 var rect: Rect2=target.get_global_rect()
 if not check(clipped_rect(target).encloses(rect),"whole target inside actual clips "+name):return false
 var physical: Rect2=root.get_final_transform()*target.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,target.size)
 var revised_action: bool=name.begins_with("Recording") or name.begins_with("DemoTrackNotes") or name.begins_with("SongSummary_book_") or name.begins_with("SongSummary_record_")
 if revised_action:
  var target_ok: bool=physical.size.x>=44 and physical.size.y>=44
  trace.append({"action":name,"physical_width":physical.size.x,"physical_height":physical.size.y,"SONG56_minimum":44,"baseline":baseline})
  if baseline and not target_ok:
   baseline_defects.append("Original action %s measures %.2f x %.2f physical px; new SONG56 minimum is not a historical baseline pass." % [name,physical.size.x,physical.size.y])
  elif not baseline and not check(target_ok,"physical 44px revised action %s: %.2f x %.2f" % [name,physical.size.x,physical.size.y]):return false
 if keyboard:
  target.grab_focus()
  await process_frame
  if not check(root.gui_get_focus_owner()==target,"actual keyboard focus "+name):return false
  for down in [true,false]:
   var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.physical_keycode=KEY_ENTER;key.pressed=down
   Input.parse_input_event(key);await process_frame
 else:
  var point: Vector2=root.get_final_transform()*target.get_global_transform_with_canvas()*(target.size/2)
  for down in [true,false]:
   var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=down;mouse.position=point;mouse.global_position=point
   Input.parse_input_event(mouse);await process_frame
 await settle()
 return true

func free_action(name: String, keyboard: bool=false) -> bool:
 var before: Dictionary=guard()
 if not await activate(name,keyboard):return false
 return unchanged(before,"native "+name)

func capture(label: String) -> bool:
 await settle()
 await RenderingServer.frame_post_draw
 var texture: Texture2D=root.get_texture()
 if not check(texture!=null,"rendered native viewport texture"):return false
 var pixels: Image=texture.get_image()
 if not check(pixels!=null and not pixels.is_empty(),"actual drawn pixels "+label):return false
 var path: String=output+"/"+label+".png"
 if not check(not FileAccess.file_exists(path),"preserve existing capture "+label):return false
 if not check(pixels.save_png(path)==OK,"write original capture "+label):return false
 images.append({"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"state":label})
 return true

func inspect_summary(key: String, quality: int, label: String) -> bool:
 var strength: Label=named("SongSummary_"+key+"_Strength") as Label
 if not check(strength!=null,"shared summary strength "+key):return false
 if not check(strength.text.contains("%d / 100" % quality),"literal saved strength "+key):return false
 if not check(strength.get_theme_font_size("font_size")>=16,"preserved readable summary type "+key):return false
 if not baseline and (key.begins_with("book_") or key.begins_with("record_") or key.begins_with("take_")):
  var gauge: Control=named("SongSummary_"+key+"_Gauge")
  if not check(gauge!=null and gauge.get_meta("source_value",-1)==quality and gauge.get_meta("known_strength",false) and gauge.get_meta("read_only",false),"exact saved value on native passive gauge "+key):return false
  var art: Control=gauge.get_node("CareerMeterArt") as Control
  if not check(art!=null and art.mouse_filter==Control.MOUSE_FILTER_IGNORE and art.focus_mode==Control.FOCUS_NONE and gauge.focus_mode==Control.FOCUS_NONE,"original meter remains input-inert "+key):return false
  if not await reveal(gauge):return false
  if not await scroll_proof("CareerScroll",str(gauge.name)):return false
 if key=="take_0_0":
  if not await reveal(strength):return false
  var title: Control=named("RecordingSavedTitle_0_0")
  if not await reveal(title):return false
  if not check(clipped_rect(title).encloses(title.get_global_rect()) and clipped_rect(strength).encloses(strength.get_global_rect()),"captured title and strength readable together"):return false
  if not await capture(label+"-strength"):return false
 var details: Control=named("SongSummary_"+key+"_Details",true)
 if not check(details!=null,"summary details exist "+key):return false
 var toggle: Button=named("SongSummary_"+key+"_Toggle") as Button
 if toggle!=null and not details.visible:
  if not await free_action(str(toggle.name)):return false
 details=named("SongSummary_"+key+"_Details")
 if not check(details!=null and details.is_visible_in_tree(),"actual expanded details "+key):return false
 for metric in ["Readiness","Recording","Reach","Evidence"]:
  var text: Label=named("SongSummary_"+key+"_"+metric) as Label
  if not check(text!=null and not text.text.strip_edges().is_empty(),"complete saved-fact row "+key+"/"+metric):return false
  if metric in ["Readiness","Recording","Reach"]:
   if not check(text.text.to_lower().contains("not tracked") and not text.text.contains(" / 100"),"no invented numeric preparation/execution/listens "+key+"/"+metric):return false
 if not await reveal(named("SongSummary_"+key+"_Readiness")):return false
 if not await capture(label+"-details"):return false
 if key=="practice_0":
  if not await scroll_proof("PracticeScroll","SongSummary_"+key+"_Readiness"):return false
 if toggle!=null:
  if not await free_action("SongSummary_"+key+"_Toggle",true):return false
  if not check(not named("SongSummary_"+key+"_Details",true).visible,"keyboard closes only details "+key):return false
 return true

func scroll_proof(name: String, text_target: String="") -> bool:
 var scroll: ScrollContainer=named(name) as ScrollContainer
 if not check(scroll!=null,"real scrolling surface "+name):return false
 var bar: VScrollBar=scroll.get_v_scroll_bar()
 var available: float=bar.max_value-bar.page
 if available<=1:
  trace.append({"scroll":name,"case":"natural fitted content","available":available})
  return true
 var before: Dictionary=guard()
 var initial: float=bar.value
 var direction: float=-1.0 if initial<available*0.7 else 1.0
 var area: Rect2=scroll.get_global_rect().intersection(scroll.get_viewport_rect())
 if not text_target.is_empty():
  var label: Control=named(text_target)
  if not check(label!=null,"expanded practice summary text exists for touch drag"):return false
  area=area.intersection(label.get_global_rect())
  if not check(area.size.x>8 and area.size.y>8,"actual text has a visible drag start"):return false
 var point: Vector2=root.get_final_transform()*(area.position+area.size/2)
 var prior_emulation: bool=Input.emulate_touch_from_mouse
 if not text_target.is_empty():Input.emulate_touch_from_mouse=true
 var received: Array=[]
 var observer: Callable=func(event: InputEvent):received.append(event.get_class())
 scroll.gui_input.connect(observer)
 var down:=InputEventScreenTouch.new();down.index=0;down.pressed=true;down.position=point
 Input.parse_input_event(down);await process_frame
 for index in range(8):
  var motion:=InputEventScreenDrag.new();motion.index=0;motion.position=point+Vector2(0,direction*(index+1)*8);motion.relative=Vector2(0,direction*8);motion.velocity=Vector2(0,direction*200)
  Input.parse_input_event(motion);await process_frame
 var up:=InputEventScreenTouch.new();up.index=0;up.pressed=false;up.position=point+Vector2(0,direction*64)
 Input.parse_input_event(up)
 # Finite quiescence observation; do not cancel native inertia or set scroll.
 var stable:=0;var prior: float=bar.value
 for _frame in range(120):
  await process_frame
  if absf(bar.value-prior)<0.01:stable+=1
  else:stable=0
  prior=bar.value
  if stable>=6:break
 scroll.gui_input.disconnect(observer)
 trace.append({"scroll":name,"start_text":text_target,"emulate_touch_from_mouse":Input.emulate_touch_from_mouse,"received":received,"available":available,"before":initial,"after":bar.value})
 Input.emulate_touch_from_mouse=prior_emulation
 return check(absf(bar.value-initial)>0.1,"genuine touch drag moves available content "+name) and unchanged(before,"native touch scroll")

func visual_zero_unknown() -> bool:
 if baseline:return true
 var view=load("res://experiments/playable_flightcase/song_summary_view.gd")
 var holder:=VBoxContainer.new()
 holder.size=Vector2(300,200)
 root.add_child(holder)
 var before: Dictionary=guard()
 var zero: Label=view.visual_strength(holder,{"known_strength":true,"quality":0},"zero_probe")
 var unknown: Label=view.visual_strength(holder,{"known_strength":false,"quality":null},"unknown_probe")
 await settle()
 var zero_gauge: Control=holder.find_child("SongSummary_zero_probe_Gauge",true,false) as Control
 var ok: bool=check(zero.text=="0 / 100" and zero_gauge!=null and zero_gauge.get_meta("source_value",-1)==0,"known zero is an explicitly scored zero")
 ok=check(unknown.text=="UNKNOWN" and holder.find_child("SongSummary_unknown_probe_Gauge",true,false)==null,"unknown has no false zero gauge") and ok
 ok=unchanged(before,"zero/unknown presentation") and ok
 holder.free()
 return ok

func settle_fixture_practice(before: Dictionary, kind: String) -> bool:
 # The same protected settlement chain used by ui.gd after its original model.
 var tracked: Dictionary=Situation.after_action(before,owner.game.career)
 if not step(tracked,"original situation post-chain"):return false
 var after: Dictionary=Live.after_practice(before,tracked.state)
 var accounted: Dictionary=Finance.apply(before,after,"practice:"+kind)
 if not step(accounted,"original practice finance settlement"):return false
 owner.game.career=accounted.state
 return true

func fixture_jam() -> bool:
 var attendance: Dictionary=Situation.inspect_rehearsal(owner.game.career)
 if not step(attendance,"inspect actual available attendees"):return false
 var before: Dictionary=owner.game.career.duplicate(true)
 if not step(owner.game.informal_practice(attendance.attendee_indices),"original informal practice"):return false
 if not check(int(owner.game.career.tour_day)==int(before.tour_day)+1,"fixture day action advances exactly once"):return false
 return settle_fixture_practice(before,"jam")

func fixture_live(verb: String, choice: String="") -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var result: Dictionary=Live.resolve(before,verb,choice,false)
 if not step(result,"original live "+verb):return false
 var accounted: Dictionary=Finance.apply(before,result.state,"live:"+verb)
 if not step(accounted,"original live finance settlement "+verb):return false
 owner.game.career=accounted.state
 return true

func finance_matches() -> bool:
 var ledger: Dictionary=Finance.view(owner.game.career)
 return check(int(ledger.accounted_day)==int(owner.game.career.tour_day) and int(ledger.closing_balance)==int(owner.game.career.cash),"fixture retains actual finance day and balance")

func prepare_writing() -> bool:
 var initial: Dictionary=Situation.inspect_writing(owner.game.career)
 if not step(initial,"inspect current writing availability"):return false
 var start: int=int(owner.game.career.tour_day)
 var last_day: int=int(initial.get("next_full_day",0))
 if not check(last_day>=start and last_day<=start+14,"bounded next full-band writing evening"):return false
 for _attempt in range(15):
  var view: Dictionary=Situation.inspect_writing(owner.game.career)
  if not step(view,"recheck current writing availability"):return false
  if view.get("can_write",false):
   trace.append({"QA_availability_preparation":{"from":start,"to":int(owner.game.career.tour_day)},"method":"original informal-practice model with actual available attendees"})
   return true
  var day: int=int(owner.game.career.tour_day)
  if not check(day<last_day,"advertised full-band evening must be available"):return false
  if not fixture_jam():return false
  if not check(int(owner.game.career.tour_day)==day+1,"original informal practice advances exactly one day"):return false
 return check(false,"bounded writing availability preparation exhausted")

func fixture() -> bool:
 owner=Owner.new()
 if not step(owner.begin_new(),"new owner") or not step(owner.set_genre("Indie rock"),"genre") or not step(owner.to_recruit(),"recruit"):return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not step(owner.recruit(id),id):return false
 if not step(owner.choose_vocal("cast_jack"),"voice") or not step(owner.confirm_lineup(),"lineup"):return false
 if not step(owner.start_naming(),"naming") or not step(owner.submit_name("QA SONGBOOK BAND","Raw"),"name") or not step(owner.lock_name(),"lock name"):return false
 if not step(owner.start_identity(),"identity") or not step(owner.set_identity("Wordmark","Amber / Charcoal","Unpolished"),"style") or not step(owner.finish_identity(),"finish identity") or not step(owner.start_playing(),"play"):return false
 for song_number in range(4):
  for _session in range(3):
   if not prepare_writing():return false
   var before: Dictionary=owner.game.career.duplicate(true)
   if not step(owner.game.write_session("Riff","Verse / Chorus","QA ORIGINAL %d" % [song_number+1],0),"original-model writing session"):return false
   if not settle_fixture_practice(before,"create"):return false
  if song_number==1:
   owner.game.career["song_catalogue"][0]["quality"]=72
   owner.game.career["song_catalogue"][0]["title"]="CAPTURED LAST TRAIN"
   owner.game.career["song_catalogue"][1]["quality"]=55
   var recording: Dictionary=Recordings.record(owner.game.career,["original:1","original:2"])
   if not step(recording,"real linked recording model"):return false
   owner.game.career=recording["state"]
 # Explicit edge fixture, not a newly implemented revision mechanic.
 owner.game.career["song_catalogue"][0]["quality"]=91
 owner.game.career["song_catalogue"][0]["title"]=LONG_TITLE
 owner.game.career["qa_song55_unknown"]={"nested":[17,{"retain":"exact"}]}
 if not step(owner.save_draft(),"persist complete explicit QA fixture"):return false
 if not check(Recordings.validate(owner.game.career).get("ok",false),"fixture is accepted by current recording validator"):return false
 if not finance_matches():return false
 var preview_before: Dictionary=owner.game.career.duplicate(true)
 if not step(Recordings.preview(owner.game.career,["original:1","original:2"]),"current demo preview accepts settled fixture"):return false
 if not check(owner.game.career==preview_before,"fixture preview retains its source"):return false
 fixture_hash=JSON.stringify(owner.snapshot()).sha256_text()
 trace.append({"fixture":"12 original-model writing calls with original availability/informal-practice preparation; one original linked recording; explicit current title/quality contrast", "saved_hash":fixture_hash,"not_native_writing":true,"not_a_revision_feature":true})
 return true

func mount_menu() -> bool:
 if is_instance_valid(scene):scene.free();scene=null;await settle()
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=true;scene.reduced_motion=true
 root.add_child(scene)
 await settle()
 return await free_action("ContinueAction",true)

func archive_release_unknown() -> bool:
 if baseline:return true
 var view=load("res://experiments/playable_flightcase/recording_desk.gd")
 var holder:=VBoxContainer.new()
 var notes:=VBoxContainer.new()
 holder.add_child(notes)
 var before: Dictionary=guard()
 view._session_facts(desk(),holder,{},90,false,notes)
 view._session_facts(desk(),holder,{"released":false},91,false,notes)
 var unknown: Label=holder.find_child("RecordingReleaseStatus_90",true,false) as Label
 var unreleased: Label=holder.find_child("RecordingReleaseStatus_91",true,false) as Label
 var ok: bool=check(unknown!=null and unknown.text=="RELEASE NOT RECORDED" and unreleased!=null and unreleased.text=="UNRELEASED","absent legacy release is distinct from explicitly unreleased")
 holder.free()
 return unchanged(before,"legacy release presentation") and ok

func desk():
 return scene.get("_career_view") if is_instance_valid(scene) else null

func songbook_recording_practice() -> bool:
 if not await mount_menu():return false
 if not await free_action("PosterNav_make") or not await free_action("CareerHome_songs"):return false
 if not check(desk()!=null and desk().page=="songs","real Make → Songbook"):return false
 if not await capture("songbook-entry"):return false
 if not await inspect_summary("book_0",91,"songbook"):return false
 if not await scroll_proof("CareerScroll"):return false
 if not await free_action("CareerRecordingAction"):return false
 if not check(desk().page=="recording" and desk().recording_mode=="select","actual songbook recording selection route"):return false
 if not await capture("recording-selection-entry"):return false
 if not await inspect_summary("record_original_1",91,"recording-selection"):return false
 if not await free_action("RecordingSong_original_1") or not await free_action("RecordingSong_original_2"):return false
 if not await free_action("RecordingUp_original_2"):return false
 var order: Array=desk().recording_ids.duplicate(true)
 if not check(order==["original:2","original:1"],"actual demo controls retain selected order"):return false
 if not await inspect_summary("record_original_1",91,"recording-selected"):return false
 if not check(desk().recording_ids==order,"details leave unsaved demo order unchanged"):return false
 if not await capture("recording-selected-order"):return false
 if not await free_action("RecordingArchiveAction"):return false
 if not archive_release_unknown():return false
 if not await capture("recording-archive-entry"):return false
 if not await free_action("DemoTrackNotes_0"):return false
 if not await capture("recording-archive-open"):return false
 if not await inspect_summary("take_0_0",72,"recording-captured"):return false
 if not check(Recordings.sessions(owner.game.career)[0]["song_links_v1"]["snapshots"][0]["title"]=="CAPTURED LAST TRAIN","archive keeps original title after current title differs"):return false
 if not await free_action("RecordingBackSongsAction") or not await free_action("CareerPracticeAction"):return false
 if not await free_action("PracticeMode_tighten"):return false
 if not check(named("RehearseAction")!=null,"real rehearsal action remains present"):return false
 if not await capture("rehearsal-entry"):return false
 if not await inspect_summary("practice_0",91,"rehearsal-originals"):return false
 if not await scroll_proof("PracticeScroll"):return false
 if not await free_action("CareerDeskAction"):return false
 return true

func actual_reload() -> bool:
 var before: Dictionary=guard()
 if not await free_action("CareerMenuAction") or not await free_action("CareerPauseExitTitle"):return false
 if not await free_action("ContinueAction",true):return false
 if not unchanged(before,"actual Pause → Title → Continue"):return false
 var reloaded=Owner.new()
 if not check(reloaded.load_draft() and reloaded.snapshot()==owner.snapshot(),"fresh real Owner reload retains every field"):return false
 return unchanged(before,"fresh owner reread")

func soundcheck_fixture() -> bool:
 if is_instance_valid(scene):scene.free();scene=null;await settle()
 if not fixture_live("book_flow","standard"):return false
 var due: int=int(Calendar.pending(owner.game.career)["day"])
 if not check(due>=int(owner.game.career.tour_day) and due<=int(owner.game.career.tour_day)+14,"bounded actual booking date"):return false
 while int(owner.game.career.tour_day)<due:
  if not fixture_jam():return false
 if not check(int(owner.game.career.tour_day)==due,"genuine model days reach the booked date"):return false
 if not fixture_live("depart") or not fixture_live("advance"):return false
 var visit: Dictionary=Journey.begin(owner.game.career,"",false)
 if not step(visit,"existing compatible soundcheck journey"):return false
 owner.game.career=visit["state"]
 if not step(owner.save_draft(),"persist soundcheck QA setup"):return false
 if not finance_matches():return false
 if not step(Flow.validate(owner.game.career),"valid current show flow") or not step(Journey.validate(owner.game.career),"valid pinned current journey"):return false
 if not check(Flow.phase(owner.game.career)=="soundcheck" and int(owner.game.career.tour_day)==int(Calendar.pending(owner.game.career).day),"current soundcheck on actual booking day"):return false
 trace.append({"fixture":"original local-booking/daily informal-practice/depart/arrival APIs with original settlement before Journey.begin; no clock jump or incident injection", "phase":Journey.active(owner.game.career).get("phase")})
 return check(Journey.active(owner.game.career).get("phase")=="soundcheck","real saved soundcheck phase")

func setlist() -> bool:
 if not await soundcheck_fixture() or not await mount_menu():return false
 if not check(desk()!=null and desk().page=="gigs","saved soundcheck resumes actual gig UI"):return false
 if not await capture("setlist-entry"):return false
 if not await inspect_summary("set_original_1",91,"setlist"):return false
 if not await free_action("ShowSong_original_3") or not await free_action("ShowSong_original_4"):return false
 if not await free_action("ShowUp_original_4"):return false
 var draft: Dictionary=desk().show_draft.duplicate(true)
 if not check(draft["song_ids"]==["original:1","original:4","original:2"],"actual set controls choose and reorder songs"):return false
 if not await inspect_summary("set_original_1",91,"setlist-selected"):return false
 if not check(desk().show_draft==draft,"summary preserves entire unsaved set draft"):return false
 if not await capture("setlist-selected-order"):return false
 if not await scroll_proof("CareerScroll"):return false
 var before: Dictionary=guard()
 var fresh=Owner.new()
 if not check(fresh.load_draft() and fresh.snapshot()==owner.snapshot(),"saved soundcheck survives fresh exact reload"):return false
 return unchanged(before,"setlist inspection and reread")

func run() -> void:
 deadline=Time.get_ticks_msec()+150000
 work_root=work_root.simplify_path().trim_suffix("/")
 output=output.simplify_path()
 var user_dir: String=ProjectSettings.globalize_path("user://").simplify_path()
 if not check(work_root.is_absolute_path() and work_root.length()>12 and output.begins_with(work_root+"/") and user_dir.begins_with(work_root+"/"),"strict fresh isolated work/output/user boundary"):finish();return
 if not check(DirAccess.dir_exists_absolute(output),"runner owns fresh output directory"):finish();return
 for value in file_state().values():
  if not check(not value["exists"] and not value["directory"],"no pre-existing owner/protected saves"):finish();return
 if not fixture_only:
  Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
  if not check(DisplayServer.is_touchscreen_available(),"effective native touch emulation; not a physical-phone test"):finish();return
 if not fixture():finish();return
 if fixture_only:
  if not await soundcheck_fixture():finish();return
  var fresh=Owner.new()
  check(fresh.load_draft() and fresh.snapshot()==owner.snapshot(),"headless fixture exact isolated reload")
  finish();return
 if not await visual_zero_unknown():finish();return
 if not await songbook_recording_practice():finish();return
 if not await actual_reload():finish();return
 if not await setlist():finish();return
 finish()

func finish() -> void:
 var size: Vector2i=DisplayServer.window_get_size()
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"errors":failures,"baseline":baseline,
  "viewport":[size.x,size.y],"engine":Engine.get_version_info(),"user_directory":ProjectSettings.globalize_path("user://"),
  "fixture_hash":fixture_hash,"images":images,"trace":trace,"physical_Android":false,"audio_listening":false,
  "mode":"headless fixture only" if fixture_only else "native comparison",
  "known_baseline_defects":baseline_defects,"candidate_acceptance_eligible":not baseline and not fixture_only,
  "method":"Original-model fixture setup and reload only; no native UI, pixel or input claim." if fixture_only else "Explicit original-model QA fixtures; real retained opening UI; pointer/Enter/touch; exact owner and save-byte guards; actual Menu/Continue plus fresh owner reload. Baseline known defects remain observations, not candidate passes. No paid UI commitment or new gameplay-model claim."}
 if not output.is_empty() and output.is_absolute_path() and not work_root.is_empty() and output.begins_with(work_root+"/"):
  var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
  if receipt!=null:receipt.store_string(JSON.stringify(result,"  "));receipt.close()
 print(("SONG55_FIXTURE " if fixture_only else "SONG55_NATIVE ")+JSON.stringify(result))
 if is_instance_valid(scene):scene.free();scene=null
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
