# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M6c: mission debrief — the spacecraft slowly rotating in 3D, big score,
# stars that pop in one by one, 3 score bars, NASA look-alike card,
# cause→effect lines from the run, Retry / Next buttons.
# Owner: Member C (Daniel).
extends Node3D

const STARS_MAP := "res://art/planets/2k_stars.jpg"

const END_TITLE := {
	"completed": "MISSION COMPLETE",
	"power_dead": "CONTACT LOST: POWER FAILURE",
	"destroyed": "CONTACT LOST: SPACECRAFT FAILED",
	"aborted": "MISSION ENDED",
}

var design: Dictionary
var result: Dictionary
var mission: Dictionary
var breakdown: Dictionary
var look: Dictionary

var _craft: Node3D
var _recorded := false
var _t := 0.0
var _score_shown := 0
var _stars_shown := 0

var _title: Label
var _score: Label
var _star_row: HBoxContainer
var _star_labels: Array[Label] = []
var _bars := {}
var _look_title: Label
var _look_fact: Label
var _log_list: VBoxContainer
var _best: Label
var _sub: Label


func _ready() -> void:
	design = MissionState.design
	if design.is_empty() or str(design.get("bus", "")) == "":
		design = Sim.make_test_design(MissionState.current_mission_id)
		MissionState.design = design
	result = MissionState.last_result
	if result.is_empty() or not result.has("data_returned_gb"):
		result = _fake_result()
		MissionState.last_result = result
	mission = GameData.get_mission(result.get("mission_id", design.get("mission_id", "mars")))
	breakdown = Sim.score(result)
	look = Sim.find_lookalike(design)
	if not _recorded:
		_recorded = true
		MissionState.record_result(result.get("mission_id", MissionState.current_mission_id), int(breakdown.get("stars", 0)), int(breakdown.get("total", 0)))
	_build_world()
	_build_ui()


func _process(delta: float) -> void:
	_t += delta
	if _craft:
		_craft.rotate_y(delta * 0.35)
	var total := int(breakdown.get("total", 0))
	if _score_shown < total:
		_score_shown = mini(total, _score_shown + maxi(1, int(ceil(total * delta * 1.5))))
		_score.text = str(_score_shown)
	var want_stars := 0
	if _t > 0.5:
		want_stars = clampi(int((_t - 0.5) / 0.45) + 1, 1, 3)
		want_stars = mini(want_stars, int(breakdown.get("stars", 0)))
	while _stars_shown < want_stars and _stars_shown < 3:
		_pop_star(_stars_shown)
		_stars_shown += 1


func _pop_star(i: int) -> void:
	var l := _star_labels[i]
	l.modulate = Color(1.0, 0.80, 0.25)
	l.scale = Vector2(1.8, 1.8)
	l.pivot_offset = l.size * 0.5
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("go", -6.0)


func _fake_result() -> Dictionary:
	var s := Sim.summarize(design)
	return {
		"mission_id": design.get("mission_id", MissionState.current_mission_id),
		"end_reason": "completed",
		"data_returned_gb": s["est_total_data_gb"],
		"data_goal_gb": s["data_goal_gb"],
		"science_bonus": 0,
		"lifetime_years": float(design.get("target_years", 1.0)),
		"target_years": float(design.get("target_years", 1.0)),
		"reserve_left_musd": s["reserve_musd"],
		"budget_musd": s["budget_musd"],
		"log": [],
	}


# ===================================================================== world

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var tex: Texture2D = null
	if ResourceLoader.exists(STARS_MAP):
		tex = load(STARS_MAP) as Texture2D
	if tex != null:
		var sky := Sky.new()
		var sm := PanoramaSkyMaterial.new()
		sm.panorama = tex
		sky.sky_material = sm
		env.background_mode = Environment.BG_SKY
		env.sky = sky
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.015, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.28, 0.45)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25, -35, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.6
	sun.shadow_enabled = false
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(18, 145, 0)
	fill.light_color = Color(0.45, 0.60, 1.0)
	fill.light_energy = 0.25
	fill.shadow_enabled = false
	add_child(fill)

	var mid := str(result.get("mission_id", design.get("mission_id", "mars")))
	var planet := MenuPlanet.make(mid)
	if planet:
		planet.name = "Backdrop"
		planet.position = Vector3(7.5, 1.5, -12.0)
		planet.scale = Vector3.ONE * 4.0
		add_child(planet)

	_craft = SpacecraftModel3D.build(design)
	_craft.name = "Spacecraft"
	_craft.position = Vector3(2.2, 0.4, 0)
	_craft.rotation = Vector3(0.1, 0.6, 0.08)
	add_child(_craft)
	SpacecraftModel3D.deploy_wings(_craft, 1.0)

	var cam := Camera3D.new()
	cam.fov = 50
	cam.position = Vector3(2.2, 1.1, 7.2)
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(2.2, 0.4, 0), Vector3.UP)


