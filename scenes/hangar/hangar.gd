# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M2b 3D Hangar: the spacecraft stands on a platform; pick parts from a slim tray and they snap
# onto the 3D model. Orbit camera (drag / wheel), 4 station buttons, compact resource chips,
# hover tooltip with plain-English "why it matters". Built in code to merge cleanly. Owner: Member A.
extends Node3D

const C_GOOD := Color(0.35, 0.85, 0.45)
const C_WARN := Color(1.0, 0.7, 0.2)
const C_BAD := Color(1.0, 0.35, 0.35)
const C_TILE := Color(0.1, 0.14, 0.26, 0.92)
const C_TILE_SEL := Color(0.34, 0.25, 0.06, 0.96)
const C_TILE_OFF := Color(0.09, 0.1, 0.14, 0.85)
const MODEL_POS := Vector3(0, 2.3, 0)
const ROCKET_POS := Vector3(-11.0, 0.0, -11.0)
const MAX_DIST := 12.5   # camera never leaves the room

# camera views per station: [target, yaw, pitch, distance]
const VIEWS := {
	"director": [Vector3(-4.0, 4.0, -4.0), 0.45, 0.12, 12.5],
	"engineer": [MODEL_POS, 0.9, 0.22, 9.0],
	"science": [MODEL_POS, PI + 0.35, 0.12, 6.5],
	"comms": [MODEL_POS + Vector3(0, 0.8, 0), 0.3, 0.75, 8.0],
}

var mission: Dictionary = {}
var station := "engineer"
var section_idx := 0

# camera
var _cam: Camera3D
var _target := MODEL_POS
var _yaw := 0.9
var _pitch := 0.22
var _dist := 9.0
var _goal := {}
var _dragging := false
var _idle := 0.0

# 3D content
var _model: Node3D
var _rocket: Node3D
var _last_rocket_id := "-"

# UI
var _ui: Control
var _chips := {}
var _station_btns := {}
var _tabs_box: HBoxContainer
var _tiles_box: HBoxContainer
var _blurb: Label
var _tip_panel: PanelContainer
var _tip: RichTextLabel
var _issue_label: Label
var _go_btn: Button


func _ready() -> void:
	var mid := MissionState.current_mission_id
	if MissionState.design.get("mission_id", "") != mid:
		MissionState.start_mission(mid)
	mission = GameData.get_mission(mid)
	station = str(MissionState.get_meta("design_station", "engineer"))
	_build_world()
	_build_ui()
	_set_view(station, true)
	MissionState.design_changed.connect(_refresh)
	_refresh()


# ======================================================================= 3D world

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.65)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	add_child(sun)

	# floor + grid
	add_child(_box(Vector3(60, 0.2, 60), Vector3(0, -0.1, 0), Color(0.16, 0.17, 0.2), 0.2, 0.8))
	for i in range(-14, 15, 2):
		add_child(_box(Vector3(56, 0.01, 0.04), Vector3(0, 0.01, i), Color(0.25, 0.27, 0.32)))
		add_child(_box(Vector3(0.04, 0.01, 56), Vector3(i, 0.01, 0), Color(0.25, 0.27, 0.32)))

	# platform with hazard ring
	add_child(_cyl(3.2, 3.4, 0.4, Vector3(0, 0.2, 0), Color(0.3, 0.32, 0.36), 0.7, 0.35))
	add_child(_cyl(3.45, 3.45, 0.06, Vector3(0, 0.03, 0), Color(1.0, 0.78, 0.1), 0.1, 0.6))
	add_child(_cyl(0.5, 0.7, 0.9, Vector3(0, 0.85, 0), Color(0.4, 0.42, 0.46), 0.8, 0.3))   # stand

	# walls with ribs
	# walls: only their inside faces are drawn ("dollhouse"), so they never block the camera
	add_child(_wall(_box(Vector3(60, 18, 0.4), Vector3(0, 9, -16), Color(0.13, 0.15, 0.2))))
	add_child(_wall(_box(Vector3(0.4, 18, 40), Vector3(-18, 9, 0), Color(0.12, 0.14, 0.19))))
	add_child(_wall(_box(Vector3(0.4, 18, 40), Vector3(18, 9, 0), Color(0.12, 0.14, 0.19))))
	for x in range(-16, 17, 4):
		add_child(_wall(_box(Vector3(0.5, 18, 0.6), Vector3(x, 9, -15.6), Color(0.2, 0.22, 0.28), 0.6, 0.4)))
	# big hangar door outline
	add_child(_box(Vector3(12, 0.4, 0.3), Vector3(-6, 11, -15.6), Color(1.0, 0.78, 0.1)))
	# ceiling lamps
	for x in [-8.0, 0.0, 8.0]:
		var lamp := _box(Vector3(3, 0.15, 0.6), Vector3(x, 13, -2), Color(1, 0.97, 0.9))
		var m: StandardMaterial3D = lamp.mesh.material
		m.emission_enabled = true
		m.emission = Color(1, 0.95, 0.85)
		m.emission_energy_multiplier = 3.0
		add_child(lamp)
	var key := OmniLight3D.new()
	key.position = Vector3(2, 9, 4)
	key.omni_range = 22
	key.light_energy = 1.6
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-6, 5, -6)
	rim.omni_range = 16
	rim.light_color = Color(0.45, 0.6, 1.0)
	rim.light_energy = 1.2
	add_child(rim)

	# wall sign
	var sign := Label3D.new()
	sign.text = "MISSION: %s" % str(mission.get("name", "")).to_upper()
	sign.font_size = 72
	sign.pixel_size = 0.01
	sign.modulate = Color(1, 0.85, 0.3)
	sign.double_sided = false
	sign.position = Vector3(3, 10, -15.1)
	add_child(sign)
	var sub := Label3D.new()
	sub.text = str(mission.get("destination", ""))
	sub.font_size = 48
	sub.pixel_size = 0.01
	sub.modulate = Color(0.7, 0.8, 1.0)
	sub.double_sided = false
	sub.position = Vector3(3, 9, -15.1)
	add_child(sub)

	# rocket gantry
	add_child(_box(Vector3(0.5, 14, 0.5), ROCKET_POS + Vector3(-2.6, 7, 0), Color(0.75, 0.25, 0.15), 0.5, 0.5))
	for y in range(2, 14, 3):
		add_child(_box(Vector3(2.2, 0.15, 0.3), ROCKET_POS + Vector3(-1.6, y, 0), Color(0.75, 0.25, 0.15), 0.5, 0.5))

	_cam = Camera3D.new()
	_cam.fov = 55
	add_child(_cam)


