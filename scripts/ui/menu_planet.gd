# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# MenuPlanet: quick procedural planets + starfield for the menu screens (title, campaign, briefing).
# If Danial's planet scenes exist (res://scenes/space/planets/<id>.tscn, radius 1, centered),
# they are used instead automatically. Owner: Member A.
class_name MenuPlanet
extends RefCounted


## A planet of radius 1 (scale it yourself). id: sun | earth | moon | mars | jupiter | saturn
static func make(id: String) -> Node3D:
	var path := "res://scenes/space/planets/%s.tscn" % id
	if ResourceLoader.exists(path):
		var scene: PackedScene = load(path)
		if scene:
			return scene.instantiate()
	var root := Node3D.new()
	root.name = id.capitalize()
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 48
	mesh.rings = 24
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	match id:
		"sun":
			m.albedo_color = Color(1.0, 0.8, 0.35)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.7, 0.25)
			m.emission_energy_multiplier = 2.5
		"earth":
			m.albedo_texture = _noise_tex(3.0, [Color(0.08, 0.25, 0.65), Color(0.1, 0.35, 0.75), Color(0.2, 0.55, 0.25), Color(0.45, 0.6, 0.3), Color(0.95, 0.95, 0.97)], [0.0, 0.48, 0.52, 0.7, 0.85], 11)
		"moon":
			m.albedo_texture = _noise_tex(5.0, [Color(0.35, 0.35, 0.37), Color(0.6, 0.6, 0.6), Color(0.78, 0.78, 0.76)], [0.0, 0.5, 1.0], 22)
		"mars":
			m.albedo_texture = _noise_tex(3.5, [Color(0.45, 0.16, 0.08), Color(0.75, 0.33, 0.15), Color(0.88, 0.5, 0.3), Color(0.97, 0.95, 0.95)], [0.0, 0.45, 0.8, 0.93], 33)
		"jupiter":
			m.albedo_texture = _bands([Color(0.85, 0.75, 0.62), Color(0.65, 0.45, 0.32), Color(0.92, 0.86, 0.75), Color(0.72, 0.5, 0.35), Color(0.95, 0.9, 0.8), Color(0.6, 0.42, 0.3), Color(0.88, 0.8, 0.68)])
		"saturn":
			m.albedo_texture = _bands([Color(0.9, 0.82, 0.6), Color(0.8, 0.7, 0.5), Color(0.93, 0.87, 0.68), Color(0.82, 0.72, 0.52), Color(0.9, 0.84, 0.64)])
		_:
			m.albedo_color = Color(0.6, 0.6, 0.65)
	mesh.material = m
	body.mesh = mesh
	root.add_child(body)

	if id == "earth":   # thin atmosphere glow
		var atm := MeshInstance3D.new()
		var am := SphereMesh.new()
		am.radius = 1.04
		am.height = 2.08
		var amat := StandardMaterial3D.new()
		amat.albedo_color = Color(0.4, 0.65, 1.0, 0.18)
		amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		am.material = amat
		atm.mesh = am
		root.add_child(atm)
	if id == "saturn":   # rings
		var ring := MeshInstance3D.new()
		ring.name = "Rings"
		var tm := TorusMesh.new()
		tm.inner_radius = 1.35
		tm.outer_radius = 2.3
		tm.rings = 64
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.85, 0.78, 0.6, 0.75)
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		tm.material = rmat
		ring.mesh = tm
		ring.scale = Vector3(1, 0.03, 1)
		ring.rotation_degrees = Vector3(18, 0, 8)
		root.add_child(ring)
	return root


static func _noise_tex(freq: float, colors: Array, offsets: Array, seed_v: int) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq / 100.0
	n.fractal_octaves = 5
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offsets)
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 256
	t.seamless = true
	t.noise = n
	t.color_ramp = g
	return t


static func _bands(colors: Array) -> GradientTexture2D:
	var g := Gradient.new()
	var offs: Array = []
	for i in colors.size():
		offs.append(float(i) / (colors.size() - 1))
	g.colors = PackedColorArray(colors)
	g.offsets = PackedFloat32Array(offs)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 8
	t.height = 256
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	return t


## Adds a big sphere of stars around the origin plus a basic dark-space environment.
static func add_space(parent: Node, star_count := 300, radius := 200.0) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.22, 0.32)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	parent.add_child(we)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	sm.radial_segments = 6
	sm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1)
	sm.material = mat
	mm.mesh = sm
	mm.instance_count = star_count
	var rng := RandomNumberGenerator.new()
	rng.seed = 1969
	for i in star_count:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var s := rng.randf_range(0.3, 1.2)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * s), dir * radius))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	parent.add_child(mmi)
