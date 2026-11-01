extends Control
## One retained Settings sheet. Owner performs existing in-place sound/motion toggles.
## Owner handles these requests with its existing in-place toggle methods.
signal sound_requested
signal motion_requested
signal notes_style_requested
signal closed

const Kit = preload("res://components/control_atlas/kit.gd")
var look := "flightcase"
var is_open := false
var panel: PanelContainer
var sound_button: Button
var motion_button: Button
var notes_button: Button
var back_button: Button
var _options_scroll: ScrollContainer
var _options: VBoxContainer
var _column: VBoxContainer
var _title: Label
var _previous_focus: WeakRef
var _fit_pending := false
var _muted := false
var _reduced_motion := false
var _notes_caption := ""

func _ready() -> void:
 name = "MenuSettingsSheet"
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 focus_mode = Control.FOCUS_NONE
 z_index = 100
 panel = Kit.frame(look,"modal")
 panel.name = "MenuSettingsPanel"
 add_child(panel)
 _column = VBoxContainer.new()
 _column.add_theme_constant_override("separation",12)
 panel.add_child(_column)
 _title = Kit.label("SETTINGS",look,22)
 _title.name = "SettingsSheetTitle"
 _title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 _column.add_child(_title)
 _options_scroll = ScrollContainer.new()
 _options_scroll.name = "SettingsOptionsScroll"
 _options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _options_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 _options_scroll.follow_focus = true
 _options_scroll.focus_mode = Control.FOCUS_NONE
 _options_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_NONE
 _options_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _column.add_child(_options_scroll)
 _options = VBoxContainer.new()
 _options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _options.add_theme_constant_override("separation",8)
 _options_scroll.add_child(_options)
 sound_button = Kit.button("",look,"tab")
 sound_button.name = "SoundAction"
 sound_button.pressed.connect(func():sound_requested.emit())
 _options.add_child(sound_button)
 motion_button = Kit.button("",look,"tab")
 motion_button.name = "MotionAction"
 motion_button.pressed.connect(func():motion_requested.emit())
 _options.add_child(motion_button)
 notes_button = Kit.button("",look,"tab")
 notes_button.name = "NotesStyleAction"
 notes_button.pressed.connect(func():notes_style_requested.emit())
 _options.add_child(notes_button)
 var scope: Label = Kit.label("Sound, transitions and note style apply to this play session.",look,14)
 scope.name = "SettingsSessionScope"
 scope.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 scope.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _options.add_child(scope)
 back_button = Kit.button("BACK",look,"action")
 back_button.name = "SettingsBackAction"
 back_button.pressed.connect(close_sheet)
 _column.add_child(back_button)
 resized.connect(_queue_fit)
 panel.minimum_size_changed.connect(_queue_fit)
 _options.minimum_size_changed.connect(_queue_fit)
 set_preferences(_muted,_reduced_motion,_notes_caption)
 hide()
 _queue_fit()

func set_preferences(sound_muted: bool, motion_reduced: bool, notes_caption: String = "") -> void:
 _muted = sound_muted
 _reduced_motion = motion_reduced
 _notes_caption = notes_caption
 if not is_instance_valid(sound_button):return
 sound_button.text = "MASTER SOUND: MUTED" if _muted else "MASTER SOUND: ON"
 sound_button.tooltip_text = sound_button.text
 motion_button.text = "TRANSITIONS: OFF" if _reduced_motion else "TRANSITIONS: ON"
 motion_button.tooltip_text = "Off shows the same results immediately in this play session."
 # Optional only when the owner actually supplies/wires a real notes setting.
 notes_button.visible = not _notes_caption.is_empty()
 notes_button.text = "NOTES: "+_notes_caption
 notes_button.tooltip_text = notes_button.text
 _link_focus()
 _queue_fit()

func _buttons() -> Array[Button]:
 var result: Array[Button] = []
 for button in [sound_button,motion_button,notes_button,back_button]:
  if is_instance_valid(button) and button.visible and not button.disabled:
   result.append(button)
 return result

