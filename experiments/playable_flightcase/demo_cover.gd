extends Control
## Deterministic original screen-print art keyed to saved recording identity.
## Native labels stay outside this drawing; never a screenshot-as-interface.
var identity: String=""
func _ready() -> void:
 custom_minimum_size.x=160
 if custom_minimum_size.y<1:custom_minimum_size.y=210
 size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 var seed_value: int=absi(identity.hash());var gold:=Color("e7b83d");var ink:=Color("191b1a")
 draw_rect(Rect2(Vector2.ZERO,size),ink)
 var center:=size*Vector2(0.5,0.48);var radius: float=minf(size.x*0.36,size.y*0.39)
 draw_circle(center,radius,gold)
 var slope: float=float(seed_value%9-4)*0.04
 for i in range(6):
  var y: float=size.y*(0.18+0.105*i)
  draw_line(Vector2(0,y),Vector2(size.x,y+size.x*slope),ink,8+i*2,true)
 draw_circle(center,radius*0.16,Color("eee8d8"))
 draw_line(Vector2(size.x*0.08,size.y*0.9),Vector2(size.x*0.92,size.y*0.9),gold,4,true)
