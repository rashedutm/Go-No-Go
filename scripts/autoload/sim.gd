# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Sim (autoload): pure mission-design math. No scene access, no state.
# Contract: README §8.1. Formulas: README §6. Owner: Member A.
extends Node

const G0 := 9.81          # m/s², standard gravity
const ISP := 320.0        # s, typical chemical thruster
const DAYS_PER_YEAR := 365.0


# ---------------------------------------------------------------- helpers

func _n(d: Dictionary, key: String) -> float:
	return float(d.get(key, 0.0))


func _part(table: String, id) -> Dictionary:
	if id == null or str(id) == "":
		return {}
	return GameData.get_item(table, str(id))


## Every chosen part as {table, item}. Used for cost/mass/power totals.
func _parts(design: Dictionary) -> Array:
	var parts: Array = []
	parts.append(_part("buses", design.get("bus", "")))
	for p in design.get("power", []):
		parts.append(_part("power", p))
	parts.append(_part("power", design.get("battery", "")))
	parts.append(_part("power", design.get("shielding", "")))
	for i in design.get("instruments", []):
		parts.append(_part("instruments", i))
	parts.append(_part("comms", design.get("antenna", "")))
	parts.append(_part("comms", design.get("storage", "")))
	return parts.filter(func(p): return not p.is_empty())


## Downlink rate in Mbps for an antenna at a mission.
func downlink_rate_mbps(antenna: Dictionary, mission: Dictionary) -> float:
	var d := _n(mission, "distance_earth_au")
	if d <= 0.0:   # near Earth: Earth orbit / Moon
		return _n(antenna, "rate_near_mbps") * float(mission.get("near_rate_factor", 1.0))
	return _n(antenna, "rate_1au_mbps") / (d * d)   # signal weakens with distance²


## Power from one power source at a distance from the Sun (start of mission).
func source_power_w(source: Dictionary, distance_sun_au: float, years_elapsed: float = 0.0) -> float:
	match source.get("kind", ""):
		"solar":
			return _n(source, "output_w") / maxf(distance_sun_au * distance_sun_au, 0.01)
		"rtg":
			return _n(source, "output_w") * pow(1.0 - _n(source, "decay_pct_year") / 100.0, years_elapsed)
	return 0.0


# ---------------------------------------------------------------- contract

func summarize(design: Dictionary) -> Dictionary:
	var mission := GameData.get_mission(design.get("mission_id", ""))
	var years := float(design.get("target_years", mission.get("min_years", 1)))
	var lv := _part("launch_vehicles", design.get("launch_vehicle", ""))
	var antenna := _part("comms", design.get("antenna", ""))
	var storage := _part("comms", design.get("storage", ""))
	var network := _part("comms", design.get("network", ""))
	var battery := _part("power", design.get("battery", ""))
	var parts := _parts(design)

	# Budget (README §6.1)
	var cost := _n(lv, "cost_musd")
	for p in parts:
		cost += _n(p, "cost_musd")
	cost += _n(network, "cost_musd_year") * years
	cost += _n(mission, "ops_cost_musd_year") * years

	# Mass + propellant (README §6.2–6.3, rocket equation)
	var dry := 0.0
	for p in parts:
		dry += _n(p, "mass_kg")
	var dv := _n(mission, "delta_v_ms")
	var propellant := dry * (exp(dv / (ISP * G0)) - 1.0)

	# Power (README §6.4)
	var d_sun := maxf(_n(mission, "distance_sun_au"), 0.1)
	var gen := 0.0
	for p in design.get("power", []):
		gen += source_power_w(_part("power", p), d_sun)
	var load := _n(mission, "heater_w")
	for p in parts:
		if p.get("kind", "") in ["solar", "rtg", "battery", "shielding"]:
			continue
		load += _n(p, "power_w")
	var eclipse_need := load * _n(mission, "eclipse_shadow_min") / 60.0

	# Data (README §6.5)
	var data_day := 0.0
	for i in design.get("instruments", []):
		data_day += _n(_part("instruments", i), "data_gb_day")
	var rate := downlink_rate_mbps(antenna, mission) if not antenna.is_empty() else 0.0
	var downlink_day := rate * _n(network, "contact_hours_day") * 3600.0 / 1000.0   # Mb -> Gb
	var est_total := minf(data_day, downlink_day) * years * DAYS_PER_YEAR

	var budget := _n(mission, "budget_musd")
	return {
		"total_cost_musd": cost,
		"budget_musd": budget,
		"reserve_musd": budget - cost,
		"dry_mass_kg": dry,
		"propellant_kg": propellant,
		"wet_mass_kg": dry + propellant,
		"launcher_capacity_kg": float(lv.get("capacity_kg", {}).get(design.get("mission_id", ""), 0)),
		"power_gen_w": gen,
		"power_load_w": load,
		"power_balance_w": gen - load,
		"battery_wh": _n(battery, "capacity_wh"),
		"eclipse_need_wh": eclipse_need,
		"data_per_day_gb": data_day,
		"downlink_rate_mbps": rate,
		"downlink_per_day_gb": downlink_day,
		"storage_gb": _n(storage, "capacity_gb"),
		"est_total_data_gb": est_total,
		"data_goal_gb": _n(mission, "data_goal_gb"),
		"signal_delay_min": _n(mission, "signal_delay_min"),
		"slots_used": design.get("instruments", []).size() + design.get("power", []).size(),
		"slots_max": int(_part("buses", design.get("bus", "")).get("slots", 0)),
	}


