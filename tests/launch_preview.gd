# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Opens the launch scene. Run: godot --path . res://tests/launch_preview.tscn -- [mission_id] [crash|hit]
# "crash" forces 3 asteroid hits at 13 s (spacecraft lost); "hit" forces 1 hit and checks Mission Control health.
extends Node

var _mode := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mid := args[0] if args.size() > 0 else "mars"
	MissionState.current_mission_id = mid
	MissionState.design = Sim.make_test_design(mid)
	if args.size() < 2:
		MissionState.go_to.call_deferred("launch_anim")
		return
	_mode = args[1]
	_run.call_deferred()


func _run() -> void:
	# survive the scene change so we can poke the launch scene
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	get_tree().current_scene = null
	MissionState.go_to("launch_anim")
	await get_tree().create_timer(12.6).timeout
	var scene := get_tree().current_scene
	if _mode == "steer":
		for key in [KEY_W, KEY_D]:
			var ev := InputEventKey.new()
			ev.keycode = key
			ev.physical_keycode = key
			ev.pressed = true
			Input.parse_input_event(ev)
		var start: Vector3 = scene._ship.position
		await get_tree().create_timer(1.0).timeout
		print("steer W+D for 1 s: moved x=%.2f y=%.2f (up and right should both be > 2)" % [scene._ship.position.x - start.x, scene._ship.position.y - start.y])
		get_tree().quit()
		return
	for i in (3 if _mode == "crash" else 1):
		scene._handle_hit()
	print("lost=", scene._lost, " hits=", MissionState.get_meta("launch_hits", 0))
	if _mode == "hit":
		# keep the (unsteered) test ship out of further hits until Mission Control opens
		while get_tree().current_scene == scene or get_tree().current_scene == null:
			if is_instance_valid(scene):
				scene._clear_asteroids()
			await get_tree().process_frame
		await get_tree().process_frame
		var mc := get_tree().current_scene
		print("scene=", mc.name, " health=", mc.sim.health)
		for e in mc.sim.event_log:
			print("log: ", e["text"])
		get_tree().quit()
