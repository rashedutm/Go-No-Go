# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Opens the launch scene (placeholder or Daniel's). Run: godot --path . res://tests/launch_preview.tscn
extends Node

func _ready() -> void:
	MissionState.current_mission_id = "mars"
	MissionState.design = Sim.make_test_design("mars")
	MissionState.go_to.call_deferred("launch_anim")
