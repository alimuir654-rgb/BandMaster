extends Control
## A held, read-only rehearsal intent. The owner performs the eventual save.
signal chosen(intent: String)
signal cancelled
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
var _state: Dictionary={}
var _view: Dictionary={}
var _done := false

func configure(state: Dictionary, view: Dictionary) -> void:
 _state=state.duplicate(true)
 _view=view.duplicate(true)
 name="WorkConflictView"

func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 z_index=120
 mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(_render)
 _render()

func _box(gap: int = 8) -> VBoxContainer:
 var result:=VBoxContainer.new()
 result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 result.add_theme_constant_override("separation",gap)
 return result

func _copy(parent: Node, text: String, points: int = 16, id: String = "") -> Label:
 var label: Label=C.paper_label(text,points)
 if not id.is_empty():label.name=id
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(label)
 return label

func _action(parent: Node, title: String, id: String, intent: String) -> Button:
 var button: Button=C.button(title)
 button.name=id
 button.pressed.connect(_choose.bind(intent))
 parent.add_child(button)
 return button

func _render() -> void:
 if not is_inside_tree():return
 var focused: Control=get_viewport().gui_get_focus_owner()
 var previous: String=str(focused.name) if is_instance_valid(focused) and is_ancestor_of(focused) else "WorkConflictBackAction"
 for child in get_children():remove_child(child);child.queue_free()
 add_child(C.background())
 var margin:=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 add_child(margin)
 var shell:=_box(10)
 margin.add_child(shell)
 shell.add_child(C.label("AN EVENING CLASH",22))
 var scroll:=ScrollContainer.new()
 scroll.name="WorkConflictScroll"
 scroll.follow_focus=true
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 shell.add_child(scroll)
 var panel:=PanelContainer.new()
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 panel.mouse_filter=Control.MOUSE_FILTER_PASS
 panel.add_theme_stylebox_override("panel",C.sheet(size.x<840))
 scroll.add_child(panel)
 var body:=_box(10)
 panel.add_child(body)
 _copy(body,"DAY %d • EVENING" % int(_view.get("day",1)),16,"WorkConflictDay")
 for missing in _view.get("absent",[]):
  var row:=HBoxContainer.new()
  row.add_theme_constant_override("separation",12)
  body.add_child(row)
  var person: Dictionary=Cast.by_id(str(missing.id))
  var path: String=str(person.get("portrait_preview",""))
  if not path.is_empty() and ResourceLoader.exists(path):
   var photo:=TextureRect.new()
   photo.texture=load(path)
   photo.custom_minimum_size=Vector2(72,76)
   photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
   photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
   row.add_child(photo)
  _copy(row,str(missing.name)+" · "+str(missing.get("reason","recorded commitment"))+" this evening.",18)
 _copy(body,"Move the session to a shared free evening, or rehearse with the musicians who can attend. Work and family commitments affect availability. Personal income is separate from the band fund.",16,"WorkConflictContext")
 var count: int=(_view.get("attendee_indices",[]) as Array).size()
 _copy(body,"%d musicians are available. Room hire is £15 and rehearsal uses 1 day when it happens." % count,16,"WorkConflictAttendance")
 if not str(_view.get("notice","")).is_empty():_copy(body,str(_view.notice),16,"WorkConflictNotice")
 var dock:=_box(5)
 shell.add_child(dock)
 _action(dock,"RESCHEDULE","WorkConflictRescheduleAction","reschedule")
 var proceed: Button=_action(dock,"REHEARSE WITH AVAILABLE","WorkConflictProceedAction","proceed")
 proceed.disabled=count<2
 proceed.tooltip_text="At least two musicians must be able to attend." if count<2 else "Use the room with the musicians who are available."
 _action(dock,"BACK TO PRACTICE","WorkConflictBackAction","back")
 var focusable: Array[Button]=[]
 for item in dock.get_children():
  if item is Button and not item.disabled:focusable.append(item)
 for index in range(focusable.size()):
  var current: Button=focusable[index]
  var following: NodePath=current.get_path_to(focusable[(index+1)%focusable.size()])
  var previous_path: NodePath=current.get_path_to(focusable[(index+focusable.size()-1)%focusable.size()])
  current.focus_next=following
  current.focus_previous=previous_path
  current.focus_neighbor_bottom=following
  current.focus_neighbor_top=previous_path
 var next: Control=find_child(previous,true,false) as Control
 if next!=null:next.call_deferred("grab_focus")

func _choose(intent: String) -> void:
 if _done:return
 _done=true
 if intent=="back":cancelled.emit()
 else:chosen.emit(intent)

func _unhandled_key_input(event: InputEvent) -> void:
 if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled()
  _choose("back")
