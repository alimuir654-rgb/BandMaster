extends VBoxContainer

const Bank = preload("res://Scripts/song_phrase_bank.gd")
const UI = preload("res://Scripts/ui_theme.gd")
var genre_id := "indie"
var state: Dictionary = {}
var initial_mix: Dictionary = {}
var read_only := false
var source_id := Bank.LEGACY
var family_selector: OptionButton
var enabled: CheckButton
var player: AudioStreamPlayer
var sync: AudioStreamSynchronized
var selectors := {}
var sliders := {}
var breaks := {}
var solos := {}
var status: Label
var play_button: Button

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	player = AudioStreamPlayer.new()
	player.volume_db = -9
	add_child(player)
	player.finished.connect(func() -> void: play_button.text = "PLAY PHRASE")
	enabled = CheckButton.new()
	enabled.text = "USE THESE PARTS IN MY SONG"
	enabled.add_theme_font_size_override("font_size", 14)
	enabled.button_pressed = not initial_mix.is_empty()
	enabled.disabled = read_only
	add_child(enabled)
	family_selector = OptionButton.new()
	family_selector.name = "SongAudioFamily"
	family_selector.custom_minimum_size.y = 48
	family_selector.clip_text = true
	family_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(family_selector)
	var saved_source := str(initial_mix.get("source", ""))
	for key in Bank.SOURCES:
		if Bank.available(str(key)) or str(key) == saved_source:
			family_selector.add_item(str(Bank.SOURCES[key]["label"]))
			family_selector.set_item_metadata(family_selector.item_count - 1, str(key))
			if str(key) == saved_source:
				family_selector.select(family_selector.item_count - 1)
	if not saved_source.is_empty() and not Bank.SOURCES.has(saved_source):
		family_selector.add_item("ARCHIVED FAMILY UNAVAILABLE")
		family_selector.set_item_metadata(family_selector.item_count - 1, saved_source)
		family_selector.select(family_selector.item_count - 1)
	if family_selector.item_count > 0:
		source_id = str(family_selector.get_selected_metadata())
	family_selector.disabled = read_only
	family_selector.item_selected.connect(_change_family)
	var info := Label.new()
	info.text = "Choose a passage family to keep the band parts together. Preview is free; commit uses the chosen phrases. Breakdown drops a part in the second half; Solo isolates selected parts."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	for role in Bank.ROLES:
		var heading := Label.new()
		var member_index := Bank.participant(state, role)
		var contributor := str(initial_mix.get("parts", {}).get(role, {}).get("contributor", "")) if read_only else (str(state["members"][member_index].get("name", "")) if member_index >= 0 else "NO PLAYER")
		heading.text = role.to_upper() + "  /  " + contributor
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.add_theme_color_override("font_color", UI.palette(genre_id)["accent"])
		add_child(heading)
		var saved: Dictionary = initial_mix.get("parts", {}).get(role, {})
		var select := OptionButton.new()
		select.custom_minimum_size.y = 48
		add_child(select)
		selectors[role] = select
		select.item_selected.connect(func(_i: int) -> void: _reload())
		var slider := HSlider.new()
		slider.min_value = -48
		slider.max_value = 0
		slider.step = 0.5
		slider.value = float(saved.get("level_db", 0))
		slider.editable = not read_only
		slider.custom_minimum_size.y = 44
		add_child(slider)
		sliders[role] = slider
		var row := HBoxContainer.new()
		add_child(row)
		var breakdown := CheckBox.new()
		breakdown.text = "BREAKDOWN"
		breakdown.button_pressed = bool(saved.get("breakdown", false))
		breakdown.disabled = read_only
		row.add_child(breakdown)
		breaks[role] = breakdown
		var solo := CheckBox.new()
		solo.text = "SOLO"
		solo.button_pressed = bool(saved.get("solo", false))
		solo.disabled = read_only
		row.add_child(solo)
		solos[role] = solo
	play_button = UI.themed_button("PLAY PHRASE", genre_id, true)
	play_button.custom_minimum_size.y = 52
	add_child(play_button)
	play_button.pressed.connect(func() -> void:
		if player.playing:
			player.stop()
			play_button.text = "PLAY PHRASE"
		else:
			_apply_levels(0)
			player.play()
			play_button.text = "STOP"
	)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	_populate_choices()
	_reload()

func _change_family(_index: int) -> void:
	source_id = str(family_selector.get_selected_metadata())
	_populate_choices()
	_reload()

func _populate_choices() -> void:
	for role in Bank.ROLES:
		var select: OptionButton = selectors[role]
		select.clear()
		var options: Array = Bank.choices(state, role, source_id)
		var saved: Dictionary = initial_mix.get("parts", {}).get(role, {}) if str(initial_mix.get("source", Bank.LEGACY)) == source_id else {}
		if read_only:
			options = [int(saved.get("phrase", 0))]
		for phrase in options:
			select.add_item("MATCHED PART" if source_id != Bank.LEGACY else "PHRASE %d" % (int(phrase) + 1), int(phrase))
			if int(saved.get("phrase", -1)) == int(phrase):
				select.select(select.item_count - 1)
		select.disabled = read_only or options.size() <= 1

func selection() -> Dictionary:
	if not enabled.button_pressed:
		return {}
	var parts := {}
	for role in Bank.ROLES:
		var select: OptionButton = selectors[role]
		parts[role] = {"phrase":select.get_selected_id(), "level_db":sliders[role].value, "breakdown":breaks[role].button_pressed, "solo":solos[role].button_pressed}
	return {"source":source_id, "parts":parts}

func _reload() -> void:
	player.stop()
	play_button.text = "PLAY PHRASE"
	sync = AudioStreamSynchronized.new()
	sync.stream_count = 3
	var valid := true
	for index in range(3):
		var role: String = Bank.ROLES[index]
		var select: OptionButton = selectors[role]
		var path := Bank.asset(role, select.get_selected_id(), source_id)
		if select.selected < 0 or not ResourceLoader.exists(path):
			valid = false
		else:
			sync.set_sync_stream(index, load(path))
	player.stream = sync
	play_button.disabled = not valid
	status.text = "%.2f-second passage · %s" % [Bank.duration(source_id), str(Bank.SOURCES.get(source_id, {}).get("label", source_id))] if valid else "No unused phrases remain for one of these instruments. Existing songs keep their audio."
	if not read_only:
		for role in Bank.ROLES:
			if Bank.participant(state, role) < 0:
				status.text = "Add active guitar, bass and drum players to build with all three parts. You can still write without audio."

func _apply_levels(seconds: float) -> void:
	var any_solo := false
	for role in Bank.ROLES:
		any_solo = any_solo or solos[role].button_pressed
	for index in range(3):
		var role: String = Bank.ROLES[index]
		var silent: bool = (any_solo and not solos[role].button_pressed) or (seconds >= Bank.duration(source_id) / 2 and breaks[role].button_pressed)
		sync.set_sync_stream_volume(index, -INF if silent else float(sliders[role].value))

func _process(_delta: float) -> void:
	if player != null and player.playing:
		_apply_levels(player.get_playback_position())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(player):
		player.stop()
		play_button.text = "PLAY PHRASE"

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
