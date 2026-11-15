# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# SpacecraftModel3D: builds a low-poly 3D spacecraft (and rocket) from a design using primitives.
# Contract: README §8.1 "3D contracts". Owner: Member A. Used by the hangar, Danial's launch/space view/debrief
# and Emon's wall screen.
#
#   var model := SpacecraftModel3D.build(MissionState.design)
#   add_child(model)
#   SpacecraftModel3D.deploy_wings(model, 0.0)   # folded (for launch), 1.0 = open
#
# Named children: "Bus", "SolarWings" (wing pivots inside), "RTGs", "Antenna", "Instruments", "Vault", "Engine".
class_name SpacecraftModel3D
extends RefCounted

const BUS_SIZE := {"cube": 0.6, "small": 1.2, "medium": 1.7, "large": 2.3}
const WING_LEN := {"solar_cube": 0.7, "solar_s": 1.4, "solar_m": 2.2, "solar_l": 3.0, "solar_xl": 4.2}
const TYPE_COLORS := {
	"imaging": Color(0.3, 0.75, 1.0), "spectro": Color(0.7, 0.45, 1.0), "radar": Color(1.0, 0.55, 0.25),
	"fields": Color(0.35, 1.0, 0.55), "interior": Color(1.0, 0.35, 0.45), "mapping": Color(1.0, 0.85, 0.25),
	"sampling": Color(0.92, 0.92, 0.92),
}
const FOLD_ANGLE := 1.5   # radians: wing folded flat against the bus side


