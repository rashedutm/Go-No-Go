# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M6a: 3D space view for Mission Control's wall screen.
# API: setup(design) / set_status(status) / set_time_scale(days_per_second).
# Owner: Member C (Daniel).
extends Node3D
class_name SpaceView

const PLANET_SCALE := {"earth": 3.0, "moon": 2.2, "mars": 2.4, "jupiter": 3.4, "saturn": 2.8}
const CRAFT_SCALE := {"earth": 0.70, "moon": 0.70, "mars": 0.70, "jupiter": 0.82, "saturn": 0.82}
const ORBIT_EXTRA := {"earth": 3.0, "moon": 3.0, "mars": 3.0, "jupiter": 3.2, "saturn": 6.0}
const STATUSES := ["normal", "safe_mode", "solar_storm", "damaged", "downlink"]
const CAMERA_FOV := 52.0
const STARS_MAP := "res://art/planets/2k_stars.jpg"

var _design: Dictionary = {}
var _planet: Node3D
var _orbit: Node3D
var _craft: Node3D
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _status_light: OmniLight3D
var _storm: CPUParticles3D
var _sparks: CPUParticles3D
var _beam: Node3D
var _beam_mats: Array[StandardMaterial3D] = []
var _status := "normal"
var _speed := 0.15
var _time := 0.0
var _ps := 2.6
var _orbit_r := 4.8


func _ready() -> void:
	if _design.is_empty():
		call_deferred("_default_setup")


func _default_setup() -> void:
	if _design.is_empty():
		setup(Sim.make_test_design("mars"))


func setup(design: Dictionary) -> void:
	_design = design.duplicate(true)
	_clear()
	_build_space()
	_build_lights()
	_build_planet()
	_build_orbit()
	_build_craft()
	_build_camera()
	_build_effects()
	_apply_status()


func set_status(status: String) -> void:
	_status = status if status in STATUSES else "normal"
	_apply_status()


func set_time_scale(days_per_second: float) -> void:
	_speed = clampf(days_per_second * 0.035, 0.0, 1.5)


func _process(delta: float) -> void:
	_time += delta
	if _orbit:
		_orbit.rotate_y(delta * _speed)
	if _planet and _speed > 0.001:
		if _planet.has_method("spin_by"):
			_planet.spin_by(delta * 0.02)
		else:
			_planet.rotate_y(delta * 0.02)
	if _beam and _beam.visible:
		var pulse := 0.82 + 0.18 * sin(_time * 4.0)
		for m in _beam_mats:
			m.albedo_color.a = float(m.get_meta("base_alpha", 0.4)) * pulse
	if _status_light:
		if _status == "damaged":
			_status_light.light_energy = 0.75 + 0.55 * abs(sin(_time * 17.0))
		elif _status == "solar_storm":
			_status_light.light_energy = 0.85 + 0.30 * sin(_time * 3.0)


func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_planet = null
	_orbit = null
	_craft = null
	_sun = null
	_fill = null
	_status_light = null
	_storm = null
	_sparks = null
	_beam = null
	_beam_mats.clear()


func _build_space() -> void:
	var tex: Texture2D = null
	if ResourceLoader.exists(STARS_MAP):
		tex = load(STARS_MAP) as Texture2D
	if tex == null:
		MenuPlanet.add_space(self, 500, 180.0)
		_fade_environment()
		return
	var we := WorldEnvironment.new()
	we.name = "SpaceEnvironment"
	var env := Environment.new()
	var sky := Sky.new()
	var sm := PanoramaSkyMaterial.new()
	sm.panorama = tex
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.background_energy_multiplier = 1.3
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.20, 0.22, 0.32)
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)


func _fade_environment() -> void:
	for child in get_children():
		if child is WorldEnvironment:
			var we := child as WorldEnvironment
			if we.environment:
				we.environment.ambient_light_energy = 0.22
				we.environment.background_color = Color(0.004, 0.006, 0.018)


func _build_lights() -> void:
	_sun = DirectionalLight3D.new()
	_sun.name = "SunLight"
	_sun.rotation_degrees = Vector3(-25, -35, 0)
	_sun.light_color = Color(1.0, 0.96, 0.88)
	_sun.light_energy = 1.70
	_sun.shadow_enabled = false
	add_child(_sun)
	_fill = DirectionalLight3D.new()
	_fill.name = "FillLight"
	_fill.rotation_degrees = Vector3(18, 145, 0)
	_fill.light_color = Color(0.45, 0.60, 1.0)
	_fill.light_energy = 0.20
	_fill.shadow_enabled = false
	add_child(_fill)


func _build_planet() -> void:
	var mid := str(_design.get("mission_id", "earth"))
	if not PLANET_SCALE.has(mid):
		mid = "earth"
	_ps = float(PLANET_SCALE[mid])
	_orbit_r = _ps + float(ORBIT_EXTRA[mid])
	_planet = MenuPlanet.make(mid)
	if _planet == null:
		return
	_planet.name = "Planet"
	_planet.scale = Vector3.ONE * _ps
	_planet.rotation.y = 0.45
	add_child(_planet)


func _build_orbit() -> void:
	_orbit = Node3D.new()
	_orbit.name = "Orbit"
	_orbit.rotation_degrees = Vector3(16, 0, -7)
	add_child(_orbit)
	var line := MeshInstance3D.new()
	line.name = "OrbitLine"
	var tm := TorusMesh.new()
	tm.inner_radius = _orbit_r - 0.008
	tm.outer_radius = _orbit_r + 0.008
	tm.rings = 96
	tm.ring_segments = 4
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.35, 0.72, 1.0, 0.10)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tm.material = lm
	line.mesh = tm
	_orbit.add_child(line)


