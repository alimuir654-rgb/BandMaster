extends SceneTree
## S02b: image-backed individually designed family; no default button styles.
const Scene = preload("res://poc/ldtd_formation_rehearsal.tscn")
const Craft = preload("res://Scripts/formation_craft_skin.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	get_root().size = Vector2i(390, 844)
	DisplayServer.window_set_size(Vector2i(390, 844))
	if not Craft.validate_source():
		_fail("Missing any of 22 approved-material generation outputs")
		return
	var v: Control = Scene.instantiate()
	get_root().add_child(v)
	for i in range(8):
		await process_frame
	var desk: TextureRect = v.find_child("FormationSunlitDesk", true, false)
	var sheet: TextureRect = v.find_child("FormationNotebookMaterial", true, false)
	if desk == null or sheet == null or desk.texture == null or sheet.texture == null:
		_fail("missing tactile paper/desk world materials")
		return
	if desk.texture.get_width() != 1600 or sheet.texture.get_height() != 1440:
		_fail("non-original or unacceptably tiny material assets")
		return
	var jo: Button = v.find_child("ChoiceJo", true, false)
	var rae: Button = v.find_child("ChoiceRae", true, false)
	var gallery: Button = v.find_child("ReturnToGallery", true, false)
	var primary: Button = v.find_child("FormationPrimaryAction", true, false)
	for b in [jo, rae, gallery, primary]:
		if b == null or not (b.get_theme_stylebox("normal") is StyleBoxTexture):
			_fail("standard-style button forbidden in S02B")
			return
		if b.focus_mode != Control.FOCUS_ALL or b.size.y < 44:
			_fail("craft button loses accessible native interaction")
			return
		for state in ["normal","hover","pressed","disabled"]:
			if not (b.get_theme_stylebox(state) is StyleBoxTexture):
				_fail("missing original tactile texture for "+b.name+" state "+state)
				return
	var candidate_style: StyleBoxTexture = jo.get_theme_stylebox("normal") as StyleBoxTexture
	var primary_style: StyleBoxTexture = primary.get_theme_stylebox("normal") as StyleBoxTexture
	var tab_style: StyleBoxTexture = gallery.get_theme_stylebox("normal") as StyleBoxTexture
	if candidate_style.texture.resource_path == primary_style.texture.resource_path or tab_style.texture.resource_path == primary_style.texture.resource_path:
		_fail("all controls share a generic design rather than purpose-specific families")
		return
	var stat: Label = v.find_child("ReadOnlyStats", true, false)
	if stat == null or stat.focus_mode != Control.FOCUS_NONE or stat.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("read-only stats are interactive")
		return
	var base: String = JSON.stringify(v.preview_state)
	v.choose_drummer("rae")
	v.choose_bassist("dev")
	if JSON.stringify(v.preview_state) != base:
		_fail("card choices prematurely mutate game economy")
		return
	v.commit_stage()
	v.choose_outing("dinner")
	v.commit_stage()
	v.choose_room_focus("tighten")
	v.commit_stage()
	if v.stage != "summary" or v.settlement_count != 2:
		_fail("bespoke materials broke the once-only gameplay")
		return
	var immutable: String = JSON.stringify(v.preview_state)
	v.commit_stage()
	if JSON.stringify(v.preview_state) != immutable:
		_fail("summary can charge twice")
		return
	for i in range(8):
		await process_frame
	primary = v.find_child("FormationPrimaryAction", true, false)
	if not primary.disabled or not (primary.get_theme_stylebox("disabled") is StyleBoxTexture):
		_fail("completed decision missing physical disabled state")
		return
	print("LDTD S02B PREMIUM STATIONERY CONTROLS AND INPUT/STAT CONTRACT PASSED")
	v.queue_free()
	quit(0)
func _fail(why: String) -> void:
	push_error("LDTD S02B FAILURE: " + why)
	quit(1)
