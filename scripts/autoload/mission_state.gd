# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# MissionState (autoload): current mission, the player's design, last result, campaign progress.
# Contract: README §8.1. Owner: Member A.
extends Node

signal design_changed

const SAVE_PATH := "user://save.cfg"

## Screen keys -> scene paths. Member B's screens fall back to placeholders until they exist.
const SCREENS := {
	"title": "res://scenes/title/title.tscn",
	"campaign_map": "res://scenes/campaign_map/campaign_map.tscn",
	"briefing": "res://scenes/briefing/briefing.tscn",
	"design": "res://scenes/design/design.tscn",
	"hangar": "res://scenes/hangar/hangar.tscn",   # v2 3D design; falls back to 2D design
	"launch_check": "res://scenes/launch_check/launch_check.tscn",
	"launch_anim": "res://scenes/launch_anim/launch_anim.tscn",
	"mission_control": "res://scenes/mission_control/mission_control.tscn",
	"debrief": "res://scenes/debrief/debrief.tscn",
}
const PLACEHOLDERS := {
	"mission_control": "res://scenes/placeholders/mission_control_placeholder.tscn",
	"debrief": "res://scenes/placeholders/debrief_placeholder.tscn",
	"launch_anim": "res://scenes/placeholders/launch_placeholder.tscn",
	"hangar": "res://scenes/design/design.tscn",
}

var current_mission_id: String = "earth"
var design: Dictionary = {}        # format: README §8.1
var last_result: Dictionary = {}   # format: README §8.1
var campaign: Dictionary = {"unlocked": ["earth"], "stars": {}, "best_score": {}}


func _ready() -> void:
	load_progress()


## Change screen by key (helper, not part of the fixed contract).
func go_to(screen_key: String) -> void:
	var path: String = SCREENS.get(screen_key, "")
	if (path == "" or not ResourceLoader.exists(path)) and PLACEHOLDERS.has(screen_key):
		path = PLACEHOLDERS[screen_key]
	if path == "" or not ResourceLoader.exists(path):
		push_error("MissionState.go_to: unknown screen '%s'" % screen_key)
		return
	get_tree().change_scene_to_file(path)


## Start (or restart) designing a mission. Keeps the old design if it is for the same mission.
func start_mission(mission_id: String) -> void:
	current_mission_id = mission_id
	if design.get("mission_id", "") != mission_id:
		design = empty_design(mission_id)
	design_changed.emit()


func empty_design(mission_id: String) -> Dictionary:
	var m := GameData.get_mission(mission_id)
	return {
		"mission_id": mission_id,
		"launch_vehicle": "",
		"bus": "",
		"power": [],
		"battery": "",
		"shielding": "shield_none",
		"instruments": [],
		"antenna": "",
		"storage": "",
		"network": "",
		"target_years": float(m.get("min_years", 1)),
	}


## Set one field of the design and notify listeners (helper for the Design screen).
func set_design_value(key: String, value) -> void:
	design[key] = value
	design_changed.emit()


func is_unlocked(mission_id: String) -> bool:
	return mission_id in campaign["unlocked"]


func record_result(mission_id: String, stars: int, score: int) -> void:
	campaign["stars"][mission_id] = max(int(campaign["stars"].get(mission_id, 0)), stars)
	campaign["best_score"][mission_id] = max(int(campaign["best_score"].get(mission_id, 0)), score)
	if stars >= 1:
		var order := GameData.get_missions_in_order()
		for i in order.size():
			if order[i]["id"] == mission_id and i + 1 < order.size():
				var next_id: String = order[i + 1]["id"]
				if not next_id in campaign["unlocked"]:
					campaign["unlocked"].append(next_id)
	save_progress()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("campaign", "data", campaign)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var data = cfg.get_value("campaign", "data", null)
		if typeof(data) == TYPE_DICTIONARY and data.has("unlocked"):
			campaign = data


func reset_progress() -> void:
	campaign = {"unlocked": ["earth"], "stars": {}, "best_score": {}}
	save_progress()


## "easy" | "normal" | "hard". Chosen on the briefing screen; default = easy on the first
## mission (Fire Watch), normal afterwards.
func difficulty() -> String:
	if has_meta("difficulty"):
		return str(get_meta("difficulty"))
	return "easy" if current_mission_id == "earth" else "normal"


func set_difficulty(level: String) -> void:
	set_meta("difficulty", level)
