extends "res://experiments/playable_flightcase/opening_capture.gd"
## S57 focused native journey. Model-prepared lineup, then genuine naming,
## look, confirmation, resize, failure/retry and disk Continue inputs.
const Style57=preload("res://experiments/playable_flightcase/identity_style.gd")
var output57 := ""
var checks57 := 0
var images57: Array[String]=[]
var screen57
var width57 := 390
var height57 := 844
var orphan57 := 0
var touch_trace57: Array=[]
var geometry57: Array=[]
var band57 := "Side Street"
var normal57 := false

func check57(condition: bool, message: String) -> bool:
 checks57+=1
 if not condition: failures.append(message)
 return condition

func settle57() -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw

func named57(value: String) -> Control:
 return screen57.find_child(value,true,false) as Control

func shot57(label: String) -> void:
 await settle57()
 var safe: Rect2=screen57.get_global_rect()
 var measured: Dictionary={"label":label,"safe":[safe.position.x,safe.position.y,safe.size.x,safe.size.y],"nodes":{}}
 for name in ["FirstPressCoverFrame","IdentityPressPaper","BandPosterPaper","IdentityLiveMark","BandPosterHeadline","MilestoneNextAction","NameSubmitAction","NameLockAction","NameMilestoneNextAction","IdentityFinishAction","IdentityBackAction","StartPlayAction","CompletedMenuAction","PracticeBackAction","CareerMenuAction"]:
  var node: Control=named57(name)
  if node==null or not node.is_visible_in_tree(): continue
  var rect: Rect2=node.get_global_rect()
  measured.nodes[name]=[rect.position.x,rect.position.y,rect.size.x,rect.size.y]
  if node is Button:
   check57(safe.encloses(rect) and rect.size.x>=44.0 and rect.size.y>=44.0,"fixed physical action inside safe content: "+name)
  elif name=="FirstPressCoverFrame":
   check57(safe.encloses(rect),"whole hero frame inside actual safe content")
 geometry57.append(measured)
 var path: String=output57+"/"+label+"-%dx%d.png"%[width57,height57]
 var picture: Image=root.get_texture().get_image()
 if check57(picture!=null and not picture.is_empty(),"actual native postdraw image exists"):
  check57(picture.save_png(path)==OK,"original native PNG saved")
  images57.append(path)

func guard57() -> Dictionary:
 return {"model":screen57.setup.snapshot(),"file":FileAccess.get_file_as_bytes(OpeningModel.SAVE_PATH)}

func unchanged57(before: Dictionary, label: String) -> bool:
 return check57(screen57.setup.snapshot()==before.model and FileAccess.get_file_as_bytes(OpeningModel.SAVE_PATH)==before.file,label+" leaves model/disk unchanged")

func insets57(label: String) -> void:
 if width57 not in [390,1280]: return
 var before: Dictionary=guard57()
 var draft: Dictionary=screen57.identity_draft.duplicate(true)
 screen57.set_meta("safe_area_test_sample",{"screen_safe_rect":Rect2(0,28,width57,height57-52),"viewport_to_screen":Transform2D.IDENTITY})
 screen57.call("_refresh_safe_area")
 await settle57()
 await shot57(label+"-safe-insets")
 check57(screen57.identity_draft==draft,"28/24 engine-inset sample preserves pending look")
 unchanged57(before,"camera/navigation inset-only reflow")
 screen57.remove_meta("safe_area_test_sample")
 screen57.call("_refresh_safe_area")
 await settle57()

func click57(value: String) -> bool:
 var button: Button=named57(value) as Button
 if not check57(button!=null and not button.disabled,"real enabled action "+value): return false
 await click_action(button)
 await settle57()
 return failures.is_empty()

func cover57(value: String, expected: Array) -> bool:
 var cover: Variant=named57(value)
 if not check57(cover!=null and cover.uses_full_length(),"actual production cover uses full-length source layers"): return false
 check57(cover.visible_ids()==expected,"cover contains only actual selected IDs in saved order")
 var regions: Dictionary=cover.source_regions()
 for pid in expected:
  var photo: TextureRect=cover.find_child("IdentityPortrait_"+str(pid),true,false) as TextureRect
  check57(photo!=null and photo.texture is AtlasTexture and regions.has(pid),"native actual per-ID atlas texture")
  if photo!=null:
   check57(str(photo.get_meta("cast_id",""))==str(pid) and photo.mouse_filter==Control.MOUSE_FILTER_IGNORE and photo.focus_mode==Control.FOCUS_NONE,"actual source ID and inert portrait semantics")
 var mark: Label=cover.find_child("IdentityLiveMark",true,false) as Label
 check57(mark!=null and str(mark.get("full_name"))==screen57.setup.name_locked,"full original band name retained by shared native mark")
 return failures.is_empty()