func _link_focus() -> void:
 var buttons: Array[Button] = _buttons()
 for index in range(buttons.size()):
  var previous: Button = buttons[posmod(index-1,buttons.size())]
  var next: Button = buttons[posmod(index+1,buttons.size())]
  buttons[index].focus_previous = buttons[index].get_path_to(previous)
  buttons[index].focus_next = buttons[index].get_path_to(next)
  buttons[index].focus_neighbor_top = buttons[index].get_path_to(previous)
  buttons[index].focus_neighbor_bottom = buttons[index].get_path_to(next)
  buttons[index].focus_neighbor_left = buttons[index].get_path_to(previous)
  buttons[index].focus_neighbor_right = buttons[index].get_path_to(next)

func _queue_fit() -> void:
 if _fit_pending or not is_inside_tree():return
 _fit_pending = true
 call_deferred("_fit")

func _fit() -> void:
 _fit_pending = false
 if not is_inside_tree() or not is_instance_valid(panel):return
 # Parent is already the S51 safe-sized RootUI. Do not apply insets again.
 var available: Vector2 = Vector2(maxf(0.0,size.x-24.0),maxf(0.0,size.y-24.0))
 var width: float = minf(460.0,available.x)
 panel.size.x = width
 var style: StyleBox = panel.get_theme_stylebox("panel")
 var chrome: float = style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM)+_title.get_combined_minimum_size().y+back_button.get_combined_minimum_size().y+24.0
 var room: float = maxf(0.0,available.y-chrome)
 _options_scroll.custom_minimum_size.y = minf(_options.get_combined_minimum_size().y,room)
 panel.size = Vector2(width,panel.get_combined_minimum_size().y)
 panel.position = Vector2(roundf((size.x-panel.size.x)*0.5),roundf(maxf(12.0,size.y-panel.size.y-24.0)) if size.x<600.0 else roundf((size.y-panel.size.y)*0.5))
 queue_redraw()

func open_sheet(invoker: Control = null) -> void:
 if not is_node_ready():return
 if is_open:
  _queue_fit()
  return
 var focused: Control = invoker if is_instance_valid(invoker) else get_viewport().gui_get_focus_owner()
 _previous_focus = weakref(focused) if focused!=null else null
 is_open = true
 panel.show()
 show()
 _fit()
 sound_button.grab_focus()

func close_sheet(restore_focus: bool = true) -> void:
 if not is_open:return
 is_open = false
 panel.hide()
 hide()
 if restore_focus and _previous_focus!=null:
  var previous: Variant = _previous_focus.get_ref()
  if is_instance_valid(previous) and previous is Control and previous.is_inside_tree() and previous.is_visible_in_tree() and previous.focus_mode!=Control.FOCUS_NONE:
   if not previous is BaseButton or not previous.disabled:previous.grab_focus()
 _previous_focus = null
 # Owner also restores the CURRENT semantic SettingsAction after a responsive
 # menu rebuild; the original weak invoker may have been replaced legitimately.
 closed.emit()

func _input(event: InputEvent) -> void:
 if not is_open or not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled()
  close_sheet()
 elif event.keycode==KEY_TAB:
  get_viewport().set_input_as_handled()
  var buttons: Array[Button] = _buttons()
  if buttons.is_empty():return
  var focused: Control = get_viewport().gui_get_focus_owner()
  # Focus can temporarily belong to another Control during host lifecycle
  # changes. TypedArray[Button].find(Label) itself raises an engine error.
  var index: int = -1
  for candidate in range(buttons.size()):
   if buttons[candidate]==focused:
    index = candidate
    break
  index = posmod(index+(-1 if event.shift_pressed else 1),buttons.size()) if index>=0 else (buttons.size()-1 if event.shift_pressed else 0)
  buttons[index].grab_focus()
  if _options_scroll.is_ancestor_of(buttons[index]):_options_scroll.ensure_control_visible(buttons[index])
 elif event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
  var focused: Control = get_viewport().gui_get_focus_owner()
  if focused==null or not is_ancestor_of(focused):
   # A responsive/stale focus must never activate the covered menu.
   get_viewport().set_input_as_handled()
   sound_button.grab_focus()
 # Enter/Space remain the native Button behavior: one actual press, not a
 # second manual emission from this overlay.

func _gui_input(_event: InputEvent) -> void:
 if is_open:accept_event()

func _draw() -> void:
 if is_open:draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.020,0.025,0.78))

func _exit_tree() -> void:
 is_open = false
 _previous_focus = null
