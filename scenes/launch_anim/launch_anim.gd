# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M6b: 3D launch & cruise — night pad, countdown, liftoff, stage separation,
# solar-wing deploy, cruise to the destination planet, then Mission Control.
# Skippable with the SKIP button or Space. Owner: Member C (Daniel).
extends Node3D

const TOTAL := 12.2
const LIFTOFF_T := 3.0
const CUT_T := 5.4
const SEP_T := 6.1
const DEPLOY_T := 6.4
const DEPLOY_END := 8.2
const ARRIVE_T := 10.5
const FADE_OUT_T := 11.6
const STAGE2_T := 8.6
const RUMBLE_FILE := "res://audio/launch_rumble.wav"
const STARS_MAP := "res://art/planets/2k_stars.jpg"

var design: Dictionary
var mission: Dictionary
var mid := "mars"
var _has_solar := false

var _t := 0.0
var _done := false
var _launched := false
var _space := false
var _last_count := 3
var _arrive_sfx := false
var _sep_fx_done := false
var _deploy_blip := false
var _rumble: AudioStreamPlayer
var _sep_puff: CPUParticles3D
var _sep_flash: OmniLight3D

var _pad_root: Node3D
var _space_root: Node3D
var _rocket: Node3D
var _flame: MeshInstance3D
var _flame_inner: MeshInstance3D
var _glow: OmniLight3D
var _smoke: CPUParticles3D
var _pad_cam: Camera3D
var _space_cam: Camera3D

var _ship: Node3D
var _craft: Node3D
var _stage1: Node3D
var _stage2: Node3D
var _dest: Node3D
var _env: Environment

var _big: Label
var _sub: Label
var _skip: Button
var _fade: ColorRect


func _ready() -> void:
	design = MissionState.design
	if design.is_empty() or str(design.get("bus", "")) == "":
		design = Sim.make_test_design("mars")
		MissionState.design = design
		MissionState.current_mission_id = "mars"
	mid = str(design.get("mission_id", MissionState.current_mission_id))
	if mid == "":
		mid = "mars"
	mission = GameData.get_mission(mid)
	for p in design.get("power", []):
		if str(GameData.get_item("power", p).get("kind", "")) == "solar":
			_has_solar = true
	_build_world()
	_build_pad()
	_build_space()
	_build_ui()
	_build_rumble()
	Sfx.play("beep", -8.0)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _t < LIFTOFF_T:
		_update_countdown()
	elif not _launched:
		_launch()
	if _t < CUT_T:
		_update_pad()
	else:
		if not _space:
			_enter_space()
		_update_space(delta)
	_update_fade()
	if _t >= TOTAL:
		_finish()


func _update_countdown() -> void:
	var n := int(ceil(LIFTOFF_T - _t))
	_big.text = "T-%d" % maxi(n, 0)
	_sub.text = "COUNTDOWN NOMINAL  ·  ALL STATIONS GO"
	if n != _last_count:
		_last_count = n
		if n > 0:
			Sfx.play("beep", -8.0)


func _launch() -> void:
	_launched = true
	_big.text = "LIFTOFF!"
	_sub.text = "ASCENT  ·  STAGE 1 NOMINAL"
	_flame.visible = true
	_flame_inner.visible = true
	_glow.light_energy = 6.0
	_smoke.emitting = true
	Sfx.play("whoosh", -2.0)
	Sfx.play("go", -6.0)
	if _rumble:
		_rumble.play()


func _update_pad() -> void:
	var ft := maxf(_t - LIFTOFF_T, 0.0)
	_rocket.position.y = 1.3 + 0.5 * 9.0 * ft * ft
	_flame.scale = Vector3.ONE * (1.0 + sin(_t * 40.0) * 0.08)
	_flame_inner.scale = Vector3.ONE * (1.0 + sin(_t * 47.0) * 0.10)
	var shake := Vector3(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12), 0.0) * clampf(1.6 - ft, 0.0, 1.0)
	_pad_cam.position = Vector3(28, 7 + _rocket.position.y * 0.55, 40) + shake
	_pad_cam.look_at(_rocket.position + Vector3(0, 10, 0), Vector3.UP)
	if ft > 1.4:
		_big.text = ""
		_sub.text = "ASCENT  ·  STAGE SEPARATION"


