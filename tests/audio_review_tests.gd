extends SceneTree

const Review = preload("res://Scripts/audio_review.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Run with isolated XDG_DATA_HOME; never point this fixture at a real profile.
	var sentinels := {
		"user://tour_save.json": '{"cash":247,"current_event":"aftershow","pending_next":"","unknown_future_key":"keep"}',
		"user://band_profile.json": '{"name":"Audio Review Save Sentinel"}',
		"user://player_profile.json": '{"display_name":"Review Tester"}'
	}
	var originals := {}
	for path in sentinels:
		originals[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(sentinels[path])
		file.close()
	var menu: Control = load("res://main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	_check(_has_button(menu, "CONTINUE CAREER"), "existing career stays reachable")
	_check(_has_button(menu, "START A NEW BAND"), "new band stays reachable")
	if not Review.assets_available():
		_check(not _has_button(menu, "LAST BUS GONE · REVIEW DESK"), "ordinary checkout does not show missing review assets")
		var missing: Control = load("res://Scenes/AudioReview.tscn").instantiate()
		root.add_child(missing)
		await process_frame
		_check(missing.play_button.disabled, "missing assets fail gracefully")
		missing.free()
	else:
		_check(_has_button(menu, "LAST BUS GONE · REVIEW DESK"), "local review is reachable from menu")
		menu._go_to("res://Scenes/AudioReview.tscn")
		await scene_changed
		var desk = current_scene
		_check(desk.available, "real review assets loaded")
		_check(not desk.mix_player.playing and not desk.reference_player.playing, "opening never autoplays")
		_check(desk.synchronized.stream_count == 4, "four parts use one synchronized stream")
		for index in range(4):
			var stream: AudioStreamWAV = desk.synchronized.get_sync_stream(index)
			_check(stream.stereo and stream.mix_rate == 48000, "stereo/rate preserved: " + str(index))
			_check(stream.data.size() == 926400 * 4, "exact PCM frame count preserved: " + str(index))
			_check(is_equal_approx(stream.get_length(), 19.3), "same duration: " + str(index))
		_check(is_equal_approx(desk.reference_player.stream.get_length(), 19.3), "reference uses identical crop length")
		var capture := AudioEffectCapture.new()
		capture.buffer_length = 0.5
		var capture_index := AudioServer.get_bus_effect_count(0)
		AudioServer.add_bus_effect(0, capture)
		desk.set_level(0, -12)
		_check(is_equal_approx(desk.synchronized.get_sync_stream_volume(0), -12), "fader changes actual stream volume")
		desk.set_level(1, 8)
		_check(desk.levels[1] == 0, "bus cannot boost beyond baseline")
		desk.set_soloed(0, true)
		_check(is_inf(desk.synchronized.get_sync_stream_volume(1)), "solo silences other buses completely")
		desk.set_soloed(1, true)
		_check(desk.synchronized.get_sync_stream_volume(1) == 0, "multiple solos form a subgroup")
		desk.set_muted(0, true)
		_check(is_inf(desk.synchronized.get_sync_stream_volume(0)), "mute wins over solo")
		desk.reset_mix()
		capture.clear_buffer()
		desk.toggle_play()
		await create_timer(0.2).timeout
		_check(desk.mix_player.playing and desk.playback_position > 0, "real transport advances through synchronized audio")
		capture.clear_buffer()
		await create_timer(0.12).timeout
		var signal_rms := _capture_rms(capture)
		print("Captured pre-mute RMS: ", signal_rms)
		_check(signal_rms > 0.001, "audio mixer produces a non-silent stem signal")
		for index in range(4):
			desk.set_muted(index, true)
		capture.clear_buffer()
		await create_timer(0.2).timeout
		var muted_rms := _capture_rms(capture)
		_check(muted_rms >= 0 and muted_rms < 0.00001, "muting all four buses silences actual mixed PCM")
		desk.reset_mix()
		capture.clear_buffer()
		await create_timer(0.1).timeout
		_check(_capture_rms(capture) > 0.001, "reset restores actual audible signal after mute")
		desk.toggle_play()
		_check(desk.mix_player.stream_paused, "pause keeps transport")
		desk.seek_to(5)
		desk.set_reference_mode(true)
		_check(not desk.mix_player.playing and desk.reference_mode, "paused reference never layers over stems")
		_check(desk.reference_player.stream_paused, "reference switch preserves paused state")
		_check(absf(desk.playback_position - 5) < 0.1, "comparison preserves excerpt position")
		_check(not desk.level_sliders[0].editable, "reference mode disables ineffective stem controls")
		desk.toggle_play()
		await create_timer(0.1).timeout
		_check(desk.reference_player.playing and not desk.mix_player.playing, "reference plays alone when resumed")
		desk.set_reference_mode(false)
		await create_timer(0.1).timeout
		_check(desk.mix_player.playing and not desk.reference_player.playing, "return restores exclusive stem playback")
		desk._notification(Control.NOTIFICATION_APPLICATION_PAUSED)
		_check(desk.mix_player.stream_paused, "backgrounding pauses audio")
		desk.toggle_play()
		desk.seek_to(19.2)
		await create_timer(0.35).timeout
		_check(not desk.mix_player.playing, "excerpt stops naturally without looping")
		_check(is_equal_approx(desk.playback_position, 19.3), "natural end retains final progress")
		desk.restart_playback()
		_check(desk.mix_player.playing, "restart works after natural completion")
		desk.stop_playback()
		_check(desk.playback_position == 0 and not desk.mix_player.playing, "stop resets transport")
		AudioServer.remove_bus_effect(0, capture_index)
		desk.back_to_menu()
		await scene_changed
		_check(current_scene.scene_file_path == "res://main_menu.tscn", "back returns to game menu")
	for path in sentinels:
		_check(FileAccess.get_file_as_string(path) == sentinels[path], "review preserved save bytes: " + path)
		if originals[path] == null:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_string(originals[path])
			file.close()
	if current_scene != null:
		current_scene.free()
		current_scene = null
	await create_timer(0.1).timeout
	if failures == 0:
		print("AUDIO REVIEW TESTS PASSED")
	quit(0 if failures == 0 else 1)

func _has_button(node: Node, text: String) -> bool:
	if node is Button and node.text == text:
		return true
	for child in node.get_children():
		if _has_button(child, text):
			return true
	return false

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("AUDIO REVIEW FAILURE: " + message)

func _capture_rms(capture: AudioEffectCapture) -> float:
	var buffer := capture.get_buffer(capture.get_frames_available())
	if buffer.is_empty():
		return -1.0
	var power := 0.0
	var count := mini(buffer.size(), 1024)
	for index in range(buffer.size() - count, buffer.size()):
		power += buffer[index].length_squared()
	return sqrt(power / (count * 2.0))
