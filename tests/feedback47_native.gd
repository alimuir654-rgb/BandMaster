extends SceneTree
const Style=preload("res://experiments/playable_flightcase/identity_style.gd")
const Chat=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Promoters=preload("res://experiments/playable_flightcase/promoter_profiles.gd")
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
var owner
var scene
var output:=""
var baseline:=false
var home_only:=false
var failures: Array=[]
var checks:=0
var observations: Dictionary={}

func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
  if arg=="--baseline":baseline=true
  if arg=="--home-only":home_only=true
 call_deferred("run")

func check(ok: bool,words: String) -> bool:
 checks+=1
 if not ok:failures.append(words);push_error(words)
 return ok

func settle() -> void:
 for _i in range(6):await process_frame

func capture(label: String) -> void:
 await settle();await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(output+"-"+label+".png")==OK,"capture "+label)

func reveal(node: Control) -> void:
 var parent: Node=node.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(node)
  parent=parent.get_parent()
 await settle()

func tap(name: String) -> bool:
 var button: Button=scene.find_child(name,true,false) as Button
 if not check(button!=null and button.is_visible_in_tree() and not button.disabled,"available "+name):return false
 await reveal(button)
 var point: Vector2=root.get_final_transform()*button.get_global_transform_with_canvas()*(button.size/2)
 for down in [true,false]:
  var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
  Input.parse_input_event(event);await process_frame
 await settle();return true

func drag(scroll: ScrollContainer,target: Control,reset_top: bool=true) -> Dictionary:
 if reset_top:scroll.scroll_vertical=0
 await settle()
 var area: Rect2=target.get_global_rect().intersection(scroll.get_global_rect())
 var point: Vector2=root.get_final_transform()*(area.position+area.size/2)
 var initial: int=scroll.scroll_vertical
 var seen: Array=[]
 var observer: Callable=func(event: InputEvent):seen.append(event.get_class())
 scroll.gui_input.connect(observer)
 var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=true;Input.parse_input_event(event);await process_frame
 for i in range(10):
  var move:=InputEventScreenDrag.new();move.index=0;move.position=point+Vector2(0,-12*(i+1));move.relative=Vector2(0,-12);move.velocity=Vector2(0,-360)
  Input.parse_input_event(move);await process_frame
 event=InputEventScreenTouch.new();event.index=0;event.position=point-Vector2(0,120);event.pressed=false;Input.parse_input_event(event)
 var stable:=0;var prior: int=scroll.scroll_vertical
 for _i in range(150):
  await process_frame
  var now: int=scroll.scroll_vertical
  stable=stable+1 if now==prior else 0
  prior=now
  if stable>=10:break
 scroll.gui_input.disconnect(observer)
 return {"initial":initial,"final":scroll.scroll_vertical,"range":scroll.get_v_scroll_bar().max_value-scroll.get_v_scroll_bar().page,"events":seen,"target_filter":target.mouse_filter}

