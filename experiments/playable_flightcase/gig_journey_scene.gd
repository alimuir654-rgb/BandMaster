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
var _travel := false

func configure(data: Dictionary, reduced: bool, available: float, short: bool = false) -> void:
 _reduced=reduced
 _fresh=bool(data.get("fresh",false))
 _travel=bool(data.get("travel",false))
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
 var image_height: float=160 if short else clampf(available*0.52,165,255)
 image_view.custom_minimum_size=Vector2(0,0 if _travel else image_height)
 image_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 image_view.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var path: String=str(data.get("image",""))
 if not path.is_empty() and ResourceLoader.exists(path):image_view.texture=load(path)
 image_view.set_meta("source",path)
 image_view.set_meta("source_sha256",str(data.get("source_sha256","")))
 image_view.set_meta("full_source_contained",true)
 if _travel:
  # Reserve honest camera padding; translate the whole contained plate only.
  # The image never zooms, rotates, crops or becomes extracted vehicle layers.
  var padding: MarginContainer=MarginContainer.new()
  padding.name="JourneyCameraPadding"
  for edge in ["left","top","right","bottom"]:padding.add_theme_constant_override("margin_"+edge,2)
  frame.add_child(padding)
  var camera: Control=Control.new()
  camera.name="JourneyCameraPad"
  camera.custom_minimum_size.y=image_height
  camera.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  camera.mouse_filter=Control.MOUSE_FILTER_IGNORE
  padding.add_child(camera)
  camera.add_child(image_view)
  image_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 else:frame.add_child(image_view)
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
 if _travel:
  var native_scale: Vector2=image_view.get_global_transform_with_canvas().get_scale().abs()
  var drift: Vector2=Vector2(1.25/maxf(1.0,native_scale.x),-0.75/maxf(1.0,native_scale.y))
  _motion.parallel().tween_property(image_view,"position",drift,0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  _motion.tween_property(image_view,"position",Vector2.ZERO,0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _settle_motion() -> void:
 if _motion!=null and _motion.is_valid():_motion.kill()
 _motion=null
 if is_instance_valid(image_view):
  image_view.modulate.a=1.0
  if _travel:
   image_view.position=Vector2.ZERO
   image_view.scale=Vector2.ONE
   image_view.rotation=0.0

func settle() -> void:
 _settle_motion()
 if is_instance_valid(note):note.call("finish_now")

func _notification(what: int) -> void:
 if what==NOTIFICATION_RESIZED:_settle_motion()

func finish_words() -> bool:
 if is_instance_valid(note) and bool(note.call("is_revealing")):
  note.call("finish_now")
  return true
 return false

func _exit_tree() -> void:
 _settle_motion()
