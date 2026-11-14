# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Headless check: every built-in test design must pass the launch check.
# Run: godot --headless --path . res://tests/sim_test.tscn
extends Node

func _ready() -> void:
	var failures := 0
	for m in GameData.get_missions_in_order():
		var d := Sim.make_test_design(m["id"])
		var s := Sim.summarize(d)
		print("%-8s cost %4d/%4d  wet %5d/%5d kg  power %5d/%4d W  batt %4d/%4d Wh  data %6d/%6d Gb  slots %d/%d" % [
			m["id"], s["total_cost_musd"], s["budget_musd"], s["wet_mass_kg"], s["launcher_capacity_kg"],
			s["power_gen_w"], s["power_load_w"], s["battery_wh"], s["eclipse_need_wh"],
			s["est_total_data_gb"], s["data_goal_gb"], s["slots_used"], s["slots_max"]])
		for c in Sim.launch_check(d):
			if not c["passed"]:
				failures += 1
				print("   NO-GO ", c["id"], ": ", c["message"])
		var r := {"data_returned_gb": s["est_total_data_gb"], "data_goal_gb": s["data_goal_gb"], "science_bonus": 0,
			"lifetime_years": d["target_years"], "target_years": d["target_years"],
			"reserve_left_musd": s["reserve_musd"], "budget_musd": s["budget_musd"]}
		print("   score ", Sim.score(r), "  lookalike ", Sim.find_lookalike(d).get("name", "-"))
	var empty := MissionState.empty_design("earth")
	print("empty design checks failing: ", Sim.launch_check(empty).filter(func(c): return not c["passed"]).size())
	print("RESULT: ", "ALL TEST DESIGNS GO" if failures == 0 else "%d FAILURES" % failures)
	get_tree().quit(0 if failures == 0 else 1)