func launch_check(design: Dictionary) -> Array:
	var s := summarize(design)
	var mission := GameData.get_mission(design.get("mission_id", ""))
	var checks: Array = []

	# One "complete" check per station, so each station shows its own missing parts.
	var needed := {
		"director": {"launch_vehicle": "a rocket"},
		"engineer": {"bus": "a spacecraft bus", "power": "a power source", "battery": "a battery"},
		"science": {"instruments": "at least one instrument"},
		"comms": {"antenna": "an antenna", "storage": "data storage", "network": "a ground network"},
	}
	for station in needed:
		var missing: Array = []
		for key in needed[station]:
			var v = design.get(key, "")
			if (typeof(v) == TYPE_ARRAY and v.is_empty()) or (typeof(v) != TYPE_ARRAY and str(v) == ""):
				missing.append(needed[station][key])
		checks.append(_check("complete_" + station, missing.is_empty(),
			"All %s parts chosen." % station,
			"Still needed: %s." % ", ".join(missing), station))

	var cap := float(s["launcher_capacity_kg"])
	if str(design.get("launch_vehicle", "")) != "":
		checks.append(_check("rocket_reaches", cap > 0.0,
			"The rocket can reach %s." % mission.get("destination", "the target"),
			"This rocket is not powerful enough to reach %s. Choose a bigger rocket." % mission.get("destination", "this target"),
			"director"))
		if cap > 0.0:
			checks.append(_check("fits_rocket", s["wet_mass_kg"] <= cap,
				"Launch mass %d kg fits the rocket (max %d kg)." % [s["wet_mass_kg"], cap],
				"Launch mass %d kg is too heavy for this rocket (max %d kg). Choose a bigger rocket or remove mass." % [s["wet_mass_kg"], cap],
				"director"))
	checks.append(_check("fits_bus", s["slots_used"] <= s["slots_max"],
		"Parts fit in the spacecraft (%d/%d slots)." % [s["slots_used"], s["slots_max"]],
		"Too many parts for this spacecraft (%d/%d slots). Choose a bigger bus or remove parts." % [s["slots_used"], s["slots_max"]],
		"engineer"))
	checks.append(_check("budget", s["reserve_musd"] >= 0.0,
		"Within budget: $%d M of $%d M." % [s["total_cost_musd"], s["budget_musd"]],
		"Over budget: $%d M of $%d M. Remove parts or choose cheaper ones." % [s["total_cost_musd"], s["budget_musd"]],
		"director"))
	checks.append(_check("power", s["power_balance_w"] >= 0.0,
		"Power OK: making %d W, using %d W." % [s["power_gen_w"], s["power_load_w"]],
		"Not enough power: making %d W but needing %d W. Add solar area, use an RTG, or remove power-hungry instruments." % [s["power_gen_w"], s["power_load_w"]],
		"engineer"))
	checks.append(_check("eclipse", s["battery_wh"] >= s["eclipse_need_wh"],
		"Battery (%d Wh) survives the shadow (needs %d Wh)." % [s["battery_wh"], s["eclipse_need_wh"]],
		"Battery too small for the shadow: needs %d Wh, has %d Wh. Choose a bigger battery." % [s["eclipse_need_wh"], s["battery_wh"]],
		"engineer"))
	checks.append(_check("science_goal", s["est_total_data_gb"] >= s["data_goal_gb"],
		"Estimated data %d Gb meets the goal of %d Gb." % [s["est_total_data_gb"], s["data_goal_gb"]],
		"Estimated data %d Gb is below the goal of %d Gb. Add instruments, a better antenna or a bigger ground network." % [s["est_total_data_gb"], s["data_goal_gb"]],
		"comms"))

	var have_types := {}
	for i in design.get("instruments", []):
		have_types[_part("instruments", i).get("type", "")] = true
	var missing_types: Array = []
	for t in mission.get("required_types", []):
		if not have_types.has(t):
			missing_types.append(t)
	checks.append(_check("required_instrument", missing_types.is_empty(),
		"Carries the instruments this mission needs.",
		"This mission needs an instrument of type: %s." % ", ".join(missing_types),
		"science"))

	if mission.get("needs_shielding", false):
		var lvl := int(_part("power", design.get("shielding", "")).get("shield_level", 0))
		checks.append(_check("radiation", lvl >= 1,
			"Radiation vault protects the electronics.",
			"Jupiter's radiation will fry unprotected electronics. Add a radiation vault.",
			"engineer"))

	var bus := _part("buses", design.get("bus", ""))
	if bus.get("cubesat", false):
		var bad: Array = []
		for p in _parts(design):
			if p != bus and not p.get("cubesat_ok", false):
				bad.append(p.get("name", "?"))
		checks.append(_check("cubesat_parts", bad.is_empty(),
			"All parts are CubeSat-sized.",
			"Too big for a CubeSat: %s." % ", ".join(bad),
			"engineer"))
	return checks


