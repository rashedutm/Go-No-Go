# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Counts how many problems a whole mission gets at 1x vs 4x time speed (should be about the same),
# and checks the Comms alert logic on Saturn (memory full but goal reachable -> no alarm).
extends Node

func _run(mid: String, speed: float, seed_v: int) -> int:
	var sim := MissionSim.new(Sim.make_test_design(mid))
	var ev := EventSystem.new()
	ev.setup(sim, seed_v, "normal")
	var count := [0]
	ev.event_started.connect(func(_e): count[0] += 1)
	var dps := sim.total_days / 180.0
	var dt := 1.0 / 30.0
	var guard := 0
	while not sim.finished and guard < 200000:
		guard += 1
		ev.update(dt, false, false, speed)
		if not ev.active.is_empty() and ev.time_left < float(ev.active.get("timer_s", 20)) - 2.0:
			ev.choose(0)   # answer after ~2 real seconds
		sim.tick(dt * dps * speed)
	return count[0]


func _ready() -> void:
	for mid in ["mars", "saturn"]:
		var a := 0
		var b := 0
		for s in 5:
			a += _run(mid, 1.0, 100 + s)
			b += _run(mid, 4.0, 100 + s)
		print("%s: avg problems per mission  1x = %.1f   4x = %.1f" % [mid, a / 5.0, b / 5.0])
	var mc = load("res://scenes/mission_control/mission_control.tscn").instantiate()
	MissionState.current_mission_id = "saturn"
	MissionState.design = Sim.make_test_design("saturn")
	add_child(mc)
	await get_tree().process_frame
	mc.sim.tick(20.0)
	mc._auto_alerts()
	print("saturn: memory %d%% full, sends %.1f vs goal needs %.1f Gb/day -> comms alarm: %s" % [
		mc.sim.storage_pct(), mc.sim.downlink_gb_day, mc._goal_rate_needed(), mc.consoles["comms"].alert])
	get_tree().quit()
