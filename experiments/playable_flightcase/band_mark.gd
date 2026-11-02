extends Label
## One native, selectable-by-data band mark. Never a baked screenshot or font image.
const Style = preload("res://experiments/playable_flightcase/identity_style.gd")
var full_name := ""
var treatment := "Wordmark"
var identity_style: Dictionary = {}
var _max_points := 70
var _min_points := 22
var _compact := false

func configure(value: String, logo: String, style: Dictionary, points: int = 70, on_dark: bool = false, compact: bool = false) -> void:
 full_name=value
 treatment=logo
 identity_style=style.duplicate(true)
 text=Style.mark_text(value,logo)
 _max_points=points
 _min_points=16 if compact else 22
 _compact=compact
 horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 autowrap_mode=TextServer.AUTOWRAP_OFF if compact else TextServer.AUTOWRAP_WORD_SMART
 if compact:
  text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  max_lines_visible=1
  tooltip_text=value
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_mode=Control.FOCUS_NONE
 add_theme_font_override("font",Style.face(style))
 add_theme_color_override("font_color",Style.ink(style,on_dark))
 add_theme_font_size_override("font_size",points)
 custom_minimum_size.y=float(points)*1.52 if compact else float(points)*2.10
 if not resized.is_connected(_fit): resized.connect(_fit)
 call_deferred("_fit")

func _fit() -> void:
 if size.x<20.0: return
 var font: Font=get_theme_font("font")
 var chosen: int=_max_points
 var available: float=maxf(custom_minimum_size.y,22.0)
 if _compact:
  # Measure the decorated mark as one line. Word wrapping can otherwise
  # approve a lone closing stamp dash on a second line. Keep the minimum
  # readable size; only genuinely longer names use the native ellipsis.
  while chosen>_min_points and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,chosen).x>size.x-4.0:
   chosen-=1
  add_theme_font_size_override("font_size",chosen)
  return
 while chosen>_min_points:
  var measure: Vector2=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,maxf(20.0,size.x-4.0),chosen)
  if measure.y<=available and measure.x<=size.x+1.0: break
  chosen-=1
 add_theme_font_size_override("font_size",chosen)