func _rebuild_model() -> void:
	if _model:
		_model.queue_free()
	_model = SpacecraftModel3D.build(MissionState.design)
	_model.position = MODEL_POS
	add_child(_model)
	_model.scale = Vector3.ONE * 0.92
	create_tween().tween_property(_model, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var lv := str(MissionState.design.get("launch_vehicle", ""))
	if lv != _last_rocket_id:
		_last_rocket_id = lv
		if _rocket:
			_rocket.queue_free()
			_rocket = null
		if lv != "":
			_rocket = SpacecraftModel3D.build_rocket(lv)
			_rocket.position = ROCKET_POS + Vector3(0, -2, 0)
			_rocket.scale = Vector3.ONE * 0.75
			add_child(_rocket)
			create_tween().tween_property(_rocket, "position", ROCKET_POS, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ======================================================================= camera

func _set_view(key: String, instant := false) -> void:
	var v: Array = VIEWS.get(key, VIEWS["engineer"])
	_goal = {"target": v[0], "yaw": v[1], "pitch": v[2], "dist": v[3]}
	if instant:
		_target = v[0]
		_yaw = v[1]
		_pitch = v[2]
		_dist = v[3]
	_idle = 0.0


func _process(delta: float) -> void:
	_idle += delta
	if not _goal.is_empty():
		var k := 1.0 - exp(-delta * 4.0)
		_target = _target.lerp(_goal["target"], k)
		_yaw = lerp_angle(_yaw, _goal["yaw"], k)
		_pitch = lerpf(_pitch, _goal["pitch"], k)
		_dist = lerpf(_dist, _goal["dist"], k)
		if absf(angle_difference(_yaw, _goal["yaw"])) < 0.002 and _target.distance_to(_goal["target"]) < 0.01:
			_goal = {}
	elif _idle > 4.0 and not _dragging:
		_yaw += delta * 0.12   # gentle showroom spin
	var dir := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	_cam.position = _target + dir * _dist
	_cam.look_at(_target, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_dragging = event.pressed
			if event.pressed:
				_goal = {}
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_dist = clampf(_dist * 0.9, 3.5, MAX_DIST)
			_goal = {}
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_dist = clampf(_dist * 1.1, 3.5, MAX_DIST)
			_goal = {}
		_idle = 0.0
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * 0.008
		_pitch = clampf(_pitch + event.relative.y * 0.006, -0.2, 1.3)
		_idle = 0.0


# ======================================================================= UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)

	# --- top: title + chips + small buttons
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 12
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(top)
	var title := Label.new()
	title.text = str(mission.get("name", "")).to_upper()
	NeonUI.heading(title, 20, NeonUI.TEXT)
	title.custom_minimum_size.x = 200
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(title)
	for c in [["budget", "BUDGET"], ["mass", "LAUNCH MASS"], ["power", "POWER"], ["battery", "SHADOW"], ["data", "SCIENCE DATA"], ["slots", "SLOTS"]]:
		top.add_child(_make_chip(c[0], c[1]))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)

	# --- left: stations
	var left := VBoxContainer.new()
	left.position = Vector2(16, 96)
	left.add_theme_constant_override("separation", 7)
	_ui.add_child(left)
	for s in PartInfo.STATIONS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 52)
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var key: String = s["key"]
		b.pressed.connect(func(): _set_station(key))
		b.tooltip_text = s["long"]
		b.set_meta("no_click", true)
		left.add_child(b)
		_station_btns[key] = b
	var gap := Control.new()
	gap.custom_minimum_size.y = 4
	left.add_child(gap)
	for item in [["Load example", func(): _load_example(), "Stuck? Load a design that works, then improve it."],
			["Clear all", func(): _clear(), "Remove every part."],
			["< Briefing", func(): MissionState.go_to("briefing"), "Back to the mission briefing."]]:
		var btn := _small_button(item[0])
		btn.custom_minimum_size = Vector2(150, 30)
		btn.add_theme_font_size_override("font_size", 13)
		btn.tooltip_text = item[2]
		btn.pressed.connect(item[1])
		left.add_child(btn)

	# --- bottom tray
	var tray := NeonUI.panel("cyan", 10)
	tray.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tray.offset_left = 16
	tray.offset_right = -300
	tray.offset_top = -178
	tray.offset_bottom = -12
	_ui.add_child(tray)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 8)
	tray.add_child(tv)
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 6)
	tv.add_child(tabs_row)
	_tabs_box = HBoxContainer.new()
	_tabs_box.add_theme_constant_override("separation", 6)
	tabs_row.add_child(_tabs_box)
	_blurb = Label.new()
	NeonUI.body(_blurb, 13, NeonUI.MUTED)
	_blurb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_blurb.clip_text = true
	tabs_row.add_child(_blurb)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 108
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tv.add_child(scroll)
	_tiles_box = HBoxContainer.new()
	_tiles_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_tiles_box)

	# --- bottom right: issues + GO button
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right.offset_left = -276
	right.offset_right = -16
	right.offset_top = -178
	right.offset_bottom = -12
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 8)
	_ui.add_child(right)
	_issue_label = Label.new()
	_issue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	NeonUI.body(_issue_label, 13, NeonUI.MUTED)
	_issue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_issue_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	right.add_child(_issue_label)
	_go_btn = Button.new()
	_go_btn.text = "GO / NO-GO POLL  →"
	_go_btn.custom_minimum_size.y = 58
	NeonUI.primary(_go_btn, 19)
	_go_btn.pressed.connect(func(): MissionState.go_to("launch_check"))
	right.add_child(_go_btn)

	# --- tooltip
	_tip_panel = NeonUI.panel("cyan", 12)
	_tip_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_tip_panel.offset_left = -420
	_tip_panel.offset_right = -16
	_tip_panel.offset_top = -420
	_tip_panel.offset_bottom = -190
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.visible = false
	_ui.add_child(_tip_panel)
	_tip = RichTextLabel.new()
	_tip.bbcode_enabled = true
	_tip.fit_content = true
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_theme_font_override("normal_font", NeonUI.font("Barlow-Regular.ttf"))
	_tip.add_theme_font_override("bold_font", NeonUI.font("Barlow-SemiBold.ttf"))
	_tip.add_theme_font_size_override("normal_font_size", 14)
	_tip.add_theme_font_size_override("bold_font_size", 16)
	_tip_panel.add_child(_tip)


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	NeonUI.ghost(b, 13)
	return b


