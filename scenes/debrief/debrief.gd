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
	_craft.position = Vector3(4.4, 0.4, 0)
	_craft.rotation = Vector3(0.1, 0.6, 0.08)
	add_child(_craft)
	SpacecraftModel3D.deploy_wings(_craft, 1.0)

	var cam := Camera3D.new()
	cam.fov = 50
	# Camera sits left of the craft so the report card's 3D subject renders
	# in the clear strip right of the panel.
	cam.position = Vector3(2.6, 1.1, 7.2)
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(2.6, 0.4, 0), Vector3.UP)


# ===================================================================== UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# --- report card, left column
	var panel := CineUI.glass(24)
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 36
	panel.offset_top = -336
	panel.offset_right = 616
	panel.offset_bottom = 336
	panel.custom_minimum_size = Vector2(580, 0)
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	# 1 — header: what this is, then the verdict
	var ok: bool = str(result.get("end_reason", "completed")) == "completed"
	box.add_child(CineUI.kicker("◆ Mission debrief  ·  " + str(mission.get("name", "")).to_upper()))
	_title = CineUI.headline(str(END_TITLE.get(result.get("end_reason", "completed"), "MISSION OVER")), 30, CineUI.GOOD if ok else CineUI.BAD)
	box.add_child(_title)
	box.add_child(CineUI.rule())

	# 2 — hero: score + stars side by side
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 24)
	hero.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_child(hero)
	_score = CineUI.headline("0", 84, CineUI.GOLD)
	_score.custom_minimum_size = Vector2(150, 0)
	hero.add_child(_score)
	var heroright := VBoxContainer.new()
	heroright.add_theme_constant_override("separation", 6)
	heroright.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(heroright)
	_star_row = HBoxContainer.new()
	_star_row.add_theme_constant_override("separation", 8)
	heroright.add_child(_star_row)
	for i in 3:
		var l := Label.new()
		l.text = "★"
		l.add_theme_font_size_override("font_size", 44)
		l.modulate = Color(0.30, 0.32, 0.38)
		_star_row.add_child(l)
		_star_labels.append(l)
	_sub = CineUI.body("DATA %s / %s Gb  ·  %s" % [_fmt(result.get("data_returned_gb", 0.0)), _fmt(result.get("data_goal_gb", 0.0)), _reason_line()], 16)
	heroright.add_child(_sub)
	box.add_child(CineUI.rule())

	# 3 — score breakdown
	for key in ["science", "survival", "budget"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var name := Label.new()
		name.text = key.capitalize()
		name.custom_minimum_size = Vector2(80, 0)
		name.add_theme_font_size_override("font_size", 16)
		name.add_theme_color_override("font_color", CineUI.TEXT)
		row.add_child(name)
		var bar := CineUI.meter({"science": Color(0.30, 0.75, 1.0), "survival": Color(0.35, 1.0, 0.55), "budget": CineUI.GOLD}[key])
		bar.value = int(breakdown.get(key, 0))
		row.add_child(bar)
		var val := Label.new()
		val.text = str(int(breakdown.get(key, 0)))
		val.custom_minimum_size = Vector2(40, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.add_theme_font_size_override("font_size", 16)
		val.add_theme_color_override("font_color", CineUI.TEXT)
		row.add_child(val)
		_bars[key] = bar

	# 4 — look-alike card, gold-trimmed
	var look_panel := CineUI.card(Color(1.0, 0.80, 0.30, 0.45))
	box.add_child(look_panel)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 4)
	look_panel.add_child(lbox)
	lbox.add_child(CineUI.kicker(" Closest real NASA mission"))
	_look_title = CineUI.headline("%s (%d)" % [str(look.get("name", "—")), int(look.get("year", 0))], 20, CineUI.GOLD)
	_look_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbox.add_child(_look_title)
	_look_fact = CineUI.body(str(look.get("fact", "")), 15)
	lbox.add_child(_look_fact)

	# 5 — flight log
	box.add_child(CineUI.kicker(" Flight log", CineUI.CYAN))
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 4)
	box.add_child(_log_list)
	for line in _pick_log_lines():
		var l := CineUI.body("•  " + line, 15)
		_log_list.add_child(l)

	var best_stars := int(MissionState.campaign.get("stars", {}).get(result.get("mission_id", ""), 0))
	var best_score := int(MissionState.campaign.get("best_score", {}).get(result.get("mission_id", ""), 0))
	_best = CineUI.body("BEST: %d / 100  ·  %d/3 STARS" % [best_score, best_stars], 15)
	box.add_child(_best)

	# 6 — actions: primary next, secondary retry
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	box.add_child(btns)
	var retry := Button.new()
	retry.text = "↻  Redesign & retry"
	CineUI.ghost(retry)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(func(): MissionState.go_to("hangar"))
	btns.add_child(retry)
	var nxt := Button.new()
	nxt.text = "Next mission  →"
	CineUI.primary(nxt)
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
