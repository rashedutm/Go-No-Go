# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M6a: procedural planets (radius 1, centered) for MenuPlanet and space_view.
# No external textures: every surface is generated in code, so there is nothing to credit.
# Owner: Member C (Daniel).
extends Node3D
class_name PlanetBody

@export_enum("earth", "moon", "mars", "jupiter", "saturn", "sun") var planet_id: String = "earth"

const TEX_W := 256
const TEX_H := 128

# Real 2K maps (Solar System Scope, CC BY 4.0). If a file is missing we fall back
# to the procedural surface below, so the game still runs with no art at all.
const MAPS := {
	"earth": "res://art/planets/2k_earth_daymap.jpg",
	"moon": "res://art/planets/2k_moon.jpg",
	"mars": "res://art/planets/2k_mars.jpg",
	"jupiter": "res://art/planets/2k_jupiter.jpg",
	"saturn": "res://art/planets/2k_saturn.jpg",
	"sun": "res://art/planets/2k_sun.jpg",
}
const CLOUD_MAP := "res://art/planets/2k_earth_clouds.jpg"
const RING_MAP := "res://art/planets/2k_saturn_ring_alpha.png"

const PLANETS := {
	"earth": {"seed": 11, "tilt": 23.4},
	"moon": {"seed": 22, "tilt": 6.7},
	"mars": {"seed": 33, "tilt": 25.2},
	"jupiter": {"seed": 44, "tilt": 3.1},
	"saturn": {"seed": 55, "tilt": 26.7},
	"sun": {"seed": 0, "tilt": 7.25},
}

const MOON_CRATERS := [
	{"lon": 0.2, "lat": 0.55, "r": 0.22, "d": 0.18},
	{"lon": 1.4, "lat": -0.1, "r": 0.30, "d": 0.14},
	{"lon": 2.3, "lat": 0.3, "r": 0.16, "d": 0.20},
	{"lon": 3.1, "lat": -0.5, "r": 0.24, "d": 0.16},
	{"lon": 4.2, "lat": 0.1, "r": 0.20, "d": 0.15},
	{"lon": 5.0, "lat": 0.6, "r": 0.18, "d": 0.18},
	{"lon": 5.7, "lat": -0.2, "r": 0.26, "d": 0.13},
	{"lon": 0.9, "lat": -0.7, "r": 0.15, "d": 0.22},
	{"lon": 2.9, "lat": 0.75, "r": 0.12, "d": 0.20},
	{"lon": 4.8, "lat": -0.65, "r": 0.17, "d": 0.16},
]

const MARS_CRATERS := [
	{"lon": 0.6, "lat": 0.3, "r": 0.18, "d": 0.09},
	{"lon": 1.9, "lat": -0.2, "r": 0.22, "d": 0.07},
	{"lon": 3.0, "lat": 0.6, "r": 0.14, "d": 0.08},
	{"lon": 4.1, "lat": -0.55, "r": 0.20, "d": 0.07},
	{"lon": 5.3, "lat": 0.1, "r": 0.16, "d": 0.08},
]

const ATMOSPHERE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;

void fragment() {
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.5);
	ALBEDO = vec3(0.22, 0.48, 1.0);
	ALPHA = rim * 0.55;
}
"""

const CLOUD_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

uniform sampler2D cloud_tex : source_color, filter_linear_mipmap;

void fragment() {
	float c = texture(cloud_tex, UV).r;
	ALBEDO = vec3(1.0);
	ALPHA = smoothstep(0.08, 0.62, c) * 0.90;
}
"""

static var _textures: Dictionary = {}
static var _cloud_texture: ImageTexture
static var _cloud_shader: Shader


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	var clouds := get_node_or_null("Tilt/Spin/Clouds")
	if clouds is Node3D:
		(clouds as Node3D).rotate_y(delta * 0.004)


## Spin around the planet's own (tilted) axis, not the world Y axis.
func spin_by(angle: float) -> void:
	var spin := get_node_or_null("Tilt/Spin")
	if spin is Node3D:
		(spin as Node3D).rotate_y(angle)


func _build() -> void:
	if has_node("Tilt"):
		return
	var data: Dictionary = PLANETS.get(planet_id, PLANETS["earth"])
	var tilt := Node3D.new()
	tilt.name = "Tilt"
	tilt.rotation_degrees = Vector3(0, 0, float(data.get("tilt", 0.0)))
	add_child(tilt)
	var spin := Node3D.new()
	spin.name = "Spin"
	tilt.add_child(spin)

	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 64
	mesh.rings = 32
	var mat := StandardMaterial3D.new()
	var map := _load_map(planet_id)
	mat.albedo_texture = map if map != null else _texture(planet_id)
	mat.roughness = 0.95
	mat.metallic = 0.0
	mat.metallic_specular = 0.12
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if planet_id == "sun":
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.93, 0.78)
	mesh.material = mat
	body.mesh = mesh
	spin.add_child(body)

	if planet_id == "earth":
		_add_clouds(spin)
		_add_atmosphere(spin)
	elif planet_id == "saturn":
		_add_rings(spin)


