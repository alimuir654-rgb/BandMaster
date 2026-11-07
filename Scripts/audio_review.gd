extends Control

const BG := Color("#101216")
const PANEL := Color("#1A1E24")
const AMBER := Color("#F0B44D")
const WHITE := Color("#F2F0E9")
const MUTED := Color("#AAB4C0")
const AUDIO_DIR := "res://Audio/Review/LastBusGone/"
const STEMS := ["Guitar", "Bass", "Drums", "Vocals"]
const DURATION := 19.3
const MASTER_DB := -6.0

var mix_player: AudioStreamPlayer
var reference_player: AudioStreamPlayer
var synchronized: AudioStreamSynchronized
var levels: Array[float] = [0.0, 0.0, 0.0, 0.0]
var muted: Array[bool] = [false, false, false, false]
var soloed: Array[bool] = [false, false, false, false]
var reference_mode := false
var available := false
var playback_position := 0.0
var transport_state := "stopped"
var play_button: Button
var compare_button: Button
var status_label: Label
var clock_label: Label
var scrubber: HSlider
var channel_grid: GridContainer
var level_sliders: Array[HSlider] = []
var level_labels: Array[Label] = []
var mute_buttons: Array[Button] = []
var solo_buttons: Array[Button] = []

static func assets_available() -> bool:
	for stem in ["guitar", "bass", "drums", "vocals", "reference"]:
		if not ResourceLoader.exists(AUDIO_DIR + stem + ".wav"):
			return false
	return true

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	available = assets_available()
	_create_players()
	_build_desk()
	get_viewport().size_changed.connect(_update_columns)
	_update_columns()
	_update_mix()
	_refresh_transport()

func _create_players() -> void:
	mix_player = AudioStreamPlayer.new()
	mix_player.name = "SynchronizedStems"
	mix_player.volume_db = MASTER_DB
	add_child(mix_player)
	reference_player = AudioStreamPlayer.new()
	reference_player.name = "SeparateReference"
	reference_player.volume_db = MASTER_DB
	add_child(reference_player)
	if not available:
		return
	synchronized = AudioStreamSynchronized.new()
	synchronized.stream_count = STEMS.size()
	for index in range(STEMS.size()):
		var stream := load(AUDIO_DIR + str(STEMS[index]).to_lower() + ".wav") as AudioStreamWAV
		synchronized.set_sync_stream(index, stream)
	mix_player.stream = synchronized
	reference_player.stream = load(AUDIO_DIR + "reference.wav") as AudioStreamWAV
	mix_player.finished.connect(_on_finished)
	reference_player.finished.connect(_on_finished)

func _build_desk() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 22)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	_label(column, "THE REVIEW ROOM", 14, AMBER)
	_label(column, "Last Bus Gone", 32, WHITE)
	_label(column, "Find the balance between four parts.", 16, WHITE)
	_label(column, "19.3-second excerpt  ·  1:10.700–1:30.000", 14, MUTED)
	var transport := HBoxContainer.new()
	transport.add_theme_constant_override("separation", 8)
	column.add_child(transport)
	play_button = _button(transport, "PLAY", toggle_play, true)
	play_button.name = "PlayPause"
	_button(transport, "STOP", stop_playback)
	_button(transport, "RESTART", restart_playback)
	clock_label = _label(column, "0:00.0 / 0:19.3", 14, MUTED)
	scrubber = HSlider.new()
	scrubber.max_value = DURATION
	scrubber.step = 0.01
	scrubber.custom_minimum_size.y = 40
	scrubber.value_changed.connect(seek_to)
	column.add_child(scrubber)
	status_label = _label(column, "", 15, AMBER)
	compare_button = _button(column, "HEAR REFERENCE", func() -> void: set_reference_mode(not reference_mode))
	compare_button.name = "CompareReference"
	_label(column, "Compare the reference with your own mix.", 13, MUTED)
	channel_grid = GridContainer.new()
	channel_grid.add_theme_constant_override("h_separation", 12)
	channel_grid.add_theme_constant_override("v_separation", 12)
	column.add_child(channel_grid)
	for index in range(STEMS.size()):
		_build_channel(index)
	var master := HBoxContainer.new()
	master.add_theme_constant_override("separation", 12)
	column.add_child(master)
	var master_title := _label(master, "MASTER", 14, AMBER)
	master_title.custom_minimum_size.x = 68
	var master_slider := HSlider.new()
	master_slider.min_value = -30
	master_slider.max_value = MASTER_DB
	master_slider.value = MASTER_DB
	master_slider.step = 0.5
	master_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master_slider.custom_minimum_size.y = 44
	master.add_child(master_slider)
	var master_label := _label(master, "−6.0 dB", 14, WHITE)
	master_label.custom_minimum_size.x = 76
	master_slider.value_changed.connect(func(db: float) -> void:
		mix_player.volume_db = db
		reference_player.volume_db = db
		master_label.text = "%.1f dB" % db
	)
	_button(column, "RESET MIX", reset_mix)
	_button(column, "BACK TO MENU", back_to_menu)
	_label(column, "Owner review  ·  AI-generated Suno audio", 13, MUTED)
	_label(column, "A mix preview, independent of your career. The song and your saves stay as they were.", 13, MUTED)
	if not available:
		for button in [play_button, compare_button]:
			button.disabled = true
		scrubber.editable = false
		status_label.text = "Review audio is not installed in this build."

