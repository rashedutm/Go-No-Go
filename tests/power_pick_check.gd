# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Power tiles: click selects (replacing others), click again deselects, -/+ change the count.
extends Node

func _ready() -> void:
	MissionState.current_mission_id = "jupiter"
	MissionState.design = MissionState.empty_design("jupiter")
	var sec := {}
	for s in PartInfo.SECTIONS["engineer"]:
		if s["key"] == "power":
			sec = s
	var log := []
	PartInfo.click(sec, "solar_s");  log.append("click small    -> %s" % [MissionState.design["power"]])
	PartInfo.click(sec, "solar_xl"); log.append("click giant    -> %s" % [MissionState.design["power"]])
	PartInfo.add_one(sec, "solar_xl"); log.append("plus           -> %s" % [MissionState.design["power"]])
	PartInfo.remove_one(sec, "solar_xl"); log.append("minus          -> %s" % [MissionState.design["power"]])
	PartInfo.click(sec, "solar_xl"); log.append("click giant    -> %s (deselected)" % [MissionState.design["power"]])
	for l in log:
		print(l)
	get_tree().quit()
