extends Control
## Original text-free sleeve illustration plus separate live native lettering.
const P=preload("res://experiments/playable_flightcase/poster_components.gd")
var identity: String=""
var caption: String="DEBUT DEMO"
var _words: Label
func _ready() -> void:
 if custom_minimum_size.x<1:custom_minimum_size.x=120
 if custom_minimum_size.y<1:custom_minimum_size.y=120
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 _words=P.label(caption,28,P.PAPER);_words.name="NativeSleeveLettering";_words.add_theme_font_override("font",P.MARKER);_words.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;add_child(_words)
 resized.connect(_layout);_layout()
func _layout() -> void:
 var edge: float=minf(size.x,size.y)
 if _words!=null:
  _words.visible=edge>=180
  _words.position=Vector2((size.x-edge)*0.5+edge*0.28,(size.y-edge)*0.5+edge*0.67)
  _words.size=Vector2(edge*0.66,edge*0.28)
  _words.add_theme_font_size_override("font_size",clampi(int(edge*0.105),20,42))
 queue_redraw()
func _draw() -> void:
 var edge: float=minf(size.x,size.y)
 var rect:=Rect2((size-Vector2(edge,edge))*0.5,Vector2(edge,edge))
 draw_texture_rect(P.cell(5),rect,false)
 set_meta("art_rect",rect);set_meta("art_source_region",Rect2(1024,512,512,512));set_meta("no_aspect_stretch",true)
