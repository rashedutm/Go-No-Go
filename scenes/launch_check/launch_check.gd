# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M3 Go/No-Go poll: night launch pad in 3D; the Flight Director polls the 4 stations one by one.
# Each station calls GO (green) or NO-GO (red + reason + "Fix it" button back to that hangar station).
# Four GOs unlock LAUNCH. Uses Sim.launch_check(). Owner: Member A.
extends Node3D

const C_GOOD := Color(0.3, 0.95, 0.45)
const C_BAD := Color(1.0, 0.33, 0.3)
const C_WAIT := Color(1.0, 0.75, 0.2)
const POLL_ORDER := ["engineer", "science", "comms", "director"]
const STEP_TIME := 1.1

var _cam: Camera3D
var _t := 0.0
var _rows := {}
var _status: Label
var _launch_btn: Button
var _skip := false
var _results := {}   # station -> Array of failed checks
var _beacon: OmniLight3D


func _ready() -> void:
	var mid := MissionState.current_mission_id
	if MissionState.design.get("mission_id", "") != mid:
		MissionState.start_mission(mid)
	_compute()
	_build_world()
	_build_ui()
	_run_poll()


func _compute() -> void:
	for st in POLL_ORDER:
		_results[st] = []
	for c in Sim.launch_check(MissionState.design):
		if not c["passed"]:
			_results[c["fix_station"]].append(c)


# ===================================================================== 3D launch pad at night

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.3, 0.5)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.1, 0.2)
	env.fog_density = 0.012
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35, 140, 0)
	moon.light_color = Color(0.6, 0.7, 1.0)
	moon.light_energy = 0.5
	moon.shadow_enabled = true
	add_child(moon)

	# stars
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 220:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.05, 1), rng.randf_range(-1, -0.1)).normalized()
		var star := SpacecraftModel3D._sphere(rng.randf_range(0.08, 0.22), Color(1, 1, 1), true)
		star.position = dir * 160.0
		add_child(star)

	# ground + pad
	add_child(_at(SpacecraftModel3D._box(Vector3(400, 0.2, 400), Color(0.08, 0.1, 0.09), 0.0, 0.9), Vector3(0, -0.1, 0)))
	add_child(_at(SpacecraftModel3D._box(Vector3(18, 1.0, 18), Color(0.4, 0.4, 0.42), 0.2, 0.8), Vector3(0, 0.5, 0)))
	add_child(_at(SpacecraftModel3D._box(Vector3(5, 0.3, 5), Color(0.2, 0.2, 0.22), 0.5, 0.6), Vector3(0, 1.15, 0)))

	# rocket (scaled up to "real" pad size) and tower
	var lv := str(MissionState.design.get("launch_vehicle", ""))
	var rocket := SpacecraftModel3D.build_rocket(lv if lv != "" else "medium")
	rocket.position = Vector3(0, 1.3, 0)
	rocket.scale = Vector3.ONE * 2.2
	add_child(rocket)
	var red := Color(0.7, 0.2, 0.12)
	add_child(_at(SpacecraftModel3D._box(Vector3(2.2, 40, 2.2), red, 0.4, 0.6), Vector3(-7.5, 20, 0)))
	for y in range(4, 40, 5):
		add_child(_at(SpacecraftModel3D._box(Vector3(4.5, 0.4, 0.6), red, 0.4, 0.6), Vector3(-4.6, y, 0)))

	# floodlights
	for p in [Vector3(14, 3, 14), Vector3(-14, 3, 12), Vector3(12, 3, -14)]:
		var l := SpotLight3D.new()
		l.position = p
		l.look_at_from_position(p, Vector3(0, 14, 0), Vector3.UP)
		l.spot_range = 60
		l.spot_angle = 22
		l.light_energy = 6.0
		l.light_color = Color(1, 0.95, 0.85)
		add_child(l)
		add_child(_at(SpacecraftModel3D._box(Vector3(1, 1, 1), Color(1, 1, 0.9), 0.0, 0.3), p))

	# beacon light on the tower that turns green/red with the poll result
	_beacon = OmniLight3D.new()
	_beacon.position = Vector3(-7.5, 41, 0)
	_beacon.omni_range = 18
	_beacon.light_energy = 3.0
	_beacon.light_color = C_WAIT
	add_child(_beacon)

	_cam = Camera3D.new()
	_cam.fov = 50
	_cam.h_offset = -11.0
	add_child(_cam)


func _process(delta: float) -> void:
	_t += delta
	# slow dolly around the rocket
	var a := 0.6 + _t * 0.04
	var d := lerpf(70.0, 52.0, clampf(_t / 12.0, 0.0, 1.0))
	_cam.position = Vector3(sin(a) * d, 12.0, cos(a) * d)
	_cam.look_at(Vector3(0, 17, 0), Vector3.UP)
	if _beacon.light_color == C_WAIT:
		_beacon.light_energy = 2.0 + sin(_t * 8.0) * 1.5


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		_skip = true   # click / key fast-forwards the poll


