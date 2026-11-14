# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M2 Design screen: 4 role stations, part cards, live resource bar, spacecraft view.
# The UI is built in code so it merges cleanly in Git. Owner: Member A.
extends Control

const SpacecraftView := preload("res://scenes/design/spacecraft_view.gd")

const STATIONS := [
	{"key": "director", "name": "Mission Director",
		"blurb": "You own the budget and the schedule. Pick a rocket that can carry the spacecraft to its destination, and decide how long the mission should last."},
	{"key": "engineer", "name": "Spacecraft Engineer",
		"blurb": "You build the spacecraft: the frame (bus), the power system, the battery for shadows and the radiation protection. Every kilogram needs fuel to brake into orbit."},
	{"key": "science", "name": "Science Lead",
		"blurb": "You choose the instruments. More instruments mean more science, but also more mass, power, cost and data to send home."},
	{"key": "comms", "name": "Comms & Ops",
		"blurb": "You get the data home. Far from Earth the signal gets weak, so you need a bigger antenna, more contact time or more memory."},
]

# Each station's sections. mode: single | multi_count | toggle | years
const SECTIONS := {
	"director": [
		{"title": "Launch vehicle", "table": "launch_vehicles", "kind": "", "key": "launch_vehicle", "mode": "single"},
		{"title": "Mission length", "mode": "years"},
	],
	"engineer": [
		{"title": "Spacecraft bus (frame)", "table": "buses", "kind": "", "key": "bus", "mode": "single"},
		{"title": "Power sources: left-click to add, right-click to remove", "table": "power", "kind": "power_source", "key": "power", "mode": "multi_count"},
		{"title": "Battery", "table": "power", "kind": "battery", "key": "battery", "mode": "single"},
		{"title": "Radiation shielding", "table": "power", "kind": "shielding", "key": "shielding", "mode": "single"},
	],
	"science": [
		{"title": "Instruments: click to add or remove", "table": "instruments", "kind": "", "key": "instruments", "mode": "toggle"},
	],
	"comms": [
		{"title": "Antenna", "table": "comms", "kind": "antenna", "key": "antenna", "mode": "single"},
		{"title": "Onboard data storage", "table": "comms", "kind": "storage", "key": "storage", "mode": "single"},
		{"title": "Ground network", "table": "comms", "kind": "network", "key": "network", "mode": "single"},
	],
}

const C_GOOD := Color(0.35, 0.85, 0.45)
const C_WARN := Color(1.0, 0.7, 0.2)
const C_BAD := Color(1.0, 0.35, 0.35)
const C_CARD := Color(0.13, 0.18, 0.33)
const C_CARD_SEL := Color(0.16, 0.42, 0.85)
const C_CARD_OFF := Color(0.12, 0.13, 0.18)

var station: String = "director"
var mission: Dictionary = {}

var _station_buttons := {}
var _bars := {}
var _cards_box: VBoxContainer
var _info: RichTextLabel
var _view: Control
var _hovered: Dictionary = {}


func _ready() -> void:
	var mid := MissionState.current_mission_id
	if MissionState.design.get("mission_id", "") != mid:
		MissionState.start_mission(mid)
	mission = GameData.get_mission(mid)
	station = str(MissionState.get_meta("design_station", "director"))
	_build()
	MissionState.design_changed.connect(_refresh)
	_refresh()


