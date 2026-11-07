extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var width := 720
	var height := 1280
	var output := "/tmp/bandmaster-audio-review.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="):
			width = int(arg.trim_prefix("--width="))
		elif arg.begins_with("--height="):
			height = int(arg.trim_prefix("--height="))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	root.size = Vector2i(width, height)
	root.content_scale_size = Vector2i(width, height)
	var desk: Control = load("res://Scenes/AudioReview.tscn").instantiate()
	root.add_child(desk)
	for frame in range(15):
		await process_frame
	for child in desk.find_children("*", "Control", true, false):
		var control := child as Control
		if control is Button or control is HSlider:
			var rect := control.get_global_rect()
			if rect.position.x < 0 or rect.end.x > width + 1:
				push_error("Audio review control exceeds viewport width: " + str(control))
				quit(1)
				return
	var image := root.get_texture().get_image()
	var result := image.save_png(output)
	desk.free()
	await process_frame
	if result != OK:
		quit(1)
		return
	print("AUDIO REVIEW SCREENSHOT SAVED: " + output)
	quit()
