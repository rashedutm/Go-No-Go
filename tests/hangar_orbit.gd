# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Renders the hangar from 4 sides at max zoom-out to check nothing blocks the spacecraft.
# Run: godot --path . --write-movie out.png --fixed-fps 10 --quit-after 40 res://tests/hangar_orbit.tscn
extends Node

func _ready() -> void:
	MissionState.current_mission_id = "earth"
	MissionState.design = Sim.make_test_design("earth")
	var h = load("res://scenes/hangar/hangar.tscn").instantiate()
	add_child(h)
	for i in 4:
		await get_tree().create_timer(1.0).timeout
		h._goal = {}
		h._yaw = i * PI / 2 + 0.3
		h._pitch = 0.15
		h._dist = h.MAX_DIST
		h._target = h.MODEL_POS
		h._idle = 0.0
