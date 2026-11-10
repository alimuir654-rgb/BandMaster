extends Label
## One native, selectable-by-data band mark. Never a baked screenshot or font image.
const Style = preload("res://experiments/playable_flightcase/identity_style.gd")
var full_name := ""
var treatment := "Wordmark"
var identity_style: Dictionary = {}
var _max_points := 70
var _min_points := 22
var _single_line := false
var _finish := "plain"
var _mark_color := Color.WHITE

func configure(value: String, logo: String, style: Dictionary, points: int = 70, on_dark: bool = false, compact: bool = false, single_line: bool = false) -> void:
 full_name=value
 treatment=logo
 identity_style=style.duplicate(true)
 _finish=Style.finish_kind(style)
 _mark_color=Style.ink(style,on_dark)
 _max_points=points
 _min_points=16 if compact else 22
 _single_line=compact and single_line
 text=Style.layout_text(value,logo,style,_single_line)
 horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 autowrap_mode=TextServer.AUTOWRAP_OFF if _single_line else TextServer.AUTOWRAP_WORD_SMART
 if _single_line:
  text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  max_lines_visible=1
  tooltip_text=value
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_mode=Control.FOCUS_NONE
 add_theme_font_override("font",Style.face(style))
 add_theme_color_override("font_color",Style.ink(style,on_dark))
 var prior: Node=get_node_or_null("MarkInkPlate")
 if prior!=null:remove_child(prior);prior.queue_free()
 if Style.layout_kind(style)=="cutout":
  var plate:=ColorRect.new();plate.name="MarkInkPlate";plate.color=_mark_color
  plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;plate.show_behind_parent=true
  plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(plate)
  add_theme_color_override("font_color",Color("191b1a") if _mark_color.get_luminance()>0.45 else Color("eee8d8"))
 add_theme_font_size_override("font_size",points)
 if _finish!="plain":
  add_theme_constant_override("outline_size",0)
 custom_minimum_size.y=float(points)*1.52 if compact else float(points)*2.10
 if text.contains("\n"):custom_minimum_size.y=float(points)*2.55
 if not resized.is_connected(_fit): resized.connect(_fit)
 call_deferred("_fit")
 queue_redraw()

func _draw() -> void:
 if _finish=="plain" or size.x<12.0:return
 var width: float=clampf(get_theme_font("font").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,get_theme_font_size("font_size")).x+12.0,12.0,size.x-8.0)
 var left: float=(size.x-width)*0.5
 var right: float=left+width
 var stroke: float=1.5
 if _finish in ["underline","rules"]:draw_line(Vector2(left,size.y-3.0),Vector2(right,size.y-3.0),_mark_color,stroke,true)
 if _finish=="rules":draw_line(Vector2(left,3.0),Vector2(right,3.0),_mark_color,stroke,true)
 if _finish=="brackets":
  for x in [left,right]:
   var direction: float=1.0 if x==left else -1.0
   draw_polyline(PackedVector2Array([Vector2(x+direction*6.0,4.0),Vector2(x,4.0),Vector2(x,size.y-4.0),Vector2(x+direction*6.0,size.y-4.0)]),_mark_color,stroke,true)

func _fit() -> void:
 if size.x<20.0: return
 var font: Font=get_theme_font("font")
 var chosen: int=_max_points
 var available: float=maxf(custom_minimum_size.y,22.0)
 var inset: float=20.0 if _finish=="brackets" else 4.0
 if _single_line:
  # Practice headers explicitly opt into a single line; naming/identity
  # previews and posters retain their original multiline fitting method.
  # Measure the decorated mark as one line. Word wrapping can otherwise
  # approve a lone closing stamp dash on a second line. Keep the minimum
  # readable size; only genuinely longer names use the native ellipsis.
  while chosen>_min_points and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,chosen).x>size.x-inset:
   chosen-=1
  add_theme_font_size_override("font_size",chosen)
  return
 while chosen>_min_points:
  var measure: Vector2=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,maxf(20.0,size.x-inset),chosen)
  var longest_word: float=0.0
  for word in text.split(" ",false):
   longest_word=maxf(longest_word,font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,chosen).x)
  if longest_word<=size.x-inset and measure.y<=available- (8.0 if _finish!="plain" else 0.0) and measure.x<=size.x+1.0: break
  chosen-=1
 add_theme_font_size_override("font_size",chosen)
 tooltip_text=full_name
 queue_redraw()
