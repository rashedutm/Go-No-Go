# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# MCBuild: small helpers to build the 3D Mission Control room from primitives (with collisions).
# Owner: Member B (Emon).
class_name MCBuild
extends RefCounted


static func mat(color: Color, emission := 0.0, metallic := 0.1, roughness := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


## A box mesh; if solid, wrapped in a StaticBody3D with a matching collision box.
static func box(parent: Node, size: Vector3, pos: Vector3, color: Color, solid := false, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat(color, emission)
	mi.mesh = bm
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		body.add_child(mi)
		parent.add_child(body)
	else:
		mi.position = pos
		parent.add_child(mi)
	return mi


static func label(parent: Node, text: String, pos: Vector3, color: Color, font_size := 64, pixel := 0.006) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = pixel
	l.modulate = color
	l.outline_size = 10
	l.position = pos
	parent.add_child(l)
	return l