func fixture() -> bool:
 owner=Owner.new()
 if not check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"fresh isolated fixture"):return false
 for id in ["cast_bex","cast_ben","cast_casey"]:
  if not check(owner.recruit(id).get("ok",false),"real recruit "+id):return false
 if not check(owner.choose_vocal("cast_bex").get("ok",false) and owner.confirm_lineup().get("ok",false),"real lead and lineup"):return false
 if not check(owner.start_naming() and owner.submit_name("Munch","Raw").get("ok",false) and owner.lock_name().get("ok",false) and owner.start_identity(),"real naming route"):return false
 return check(owner.finish_identity({"version":1,"font":"handpainted","ink":"burnt_amber"}).get("ok",false),"real final identity save")

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not await fixture():await finish();return
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;root.add_child(scene);await settle()
 var heights: Dictionary={}
 for id in ["cast_bex","cast_ben","cast_casey"]:
  var portrait: Control=scene.find_child("IdentityPortrait_"+id,true,false)
  check(portrait!=null,"formation actual identity "+id)
  if portrait!=null:heights[id]=portrait.get_meta("visible_figure_height",0.0)
 observations["formation_heights"]=heights
 if not baseline and heights.size()==3:
  var sizes: Array=heights.values();sizes.sort()
  check(float(sizes.back())-float(sizes.front())>20.0,"visible varied stature in exact owner lineup")
  check(scene.find_child("IdentityRehearsalRoom",true,false)!=null,"source-backed formation place")
 await capture("formation")
 if not await tap("StartPlayAction"):await finish();return
 if scene.find_child("PosterActivitiesAction",true,false)!=null and scene.find_child("PosterWriteAction",true,false)==null:await tap("PosterActivitiesAction")
 for key in ["CareerDate","CareerMenuAction","PosterNav_home","PosterNav_gigs"]:
  var persistent: Control=scene.find_child(key,true,false)
  check(persistent!=null and persistent.is_visible_in_tree() and scene.get_global_rect().encloses(persistent.get_global_rect()),"persistent home control bounded "+key)
 await capture("home")
 if home_only:await finish();return
 if not baseline:
  var seen_icons: Dictionary={}
  for route in ["create","practice","gigs","recording","promotion","offstage"]:
   var icon: TextureRect=scene.find_child("CareerLauncherIcon_"+route,true,false)
   check(icon!=null and icon.texture!=null,"real icon "+route)
   if icon!=null:seen_icons[str(icon.get_meta("source",""))]=true
  check(seen_icons.size()==6,"six distinct semantic primary icons")
 if not await tap("PosterNav_gigs"):await finish();return
 await capture("venues-before-drag")
 var view=scene._career_view
 var scroll: ScrollContainer=scene.find_child("CareerScroll",true,false)
 var local: Button=scene.find_child("BookingVenue_local",true,false)
 if not check(scroll!=null and local!=null,"actual venue list"):await finish();return
 var frame: Control=local.get_parent().get_parent()
 var before: Dictionary=owner.snapshot()
 observations["venue_card_drag"]=await drag(scroll,frame)
 check(owner.snapshot()==before and view.booking_step=="rooms","venue drag never commits or selects")
 if not baseline and observations.venue_card_drag.range>8:check(observations.venue_card_drag.final>8,"touch over venue card actually scrolls")
 if not baseline:
  for _i in range(4):await drag(scroll,scroll,false)
  check(scroll.scroll_vertical>=scroll.get_v_scroll_bar().max_value-scroll.get_v_scroll_bar().page-2,"real repeated touch reaches deepest venue")
  var point: Vector2=root.get_final_transform()*(scroll.get_global_rect().position+scroll.size/2)
  var prior: int=scroll.scroll_vertical
  var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.position=point;wheel.global_position=point;wheel.pressed=true
  Input.parse_input_event(wheel);await settle()
  wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.position=point;wheel.global_position=point;wheel.pressed=false
  Input.parse_input_event(wheel);await settle()
  if prior>8:check(scroll.scroll_vertical<prior,"wheel also scrolls venue list")
  check(owner.snapshot()==before and view.booking_step=="rooms","deep scroll and wheel never select or spend")
 await capture("venues-after-drag")
 # Finish kinetic scrolling, then return with the actual scrollbar key.
 scroll.get_v_scroll_bar().grab_focus()
 for down in [true,false]:
  var home:=InputEventKey.new();home.keycode=KEY_HOME;home.pressed=down
  Input.parse_input_event(home);await process_frame
 for _i in range(20):await process_frame
 await reveal(local)
 if not await tap("BookingVenue_local"):await finish();return
 await capture("promoter-local")
 if not baseline:
  var portrait: TextureRect=scene.find_child("BookingPromoterPortrait",true,false)
  check(portrait!=null and portrait.texture!=null and portrait.get_meta("promoter_id","")=="mo_farrow","actual named local promoter portrait")
  var heading: Label=scene.find_child("BookingPromoterHeading",true,false)
  if not check(heading!=null and heading.text=="MO FARROW","promoter identity visible"):await finish();return
 if not baseline:
  await extended_journey()
  await logo_journey()
 await finish()

func finish() -> void:
 if is_instance_valid(scene):scene.free()
 scene=null;owner=null;Style._font_cache.clear()
 await create_timer(0.25).timeout
 await settle()
 print("FEEDBACK47_NATIVE "+JSON.stringify({"checks":checks,"failures":failures,"baseline":baseline,"viewport":str(root.size),"observations":observations,"physical_Android":false}))
 quit(0 if failures.is_empty() else 1)