func _enter_space() -> void:
	_space = true
	_pad_root.visible = false
	_space_root.visible = true
	_space_cam.current = true
	if _env:
		_env.fog_enabled = false
		_env.ambient_light_energy = 0.22
	_big.text = ""
	_sub.text = "STAGE SEPARATION"
	_fade.color = Color.WHITE
	_fade.modulate.a = 1.0
	Sfx.play("snap", -5.0)
	if _rumble:
		_rumble.stop()


func _update_space(delta: float) -> void:
	var sep := maxf(_t - SEP_T, 0.0)
	_stage1.position = Vector3(-2.4 * sep, -1.1 * sep, 10.2 + 2.0 * sep)
	_stage1.rotation.z = 0.9 * sep
	_stage1.rotation.x = 0.45 * sep
	# Keep the booster tumbling until it has clearly left the frame, then cull it.
	_stage1.visible = _t < 7.6
	var s2 := maxf(_t - STAGE2_T, 0.0)
	_stage2.position = Vector3(-0.4 * s2, -1.6 * s2, 4.6 + 1.0 * s2)
	_stage2.rotation.z = 0.25 * s2
	_stage2.visible = _t < 11.2

	if _t >= SEP_T and not _sep_fx_done:
		_sep_fx_done = true
		_sep_puff.restart()
		_sep_puff.emitting = true
		_sep_flash.light_energy = 3.0
	_sep_flash.light_energy = maxf(_sep_flash.light_energy - delta * 9.0, 0.0)

	var deploy := clampf((_t - DEPLOY_T) / (DEPLOY_END - DEPLOY_T), 0.0, 1.0)
	SpacecraftModel3D.deploy_wings(_craft, deploy)
	if deploy >= 1.0 and not _deploy_blip:
		_deploy_blip = true
		Sfx.play("fixed", -8.0)

	var ship_z := -clampf((_t - 7.4) * 2.4, 0.0, 10.0)
	_ship.position.z = ship_z
	var approach := clampf((_t - 7.4) / 4.0, 0.0, 1.0)
	if _dest:
		_dest.scale = Vector3.ONE * lerpf(2.8, 8.0, approach)
		if _dest.has_method("spin_by"):
			_dest.spin_by(delta * 0.02)
		else:
			_dest.rotate_y(delta * 0.02)

	_space_cam.position = Vector3(6.0 + sin(_t * 0.25) * 0.6, 3.5, ship_z + 16.0)
	_space_cam.look_at(Vector3(0, 0, ship_z - 2.0), Vector3.UP)

	if _t < SEP_T + 0.5:
		_sub.text = "STAGE SEPARATION"
	elif _t < DEPLOY_END:
		_sub.text = "SOLAR ARRAYS DEPLOY" if _has_solar else "SPACECRAFT SYSTEMS ONLINE"
	elif _t < ARRIVE_T:
		_sub.text = "CRUISE TO %s" % str(mission.get("destination", "")).to_upper()
	else:
		_sub.text = "ARRIVAL  ·  MISSION CONTROL HANDOFF"
		_big.add_theme_font_size_override("font_size", 56)
		_big.text = "ARRIVED AT %s" % str(mission.get("destination", "")).to_upper()
		if not _arrive_sfx:
			_arrive_sfx = true
			Sfx.play("complete", -4.0)


func _update_fade() -> void:
	var a := 0.0
	if _space:
		if _t < CUT_T + 0.6:
			a = 1.0 - clampf((_t - CUT_T) / 0.6, 0.0, 1.0)
		if _t > FADE_OUT_T:
			_fade.color = Color.BLACK
			a = clampf((_t - FADE_OUT_T) / 0.6, 0.0, 1.0)
	_fade.modulate.a = a


func _finish() -> void:
	if _done:
		return
	_done = true
	MissionState.go_to("mission_control")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_finish()


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
		env.background_energy_multiplier = 0.9
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.015, 0.025, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.28, 0.45)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.07, 0.14)
	env.fog_density = 0.006
	we.environment = env
	_env = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-32, 140, 0)
	moon.light_color = Color(0.60, 0.70, 1.0)
	moon.light_energy = 0.6
	moon.shadow_enabled = true
	add_child(moon)


