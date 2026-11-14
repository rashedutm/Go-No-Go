# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Headless check of the event system: flies each mission's test design for a full mission
# (about 3 real minutes, simulated) twice: ignoring every alarm, and always answering with choice 1.
# Run: godot --headless --path . res://tests/events_test.tscn
extends Node


func _fly(mid: String, policy: String, seed_value: int) -> Dictionary:
	var sim := MissionSim.new(Sim.make_test_design(mid))
	var ev := EventSystem.new()
	ev.setup(sim, seed_value)
	var dps := sim.total_days / 180.0
	var dt := 1.0 / 30.0
	var counter := [0]
	ev.event_started.connect(func(_e): counter[0] += 1)
	while not sim.finished:
		ev.update(dt, false, false)
		if policy == "first" and not ev.active.is_empty():
			if not ev.choose(0):
				ev.choose(1)
		sim.tick(dt * dps)
	ev.free()
	var s := Sim.score(sim.result())
	print("%-8s %-7s events %d  end %-10s  data %6d/%6d  health %3d  reserve $%3dM  bonus %2d  -> score %3d  stars %d" % [
		mid, policy, counter[0], sim.end_reason, sim.data_returned_gb, sim.mission["data_goal_gb"], sim.health,
		sim.reserve_musd, sim.science_bonus, s["total"], s["stars"]])
	return s


func _ready() -> void:
	print("events loaded: ", GameData.get_table("events").size())
	for mid in ["earth", "moon", "mars", "jupiter", "saturn"]:
		_fly(mid, "ignore", 11)
		_fly(mid, "first", 11)
	print("RESULT: events test finished")
	get_tree().quit()
