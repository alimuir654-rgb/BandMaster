extends "res://experiments/playable_flightcase/recording_capture.gd"
## S56 SCRATCH ONLY. Root alone executes ONE native GL. All date variants are
## explicitly model-prepared display fixtures, not gameplay/booking journeys.
const CalendarOriginal = preload("res://Scripts/gig_calendar.gd")
const S56_ROOT := "/workspace/work/overnight-20261101/s56/"
var calendar_api: Variant
var totals_saves := 0
var totals_loads := 0
var case_name := ""

func verify(ok: bool, message: String) -> bool:
 checks+=1
 if not ok:
  failures.append(message)
  push_error("S56_CALENDAR_NATIVE "+message)
 return ok

func prepare_calendar_case(tag: String) -> bool:
 if is_instance_valid(screen):screen.free()
 screen=null;await frames(3)
 if model!=null:
  totals_saves+=model.saves;totals_loads+=model.loads
 if not make_fixture():return false
 case_name=tag
 if tag!="empty":
  var before: Dictionary=model.game.career.duplicate(true)
  var booked: Dictionary=CalendarOriginal.book(before,"local","tight",false,"drive_home")
  if not verify(bool(booked.get("ok",false)) and model.game.career==before,"pure ORIGINAL local booking prepares labelled display fixture only"):return false
  var original_booking: Dictionary=booked.state.booked_show.duplicate(true)
  model.game.career=booked.state
  if tag=="due":model.game.career["tour_day"]=4
  elif tag=="overdue":model.game.career["tour_day"]=5
  elif tag=="invalid-booking-date":model.game.career["booked_show"]["day"]="unreadable legacy date"
  trace.append({"kind":"EXPLICIT MODEL-PREPARED READ-ONLY DISPLAY FIXTURE, not native booking or time progression","case":tag,"original_booking":original_booking,"actual_fixture":model.game.career.duplicate(true)})
 if not fixture_step("save isolated calendar fixture "+tag,model.save_draft()):return false
 screen=RootUI.new();screen.name="S56CalendarActualNativeQA";screen.setup=model;screen.showing_menu=true;screen.reduced_motion=true
 root.add_child(screen);await frames(4)
 var saved: Dictionary=guard()
 if not await activate("ContinueAction","enter") or not unchanged(saved,"actual saved-calendar Continue "+tag,1) or not await wait_practice():return false
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice():return false
 # On a due/overdue show day the existing RootUI already opens the live desk
 # after Continue. Navigate its real DESK control rather than targeting the
 # hidden practice button; this is fixture routing, not a product bypass.
 if desk()!=null and desk().is_visible_in_tree():
  if not await free_action("CareerNav_home"):return false
 elif not await free_action("CareerDeskAction"):
  return false
 if not await free_action("CareerHome_calendar","pointer"):return false
 return verify(str(desk().get("page"))=="calendar" and desk().get("game")==model.game,"real Home CALENDAR opens actual same-game calendar: "+tag)

