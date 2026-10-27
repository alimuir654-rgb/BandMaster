extends SceneTree
## Optional local smoke test:
## godot --headless --path . --script res://bandmaster_premium_dashboard_poc/tests/lab08_smoke.gd

const ROOT := "res://bandmaster_premium_dashboard_poc/"

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var dial_script: Script = load(ROOT + "studio_control.gd") as Script
	var dashboard_scene: PackedScene = load(ROOT + "studio_dashboard.tscn") as PackedScene
	var bench_scene: PackedScene = load(ROOT + "studio_controls_lab.tscn") as PackedScene
	if dial_script == null or dashboard_scene == null or bench_scene == null:
		push_error("Lab08: required script or scene could not be loaded")
		quit(1)
		return
	var dial := Control.new()
	dial.set_script(dial_script)
	dial.set("control_kind", "horizontal")
	dial.set("level", 64.0)
	root.add_child(dial)
	dial.call("set_level", 85.0)
	if not is_equal_approx(float(dial.get("level")), 85.0):
		push_error("Lab08: dial value mutation failed")
		quit(1)
		return
	dial.call("set_level", 150.0)
	if not is_equal_approx(float(dial.get("level")), 100.0):
		push_error("Lab08: dial clamping failed")
		quit(1)
		return
	dial.queue_free()
	# Lab 08.2: both rings load all LED layers and remain value-addressable.
	for kind in ["focus", "buzz"]:
		var knob: Control = Control.new()
		knob.set_script(dial_script)
		knob.set("control_kind", kind)
		knob.set("level", 0.0)
		root.add_child(knob)
		var layers: Array = knob.get("ring_layers") as Array
		var expected: int = 27 if kind == "focus" else 23
		if layers.size() != expected:
			push_error("Lab 08.4: %s knob failed to load %s LED layers" % [kind, expected])
			quit(1)
			return
		knob.call("set_level", 100.0)
		if not is_equal_approx(float(knob.get("level")), 100.0):
			push_error("Lab 08.2: %s knob range failed" % kind)
			quit(1)
			return
		knob.queue_free()
	var dashboard: Node = dashboard_scene.instantiate()
	root.add_child(dashboard)
	await process_frame
	if not dashboard.has_method("_apply_scale"):
		push_error("Lab08: dashboard did not instantiate correctly")
		quit(1)
		return
	dashboard.queue_free()
	var bench: Node = bench_scene.instantiate()
	root.add_child(bench)
	await process_frame
	bench.queue_free()
	print("Lab08.4 smoke: PASS (resources, 27/23 individual LEDs, dial endpoints and scenes)")
	quit(0)