# ============================================================ layout

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# Header
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "DESIGN: %s" % mission.get("name", "")
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	var sub := Label.new()
	sub.text = "   %s · goal: %s" % [mission.get("destination", ""), mission.get("objective", "")]
	sub.modulate = Color(0.7, 0.78, 0.95)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.clip_text = true
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(sub)

	# Resource bar
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	root.add_child(bar_row)
	for b in [["budget", "Budget"], ["mass", "Launch mass"], ["power", "Power used"],
			["battery", "Shadow energy"], ["data", "Science data"], ["slots", "Slots"]]:
		bar_row.add_child(_make_bar(b[0], b[1]))

	# Main area
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 12)
	root.add_child(main)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 230
	left.add_theme_constant_override("separation", 8)
	main.add_child(left)
	var st_label := Label.new()
	st_label.text = "STATIONS"
	st_label.modulate = Color(0.6, 0.7, 0.9)
	left.add_child(st_label)
	for s in STATIONS:
		var b := Button.new()
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 52
		var key: String = s["key"]
		b.pressed.connect(func(): _set_station(key))
		left.add_child(b)
		_station_buttons[key] = b

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	_cards_box = VBoxContainer.new()
	_cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_cards_box)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 340
	right.add_theme_constant_override("separation", 8)
	main.add_child(right)
	var view_panel := PanelContainer.new()
	right.add_child(view_panel)
	_view = SpacecraftView.new()
	_view.custom_minimum_size = Vector2(300, 210)
	view_panel.add_child(_view)
	var info_panel := PanelContainer.new()
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(info_panel)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.scroll_active = true
	_info.add_theme_font_size_override("normal_font_size", 16)
	_info.add_theme_font_size_override("bold_font_size", 16)
	info_panel.add_child(_info)

	# Footer
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	root.add_child(footer)
	var back := Button.new()
	back.text = "< Briefing"
	back.pressed.connect(func(): MissionState.go_to("briefing"))
	footer.add_child(back)
	var example := Button.new()
	example.text = "Load example design"
	example.tooltip_text = "Stuck? Load a design that works, then improve it."
	example.pressed.connect(func():
		MissionState.design = Sim.make_test_design(MissionState.current_mission_id)
		MissionState.design_changed.emit())
	footer.add_child(example)
	var clear := Button.new()
	clear.text = "Clear"
	clear.pressed.connect(func():
		MissionState.design = MissionState.empty_design(MissionState.current_mission_id)
		MissionState.design_changed.emit())
	footer.add_child(clear)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var go := Button.new()
	go.text = "Go to Launch Check  >"
	go.custom_minimum_size.x = 260
	go.pressed.connect(func(): MissionState.go_to("launch_check"))
	footer.add_child(go)