func _build_pad() -> void:
	_pad_root = Node3D.new()
	_pad_root.name = "Pad"
	add_child(_pad_root)

	_pad_root.add_child(_at(_box(Vector3(400, 0.2, 400), Color(0.08, 0.11, 0.09), 0.0, 0.95), Vector3(0, -0.1, 0)))
	_pad_root.add_child(_at(_box(Vector3(70, 0.08, 70), Color(0.16, 0.18, 0.20), 0.1, 0.9), Vector3(0, 0.04, 0)))
	_pad_root.add_child(_at(_box(Vector3(20, 1.0, 20), Color(0.36, 0.37, 0.41), 0.2, 0.8), Vector3(0, 0.5, 0)))
	_pad_root.add_child(_at(_box(Vector3(6, 0.3, 6), Color(0.18, 0.18, 0.2), 0.5, 0.6), Vector3(0, 1.15, 0)))

	var pad_fill := OmniLight3D.new()
	pad_fill.position = Vector3(0, 6, 2)
	pad_fill.omni_range = 55
	pad_fill.light_energy = 1.8
	pad_fill.light_color = Color(1.0, 0.78, 0.55)
	_pad_root.add_child(pad_fill)
	var cool_fill := OmniLight3D.new()
	cool_fill.position = Vector3(12, 10, 14)
	cool_fill.omni_range = 38
	cool_fill.light_energy = 0.9
	cool_fill.light_color = Color(0.60, 0.70, 1.0)
	_pad_root.add_child(cool_fill)

	# Bright night-sky stars, independent of the panorama so the pad always reads as night.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1969
	for i in 90:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.04, 1.0), rng.randf_range(-1, 1)).normalized()
		var star := _star(rng.randf_range(0.15, 0.42), Color(0.88, 0.94, 1.0))
		star.position = dir * 150.0
		_pad_root.add_child(star)

	var red := Color(0.65, 0.16, 0.10)
	_pad_root.add_child(_at(_box(Vector3(2.2, 40, 2.2), red, 0.4, 0.6), Vector3(-8.5, 20, 0)))
	for y in range(4, 40, 5):
		_pad_root.add_child(_at(_box(Vector3(5.0, 0.35, 0.5), red, 0.4, 0.6), Vector3(-5.7, y, 0)))
	var beacon := _star(0.45, Color(1.0, 0.18, 0.12))
	beacon.position = Vector3(-8.5, 40.6, 0)
	_pad_root.add_child(beacon)

	for p in [Vector3(15, 3, 15), Vector3(-15, 3, 13), Vector3(13, 3, -15)]:
		var l := SpotLight3D.new()
		l.position = p
		l.look_at_from_position(p, Vector3(0, 14, 0), Vector3.UP)
		l.spot_range = 70
		l.spot_angle = 24
		l.light_energy = 6.0
		l.light_color = Color(1.0, 0.95, 0.85)
		_pad_root.add_child(l)
		_pad_root.add_child(_at(_box(Vector3(1.2, 1.2, 1.2), Color(1, 1, 0.9), 0.0, 0.3), p))

	var lv := str(design.get("launch_vehicle", ""))
	if lv == "":
		lv = "medium"
	_rocket = SpacecraftModel3D.build_rocket(lv)
	_rocket.scale = Vector3.ONE * 2.2
	_rocket.position = Vector3(0, 1.3, 0)
	_pad_root.add_child(_rocket)

	_flame = _flame_cone(1.2, 0.05, 6.0, Color(1.0, 0.55, 0.10))
	_flame.position = Vector3(0, -3.0, 0)
	_flame.visible = false
	_rocket.add_child(_flame)
	_flame_inner = _flame_cone(0.55, 0.02, 4.2, Color(1.0, 0.95, 0.60))
	_flame_inner.position = Vector3(0, -2.1, 0)
	_flame_inner.visible = false
	_rocket.add_child(_flame_inner)

	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = Color(1.0, 0.55, 0.15)
	_glow.omni_range = 30
	_glow.light_energy = 0.0
	_rocket.add_child(_glow)

	_smoke = CPUParticles3D.new()
	_smoke.name = "Smoke"
	_smoke.amount = 180
	_smoke.lifetime = 3.5
	_smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_smoke.emission_sphere_radius = 3.0
	_smoke.direction = Vector3(0, 1, 0)
	_smoke.spread = 70.0
	_smoke.initial_velocity_min = 1.0
	_smoke.initial_velocity_max = 3.0
	_smoke.gravity = Vector3(0, 0.6, 0)
	_smoke.scale_amount_min = 1.2
	_smoke.scale_amount_max = 3.2
	_smoke.mesh = _smoke_mesh()
	_smoke.position = Vector3(0, 1.3, 0)
	_smoke.emitting = false
	_pad_root.add_child(_smoke)

	_pad_cam = Camera3D.new()
	_pad_cam.fov = 52
	_pad_cam.position = Vector3(28, 7, 40)
	_pad_cam.current = true
	_pad_root.add_child(_pad_cam)
	_pad_cam.look_at(Vector3(0, 16, 0), Vector3.UP)