func _build_craft() -> void:
	var mid := str(_design.get("mission_id", "earth"))
	if not CRAFT_SCALE.has(mid):
		mid = "earth"
	_craft = SpacecraftModel3D.build(_design)
	_craft.name = "Spacecraft"
	_craft.scale = Vector3.ONE * float(CRAFT_SCALE[mid])
	_craft.position = Vector3(_orbit_r, 0, 0)
	_craft.rotation = Vector3(0.12, 2.35, 0.10)
	_orbit.add_child(_craft)


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = CAMERA_FOV
	cam.near = 0.05
	cam.far = 600.0
	cam.position = Vector3(0, _ps * 0.40, _orbit_r + _ps * 1.9 + 2.0)
	add_child(cam)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	cam.current = true


func _build_effects() -> void:
	_status_light = OmniLight3D.new()
	_status_light.name = "StatusLight"
	_status_light.position = Vector3(_orbit_r, 0, 0)
	_status_light.omni_range = 3.0
	_status_light.light_energy = 0.0
	_orbit.add_child(_status_light)

	_storm = CPUParticles3D.new()
	_storm.name = "SolarStorm"
	_storm.amount = 220
	_storm.lifetime = 3.2
	_storm.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_storm.emission_sphere_radius = _ps * 1.08
	_storm.direction = Vector3(1, 0, 0)
	_storm.spread = 180.0
	_storm.initial_velocity_min = 0.12
	_storm.initial_velocity_max = 0.50
	_storm.gravity = Vector3.ZERO
	_storm.scale_amount_min = 0.7
	_storm.scale_amount_max = 1.8
	_storm.mesh = _particle_mesh(0.045, Color(1.0, 0.55, 0.18))
	_storm.emitting = false
	_storm.visible = false
	add_child(_storm)

	_sparks = CPUParticles3D.new()
	_sparks.name = "Sparks"
	_sparks.amount = 32
	_sparks.lifetime = 1.1
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sparks.emission_sphere_radius = 0.10
	_sparks.direction = Vector3(0, 1, 0)
	_sparks.spread = 70.0
	_sparks.initial_velocity_min = 0.40
	_sparks.initial_velocity_max = 1.20
	_sparks.gravity = Vector3(0, -1.4, 0)
	_sparks.scale_amount_min = 0.8
	_sparks.scale_amount_max = 2.0
	_sparks.mesh = _particle_mesh(0.030, Color(1.0, 0.80, 0.30))
	_sparks.local_coords = true
	_sparks.position = Vector3(_orbit_r, 0, 0)
	_sparks.emitting = false
	_sparks.visible = false
	_orbit.add_child(_sparks)

	_beam = Node3D.new()
	_beam.name = "Downlink"
	_beam.position = Vector3(_orbit_r, 0, 0)
	_orbit.add_child(_beam)
	_beam.add_child(_beam_layer(0.04, 0.55))
	_beam.add_child(_beam_layer(0.14, 0.10))
	var glow := MeshInstance3D.new()
	var gs := SphereMesh.new()
	gs.radius = 0.10
	gs.height = 0.20
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.35, 0.90, 1.0)
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.emission_enabled = true
	gm.emission = Color(0.30, 0.85, 1.0)
	gm.emission_energy_multiplier = 3.0
	gs.material = gm
	glow.mesh = gs
	_beam.add_child(glow)
	_beam.visible = false


func _beam_layer(radius: float, alpha: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius * 0.2
	cm.height = 10.0
	cm.radial_segments = 8
	cm.rings = 1
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.88, 1.0, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.set_meta("base_alpha", alpha)
	cm.material = m
	mi.mesh = cm
	mi.rotation.z = -PI / 2.0
	mi.position = Vector3(5.0, 0, 0)
	_beam_mats.append(m)
	return mi


func _particle_mesh(radius: float, color: Color) -> SphereMesh:
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
	m.emission_energy_multiplier = 2.0
	sm.material = m
	return sm


func _apply_status() -> void:
	var sun_e := 1.55
	var sun_c := Color(1.0, 0.96, 0.88)
	var fill_e := 0.18
	var light_e := 0.0
	var light_c := Color(1.0, 0.55, 0.2)
	match _status:
		"safe_mode":
			sun_e = 0.55
			fill_e = 0.10
			light_e = 0.35
			light_c = Color(0.35, 0.60, 1.0)
		"solar_storm":
			sun_e = 1.25
			sun_c = Color(1.0, 0.55, 0.28)
			light_e = 1.10
			light_c = Color(1.0, 0.45, 0.15)
		"damaged":
			sun_e = 1.35
			light_e = 0.85
			light_c = Color(1.0, 0.35, 0.10)
		"downlink":
			light_e = 0.40
			light_c = Color(0.30, 0.85, 1.0)
	if _sun:
		_sun.light_energy = sun_e
		_sun.light_color = sun_c
	if _fill:
		_fill.light_energy = fill_e
	if _status_light:
		_status_light.light_energy = light_e
		_status_light.light_color = light_c
	if _storm:
		var storm_on := _status == "solar_storm"
		_storm.visible = storm_on
		_storm.emitting = storm_on
	if _sparks:
		var hurt := _status == "damaged"
		_sparks.visible = hurt
		_sparks.emitting = hurt
	if _beam:
		_beam.visible = _status == "downlink"