func _make_chip(key: String, label_text: String) -> Control:
	var panel := NeonUI.panel("cyan", 12)
	panel.custom_minimum_size = Vector2(140, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var name_l := NeonUI.kicker(label_text, NeonUI.MUTED, 9)
	v.add_child(name_l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 5
	bar.max_value = 1.0
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bar)
	var val := Label.new()
	NeonUI.mono(val, 12, NeonUI.TEXT)
	v.add_child(val)
	_chips[key] = {"bar": bar, "label": val, "panel": panel}
	return panel


# ======================================================================= refresh

func _set_station(key: String) -> void:
	station = key
	section_idx = 0
	MissionState.set_meta("design_station", key)
	Sfx.play("whoosh", -8.0)
	_set_view(key)
	_refresh()


func _refresh() -> void:
	var s := Sim.summarize(MissionState.design)
	var checks := Sim.launch_check(MissionState.design)
	_rebuild_model()
	_update_chips(s)
	_update_stations(checks)
	_rebuild_tray()
	var bad: Array = checks.filter(func(c): return not c["passed"])
	if bad.is_empty():
		_issue_label.text = "All systems look GO."
		_issue_label.modulate = C_GOOD
	else:
		_issue_label.text = "%d to fix:\n%s" % [bad.size(), bad[0]["message"]]
		_issue_label.modulate = C_WARN


func _chip(key: String, ratio: float, text: String, color: Color, tip: String) -> void:
	var c: Dictionary = _chips[key]
	var bar: ProgressBar = c["bar"]
	bar.value = clampf(ratio, 0.0, 1.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	c["label"].text = text
	c["label"].modulate = color.lightened(0.35)
	c["panel"].tooltip_text = tip


func _update_chips(s: Dictionary) -> void:
	var f := PartInfo.fmt
	var r: float = s["total_cost_musd"] / maxf(s["budget_musd"], 1.0)
	_chip("budget", r, "$%s/%sM" % [f.call(s["total_cost_musd"]), f.call(s["budget_musd"])],
		C_BAD if r > 1.0 else (C_WARN if r > 0.9 else C_GOOD),
		"Parts + rocket + operations. Money left over is your emergency reserve.")
	var cap: float = s["launcher_capacity_kg"]
	r = s["wet_mass_kg"] / cap if cap > 0.0 else 0.0
	_chip("mass", r, ("%s/%s kg" % [f.call(s["wet_mass_kg"]), f.call(cap)]) if cap > 0.0 else "no rocket",
		C_WARN if cap <= 0.0 else (C_BAD if r > 1.0 else (C_WARN if r > 0.9 else C_GOOD)),
		"Spacecraft %s kg + fuel %s kg must fit the rocket." % [f.call(s["dry_mass_kg"]), f.call(s["propellant_kg"])])
	r = s["power_load_w"] / maxf(s["power_gen_w"], 0.001)
	_chip("power", r, "%s/%s W" % [f.call(s["power_load_w"]), f.call(s["power_gen_w"])],
		C_BAD if r > 1.0 else (C_WARN if r > 0.85 else C_GOOD), "Power used / power made.")
	if float(mission.get("eclipse_shadow_min", 0)) <= 0.0:
		_chip("battery", 0.0, "no shadows", C_GOOD, "This orbit has no long shadows.")
	else:
		r = s["eclipse_need_wh"] / maxf(s["battery_wh"], 0.001)
		_chip("battery", r, "%s/%s Wh" % [f.call(s["eclipse_need_wh"]), f.call(s["battery_wh"])],
			C_BAD if r > 1.0 else (C_WARN if r > 0.8 else C_GOOD),
			"Energy needed in Earth's/the planet's shadow vs. battery size.")
	r = s["est_total_data_gb"] / maxf(s["data_goal_gb"], 1.0)
	_chip("data", r, "%s/%s Gb" % [f.call(s["est_total_data_gb"]), f.call(s["data_goal_gb"])],
		C_GOOD if r >= 1.0 else (C_WARN if r >= 0.6 else C_BAD),
		"Instruments make %.1f Gb/day, the antenna sends %.1f Gb/day." % [s["data_per_day_gb"], s["downlink_per_day_gb"]])
	var mx: int = s["slots_max"]
	r = float(s["slots_used"]) / maxf(mx, 1.0)
	_chip("slots", r if mx > 0 else 0.0, ("%d/%d" % [s["slots_used"], mx]) if mx > 0 else "no frame",
		C_BAD if mx > 0 and s["slots_used"] > mx else C_GOOD, "Instruments + power sources must fit in the frame.")


func _update_stations(checks: Array) -> void:
	var issues := {}
	for c in checks:
		if not c["passed"]:
			issues[c["fix_station"]] = int(issues.get(c["fix_station"], 0)) + 1
	for s in PartInfo.STATIONS:
		var b: Button = _station_btns[s["key"]]
		var n := int(issues.get(s["key"], 0))
		b.text = "%s\n%s" % [s["name"].to_upper(), ("%d to fix" % n) if n > 0 else "ready"]
		b.button_pressed = s["key"] == station
		b.add_theme_color_override("font_color", C_WARN if n > 0 else Color.WHITE)


func _rebuild_tray() -> void:
	for c in _tabs_box.get_children():
		c.queue_free()
	for c in _tiles_box.get_children():
		c.queue_free()
	var secs: Array = PartInfo.SECTIONS[station]
	section_idx = clampi(section_idx, 0, secs.size() - 1)
	for i in secs.size():
		var t := Button.new()
		t.text = secs[i]["title"]
		t.toggle_mode = true
		t.button_pressed = i == section_idx
		t.add_theme_font_size_override("font_size", 15)
		var idx := i
		t.pressed.connect(func():
			section_idx = idx
			_rebuild_tray())
		_tabs_box.add_child(t)
	var sec: Dictionary = secs[section_idx]
	var hint := ""
	match sec["mode"]:
		"multi_count":
			hint = "   Left-click to add, right-click to remove."
		"toggle":
			hint = "   Click to add or remove."
	_blurb.text = PartInfo.station(station)["blurb"] + hint
	if sec["mode"] == "years":
		var base := float(mission.get("min_years", 1))
		for extra in [0.0, 1.0, 2.0]:
			var y: float = base + extra
			var sel := is_equal_approx(float(MissionState.design.get("target_years", base)), y)
			var tile := _tile("%d years" % int(y), "minimum" if extra == 0.0 else "+ more science", "more ops cost & wear" if extra > 0.0 else "", sel, "")
			tile.pressed.connect(func(): MissionState.set_design_value("target_years", y))
			_tiles_box.add_child(tile)
		return
	for it in PartInfo.items_for(sec):
		var id: String = it["id"]
		var count := PartInfo.count_selected(sec, id)
		var prob := PartInfo.problem(sec, it, mission)
		var name_text: String = it.get("name", id)
		if sec["mode"] == "multi_count" and count > 0:
			name_text = "x%d %s" % [count, name_text]
		var tile := _tile(name_text, PartInfo.key_stat(sec, it, mission), PartInfo.cost_stat(it), count > 0, prob)
		tile.pressed.connect(func():
			Sfx.play("snap")
			PartInfo.click(sec, id))
		tile.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
				Sfx.play("whoosh", -4.0, 1.3)
				PartInfo.remove(sec, id))
		tile.mouse_entered.connect(func(): _show_tip(sec, it))
		tile.mouse_exited.connect(func(): _tip_panel.visible = false)
		_tiles_box.add_child(tile)


func _tile(title: String, stat: String, cost: String, selected: bool, prob: String) -> Button:
	var b := Button.new()
	b.set_meta("no_click", true)
	b.custom_minimum_size = Vector2(168, 100)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 14)
	b.text = "%s\n%s\n%s" % [title, stat if prob == "" else prob, cost]
	var col := C_TILE_SEL if selected else (C_TILE_OFF if prob != "" else C_TILE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col.lightened(0.12) if state == "hover" else col
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(8)
		if selected:
			sb.set_border_width_all(2)
			sb.border_color = Color(1, 0.8, 0.3)
		b.add_theme_stylebox_override(state, sb)
	var fc := Color(1, 0.55, 0.5) if prob != "" and not selected else Color.WHITE
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fc)
	return b


