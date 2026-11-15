# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Prints data made vs data sent per day for each mission's example design, before/after renting antenna time.
extends Node

func _ready() -> void:
	for mid in ["earth", "moon", "mars", "jupiter", "saturn"]:
		var sim := MissionSim.new(Sim.make_test_design(mid))
		sim.tick(0.5)
		var goal := float(sim.mission.get("data_goal_gb", 0)) / sim.total_days
		var line := "%s: makes %.1f, sends %.1f Gb/day (goal needs %.1f)" % [mid, sim.data_rate_gb_day, sim.downlink_gb_day, goal]
		var n := 0
		while sim.can_buy_contact():
			sim.buy_contact_time(); n += 1
		sim.tick(0.5)
		line += " | after %d rentals sends %.1f" % [n, sim.downlink_gb_day]
		print(line)
	get_tree().quit()
