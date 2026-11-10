extends Label
## One native, selectable-by-data band mark. Never a baked screenshot or font image.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
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
 var prior: Node=get_node_or_null("MarkComposition")
 if prior!=null:remove_child(prior);prior.queue_free()
 prior=get_node_or_null("MarkInkPlate")
 if prior!=null:remove_child(prior);prior.queue_free()
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
 if not _single_line and Style.layout_kind(identity_style)=="cutout" and _compose_cutout(font):
  tooltip_text=full_name
  queue_redraw();return
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

func _compose_cutout(font: Font) -> bool:
 # Live native glyphs on the existing scanned paper/ink stock, never a baked
 # band-name image. Non-ASCII words stay together so shaping remains native.
 var old: Node=get_node_or_null("MarkComposition")
 if old!=null:remove_child(old);old.queue_free()
 var tokens: Array[String]=[]
 for word in text.replace("\n"," ").split(" ",false):
  if not tokens.is_empty():tokens.append(" ")
  var ascii_only:=true
  for character in word:
   if character.unicode_at(0)>126:ascii_only=false;break
  if ascii_only:
   for character in word:tokens.append(character)
  else:tokens.append(word)
 var points: int=_max_points
 var rows: Array=[];var row_widths: Array=[]
 var row_height:=0.0
 while points>=_min_points:
  rows=[];row_widths=[]
  var line: Array=[];var width:=0.0
  row_height=font.get_height(points)+8.0
  var impossible:=false
  for token in tokens:
   var token_width: float=font.get_string_size(token,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x+(4.0 if token==" " else 9.0)
   if token_width>size.x-18.0:impossible=true;break
   if not line.is_empty() and width+token_width>size.x-18.0:
    rows.append(line);row_widths.append(width);line=[];width=0.0
   if token==" " and line.is_empty():continue
   line.append({"text":token,"width":token_width});width+=token_width
  if not line.is_empty():rows.append(line);row_widths.append(width)
  if not impossible and rows.size()*row_height+12.0<=size.y:break
  points-=1
 if points<_min_points or rows.is_empty():
  add_theme_color_override("font_color",_mark_color)
  return false
 add_theme_color_override("font_color",Color.TRANSPARENT)
 add_theme_font_size_override("font_size",points)
 var composition:=Control.new();composition.name="MarkComposition";composition.mouse_filter=Control.MOUSE_FILTER_IGNORE
 composition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(composition)
 var random:=RandomNumberGenerator.new();random.seed=absi(full_name.hash())+Style.cut_variant(identity_style)*7919
 var index:=0;var top: float=(size.y-rows.size()*row_height)/2.0
 var identity_ink: Color=Style.ink(identity_style,false)
 for row_index in range(rows.size()):
  var x: float=(size.x-float(row_widths[row_index]))/2.0
  for token in rows[row_index]:
   var width: float=token.width
   if token.text!=" ":
    var material: Color=Poster.INK if index%3==1 else (Poster.GOLD if index%5==0 else Poster.PAPER)
    var plate:=PanelContainer.new();plate.name="MarkCut_%d"%index;plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
    plate.add_theme_stylebox_override("panel",Poster.control_stock(material,2))
    plate.position=Vector2(x,top+row_index*row_height+random.randf_range(-1.5,1.5));plate.size=Vector2(width,row_height-3.0)
    plate.pivot_offset=plate.size/2;plate.rotation=deg_to_rad(random.randf_range(-4.0,4.0))
    var glyph:=Label.new();glyph.text=token.text;glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
    glyph.add_theme_font_override("font",font);glyph.add_theme_font_size_override("font_size",points)
    glyph.add_theme_color_override("font_color",Style.ink(identity_style,true) if material==Poster.INK else (Poster.INK if identity_ink.get_luminance()>0.5 else identity_ink))
    glyph.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;glyph.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    plate.add_child(glyph);composition.add_child(plate);index+=1
   x+=width
 composition.set_meta("cut_variant",Style.cut_variant(identity_style));composition.set_meta("live_glyphs",index)
 return true