func _check(id: String, passed: bool, ok_msg: String, fail_msg: String, station: String) -> Dictionary:
	return {"id": id, "passed": passed, "message": ok_msg if passed else fail_msg, "fix_station": station}


## True if every launch check passes.
func is_go(design: Dictionary) -> bool:
	for c in launch_check(design):
		if not c["passed"]:
			return false
	return true


func score(result: Dictionary) -> Dictionary:
	# README §6.9: Science 50 %, Survival 30 %, Budget 20 %.
	var goal := maxf(_n(result, "data_goal_gb"), 0.001)
	var ratio := _n(result, "data_returned_gb") / goal
	var science := minf(ratio, 1.0) * 85.0 + clampf((ratio - 1.0) / 0.5, 0.0, 1.0) * 15.0
	science = minf(science, 100.0)
	var bonus := _n(result, "science_bonus")   # discoveries from events add straight to the total
	var survival := minf(_n(result, "lifetime_years") / maxf(_n(result, "target_years"), 0.001), 1.0) * 100.0
	var budget_pts := clampf(_n(result, "reserve_left_musd") / maxf(_n(result, "budget_musd"), 0.001) * 200.0, 0.0, 100.0)
	var total := minf(science * 0.5 + survival * 0.3 + budget_pts * 0.2 + bonus * 0.5, 100.0)
	var stars := 0
	if total >= 85.0:
		stars = 3
	elif total >= 65.0:
		stars = 2
	elif total >= 40.0:
		stars = 1
	return {
		"science": int(round(science)),
		"survival": int(round(survival)),
		"budget": int(round(budget_pts)),
		"bonus": int(round(bonus * 0.5)),
		"total": int(round(total)),
		"stars": stars,
	}


func find_lookalike(design: Dictionary) -> Dictionary:
	var dest: String = design.get("mission_id", "")
	var my_traits := {}
	for i in design.get("instruments", []):
		my_traits[i] = true
	for p in design.get("power", []):
		my_traits[_part("power", p).get("kind", "")] = true
	my_traits[design.get("bus", "")] = true
	my_traits[design.get("antenna", "")] = true
	my_traits[design.get("shielding", "")] = true
	var best: Dictionary = {}
	var best_score := -1
	for row in GameData.get_table("lookalikes"):
		if row.get("destination", "") != dest:
			continue
		var n := 0
		for t in row.get("traits", []):
			if my_traits.has(t):
				n += 1
		if n > best_score:
			best_score = n
			best = row
	return best


func make_test_design(mission_id: String = "mars") -> Dictionary:
	var d: Dictionary
	match mission_id:
		"earth":
			d = {"launch_vehicle": "small", "bus": "small", "power": ["solar_s"], "battery": "batt_s",
				"shielding": "shield_none", "instruments": ["cam_wide"], "antenna": "mga",
				"storage": "stor_s", "network": "net_basic", "target_years": 2.0}
		"moon":
			d = {"launch_vehicle": "medium", "bus": "small", "power": ["solar_m"], "battery": "batt_m",
				"shielding": "shield_none", "instruments": ["cam_wide", "altimeter", "ir_spec"], "antenna": "mga",
				"storage": "stor_m", "network": "net_deep", "target_years": 1.0}
		"jupiter":
			d = {"launch_vehicle": "heavy", "bus": "medium", "power": ["solar_xl", "solar_xl"], "battery": "batt_m",
				"shielding": "shield_med", "instruments": ["microwave", "magnet", "particle", "cam_wide"], "antenna": "hga",
				"storage": "stor_m", "network": "net_deep", "target_years": 2.0}
		"saturn":
			d = {"launch_vehicle": "heavy", "bus": "medium", "power": ["rtg", "rtg"], "battery": "batt_m",
				"shielding": "shield_none", "instruments": ["cam_wide", "ir_spec", "dust", "magnet"], "antenna": "hga",
				"storage": "stor_m", "network": "net_deep", "target_years": 4.0}
		_:
			mission_id = "mars"
			d = {"launch_vehicle": "medium", "bus": "medium", "power": ["solar_l"], "battery": "batt_m",
				"shielding": "shield_none", "instruments": ["cam_hires", "ir_spec"], "antenna": "hga",
				"storage": "stor_m", "network": "net_deep", "target_years": 2.0}
	d["mission_id"] = mission_id
	return d
