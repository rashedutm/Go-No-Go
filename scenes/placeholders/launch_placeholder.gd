# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Simple stand-in launch until Daniel's real 3D launch & cruise (scenes/launch_anim/launch_anim.tscn)
# exists: countdown, liftoff with a flame, camera follows, then straight into Mission Control.
# Click / Space / Enter skips. Owner: Member A.
extends Node3D

var _rocket: Node3D
var _flame: MeshInstance3D
var _cam: Camera3D
var _label: Label
var _sub: Label
var _t := 0.0
var _done := false

const COUNT_START := 3.0   # seconds of countdown
const FLIGHT := 4.0        # seconds of flight before cutting to Mission Control


func _ready() -> void:
	MenuPlanet.add_space(self, 300, 220.0)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-30, 130, 0)
	moon.light_energy = 0.8
	add_child(moon)
	add_child(_at(SpacecraftModel3D._box(Vector3(400, 0.2, 400), Color(0.07, 0.09, 0.08), 0.0, 0.9), Vector3(0, -0.1, 0)))
	add_child(_at(SpacecraftModel3D._box(Vector3(14, 1.0, 14), Color(0.38, 0.38, 0.4), 0.2, 0.8), Vector3(0, 0.5, 0)))
	var lv := str(MissionState.design.get("launch_vehicle", "medium"))
	_rocket = SpacecraftModel3D.build_rocket(lv if lv != "" else "medium")
	_rocket.scale = Vector3.ONE * 1.6
	_rocket.position = Vector3(0, 1.0, 0)
	add_child(_rocket)
	_flame = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 1.2
	cone.bottom_radius = 0.05
	cone.height = 6.0
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1, 0.6, 0.15)
	fm.emission_enabled = true
	fm.emission = Color(1, 0.55, 0.1)
	fm.emission_energy_multiplier = 4.0
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone.material = fm
	_flame.mesh = cone
	_flame.position = Vector3(0, -3.0, 0)
	_flame.visible = false
	_rocket.add_child(_flame)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1, 0.6, 0.2)
	glow.omni_range = 25
	glow.light_energy = 0.0
	glow.name = "Glow"
	_rocket.add_child(glow)
	_cam = Camera3D.new()
	_cam.fov = 55
	add_child(_cam)

	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 120)
	_label.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(140, 220)
	_label.size = Vector2(1000, 160)
	layer.add_child(_label)
	_sub = Label.new()
	_sub.add_theme_font_size_override("font_size", 24)
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_sub.add_theme_constant_override("outline_size", 8)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.position = Vector2(140, 380)
	_sub.size = Vector2(1000, 40)
	layer.add_child(_sub)
	var hint := Label.new()
	hint.text = "Click or press Space to skip"
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.7, 0.78, 0.95, 0.8)
	hint.position = Vector2(540, 690)
	layer.add_child(hint)
	Sfx.play("beep")


func _process(delta: float) -> void:
	var prev := _t
	_t += delta
	var mission := GameData.get_mission(MissionState.current_mission_id)
	if _t < COUNT_START:
		var n := int(ceil(COUNT_START - _t))
		_label.text = "T-%d" % n
		_sub.text = "%s  ·  launching to %s" % [mission.get("name", ""), mission.get("destination", "")]
		if int(ceil(COUNT_START - prev)) != n:
			Sfx.play("beep")
		_cam.position = Vector3(18, 6, 22)
		_cam.look_at(Vector3(0, 9, 0), Vector3.UP)
		return
	var ft := _t - COUNT_START
	if prev < COUNT_START:
		_label.text = "LIFTOFF!"
		_flame.visible = true
		_rocket.get_node("Glow").light_energy = 6.0
		Sfx.play("go")
	_flame.scale = Vector3.ONE * (1.0 + sin(_t * 40.0) * 0.08)
	_rocket.position.y = 1.0 + 0.5 * 9.0 * ft * ft   # constant acceleration
	var shake := Vector3(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15), 0) * clampf(1.5 - ft, 0.0, 1.0)
	_cam.position = Vector3(18, 6 + _rocket.position.y * 0.6, 22) + shake
	_cam.look_at(_rocket.position + Vector3(0, 8, 0), Vector3.UP)
	if ft > 1.5:
		_label.text = ""
		_sub.text = "Cruising to %s…" % mission.get("destination", "the target")
	if ft > FLIGHT:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	MissionState.go_to("mission_control")


func _at(node: Node3D, pos: Vector3) -> Node3D:
	node.position = pos
	return node
