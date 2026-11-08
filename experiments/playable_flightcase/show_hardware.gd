extends VBoxContainer
## Paper choices edit only the host's free soundcheck draft.
## Keep the original exact 0–100 API and silent hydration; no save/resolver here.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
signal level_changed(value: float)
var level:=50.0
var read_only:=false
var _role: String="approach"
var _choices: Array[Button]=[]
var _reading: Label

func configure(role: String,initial: float=50.0) -> bool:
 if is_inside_tree() or role not in ["approach","intensity"] or not is_finite(initial):return false
 _role=role;hydrate_level(initial);return true

func _ready() -> void:
 size_flags_horizontal=Control.SIZE_EXPAND_FILL;focus_mode=Control.FOCUS_ALL
 add_theme_constant_override("separation",4)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",4);add_child(row)
 if _role=="approach":
  for index in range(3):
   var button: Button=Poster.button(["TIGHT","CROWD","WILD"][index]);Poster.choice_style(button);button.toggle_mode=true
   button.pressed.connect(set_level.bind(float(index*50)));row.add_child(button);_choices.append(button)
 else:
  for direction in [-1,1]:
   var button: Button=Poster.button("−" if direction<0 else "+");Poster.choice_style(button)
   button.custom_minimum_size.x=48;button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
   button.pressed.connect(func():set_level(level+direction));row.add_child(button);_choices.append(button)
   if direction<0:
    _reading=Poster.label("",20,Poster.PAPER);_reading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;row.add_child(_reading)
 _refresh()

func get_role() -> String:return _role
func is_gesture_owned() -> bool:return false
func cancel_gesture() -> void:pass
func _normalise(value: float) -> float:
 return float(roundi(clampf(value,0,100)/50)*50) if _role=="approach" else float(roundi(clampf(value,0,100)))
func hydrate_level(value: float) -> void:
 if not is_finite(value):return
 level=_normalise(value);_refresh()
func set_level(value: float) -> void:
 if read_only or not is_finite(value):return
 var next: float=_normalise(value)
 if is_equal_approx(level,next):_refresh();return
 level=next;_refresh();level_changed.emit(level)
func set_read_only(value: bool) -> void:
 read_only=value;focus_mode=Control.FOCUS_NONE if value else Control.FOCUS_ALL;_refresh()
func _refresh() -> void:
 for index in range(_choices.size()):
  var button: Button=_choices[index];button.disabled=read_only;button.focus_mode=Control.FOCUS_NONE if read_only else Control.FOCUS_ALL
  if _role=="approach":
   var selected: bool=roundi(level)==index*50
   button.text=("✓ " if selected else "")+["TIGHT","CROWD","WILD"][index];button.set_pressed_no_signal(selected)
 if is_instance_valid(_reading):_reading.text=str(roundi(level))+" / 100"
func _gui_input(event: InputEvent) -> void:
 if read_only or not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode not in [KEY_LEFT,KEY_DOWN,KEY_RIGHT,KEY_UP,KEY_HOME,KEY_END]:return
 accept_event()
 var amount: float=50 if _role=="approach" else (10 if event.shift_pressed else 1)
 if event.keycode==KEY_HOME:set_level(0)
 elif event.keycode==KEY_END:set_level(100)
 else:set_level(level+(-amount if event.keycode in [KEY_LEFT,KEY_DOWN] else amount))
