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
 var path: String=output57+"/"+label+"-%dx%d.png"%[width57,height57]
 var picture: Image=root.get_texture().get_image()
 if check57(picture!=null and not picture.is_empty(),"actual native postdraw image exists"):
  check57(picture.save_png(path)==OK,"original native PNG saved")
  images57.append(path)

func guard57() -> Dictionary:
 return {"model":screen57.setup.snapshot(),"file":FileAccess.get_file_as_bytes(OpeningModel.SAVE_PATH)}

func unchanged57(before: Dictionary, label: String) -> bool:
 return check57(screen57.setup.snapshot()==before.model and FileAccess.get_file_as_bytes(OpeningModel.SAVE_PATH)==before.file,label+" leaves model/disk unchanged")

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

func journey57() -> bool:
 # Honest prepared lineup; the original standard journey tests auditions.
 var model=OpeningModel.new()
 if not check57(model.begin_new() and model.set_genre("Indie") and model.to_recruit(),"real model prepares isolated Indie opening"): return false
 for pid in ["cast_jack","cast_zoe","cast_casey"]:
  if not check57(bool(model.recruit(pid).get("ok",false)),"real model recruits fixture ID "+pid): return false
 if not check57(bool(model.choose_vocal("cast_jack").get("ok",false)) and bool(model.confirm_lineup().get("ok",false)) and model.start_naming(),"real confirmed trio reaches naming"): return false
 screen57=UI.new()
 screen57.setup=model
 screen57.showing_menu=false
 screen57.reduced_motion=true
 root.add_child(screen57)
 await settle57()
 await shot57("name-editor-empty")
 var field: LineEdit=named57("FreeBandName") as LineEdit
 if not check57(field!=null and field.editable,"actual editable name field"): return false
 field.grab_focus()
 for index in range("Side Street".length()):
  var down:=InputEventKey.new()
  down.pressed=true
  down.unicode="Side Street".unicode_at(index)
  Input.parse_input_event(down)
  await process_frame
  var up:=InputEventKey.new()
  up.pressed=false
  up.unicode=down.unicode
  Input.parse_input_event(up)
  await process_frame
 await settle57()
 if not check57(field.text=="Side Street" and screen57.free_name=="Side Street","native engine typing updates retained draft"): return false
 var live: Label=named57("NameLiveMark") as Label
 check57(live!=null and str(live.get("full_name"))=="Side Street","typing updates actual shared mark without navigation")
 await shot57("name-editor-live")
 if not await click57("NameSubmitAction") or not await click57("NameLockAction"): return false
 if not check57(model.screen=="name_milestone","native name confirmation reaches held acknowledgement"): return false
 await shot57("named-milestone")
 if not await click57("NameMilestoneNextAction"): return false
 if not cover57("IdentityPreviewPrint",["cast_jack","cast_zoe","cast_casey"]): return false
 await shot57("identity-initial")
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
 if not await click57("IdentityType_blockprint") or not await click57("IdentityInk_charcoal") or not await click57("IdentityLogo_Stamp"): return false
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
 unchanged57(before,"real failed identity save")
 await shot57("identity-save-failure")
 check57(DirAccess.remove_absolute(temporary)==OK,"remove only owned empty temp-directory fixture")
 if not await click57("IdentityFinishAction"): return false
 if not check57(model.screen=="complete" and model.identity_style==draft.style and model.game.career.get(Style57.KEY,{})==draft.style,"Apply commits exact chosen style to opening and career once"): return false
 if not cover57("CompletedBandPrint",["cast_jack","cast_zoe","cast_casey"]): return false
 var committed: Dictionary=guard57()
 await shot57("identity-confirmed-poster")
 await create_timer(1.2).timeout
 unchanged57(committed,"held milestone idle")
 if not await click57("StartPlayAction"): return false
 if not check57(model.screen=="play","native held poster Continue reaches real practice"): return false
 var header: Label=named57("PracticeBandName") as Label
 check57(header!=null and str(header.get("full_name"))=="Side Street","same shared band mark reaches actual practice header")
 await shot57("identity-practice-header")
 if not await click57("PracticeBackAction"): return false
 var saved: Dictionary=guard57()
 if not await click57("ContinueAction"): return false
 check57(screen57.setup.identity_style==draft.style and screen57.setup.game.career.get(Style57.KEY,{})==draft.style,"actual disk Continue restores committed style")
 unchanged57(saved,"native Menu/Continue")
 return failures.is_empty()

func take() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--out="): output57=argument.substr(6)
  elif argument.begins_with("--size="):
   var parts: PackedStringArray=argument.substr(7).split("x")
   width57=int(parts[0]);height57=int(parts[1])
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
 var result: Dictionary={"pass":okay and failures.is_empty(),"checks":checks57,"errors":failures,"originals":images57,"orphan_before":orphan57,"orphan_after":after,"physical_phone":false,"fixture":"Real model-prepared trio, then actual native typing/pointer/resize/save-failure/retry/held/Continue"}
 var file:=FileAccess.open(output57+"/result.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"  "));file.close()
 print("S57_IDENTITY_NATIVE_RESULT ",JSON.stringify(result))
 quit(0 if result["pass"] else 1)