static func build(design: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Spacecraft"
	var bus_id: String = str(design.get("bus", ""))
	var s: float = BUS_SIZE.get(bus_id, 1.2)
	var placeholder := bus_id == ""

	# ---- bus (gold foil box with a darker frame)
	var bus := _box(Vector3(s, s, s), Color(0.85, 0.66, 0.22) if not placeholder else Color(0.35, 0.4, 0.5), 0.35, 0.55)
	bus.name = "Bus"
	root.add_child(bus)
	for y in [-0.5, 0.5]:
		var rim := _box(Vector3(s * 1.03, s * 0.06, s * 1.03), Color(0.45, 0.42, 0.38), 0.6, 0.4)
		rim.position.y = y * s
		bus.add_child(rim)
	if placeholder:
		return root

	# ---- engine nozzle underneath
	var engine := _cyl(s * 0.12, s * 0.22, s * 0.3, Color(0.3, 0.3, 0.33), 0.8, 0.3)
	engine.name = "Engine"
	engine.position.y = -s * 0.5 - s * 0.15
	root.add_child(engine)

	# ---- radiation vault (grey box on top)
	var lvl := int(GameData.get_item("power", design.get("shielding", "")).get("shield_level", 0))
	var vault := Node3D.new()
	vault.name = "Vault"
	root.add_child(vault)
	if lvl > 0:
		var v := _box(Vector3(s * 0.55, s * (0.18 + 0.08 * lvl), s * 0.55), Color(0.62, 0.64, 0.68), 0.9, 0.35)
		v.position.y = s * 0.5 + s * (0.09 + 0.04 * lvl)
		vault.add_child(v)

	# ---- solar wings: one pair per solar source, stacked; pivots at the bus sides
	var wings := Node3D.new()
	wings.name = "SolarWings"
	root.add_child(wings)
	var rtgs := Node3D.new()
	rtgs.name = "RTGs"
	root.add_child(rtgs)
	var wing_i := 0
	var rtg_i := 0
	for pid in design.get("power", []):
		var p := GameData.get_item("power", pid)
		match p.get("kind", ""):
			"solar":
				var length: float = WING_LEN.get(pid, 1.5)
				var width: float = clampf(length * 0.35, 0.35, 1.3)
				var y := (wing_i * 0.32 - 0.1) * s
				for side in [-1.0, 1.0]:
					var pivot := Node3D.new()
					pivot.name = "Wing%s%d" % ["L" if side < 0 else "R", wing_i]
					pivot.position = Vector3(side * s * 0.5, y, 0)
					pivot.set_meta("side", side)
					wings.add_child(pivot)
					var boom := _box(Vector3(0.25, 0.05, 0.05), Color(0.75, 0.75, 0.78), 0.8, 0.3)
					boom.position.x = side * 0.125
					pivot.add_child(boom)
					var panel := _box(Vector3(length, width, 0.04), Color(0.1, 0.2, 0.55), 0.4, 0.25)
					panel.position.x = side * (0.25 + length * 0.5)
					pivot.add_child(panel)
					# cell lines
					var n := int(length / 0.35)
					for k in range(1, n):
						var line := _box(Vector3(0.015, width * 0.98, 0.045), Color(0.45, 0.6, 1.0), 0.2, 0.4)
						line.position.x = side * (0.25 + k * length / n)
						pivot.add_child(line)
				wing_i += 1
			"rtg":
				var rtg := Node3D.new()
				var ang := PI * 0.75 + rtg_i * PI * 0.5
				var dir := Vector3(cos(ang), 0, sin(ang))
				var boom := _box(Vector3(0.05, 0.05, s * 0.6), Color(0.7, 0.7, 0.72), 0.8, 0.3)
				boom.position = dir * s * 0.55 + Vector3(0, -s * 0.3, 0)
				boom.look_at_from_position(boom.position, boom.position + dir, Vector3.UP)
				rtgs.add_child(boom)
				var body := _cyl(0.16, 0.16, 0.6, Color(0.25, 0.25, 0.27), 0.7, 0.4)
				body.position = dir * (s * 0.85 + 0.15) + Vector3(0, -s * 0.3, 0)
				rtg.add_child(body)
				for f in 4:   # cooling fins
					var fin := _box(Vector3(0.42, 0.55, 0.02), Color(0.3, 0.3, 0.32), 0.7, 0.4)
					fin.position = body.position
					fin.rotation.y = f * PI / 4
					rtg.add_child(fin)
				var glow := _sphere(0.07, Color(1.0, 0.35, 0.1), true)
				glow.position = body.position + Vector3(0, 0.32, 0)
				rtg.add_child(glow)
				rtgs.add_child(rtg)
				rtg_i += 1

	# ---- antenna on top
	var ant := Node3D.new()
	ant.name = "Antenna"
	root.add_child(ant)
	var top := s * 0.5 + (s * 0.3 if lvl > 0 else 0.0)
	match str(design.get("antenna", "")):
		"hga":
			ant.add_child(_at(_cyl(0.04, 0.04, 0.45, Color(0.8, 0.8, 0.82)), Vector3(0, top + 0.22, 0)))
			var dish := _cyl(1.1, 0.12, 0.35, Color(0.95, 0.95, 0.97), 0.1, 0.6)
			dish.position.y = top + 0.6
			ant.add_child(dish)
			ant.add_child(_at(_cyl(0.03, 0.03, 0.5, Color(0.7, 0.7, 0.7)), Vector3(0, top + 0.95, 0)))
		"mga":
			ant.add_child(_at(_cyl(0.03, 0.03, 0.3, Color(0.8, 0.8, 0.82)), Vector3(0, top + 0.15, 0)))
			var dish2 := _cyl(0.45, 0.08, 0.18, Color(0.95, 0.95, 0.97), 0.1, 0.6)
			dish2.position.y = top + 0.38
			ant.add_child(dish2)
		"lga":
			ant.add_child(_at(_cyl(0.02, 0.02, 0.7, Color(0.85, 0.85, 0.88)), Vector3(s * 0.3, top + 0.35, s * 0.3)))
			ant.add_child(_at(_sphere(0.06, Color(0.9, 0.9, 0.95)), Vector3(s * 0.3, top + 0.72, s * 0.3)))

	# ---- instruments on the front face (-Z), in a grid
	var inst_node := Node3D.new()
	inst_node.name = "Instruments"
	root.add_child(inst_node)
	var inst: Array = design.get("instruments", [])
	var cols := 3
	for i in inst.size():
		var it := GameData.get_item("instruments", inst[i])
		var col: Color = TYPE_COLORS.get(it.get("type", ""), Color.WHITE)
		var cell := s / cols
		var px := (i % cols - (cols - 1) / 2.0) * cell
		var py := (0.25 - int(i / cols) * 0.33) * s
		var box := _box(Vector3(cell * 0.7, cell * 0.55, cell * 0.5), col, 0.3, 0.45)
		box.position = Vector3(px, py, -s * 0.5 - cell * 0.22)
		inst_node.add_child(box)
		var lens := _cyl(cell * 0.16, cell * 0.16, cell * 0.12, Color(0.05, 0.05, 0.08), 0.2, 0.1)
		lens.rotation.x = PI / 2
		lens.position = box.position + Vector3(0, 0, -cell * 0.3)
		inst_node.add_child(lens)
	return root


## t: 0 = wings folded against the bus (launch), 1 = fully open.
static func deploy_wings(model: Node3D, t: float) -> void:
	var wings := model.get_node_or_null("SolarWings")
	if wings == null:
		return
	t = clampf(t, 0.0, 1.0)
	for pivot in wings.get_children():
		var side: float = pivot.get_meta("side", 1.0)
		pivot.rotation.z = lerpf(-side * FOLD_ANGLE, 0.0, t)


## A simple rocket for the chosen launch vehicle (pad height ~ 6–16 m). Origin at the base.
## Named children: "Stage1", "Stage2", "Fairing" (so a launch animation can separate them).
static func build_rocket(launch_vehicle_id: String) -> Node3D:
	var dims: Array = {
		"rideshare": [0.9, 9.0], "small": [0.8, 7.0], "medium": [1.3, 11.0],
		"heavy": [1.6, 13.0], "super": [2.2, 16.0],
	}.get(launch_vehicle_id, [1.0, 9.0])
	var r: float = dims[0]
	var h: float = dims[1]
	var root := Node3D.new()
	root.name = "Rocket"
	var white := Color(0.93, 0.94, 0.96)
	var s1 := _cyl(r, r, h * 0.55, white, 0.2, 0.5)
	s1.name = "Stage1"
	s1.position.y = h * 0.275
	root.add_child(s1)
	var band := _cyl(r * 1.01, r * 1.01, h * 0.04, Color(0.15, 0.2, 0.35), 0.3, 0.5)
	band.position.y = h * 0.45
	s1.add_child(band)
	for k in 4:   # fins
		var fin := _box(Vector3(0.08, h * 0.12, r * 0.9), Color(0.15, 0.2, 0.35), 0.3, 0.5)
		var a := k * PI / 2
		fin.position = Vector3(cos(a) * r, -h * 0.2, sin(a) * r)
		fin.rotation.y = -a
		s1.add_child(fin)
	if launch_vehicle_id in ["heavy", "super"]:   # side boosters
		for side in [-1.0, 1.0]:
			var b := _cyl(r * 0.55, r * 0.55, h * 0.42, white, 0.2, 0.5)
			b.position = Vector3(side * r * 1.55, -h * 0.065, 0)
			s1.add_child(b)
			var cone := _cyl(0.02, r * 0.55, r * 0.9, white, 0.2, 0.5)
			cone.position = b.position + Vector3(0, h * 0.21 + r * 0.45, 0)
			s1.add_child(cone)
	var s2 := _cyl(r * 0.85, r, h * 0.25, white, 0.2, 0.5)
	s2.name = "Stage2"
	s2.position.y = h * 0.675
	root.add_child(s2)
	var fairing := _cyl(0.02, r * 0.85, h * 0.2, Color(0.95, 0.75, 0.3), 0.2, 0.5)
	fairing.name = "Fairing"
	fairing.position.y = h * 0.9
	root.add_child(fairing)
	return root


# ---------------------------------------------------------------- primitive helpers

static func _mat(color: Color, metallic := 0.3, roughness := 0.5, emissive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.0
	return m


static func _box(size: Vector3, color: Color, metallic := 0.3, roughness := 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color, metallic, roughness)
	mi.mesh = mesh
	return mi


static func _cyl(top_r: float, bottom_r: float, height: float, color: Color, metallic := 0.3, roughness := 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 24
	mesh.material = _mat(color, metallic, roughness)
	mi.mesh = mesh
	return mi


static func _sphere(radius: float, color: Color, emissive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = _mat(color, 0.1, 0.4, emissive)
	mi.mesh = mesh
	return mi


static func _at(node: Node3D, pos: Vector3) -> Node3D:
	node.position = pos
	return node
