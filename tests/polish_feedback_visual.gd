extends "res://tests/character_consequence_visual.gd"
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")

func mount() -> void:
 if is_instance_valid(scene):scene.free()
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true
 root.add_child(scene);await settle()

func drag_scroll(scroll: ScrollContainer,target: Control,label: String,reset_top: bool=true,direction: float=-1.0,expect_movement: bool=true) -> void:
 var bar: VScrollBar=scroll.get_v_scroll_bar()
 if bar.max_value<=bar.page+8:
  check(true,"all content fits without scroll "+label);return
 if reset_top:scroll.scroll_vertical=0
 await settle()
 var area: Rect2=target.get_global_rect().intersection(scroll.get_global_rect())
 if not check(area.size.x>8 and area.size.y>8,"visible drag target "+label):return
 var point: Vector2=root.get_final_transform()*(area.position+area.size/2)
 var before: Dictionary=owner.snapshot()
 var initial: float=bar.value
 var seen: Array=[]
 var observer: Callable=func(event: InputEvent):seen.append(event.get_class())
 scroll.gui_input.connect(observer)
 var down:=InputEventScreenTouch.new();down.index=0;down.pressed=true;down.position=point
 Input.parse_input_event(down);await process_frame
 for i in range(10):
  var move:=InputEventScreenDrag.new();move.index=0;move.position=point+Vector2(0,(i+1)*12*direction)
  move.relative=Vector2(0,12*direction);move.velocity=Vector2(0,360*direction)
  Input.parse_input_event(move);await process_frame
 var up:=InputEventScreenTouch.new();up.index=0;up.pressed=false;up.position=point+Vector2(0,120*direction)
 Input.parse_input_event(up)
 var stable:=0;var prior: float=bar.value
 for _i in range(120):
  await process_frame
  var current: float=bar.value
  stable=stable+1 if absf(current-prior)<0.01 else 0
  prior=current
  if stable>=5:break
 check(absf(bar.value-initial)>8 if expect_movement else absf(bar.value-initial)<1,"real touch behavior "+label)
 print("TOUCH_PROBE "+JSON.stringify({"label":label,"point":str(point),"scroll":str(scroll.get_global_rect()),"initial":initial,"final":bar.value,"events":seen}))
 scroll.gui_input.disconnect(observer)
 check(owner.snapshot()==before,"touch drag has no recruitment/save effect "+label)

