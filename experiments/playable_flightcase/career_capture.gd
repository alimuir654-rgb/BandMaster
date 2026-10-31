extends SceneTree
## SCRATCH native S45 integration proof. Root alone executes an exact runtime.
## Uses actual Input, the corrected 448a clip predicate, and real isolated C27 IO.
## Never emits UI signals, calls UI action handlers, or scrolls programmatically.
const RootUI = preload("res://experiments/playable_flightcase/opening_ui.gd")
const Model = preload("res://experiments/playable_flightcase/opening_state.gd")
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Bridge = preload("res://experiments/playable_flightcase/career_bridge.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const SAFE_ROOT := "/workspace/work/unify/s45/"
const PENDING_TITLE := "UNSAVED S45 IDEA"

class DiskCountingOpeningModel extends Model:
 var saves: int = 0
 var loads: int = 0
 func save_draft() -> bool:
  saves += 1
  return super.save_draft()
 func load_draft() -> bool:
  loads += 1
  return super.load_draft()
 func has_valid_draft() -> bool:
  var trial := Model.new()
  return trial.load_draft()

var screen: Control
var model: DiskCountingOpeningModel
var width: int = 390
var height: int = 844
var output := "/workspace/work/unify/s45/career-capture"
var checks: int = 0
var failures: Array[String] = []
var images: Array[String] = []
var evidence: Array = []
var protected_initial: Dictionary = {}
var deadline: int = 0
var practice_id: int = 0

func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
  elif arg.begins_with("--size="):
   var values := arg.trim_prefix("--size=").split("x")
   if values.size()==2:
    width=int(values[0])
    height=int(values[1])
 call_deferred("run")

func verify(ok: bool, message: String) -> bool:
 checks+=1
 if not ok:
  failures.append(message)
  push_error("S45_CAREER_CAPTURE "+message)
 return ok

func frames(count: int=2) -> void:
 for index in range(count): await process_frame

func files(protected_only: bool=false) -> Dictionary:
 var result: Dictionary = {}
 var paths: Array = ["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]
 if not protected_only: paths.append(Model.SAVE_PATH)
 for path in paths:
  result[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return result

func guard() -> Dictionary:
 return {"snapshot":model.snapshot(),"files":files(),"saves":model.saves,"loads":model.loads}

func unchanged(before: Dictionary, label: String, allow_load: int=0) -> bool:
 return verify(model.snapshot()==before.snapshot and files()==before.files and model.saves==before.saves and model.loads==int(before.loads)+allow_load,"free UI operation preserved model/files/save counts: "+label)

func desk() -> Control:
 return screen.get("_career_view") as Control if is_instance_valid(screen) else null

func practice() -> Control:
 return screen.get("_practice_view") as Control if is_instance_valid(screen) else null

func named(node_name: String) -> Control:
 if not is_instance_valid(screen): return null
 for node in screen.find_children(node_name,"Control",true,false):
  if str(node.name)==node_name and node.is_visible_in_tree(): return node as Control
 return null

func pointer(point: Vector2) -> void:
 for down in [true,false]:
  var event := InputEventMouseButton.new()
  event.window_id=root.get_window_id()
  event.button_index=MOUSE_BUTTON_LEFT
  event.position=point
  event.global_position=point
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame

func key(code: int, shift: bool=false, ctrl: bool=false, unicode: int=0) -> void:
 for down in [true,false]:
  var event := InputEventKey.new()
  event.window_id=root.get_window_id()
  event.keycode=code
  event.physical_keycode=code
  event.shift_pressed=shift
  event.ctrl_pressed=ctrl
  event.unicode=unicode
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame

func inside(control: Control) -> bool:
 # Exact corrected 448a effective-clip method, including native scrollbar area.
 if not is_instance_valid(control) or not control.is_visible_in_tree(): return false
 var clip := Rect2(Vector2.ZERO,Vector2(root.size))
 var ancestor := control.get_parent()
 while ancestor!=null:
  if ancestor is Control and (ancestor as Control).clip_contents:
   var area: Rect2=(ancestor as Control).get_global_rect()
   if ancestor is ScrollContainer:
    var scroll:=ancestor as ScrollContainer
    var horizontal:=scroll.get_h_scroll_bar()
    var vertical:=scroll.get_v_scroll_bar()
    if horizontal.is_visible_in_tree():
     area.size.y=maxf(0.0,minf(area.end.y,horizontal.get_global_rect().position.y)-area.position.y)
    if vertical.is_visible_in_tree():
     area.size.x=maxf(0.0,minf(area.end.x,vertical.get_global_rect().position.x)-area.position.x)
   clip=clip.intersection(area)
  ancestor=ancestor.get_parent()
 return clip.encloses(control.get_global_rect())

func tab_to(control: Control) -> bool:
 if not verify(control!=null,"real native Tab destination exists"): return false
 if control.has_focus() and not inside(control): await key(KEY_TAB,true)
 for attempt in range(64):
  if control.has_focus() and inside(control): return true
  await key(KEY_TAB)
  var focus: Control=root.gui_get_focus_owner()
  if focus!=null and not verify(focus.is_visible_in_tree(),"Tab never focuses a hidden practice/desk node"): return false
 return verify(false,"bounded native Tab did not reveal "+str(control.name))

func settled(control: Control, minimum: Vector2=Vector2(48,48)) -> bool:
 if not verify(control!=null,"native rendered target exists"): return false
 var previous:=""
 var stable:=0
 for attempt in range(8):
  await RenderingServer.frame_post_draw
  if not verify(is_instance_valid(control),"target remains valid before input"): return false
  var rect:=control.get_global_rect()
  var signature:=str(rect)
  var ancestor:=control.get_parent()
  while ancestor is Control:
   signature+="|"+str((ancestor as Control).get_global_rect())
   ancestor=ancestor.get_parent()
  var valid:=inside(control) and rect.size.x>=minimum.x and rect.size.y>=minimum.y
  stable=stable+1 if valid and signature==previous else (1 if valid else 0)
  previous=signature
  if stable>=2: return true
  await process_frame
 return verify(false,"native target did not settle inside ALL clip ancestors: "+str(control.name))

func text_fits(button: Button) -> bool:
 # Catalogue deliberately ellipsizes with full native selected dossier/tooltip.
 if str(button.name).begins_with("GearChoice_"): return true
 var available: float=button.size.x-button.get_theme_stylebox("normal").get_minimum_size().x
 if button.icon!=null: available-=button.icon.get_width()+button.get_theme_constant("h_separation")
 var actual: float=button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
 return verify(actual<=available+1.0,"full primary/navigation action text fits: "+button.text)

func activate(node_name: String, method: String="pointer", disabled_ok: bool=false) -> bool:
 if not verify(Time.get_ticks_msec()<deadline,"native career proof stays bounded90seconds"): return false
 var target:=named(node_name) as Button
 if not verify(target!=null and (not target.disabled or disabled_ok),"actual enabled native action "+node_name): return false
 if method!="pointer" or not inside(target):
  if not await tab_to(target): return false
 if not await settled(target) or not text_fits(target): return false
 var overlay:=named("SessionTransition")
 if not verify(overlay==null or overlay.is_ancestor_of(target),"action is not occluded by a presentation overlay"): return false
 var count: Array[int]=[0]
 var count_press: Callable=func(): count[0]+=1
 target.pressed.connect(count_press)
 var expected: int=0 if target.disabled else 1
 if method=="pointer": await pointer(target.get_global_rect().get_center())
 else: await key(KEY_ENTER if method=="enter" else KEY_SPACE)
 if is_instance_valid(target) and target.pressed.is_connected(count_press): target.pressed.disconnect(count_press)
 return verify(count[0]==expected,"one actual native "+method+" pressed callback (zero for disabled): "+node_name)

func free_action(node_name: String, method: String="pointer") -> bool:
 var before:=guard()
 if not await activate(node_name,method): return false
 return unchanged(before,node_name)

func capture(label: String) -> bool:
 var before:=guard()
 await RenderingServer.frame_post_draw
 if label!="FIRST-FAILURE" and not check_fixed_layout(): return false
 var image: Image=root.get_texture().get_image()
 var path:=output+"/"+label+"-%dx%d.png" % [root.size.x,root.size.y]
 if not verify(image!=null and not image.is_empty() and image.get_size()==Vector2i(root.size),"actual full-resolution original "+label): return false
 if not verify(image.save_png(path)==OK,"write native original "+label): return false
 images.append(path)
 return unchanged(before,"capture "+label)

func fixture_step(label: String, result: Variant) -> bool:
 return verify(bool(result.get("ok",false)) if result is Dictionary else bool(result),"actual C27 fixture API "+label)

func make_fixture() -> bool:
 model=DiskCountingOpeningModel.new()
 if not fixture_step("begin",model.begin_new()) or not fixture_step("Indie",model.set_genre("Indie rock")) or not fixture_step("recruit phase",model.to_recruit()): return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not fixture_step(id,model.recruit(id)): return false
 if not fixture_step("Jack lead",model.choose_vocal("cast_jack")) or not fixture_step("lineup",model.confirm_lineup()): return false
 if not fixture_step("name phase",model.start_naming()) or not fixture_step("name",model.submit_name("QA UNIFIED BAND","Raw")) or not fixture_step("name lock",model.lock_name()): return false
 if not fixture_step("identity",model.start_identity()) or not fixture_step("choices",model.set_identity("Wordmark","Amber / Charcoal","Unpolished")) or not fixture_step("finish",model.finish_identity()) or not fixture_step("play",model.start_playing()): return false
 return verify(int(model.game.career.cash)==250 and int(model.game.career.tour_day)==1,"same genuine250/day1 trio fixture as original baseline")

func type_pending_title() -> bool:
 var before:=guard()
 var entry:=named("SongTitle") as LineEdit
 if not verify(entry!=null,"actual practice title input exists"): return false
 if not inside(entry) and not await tab_to(entry): return false
 if not await settled(entry): return false
 await pointer(entry.get_global_rect().get_center())
 if not verify(entry.has_focus(),"native pointer focuses actual practice LineEdit"): return false
 await key(KEY_A,false,true)
 for index in range(PENDING_TITLE.length()):
  var code: int=PENDING_TITLE.unicode_at(index)
  await key(code,false,false,code)
 return verify(entry.text==PENDING_TITLE and str(practice().get("song_title"))==PENDING_TITLE,"real native typing sets pending practice draft") and unchanged(before,"typing pending title")

func check_desk_header() -> bool:
 var name:=named("CareerBandName") as Label
 var money:=named("CareerDayCash") as Label
 if not verify(name!=null and name.text==str(model.game.career.band_name) and money!=null and money.text=="DAY %d  •  £%d" % [int(model.game.career.tour_day),int(model.game.career.cash)],"desk header reflects actual same band/day/cash"): return false
 if not verify(inside(name) and inside(money) and money.get_theme_font_size("font_size")>=16,"native band/day/cash text remains visible"): return false
 for id in ["CareerNav_home","CareerNav_gear","CareerNav_band","CareerNav_songs","CareerPracticeAction","CareerMenuAction"]:
  var action:=named(id) as Button
  if not await settled(action) or not text_fits(action): return false
 return check_fixed_layout()

func check_fixed_layout() -> bool:
 if desk()==null or not desk().is_visible_in_tree(): return true
 var viewport:=Rect2(Vector2.ZERO,Vector2(root.size))
 for section_name in ["CareerNavigation","CareerDecisionDock"]:
  var section:=named(section_name)
  if not verify(section!=null,"actual fixed native section exists "+section_name): return false
  for raw in section.find_children("*","Button",true,false):
   var button:=raw as Button
   if not button.is_visible_in_tree(): continue
   if not verify(viewport.encloses(button.get_global_rect()) and inside(button) and button.size.x>=48 and button.size.y>=48,"ALL navigation/dock physical targets stay inside window/clips: "+str(button.name)): return false
   if not text_fits(button): return false
 if str(desk().get("page"))=="home" and not bool(desk().get("receipt_open")):
  var scroll:=named("CareerScroll") as ScrollContainer
  if not verify(scroll!=null,"actual Home scroll exists"): return false
  var bounds: Rect2=scroll.get_global_rect()
  var bar:=scroll.get_v_scroll_bar()
  var right: float=minf(bounds.end.x,bar.get_global_rect().position.x) if bar.is_visible_in_tree() else bounds.end.x
  for route_name in ["CareerHomePracticeAction","CareerHome_gear","CareerHome_band","CareerHome_songs"]:
   var route:=named(route_name) as Button
   if not verify(route!=null and route.get_global_rect().position.x>=bounds.position.x and route.get_global_rect().end.x<=right,"Home route remains inside actual scroll horizontally: "+route_name): return false
 return true

func check_item(id: String) -> bool:
 var title:=named("GearItemTitle") as Label
 return verify(desk()!=null and str(desk().get("page"))=="gear" and str(desk().get("selected_item"))==id and title!=null and title.text==str(Gear.item_for(id).name) and title.get_theme_font_size("font_size")>=16,"native dossier belongs to actual chosen catalogue item "+id)

func browse_catalogue() -> bool:
 var index:=0
 for item in Gear.ITEMS:
  if width<840 or width<height:
   if not await free_action("GearCatalogueAction"): return false
   if not verify(bool(desk().get("catalogue_open")),"native compact catalogue opens"): return false
  var choice:=named("GearChoice_"+str(item.id)) as Button
  if not verify(choice!=null and choice.text.contains(str(item.name)) and choice.text.contains("£%d" % int(item.price)),"all five choices retain actual catalogue names/prices"): return false
  if not await free_action(str(choice.name),str(["pointer","enter","space"][index%3])) or not check_item(str(item.id)): return false
  index+=1
 if not await free_action("GearNextAction") or not check_item("amp"): return false
 if not await free_action("GearPreviousAction") or not check_item("pa"): return false
 if not await free_action("GearNextAction") or not check_item("amp"): return false
 return verify(index==5,"five real choices and both wraparound arrows were exercised without spending")

func wait_receipt() -> bool:
 var until: int=Time.get_ticks_msec()+3000
 while Time.get_ticks_msec()<until:
  if desk()!=null and not bool(desk().get("busy")):
   var note:=named("CareerReceiptNote") as Label
   if note!=null and note.has_method("is_revealing") and bool(note.call("is_revealing")):
    if note.visible_characters>0 and note.visible_characters<note.text.length(): return true
  await process_frame
 return verify(false,"actual newly committed receipt reaches a genuinely partial InkNote phase")

func check_receipt(before: Dictionary, expected: Dictionary) -> bool:
 var receipt: Dictionary=desk().get("receipt")
 var note:=named("CareerReceiptNote") as Label
 var action:=named("CareerReceiptContinueAction") as Button
 if not verify(note!=null and note.text==str(receipt.get("text","")) and note.get_theme_font_size("font_size")>=16 and note.visible_characters_behavior==TextServer.VC_CHARS_AFTER_SHAPING,"receipt keeps full committed native text/AFTER_SHAPING"): return false
 if not verify(int(receipt.cash_before)==int(before.cash) and int(receipt.cash_after)==int(expected.cash) and int(receipt.day_before)==int(before.tour_day) and int(receipt.day_after)==int(expected.tour_day),"receipt before/after values come from actual resolver result"): return false
 return verify(inside(note) and action!=null and inside(action) and action.size.y>=48 and named("SessionTransition")==null and not bool(desk().get("busy")),"UIReceiptFirstFold: full note and fixed Continue are visible after busy presentation")

func complete_note(natural: bool, tag: String="") -> bool:
 var before:=guard()
 var note:=named("CareerReceiptNote") as Label
 if not verify(note!=null and bool(note.call("is_revealing")),"completion begins while actual receipt is revealing"): return false
 var full: String=note.text
 var rect: Rect2=note.get_global_rect()
 if not tag.is_empty():
  if not await capture(tag+"-partial"): return false
 if natural:
  var until: int=Time.get_ticks_msec()+4500
  while bool(note.call("is_revealing")) and Time.get_ticks_msec()<until: await process_frame
 else:
  # Use the current automatically focused native note; Tab reveals if required.
  if not await tab_to(note) or not await settled(note,Vector2(1,1)): return false
  await key(KEY_SPACE)
 if not verify(not bool(note.call("is_revealing")) and note.visible_characters==-1 and note.text==full and note.get_global_rect()==rect,"natural/Space completion preserves shaped full text and geometry"): return false
 if not unchanged(before,"receipt presentation completion"): return false
 if not tag.is_empty():
  if not await capture(tag+"-full"): return false
 return true

func commit_gear(verb: String, item: String, member: int=-1, method: String="pointer", natural: bool=false, tag: String="") -> bool:
 var before: Dictionary=model.game.career.duplicate(true)
 var expected: Dictionary=Bridge.gear_action(before,verb,item,member)
 if not verify(bool(expected.get("ok",false)),"authoritative bridge permits intended actual input "+verb+" "+item): return false
 var saves: int=model.saves
 var snapshot: Dictionary=model.snapshot()
 var action_name: String="GearBuyAction" if verb=="buy" else ("GearServiceAction" if verb=="service" else "GearAssign_"+str(member))
 var target:=named(action_name) as Button
 var original_point: Vector2=target.get_global_rect().get_center() if target!=null else Vector2.ZERO
 if not await activate(action_name,method): return false
 if not verify(model.game.career==expected.state and model.saves==saves+1 and model.snapshot().change_counter==snapshot.change_counter,"one native career input commits exact original rules and one actual save"): return false
 if not verify(desk()!=null and bool(desk().get("busy")) and named("SessionTransition")!=null,"actual transition is in flight after commit"): return false
 if verb=="buy" and item=="amp":
  # Genuine second pointer at the prior commit point is blocked by the overlay.
  await pointer(original_point)
  if not verify(model.game.career==expected.state and model.saves==saves+1,"busy overlay blocks repeated paid pointer without duplicate settlement"): return false
  var original_desk: int = desk().get_instance_id()
  var alternate := Vector2i(1280,720) if width<900 else Vector2i(390,844)
  for window_size in [alternate,Vector2i(width,height)]:
   root.size=window_size
   DisplayServer.window_set_size(window_size)
   await frames(4)
   if not verify(desk()!=null and desk().get_instance_id()==original_desk and practice().get_instance_id()==practice_id and model.game.career==expected.state and model.saves==saves+1,"actual live commit resize retains panes and one saved original settlement"): return false
 if not await wait_receipt() or not check_receipt(before,expected.state): return false
 if not await complete_note(natural,tag): return false
 var loaded:=Model.new()
 if not verify(loaded.load_draft() and loaded.snapshot()==model.snapshot() and model.saves==saves+1,"actual saved gear result reloads exactly; presentation never saves again"): return false
 evidence.append({"verb":verb,"item":item,"member":member,"before":before,"after":model.game.career.duplicate(true),"save_delta":model.saves-saves})
 if not await free_action("CareerReceiptContinueAction","enter"): return false
 await frames(3)
 return verify(inside(named("GearItemTitle")) and inside(named("GearCatalogueAction")) and named("GearCatalogueAction").has_focus() and (named("CareerScroll") as ScrollContainer).scroll_vertical==0,"receipt return reveals current selected identity/browse and semantic focus at top after native layout")

func band_and_native_scroll() -> bool:
 if not await free_action("CareerNav_band","space"): return false
 var before:=guard()
 for index in range(model.game.career.members.size()):
  var member: Dictionary=model.game.career.members[index]
  var photo:=named("CareerPortrait_"+str(member.candidate_id)) as TextureRect
  var source: Dictionary=Cast.by_id(str(member.candidate_id))
  if not verify(photo!=null and photo.texture!=null and photo.texture.resource_path==str(source.portrait_preview) and photo.focus_mode==Control.FOCUS_NONE and photo.mouse_filter==Control.MOUSE_FILTER_IGNORE,"native band portrait is original canonical inert source"): return false
  for stat in ["skill","morale","fatigue","loyalty"]:
   var meter:=named("CareerMemberStat_"+str(index)+"_"+stat)
   if not verify(meter!=null and int(meter.get_meta("source_value",-1))==int(member.get(stat,0)) and meter.focus_mode==Control.FOCUS_NONE and meter.mouse_filter==Control.MOUSE_FILTER_IGNORE,"native passive band stat reflects exact saved value "+stat): return false
 var scroll:=named("CareerScroll") as ScrollContainer
 if not verify(scroll!=null and scroll.follow_focus,"career native scroll follows keyboard focus"): return false
 var bar:=scroll.get_v_scroll_bar()
 if bar.max_value>bar.page:
  # The bar is native scroll chrome, outside its owner's content clip. Do not
  # apply the 448a content-area subtraction to the bar itself or click it.
  if bar.has_focus(): await key(KEY_TAB,true)
  var tab_count:=0
  while not bar.has_focus() and tab_count<64:
   await key(KEY_TAB)
   tab_count+=1
  if not verify(bar.has_focus() and bar.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bar.get_global_rect()) and scroll.get_global_rect().encloses(bar.get_global_rect()),"genuine Tab reaches visible native scrollbar chrome"): return false
  await key(KEY_END)
  if not verify(scroll.scroll_vertical==roundi(bar.max_value-bar.page) and bar.has_focus(),"genuine End reaches full band dossier with native focus"): return false
  await key(KEY_HOME)
  if not verify(scroll.scroll_vertical==0 and bar.has_focus(),"genuine Home restores band dossier start"): return false
 return unchanged(before,"native band stats/Tab/Home/End")

func retained_resize_and_back() -> bool:
 var before:=guard()
 var desk_id: int=desk().get_instance_id()
 var alternate:=Vector2i(1280,720) if width<900 else Vector2i(390,844)
 for size in [alternate,Vector2i(width,height)]:
  root.size=size
  DisplayServer.window_set_size(size)
  await frames(4)
  if not verify(practice()!=null and practice().get_instance_id()==practice_id and str(practice().get("song_title"))==PENDING_TITLE and desk()!=null and desk().get_instance_id()==desk_id,"live resize retains desk/practice identities and typed pending title"): return false
  if not await check_desk_header() or not unchanged(before,"live desk resize"): return false
 if not await free_action("CareerPracticeAction"): return false
 var title:=named("SongTitle") as LineEdit
 if not verify(practice().get_instance_id()==practice_id and title!=null and title.text==PENDING_TITLE,"actual Desk→Practice retains same pane and native pending text"): return false
 if not await free_action("CareerDeskAction"): return false
 return verify(str(desk().get("page"))=="home" and (named("CareerScroll") as ScrollContainer).scroll_vertical==0,"real desk reopen starts Home at top")

func write_saved_draft() -> bool:
 if not await free_action("CareerPracticeAction"): return false
 var pane:=practice()
 var title:=named("SongTitle") as LineEdit
 if not verify(title!=null and title.text==PENDING_TITLE,"pending native title is ready for one genuine writing commit"): return false
 var trial:=Game.new()
 if not verify(trial.restore(model.game.snapshot()),"valid independent original writing oracle"): return false
 var result: Dictionary=trial.write_session(str(Workshop.IDEAS[int(pane.get("idea_index"))]),str(Workshop.FORMS[int(pane.get("form_index"))]),PENDING_TITLE,int(pane.get("leader_index")))
 if not verify(bool(result.get("ok",false)),"original writing model permits the saved draft"): return false
 var saves: int=model.saves
 if not await activate("WriteAction"): return false
 var until: int=Time.get_ticks_msec()+3000
 while bool(pane.get("session_busy")) and Time.get_ticks_msec()<until: await process_frame
 if not verify(not bool(pane.get("session_busy")) and model.game.career==trial.career and model.saves==saves+1,"one real Write saves exact original draft/day once"): return false
 # The notes can be inspected without waiting for unrelated paragraphs to finish.
 if not await activate("RecapToggleAction"): return false
 until=Time.get_ticks_msec()+3000
 while bool(pane.get("session_busy")) and Time.get_ticks_msec()<until: await process_frame
 if not verify(not bool(pane.get("session_busy")) and model.saves==saves+1,"return from saved report is presentation only"): return false
 if not await free_action("CareerDeskAction") or not await free_action("CareerNav_songs","enter"): return false
 var draft: Dictionary=model.game.career.get("current_song_draft",{})
 var sessions: Array=draft.get("sessions",[])
 if not verify(str(draft.get("title",""))==PENDING_TITLE and sessions.size()==1 and int(model.game.career.get("song_draft_progress",0))==1,"Songs page receives genuine saved1/3 Workshop.sessions array"): return false
 var has_title:=false
 var has_stage:=false
 for node in desk().find_children("*","Label",true,false):
  var label:=node as Label
  if label.text==PENDING_TITLE: has_title=inside(label)
  if label.text.begins_with("SESSION 1 / 3"): has_stage=inside(label)
 return verify(has_title and has_stage,"actual Songbook displays saved native title/session count without clipping")

func menu_continue_roundtrip() -> bool:
 var before:=guard()
 if not await activate("CareerMenuAction"): return false
 if not verify(bool(screen.get("showing_menu")),"real career Menu returns to actual root menu") or not unchanged(before,"Career Menu"): return false
 if not await activate("ContinueAction"): return false
 if not unchanged(before,"genuine saved-career Continue",1): return false
 # Current Continue intentionally reopens the saved last-session recap. Use
 # its real existing Continue action before inspecting the hydrated form.
 if named("RecapToggleAction")!=null:
  var recap_before:=guard()
  if not await activate("RecapToggleAction"): return false
  var until: int=Time.get_ticks_msec()+3000
  while bool(practice().get("session_busy")) and Time.get_ticks_msec()<until: await process_frame
  if not verify(not bool(practice().get("session_busy")),"resumed recap returns to real practice") or not unchanged(recap_before,"resumed recap Continue"): return false
 var title:=named("SongTitle") as LineEdit
 if not verify(title!=null and title.text==str(model.game.career.current_song_draft.title),"Continue hydrates SAVED writing fields in a fresh practice view"): return false
 if not await free_action("CareerDeskAction") or not await free_action("CareerNav_gear"): return false
 var inventory: Array=model.game.career.get("owned_equipment",[])
 if not verify(inventory==["amp","mics"] and int(Gear.record(model.game.career,"amp").condition)==100 and int(Gear.record(model.game.career,"mics").condition)==86 and Gear.holder_index(model.game.career,Gear.record(model.game.career,"amp"))==0 and Gear.holder_index(model.game.career,Gear.record(model.game.career,"mics"))==0,"actual reloaded inventory/conditions/canonical holders are preserved"): return false
 return await check_desk_header() and check_item("amp")

func journey() -> bool:
 if not verify(practice()!=null,"actual saved C27 practice pane exists"): return false
 practice_id=practice().get_instance_id()
 if not await type_pending_title() or not await free_action("CareerDeskAction"): return false
 if not verify(desk()!=null and desk().get("game")==model.game and not practice().is_visible_in_tree(),"native desk shares authoritative current game and retains hidden practice"): return false
 if not await check_desk_header() or not await capture("career-home"): return false
 if not await free_action("CareerNav_songs") or not await free_action("CareerNav_home","enter") or not await free_action("CareerNav_gear","space"): return false
 if not await browse_catalogue() or not await capture("career-gear-unowned"): return false
 if not await commit_gear("buy","amp",-1,"pointer",true,"career-amp-receipt"): return false
 if not await capture("career-gear-owned"): return false
 if not await commit_gear("assign","amp",0,"enter"): return false
 if not await commit_gear("service","amp",-1,"space"): return false
 var before_disabled:=guard()
 if not await activate("GearServiceAction","pointer",true) or not unchanged(before_disabled,"already-perfect service disabled native click"): return false
 if not await capture("career-gear-serviced"): return false
 if not await free_action("GearNextAction") or not check_item("mics"): return false
 if not await commit_gear("buy","mics",-1,"pointer") or not await commit_gear("assign","mics",0,"space"): return false
 if not verify(str(model.game.career.members[0].role)=="Guitarist","native mic assignment never changes canonical Jack role"): return false
 if not await band_and_native_scroll() or not await capture("career-band"): return false
 if not await retained_resize_and_back() or not await write_saved_draft() or not await capture("career-songs-draft"): return false
 if not await menu_continue_roundtrip(): return false
 return await capture("career-reloaded-gear")

func run() -> void:
 var user_dir:=ProjectSettings.globalize_path("user://")
 var output_path:=ProjectSettings.globalize_path(output)
 var safe: bool=verify(user_dir.begins_with(SAFE_ROOT) and output_path.begins_with(SAFE_ROOT),"fresh isolated S45 XDG/output guard")
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=verify(not FileAccess.file_exists(path),"fresh fixture save path "+path) and safe
 if not safe:
  print("S45_CAREER_CAPTURE_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}));quit(1);return
 output=output_path
 if not verify(DirAccess.make_dir_recursive_absolute(output)==OK,"create scratch native capture directory"):
  quit(1);return
 protected_initial=files(true)
 root.size=Vector2i(width,height)
 DisplayServer.window_set_size(root.size)
 root.grab_focus()
 await frames(4)
 deadline=Time.get_ticks_msec()+90000
 if make_fixture():
  screen=RootUI.new()
  screen.name="S45CareerActualNativeQA"
  screen.setup=model
  screen.showing_menu=false
  root.add_child(screen)
  await frames(3)
  await journey()
 if not failures.is_empty() and is_instance_valid(screen): await capture("FIRST-FAILURE")
 if is_instance_valid(screen): screen.free()
 await frames(3)
 verify(files(true)==protected_initial,"native career proof leaves original legacy3/C26 save bytes untouched")
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"errors":failures,"width":width,"height":height,"engine":Engine.get_version_info(),"user_data":user_dir,"save_calls":model.saves if model!=null else 0,"load_calls":model.loads if model!=null else 0,"images":images,"paid_and_free_commits":evidence,"clip_method":"448a72bc ALL clipping ancestors and visible scrollbar area; real Tab reveal only","method":"genuine C27 fixture; native pointer/Enter/Space/Tab/Home/End; one-owner actual super save/load; true pending form and saved Workshop draft; exact original bridge/writing state"}
 var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:
  push_error("S45_CAREER_CAPTURE could not write result");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close()
 print("S45_CAREER_CAPTURE_RESULT ",JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
