extends RefCounted
## Shared presentation primitives for the existing playtest and career desk.
## These factories never resolve an action, connect callbacks, or write a save.
## Original controls/materials remain the source; branding is RGBA art, not a font.
const Kit = preload("res://components/control_atlas/kit.gd")
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const Poster = preload("res://experiments/playable_flightcase/poster_components.gd")
const WORDMARK_PATH := "res://experiments/playable_flightcase/art/opening_wordmark.png"
const WORDMARK_CROP := Rect2i(264,95,1248,718)
const WORDMARK_TEXT := "LIVIN' THE\nDREAM"
static var _brand_texture_cache: ImageTexture


static func label(value: String, points: int = 16, look: String = "flightcase") -> Label:
 var result: Label = Poster.label(value,points,Poster.INK if look=="notepaper" else Poster.PAPER)
 result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.focus_mode = Control.FOCUS_NONE
 return result


static func paper_label(value: String, points: int = 16, muted: bool = false) -> Label:
 # Preserve RehearsalPress.ink's default SIZE_FILL, unlike ordinary labels.
 # A caller requiring expansion (such as ui._ink) sets it explicitly.
 var result: Label = Poster.label(value,points,Poster.INK)
 result.size_flags_horizontal=Control.SIZE_FILL
 result.add_theme_color_override("font_color",Color("695c4b") if muted else Color("29241f"))
 result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.focus_mode = Control.FOCUS_NONE
 return result


static func button(value: String, look: String = "flightcase", family: String = "action", toggle: bool = false) -> Button:
 # Preserve the verified state textures, 48px minimum, 16px native text,
 # disabled/focus behaviour and source provenance from the original factory.
 # The owning view sets its node name and connects its one action callback.
 var result: Button=Poster.button(value,family=="primary")
 result.toggle_mode=toggle
 if toggle:Poster.choice_style(result)
 return result


static func sheet(compact: bool) -> StyleBoxTexture:
 # Paper.sheet returns a fresh style referencing its unchanged cached texture.
 # Keep its fixed slices, safety bleed and actual content-safe insets intact.
 return Paper.sheet(compact)


static func dialog(title: String, body: String, look: String = "flightcase") -> Control:
 # Keep the original modal's focus, scrolling, Escape and once-only result.
 # Presentation is opt-in here, inside the Playtest; other Kit users retain it.
 var result: Control=Kit.dialog(title,body,look)
 result.ready.connect(_poster_dialog_ready.bind(result))
 return result


static func _poster_dialog_ready(dialog_view: Control) -> void:
 var panel: PanelContainer=dialog_view.get("panel")
 panel.add_theme_stylebox_override("panel",Poster.stock(Poster.INK,24))
 var heading: Label=dialog_view.get("heading")
 heading.add_theme_font_override("font",Poster.DISPLAY)
 heading.add_theme_font_size_override("font_size",24)
 heading.add_theme_color_override("font_color",Poster.PAPER)
 var message: Label=dialog_view.get("message_label")
 message.add_theme_font_override("font",Poster.FONT)
 message.add_theme_color_override("font_color",Poster.PAPER)
 for key in ["cancel_button","confirm_button"]:
  var action: Button=dialog_view.get(key)
  Poster.choice_style(action)
  action.custom_minimum_size.y=52
 dialog_view.call_deferred("_fit")


static func meter(value: int, look: String = "flightcase") -> HBoxContainer:
 # The model supplies a 0..100 value. Only the visual lookup is bounded;
 # the number stays exact instead of displaying a rounded ten-segment value.
 # 99 is nine segments, and only 100 fills all ten original segments.
 var segments: int = floori(float(clampi(value,0,100)) / 10.0)
 var row := HBoxContainer.new()
 row.name = "CareerMeter"
 row.add_theme_constant_override("separation",8)
 row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.focus_mode = Control.FOCUS_NONE
 row.set_meta("source_value",value)
 row.set_meta("visual_segments",segments)
 row.set_meta("scale_maximum",100)
 row.set_meta("read_only",true)
 var art: TextureRect = Kit.PassiveMeter.new(look,segments)
 art.name = "CareerMeterArt"
 art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 art.tooltip_text = "%d / 100 (read only)" % value
 row.add_child(art)
 var number: Label = label("%d / 100" % value,16,look)
 number.name = "CareerMeterValue"
 number.autowrap_mode = TextServer.AUTOWRAP_OFF
 number.size_flags_horizontal = Control.SIZE_SHRINK_END
 number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(number)
 return row


static func _wordmark_texture() -> ImageTexture:
 if _brand_texture_cache != null:
  return _brand_texture_cache
 if not ResourceLoader.exists(WORDMARK_PATH):
  return null
 var source: Texture2D = load(WORDMARK_PATH) as Texture2D
 if source == null:
  return null
 var image: Image = source.get_image()
 if image == null or image.is_empty():
  return null
 if image.is_compressed() and image.decompress() != OK:
  return null
 if not Rect2i(Vector2i.ZERO,image.get_size()).encloses(WORDMARK_CROP):
  return null
 # Same measured main-ink crop as the verified opening. Original PNG stays
 # untouched; this creates only a cached runtime texture of that region.
 _brand_texture_cache = ImageTexture.create_from_image(image.get_region(WORDMARK_CROP))
 return _brand_texture_cache


static func brand(height: float = 80.0) -> Control:
 var result := Control.new()
 result.name = "CareerBrand"
 var fitted_height: float = height if height > 0.0 else 80.0
 var aspect: float = float(WORDMARK_CROP.size.x) / float(WORDMARK_CROP.size.y)
 result.custom_minimum_size = Vector2(fitted_height * aspect,fitted_height)
 result.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.focus_mode = Control.FOCUS_NONE
 result.set_meta("brand_text",WORDMARK_TEXT)
 result.set_meta("lettering_kind","Original RGBA wordmark artwork; not an installable font")
 var native_copy: Label = label(WORDMARK_TEXT,maxi(12,roundi(fitted_height * 0.30)))
 native_copy.name = "CareerBrandNativeText"
 native_copy.autowrap_mode = TextServer.AUTOWRAP_OFF
 native_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 native_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 native_copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 result.add_child(native_copy)
 var texture: ImageTexture = _wordmark_texture()
 if texture != null:
  var art := TextureRect.new()
  art.name = "CareerBrandWordmark"
  art.texture = texture
  art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  art.mouse_filter = Control.MOUSE_FILTER_IGNORE
  art.focus_mode = Control.FOCUS_NONE
  art.set_meta("source",WORDMARK_PATH)
  art.set_meta("source_crop_rect",WORDMARK_CROP)
  art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  result.add_child(art)
  # Retain native wording and its visible fallback if the asset cannot load.
  native_copy.self_modulate.a = 0.0
 return result


static func background() -> TextureRect:
 var result := TextureRect.new()
 result.texture = Poster.backdrop_texture()
 result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 result.stretch_mode = TextureRect.STRETCH_SCALE
 result.modulate = Color(0.18,0.19,0.18)
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 return result
