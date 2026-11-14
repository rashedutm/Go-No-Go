# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M6c: mission debrief — neon HUD mission report (Barlow Condensed / Barlow /
# IBM Plex Mono), 3D spacecraft + planet, animated score, stars, flight recorder.
# Owner: Member C (Daniel).
extends Node3D

const STARS_MAP := "res://art/planets/2k_stars.jpg"

var design: Dictionary
var result: Dictionary
var mission: Dictionary
var breakdown: Dictionary
var look: Dictionary
var verdict: Dictionary

var _craft: Node3D
var _recorded := false
var _t := 0.0
var _score_shown := 0
var _stars_shown := 0

var _score: Label
var _star_labels: Array[Label] = []
var _best: Label


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
	verdict = _verdict()
	if not _recorded:
		_recorded = true
		MissionState.record_result(result.get("mission_id", MissionState.current_mission_id), int(breakdown.get("stars", 0)), int(breakdown.get("total", 0)))
	_build_world()
	_build_ui()


func _process(delta: float) -> void:
	_t += delta
	if _craft:
		_craft.rotate_y(delta * 0.32)
	var total := int(breakdown.get("total", 0))
	if _score_shown < total:
		_score_shown = mini(total, _score_shown + maxi(1, int(ceil(total * delta * 1.6))))
		_score.text = "%03d" % _score_shown
	if _t > 0.45:
		var want := clampi(int((_t - 0.45) / 0.4) + 1, 1, 3)
		want = mini(want, int(breakdown.get("stars", 0)))
		while _stars_shown < want and _stars_shown < 3:
			_pop_star(_stars_shown)
			_stars_shown += 1


func _pop_star(i: int) -> void:
	var l := _star_labels[i]
	l.text = "★"
	l.add_theme_color_override("font_color", NeonUI.GOLD)
	l.scale = Vector2(1.9, 1.9)
	l.pivot_offset = l.size * 0.5
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("beep", -9.0)


func _verdict() -> Dictionary:
	match str(result.get("end_reason", "completed")):
		"power_dead":
			return {"title": "CONTACT LOST", "reason": "POWER FAILURE",
				"detail": "Battery depleted before the planned mission lifetime was reached.", "color": NeonUI.RED}
		"destroyed":
			return {"title": "CONTACT LOST", "reason": "SPACECRAFT FAILED",
				"detail": "The spacecraft was lost before it could complete its mission.", "color": NeonUI.RED}
		"aborted":
			return {"title": "MISSION ENDED", "reason": "DIRECTOR ABORT",
				"detail": "The mission was ended early by the flight director.", "color": NeonUI.GOLD}
		_:
			return {"title": "MISSION COMPLETE", "reason": "OBJECTIVES MET",
				"detail": "The spacecraft completed its planned mission and returned its science data.", "color": NeonUI.GREEN}


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


# ===================================================================== 3D

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
		planet.position = Vector3(9.0, 1.6, -13.0)
		planet.scale = Vector3.ONE * 4.2
		add_child(planet)

	_craft = SpacecraftModel3D.build(design)
	_craft.name = "Spacecraft"
	_craft.position = Vector3(6.5, 0.4, 0)
	_craft.rotation = Vector3(0.1, 0.6, 0.08)
	_craft.scale = Vector3.ONE * 1.25
	add_child(_craft)
	SpacecraftModel3D.deploy_wings(_craft, 1.0)

	var cam := Camera3D.new()
	cam.fov = 50
	cam.position = Vector3(4.5, 1.2, 7.4)
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(4.5, 0.4, 0), Vector3.UP)


