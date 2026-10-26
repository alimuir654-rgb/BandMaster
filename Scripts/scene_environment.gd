extends Control
# Deterministic, non-interactive environmental texture.
# Drawn beneath the UI; never uses expensive per-frame effects.
var scene_id := "HOME"

func set_scene(value: String) -> void:
 scene_id = value
 queue_redraw()

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 var w := size.x
 var h := size.y
 if w <= 0.0 or h <= 0.0:
  return
 match scene_id:
  "HOME":
   draw_rect(Rect2(0,0,w,h),Color("#201C1B"))
   draw_rect(Rect2(0,0,w,h*0.38),Color("#382A22",0.60))
   for i in range(7):
    draw_line(Vector2(0,h*0.49+i*95),Vector2(w,h*0.49+i*95),Color("#8F704A",0.10),2)
   draw_circle(Vector2(w*0.85,h*0.14),minf(w,h)*0.20,Color("#C28B43",0.055))
  "DAY":
   draw_rect(Rect2(0,0,w,h),Color("#393B35"))
   draw_rect(Rect2(0,0,w,h*0.65),Color("#616454",0.22))
   for i in range(15):
    var y := float(i)*64.0
    draw_line(Vector2(0,y),Vector2(w,y),Color("#E3D5AE",0.045),1)
   draw_rect(Rect2(w*0.71,0,w*0.14,h),Color("#F3DFC2",0.035))
  "STUDIO":
   draw_rect(Rect2(0,0,w,h),Color("#121D22"))
   for i in range(30):
    var x := float(i)*64.0
    draw_line(Vector2(x,0),Vector2(x,h),Color("#67A4A5",0.07),1)
   for i in range(14):
    var y := float(i)*72.0
    draw_line(Vector2(0,y),Vector2(w,y),Color("#67A4A5",0.045),1)
   for i in range(9):
    draw_rect(Rect2(w-50-i*16,h*0.20+float(i%3)*18,6,28),Color("#9BD0A8",0.10))
  "GIGS":
   draw_rect(Rect2(0,0,w,h),Color("#100F1B"))
   draw_circle(Vector2(w*0.18,-h*0.09),h*0.62,Color("#9F385F",0.11))
   draw_circle(Vector2(w*0.84,0),h*0.48,Color("#7260B0",0.09))
   for i in range(19):
    var y := h*0.64+float(i)*18.0
    draw_line(Vector2(0,y),Vector2(w,y),Color("#D67D93",0.045),2)
  "GEAR":
   draw_rect(Rect2(0,0,w,h),Color("#152822"))
   draw_rect(Rect2(0,h*0.62,w,h*0.38),Color("#594634",0.52))
   for i in range(11):
    draw_line(Vector2(0,h*0.63+float(i)*31),Vector2(w,h*0.63+float(i)*31),Color("#E3C5A0",0.035),2)
   draw_circle(Vector2(w*0.82,h*0.21),minf(w,h)*0.34,Color("#D5AF6D",0.10))
  "BAND":
   draw_rect(Rect2(0,0,w,h),Color("#1D2332"))
   draw_rect(Rect2(0,h*0.69,w,h*0.31),Color("#482C3B",0.50))
   draw_circle(Vector2(w*0.76,h*0.16),minf(w,h)*0.36,Color("#D792A8",0.09))
   for i in range(6):
    draw_line(Vector2(float(i)*w/5.0,0),Vector2(float(i)*w/5.0,h),Color("#F1C5D0",0.025),2)
  "SCENE":
   draw_rect(Rect2(0,0,w,h),Color("#151E37"))
   draw_circle(Vector2(w*0.67,h*0.21),minf(w,h)*0.48,Color("#A86A9E",0.11))
   draw_rect(Rect2(0,h*0.74,w,h*0.26),Color("#3B2739",0.52))
   for i in range(10):
    draw_line(Vector2(0,h*0.76+float(i)*18),Vector2(w,h*0.76+float(i)*18),Color("#DAB0CC",0.04),2)
  _:
   draw_rect(Rect2(0,0,w,h),Color("#101720"))