func _add_clouds(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Clouds"
	var sm := SphereMesh.new()
	sm.radius = 1.012
	sm.height = 2.024
	sm.radial_segments = 48
	sm.rings = 24
	var m: Material
	if ResourceLoader.exists(CLOUD_MAP):
		if _cloud_shader == null:
			_cloud_shader = Shader.new()
			_cloud_shader.code = CLOUD_SHADER
		var smat := ShaderMaterial.new()
		smat.shader = _cloud_shader
		smat.set_shader_parameter("cloud_tex", load(CLOUD_MAP))
		m = smat
	else:
		var std := StandardMaterial3D.new()
		std.albedo_texture = _get_cloud_texture()
		std.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		std.roughness = 1.0
		std.metallic_specular = 0.0
		std.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		m = std
	sm.material = m
	mi.mesh = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _add_atmosphere(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Atmosphere"
	var sm := SphereMesh.new()
	sm.radius = 1.045
	sm.height = 2.09
	sm.radial_segments = 48
	sm.rings = 24
	var sh := Shader.new()
	sh.code = ATMOSPHERE_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	sm.material = m
	mi.mesh = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _add_rings(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Rings"
	mi.mesh = _ring_mesh(1.35, 2.3, 96)
	var ring := _load_ring_texture()
	if ring != null:
		var m := StandardMaterial3D.new()
		m.albedo_texture = ring
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mi.material_override = m
	else:
		mi.material_override = _ring_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


# ---------------------------------------------------------------- textures

static func _load_map(id: String) -> Texture2D:
	var path := str(MAPS.get(id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func _load_ring_texture() -> Texture2D:
	if not ResourceLoader.exists(RING_MAP):
		return null
	return load(RING_MAP) as Texture2D


static func _texture(id: String) -> ImageTexture:
	if _textures.has(id):
		return _textures[id] as ImageTexture
	var img := _make_image(id)
	var tex := ImageTexture.create_from_image(img)
	_textures[id] = tex
	return tex


static func _get_cloud_texture() -> ImageTexture:
	if _cloud_texture:
		return _cloud_texture
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	var n := _noise(77, 1.0, 5)
	var n2 := _noise(177, 4.5, 4)
	for y in TEX_H:
		var v := (float(y) + 0.5) / float(TEX_H)
		var lat := (0.5 - v) * PI
		var cl := cos(lat)
		var sl := sin(lat)
		for x in TEX_W:
			var u := (float(x) + 0.5) / float(TEX_W)
			var lon := u * TAU
			var dir := Vector3(cl * cos(lon), sl, cl * sin(lon))
			var cover := _n01(n, dir * 2.6 + Vector3(2, 4, 6)) * 0.75
			cover += _n01(n2, dir * 7.0 + Vector3(1, 8, 3)) * 0.25
			var a := smoothstep(0.55, 0.74, cover) * 0.85
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_cloud_texture = ImageTexture.create_from_image(img)
	return _cloud_texture


static func _make_image(id: String) -> Image:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	var data: Dictionary = PLANETS.get(id, PLANETS["earth"])
	var seed_v := int(data.get("seed", 1))
	var n := _noise(seed_v, 1.0, 5)
	var n2 := _noise(seed_v + 100, 4.0, 4)
	var n3 := _noise(seed_v + 200, 9.0, 3)

	var crater_dirs: Array[Vector3] = []
	var crater_cos: Array[float] = []
	var crater_depth: Array[float] = []
	var crater_list: Array = []
	if id == "moon":
		crater_list = MOON_CRATERS
	elif id == "mars":
		crater_list = MARS_CRATERS
	for c in crater_list:
		var clat := float(c["lat"])
		var clon := float(c["lon"])
		crater_dirs.append(Vector3(cos(clat) * cos(clon), sin(clat), cos(clat) * sin(clon)))
		crater_cos.append(cos(float(c["r"])))
		crater_depth.append(float(c["d"]))

	for y in TEX_H:
		var v := (float(y) + 0.5) / float(TEX_H)
		var lat := (0.5 - v) * PI
		var cl := cos(lat)
		var sl := sin(lat)
		for x in TEX_W:
			var u := (float(x) + 0.5) / float(TEX_W)
			var lon := u * TAU
			var dir := Vector3(cl * cos(lon), sl, cl * sin(lon))
			var c: Color
			match id:
				"earth":
					c = _earth_color(dir, lat, n, n2, n3)
				"moon":
					c = _moon_color(dir, lat, n, n2, crater_dirs, crater_cos, crater_depth)
				"mars":
					c = _mars_color(dir, lat, n, n2, n3, crater_dirs, crater_cos, crater_depth)
				"jupiter":
					c = _jupiter_color(dir, lat, lon, n, n2)
				"saturn":
					c = _saturn_color(dir, lat, n, n2)
				"sun":
					c = Color(1.0, 0.50, 0.10).lerp(Color(1.0, 0.95, 0.60), _n01(n, dir * 5.0))
				_:
					c = Color(0.5, 0.5, 0.5)
			img.set_pixel(x, y, c)
	return img


static func _noise(seed_v: int, freq: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = octaves
	n.fractal_gain = 0.5
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	return n


static func _n01(n: FastNoiseLite, p: Vector3) -> float:
	return (n.get_noise_3dv(p) + 1.0) * 0.5


static func _earth_color(dir: Vector3, lat: float, n: FastNoiseLite, n2: FastNoiseLite, n3: FastNoiseLite) -> Color:
	var cont := _n01(n, dir * 1.15 + Vector3(10, 0, 0))
	var detail := _n01(n2, dir * 4.2 + Vector3(0, 7, 0))
	var h := cont * 0.72 + detail * 0.28
	var c: Color
	if h < 0.36:
		c = Color(0.02, 0.07, 0.22)
	elif h < 0.42:
		c = Color(0.03, 0.13, 0.36)
	elif h < 0.46:
		c = Color(0.05, 0.22, 0.48)
	elif h < 0.49:
		c = Color(0.17, 0.38, 0.32)
	elif h < 0.58:
		c = Color(0.10, 0.30, 0.10).lerp(Color(0.18, 0.42, 0.14), detail)
	elif h < 0.68:
		c = Color(0.28, 0.28, 0.14).lerp(Color(0.44, 0.38, 0.20), detail)
	else:
		c = Color(0.55, 0.52, 0.47)
	var dry := smoothstep(0.50, 0.62, _n01(n3, dir * 1.7 + Vector3(3, 9, 1)))
	if h >= 0.49:
		c = c.lerp(Color(0.63, 0.52, 0.32), dry * 0.35)
	var ice := smoothstep(0.80, 0.90, abs(lat) / (PI * 0.5))
	c = c.lerp(Color(0.92, 0.96, 1.0), ice)
	return c


static func _moon_color(dir: Vector3, lat: float, n: FastNoiseLite, n2: FastNoiseLite, cdirs: Array[Vector3], ccos: Array[float], cdep: Array[float]) -> Color:
	var h := _n01(n, dir * 2.4 + Vector3(5, 1, 2))
	var maria := _n01(n2, dir * 0.85 + Vector3(8, 3, 0))
	var g := 0.46 + h * 0.26
	if maria < 0.44:
		g *= 0.78
	var c := Color(g, g * 0.985, g * 0.94)
	c = _apply_craters(c, dir, cdirs, ccos, cdep)
	var ice := smoothstep(0.88, 0.96, abs(lat) / (PI * 0.5))
	c = c.lerp(Color(0.88, 0.90, 0.92), ice * 0.4)
	return c


static func _mars_color(dir: Vector3, lat: float, n: FastNoiseLite, n2: FastNoiseLite, n3: FastNoiseLite, cdirs: Array[Vector3], ccos: Array[float], cdep: Array[float]) -> Color:
	var h := _n01(n, dir * 2.1 + Vector3(4, 2, 9))
	var d := _n01(n2, dir * 5.5 + Vector3(1, 6, 3))
	var c := Color(0.36, 0.13, 0.06).lerp(Color(0.85, 0.40, 0.18), h)
	var dark := smoothstep(0.55, 0.82, _n01(n, dir * 0.85 + Vector3(2, 2, 4)))
	c = c.lerp(Color(0.24, 0.08, 0.04), dark * 0.55)
	c = c.lerp(Color(0.55, 0.28, 0.16), smoothstep(0.2, 0.7, _n01(n3, dir * 1.2)) * 0.25)
	c = _apply_craters(c, dir, cdirs, ccos, cdep)
	var ice := smoothstep(0.82, 0.93, abs(lat) / (PI * 0.5))
	c = c.lerp(Color(0.95, 0.90, 0.86), ice * 0.9)
	return c


static func _jupiter_color(dir: Vector3, lat: float, lon: float, n: FastNoiseLite, n2: FastNoiseLite) -> Color:
	var turb := (_n01(n, dir * 2.6 + Vector3(7, 1, 3)) - 0.5) * 0.11
	var l := lat + turb
	var band := sin(l * 18.0 + 0.6) * 0.5 + 0.5
	var fine := sin(l * 43.0 + 1.7) * 0.5 + 0.5
	var c := Color(0.93, 0.87, 0.73).lerp(Color(0.55, 0.33, 0.18), band * 0.64 + fine * 0.20)
	c = c.lerp(Color(0.95, 0.91, 0.82), _n01(n2, dir * 7.0) * 0.12)
	# Great Red Spot (south) and the smaller Oval BA (opposite longitude)
	var spot := _storm_oval(lon, lat, 2.15, -0.33, 0.34, 0.15)
	if spot > 0.0:
		c = c.lerp(Color(0.72, 0.24, 0.13), spot * 0.9)
	var oval := _storm_oval(lon, lat, 5.25, -0.46, 0.20, 0.10)
	if oval > 0.0:
		c = c.lerp(Color(0.52, 0.22, 0.15), oval * 0.75)
	return c


static func _storm_oval(lon: float, lat: float, center_lon: float, center_lat: float, w: float, h: float) -> float:
	var du := wrapf(lon - center_lon, -PI, PI) * cos(lat)
	var dv := lat - center_lat
	var e := (du / w) * (du / w) + (dv / h) * (dv / h)
	if e >= 1.0:
		return 0.0
	return smoothstep(0.0, 0.35, 1.0 - e)


static func _saturn_color(dir: Vector3, lat: float, n: FastNoiseLite, n2: FastNoiseLite) -> Color:
	var turb := (_n01(n, dir * 2.2 + Vector3(2, 5, 8)) - 0.5) * 0.05
	var l := lat + turb
	var band := sin(l * 15.0 + 0.4) * 0.5 + 0.5
	var c := Color(0.90, 0.82, 0.62).lerp(Color(0.68, 0.57, 0.38), band * 0.55)
	c = c.lerp(Color(0.96, 0.90, 0.74), _n01(n2, dir * 8.0) * 0.12)
	var hood := smoothstep(0.75, 0.95, abs(lat) / (PI * 0.5))
	return c.lerp(Color(0.55, 0.60, 0.60), hood * 0.20)


static func _apply_craters(c: Color, dir: Vector3, cdirs: Array[Vector3], ccos: Array[float], cdep: Array[float]) -> Color:
	var shade := 1.0
	for i in cdirs.size():
		var d := dir.dot(cdirs[i])
		if d <= ccos[i]:
			continue
		var t := (d - ccos[i]) / (1.0 - ccos[i])
		var center := smoothstep(0.0, 0.75, t)
		var rim := (1.0 - smoothstep(0.0, 0.22, t)) * smoothstep(0.0, 0.04, t)
		shade -= cdep[i] * center * 0.55
		shade += 0.05 * rim
	return Color(c.r * shade, c.g * shade, c.b * shade, c.a)


# ---------------------------------------------------------------- rings

static func _ring_mesh(inner: float, outer: float, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in segments + 1:
		var a := TAU * float(i) / float(segments)
		var ca := cos(a)
		var sa := sin(a)
		verts.append(Vector3(ca * inner, 0.0, sa * inner))
		verts.append(Vector3(ca * outer, 0.0, sa * outer))
		uvs.append(Vector2(0.0, float(i) / float(segments)))
		uvs.append(Vector2(1.0, float(i) / float(segments)))
	for i in segments:
		var b := i * 2
		idx.append(b)
		idx.append(b + 2)
		idx.append(b + 1)
		idx.append(b + 1)
		idx.append(b + 2)
		idx.append(b + 3)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


static func _ring_material() -> StandardMaterial3D:
	var g := Gradient.new()
	g.colors = PackedColorArray([
		Color(0.55, 0.50, 0.40, 0.0),
		Color(0.80, 0.72, 0.55, 0.62),
		Color(0.90, 0.82, 0.65, 0.75),
		Color(0.55, 0.48, 0.35, 0.10),
		Color(0.85, 0.78, 0.60, 0.60),
		Color(0.75, 0.68, 0.52, 0.45),
		Color(0.60, 0.55, 0.45, 0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.08, 0.45, 0.55, 0.62, 0.95, 1.0])
	var t := GradientTexture1D.new()
	t.gradient = g
	t.width = 128
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m