func extended_journey() -> void:
 # Explicit eligible test fixture; not an earned day-one career claim.
 owner.game.career.reputation=100;owner.game.career.fans=10000
 check(owner.save_draft(),"save explicitly eligible promoter fixture")
 scene._career_view._open_booking();await settle()
 if not await tap("BookingVenue_local"):return
 observations["later_promoters_fixture"]="manual eligible reputation/fans; original day-one locked gates retained"
 var unchanged: Dictionary=owner.snapshot()
 for room in ["bristol","cardiff","birmingham","manchester","london"]:
  if not await tap("BookingBackAction"):return
  if not await tap("BookingVenue_"+room):return
  var portrait: TextureRect=scene.find_child("BookingPromoterPortrait",true,false)
  check(portrait!=null and portrait.get_meta("promoter_id")==Promoters.ROOMS[room],"actual venue contact "+room)
  check(owner.snapshot()==unchanged,"meeting a promoter is free "+room)
  if room in ["cardiff","manchester"]:await capture("promoter-"+room)
 var view=scene._career_view
 view._navigate("band");await settle()
 if not await tap("CareerTalk_cast_bex"):return
 await capture("chat-before")
 var before: Dictionary=owner.snapshot()
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"block actual chat save")
 await tap("ChatReply_write_together")
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"failed actual chat save rolls back memory and disk")
 check(scene.find_child("MusicianChatSavedReply",true,false)==null,"failed reply never shown as saved")
 check(DirAccess.remove_absolute(blocker)==OK,"remove isolated chat blocker")
 await tap("ChatReply_write_together")
 var reply: Label=scene.find_child("MusicianChatSavedReply",true,false)
 var saved: Dictionary=Chat.record(owner.game.career,"cast_bex")
 check(reply!=null and reply.is_visible_in_tree() and reply.text==saved.turns.back().reply,"actual saved reply visible without history disclosure")
 check(not view.chat_history_open,"saved reply not hidden behind history")
 await reveal(reply);await capture("chat-saved-reply")
 var after: Dictionary=owner.snapshot()
 check(not owner.answer_musician(before,"cast_bex","direction","write_together").get("ok",false) and owner.snapshot()==after,"replayed reply cannot settle twice")
 var restored=Owner.new()
 check(restored.load_draft() and restored.snapshot()==after,"strict chat and promoter-state reload")
 await tap("ChatBack");await tap("CareerTalk_cast_ben")
 var voices: Array=[]
 for label in scene.find_children("*","Label",true,false):voices.append(label.text)
 check("Ben:" in voices and not Chat.VOICES.cast_bex in voices,"different musician opens their own conversation")
 await capture("chat-ben")

func logo_journey() -> void:
 scene.free();await settle()
 owner=Owner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"six-person identity fixture")
 for id in ["cast_tom","cast_ben","cast_dan","cast_ellis","cast_nina","cast_jack"]:
  if not check(owner.recruit(id).get("ok",false),"six actual recruits "+id):return
 check(owner.choose_vocal("cast_nina").get("ok",false) and owner.confirm_lineup().get("ok",false),"real six-person lead and lineup")
 var full_name: String="THE MIDNIGHT ÉCHO 東京 COLLECTIVE"
 if not check(owner.start_naming() and owner.submit_name(full_name,"Raw").get("ok",false) and owner.lock_name().get("ok",false) and owner.start_identity(),"real long Unicode naming route"):return
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;root.add_child(scene);await settle()
 var saved: Dictionary=owner.snapshot()
 for kind in Style.LAYOUTS:
  if not await tap("IdentityLayout_"+kind):return
  var mark: Label=scene.find_child("IdentityLiveMark",true,false)
  check(mark!=null and mark.full_name==full_name and Style.layout_kind(mark.identity_style)==kind,"live Unicode mark "+kind)
  check(owner.snapshot()==saved,"preview is free "+kind)
  if kind in ["stacked","cutout","xerox"]:
   await reveal(mark);await capture("logo-"+kind)
 await tap("IdentityLayout_stencil")
 var draft: Dictionary=scene.identity_draft.duplicate(true)
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"block actual identity save")
 await tap("IdentityFinishAction")
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk and scene.identity_draft==draft,"failed identity save retains complete old owner and local mark")
 check(DirAccess.remove_absolute(blocker)==OK,"remove isolated identity blocker")
 await tap("IdentityFinishAction")
 check(owner.identity_complete and owner.game.roster.size()==6 and Style.layout_kind(owner.identity_style)=="stencil","real logo commit retains six people and direction")
 var restored=Owner.new()
 check(restored.load_draft() and restored.snapshot()==owner.snapshot(),"strict new logo and six-person reload")
 await capture("six-formed")
 check(owner.start_playing(),"real six-person start")
