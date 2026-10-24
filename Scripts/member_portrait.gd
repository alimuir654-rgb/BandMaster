extends Control
# Offline vector portrait: different silhouettes for each musician, no asset dependency.
var person_id := ""
var initials := "?"
const COLOURS := [
 Color("#6B8FA5"),Color("#B37883"),Color("#9282B2"),Color("#7A9D8B"),
 Color("#B09A70"),Color("#847C9D"),Color("#578F93"),Color("#B17668")
]
func set_character(value: String, display_name: String) -> void:
 person_id = value
 initials = display_name.left(1).to_upper()
 queue_redraw()

func _ready() -> void:
 custom_minimum_size = Vector2(90,108)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 queue_redraw()

func _draw() -> void:
 var size_vec := size
 var width := maxf(1.0,size_vec.x)
 var height := maxf(1.0,size_vec.y)
 var seed := absi(person_id.hash())
 var base: Color = COLOURS[seed % COLOURS.size()]
 draw_rect(Rect2(Vector2.ZERO,size_vec),base.darkened(0.64))
 draw_rect(Rect2(Vector2(5,5),Vector2(width-10,height-10)),base.darkened(0.35))
 var center := Vector2(width*0.5,height*0.49)
 var scale_value := minf(width/100.0,height/110.0)
 var shoulders := Vector2(width*0.5,height*0.91)
 draw_circle(shoulders,44.0*scale_value,base.darkened(0.12))
 draw_circle(center,26.0*scale_value,Color("#D7AE88") if seed%3==0 else (Color("#AE795F") if seed%3==1 else Color("#E0BBA1")))
 var head_top := center + Vector2(0,-13.0*scale_value)
 draw_circle(head_top,26.0*scale_value,Color("#251F2A") if seed%2==0 else Color("#51413E"))
 draw_circle(center+Vector2(0,5.0*scale_value),23.0*scale_value,Color("#D7AE88") if seed%3==0 else (Color("#AE795F") if seed%3==1 else Color("#E0BBA1")))
 var eye_y := center.y+6*scale_value
 draw_circle(Vector2(center.x-9*scale_value,eye_y),2.3*scale_value,Color("#22242B"))
 draw_circle(Vector2(center.x+9*scale_value,eye_y),2.3*scale_value,Color("#22242B"))
 draw_line(Vector2(center.x-5*scale_value,center.y+17*scale_value),Vector2(center.x+5*scale_value,center.y+17*scale_value),Color("#70483E"),1.7*scale_value)
 if seed%4==0:
  draw_arc(center,30*scale_value,PI*1.05,PI*1.95,16,base.lightened(0.18),3*scale_value,true)
 draw_line(Vector2(8,height-9),Vector2(width-8,height-9),Color("#F0B44D"),2.0)
