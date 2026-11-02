extends VBoxContainer
## One visual place and a player-held band voice. Motion is presentation only.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
var note: Label
var image_view: TextureRect
var _motion: Tween
var _reduced := false
var _fresh := false

func configure(data: Dictionary, reduced: bool, available: float, short: bool = false) -> void:
 _reduced=reduced
 _fresh=bool(data.get("fresh",false))
 name="GigJourneyPlace"
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",6)
 var title: Label=C.label(str(data.get("title","TONIGHT")),22)
 title.name="JourneySceneTitle"
 add_child(title)
 var frame: PanelContainer=Kit.frame("flightcase","inset")
 frame.name="JourneyImageFrame"
 frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(frame)
 image_view=TextureRect.new()
 image_view.name="JourneyPlaceImage"
 image_view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image_view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image_view.custom_minimum_size=Vector2(0,160 if short else clampf(available*0.52,165,255))
 image_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 image_view.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var path: String=str(data.get("image",""))
 if not path.is_empty() and ResourceLoader.exists(path):image_view.texture=load(path)
 frame.add_child(image_view)
 var caption: Label=C.label(str(data.get("caption","")),16)
 caption.name="JourneyPlaceCaption"
 caption.add_theme_color_override("font_color",Color("f0c78b"))
 add_child(caption)
 var voice: HBoxContainer=HBoxContainer.new()
 voice.name="JourneyBandVoice"
 voice.add_theme_constant_override("separation",10)
 add_child(voice)
 var portrait_path: String=str(data.get("portrait",""))
 if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
  var portrait: TextureRect=TextureRect.new()
  portrait.name="JourneySpeakerPortrait"
  portrait.texture=load(portrait_path)
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  portrait.custom_minimum_size=Vector2(64,68)
  portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
  voice.add_child(portrait)
 var words: VBoxContainer=VBoxContainer.new()
 words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 voice.add_child(words)
 var speaker: Label=C.label(str(data.get("speaker","THE BAND")),16)
 speaker.name="JourneySpeakerName"
 words.add_child(speaker)
 note=Ink.new()
 note.name="JourneyHeldNote"
 note.text=str(data.get("text",""))
 note.add_theme_color_override("font_color",Color("eee7d7"))
 if _fresh:note.visible_characters=0
 words.add_child(note)
 if not reduced and _fresh:
  var skip: Button=C.button("SKIP TRANSITION","flightcase","tab")
  skip.name="JourneySkipTransitionAction"
  skip.pressed.connect(settle)
  add_child(skip)
 call_deferred("_begin")

func _begin() -> void:
 if not is_inside_tree():return
 if is_instance_valid(note) and _fresh:note.call("begin",_reduced)
 if _reduced or not _fresh:return
 image_view.modulate.a=0.25
 _motion=create_tween()
 _motion.tween_property(image_view,"modulate:a",1.0,0.24)

func settle() -> void:
 if _motion!=null and _motion.is_valid():_motion.kill()
 _motion=null
 if is_instance_valid(image_view):image_view.modulate.a=1.0
 if is_instance_valid(note):note.call("finish_now")

func finish_words() -> bool:
 if is_instance_valid(note) and bool(note.call("is_revealing")):
  note.call("finish_now")
  return true
 return false

func _exit_tree() -> void:
 if _motion!=null and _motion.is_valid():_motion.kill()
 _motion=null
