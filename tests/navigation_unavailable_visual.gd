extends "res://tests/band_stories_visual.gd"
const Day=preload("res://experiments/playable_flightcase/day_navigation.gd")

func unchanged(before: Dictionary,label: String) -> void:
 check(owner.snapshot()==before,"no cost/day/state on "+label)

func finish_day() -> void:
 await settle()
 if is_instance_valid(scene._practice_view._session_overlay):await tap("SkipSessionBeatAction")

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not check(fresh(),"real owner band"):finish();return
 for _day in range(7):
  if Day.inspect(owner.game.career).count==0:break
  if not check(await advance_day(),"actual days to authored nobody-free evening"):finish();return
 if not check(Day.inspect(owner.game.career).count==0,"actual nobody-free evening"):finish();return
 await mount();scene._open_career_desk();await settle()
 var before: Dictionary=owner.snapshot()
 await capture("home-nobody")
 check((scene.find_child("PosterNextAction",true,false) as Button).text.contains("QUIET"),"Home offers useful nobody-free action")
 if not await tap("PosterNextAction"):finish();return
 check(scene._practice_view.practice_activity=="jam","career-to-existing-pane honors jam")
 unchanged(before,"quiet preview")
 await capture("quiet-preview")
 await tap("PracticeMode_tighten")
 check(scene.find_child("RehearseAction",true,false)==null and scene.find_child("PracticeAlternativeAction",true,false)!=null,"no paid dead-end rehearsal action")
 check(scene.find_child("PracticeBackAction",true,false)==null,"duplicate Desk action removed")
 await capture("blocked-rehearsal")
 await tap("PracticePlanningAction")
 check(scene._career_view.page=="situation","real optional planning page")
 await reveal(scene.find_child("WeekEveningAction",true,false));await capture("planning-escape")
 unchanged(before,"planning preview")
 await tap("WeekEveningAction")
 check(scene._practice_view.practice_activity=="jam","planner escape honors actual jam route")
 await tap("CareerDeskAction")
 check(scene._career_view.page=="home" and not scene._career_view.poster_activities_open,"one explicitHome never silently reopens planner")
 unchanged(before,"returnHome")
 # Exercise the constructor path as well as a retained pane, without altering saved gameplay.
 scene._practice_view.free();await settle()
 await tap("PosterNextAction")
 check(scene._practice_view.practice_activity=="jam","career-to-first-pane honors jam")
 await tap("CareerDeskAction")
 var recipe: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 check(owner.begin_workbench("Evening paper",0,owner.workbench_expected(),recipe).ok,"actual free unfinished sketch")
 scene._career_view._render();await settle();await tap("PosterNav_make");await tap("PosterWriteAction")
 var desk=scene.find_child("MixingDesk",true,false)
 if not check(desk!=null,"real integrated writing room"):finish();return
 check(desk._commit.text.contains("QUIET") and not desk._commit.disabled,"writing dock offers quiet evening rather than no-day planner")
 before=owner.snapshot()
 await tap("Choice_tone_2");await tap("MixingCommit")
 check(is_instance_valid(desk._dialog),"dirty quiet exit guarded")
 await capture("dirty-exit")
 await tap("MixingExitKeep");unchanged(before,"keep shaping")
 await tap("MixingCommit");await failure_action("MixingExitSave","dirty-draft")
 check(is_instance_valid(desk._dialog) and desk._recipe.tone=="biting","save failure retains exact local draft")
 await tap("MixingExitSave")
 check(int(owner.game.career.tour_day)==int(before.game.career.tour_day) and int(owner.game.career.cash)==int(before.game.career.cash),"free draft exit never advances time")
 check(scene._practice_view.practice_activity=="jam","saved draft proceeds to actual quiet preview")
 before=owner.snapshot()
 await failure_action("InformalPracticeAction","quiet-evening")
 var start: Button=scene.find_child("InformalPracticeAction",true,false) as Button
 await reveal(start)
 var old_point: Vector2=root.get_final_transform()*start.get_global_transform_with_canvas()*(start.size/2)
 if not await tap("InformalPracticeAction"):finish();return
 var just_saved: Dictionary=owner.snapshot()
 await point_click(old_point)
 check(owner.snapshot()==just_saved,"stale rapid pointer cannot start a second evening")
 await finish_day()
 check(int(owner.game.career.tour_day)==int(before.game.career.tour_day)+1,"quiet evening advances exactly one day")
 check(owner.game.career.members==before.game.career.members and owner.game.career.relationships==before.game.career.relationships,"quiet evening never credits absent players")
 check(owner.game.career.get("readiness",0)==before.game.career.get("readiness",0),"no pretend full rehearsal readiness")
 check(owner.game.career.get("recorded_phrase_uses_v1",{})==before.game.career.get("recorded_phrase_uses_v1",{}),"quiet day consumes no phrase")
 check(owner.workbench_view().project.fragment.producer_recipe.tone=="biting","saved song direction survives quiet day")
 var durable: Dictionary=owner.snapshot()
 await capture("quiet-saved")
 scene._home();await settle();scene._continue();await settle();scene._open_career_desk();await settle()
 unchanged(durable,"Menu/Continue")
 var reload=Owner.new();check(reload.load_draft() and reload.snapshot()==durable,"actual day and sketch typed reload")
 scene._career_view._navigate("home");await settle();await capture("tomorrow-home")
 check(Day.inspect(owner.game.career).count==Situation.inspect_rehearsal(owner.game.career).attendee_indices.size(),"tomorrow availability recomputes from saved actual day")
 finish()

func finish() -> void:
 print("NAVIGATION_UNAVAILABLE_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