func calendar_facts(expected_status: String) -> bool:
 var before: Dictionary=guard()
 var value: Dictionary=calendar_api.summary(model.game.career)
 if not unchanged(before,"pure calendar summary "+case_name):return false
 if not verify(bool(value.today_valid) and int(value.today)==int(model.game.career.tour_day) and value.days.size()==15 and str(value.booking.status)==expected_status,"calendar summary reflects actual saved ordinal day/status without mutation: "+case_name):return false
 var today: Label=named("CalendarToday") as Label
 var status: Label=named("CalendarStatus") as Label
 if not verify(today!=null and today.text=="TODAY  /  DAY %d" % int(value.today) and inside(today) and today.get_theme_font_size("font_size")>=16 and status!=null and inside(status) and status.get_theme_font_size("font_size")>=16,"full legible today/booking status are in the initial fold: "+case_name):return false
 var markers: int=0
 for index in range(value.days.size()):
  var day: Dictionary=value.days[index]
  var label: Label=named("CalendarDay_"+str(day.day)) as Label
  var expected: String="DAY %d" % int(day.day)
  if bool(day.today):expected+="\nTODAY"
  if bool(day.booking):expected+="\nSHOW";markers+=1
  if not verify(int(day.day)==int(value.today)+index and bool(day.today)==(index==0) and label!=null and label.text==expected and label.focus_mode==Control.FOCUS_NONE and label.mouse_filter==Control.MOUSE_FILTER_IGNORE,"all15 passive ordinal cells match actual saved appointment only"):return false
 if expected_status in ["upcoming","due","overdue"]:
  var booking: Dictionary=CalendarOriginal.pending(model.game.career)
  var date: Label=named("CalendarBookingDay") as Label
  if not verify(value.booking.day==int(booking.day) and value.booking.venue==str(booking.venue) and value.booking.city==str(booking.city) and date!=null and inside(date) and (named("CalendarBookingVenue") as Label).text==str(booking.venue),"saved original appointment/date/venue remain factual and first-fold readable"):return false
  if not verify(markers==(0 if expected_status=="overdue" else 1),"overdue booking is retained without inventing a future appointment"):return false
 elif not verify(markers==0 and named("CalendarBookingDay")==null,"empty/invalid dates never fabricate an appointment marker"):return false
 if expected_status=="invalid":
  if not verify(not value.booking.valid and not value.issues.is_empty() and named("CalendarValidation")!=null,"malformed legacy booking date shows actual readable warning without changing it"):return false
 trace.append({"case":case_name,"summary":value,"snapshot_sha256":JSON.stringify(model.snapshot()).sha256_text()})
 return check_fixed_layout()

func native_calendar_scroll() -> bool:
 var before: Dictionary=guard()
 var scroll: ScrollContainer=named("CareerScroll") as ScrollContainer
 if not verify(scroll!=null and scroll.follow_focus,"calendar uses actual inherited focus-following scroll"):return false
 var bar: VScrollBar=scroll.get_v_scroll_bar()
 if bar.is_visible_in_tree() and bar.max_value>bar.page:
  for attempt in range(64):
   if bar.has_focus():break
   await key(KEY_TAB)
  if not verify(bar.has_focus() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bar.get_global_rect()),"real Tab reaches actual calendar scrollbar chrome"):return false
  await key(KEY_END);await frames(3)
  if not verify(bar.has_focus() and scroll.scroll_vertical==roundi(bar.max_value-bar.page),"real End reaches calendar saved-note tail"):return false
  if not await capture("calendar-"+case_name+"-saved-notes"):return false
  await key(KEY_HOME);await frames(3)
  if not verify(bar.has_focus() and scroll.scroll_vertical==0,"real Home restores calendar summary"):return false
 else:trace.append({"case":case_name,"native_scroll":"no overflow, no synthetic scrolling or content added"})
 return unchanged(before,"real calendar Tab/End/Home")

