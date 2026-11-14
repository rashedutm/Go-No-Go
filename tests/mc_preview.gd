# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Opens Mission Control and moves the player for screenshots.
# Run: godot --path . res://tests/mc_preview.tscn -- mars [front|console|panel]
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mid := args[0] if args.size() > 0 else "mars"
	MissionState.current_mission_id = mid
	MissionState.design = Sim.make_test_design(mid)
	var mc = load("res://scenes/mission_control/mission_control.tscn").instantiate()
	add_child(mc)
	var shot := args[1] if args.size() > 1 else "front"
	await get_tree().process_frame
	match shot:
		"console", "panel":
			mc.player.position = Vector3(-5.0, 0.1, -1.6)
			mc.player.cam.rotation.x = -0.25
			mc.set_console_alert("engineer", true)
			if shot == "panel":
				await get_tree().create_timer(0.3).timeout
				mc.open_console(args[2] if args.size() > 2 else "engineer")
		_:
			mc.player.position = Vector3(0, 0.1, 7.0)