func touch_scroll57(target_name: String) -> bool:
 var scroll: ScrollContainer=named57("IdentityChoicesScroll") as ScrollContainer
 var target: Control=named57(target_name)
 if not check57(scroll!=null and target!=null and scroll.follow_focus,"real focus-following editor scroll and touch target"): return false
 scroll.ensure_control_visible(target)
 await settle57()
 var before: Dictionary=guard57()
 var draft: Dictionary=screen57.identity_draft.duplicate(true)
 var previous_mouse: bool=Input.emulate_mouse_from_touch
 var previous_touch: bool=Input.emulate_touch_from_mouse
 Input.emulate_mouse_from_touch=true
 Input.emulate_touch_from_mouse=true
 if not DisplayServer.is_touchscreen_available():
  Input.emulate_mouse_from_touch=previous_mouse;Input.emulate_touch_from_mouse=previous_touch
  return check57(false,"existing native touch-emulation positive capability")
 var point: Vector2=target.get_global_rect().get_center()
 var down:=InputEventScreenTouch.new()
 down.window_id=root.get_window_id();down.index=0;down.position=point;down.pressed=true
 Input.parse_input_event(down);await process_frame
 var start: int=scroll.scroll_vertical
 var samples: Array=[]
 for step in range(6):
  var delta:=Vector2(0,-16);point+=delta
  var drag:=InputEventScreenDrag.new()
  drag.window_id=root.get_window_id();drag.index=0;drag.position=point
  drag.relative=delta;drag.screen_relative=delta;drag.velocity=delta*60;drag.screen_velocity=delta*60
  Input.parse_input_event(drag);await process_frame;samples.append(scroll.scroll_vertical)
 var finish: int=scroll.scroll_vertical
 var up:=InputEventScreenTouch.new()
 up.window_id=root.get_window_id();up.index=0;up.position=point;up.pressed=false
 Input.parse_input_event(up)
 await create_timer(0.35).timeout
 Input.emulate_mouse_from_touch=previous_mouse;Input.emulate_touch_from_mouse=previous_touch
 touch_trace57.append({"target":target_name,"after_press":start,"samples":samples,"after_drag":finish,"physical_device":false})
 check57(finish>start+24,"actual native drag from "+target_name+" scrolls the production editor")
 check57(screen57.identity_draft==draft,"native scrolling never activates a type choice")
 unchanged57(before,"actual editor touch gesture")
 return failures.is_empty()

