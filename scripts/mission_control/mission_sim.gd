# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# MissionSim (M4b): the live mission model, advanced in "days" by Mission Control.
# Uses the shared math in Sim (README §6.4–6.7). No scene access, so it can be tested headless.
# Owner: Member B (Emon).
#
#   var sim := MissionSim.new(design)
#   sim.tick(days)              # call every frame with delta * days_per_second
#   sim.finished / sim.end_reason
#   MissionState.last_result = sim.result()
class_name MissionSim
extends RefCounted

const RADIATION_WEAR := {0: 90.0, 1: 12.0, 2: 5.0}   # % health lost per year at Jupiter by shield level
const BASE_WEAR := 2.0                              # % per year everywhere (aging)
const DEAD_BATTERY_DAYS := 10.0

var design: Dictionary
var mission: Dictionary
var summary: Dictionary

# --- state (read by the HUD / consoles)
var day := 0.0
var total_days := 365.0
var battery_wh := 0.0
var battery_max := 0.0
var storage_gb := 0.0
var storage_max := 0.0
var data_returned_gb := 0.0
var data_lost_gb := 0.0
var health := 100.0
var reserve_musd := 0.0
var science_bonus := 0
var instruments_on := {}            # id -> bool
var safe_mode := false
var extra_contact_hours := 0.0      # bought by Comms/Director
var blackout_days := 0.0            # comms outage (events)
var power_penalty := 0.0            # 0..1 fraction of generation lost (damage events)
var finished := false
var end_reason := ""
var event_log: Array = []           # {day, text, cause, effect}

# --- last-tick rates (for gauges)
var power_gen_w := 0.0
var power_load_w := 0.0
var data_rate_gb_day := 0.0
var downlink_gb_day := 0.0

var _dead_days := 0.0
var _flags := {}                    # one-time log flags


func _init(p_design: Dictionary) -> void:
	design = p_design
	mission = GameData.get_mission(design.get("mission_id", ""))
	summary = Sim.summarize(design)
	total_days = float(design.get("target_years", mission.get("min_years", 1))) * 365.0
	battery_max = summary["battery_wh"]
	battery_wh = battery_max
	storage_max = maxf(summary["storage_gb"], 1.0)
	reserve_musd = maxf(summary["reserve_musd"], 0.0)
	for i in design.get("instruments", []):
		instruments_on[i] = true


# ================================================================ helpers

func years() -> float:
	return day / 365.0


func load_w() -> float:
	var w := float(mission.get("heater_w", 0)) + float(GameData.get_item("buses", design.get("bus", "")).get("power_w", 0))
	w += float(GameData.get_item("comms", design.get("antenna", "")).get("power_w", 0))
	w += float(GameData.get_item("comms", design.get("storage", "")).get("power_w", 0))
	if not safe_mode:
		for i in instruments_on:
			if instruments_on[i]:
				w += float(GameData.get_item("instruments", i).get("power_w", 0))
	return w


func gen_w() -> float:
	var g := 0.0
	var d := float(mission.get("distance_sun_au", 1.0))
	for p in design.get("power", []):
		g += Sim.source_power_w(GameData.get_item("power", p), d, years())
	return g * (1.0 - power_penalty)


func produced_gb_day() -> float:
	if safe_mode:
		return 0.0
	var r := 0.0
	for i in instruments_on:
		if instruments_on[i]:
			r += float(GameData.get_item("instruments", i).get("data_gb_day", 0))
	return r


func downlink_capacity_gb_day() -> float:
	if blackout_days > 0.0:
		return 0.0
	var ant := GameData.get_item("comms", design.get("antenna", ""))
	var hours := float(GameData.get_item("comms", design.get("network", "")).get("contact_hours_day", 0)) + extra_contact_hours
	return Sim.downlink_rate_mbps(ant, mission) * minf(hours, 24.0) * 3600.0 / 1000.0


func battery_pct() -> float:
	return 100.0 * battery_wh / maxf(battery_max, 0.001)


func storage_pct() -> float:
	return 100.0 * storage_gb / storage_max


func progress() -> float:
	return clampf(day / total_days, 0.0, 1.0)


func add_log(text: String, cause := "", effect := "") -> void:
	event_log.append({"day": int(day), "text": text, "cause": cause, "effect": effect})


func _once(flag: String, text: String, cause: String, effect: String) -> void:
	if not _flags.has(flag):
		_flags[flag] = true
		add_log(text, cause, effect)


# ================================================================ tick