# ===================================================================== UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var title := Label.new()
	title.text = "%s  ·  %s" % [str(mission.get("name", "")).to_upper(), str(mission.get("destination", "")).to_upper()]
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.70, 0.82, 1.0))
	title.position = Vector2(40, 26)
	root.add_child(title)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 40
	panel.offset_top = -300
	panel.offset_right = 560
	panel.offset_bottom = 300
	panel.custom_minimum_size = Vector2(520, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.10, 0.88)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	_title = Label.new()
	_title.text = str(END_TITLE.get(result.get("end_reason", "completed"), "MISSION OVER"))
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55) if result.get("end_reason", "completed") == "completed" else Color(1.0, 0.45, 0.40))
	box.add_child(_title)

	_score = Label.new()
	_score.text = "0"
	_score.add_theme_font_size_override("font_size", 84)
	_score.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	box.add_child(_score)

	_star_row = HBoxContainer.new()
	_star_row.add_theme_constant_override("separation", 8)
	box.add_child(_star_row)
	for i in 3:
		var l := Label.new()
		l.text = "★"
		l.add_theme_font_size_override("font_size", 44)
		l.modulate = Color(0.30, 0.32, 0.38)
		_star_row.add_child(l)
		_star_labels.append(l)

	_sub = Label.new()
	_sub.text = "DATA %s / %s Gb  ·  %s" % [_fmt(result.get("data_returned_gb", 0.0)), _fmt(result.get("data_goal_gb", 0.0)), _reason_line()]
	_sub.add_theme_font_size_override("font_size", 16)
	_sub.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	box.add_child(_sub)

	for key in ["science", "survival", "budget"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var name := Label.new()
		name.text = key.capitalize()
		name.custom_minimum_size = Vector2(90, 0)
		name.add_theme_font_size_override("font_size", 16)
		row.add_child(name)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = int(breakdown.get(key, 0))
		bar.custom_minimum_size = Vector2(280, 20)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = false
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.16, 0.19, 0.27)
		bg.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("background", bg)
		var fill_sb := StyleBoxFlat.new()
		fill_sb.bg_color = {"science": Color(0.30, 0.75, 1.0), "survival": Color(0.35, 1.0, 0.55), "budget": Color(1.0, 0.80, 0.25)}[key]
		fill_sb.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("fill", fill_sb)
		row.add_child(bar)
		var val := Label.new()
		val.text = str(int(breakdown.get(key, 0)))
		val.custom_minimum_size = Vector2(40, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.add_theme_font_size_override("font_size", 16)
		row.add_child(val)
		_bars[key] = bar

	var look_panel := PanelContainer.new()
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color(0.08, 0.12, 0.20, 0.9)
	lsb.set_corner_radius_all(12)
	lsb.set_content_margin_all(14)
	look_panel.add_theme_stylebox_override("panel", lsb)
	box.add_child(look_panel)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 4)
	look_panel.add_child(lbox)
	_look_title = Label.new()
	_look_title.text = "YOUR MISSION IS LIKE %s (%d)" % [str(look.get("name", "—")).to_upper(), int(look.get("year", 0))]
	_look_title.add_theme_font_size_override("font_size", 17)
	_look_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	_look_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbox.add_child(_look_title)
	_look_fact = Label.new()
	_look_fact.text = str(look.get("fact", ""))
	_look_fact.add_theme_font_size_override("font_size", 15)
	_look_fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbox.add_child(_look_fact)

	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 4)
	box.add_child(_log_list)
	for line in _pick_log_lines():
		var l := Label.new()
		l.text = "•  " + line
		l.add_theme_font_size_override("font_size", 15)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_log_list.add_child(l)

	var best_stars := int(MissionState.campaign.get("stars", {}).get(result.get("mission_id", ""), 0))
	var best_score := int(MissionState.campaign.get("best_score", {}).get(result.get("mission_id", ""), 0))
	_best = Label.new()
	_best.text = "BEST: %d / 100  ·  %d/3 STARS" % [best_score, best_stars]
	_best.add_theme_font_size_override("font_size", 15)
	_best.add_theme_color_override("font_color", Color(0.65, 0.75, 0.90))
	box.add_child(_best)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	box.add_child(btns)
	var retry := Button.new()
	retry.text = "↻  Redesign & retry"
	retry.add_theme_font_size_override("font_size", 20)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(func(): MissionState.go_to("hangar"))
	btns.add_child(retry)
	var nxt := Button.new()
	nxt.text = "Next mission  →"
	nxt.add_theme_font_size_override("font_size", 20)
	nxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nxt.pressed.connect(func(): MissionState.go_to("campaign_map"))
	btns.add_child(nxt)


func _reason_line() -> String:
	return {
		"completed": "Planned lifetime reached",
		"power_dead": "Batteries ran out",
		"destroyed": "Spacecraft failed",
		"aborted": "Ended by the Director",
	}.get(result.get("end_reason", "completed"), "")


func _fmt(v: float) -> String:
	if v >= 1000.0:
		return "%d" % int(round(v))
	if v >= 100.0:
		return "%.0f" % v
	return "%.1f" % v


func _pick_log_lines() -> Array[String]:
	var out: Array[String] = []
	var log: Array = result.get("log", [])
	var tail := log.slice(maxi(0, log.size() - 3))
	for entry in tail:
		var text := str(entry.get("text", ""))
		if text == "":
			var cause := str(entry.get("cause", ""))
			var effect := str(entry.get("effect", ""))
			if cause != "" and effect != "":
				text = "%s → %s" % [cause, effect]
			elif cause != "":
				text = cause
		if text != "":
			out.append(text)
	if out.is_empty():
		out.append("A quiet cruise — no major events this time.")
	return out
