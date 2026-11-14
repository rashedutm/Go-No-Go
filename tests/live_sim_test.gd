# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Headless check of MissionSim: flies every mission's test design (no events, no player actions)
# plus a few broken designs, and prints the outcome and score.
# Run: godot --headless --path . res://tests/live_sim_test.tscn
extends Node


func _fly(label: String, d: Dictionary) -> Dictionary:
	var sim := MissionSim.new(d)
	var steps := 0
	while not sim.finished and steps < 100000:
		sim.tick(0.5)
		steps += 1
	var r := sim.result()
	var s := Sim.score(r)
	print("%-22s %-10s day %4d/%4d  data %7d/%6d Gb  lost %6d  health %3d  batt %3d%%  -> score %3d  stars %d" % [
		label, sim.end_reason, int(sim.day), int(sim.total_days), sim.data_returned_gb, r["data_goal_gb"],
		sim.data_lost_gb, sim.health, sim.battery_pct(), s["total"], s["stars"]])
	for e in sim.event_log:
		if e["cause"] != "":
			print("      day %d: %s" % [e["day"], e["text"]])
	return s


func _ready() -> void:
	var bad := 0
	for m in GameData.get_missions_in_order():
		var s := _fly(m["id"] + " (test design)", Sim.make_test_design(m["id"]))
		if s["stars"] < 2:
			bad += 1
	# broken designs should do badly
	var d := Sim.make_test_design("jupiter")
	d["shielding"] = "shield_none"
	_fly("jupiter no shield", d)
	d = Sim.make_test_design("earth")
	d["battery"] = "batt_s"
	d["instruments"] = ["cam_wide", "cam_hires"]
	_fly("earth tiny battery", d)
	d = Sim.make_test_design("mars")
	d["power"] = ["solar_s"]
	_fly("mars weak solar", d)
	d = Sim.make_test_design("mars")
	d["antenna"] = "mga"
	_fly("mars small antenna", d)
	print("RESULT: ", "ALL TEST DESIGNS >= 2 STARS" if bad == 0 else "%d test designs under 2 stars" % bad)
	get_tree().quit()
