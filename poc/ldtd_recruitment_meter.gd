extends Control
## Inert red->amber->green musician attribute readout, 0-10.
## The marker is the value; the whole gradient remains visible at zero.
@export_range(0,10,1) var value: int = 5:
 set(next):
  value = clampi(next,0,10)
  queue_redraw()

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_mode = Control.FOCUS_NONE
 custom_minimum_size.y = 23.0
 resized.connect(queue_redraw)

func _draw() -> void:
 if size.x < 8 or size.y < 4:
  return
 var left := 4.0
 var length := maxf(8.0,size.x-8.0)
 var height := 9.0
 var y := (size.y-height)*0.5
 draw_rect(Rect2(0,y-3,size.x,height+6),Color("#0C1014"))
 for i in range(40):
  var t := float(i)/39.0
  var ink := Color("#C73F38").lerp(Color("#F0BE46"),minf(t*2.0,1.0)) if t <= 0.5 else Color("#F0BE46").lerp(Color("#4AC477"),(t-0.5)*2.0)
  draw_rect(Rect2(left+float(i)*length/40.0,y,length/40.0+0.4,height),ink)
 var marker_x := left+float(value)/10.0*length
 draw_rect(Rect2(marker_x-3.0,y-5.0,6.0,height+10.0),Color("#101820"))
 draw_rect(Rect2(marker_x-2.0,y-4.0,4.0,height+8.0),Color("#E6E6DA"))
