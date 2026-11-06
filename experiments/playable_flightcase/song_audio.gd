extends RefCounted
## Explicit illustration of a saved arrangement. Never settles a song or show.
const Producer = preload("res://experiments/playable_flightcase/producer_recipe.gd")
const Rules = preload("res://experiments/playable_flightcase/song_workbench.gd")
const AudioPart = preload("res://experiments/playable_flightcase/audition_audio.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")

static func recipe(song: Dictionary) -> Dictionary:
 if not song.get("id") is String or not Rules._whole(song.get("quality"),1,100):return {}
 var extension: Variant=song.get(Rules.FRAGMENT_KEY)
 if not Rules._extension_ok(extension):return {}
 var value: Variant=extension.fragment.get("producer_recipe")
 if not Producer.valid(value) or int(value.stage)!=2:return {}
 var receipt: Dictionary=extension.get("producer_quality_receipt",{})
 if receipt.get("song_id")!=song.get("id") or receipt.get("final_quality")!=song.get("quality"):return {}
 return value.duplicate(true)

static func attach(parent: Node,song: Dictionary,context: Callable,paper: bool=true) -> void:
 var value: Dictionary=recipe(song)
 if value.is_empty():return
 var caption: Label=C.label("SAVED ARRANGEMENT · "+str(song.get("title","Original")),16,"notepaper" if paper else "flightcase")
 caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(caption)
 var written: Label=C.label(Producer.written(value),16,"notepaper" if paper else "flightcase")
 written.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(written)
 if value.get("version")==3:
  preload("res://experiments/playable_flightcase/mixing_audio.gd").attach_controls(parent,value,context)
  return
 var audio=AudioPart.new()
 audio.manifest_path=Producer.MANIFEST
 audio.play_caption="PLAY SAVED TAKE"
 audio.available_hint="Illustration of this saved direction; not the performance or a skill grade."
 audio.configure(func():return {"allowed":bool(context.call()),"material_id":Producer.audio_id(value),"content_version":Producer.VERSION})
 audio.set_clip(Producer.audio_id(value))
 parent.add_child(audio)
 audio.add_to_group("SavedArrangementAudio")
 audio.resized.connect(audio.stop)
 audio.play_button.pressed.connect(func():
  for other in audio.get_tree().get_nodes_in_group("SavedArrangementAudio"):
   if other!=audio:other.stop())
