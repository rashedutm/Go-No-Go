# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Opens a menu screen with fake progress. Run: godot --path . res://tests/menu_preview.tscn -- campaign_map jupiter
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var screen := args[0] if args.size() > 0 else "title"
	MissionState.current_mission_id = args[1] if args.size() > 1 else "mars"
	MissionState.campaign = {"unlocked": ["earth", "moon", "mars"], "stars": {"earth": 3, "moon": 2}, "best_score": {"earth": 91, "moon": 74}}
	add_child(load("res://scenes/%s/%s.tscn" % [screen, screen]).instantiate())
