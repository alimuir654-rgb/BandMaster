extends "res://tests/band_stories_visual.gd"
const Day=preload("res://experiments/playable_flightcase/day_navigation.gd")
const Recordings=preload("res://experiments/playable_flightcase/recording_rules.gd")
const RadioRules=preload("res://experiments/playable_flightcase/radio_visit_rules.gd")

func escape() -> void:
 for pressed in [true,false]:
  var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.physical_keycode=KEY_ESCAPE;event.pressed=pressed
  Input.parse_input_event(event);await process_frame
 await settle()

func no_state(before: Dictionary,label: String) -> void:
 check(owner.snapshot()==before,"no state/cost/day change "+label)

func write_song(title: String) -> bool:
 for _stage in range(3):
  for _day in range(7):
   if Situation.inspect_writing(owner.game.career).get("can_write",false):break
   if not await advance_day():return false
  var before: Dictionary=owner.game.career.duplicate(true)
  var written: Dictionary=owner.game.write_session("Riff","Verse / Chorus",title,0)
  if not check(written.get("ok",false),"genuine original for radio fixture"):return false
  var tracked: Dictionary=Situation.after_action(before,owner.game.career)
  if not tracked.ok:return false
  var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:create")
  if not accounted.ok:return false
  owner.game.career=accounted.state
  if not owner.save_draft():return false
 return true

func install_result(result: Dictionary,label: String) -> bool:
 if not check(result.get("ok",false),label+": "+str(result.get("message",""))):return false
 owner.game.career=result.state
 return check(owner.save_draft(),"saved "+label)

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not check(fresh(),"canonical future rehearsal fixture"):finish();return
 for _day in range(7):
  if Situation.inspect_rehearsal(owner.game.career).conflict:break
  if not await advance_day():finish();return
 var planned: Dictionary=Situation.reschedule(owner.game.career)
 if not install_result(planned,"actual saved future agreement"):finish();return
 await mount();scene._open_career_desk();await settle();scene._career_view._practice("tighten");await settle()
 var before: Dictionary=owner.snapshot()
 var date: Label=scene.find_child("SituationPracticePlan",true,false) as Label
 check(date!=null and date.text.contains(str(planned.plan.day)),"future rehearsal shows saved date")
 await capture("future-rehearsal")
 await tap("PracticePlanningAction")
 check(scene._career_view.page=="situation","actual planner origin for keyboard exit")
 await tap("CareerPracticeAction");await tap("PracticeMode_create")
 var recipe: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 if not check(owner.begin_workbench("The spare evening",0,owner.workbench_expected(),recipe).ok,"free sketch for keyboard route"):finish();return
 scene._practice_view._rebuild();await settle()
 var desk=scene.find_child("MixingDesk",true,false)
 if not check(desk!=null,"actual saved sketch editor after planner"):finish();return
 before=owner.snapshot()
 await tap("Choice_tone_2");await escape()
 check(is_instance_valid(desk._dialog),"dirtyEscape offers guarded exit")
 await escape();check(not is_instance_valid(desk._dialog) and desk._recipe.tone=="biting","Escape cancels exit and keeps local direction")
 no_state(before,"dirtyEscape cancel")
 await escape();await tap("MixingExitDiscard")
 check(scene._career_view.page=="home","dirtyEscape discard returnsHome rather than planner")
 no_state(before,"discard local edits toHome")
 scene._career_view._open_situation();await settle();await tap("CareerPracticeAction")
 await escape()
 check(scene._career_view.page=="home","cleanEscape uses sameHome route")
 no_state(before,"cleanEscape toHome")
 scene._career_view._practice("tighten");await settle();before=owner.snapshot()
 await tap("PracticeAlternativeAction");no_state(before,"future alternative preview")
 var count: int=Day.inspect(owner.game.career).count
 check((scene.find_child("InformalPracticeAction",true,false) as Button).text.contains("SOLO" if count==1 else ("QUIET" if count==0 else "JAM")),"preview matches actual future-day attendees")
 await capture("solo-or-jam-preview")
 await tap("InformalPracticeAction");await settle()
 if is_instance_valid(scene._practice_view._session_overlay):await tap("SkipSessionBeatAction")
 check(Situation.inspect_rehearsal(owner.game.career).plan.get("status")=="planned","informal practice never fulfils future rehearsal")
 # Mandatory destinations use real domain-owned fixtures; no fake saved wrappers.
 if not check(fresh(),"canonical gig lock fixture"):finish();return
 var state: Dictionary=owner.game.career.duplicate(true)
 var request: Dictionary={"venue_id":"local","offer_id":"standard","day":int(state.tour_day)+3,"travel_plan":"drive_home","session_drummer":false}
 if not install_result(Live.book_selected(state,request,Booking.expected(state)),"actual dated booking"):finish();return
 for _day in range(3):
  if not await advance_day():finish();return
 await mount();scene._open_career_home();await settle();before=owner.snapshot()
 check(scene._career_view.page=="gigs","Home preserves due-show priority")
 scene._career_view._practice("jam");await settle();no_state(before,"quiet route during due show")
 check(scene._career_view.page=="gigs","due show cannot be bypassed by jam")
 await capture("show-lock")
 if not check(fresh(),"canonical radio lock fixture"):finish();return
 if not await write_song("One more evening") or not await write_song("The quiet road"):finish();return
 if not install_result(Recordings.record(owner.game.career,["original:1","original:2"]),"actual demo recording"):finish();return
 var demo: Dictionary=Recordings.sessions(owner.game.career)[0]
 if not install_result(Recordings.release(owner.game.career,demo.id,Recordings.fingerprint(demo),0),"actual demo release"):finish();return
 demo=Recordings.sessions(owner.game.career)[0]
 if not install_result(RadioRules.begin(owner.game.career,demo.id,Recordings.fingerprint(demo),0),"actual radio checkpoint"):finish();return
 await mount();scene._open_career_home();await settle();before=owner.snapshot()
 check(scene._career_view.page=="recording" and RadioRules.locked(owner.game.career),"Home preserves saved radio visit")
 scene._career_view._practice("jam");await settle();no_state(before,"quiet route during radio")
 check(scene._career_view.page=="recording","radio cannot be bypassed")
 await capture("radio-lock")
 if not check(fresh(),"canonical final-accounts fixture"):finish();return
 var account: Dictionary=Finance.view(owner.game.career)
 account.game_over=true;account.broke_days=14;account.ended_day=int(owner.game.career.tour_day)
 owner.game.career[Finance.KEY]=account
 check(owner.save_draft(),"saved existing terminal account fixture")
 await mount();scene._open_career_home();await settle();before=owner.snapshot()
 check(scene._career_view.page=="finance","Home preserves final accounts")
 scene._career_view._practice("jam");await settle();no_state(before,"quiet route after band closed")
 check(scene._career_view.page=="finance","terminal accounts cannot be bypassed")
 await capture("finance-lock")
 finish()

func finish() -> void:
 print("NAVIGATION_EDGES_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