func _make_bar(key: String, label_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)
	var name_l := Label.new()
	name_l.text = label_text
	name_l.add_theme_font_size_override("font_size", 14)
	name_l.modulate = Color(0.7, 0.78, 0.95)
	v.add_child(name_l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	bar.max_value = 1.0
	bar.step = 0.0
	v.add_child(bar)
	var val := Label.new()
	val.add_theme_font_size_override("font_size", 14)
	v.add_child(val)
	_bars[key] = {"bar": bar, "label": val, "panel": panel}
	return panel


# ============================================================ refresh

func _set_station(key: String) -> void:
	station = key
	MissionState.set_meta("design_station", key)
	_hovered = {}
	_refresh()


func _refresh() -> void:
	var d := MissionState.design
	var s := Sim.summarize(d)
	var checks := Sim.launch_check(d)
	_update_bars(s)
	_update_station_buttons(checks)
	_rebuild_cards(s)
	_view.set("design", d.duplicate(true))
	_view.queue_redraw()
	_update_info(checks)


func _set_bar(key: String, ratio: float, text: String, color: Color, tip: String) -> void:
	var b: Dictionary = _bars[key]
	var bar: ProgressBar = b["bar"]
	bar.value = clampf(ratio, 0.0, 1.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	b["label"].text = text
	b["label"].modulate = color.lightened(0.3)
	b["panel"].tooltip_text = tip


func _update_bars(s: Dictionary) -> void:
	var r: float = s["total_cost_musd"] / maxf(s["budget_musd"], 1.0)
	_set_bar("budget", r, "$%s M / $%s M" % [_fmt(s["total_cost_musd"]), _fmt(s["budget_musd"])],
		C_BAD if r > 1.0 else (C_WARN if r > 0.9 else C_GOOD),
		"Total cost of parts, rocket and operations. Money left over becomes your reserve for emergencies and earns budget points.")

	var cap: float = s["launcher_capacity_kg"]
	if cap <= 0.0:
		_set_bar("mass", 0.0, "%s kg (no rocket)" % _fmt(s["wet_mass_kg"]), C_WARN,
			"Pick a rocket that can reach this destination.")
	else:
		r = s["wet_mass_kg"] / cap
		_set_bar("mass", r, "%s / %s kg" % [_fmt(s["wet_mass_kg"]), _fmt(cap)],
			C_BAD if r > 1.0 else (C_WARN if r > 0.9 else C_GOOD),
			"Spacecraft %s kg + fuel %s kg. Heavier spacecraft need more fuel to brake into orbit." % [_fmt(s["dry_mass_kg"]), _fmt(s["propellant_kg"])])

	r = s["power_load_w"] / maxf(s["power_gen_w"], 0.001)
	_set_bar("power", r, "%s W used / %s W made" % [_fmt(s["power_load_w"]), _fmt(s["power_gen_w"])],
		C_BAD if r > 1.0 else (C_WARN if r > 0.85 else C_GOOD),
		"Solar power here is %d%% of what it is at Earth (sunlight weakens with distance squared)." % int(100.0 / pow(mission.get("distance_sun_au", 1.0), 2)))

	var need: float = s["eclipse_need_wh"]
	if float(mission.get("eclipse_shadow_min", 0)) <= 0.0:
		_set_bar("battery", 0.0, "No long shadows here", C_GOOD, "This orbit has no long shadows, but a battery still helps with emergencies.")
	else:
		r = need / maxf(s["battery_wh"], 0.001)
		_set_bar("battery", r, "need %s / have %s Wh" % [_fmt(need), _fmt(s["battery_wh"])],
			C_BAD if r > 1.0 else (C_WARN if r > 0.8 else C_GOOD),
			"Each orbit spends %d min in shadow, where only the battery powers the spacecraft." % int(mission.get("eclipse_shadow_min", 0)))

	r = s["est_total_data_gb"] / maxf(s["data_goal_gb"], 1.0)
	var limit := "instruments" if s["data_per_day_gb"] < s["downlink_per_day_gb"] else "downlink"
	_set_bar("data", r, "%s / %s Gb" % [_fmt(s["est_total_data_gb"]), _fmt(s["data_goal_gb"])],
		C_GOOD if r >= 1.0 else (C_WARN if r >= 0.6 else C_BAD),
		"Instruments make %.1f Gb/day, you can send %.1f Gb/day. Limited by: %s." % [s["data_per_day_gb"], s["downlink_per_day_gb"], limit])

	var mx: int = s["slots_max"]
	r = float(s["slots_used"]) / maxf(mx, 1.0)
	_set_bar("slots", r if mx > 0 else 0.0, "%d / %d" % [s["slots_used"], mx] if mx > 0 else "pick a bus",
		C_BAD if s["slots_used"] > mx and mx > 0 else C_GOOD,
		"Instruments + power sources must fit in the spacecraft bus.")


func _update_station_buttons(checks: Array) -> void:
	var issues := {}
	for c in checks:
		if not c["passed"]:
			issues[c["fix_station"]] = int(issues.get(c["fix_station"], 0)) + 1
	for s in STATIONS:
		var b: Button = _station_buttons[s["key"]]
		var n := int(issues.get(s["key"], 0))
		b.text = s["name"] + ("\n%d issue%s" % [n, "" if n == 1 else "s"] if n > 0 else "\nall good")
		b.button_pressed = s["key"] == station
		b.add_theme_color_override("font_color", C_WARN if n > 0 else Color.WHITE)


# ============================================================ cards

func _rebuild_cards(s: Dictionary) -> void:
	for c in _cards_box.get_children():
		c.queue_free()
	var st := _station_def(station)
	var intro := Label.new()
	intro.text = st["blurb"]
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.75, 0.82, 0.95)
	_cards_box.add_child(intro)

	for sec in SECTIONS[station]:
		var head := Label.new()
		head.text = sec["title"].to_upper()
		head.add_theme_font_size_override("font_size", 16)
		head.modulate = Color(1, 0.8, 0.35)
		_cards_box.add_child(head)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		_cards_box.add_child(flow)
		if sec["mode"] == "years":
			_add_year_cards(flow)
			continue
		for item in _items_for(sec):
			flow.add_child(_make_card(sec, item))


func _station_def(key: String) -> Dictionary:
	for s in STATIONS:
		if s["key"] == key:
			return s
	return STATIONS[0]


func _items_for(sec: Dictionary) -> Array:
	var rows := GameData.get_table(sec["table"])
	match sec["kind"]:
		"":
			return rows
		"power_source":
			return rows.filter(func(r): return r.get("kind", "") in ["solar", "rtg"])
		_:
			return rows.filter(func(r): return r.get("kind", "") == sec["kind"])


func _count_selected(sec: Dictionary, id: String) -> int:
	var v = MissionState.design.get(sec["key"])
	if typeof(v) == TYPE_ARRAY:
		return v.count(id)
	return 1 if str(v) == id else 0


func _make_card(sec: Dictionary, item: Dictionary) -> Control:
	var id: String = item["id"]
	var count := _count_selected(sec, id)
	var problem := _card_problem(sec, item)

	var b := Button.new()
	b.custom_minimum_size = Vector2(204, 104)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 14)
	var title: String = item.get("name", id)
	if sec["mode"] == "multi_count" and count > 0:
		title = "x%d  %s" % [count, title]
	elif count > 0:
		title = "[ON]  " + title
	b.text = title + "\n" + _card_stats(sec, item) + ("\n! " + problem if problem != "" else "")
	b.tooltip_text = item.get("description", "")

	var col := C_CARD_SEL if count > 0 else (C_CARD_OFF if problem != "" else C_CARD)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col.lightened(0.12) if state == "hover" else col
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(10)
		if count > 0:
			sb.set_border_width_all(2)
			sb.border_color = Color(1, 0.8, 0.3)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7) if problem != "" and count == 0 else Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)

	b.pressed.connect(func(): _on_card_left(sec, id))
	b.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			_on_card_right(sec, id))
	b.mouse_entered.connect(func():
		_hovered = {"sec": sec, "item": item}
		_update_info(Sim.launch_check(MissionState.design)))
	return b