func _show_tip(sec: Dictionary, it: Dictionary) -> void:
	var prob := PartInfo.problem(sec, it, mission)
	var t := "[b]%s[/b]\n%s\n\n[color=#9fb4e8]%s  |  %s[/color]\n\n[i]%s[/i]" % [
		it.get("name", ""), it.get("description", ""), PartInfo.key_stat(sec, it, mission),
		PartInfo.cost_stat(it), PartInfo.why(it, mission)]
	if prob != "":
		t += "\n\n[color=#ff8a80]%s[/color]" % prob
	_tip.text = t
	_tip_panel.visible = true


func _load_example() -> void:
	MissionState.design = Sim.make_test_design(MissionState.current_mission_id)
	MissionState.design_changed.emit()


func _clear() -> void:
	MissionState.design = MissionState.empty_design(MissionState.current_mission_id)
	MissionState.design_changed.emit()


# ======================================================================= mesh helpers

func _box(size: Vector3, pos: Vector3, color: Color, metallic := 0.2, roughness := 0.7) -> MeshInstance3D:
	var mi := SpacecraftModel3D._box(size, color, metallic, roughness)
	mi.position = pos
	return mi


func _cyl(top_r: float, bottom_r: float, h: float, pos: Vector3, color: Color, metallic := 0.2, roughness := 0.7) -> MeshInstance3D:
	var mi := SpacecraftModel3D._cyl(top_r, bottom_r, h, color, metallic, roughness)
	mi.position = pos
	return mi


## Draw only the inside faces of a wall, so the orbit camera can see through it from outside.
func _wall(mi: MeshInstance3D) -> MeshInstance3D:
	var m: StandardMaterial3D = mi.mesh.material
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	return mi
