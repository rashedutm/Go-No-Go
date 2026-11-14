# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Temporary screen used by the M1 skeleton so the whole game flow is clickable.
# Each real screen replaces its placeholder in a later milestone. Owner: Member A.
extends Control

@export var screen_key: String = "title"

var _body: RichTextLabel
var _buttons: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	var title := Label.new()
	title.text = _title()
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)

	var tag := Label.new()
	tag.text = "[placeholder — milestone M1 skeleton]"
	tag.modulate = Color(1, 0.75, 0.3)
	box.add_child(tag)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(panel)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.scroll_active = true
	panel.add_child(_body)

	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	box.add_child(_buttons)

	_fill()


func _title() -> String:
	return {
		"title": "GO / NO-GO",
		"campaign_map": "Campaign Map",
		"briefing": "Mission Briefing",
		"design": "Design Your Spacecraft",
		"launch_check": "Launch Check: Go or No-Go?",
		"launch_anim": "Launch!",
		"mission_control": "Live Mission Control",
		"debrief": "Mission Debrief",
	}.get(screen_key, screen_key)


func _add_button(text: String, target: String, callback: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func():
		if callback.is_valid():
			callback.call()
		if target != "":
			MissionState.go_to(target))
	_buttons.add_child(b)
	return b


func _fill() -> void:
	var mission := GameData.get_mission(MissionState.current_mission_id)
	match screen_key:
		"title":
			_body.text = "\"Go/No-Go\" is the call every flight controller makes before launch.\nDesign a real space mission, fly it live, and earn your GO.\n\n" \
				+ "Loaded data: %d missions, %d instruments, %d launchers." % [
					GameData.get_table("missions").size(), GameData.get_table("instruments").size(),
					GameData.get_table("launch_vehicles").size()]
			_add_button("Play", "campaign_map")
			_add_button("Reset progress", "", func(): MissionState.reset_progress())

		"campaign_map":
			_body.text = "Pick a mission. Earn at least 1 star to unlock the next one."
			for m in GameData.get_missions_in_order():
				var id: String = m["id"]
				var stars := int(MissionState.campaign["stars"].get(id, 0))
				var b := _add_button("%d. %s %s" % [m["order"], m["name"], "★".repeat(stars)], "briefing",
					func(): MissionState.start_mission(id))
				b.disabled = not MissionState.is_unlocked(id)
			_add_button("Back", "title")

		"briefing":
			_body.text = "[b]%s — %s[/b]\n\n%s\n\n%s\n\nBudget: $%d M   •   Lifetime: %d years   •   Data goal: %d Gb\nRequired instrument types: %s\n\n[i]Did you know? %s[/i]" % [
				mission.get("name", ""), mission.get("destination", ""), mission.get("objective", ""),
				mission.get("description", ""), mission.get("budget_musd", 0), mission.get("min_years", 0),
				mission.get("data_goal_gb", 0), ", ".join(mission.get("required_types", [])), mission.get("fact", "")]
			_add_button("Back", "campaign_map")
			_add_button("Design spacecraft", "design")

		"design":
			_body.text = "The real 4-station design screen comes in M2.\nFor now, use the built-in test design for this mission.\n\n" + _summary_text()
			_add_button("Back", "briefing")
			_add_button("Use test design", "", func():
				MissionState.design = Sim.make_test_design(MissionState.current_mission_id)
				MissionState.design_changed.emit()
				_body.text = "Test design loaded.\n\n" + _summary_text())
			_add_button("Go to launch check", "launch_check")

		"launch_check":
			var lines: Array = []
			for c in Sim.launch_check(MissionState.design):
				lines.append(("[color=#5f5]GO[/color]  " if c["passed"] else "[color=#f66]NO-GO[/color]  ") + c["message"])
			var go := Sim.is_go(MissionState.design)
			_body.text = "\n".join(lines) + ("\n\n[b]FLIGHT DIRECTOR: GO FOR LAUNCH![/b]" if go else "\n\n[b]NO-GO. Fix the red items.[/b]")
			_add_button("Back to design", "design")
			var launch := _add_button("Launch", "launch_anim")
			launch.disabled = not go

		"launch_anim":
			_body.text = "3… 2… 1… Liftoff!\n(The launch & cruise animation is a stretch goal.)"
			_add_button("Arrive at destination", "mission_control")

		"mission_control":
			_body.text = "Member B (Emon) builds the real Live Mission Control here.\nThis placeholder fakes a finished mission using the design estimate."
			_add_button("Finish mission (fake)", "debrief", func(): _fake_result())

		"debrief":
			var r := MissionState.last_result
			var s := Sim.score(r)
			var look := Sim.find_lookalike(MissionState.design)
			_body.text = "Score: %d   %s\nScience %d  •  Survival %d  •  Budget %d\n\nYour mission is like [b]%s[/b] (%s): %s" % [
				s["total"], "★".repeat(s["stars"]) if s["stars"] > 0 else "(failed)", s["science"], s["survival"], s["budget"],
				look.get("name", "—"), str(look.get("year", "")), look.get("fact", "")]
			MissionState.record_result(r.get("mission_id", MissionState.current_mission_id), s["stars"], s["total"])
			_add_button("Redesign & retry", "design")
			_add_button("Next mission", "campaign_map")


func _summary_text() -> String:
	if MissionState.design.is_empty():
		return "(no design yet)"
	var s := Sim.summarize(MissionState.design)
	return "Cost $%d M / $%d M\nLaunch mass %d kg (dry %d + fuel %d) / rocket max %d kg\nPower %d W made, %d W used\nBattery %d Wh (shadow needs %d Wh)\nData %.1f Gb/day made, %.1f Gb/day sent → about %d Gb total (goal %d)\nSignal delay %.1f min" % [
		s["total_cost_musd"], s["budget_musd"], s["wet_mass_kg"], s["dry_mass_kg"], s["propellant_kg"], s["launcher_capacity_kg"],
		s["power_gen_w"], s["power_load_w"], s["battery_wh"], s["eclipse_need_wh"],
		s["data_per_day_gb"], s["downlink_per_day_gb"], s["est_total_data_gb"], s["data_goal_gb"], s["signal_delay_min"]]


func _fake_result() -> void:
	var s := Sim.summarize(MissionState.design)
	MissionState.last_result = {
		"mission_id": MissionState.current_mission_id,
		"end_reason": "completed",
		"data_returned_gb": s["est_total_data_gb"],
		"data_goal_gb": s["data_goal_gb"],
		"science_bonus": 0,
		"lifetime_years": float(MissionState.design.get("target_years", 1.0)),
		"target_years": float(MissionState.design.get("target_years", 1.0)),
		"reserve_left_musd": s["reserve_musd"],
		"budget_musd": s["budget_musd"],
		"log": [],
	}
