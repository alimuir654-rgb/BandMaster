extends RefCounted
## Precision-fader input/state model. NO placeholder art or save mutations.
## Image-backed renderer must be supplied separately once approved source is imported.
signal value_changed(normalized_value: float)
signal state_changed()

const SMALL_STEP := 0.02
const LARGE_STEP := 0.10
var value := 0.0
var enabled := true
var hovered := false
var focused := false
var pressed := false
var selected := false

func set_value(next_value: float) -> void:
	if not enabled:
		return
	var bounded := clampf(next_value, 0.0, 1.0)
	if is_equal_approx(bounded, value):
		return
	value = bounded
	value_changed.emit(value)

func set_enabled(next_enabled: bool) -> void:
	if enabled == next_enabled:
		return
	enabled = next_enabled
	if not enabled:
		pressed = false
		hovered = false
		focused = false
	state_changed.emit()

func set_hovered(next_hovered: bool) -> void:
	var next := next_hovered and enabled
	if hovered != next:
		hovered = next
		state_changed.emit()

func set_focused(next_focused: bool) -> void:
	var next := next_focused and enabled
	if focused != next:
		focused = next
		state_changed.emit()

func set_selected(next_selected: bool) -> void:
	if not enabled:
		return
	if selected != next_selected:
		selected = next_selected
		state_changed.emit()

func begin_drag() -> bool:
	if not enabled:
		return false
	pressed = true
	state_changed.emit()
	return true

func drag_to_pointer(pointer_y: float, track_top: float, track_bottom: float) -> void:
	if not enabled or not pressed or track_bottom <= track_top:
		return
	# Vertical fader: physical TOP is 100%, physical BOTTOM is 0%.
	set_value(1.0 - (pointer_y - track_top) / (track_bottom - track_top))

func end_drag() -> void:
	if pressed:
		pressed = false
		state_changed.emit()

func keyboard_step(direction: int, large: bool = false) -> void:
	if not enabled or direction == 0:
		return
	var step := LARGE_STEP if large else SMALL_STEP
	set_value(value + step * signi(direction))

func cap_ratio_from_value() -> float:
	# Position ratio from top: full up -> 0, fully down -> 1.
	return 1.0 - value

func illuminated_ratio() -> float:
	# Zero value means ZERO emitted LED pixels, regardless of theme.
	return value if enabled else 0.0

func visual_state() -> String:
	if not enabled:
		return "disabled"
	if pressed:
		return "pressed"
	if selected:
		return "selected"
	if focused:
		return "focused"
	if hovered:
		return "hover"
	return "normal"
