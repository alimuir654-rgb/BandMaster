extends SceneTree
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Song=preload("res://experiments/playable_flightcase/song_audio.gd")
const Bank=preload("res://experiments/playable_flightcase/recorded_steady.gd")
var checks:=0
var failures: Array=[]
func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run() -> void:
 var fixture:=""
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--fixture="):fixture=argument.trim_prefix("--fixture=")
 check(FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot"),"isolated actual exported V25")
 check(not fixture.is_empty() and FileAccess.file_exists(fixture),"retained V24 source fixture")
 if not failures.is_empty():quit(1);return
 var bytes:=FileAccess.get_file_as_bytes(fixture)
 var source_sha:=FileAccess.get_sha256(fixture)
 var owner:=Owner.new();var expected:=Owner.new()
 var raw: Variant=owner.game._restore_integral_numbers(JSON.parse_string(bytes.get_string_from_utf8()))
 check(expected.restore(raw),"exact original V24 typed state")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Owner.SAVE_PATH).get_base_dir())
 var file:=FileAccess.open(Owner.SAVE_PATH,FileAccess.WRITE);file.store_buffer(bytes);file.close()
 check(owner.load_draft(),"V25 Continue reads V24 save without migration/reset")
 check(owner.snapshot()==expected.snapshot(),"whole typed V24 state retained")
 check(FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==bytes,"Continue leaves saved bytes unchanged")
 for song in owner.game.career.get("song_catalogue",[]):
  var recipe: Dictionary=Song.recipe(song)
  if not Bank.has_hook(recipe):continue
  var entry: Dictionary=Bank.entry(recipe)
  check(not entry.is_empty(),"V24 frozen song source remains available")
  for part in entry.get("parts",{}):
   var stream=Bank.VocalKeys.stream(entry.parts[part],int(entry.frames)) if recipe.get("version")==5 else Bank.stream(entry.parts[part],int(entry.frames))
   check(stream!=null,"V24 saved song exact packed PCM "+str(part))
 check(FileAccess.get_sha256(fixture)==source_sha,"original V24 fixture never changed")
 print("PILOT51_UPGRADE "+JSON.stringify({"checks":checks,"failures":failures,"fixture_sha256":source_sha,"physical_Android":false}))
 quit(0 if failures.is_empty() else 1)