func advance_day() -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var available: Dictionary=Situation.inspect_rehearsal(before)
 if not available.get("ok",false):return false
 var jam: Dictionary=owner.game.informal_practice(available.attendee_indices)
 if not jam.get("ok",false):return false
 var tracked: Dictionary=Situation.after_action(before,owner.game.career)
 if not tracked.get("ok",false):return false
 var result: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:jam")
 if not result.get("ok",false):return false
 owner.game.career=result.state
 return owner.save_draft()

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 check(DisplayServer.is_touchscreen_available(),"desktop touch emulation enabled, not physical Android")
 owner=Owner.new()
 if not check(not output.is_empty() and owner.begin_new(),"isolated new owner"):finish();return
 await mount();await tap("Genre_Indie_rock")
 if not baseline:
  var saved: Dictionary=owner.snapshot()
  var player=scene.find_child("GenreRecordedAudio",true,false)
  check(player!=null and not player.playing,"genre browse does not autoplay")
  await tap("GenreHearA");check(player.playing and player.current_recipe().hook=="rehearsal_01_v1","real recorded idea A")
  await tap("GenreHearB");check(player.playing and player.current_recipe().hook=="rehearsal_04_v1","different recorded passage B")
  await tap("GenreStopRecorded");check(not player.playing and owner.snapshot()==saved,"audio comparison remains free")
  check(not scene.find_child("GenreRecordedStatus",true,false).text.begins_with("PLAYING"),"stop clears actual playing caption")
 await capture("genre")
 await tap("GenreNextAction")
 if not check(owner.recruit("cast_arjun").get("ok",false) and owner.choose_vocal("cast_arjun").get("ok",false),"canonical one-member audition fixture"):finish();return
 await person("cast_arjun","Guitarist")
 if not baseline:
  var scroll: ScrollContainer=scene.find_child("RecruitProfileScroll",true,false)
  var strip: Control=scene.find_child("RecruitLineupSummary",true,false)
  check(not scroll.is_ancestor_of(strip) and strip.size.y<=56,"compact lineup does not push candidate down in scroll")
  check(scene.find_child("RecruitPortrait",true,false).custom_minimum_size.y>=176,"approved candidate portrait leads")
  var paper: Control=scene.find_child("AuditionPaper",true,false)
  paper.mouse_filter=Control.MOUSE_FILTER_STOP
  await drag_scroll(scroll,scene.find_child("RecruitPortrait",true,false),"old decorative stop filter",true,-1.0,false)
  paper.mouse_filter=Control.MOUSE_FILTER_PASS
  await drag_scroll(scroll,scene.find_child("RecruitPortrait",true,false),"candidate portrait")
  scroll.scroll_vertical=0;await settle()
  await tap("RecruitPracticalToggle")
  var details: Control=scene.find_child("RecruitPracticalContext",true,false)
  check(details.visible,"work/availability still readable")
  await drag_scroll(scroll,scene.find_child("RecruitPortrait",true,false),"expanded candidate")
  var toggle: Button=scene.find_child("RecruitPracticalToggle",true,false)
  await reveal(toggle)
  await drag_scroll(scroll,toggle,"button drag cancels tap",false,1.0)
  check(details.visible,"drag over details button never toggles it")
  scroll.scroll_vertical=0;await settle()
 await capture("audition-browse")
 for id in ["cast_hannah","cast_ellis"]:
  if not check(owner.recruit(id).get("ok",false),"canonical actual lineup "+id):finish();return
 if not check(owner.confirm_lineup().get("ok",false) and owner.start_naming() and owner.submit_name("NIGHT BUS CLUB","Raw").get("ok",false) and owner.lock_name().get("ok",false) and owner.start_identity(),"real named lineup"):finish();return
 scene._load_identity_draft();scene._render();await settle()
 if not baseline:
  var press=scene.find_child("IdentityPreviewPrint",true,false)
  check(press.visible_ids()==["cast_arjun","cast_hannah","cast_ellis"] and not press.uses_full_length(),"exact selected musicians in close portrait preview")
  check(scene.find_child("IdentityLivePreviewMark",true,false)==null,"one band name rather than competing repeated marks")
 await capture("identity-preview")
 if not baseline:
  var saved: Dictionary=owner.snapshot()
  await tap("IdentityType_condensed")
  check(owner.snapshot()==saved,"style preview remains free")
  await capture("identity-selected")
 await tap("IdentityFinishAction");await tap("StartPlayAction")
 var saved: Dictionary=owner.snapshot()
 await tap("PosterNav_make")
 var career=scene._career_view
 if not baseline:
  check(career._scroll.scroll_vertical<=2,"actual Make navigation starts at top")
  var heading: Label
  for node in scene.find_children("*","Label",true,false):
   if node.text=="WHAT'S THE PLAN?":heading=node;break
  check(heading!=null and career._scroll.get_global_rect().encloses(heading.get_global_rect()),"Make heading not cropped")
  for name in ["create","practice","gigs","recording","promotion","offstage"]:
   var label: Label=scene.find_child("CareerLauncherLabel_"+name,true,false)
   check(label.get_theme_font("font")==Poster.FONT,"readable action font "+name)
   var icon: TextureRect=scene.find_child("CareerLauncherIcon_"+name,true,false)
   check(icon.texture.get_size()==Vector2(48,48),"original vector rendered at real48px "+name)
  check(owner.snapshot()==saved,"Make navigation remains free")
 await capture("make")
 var recipe: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 recipe.hook="rehearsal_03_v1"
 check(owner.begin_workbench("The last bus home",0,owner.workbench_expected(),recipe).ok,"real free song sketch")
 var unavailable:=false
 for _day in range(7):
  var work: Dictionary=Situation.inspect_writing(owner.game.career)
  if work.get("ok",false) and not work.get("can_write",false):unavailable=true;break
  if not await advance_day():break
 check(unavailable,"actual authored commitments block full writing")
 scene._career_landing=false;scene._render();await settle()
 var desk=scene.find_child("MixingDesk",true,false)
 if not check(desk!=null,"existing writing room retains sketch"):finish();return
 await capture("unavailable-writing")
 if baseline:finish();return
 var available: Dictionary=Situation.inspect_writing(owner.game.career)
 check(not desk._commit.disabled and desk._commit.text!="BAND UNAVAILABLE","useful dock alternative enabled")
 var before: Dictionary=owner.snapshot();var day: int=owner.game.career.tour_day;var cash: int=owner.game.career.cash
 desk._choose("tone",2);await settle()
 await tap("MixingCommit")
 check(is_instance_valid(desk._dialog) and owner.snapshot()==before,"alternate preserves dirty-sketch guard and spends nothing")
 await tap("MixingExitKeep")
 check(desk._recipe.tone=="biting" and owner.snapshot()==before,"cancel retains local song direction")
 await tap("MixingCommit")
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject isolated alternative-route save failure")
 await tap("MixingExitSave")
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"failed alternative save preserves memory and disk")
 check(is_instance_valid(desk._dialog) and desk._recipe.tone=="biting","failed alternative save retains editable draft and guarded route")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated alternative blocker")
 await tap("MixingExitSave")
 check(owner.game.career.tour_day==day and owner.game.career.cash==cash,"saving sketch and routing stays free")
 if not available.attendee_indices.is_empty():
  var before_members: Array=owner.game.career.members.duplicate(true)
  var before_progress: int=owner.game.career.get("song_draft_progress",0)
  await capture("available-practice")
  await tap("InformalPracticeAction")
  check(owner.game.career.tour_day==day+1 and owner.game.career.cash==cash,"explicit jam uses exactly1day and no hire fee")
  check(owner.game.career.get("song_draft_progress",0)==before_progress,"jam does not advance unavailable song")
  for i in range(before_members.size()):
   if i not in available.attendee_indices:check(owner.game.career.members[i].get("skill")==before_members[i].get("skill"),"absent musician gets no invented practice "+str(i))
  await capture("practice-saved")
  var reloaded=Owner.new();check(reloaded.load_draft() and reloaded.snapshot()==owner.snapshot(),"actual consequence and sketch survive reload")
 finish()

func finish() -> void:
 print("POLISH_FEEDBACK_VISUAL "+JSON.stringify({"viewport":str(root.size),"baseline":baseline,"checks":checks,"failures":failures,"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
