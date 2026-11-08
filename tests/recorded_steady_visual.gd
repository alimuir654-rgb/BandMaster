extends SceneTree
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Recipe=preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Sound=preload("res://experiments/playable_flightcase/band_sound.gd")
var owner
var output: String=""
var baseline:=false
var failures: Array=[]
var checks:=0

func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
  if arg=="--baseline":baseline=true
 call_deferred("run")

func check(ok: bool,words: String) -> bool:
 checks+=1
 if not ok:failures.append(words);push_error(words)
 return ok

func fixture() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not owner.recruit(id):return false
 return owner.choose_vocal("cast_jack") and owner.confirm_lineup() and owner.start_naming() and owner.submit_name("QA UNIFIED BAND","Raw") and owner.lock_name() and owner.start_identity() and owner.set_identity("Wordmark","Amber / Charcoal","Unpolished") and owner.finish_identity() and owner.start_playing()

func capture(label: String) -> void:
 for _i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(output+"-"+label+".png")==OK,"native capture "+label)

func run() -> void:
 if not check(not output.is_empty() and fixture(),"isolated genuine formation"):quit(1);return
 var recipe: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 if not check(owner.begin_workbench("Steady at last",0,owner.workbench_expected(),recipe).ok,"real workbench entry"):quit(1);return
 var scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;scene._career_landing=false
 root.add_child(scene)
 await create_timer(0.4).timeout
 var desk=scene.find_child("MixingDesk",true,false)
 if not check(desk!=null,"actual entry mounts existing writing room"):quit(1);return
 check(desk._hear.is_visible_in_tree() and desk._commit.is_visible_in_tree(),"existing hear/commit visible")
 check(desk._hear.get_global_rect().end.y<=scene.get_viewport_rect().end.y and desk._commit.get_global_rect().end.y<=scene.get_viewport_rect().end.y,"footer inside logical viewport")
 await capture("legacy")
 if not baseline:
  var snapshot: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
  desk.find_child("MixingRecorded_0",true,false).pressed.emit()
  check(desk._recipe.hook=="steady_early_v1","native existing workbench selects recorded source")
  for key in ["pace","groove","originality"]:
   check(desk._controls[key].locked and desk._controls[key].focus_mode==Control.FOCUS_NONE,"fixed axis "+key)
  check(desk._controls.pace.labels[1]=="100 BPM","actual tempo caption")
  desk._choose("pace",2)
  check(desk._recipe.pace=="driving","direct unsupported selection rejected")
  await capture("recorded")
  desk._hear.pressed.emit()
  check(desk._audio.playing,"native Hear invokes synchronized player")
  desk.find_child("MixingPauseButton",true,false).pressed.emit()
  await process_frame
  check(not desk._audio.playing and is_instance_valid(desk._dialog) and desk._commit.disabled,"pause interrupts and disables commit")
  if root.size.x==390:await capture("pause")
  desk._close_dialog();desk._refresh()
  desk._scroll.scroll_vertical=100000
  if root.size.x==390:await capture("scrolled")
  desk._scroll.scroll_vertical=0
  desk.find_child("MixingRecorded_1",true,false).pressed.emit()
  check(desk._recipe.hook=="steady_later_v1","second family selected")
  desk.find_child("MixingFoundation_0",true,false).pressed.emit()
  check(not desk._controls.pace.locked and not desk._controls.pace.tooltip_text.contains("Fixed"),"return to legacy clears locked hint")
  check(owner.snapshot()==snapshot and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"all local UI/audio actions preserve owner and disk")
  desk._choose("tone",0);desk.request_exit("career")
  check(is_instance_valid(desk._dialog),"dirty exit remains guarded")
  await process_frame
  desk._close_dialog()
  await process_frame
 print("RECORDED_VISUAL "+JSON.stringify({"viewport":str(root.size),"baseline":baseline,"checks":checks,"failures":failures,"actual_entry":"opening.tscn","physical_device":false}))
 scene.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)
