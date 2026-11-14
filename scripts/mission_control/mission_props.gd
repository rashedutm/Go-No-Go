# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Asset Store models used around Mission Control. Both are low-poly and CC0/MIT.
#  - Prop_Computer (Quaternius, Modular Sci-Fi MegaKit, CC0)
#  - Chair01 (Abstract_Duck, Lowpoly Furniture Asset Pack, MIT)
class_name MissionProps
extends RefCounted

const COMPUTER_MODEL := preload("res://art/models/mission_control/Prop_Computer.gltf")
const CHAIR_MODEL := preload("res://art/models/mission_control/chair_office.glb")
const _DISPLAY_FONT := preload("res://ui/fonts/BarlowCondensed-SemiBold.ttf")
const _MONO_FONT := preload("res://ui/fonts/IBMPlexMono-Medium.ttf")

const COMPUTER_SCALE := 1.15


## A sci-fi terminal with a small mission-control screen. The unique screen
## material is stored on the node so alert code can tint it.
static func computer(accent: Color, screen_title: String = "MISSION OPS") -> Node3D:
	var comp := COMPUTER_MODEL.instantiate() as Node3D
	comp.name = "Computer"
	comp.scale = Vector3.ONE * COMPUTER_SCALE

	var sub := SubViewport.new()
	sub.name = "Screen"
	sub.size = Vector2i(512, 264)
	sub.disable_3d = true
	sub.transparent_bg = false
	comp.add_child(sub)

	var bg := ColorRect.new()
	bg.color = Color(0.008, 0.018, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(bg)

	var top := ColorRect.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(512, 3)
	top.color = accent
	sub.add_child(top)

	var kicker := _label(accent, 12, _MONO_FONT, "MISSION CONTROL")
	kicker.position = Vector2(18, 8)
	sub.add_child(kicker)

	var title := _label(Color(0.86, 0.94, 1.0), 46, _DISPLAY_FONT, screen_title)
	title.position = Vector2(16, 20)
	sub.add_child(title)

	var status := _label(accent, 12, _MONO_FONT, "LINK NOMINAL  ·  ALL STATIONS GO")
	status.position = Vector2(18, 74)
	sub.add_child(status)

	var div := ColorRect.new()
	div.position = Vector2(18, 96)
	div.size = Vector2(476, 1)
	div.color = Color(accent.r, accent.g, accent.b, 0.35)
	sub.add_child(div)

	var bar := ColorRect.new()
	bar.position = Vector2(18, 104)
	bar.size = Vector2(220, 4)
	bar.color = accent
	sub.add_child(bar)

	sub.render_target_update_mode = SubViewport.UPDATE_ONCE

	var mat := _unique_screen_material(comp)
	if mat:
		var tex := sub.get_texture()
		mat.albedo_texture = tex
		mat.albedo_color = Color.WHITE
		mat.emission_enabled = false
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		comp.set_meta("screen_material", mat)
	return comp


## A low-poly office chair, rotated to face a desk at -Z.
static func chair() -> Node3D:
	var ch := CHAIR_MODEL.instantiate() as Node3D
	ch.name = "Chair"
	ch.rotation.y = PI
	# The source model is authored 2 m off-origin; keep the wrapper at the desk.
	for child in ch.get_children():
		if child is Node3D:
			(child as Node3D).position = Vector3.ZERO
	return ch


static func _label(color: Color, font_size: int, font: Font, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


static func _unique_screen_material(root: Node) -> StandardMaterial3D:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i)
			if mat is StandardMaterial3D and str(mat.resource_name).contains("Decal"):
				var unique := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				mi.set_surface_override_material(i, unique)
				return unique
	return null
