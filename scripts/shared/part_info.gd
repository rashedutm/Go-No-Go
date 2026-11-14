# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# PartInfo: station/section definitions and plain-English text for parts (used by the 3D hangar).
# Owner: Member A.
class_name PartInfo
extends RefCounted

const STATIONS := [
	{"key": "director", "name": "Director", "long": "Mission Director",
		"blurb": "Pick a rocket that can carry everything to the destination, and how long the mission lasts."},
	{"key": "engineer", "name": "Engineer", "long": "Spacecraft Engineer",
		"blurb": "Build the spacecraft: frame, power, battery and radiation protection."},
	{"key": "science", "name": "Science", "long": "Science Lead",
		"blurb": "Choose the instruments. More science means more mass, power, cost and data."},
	{"key": "comms", "name": "Comms", "long": "Comms & Ops",
		"blurb": "Get the data home: antenna, memory and ground stations."},
]

# mode: single | multi_count | toggle | years
const SECTIONS := {
	"director": [
		{"title": "Rocket", "table": "launch_vehicles", "kind": "", "key": "launch_vehicle", "mode": "single"},
		{"title": "Mission length", "mode": "years", "key": "target_years"},
	],
	"engineer": [
		{"title": "Frame", "table": "buses", "kind": "", "key": "bus", "mode": "single"},
		{"title": "Power", "table": "power", "kind": "power_source", "key": "power", "mode": "multi_count"},
		{"title": "Battery", "table": "power", "kind": "battery", "key": "battery", "mode": "single"},
		{"title": "Shielding", "table": "power", "kind": "shielding", "key": "shielding", "mode": "single"},
	],
	"science": [
		{"title": "Instruments", "table": "instruments", "kind": "", "key": "instruments", "mode": "toggle"},
	],
	"comms": [
		{"title": "Antenna", "table": "comms", "kind": "antenna", "key": "antenna", "mode": "single"},
		{"title": "Memory", "table": "comms", "kind": "storage", "key": "storage", "mode": "single"},
		{"title": "Ground", "table": "comms", "kind": "network", "key": "network", "mode": "single"},
	],
}


static func station(key: String) -> Dictionary:
	for s in STATIONS:
		if s["key"] == key:
			return s
	return STATIONS[0]


static func items_for(sec: Dictionary) -> Array:
	var rows := GameData.get_table(sec.get("table", ""))
	match sec.get("kind", ""):
		"":
			return rows
		"power_source":
			return rows.filter(func(r): return r.get("kind", "") in ["solar", "rtg"])
		_:
			return rows.filter(func(r): return r.get("kind", "") == sec["kind"])


static func count_selected(sec: Dictionary, id: String) -> int:
	var v = MissionState.design.get(sec["key"])
	if typeof(v) == TYPE_ARRAY:
		return v.count(id)
	return 1 if str(v) == id else 0


## Apply a left click (add/select) on a part.
static func click(sec: Dictionary, id: String) -> void:
	var key: String = sec["key"]
	match sec["mode"]:
		"single":
			var same: bool = MissionState.design.get(key, "") == id
			MissionState.set_design_value(key, "" if same and key != "shielding" else id)
		"multi_count":
			var arr: Array = MissionState.design.get(key, []).duplicate()
			if arr.size() < 4:
				arr.append(id)
			MissionState.set_design_value(key, arr)
		"toggle":
			var arr: Array = MissionState.design.get(key, []).duplicate()
			if id in arr:
				arr.erase(id)
			else:
				arr.append(id)
			MissionState.set_design_value(key, arr)


## Apply a right click (remove one).
static func remove(sec: Dictionary, id: String) -> void:
	var key: String = sec["key"]
	if sec["mode"] in ["multi_count", "toggle"]:
		var arr: Array = MissionState.design.get(key, []).duplicate()
		arr.erase(id)
		MissionState.set_design_value(key, arr)
	elif MissionState.design.get(key, "") == id and key != "shielding":
		MissionState.set_design_value(key, "")


