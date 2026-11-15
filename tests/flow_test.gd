# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# End-to-end flow test: walks through every screen of the real game in order, the way a player
# would (title -> campaign -> briefing -> hangar -> poll -> launch -> mission control -> debrief),
# fast-forwards the mission, and reports which screen was reached at each step.
# Run: godot --headless --path . res://tests/flow_test.tscn   (or without --headless to watch)
extends Node

var _log: Array = []


func _ready() -> void:
	# reparent this test node to the root so it survives the scene changes it triggers
	(func():
		var root := get_tree().root
		get_parent().remove_child(self)
		root.add_child(self)
		get_tree().current_scene = null
		_run()).call_deferred()


func _scene() -> String:
	var s := get_tree().current_scene
	return s.scene_file_path.get_file() if s else "(none)"


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _step(label: String, screen: String, expect: String, sec: float) -> void:
	if screen != "":
		MissionState.go_to(screen)
	await _wait(sec)
	var got := _scene()
	var ok := got == expect
	_log.append("%-22s -> %-32s %s" % [label, got, "OK" if ok else "EXPECTED " + expect])


func _run() -> void:
	MissionState.reset_progress()
	MissionState.current_mission_id = "mars"
	MissionState.campaign["unlocked"] = ["earth", "moon", "mars"]
	MissionState.set_difficulty("normal")
	await _step("title", "title", "title.tscn", 1.0)
	await _step("campaign map", "campaign_map", "campaign_map.tscn", 1.0)
	MissionState.start_mission("mars")
	await _step("briefing", "briefing", "briefing.tscn", 1.0)
	await _step("hangar", "hangar", "hangar.tscn", 1.5)
	MissionState.design = Sim.make_test_design("mars")
	MissionState.design_changed.emit()
	await _step("go/no-go poll", "launch_check", "launch_check.tscn", 8.0)
	var go := Sim.is_go(MissionState.design)
	_log.append("%-22s -> %s" % ["poll result", "GO" if go else "NO-GO"])
	await _step("launch (Danial)", "launch_anim", "launch_anim.tscn", 2.0)
	# let the real launch run to its end (it hands over to Mission Control by itself)
	var t := 0.0
	while _scene() != "mission_control.tscn" and t < 40.0:
		# the test can't steer, so fly like a careful pilot: no asteroids reach the ship
		var cs := get_tree().current_scene
		if cs and cs.has_method("_clear_asteroids"):
			cs._clear_asteroids()
		await _wait(0.1)
		t += 0.1
	_log.append("%-22s -> %-32s %s" % ["launch auto-continues", _scene(), "OK (%d s)" % int(t) if _scene() == "mission_control.tscn" else "STUCK"])
	if _scene() != "mission_control.tscn":
		MissionState.go_to("mission_control")
		await _wait(1.5)
	var mc = get_tree().current_scene
	_log.append("%-22s -> difficulty %s, %d repair tools on POWER, wall view: %s" % ["mission control", mc.difficulty,
		mc.events.tools_for("engineer").size(), mc.wall_view.get_class() + (" (Danial's space_view)" if mc.wall_view.scene_file_path != "" else " (placeholder)")])
	mc.events.start_by_id("solar_storm")
	mc.open_console("engineer")
	await _wait(0.3)
	mc.sim.set_safe_mode(true)
	var fixed: String = mc.events.try_fix("safe_mode")
	mc.close_console()
	_log.append("%-22s -> %s" % ["fix solar storm", fixed])
	mc.days_per_second = 400.0   # fast-forward the rest of the mission
	t = 0.0
	while _scene() != "debrief.tscn" and t < 40.0:
		await _wait(1.0)
		t += 1.0
	_log.append("%-22s -> %-32s %s" % ["mission end -> debrief", _scene(), "OK" if _scene() == "debrief.tscn" else "STUCK"])
	var r := MissionState.last_result
	var s := Sim.score(r)
	_log.append("%-22s -> end %s, data %d/%d Gb, score %d, stars %d" % ["result", r.get("end_reason", "?"),
		r.get("data_returned_gb", 0), r.get("data_goal_gb", 0), s["total"], s["stars"]])
	await _wait(2.0)
	_log.append("%-22s -> stars saved for mars: %s" % ["campaign progress", str(MissionState.campaign["stars"].get("mars", 0))])
	print("\n".join(_log))
	var bad := _log.filter(func(l): return "EXPECTED" in l or "STUCK" in l).size()
	print("RESULT: ", "FULL FLOW OK" if bad == 0 else "%d PROBLEMS" % bad)
	get_tree().quit()
