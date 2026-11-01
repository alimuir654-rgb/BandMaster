extends Control
## Presentation only. The owning UI has already resolved and saved the action.
## Neither this node nor its callbacks may advance time or call a game resolver.
signal covered
signal finished

const Kit = preload("res://components/control_atlas/kit.gd")
var reduced_motion := false
var style := "flightcase"
var focus_kind := "tighten"
var completed_day := 1
var next_day := 1
var available_cash := 0
var _shade: ColorRect
var _card: VBoxContainer
var _skip: Button
var _motion: Tween
var _has_covered := false
var _closed := false

func configure(kind: String, report: Dictionary, reduce: bool, look: String, current_day: int = 0, current_cash: int = -1) -> void:
 focus_kind = kind
 completed_day = int(report.get("metrics",{}).get("tour_day",{}).get("before",1))
 next_day = current_day if current_day>0 else int(report.get("metrics",{}).get("tour_day",{}).get("after",completed_day+1))
 available_cash = current_cash if current_cash>=0 else int(report.get("metrics",{}).get("cash",{}).get("after",0))
 reduced_motion = reduce
 style = look

func _ready() -> void:
 name = "SessionTransition"
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 _shade = ColorRect.new()
 _shade.name = "SessionTransitionShade"
 _shade.color = Color(0.025,0.03,0.032,0.0)
 _shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 add_child(_shade)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for side in ["left","top","right","bottom"]:
  margin.add_theme_constant_override("margin_"+side,24)
 add_child(margin)
 var center := CenterContainer.new()
 center.mouse_filter = Control.MOUSE_FILTER_IGNORE
 margin.add_child(center)
 _card = VBoxContainer.new()
 _card.name = "SessionBeatCard"
 _card.visible = false
 _card.add_theme_constant_override("separation",16)
 _card.custom_minimum_size.x = minf(520.0,maxf(260.0,size.x-48.0))
 center.add_child(_card)
 var heading_text: String = "DAY %d" % next_day if focus_kind=="day" else str({"tighten":"IN THE REHEARSAL ROOM","create":"WRITING TOGETHER","connect":"CLEARING THE AIR","report":"THE SESSION FILES"}.get(focus_kind,"WITH THE BAND"))
 var heading := Kit.label(heading_text,style,26)
 heading.name = "SessionBeatTitle"
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 _card.add_child(heading)
 var day_text: String = "£%d AVAILABLE  •  CHOOSE YOUR NEXT SESSION" % available_cash if focus_kind=="day" else ("SAVED NOTES  •  NO TIME SPENT" if focus_kind=="report" else "DAY %d  •  SESSION COMPLETE" % completed_day)
 var day := Kit.label(day_text,style,16)
 day.name = "SessionBeatDay"
 day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 day.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 day.add_theme_color_override("font_color",Color("f0c78b"))
 _card.add_child(day)
 _skip = Kit.button("PLAN THE DAY  ›" if focus_kind=="day" else ("SHOW SAVED NOTES  ›" if focus_kind=="report" else "SHOW THE RESULTS  ›"),style,"tab")
 _skip.name = "SkipSessionBeatAction"
 _skip.pressed.connect(finish_now)
 _card.add_child(_skip)
 resized.connect(_fit_card)
 # Start after add_child has completed; reduced-motion cleanup can then safely
 # remove this node without mutating a parent that is still entering the tree.
 call_deferred("_start")

func _fit_card() -> void:
 if is_instance_valid(_card):
  _card.custom_minimum_size.x = minf(520.0,maxf(260.0,size.x-48.0))

func _start() -> void:
 if _closed or not is_inside_tree():
  return
 if reduced_motion:
  finish_now()
  return
 _motion = create_tween()
 _motion.tween_property(_shade,"color:a",1.0,0.15)
 _motion.tween_callback(_cover)
 _motion.tween_interval(0.40 if focus_kind=="day" else (0.0 if focus_kind=="report" else 0.65))
 _motion.tween_property(self,"modulate:a",0.0,0.20)
 _motion.tween_callback(finish_now)

func _cover() -> void:
 if _closed or _has_covered:
  return
 _has_covered = true
 _card.visible = true
 covered.emit()
 if is_instance_valid(_skip) and is_visible_in_tree():
  _skip.grab_focus()

func finish_now() -> void:
 if _closed:
  return
 if is_instance_valid(_motion):
  _motion.kill()
 _cover()
 _closed = true
 finished.emit()

func abort() -> void:
 # Teardown is not a completed action. The model was committed before the
 # presentation began; leaving the tree must never invoke it again.
 _closed = true
 if is_instance_valid(_motion):
  _motion.kill()

func _exit_tree() -> void:
 abort()

func _input(event: InputEvent) -> void:
 if _closed or not is_visible_in_tree():
  return
 if event is InputEventKey:
  # Consume repeated acceptance keys instead of forwarding the same key to a
  # newly focused result action after the overlay has been removed.
  get_viewport().set_input_as_handled()
  if event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_ESCAPE]:
   finish_now()
  elif event.pressed and event.keycode==KEY_TAB and _card.visible:
   _skip.grab_focus()

