# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Opens the Design screen with a test design (for screenshots / quick checks).
# Run: godot --path . res://tests/design_preview.tscn -- mars engineer
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mid := args[0] if args.size() > 0 else "mars"
	MissionState.current_mission_id = mid
	MissionState.design = Sim.make_test_design(mid)
	if args.size() > 1:
		MissionState.set_meta("design_station", args[1])
	if args.size() > 2 and args[2] == "empty":
		MissionState.design = MissionState.empty_design(mid)
	add_child(load("res://scenes/design/design.tscn").instantiate())