# ===================================================================== UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var card := NeonUI.panel("cyan", 18)
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.offset_left = 28
	card.offset_top = 20
	card.offset_right = 588
	card.offset_bottom = 600
	root.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	# --- header: hazard stripes + mission line
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	box.add_child(hdr)
	hdr.add_child(NeonUI.stripes(NeonUI.GOLD))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr.add_child(hv)
	hv.add_child(NeonUI.heading(_mission_line(), 20))
	hv.add_child(NeonUI.kicker("MISSION REPORT", NeonUI.MUTED, 10))
	box.add_child(NeonUI.rule())

	# --- verdict
	var verdict_row := HBoxContainer.new()
	verdict_row.add_theme_constant_override("separation", 12)
	box.add_child(verdict_row)
	verdict_row.add_child(NeonUI.accent(verdict.get("color", NeonUI.RED), 4.0))
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 1)
	verdict_row.add_child(vv)
	var vt := Label.new()
	NeonUI.display(vt, 40, verdict.get("color", NeonUI.RED))
	vt.text = str(verdict.get("title", ""))
	vv.add_child(vt)
	var vr := Label.new()
	NeonUI.heading(vr, 16, verdict.get("color", NeonUI.RED))
	vr.text = str(verdict.get("reason", ""))
	vv.add_child(vr)
	var vd := Label.new()
	NeonUI.body(vd, 13, NeonUI.MUTED, true)
	vd.text = str(verdict.get("detail", ""))
	vd.custom_minimum_size.x = 500
	vv.add_child(vd)
	box.add_child(NeonUI.rule())

	# --- score + stars
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 18)
	box.add_child(score_row)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 0)
	score_row.add_child(sv)
	sv.add_child(NeonUI.kicker("MISSION SCORE", NeonUI.MUTED, 10))
	_score = Label.new()
	NeonUI.display(_score, 56, NeonUI.GOLD)
	_score.text = "000"
	sv.add_child(_score)
	var star_v := VBoxContainer.new()
	star_v.add_theme_constant_override("separation", 2)
	star_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star_v.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_child(star_v)
	var star_row := HBoxContainer.new()
	star_row.add_theme_constant_override("separation", 6)
	star_v.add_child(star_row)
	for i in 3:
		var l := Label.new()
		l.text = "☆"
		NeonUI.heading(l, 32, NeonUI.DIM)
		star_row.add_child(l)
		_star_labels.append(l)
	_best = Label.new()
	NeonUI.mono_regular(_best, 11, NeonUI.MUTED)
	_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best.text = _best_line()
	star_v.add_child(_best)

	var data := HBoxContainer.new()
	box.add_child(data)
	data.add_child(NeonUI.kicker("DATA ACQUIRED", NeonUI.MUTED, 10))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data.add_child(spacer)
	var dv := Label.new()
	NeonUI.mono(dv, 13, NeonUI.TEXT)
	dv.text = "%s / %s GB" % [_fmt(result.get("data_returned_gb", 0.0)), _fmt(result.get("data_goal_gb", 0.0))]
	data.add_child(dv)
	box.add_child(NeonUI.rule())

	# --- score breakdown rows (mono values, like a telemetry panel)
	for key in ["science", "survival", "budget"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var k := Label.new()
		NeonUI.caption(k, 13, NeonUI.MUTED)
		k.text = key.to_upper()
		row.add_child(k)
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)
		var v := Label.new()
		NeonUI.mono(v, 15, NeonUI.TEXT)
		v.text = "%02d" % int(breakdown.get(key, 0))
		row.add_child(v)
		box.add_child(NeonUI.rule(Color(0.31, 0.84, 1.0, 0.12)))

	# --- flight recorder
	var rec_hdr := HBoxContainer.new()
	rec_hdr.add_theme_constant_override("separation", 10)
	box.add_child(rec_hdr)
	var tag := NeonUI.panel("gold", 7)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rec_hdr.add_child(tag)
	var tag_l := Label.new()
	NeonUI.mono(tag_l, 10, Color(0.05, 0.06, 0.10))
	tag_l.text = "FLIGHT RECORDER"
	tag.add_child(tag_l)
	var rec_rule := NeonUI.rule(NeonUI.CYAN_DIM)
	rec_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rec_hdr.add_child(rec_rule)
	for entry in _log_entries():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var dot := ColorRect.new()
		dot.color = entry["color"]
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var ts := Label.new()
		NeonUI.mono(ts, 11, NeonUI.CYAN)
		ts.text = "T+%03dd" % int(entry["day"])
		row.add_child(ts)
		var msg := Label.new()
		NeonUI.mono_regular(msg, 12, NeonUI.TEXT)
		msg.text = str(entry["text"])
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(msg)

	box.add_child(NeonUI.rule())
	# --- closest real mission, as the report's "real mission file" card
	var look_card := NeonUI.panel("cyan", 10)
	box.add_child(look_card)
	var lb := VBoxContainer.new()
	lb.add_theme_constant_override("separation", 1)
	look_card.add_child(lb)
	lb.add_child(NeonUI.kicker("CLOSEST REAL MISSION · NASA FILE", NeonUI.GOLD, 10))
	lb.add_child(NeonUI.heading("%s (%d)" % [str(look.get("name", "—")).to_upper(), int(look.get("year", 0))], 16, NeonUI.GOLD))
	var fact := Label.new()
	NeonUI.body(fact, 12, NeonUI.TEXT, true)
	fact.text = str(look.get("fact", ""))
	lb.add_child(fact)

	# --- actions
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	box.add_child(btns)
	var retry := Button.new()
	retry.text = "RETRY MISSION"
	NeonUI.primary(retry, 18)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(func(): MissionState.go_to("hangar"))
	btns.add_child(retry)
	var nxt := Button.new()
	nxt.text = "NEXT MISSION  →"
	NeonUI.ghost(nxt, 17)
	nxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nxt.pressed.connect(func(): MissionState.go_to("campaign_map"))
	btns.add_child(nxt)


func _mission_line() -> String:
	return "MISSION %02d  /  %s" % [int(mission.get("order", 0)), str(mission.get("name", "")).to_upper()]


func _best_line() -> String:
	var best_stars := int(MissionState.campaign.get("stars", {}).get(result.get("mission_id", ""), 0))
	var best_score := int(MissionState.campaign.get("best_score", {}).get(result.get("mission_id", ""), 0))
	return "BEST %03d  ·  %d/3 STARS" % [best_score, best_stars]


func _fmt(v: float) -> String:
	if v >= 1000.0:
		return "%d" % int(round(v))
	if v >= 100.0:
		return "%.0f" % v
	return "%.1f" % v


func _log_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
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
			elif effect != "":
				text = effect
		if text == "":
			continue
		var lower := text.to_lower()
		var color := NeonUI.CYAN
		if lower.contains("storm") or lower.contains("fail") or lower.contains("lost") or lower.contains("battery") or lower.contains("damage") or lower.contains("blackout") or lower.contains("error"):
			color = NeonUI.RED
		elif lower.contains("discover") or lower.contains("bonus") or lower.contains("science") or lower.contains("opportunity"):
			color = NeonUI.GOLD
		out.append({"day": int(entry.get("day", 0)), "text": text, "color": color})
	if out.is_empty():
		out.append({"day": 0, "text": "NO ANOMALIES RECORDED — NOMINAL CRUISE", "color": NeonUI.CYAN})
	return out
