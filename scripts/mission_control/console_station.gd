# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# One interactive console in the Mission Control room: desk, monitor with a glowing screen,
# a sign, a light. set_alert(true) makes the screen and light blink red. Owner: Member B (Emon).
class_name ConsoleStation
extends Node3D

const Props := preload("res://scripts/mission_control/mission_props.gd")

var key := ""
var title := ""
var color := Color.WHITE
var alert := false

var _screen_mat: StandardMaterial3D
var _light: OmniLight3D
var _t := 0.0


## The console faces +Z (the operator stands on the +Z side, looking at the wall screen at -Z).
func setup(p_key: String, p_title: String, p_color: Color) -> void:
	key = p_key
	title = p_title
	color = p_color
	# desk
	MCBuild.box(self, Vector3(2.2, 0.85, 1.0), Vector3(0, 0.425, 0), Color(0.28, 0.32, 0.42), true)
	MCBuild.box(self, Vector3(2.25, 0.05, 1.05), Vector3(0, 0.875, 0), Color(0.1, 0.11, 0.14))
	MCBuild.box(self, Vector3(2.2, 0.06, 0.06), Vector3(0, 0.86, 0.52), p_color, false, 1.5)   # accent strip
	# desk clutter: keyboard + mouse
	MCBuild.box(self, Vector3(0.72, 0.035, 0.24), Vector3(0, 0.91, 0.18), Color(0.05, 0.06, 0.08), true)
	MCBuild.box(self, Vector3(0.11, 0.03, 0.17), Vector3(0.55, 0.91, 0.18), Color(0.05, 0.06, 0.08), true)
	# monitors (Asset Store sci-fi computer with a small console UI)
	var computer := Props.computer(color, p_title)
	computer.position = Vector3(0, 0.9, -0.30)
	# Angle side consoles inward toward the room centre and tilt the screen up
	# slightly so it reads from the floor, not just from the operator point.
	computer.rotation.y = clampf(atan2(-global_position.x, -global_position.z), -1.0, 1.0)
	computer.rotation.x = 0.10
	add_child(computer)
	_screen_mat = computer.get_meta("screen_material", null) as StandardMaterial3D
	# chair (Asset Store low-poly office chair, facing the desk)
	var chair := Props.chair()
	chair.position = Vector3(0, 0, 0.98)
	add_child(chair)
	# sign
	MCBuild.label(self, p_title, Vector3(0, 1.95, -0.25), p_color, 56, 0.005)
	# light
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 1.9, 0.4)
	_light.omni_range = 3.5
	_light.light_color = p_color
	_light.light_energy = 0.8
	add_child(_light)


func _reset_screen() -> void:
	if _screen_mat:
		_screen_mat.albedo_color = Color.WHITE


func set_alert(on: bool) -> void:
	alert = on
	if not on:
		_reset_screen()
		_light.light_color = color
		_light.light_energy = 0.8


func _process(delta: float) -> void:
	if not alert:
		return
	_t += delta
	var on := fmod(_t, 0.6) < 0.3
	if _screen_mat:
		_screen_mat.albedo_color = Color(1.0, 0.22, 0.18) if on else Color(0.22, 0.03, 0.02)
	_light.light_color = Color(1, 0.2, 0.1)
	_light.light_energy = 2.5 if on else 0.6


## World-space point where the operator stands (in front of the desk).
func operator_point() -> Vector3:
	return global_transform * Vector3(0, 0, 1.1)