## The one number that matters most for a tile.
static func key_stat(sec: Dictionary, it: Dictionary, mission: Dictionary) -> String:
	var mid: String = mission.get("id", "")
	match sec.get("table", ""):
		"launch_vehicles":
			var cap := float(it.get("capacity_kg", {}).get(mid, 0))
			return ("%s kg here" % fmt(cap)) if cap > 0 else "can't reach"
		"buses":
			return "%d slots" % int(it["slots"])
		"instruments":
			return "%s Gb/day" % fmt(it["data_gb_day"])
		"power":
			match it.get("kind", ""):
				"solar":
					return "%s W here" % fmt(Sim.source_power_w(it, mission.get("distance_sun_au", 1.0)))
				"rtg":
					return "%s W anywhere" % fmt(it["output_w"])
				"battery":
					return "%s Wh" % fmt(it["capacity_wh"])
				"shielding":
					return "level %d" % int(it["shield_level"])
		"comms":
			match it.get("kind", ""):
				"antenna":
					return "%s Mbps here" % fmt(Sim.downlink_rate_mbps(it, mission))
				"storage":
					return "%s Gb" % fmt(it["capacity_gb"])
				"network":
					return "%s h/day" % fmt(it["contact_hours_day"])
	return ""


## Cost line for a tile.
static func cost_stat(it: Dictionary) -> String:
	if it.has("cost_musd_year"):
		return "$%s M/yr" % fmt(it["cost_musd_year"])
	var parts: Array = ["$%s M" % fmt(it.get("cost_musd", 0))]
	if it.has("mass_kg"):
		parts.append("%s kg" % fmt(it["mass_kg"]))
	if float(it.get("power_w", 0)) > 0 and not it.has("slots"):
		parts.append("%s W" % fmt(it["power_w"]))
	return "  ".join(parts)


## Short reason a part is a bad fit right now ("" = fine).
static func problem(sec: Dictionary, it: Dictionary, mission: Dictionary) -> String:
	var mid: String = mission.get("id", "")
	if sec.get("table", "") == "launch_vehicles" and float(it.get("capacity_kg", {}).get(mid, 0)) <= 0.0:
		return "Can't reach " + mission.get("name", "this target")
	var bus := GameData.get_item("buses", MissionState.design.get("bus", ""))
	if bus.get("cubesat", false) and not sec.get("table", "") in ["buses", "launch_vehicles"] \
			and it.has("cubesat_ok") and not it.get("cubesat_ok", false):
		return "Too big for a CubeSat"
	if it.get("kind", "") == "solar" and float(mission.get("distance_sun_au", 1.0)) >= 9.0:
		return "Almost no sunlight here"
	return ""


## Plain-English "why it matters".
static func why(it: Dictionary, mission: Dictionary) -> String:
	var pct := int(100.0 / pow(float(mission.get("distance_sun_au", 1.0)), 2))
	match it.get("kind", it.get("type", "")):
		"solar":
			return "Sunlight gets weaker with distance squared. Here it is %d%% of Earth's." % pct
		"rtg":
			return "Doesn't need the Sun, which is why Cassini used them at Saturn. Heavy and expensive for its power."
		"battery":
			return "In an orbit's shadow the battery is the only power. If it runs out, the spacecraft shuts down."
		"shielding":
			return "Jupiter's radiation fries electronics. Juno keeps its brain in a titanium vault."
		"antenna":
			return "Signals spread out with distance. Only a big dish can send lots of data from far away."
		"storage":
			return "Data waits in memory until a ground station is listening."
		"network":
			return "More contact hours means more data reaches Earth, but antenna time costs money every year."
	if it.has("capacity_kg"):
		return "Rockets carry much less to far planets than to Earth orbit. The spacecraft AND its fuel must fit."
	if it.has("slots"):
		return "A bigger frame fits more parts, but its mass needs more fuel and a bigger rocket."
	if it.has("data_gb_day"):
		return "More science, but also more mass, power, cost, and data to send home."
	return ""


static func fmt(v) -> String:
	var f := float(v)
	if absf(f) < 10.0 and absf(f - roundf(f)) > 0.001:
		return "%.2f" % f if absf(f) < 1.0 else "%.1f" % f
	var n := int(round(f))
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