func _on_card_left(sec: Dictionary, id: String) -> void:
	var key: String = sec["key"]
	match sec["mode"]:
		"single":
			MissionState.set_design_value(key, "" if MissionState.design.get(key, "") == id and key != "shielding" else id)
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


func _on_card_right(sec: Dictionary, id: String) -> void:
	var key: String = sec["key"]
	if sec["mode"] in ["multi_count", "toggle"]:
		var arr: Array = MissionState.design.get(key, []).duplicate()
		arr.erase(id)
		MissionState.set_design_value(key, arr)
	elif MissionState.design.get(key, "") == id and key != "shielding":
		MissionState.set_design_value(key, "")


func _add_year_cards(flow: HFlowContainer) -> void:
	var base := float(mission.get("min_years", 1))
	for extra in [0.0, 1.0, 2.0]:
		var y: float = base + extra
		var b := Button.new()
		b.custom_minimum_size = Vector2(204, 84)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 14)
		var sel := is_equal_approx(float(MissionState.design.get("target_years", base)), y)
		b.text = ("[ON]  " if sel else "") + "%d years%s\n+ more science   - more operations cost & wear" % [y, " (minimum)" if extra == 0.0 else ""]
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_CARD_SEL if sel else C_CARD
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(10)
		for state in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func(): MissionState.set_design_value("target_years", y))
		flow.add_child(b)


func _card_stats(sec: Dictionary, it: Dictionary) -> String:
	var mid := MissionState.current_mission_id
	match sec["table"]:
		"launch_vehicles":
			var cap := float(it.get("capacity_kg", {}).get(mid, 0))
			return "$%s M   |   %s" % [_fmt(it["cost_musd"]), ("can carry %s kg here" % _fmt(cap)) if cap > 0 else "cannot reach this target"]
		"buses":
			return "$%s M  |  %s kg  |  %s W  |  %d slots" % [_fmt(it["cost_musd"]), _fmt(it["mass_kg"]), _fmt(it["power_w"]), it["slots"]]
		"instruments":
			return "%s  |  $%s M  |  %s kg  |  %s W  |  %s Gb/day" % [it["type"], _fmt(it["cost_musd"]), _fmt(it["mass_kg"]), _fmt(it["power_w"]), _fmt(it["data_gb_day"])]
		"power":
			match it.get("kind", ""):
				"solar":
					return "$%s M  |  %s kg  |  %s W at Earth, %s W here" % [_fmt(it["cost_musd"]), _fmt(it["mass_kg"]), _fmt(it["output_w"]),
						_fmt(Sim.source_power_w(it, mission.get("distance_sun_au", 1.0)))]
				"rtg":
					return "$%s M  |  %s kg  |  %s W anywhere" % [_fmt(it["cost_musd"]), _fmt(it["mass_kg"]), _fmt(it["output_w"])]
				"battery":
					return "$%s M  |  %s kg  |  stores %s Wh" % [_fmt(it["cost_musd"]), _fmt(it["mass_kg"]), _fmt(it["capacity_wh"])]
				"shielding":
					return "$%s M  |  %s kg  |  protection level %d" % [_fmt(it["cost_musd"]), _fmt(it["mass_kg"]), it["shield_level"]]
		"comms":
			match it.get("kind", ""):
				"antenna":
					return "$%s M  |  %s kg  |  %s W  |  %s Mbps here" % [_fmt(it["cost_musd"]), _fmt(it["mass_kg"]), _fmt(it["power_w"]),
						_fmt(Sim.downlink_rate_mbps(it, mission))]
				"storage":
					return "$%s M  |  %s kg  |  holds %s Gb" % [_fmt(it["cost_musd"]), _fmt(it["mass_kg"]), _fmt(it["capacity_gb"])]
				"network":
					return "$%s M per year  |  %s h contact per day" % [_fmt(it["cost_musd_year"]), _fmt(it["contact_hours_day"])]
	return ""