func journey57() -> bool:
 # Honest prepared lineup; the original standard journey tests auditions.
 var model=OpeningModel.new()
 if not check57(model.begin_new() and model.set_genre("Post-punk") and model.to_recruit(),"real model prepares isolated original Post-punk opening"): return false
 for pid in ["cast_jack","cast_zoe","cast_casey"]:
  if not check57(bool(model.recruit(pid).get("ok",false)),"real model recruits fixture ID "+pid): return false
 if not check57(bool(model.choose_vocal("cast_jack").get("ok",false)) and bool(model.confirm_lineup().get("ok",false)),"real confirmed trio reaches first held milestone"): return false
 screen57=UI.new()
 screen57.setup=model
 screen57.showing_menu=false
 screen57.reduced_motion=not normal57
 root.add_child(screen57)
 await settle57()
 var formation: Variant=named57("BandFormationPoster")
 check57(formation!=null and formation.visible_ids()==["cast_jack","cast_zoe","cast_casey"],"pre-name cover preserves actual selected trio")
 var founding_group: Variant=named57("SelectedBandLineup")
 check57(founding_group!=null and founding_group.uses_full_length(),"pre-name formation uses same actual full-length compositor")
 for pid in ["cast_jack","cast_zoe","cast_casey"]:
  check57(named57("LineupPortrait_"+pid)!=null and named57("LineupRole_"+pid)!=null,"pre-name native picture and role match actual selected ID")
 await shot57("formation-milestone")
 await insets57("formation")
 if not await click57("MilestoneNextAction"): return false
 await shot57("name-editor-empty")
 var field: LineEdit=named57("FreeBandName") as LineEdit
 if not check57(field!=null and field.editable,"actual editable name field"): return false
 field.grab_focus()
 for index in range(band57.length()):
  var down:=InputEventKey.new()
  down.pressed=true
  down.unicode=band57.unicode_at(index)
  Input.parse_input_event(down)
  await process_frame
  var up:=InputEventKey.new()
  up.pressed=false
  up.unicode=down.unicode
  Input.parse_input_event(up)
  await process_frame
 await settle57()
 if not check57(field.text==band57 and screen57.free_name==band57,"native engine typing updates retained draft"): return false
 var live: Label=named57("NameLiveMark") as Label
 check57(live!=null and str(live.get("full_name"))==band57,"typing updates actual shared mark without navigation")
 await shot57("name-editor-live")
 if not await click57("NameSubmitAction") or not await click57("NameLockAction"): return false
 if not check57(model.screen=="name_milestone","native name confirmation reaches held acknowledgement"): return false
 await shot57("named-milestone")
 if not await click57("NameMilestoneNextAction"): return false
 if not cover57("IdentityPreviewPrint",["cast_jack","cast_zoe","cast_casey"]): return false
 await shot57("identity-initial")
 await insets57("identity")
 var before: Dictionary=guard57()
 for kind in Style57.FONTS:
  if not await click57("IdentityType_"+str(kind)): return false
  check57(screen57.identity_draft.style.font==kind,"real type choice latched")
  unchanged57(before,"free type preview")
  await shot57("identity-type-"+str(kind))
 for ink in Style57.INKS:
  if not await click57("IdentityInk_"+str(ink)): return false
  check57(screen57.identity_draft.style.ink==ink,"real ink choice latched")
  unchanged57(before,"free ink preview")
  if ink in ["ivory","cobalt"]: await shot57("identity-ink-"+str(ink))
 # The real Tab path leaves the final ink and reveals the treatment row.
 await _recap_key(KEY_TAB)
 await settle57()
 var focused: Control=root.gui_get_focus_owner()
 check57(focused!=null and str(focused.name)=="IdentityLogo_Wordmark","actual Tab advances from final ink to visible treatment")
 if focused!=null:
  check57((named57("IdentityChoicesScroll") as ScrollContainer).get_global_rect().encloses(focused.get_global_rect()),"follow-focus reveals the actual keyboard destination")
 await _recap_key(KEY_SPACE)
 await settle57()
 unchanged57(before,"native keyboard treatment preview")
 for treatment in ["Monogram","Wordmark","Stamp"]:
  if not await click57("IdentityLogo_"+treatment): return false
  check57(str(screen57.identity_draft.logo)==treatment,"real native treatment preview")
  unchanged57(before,"free native treatment preview")
  if treatment=="Monogram":
   var full: Label=named57("IdentityFullName") as Label
   check57(full!=null and full.visible and full.text==band57 and full.get_theme_font_size("font_size")>=16,"Monogram keeps the complete original name legible")
   await shot57("identity-monogram")
   await insets57("identity-monogram")
 if not await click57("IdentityType_blockprint") or not await click57("IdentityInk_charcoal") or not await click57("IdentityLogo_Stamp"): return false
 if width57<480:
  if not await touch_scroll57("IdentityPressMasthead") or not await touch_scroll57("IdentityType_condensed"): return false
 unchanged57(before,"all native previews before Apply")
 var draft: Dictionary=screen57.identity_draft.duplicate(true)
 DisplayServer.window_set_size(Vector2i(height57,width57))
 root.size=Vector2i(height57,width57)
 await settle57()
 DisplayServer.window_set_size(Vector2i(width57,height57))
 root.size=Vector2i(width57,height57)
 await settle57()
 check57(screen57.identity_draft==draft,"actual live resize retains pending type/ink/treatment")
 unchanged57(before,"native responsive editor reflow")
 # A real filesystem failure blocks temp output but retains the old valid save.
 var temporary: String=ProjectSettings.globalize_path(OpeningModel.SAVE_PATH+".identity-tmp")
 if not check57(DirAccess.make_dir_recursive_absolute(temporary)==OK,"actual isolated temp-directory failure fixture"): return false
 if not await click57("IdentityFinishAction"): return false
 check57(model.screen=="identity" and screen57.identity_draft==draft,"failed Save leaves editor and retained draft ready to retry")
 var notice: Label=named57("IdentityCommitNotice") as Label
 check57(notice!=null and notice.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(notice.get_global_rect()) and notice.get_theme_font_size("font_size")>=16,"actual save error is readable beside fixed retry controls")
 unchanged57(before,"real failed identity save")
 await shot57("identity-save-failure")
 check57(DirAccess.remove_absolute(temporary)==OK,"remove only owned empty temp-directory fixture")
 if not await click57("IdentityFinishAction"): return false
 if not check57(model.screen=="complete" and model.identity_style==draft.style and model.game.career.get(Style57.KEY,{})==draft.style,"Apply commits exact chosen style to opening and career once"): return false
 if not cover57("CompletedBandPrint",["cast_jack","cast_zoe","cast_casey"]): return false
 var committed: Dictionary=guard57()
 await shot57("identity-confirmed-poster")
 await insets57("confirmed-poster")
 await create_timer(1.2).timeout
 unchanged57(committed,"held milestone idle")
 if not await click57("StartPlayAction"): return false
 if not check57(model.screen=="play","native held poster Continue reaches real practice"): return false
 var header: Label=named57("PracticeBandName") as Label
 check57(header!=null and str(header.get("full_name"))==band57,"same shared band mark reaches actual practice header")
 await shot57("identity-practice-header")
 if not await click57("PracticeBackAction"): return false
 var saved: Dictionary=guard57()
 if not await click57("ContinueAction"): return false
 check57(screen57.setup.identity_style==draft.style and screen57.setup.game.career.get(Style57.KEY,{})==draft.style,"actual disk Continue restores committed style")
 unchanged57(saved,"native Menu/Continue")
 var before_career: Dictionary=guard57()
 if not await click57("CareerDeskAction"): return false
 var career_header: Label=named57("CareerBandName") as Label
 check57(career_header!=null and str(career_header.get("full_name"))==band57,"actual career header uses the same saved band mark")
 await shot57("identity-career-header")
 if not await click57("CareerHome_calendar"): return false
 await shot57("identity-calendar-header")
 if not await click57("CareerCalendarBackAction"): return false
 unchanged57(before_career,"native career/calendar free routes")
 return failures.is_empty()

