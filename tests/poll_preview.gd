# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Opens the Go/No-Go poll. Run: godot --path . res://tests/poll_preview.tscn -- mars [broken]
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mid := args[0] if args.size() > 0 else "mars"
	MissionState.current_mission_id = mid
	MissionState.design = Sim.make_test_design(mid)
	if args.size() > 1 and args[1] == "broken":
		MissionState.design["battery"] = "batt_s"
		MissionState.design["instruments"] = ["cam_hires", "ir_spec", "radar"]
	add_child(load("res://scenes/launch_check/launch_check.tscn").instantiate())