## Advance the mission by `dt` days.
func tick(dt: float) -> void:
	if finished or dt <= 0.0:
		return
	day = minf(day + dt, total_days)
	blackout_days = maxf(blackout_days - dt, 0.0)

	# ---- power: sunlit balance, then shadows
	power_gen_w = gen_w()
	power_load_w = load_w()
	var shadow := float(mission.get("eclipse_shadow_min", 0))
	var period := maxf(float(mission.get("eclipse_period_min", 0)), 1.0)
	var sun_frac := 1.0 - (shadow / period if shadow > 0.0 else 0.0)
	var net_wh_per_day := (power_gen_w * sun_frac - power_load_w) * 24.0
	battery_wh = clampf(battery_wh + net_wh_per_day * dt, 0.0, battery_max)

	# battery too small for one shadow -> instruments brown out part of every orbit
	var science_eff := 1.0
	var need := power_load_w * shadow / 60.0
	if shadow > 0.0 and need > battery_max:
		science_eff = clampf(battery_max / need, 0.0, 1.0)
		_once("eclipse", "Battery too small for the planet's shadow.", "Battery smaller than the energy needed in shadow",
			"Instruments shut down in every shadow, so about %d%% of science was lost" % int((1.0 - science_eff) * 100))

	if battery_wh <= 0.0 and net_wh_per_day < 0.0:
		_dead_days += dt
		science_eff = 0.0
		_once("power_neg", "Power failure! The spacecraft uses more power than it makes.", "Power use was higher than power made",
			"The battery ran flat and science stopped")
		if _dead_days > DEAD_BATTERY_DAYS:
			_end("power_dead")
			return
	else:
		_dead_days = 0.0

	# ---- data: instruments -> storage -> Earth
	data_rate_gb_day = produced_gb_day() * science_eff
	downlink_gb_day = downlink_capacity_gb_day()
	storage_gb += data_rate_gb_day * dt
	var sent := minf(storage_gb, downlink_gb_day * dt)
	storage_gb -= sent
	data_returned_gb += sent
	if storage_gb > storage_max:
		data_lost_gb += storage_gb - storage_max
		storage_gb = storage_max
		if data_lost_gb > 1.0:
			_once("storage", "Memory full: new science data is being lost.", "Instruments made more data than the antenna could send",
				"Data was thrown away because memory was full")

	# ---- health: aging + radiation
	var wear := BASE_WEAR
	if mission.get("needs_shielding", false):
		var lvl := int(GameData.get_item("power", design.get("shielding", "")).get("shield_level", 0))
		wear += RADIATION_WEAR.get(lvl, 30.0)
		if lvl == 0:
			_once("radiation", "Radiation is damaging the electronics!", "No radiation vault at Jupiter", "The spacecraft wore out much faster")
	if safe_mode:
		wear *= 0.5
	health = maxf(health - wear / 365.0 * dt, 0.0)
	if health <= 0.0:
		_end("destroyed")
		return

	if day >= total_days:
		_end("completed")


func _end(reason: String) -> void:
	finished = true
	end_reason = reason
	match reason:
		"completed":
			add_log("Mission complete! The spacecraft finished its planned %d years." % int(total_days / 365.0), "", "")
		"power_dead":
			add_log("Contact lost: the batteries are dead.", "Not enough power for too long", "The mission ended early")
		"destroyed":
			add_log("Contact lost: the spacecraft is worn out.", "Damage and wear reached 100%", "The mission ended early")


# ================================================================ player actions (M4c)
# Each returns true if it happened. Costs come out of the reserve (unspent budget).

const CONTACT_STEP_H := 4.0      # hours/day added per purchase
const CONTACT_COST := 4.0        # $M per purchase
const CONTACT_MAX_H := 8.0
const REPAIR_COST := 15.0        # $M
const REPAIR_AMOUNT := 15.0      # % health


func set_safe_mode(on: bool) -> bool:
	if safe_mode == on or finished:
		return false
	safe_mode = on
	if on:
		add_log("SAFE MODE on: instruments off to save power.", "Safe mode", "No science while it is on, but power and wear are saved")
	else:
		add_log("Safe mode off: science resumes.")
	return true


func toggle_instrument(id: String) -> bool:
	if not instruments_on.has(id) or finished:
		return false
	instruments_on[id] = not instruments_on[id]
	var name: String = GameData.get_item("instruments", id).get("name", id)
	add_log("%s switched %s." % [name, "ON" if instruments_on[id] else "OFF"])
	return true


func can_buy_contact() -> bool:
	return not finished and extra_contact_hours < CONTACT_MAX_H and reserve_musd >= CONTACT_COST


func buy_contact_time() -> bool:
	if not can_buy_contact():
		return false
	extra_contact_hours += CONTACT_STEP_H
	reserve_musd -= CONTACT_COST
	add_log("Bought +%d h/day of antenna time for $%d M." % [int(CONTACT_STEP_H), int(CONTACT_COST)],
		"Extra ground-station time", "More data reaches Earth, but less money left over")
	return true


func can_repair() -> bool:
	return not finished and health < 100.0 and reserve_musd >= REPAIR_COST


func repair() -> bool:
	if not can_repair():
		return false
	health = minf(health + REPAIR_AMOUNT, 100.0)
	reserve_musd -= REPAIR_COST
	add_log("Engineers uploaded a software fix (+%d%% health) for $%d M." % [int(REPAIR_AMOUNT), int(REPAIR_COST)],
		"Spent reserve on a repair", "The spacecraft lasts longer, but the budget score drops")
	return true


## Ends the mission now (Director decision / quit).
func abort() -> void:
	if not finished:
		finished = true
		end_reason = "aborted"
		add_log("Mission ended early by the Director.", "Mission ended early", "Less time to collect science")


func result() -> Dictionary:
	return {
		"mission_id": design.get("mission_id", ""),
		"end_reason": end_reason if end_reason != "" else "completed",
		"data_returned_gb": data_returned_gb,
		"data_goal_gb": float(mission.get("data_goal_gb", 1)),
		"science_bonus": science_bonus,
		"lifetime_years": day / 365.0,
		"target_years": total_days / 365.0,
		"reserve_left_musd": reserve_musd,
		"budget_musd": float(mission.get("budget_musd", 1)),
		"log": event_log,
	}