# ===================================================================== UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var title := Label.new()
	title.text = "GO / NO-GO POLL"
	title.add_theme_font_size_override("font_size", 40)
	title.position = Vector2(40, 28)
	root.add_child(title)
	var sub := Label.new()
	sub.text = "%s  ·  %s" % [GameData.get_mission(MissionState.current_mission_id).get("name", ""), GameData.get_mission(MissionState.current_mission_id).get("destination", "")]
	sub.modulate = Color(0.7, 0.8, 1.0)
	sub.position = Vector2(42, 80)
	root.add_child(sub)

	var panel := PanelContainer.new()
	panel.position = Vector2(40, 130)
	panel.custom_minimum_size = Vector2(620, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.1, 0.82)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	panel.add_child(list)

	for st in POLL_ORDER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.modulate.a = 0.35
		list.add_child(row)
		var light := Panel.new()
		light.custom_minimum_size = Vector2(22, 22)
		light.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var lsb := StyleBoxFlat.new()
		lsb.bg_color = Color(0.3, 0.3, 0.35)
		lsb.set_corner_radius_all(11)
		light.add_theme_stylebox_override("panel", lsb)
		row.add_child(light)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 0)
		row.add_child(text)
		var who := Label.new()
		who.text = PartInfo.station(st)["long"].to_upper()
		who.add_theme_font_size_override("font_size", 15)
		who.modulate = Color(0.65, 0.75, 0.95)
		text.add_child(who)
		var call_l := Label.new()
		call_l.text = "standing by…"
		call_l.add_theme_font_size_override("font_size", 22)
		call_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		call_l.custom_minimum_size.x = 420
		text.add_child(call_l)
		var fix := Button.new()
		fix.text = "Fix it"
		fix.visible = false
		fix.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var station_key: String = st
		fix.pressed.connect(func():
			MissionState.set_meta("design_station", station_key)
			MissionState.go_to("hangar"))
		row.add_child(fix)
		_rows[st] = {"row": row, "light": lsb, "call": call_l, "fix": fix}

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 30)
	_status.position = Vector2(40, 560)
	_status.custom_minimum_size.x = 800
	root.add_child(_status)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom.offset_left = -520
	bottom.offset_top = -96
	bottom.offset_right = -32
	bottom.offset_bottom = -28
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	var back := Button.new()
	back.text = "< Hangar"
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): MissionState.go_to("hangar"))
	bottom.add_child(back)
	_launch_btn = Button.new()
	_launch_btn.text = "LAUNCH!"
	_launch_btn.custom_minimum_size = Vector2(240, 68)
	_launch_btn.add_theme_font_size_override("font_size", 30)
	_launch_btn.disabled = true
	_launch_btn.pressed.connect(func(): MissionState.go_to("launch_anim"))
	bottom.add_child(_launch_btn)


# ===================================================================== the poll

func _wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()


func _run_poll() -> void:
	_status.text = "Flight Director: \"All stations, go/no-go for launch.\""
	_status.modulate = C_WAIT
	await _wait(1.4)
	var nogo := 0
	for st in POLL_ORDER:
		var r: Dictionary = _rows[st]
		r["row"].modulate.a = 1.0
		r["light"].bg_color = C_WAIT
		r["call"].text = "checking…"
		r["call"].modulate = C_WAIT
		Sfx.play("beep", -6.0)
		await _wait(STEP_TIME * 0.6)
		var fails: Array = _results[st]
		if fails.is_empty():
			r["light"].bg_color = C_GOOD
			r["call"].text = "GO!"
			Sfx.play("go", -4.0)
			r["call"].modulate = C_GOOD
		else:
			nogo += 1
			r["light"].bg_color = C_BAD
			var more := "" if fails.size() == 1 else "  (+%d more)" % (fails.size() - 1)
			r["call"].text = "NO-GO. %s%s" % [fails[0]["message"], more]
			r["call"].modulate = C_BAD
			r["fix"].visible = true
			Sfx.play("nogo", -4.0)
		await _wait(STEP_TIME * 0.4)
	if nogo == 0:
		_status.text = "Flight Director: \"We are GO for launch!\""
		_status.modulate = C_GOOD
		_beacon.light_color = C_GOOD
		_beacon.light_energy = 4.0
		_launch_btn.disabled = false
		Sfx.play("complete", -3.0)
		_launch_btn.grab_focus()
	else:
		_status.text = "Flight Director: \"We are NO-GO. %d station%s must fix their systems.\"" % [nogo, "" if nogo == 1 else "s"]
		_status.modulate = C_BAD
		_beacon.light_color = C_BAD
		Sfx.play("fail", -3.0)
		_beacon.light_energy = 4.0


func _at(node: Node3D, pos: Vector3) -> Node3D:
	node.position = pos
	return node