func native_calendar_touch() -> bool:
 var scroll: ScrollContainer=named("CareerScroll") as ScrollContainer
 var bar: VScrollBar=scroll.get_v_scroll_bar()
 if bar.max_value-bar.page<=48:
  trace.append({"case":"calendar genuine touch","status":"no real overflow; no false scroll claim"})
  return true
 var before: Dictionary=guard()
 var target: Control=named("CalendarStatus")
 if not verify(target!=null and inside(target),"calendar touch starts on actual visible native summary paper"):return false
 var previous_mouse: bool=Input.emulate_mouse_from_touch
 var previous_touch: bool=Input.emulate_touch_from_mouse
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 var capable: bool=DisplayServer.is_touchscreen_available()
 if not capable:
  Input.emulate_mouse_from_touch=previous_mouse;Input.emulate_touch_from_mouse=previous_touch
  return verify(false,"calendar touch precondition requires existing S51 native emulation capability")
 var point: Vector2=target.get_global_rect().get_center()
 var down:=InputEventScreenTouch.new();down.window_id=root.get_window_id();down.index=0;down.position=point;down.pressed=true
 Input.parse_input_event(down);await process_frame
 var after_press: int=scroll.scroll_vertical
 var samples: Array=[]
 for step in range(6):
  var delta:=Vector2(0,-16);point+=delta
  var drag:=InputEventScreenDrag.new();drag.window_id=root.get_window_id();drag.index=0;drag.position=point
  drag.relative=delta;drag.screen_relative=delta;drag.velocity=delta*60;drag.screen_velocity=delta*60
  Input.parse_input_event(drag);await process_frame;samples.append(scroll.scroll_vertical)
 var after_drag: int=scroll.scroll_vertical
 var up:=InputEventScreenTouch.new();up.window_id=root.get_window_id();up.index=0;up.position=point;up.pressed=false
 Input.parse_input_event(up);await frames(3)
 Input.emulate_mouse_from_touch=previous_mouse;Input.emulate_touch_from_mouse=previous_touch
 trace.append({"case":"calendar genuine ScreenTouch/Drag paper","after_press":after_press,"samples":samples,"after_drag":after_drag,"touchscreen_available":capable,"actual_scroll_deadzone":scroll.scroll_deadzone,"physical_device_claim":false})
 return verify(after_drag>after_press+24 and str(desk().get("page"))=="calendar","actual calendar paper drag scrolls beyond after-press by24 without navigation") and unchanged(before,"calendar native paper touch drag")

func free_reflow() -> bool:
 var before: Dictionary=guard()
 var identity: int=desk().get_instance_id()
 var original: Vector2i=root.size
 var alternate:=Vector2i(1280,720) if original.x<900 else Vector2i(390,844)
 for dimensions in [alternate,original]:
  root.size=dimensions;DisplayServer.window_set_size(dimensions);await frames(5)
  if not verify(desk()!=null and desk().get_instance_id()==identity and str(desk().get("page"))=="calendar","actual calendar resize retains owner/page"):return false
  if not await settled(named("CareerCalendarBackAction")) or not check_fixed_layout() or not unchanged(before,"free actual calendar resize"):return false
  if not await capture("calendar-booked-resize" if dimensions==alternate else "calendar-booked-restored"):return false
 if width==390:
  screen.set_meta("safe_area_test_sample",{"screen_safe_rect":Rect2(0,28,width,height-52),"viewport_to_screen":Transform2D.IDENTITY})
  screen.call("_refresh_safe_area");await frames(5)
  var safe_rect:=Rect2(0,28,width,height-52)
  if not await settled(named("CareerCalendarBackAction")) or not verify(safe_rect.encloses(named("CareerCalendarBackAction").get_global_rect()) and safe_rect.encloses(named("CareerCalendarLiveAction").get_global_rect()),"engine safe-inset sample contains both physical48 calendar fixed actions"):return false
  if not await capture("calendar-booked-safe-insets") or not unchanged(before,"calendar camera28/navigation24 safe engine sample"):return false
  screen.remove_meta("safe_area_test_sample");screen.call("_refresh_safe_area");await frames(5)
 return unchanged(before,"calendar reflow complete")

func real_menu_roundtrip() -> bool:
 var before: Dictionary=guard()
 if not await free_action("CareerCalendarBackAction","enter") or not verify(str(desk().get("page"))=="home","actual fixed calendar Back returns Home"):return false
 if not await free_action("CareerHome_calendar","space") or not await free_action("CareerMenuAction"):return false
 if not await activate("ContinueAction","enter") or not unchanged(before,"calendar Back/Home/Menu/actual disk Continue",1) or not await wait_practice():return false
 if named("RecapToggleAction")!=null:
  if not await free_action("RecapToggleAction") or not await wait_practice():return false
 if not await free_action("CareerDeskAction") or not await free_action("CareerHome_calendar"):return false
 return await capture("calendar-booked-reloaded")