func _build_channel(index: int) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	channel_grid.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	body.add_child(heading)
	var title := _label(heading, str(STEMS[index]).to_upper(), 15, AMBER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var readout := _label(heading, "0.0 dB", 13, WHITE)
	readout.custom_minimum_size.x = 48
	level_labels.append(readout)
	var slider := HSlider.new()
	slider.min_value = -48
	slider.max_value = 0
	slider.step = 0.5
	slider.value = 0
	slider.custom_minimum_size.y = 40
	slider.tooltip_text = "Level of the " + str(STEMS[index]).to_lower() + " part. Mute silences it completely."
	slider.value_changed.connect(func(db: float) -> void: set_level(index, db))
	body.add_child(slider)
	level_sliders.append(slider)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	body.add_child(actions)
	var mute := _button(actions, "MUTE", func() -> void: set_muted(index, not muted[index]))
	mute.toggle_mode = true
	mute.custom_minimum_size.y = 44
	mute.add_theme_font_size_override("font_size", 12)
	mute_buttons.append(mute)
	var solo := _button(actions, "SOLO", func() -> void: set_soloed(index, not soloed[index]))
	solo.toggle_mode = true
	solo.custom_minimum_size.y = 44
	solo.add_theme_font_size_override("font_size", 12)
	solo_buttons.append(solo)

func _update_columns() -> void:
	if is_instance_valid(channel_grid):
		var width := get_viewport_rect().size.x
		channel_grid.columns = 4 if width >= 1000 else (2 if width >= 360 else 1)

func set_level(index: int, db: float) -> void:
	levels[index] = clampf(db, -48.0, 0.0)
	_update_mix()

func set_muted(index: int, value: bool) -> void:
	muted[index] = value
	_update_mix()

func set_soloed(index: int, value: bool) -> void:
	soloed[index] = value
	_update_mix()

func _update_mix() -> void:
	var any_solo := soloed.has(true)
	for index in range(STEMS.size()):
		var audible := not muted[index] and (not any_solo or soloed[index])
		if synchronized != null:
			synchronized.set_sync_stream_volume(index, levels[index] if audible else -INF)
		if index < level_sliders.size():
			level_sliders[index].set_value_no_signal(levels[index])
			level_sliders[index].editable = available and not reference_mode
			level_labels[index].text = "%.1f dB" % levels[index] if audible else "SILENT"
			mute_buttons[index].set_pressed_no_signal(muted[index])
			solo_buttons[index].set_pressed_no_signal(soloed[index])
			mute_buttons[index].disabled = reference_mode or not available
			solo_buttons[index].disabled = reference_mode or not available

func reset_mix() -> void:
	for index in range(STEMS.size()):
		levels[index] = 0
		muted[index] = false
		soloed[index] = false
	_update_mix()

func _active_player() -> AudioStreamPlayer:
	return reference_player if reference_mode else mix_player

func toggle_play() -> void:
	if not available:
		return
	var player := _active_player()
	if transport_state == "playing":
		player.stream_paused = true
		transport_state = "paused"
	elif transport_state == "paused":
		player.stream_paused = false
		transport_state = "playing"
	else:
		if playback_position >= DURATION - 0.01:
			playback_position = 0
		player.stream_paused = false
		player.play(playback_position)
		transport_state = "playing"
	_refresh_transport()

func stop_playback() -> void:
	mix_player.stop()
	reference_player.stop()
	mix_player.stream_paused = false
	reference_player.stream_paused = false
	playback_position = 0
	transport_state = "stopped"
	_refresh_transport()

func restart_playback() -> void:
	stop_playback()
	if available:
		_active_player().play()
		transport_state = "playing"
	_refresh_transport()

func seek_to(seconds: float) -> void:
	playback_position = clampf(seconds, 0.0, DURATION)
	var player := _active_player()
	if transport_state != "stopped":
		player.seek(playback_position)
	_refresh_transport()

func set_reference_mode(value: bool) -> void:
	if not available or value == reference_mode:
		return
	var old := _active_player()
	var was_active := transport_state != "stopped"
	var was_paused := transport_state == "paused"
	if transport_state == "playing":
		playback_position = clampf(old.get_playback_position(), 0.0, DURATION)
	mix_player.stop()
	reference_player.stop()
	mix_player.stream_paused = false
	reference_player.stream_paused = false
	reference_mode = value
	if was_active:
		_active_player().play(playback_position)
		_active_player().stream_paused = was_paused
	_update_mix()
	_refresh_transport()

func _on_finished() -> void:
	playback_position = DURATION
	transport_state = "stopped"
	_refresh_transport()

func _process(_delta: float) -> void:
	var player := _active_player()
	if transport_state == "playing" and player.playing:
		playback_position = clampf(player.get_playback_position(), 0.0, DURATION)
	_refresh_transport()

func _refresh_transport() -> void:
	if not is_instance_valid(play_button):
		return
	play_button.text = "PAUSE" if transport_state == "playing" else "PLAY"
	compare_button.text = "BACK TO MY MIX" if reference_mode else "HEAR REFERENCE"
	if available:
		status_label.text = "FINISHED MIX  /  REFERENCE" if reference_mode else "YOUR FOUR-PART MIX"
	clock_label.text = "0:%04.1f / 0:19.3" % playback_position
	scrubber.set_value_no_signal(playback_position)

func back_to_menu() -> void:
	stop_playback()
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _exit_tree() -> void:
	if is_instance_valid(mix_player):
		mix_player.stop()
	if is_instance_valid(reference_player):
		reference_player.stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(mix_player):
		if transport_state == "playing":
			_active_player().stream_paused = true
			transport_state = "paused"
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(mix_player):
		back_to_menu()

func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = AMBER if primary else Color("#303B48")
		if state != "normal":
			style.bg_color = style.bg_color.lightened(0.1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(10)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, BG if primary else WHITE)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