func _build_space() -> void:
	_space_root = Node3D.new()
	_space_root.name = "Space"
	_space_root.visible = false
	add_child(_space_root)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20, 160, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.6
	sun.shadow_enabled = false
	_space_root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(15, -30, 0)
	fill.light_color = Color(0.45, 0.60, 1.0)
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	_space_root.add_child(fill)

	_ship = Node3D.new()
	_ship.name = "Ship"
	_space_root.add_child(_ship)

	_dest = MenuPlanet.make(mid)
	if _dest:
		_dest.name = "Destination"
		_dest.position = Vector3(0, 0, -18)
		_dest.scale = Vector3.ONE * 2.4
		_ship.add_child(_dest)

	_craft = SpacecraftModel3D.build(design)
	_craft.name = "Spacecraft"
	_craft.scale = Vector3.ONE * 2.0
	_craft.rotation = Vector3(0.12, PI, 0.10)
	_ship.add_child(_craft)
	SpacecraftModel3D.deploy_wings(_craft, 0.0)

	_stage2 = _space_stage(1.35, 1.55, 4.5, Color(0.92, 0.93, 0.96))
	_stage2.position = Vector3(0, 0, 4.6)
	_ship.add_child(_stage2)
	var truss := _cyl(0.35, 0.35, 2.2, Color(0.40, 0.42, 0.48), 0.6, 0.4)
	truss.rotation.x = -PI / 2.0
	truss.position = Vector3(0, 0, -2.4)
	_stage2.add_child(truss)

	_stage1 = _space_stage(1.65, 1.85, 6.0, Color(0.90, 0.91, 0.94))
	_stage1.position = Vector3(0, 0, 10.2)
	_ship.add_child(_stage1)
	var inter := _cyl(1.5, 1.5, 1.2, Color(0.55, 0.57, 0.62), 0.5, 0.5)
	inter.rotation.x = -PI / 2.0
	inter.position = Vector3(0, 0, -2.4)
	_stage1.add_child(inter)
	for k in 4:
		var fin := _box(Vector3(0.15, 2.2, 1.4), Color(0.20, 0.25, 0.40), 0.3, 0.5)
		var a := k * PI / 2.0
		fin.position = Vector3(cos(a) * 1.8, 0, sin(a) * 1.8)
		fin.rotation.y = -a
		_stage1.add_child(fin)

	_sep_puff = CPUParticles3D.new()
	_sep_puff.name = "SepPuff"
	_sep_puff.amount = 16
	_sep_puff.one_shot = true
	_sep_puff.explosiveness = 1.0
	_sep_puff.lifetime = 0.9
	_sep_puff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sep_puff.emission_sphere_radius = 0.6
	_sep_puff.direction = Vector3(0, 0, 1)
	_sep_puff.spread = 60.0
	_sep_puff.initial_velocity_min = 1.0
	_sep_puff.initial_velocity_max = 2.5
	_sep_puff.gravity = Vector3.ZERO
	_sep_puff.scale_amount_min = 0.6
	_sep_puff.scale_amount_max = 1.4
	_sep_puff.mesh = _smoke_mesh()
	_sep_puff.position = Vector3(0, 0, 8.5)
	_sep_puff.emitting = false
	_ship.add_child(_sep_puff)

	_sep_flash = OmniLight3D.new()
	_sep_flash.name = "SepFlash"
	_sep_flash.position = Vector3(0, 0, 8.5)
	_sep_flash.omni_range = 14.0
	_sep_flash.light_color = Color(1.0, 0.85, 0.6)
	_sep_flash.light_energy = 0.0
	_ship.add_child(_sep_flash)

	_space_cam = Camera3D.new()
	_space_cam.fov = 55
	_space_cam.position = Vector3(6, 3.5, 16)
	_space_cam.current = false
	_space_root.add_child(_space_cam)
	_space_cam.look_at(Vector3(0, 0, -2), Vector3.UP)


