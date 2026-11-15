# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Hangar on the Power tab with 2 giant solar wings selected (screenshot check for the - / + buttons).
extends Node

func _ready() -> void:
	MissionState.current_mission_id = "jupiter"
	MissionState.design = Sim.make_test_design("jupiter")
	MissionState.set_meta("design_station", "engineer")
	var h = load("res://scenes/hangar/hangar.tscn").instantiate()
	add_child(h)
	await get_tree().process_frame
	h.section_idx = 1
	h._refresh()