func pure_malformed_today() -> bool:
 var before: Dictionary=guard()
 var bad: Dictionary=model.game.career.duplicate(true)
 bad["tour_day"]="legacy unreadable current day"
 var original_bad: Dictionary=bad.duplicate(true)
 var value: Dictionary=calendar_api.summary(bad)
 return verify(bad==original_bad and not value.today_valid and int(value.today)==0 and value.days.is_empty() and not value.issues.is_empty(),"PURE component invalid-current-day query invents no ordinal/date; never passed through unrelated original header casts") and unchanged(before,"pure malformed today query")

func journey() -> bool:
 if not await prepare_calendar_case("empty") or not calendar_facts("none") or not await capture("calendar-empty"):return false
 if not await free_action("CareerCalendarBackAction","enter") or not await free_action("CareerHome_calendar","space"):return false
 if not await prepare_calendar_case("booked") or not calendar_facts("upcoming") or not await capture("calendar-booked"):return false
 if not await free_reflow() or not await native_calendar_scroll():return false
 if width==390 and not await native_calendar_touch():return false
 if not await real_menu_roundtrip():return false
 for item in [["due","due"],["overdue","overdue"],["invalid-booking-date","invalid"]]:
  if not await prepare_calendar_case(str(item[0])) or not calendar_facts(str(item[1])) or not await capture("calendar-"+str(item[0])):return false
 return pure_malformed_today()

func run() -> void:
 var started: int=Time.get_ticks_msec();deadline=started+105000
 var user_dir: String=ProjectSettings.globalize_path("user://")
 output=ProjectSettings.globalize_path(output)
 var safe: bool=verify([Vector2i(390,844),Vector2i(720,1280),Vector2i(1280,720),Vector2i(1600,900)].has(Vector2i(width,height)) and user_dir.begins_with(S56_ROOT) and output.begins_with(S56_ROOT),"one real profile/fresh S56 userdata/output boundary")
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated calendar save path "+path) and safe
 if not safe:print("S56_CALENDAR_REFUSED ",JSON.stringify(failures));quit(1);return
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create S56 calendar captures"):quit(1);return
 calendar_api=load("res://experiments/playable_flightcase/calendar_desk.gd")
 if not verify(calendar_api!=null,"actual integrated pure calendar module exists"):quit(1);return
 protected_initial=files(true)
 root.size=Vector2i(width,height);DisplayServer.window_set_size(root.size);root.grab_focus();await frames(4)
 var orphan_before: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 await journey()
 if not failures.is_empty() and is_instance_valid(screen):await capture("FIRST-FAILURE")
 if model!=null:totals_saves+=model.saves;totals_loads+=model.loads
 if is_instance_valid(screen):screen.free()
 screen=null;await frames(4)
 var orphan_after: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 verify(files(true)==protected_initial,"calendar leaves all original legacy/C26 bytes unchanged")
 verify(orphan_after<=orphan_before,"zero calendar orphan growth after all actual owners freed")
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"errors":failures,"images":images,"width":width,"height":height,"engine":Engine.get_version_info(),"elapsed_ms":Time.get_ticks_msec()-started,"user_data":user_dir,"save_calls":totals_saves,"load_calls":totals_loads,"orphan_before":orphan_before,"orphan_after":orphan_after,"trace":trace,"method":"Genuine Root Menu/Continue/heldDAY acknowledgement→CareerDesk→HomeCalendar; free actual keys/pointer/Back/Menu/reload/windowresize/simulated safeinsets/native Tab-End-Home and phone touch. Empty and unchanged-original Calendar.book are explicit model-prepared fixtures; due/overdue/invalidbooking dates are labelled display fixtures, not booking or time gameplay. Invalid CURRENTtoday is pure summary only. Strict model/files/save guards surround every free operation; no calendar resolver/expiry/paid action or physical-device claim."}
 var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:push_error("S56_CALENDAR_NATIVE cannot write receipt");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close();print("S56_CALENDAR_NATIVE_RESULT ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
