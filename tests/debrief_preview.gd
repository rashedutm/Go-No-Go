# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Flies a quick simulated mission and opens the debrief. Run: godot --path . res://tests/debrief_preview.tscn -- jupiter
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mid := args[0] if args.size() > 0 else "jupiter"
	MissionState.current_mission_id = mid
	MissionState.design = Sim.make_test_design(mid)
	var sim := MissionSim.new(MissionState.design)
	var ev := EventSystem.new()
	ev.setup(sim, 7)
	while not sim.finished:
		ev.update(1.0 / 30.0, false, false)
		if not ev.active.is_empty():
			ev.choose(0)
		sim.tick(sim.total_days / 180.0 / 30.0)
	ev.free()
	MissionState.last_result = sim.result()
	MissionState.go_to.call_deferred("debrief")
