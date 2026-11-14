# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Asset Store / CC0 models used around Mission Control:
#  - Computer Screen (Kenney, Furniture Kit, CC0) — flat desk monitor
#  - Chair01 (Abstract_Duck, Lowpoly Furniture Asset Pack, MIT) — office chair
class_name MissionProps
extends RefCounted

const COMPUTER_MODEL := preload("res://art/models/mission_control/computer_monitor.glb")
const CHAIR_MODEL := preload("res://art/models/mission_control/chair_office.glb")
const _DISPLAY_FONT := preload("res://ui/fonts/BarlowCondensed-SemiBold.ttf")
const _MONO_FONT := preload("res://ui/fonts/IBMPlexMono-Medium.ttf")

const COMPUTER_SCALE := 1.7
# The Kenney monitor is authored with its right edge at x=0 and front at +Z.
const MODEL_OFFSET := Vector3(0.1965, 0.0, -0.052)
const SCREEN_CENTER := Vector3(-0.1965, 0.1715, 0.0695)
const SCREEN_SIZE := Vector2(0.355, 0.213)


## A flat desk monitor with a small mission-control screen. The unique screen
## material is stored on the node so alert code can tint it.
static func computer(accent: Color, screen_title: String = "MISSION OPS") -> Node3D:
	var comp := Node3D.new()
	comp.name = "Computer"
	comp.scale = Vector3.ONE * COMPUTER_SCALE

	var root := Node3D.new()
	root.position = MODEL_OFFSET
	comp.add_child(root)

	var model := COMPUTER_MODEL.instantiate() as Node3D
	root.add_child(model)

	var sub := SubViewport.new()
	sub.name = "Screen"
	sub.size = Vector2i(512, 306)
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
	kicker.position = Vector2(18, 10)
	sub.add_child(kicker)

	var title := _label(Color(0.86, 0.94, 1.0), 54, _DISPLAY_FONT, screen_title)
	title.position = Vector2(16, 24)
	sub.add_child(title)

	var status := _label(accent, 12, _MONO_FONT, "LINK NOMINAL  ·  ALL STATIONS GO")
	status.position = Vector2(18, 94)
	sub.add_child(status)

	var div := ColorRect.new()
	div.position = Vector2(18, 120)
	div.size = Vector2(476, 1)
	div.color = Color(accent.r, accent.g, accent.b, 0.35)
	sub.add_child(div)

	var names := ["POWER", "SIGNAL", "MEMORY"]
	var vals := [0.84, 0.62, 0.71]
	for i in 3:
		var y := 138 + i * 28
		var k := _label(Color(0.55, 0.65, 0.8), 11, _MONO_FONT, names[i])
		k.position = Vector2(18, y)
		sub.add_child(k)
		var track := ColorRect.new()
		track.position = Vector2(104, y + 5)
		track.size = Vector2(280, 8)
		track.color = Color(0.06, 0.1, 0.16)
		sub.add_child(track)
		var fill := ColorRect.new()
		fill.position = track.position
		fill.size = Vector2(280.0 * float(vals[i]), 8)
		fill.color = accent
		sub.add_child(fill)
		var pct := _label(accent, 11, _MONO_FONT, "%d%%" % int(vals[i] * 100.0))
		pct.position = Vector2(398, y)
		sub.add_child(pct)

	var foot := _label(Color(0.42, 0.52, 0.68), 11, _MONO_FONT, "GO/NO-GO  ·  FLIGHT OPERATIONS")
	foot.position = Vector2(18, 276)
	sub.add_child(foot)

	sub.render_target_update_mode = SubViewport.UPDATE_ONCE

	# Screen quad sits just in front of the Kenney monitor's display.
	var screen := MeshInstance3D.new()
	screen.name = "Display"
	var quad := QuadMesh.new()
	quad.size = SCREEN_SIZE
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = sub.get_texture()
	mat.albedo_color = Color.WHITE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	quad.material = mat
	screen.mesh = quad
	screen.position = SCREEN_CENTER
	root.add_child(screen)
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