func take() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--out="): output57=argument.substr(6)
  elif argument.begins_with("--size="):
   var parts: PackedStringArray=argument.substr(7).split("x")
   width57=int(parts[0]);height57=int(parts[1])
  elif argument.begins_with("--band-name="): band57=argument.substr(12)
  elif argument=="--motion=normal": normal57=true
 if not output57.begins_with("/workspace/work/identity-20261101/s57/"):
  print("S57 unsafe output guard");quit(2);return
 if not ProjectSettings.globalize_path("user://").begins_with("/workspace/work/identity-20261101/s57/"):
  print("S57 unsafe userdata guard");quit(2);return
 DirAccess.make_dir_recursive_absolute(output57)
 DisplayServer.window_set_size(Vector2i(width57,height57))
 root.size=Vector2i(width57,height57)
 orphan57=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 var okay: bool=await journey57()
 if not okay: await shot57("FIRST-FAILURE")
 if is_instance_valid(screen57): screen57.queue_free()
 await settle57()
 var after: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 check57(after<=orphan57,"no orphan growth after native journey cleanup")
 var result: Dictionary={"pass":okay and failures.is_empty(),"checks":checks57,"errors":failures,"originals":images57,"orphan_before":orphan57,"orphan_after":after,"touch_trace":touch_trace57,"geometry":geometry57,"band_name":band57,"normal_motion":normal57,"physical_phone":false,"fixture":"Real model-prepared trio, then actual native typing/pointer/touch/keyboard/resize/safearea/save-failure/retry/held/Continue/career/calendar"}
 var file:=FileAccess.open(output57+"/result.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"  "));file.close()
 print("S57_IDENTITY_NATIVE_RESULT ",JSON.stringify(result))
 quit(0 if result["pass"] else 1)