# ===================================================================== UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "%s  ·  %s" % [str(mission.get("name", "")).to_upper(), str(mission.get("destination", "")).to_upper()]
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.70, 0.82, 1.0))
	title.position = Vector2(40, 26)
	root.add_child(title)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	center.add_child(vbox)

	_big = Label.new()
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_big.add_theme_font_size_override("font_size", 110)
	_big.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	_big.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_big.add_theme_constant_override("outline_size", 16)
	vbox.add_child(_big)

	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.add_theme_font_size_override("font_size", 26)
	_sub.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_sub.add_theme_constant_override("outline_size", 8)
	vbox.add_child(_sub)

	# Lift the captions above the centre so the rocket / spacecraft stays readable.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 140)
	vbox.add_child(spacer)

	_skip = Button.new()
	_skip.text = "SKIP  ▶"
	_skip.add_theme_font_size_override("font_size", 20)
	_skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip.offset_left = -170
	_skip.offset_top = -78
	_skip.offset_right = -30
	_skip.offset_bottom = -28
	_skip.pressed.connect(_finish)
	root.add_child(_skip)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color.WHITE
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)


# ===================================================================== helpers

func _box(size: Vector3, color: Color, metallic := 0.2, roughness := 0.7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	mesh.material = m
	mi.mesh = mesh
	return mi


func _cyl(top_r: float, bottom_r: float, height: float, color: Color, metallic := 0.2, roughness := 0.6) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 24
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	mesh.material = m
	mi.mesh = mesh
	return mi


func _flame_cone(top_r: float, bottom_r: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 4.0
	mesh.material = m
	mi.mesh = mesh
	return mi


func _smoke_mesh() -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.55, 0.60, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = m
	return sm


func _star(radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.5
	m.disable_fog = true
	sm.material = m
	mi.mesh = sm
	return mi


func _space_stage(top_r: float, bottom_r: float, height: float, color: Color) -> Node3D:
	var root := Node3D.new()
	var body := _cyl(top_r, bottom_r, height, color, 0.2, 0.5)
	body.rotation.x = -PI / 2.0
	root.add_child(body)
	var nozzle := _cyl(bottom_r * 0.55, 0.02, 0.8, Color(0.25, 0.25, 0.30), 0.8, 0.3)
	nozzle.rotation.x = -PI / 2.0
	nozzle.position = Vector3(0, 0, height * 0.5 + 0.4)
	root.add_child(nozzle)
	return root


func _build_rumble() -> void:
	_rumble = AudioStreamPlayer.new()
	_rumble.name = "LaunchRumble"
	_rumble.volume_db = -4.0
	var stream: AudioStream = null
	if ResourceLoader.exists(RUMBLE_FILE):
		stream = load(RUMBLE_FILE) as AudioStream
	if stream == null:
		stream = _make_rumble()
	_rumble.stream = stream
	add_child(_rumble)


## Procedural launch rumble (Member C, README §C step 7): brown noise + low-pass +
## envelope. Drop a real file at res://audio/launch_rumble.wav to replace it.
func _make_rumble() -> AudioStreamWAV:
	var rate := 22050
	var seconds := 4.0
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var brown := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(rate)
		brown = clampf(brown + rng.randf_range(-1.0, 1.0) * 0.02, -1.0, 1.0)
		lp = lerpf(lp, brown, 0.06)
		var env := 1.0
		if t < 0.25:
			env = t / 0.25
		elif t > 3.0:
			env = clampf(1.0 - (t - 3.0) / 1.0, 0.0, 1.0)
		var wob := 0.80 + 0.20 * sin(t * 2.3) * sin(t * 0.8)
		var v := clampf(lp * 5.0 * env * wob, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


func _at(node: Node3D, pos: Vector3) -> Node3D:
	node.position = pos
	return node
