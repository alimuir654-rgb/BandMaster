extends Range
## Finite choices in the same native paper language as the rest of the poster.
## Range preserves silent hydration and the existing free-draft callback API.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
var field: String=""
var caption: String=""
var kind: String="choice"
var labels: Array=[]
var fixed_hint: String=""
var locked:=false
var _row: HBoxContainer
var _heading: Label
var _choices: Array[Button]=[]
var _built_labels: Array=[]

func configure(key: String,title: String,_kind: String,words: Array) -> void:
 field=key;caption=title;labels=words.duplicate();kind="choice"
 min_value=0;max_value=maxi(0,labels.size()-1);step=1
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 mouse_filter=Control.MOUSE_FILTER_PASS

func _ready() -> void:
 var column:=VBoxContainer.new();column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 column.add_theme_constant_override("separation",4);column.mouse_filter=Control.MOUSE_FILTER_PASS;add_child(column)
 _heading=Poster.label(caption,18,Poster.PAPER);column.add_child(_heading)
 _row=HBoxContainer.new();_row.add_theme_constant_override("separation",4);column.add_child(_row)
 custom_minimum_size.y=76
 focus_mode=Control.FOCUS_ALL
 value_changed.connect(func(_value: float):_update_caption())
 _update_caption()

func _pick(index: int) -> void:
 if not locked:value=index
 _update_caption()

func _update_caption() -> void:
 if not is_instance_valid(_row):return
 if _built_labels!=labels:
  for button in _choices:button.free()
  _choices.clear();_built_labels=labels.duplicate()
  for index in range(labels.size()):
   var button: Button=Poster.button("");Poster.choice_style(button)
   button.name="Choice_%s_%d" % [field,index];button.toggle_mode=true
   button.pressed.connect(_pick.bind(index));_row.add_child(button);_choices.append(button)
 for index in range(_choices.size()):
  var button: Button=_choices[index]
  var selected: bool=index==roundi(value)
  button.text=("✓ " if selected else "")+str(labels[index])
  button.set_pressed_no_signal(selected);button.disabled=locked
  button.focus_mode=Control.FOCUS_NONE if locked else Control.FOCUS_ALL
 _heading.text=caption
 # Immutable recorded playing is a fact, not a disabled interactive control.
 visible=fixed_hint.is_empty()

func set_locked(state: bool) -> void:
 locked=state;focus_mode=Control.FOCUS_NONE if locked else Control.FOCUS_ALL
 _update_caption()

func cancel_gesture() -> void:
 # Native buttons handle canceled releases and scroll gestures; no drag state.
 for button in _choices:button.set_pressed_no_signal(_choices.find(button)==roundi(value))

func _gui_input(event: InputEvent) -> void:
 if locked or not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode not in [KEY_LEFT,KEY_DOWN,KEY_RIGHT,KEY_UP,KEY_HOME,KEY_END]:return
 accept_event()
 if event.keycode==KEY_HOME:value=min_value
 elif event.keycode==KEY_END:value=max_value
 else:value+=-1 if event.keycode in [KEY_LEFT,KEY_DOWN] else 1
