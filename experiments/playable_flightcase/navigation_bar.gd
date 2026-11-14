extends RefCounted
## Presentation only. Each caller supplies its existing guarded exit actions.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")

static func add(parent: Control,title: String,back: Button,menu: Button) -> HBoxContainer:
 var bar:=HBoxContainer.new()
 bar.name="NavigationBar"
 bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 bar.add_theme_constant_override("separation",8)
 parent.add_child(bar)
 for action in [back,menu]:
  preload("res://experiments/playable_flightcase/control_roles.gd").quiet(action)
  action.custom_minimum_size=Vector2(96,52)
  action.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
  action.mouse_filter=Control.MOUSE_FILTER_STOP
  action.set_meta("global_navigation",true)
  minimum(action,parent)
 bar.add_child(back)
 var current: Label=Poster.label(title,18,Poster.PAPER)
 current.name="NavigationPlace"
 current.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 current.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 current.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 current.autowrap_mode=TextServer.AUTOWRAP_OFF
 current.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 current.mouse_filter=Control.MOUSE_FILTER_IGNORE
 bar.add_child(current)
 bar.add_child(menu)
 return bar

static func minimum(button: Button,host: Control) -> void:
 if not host.is_inside_tree():return
 var scale: Vector2=(host.get_viewport().get_final_transform()*host.get_global_transform_with_canvas()).get_scale().abs()
 button.custom_minimum_size=button.custom_minimum_size.max(Vector2(ceilf(48.0/maxf(0.01,scale.x)),ceilf(48.0/maxf(0.01,scale.y))))