## A short reason this card is a bad fit right now ("" = fine).
func _card_problem(sec: Dictionary, it: Dictionary) -> String:
	var mid := MissionState.current_mission_id
	if sec["table"] == "launch_vehicles" and float(it.get("capacity_kg", {}).get(mid, 0)) <= 0.0:
		return "can't reach " + mission.get("name", "")
	var bus := GameData.get_item("buses", MissionState.design.get("bus", ""))
	if bus.get("cubesat", false) and sec["table"] != "buses" and sec["table"] != "launch_vehicles" \
			and it.has("cubesat_ok") and not it.get("cubesat_ok", false):
		return "too big for a CubeSat"
	if it.get("kind", "") == "solar" and mission.get("distance_sun_au", 1.0) >= 9.0:
		return "almost no sunlight here"
	return ""


# ============================================================ info panel

func _update_info(checks: Array) -> void:
	var t := ""
	if not _hovered.is_empty():
		var it: Dictionary = _hovered["item"]
		t += "[b][font_size=20]%s[/font_size][/b]\n%s\n\n" % [it.get("name", ""), it.get("description", "")]
		t += "[color=#9fb4e8]%s[/color]\n\n" % _card_stats(_hovered["sec"], it)
		t += _why(it) + "\n\n"
	var bad: Array = checks.filter(func(c): return not c["passed"])
	if bad.is_empty():
		t += "[color=#5f5][b]All systems GO.[/b][/color] Your design passes every launch check. Head to the Launch Check!"
	else:
		t += "[b]Things to fix (%d):[/b]\n" % bad.size()
		for c in bad:
			t += "[color=#f88]•[/color] %s [color=#9fb4e8](%s)[/color]\n" % [c["message"], _station_def(c["fix_station"])["name"]]
	_info.text = t


## Plain-English "why it matters" for the hovered part.
func _why(it: Dictionary) -> String:
	match it.get("kind", it.get("type", "")):
		"solar":
			return "[i]Why it matters:[/i] sunlight gets weaker with distance squared. At %s it is %d%% of Earth's." % [
				mission.get("name", ""), int(100.0 / pow(mission.get("distance_sun_au", 1.0), 2))]
		"rtg":
			return "[i]Why it matters:[/i] RTGs don't need the Sun, which is why missions like Cassini used them far from it. They are expensive and heavy for the power they give."
		"battery":
			return "[i]Why it matters:[/i] in an orbit's shadow, the battery is the only power source. If it runs out, the spacecraft shuts down."
		"shielding":
			return "[i]Why it matters:[/i] Jupiter's radiation belts are the harshest in the Solar System. Juno keeps its electronics in a titanium vault."
		"antenna":
			return "[i]Why it matters:[/i] the signal spreads out as it travels, so a dish that focuses it is the only way to send lots of data from far away."
		"storage":
			return "[i]Why it matters:[/i] the spacecraft can only send data while a ground station is listening. Memory holds data in between."
		"network":
			return "[i]Why it matters:[/i] more contact hours mean more data reaches Earth, but antenna time costs money every year."
	if it.has("capacity_kg"):
		return "[i]Why it matters:[/i] rockets can carry much less to far destinations than to Earth orbit. The spacecraft AND its fuel must fit."
	if it.has("slots"):
		return "[i]Why it matters:[/i] a bigger frame fits more parts, but its own mass needs more fuel and a bigger rocket."
	if it.has("data_gb_day"):
		return "[i]Why it matters:[/i] each instrument adds science, but also mass, power, cost and data that must be sent home."
	return ""


func _fmt(v) -> String:
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
