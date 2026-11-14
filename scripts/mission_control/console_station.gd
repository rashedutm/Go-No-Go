# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# One interactive console in the Mission Control room: desk, monitor with a glowing screen,
# a sign, a light. set_alert(true) makes the screen and light blink red. Owner: Member B (Emon).
class_name ConsoleStation
extends Node3D

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
	# monitors
	MCBuild.box(self, Vector3(1.5, 0.85, 0.08), Vector3(0, 1.4, -0.25), Color(0.08, 0.08, 0.1))
	var screen := MCBuild.box(self, Vector3(1.38, 0.73, 0.02), Vector3(0, 1.4, -0.2), p_color.darkened(0.4), false, 1.2)
	_screen_mat = screen.mesh.material
	for side in [-1.0, 1.0]:
		MCBuild.box(self, Vector3(0.6, 0.45, 0.06), Vector3(side * 0.95, 1.2, -0.15), Color(0.08, 0.08, 0.1))
		MCBuild.box(self, Vector3(0.54, 0.39, 0.02), Vector3(side * 0.95, 1.2, -0.11), p_color.darkened(0.6), false, 0.8)
	# chair
	MCBuild.box(self, Vector3(0.55, 0.08, 0.55), Vector3(0, 0.5, 0.95), Color(0.15, 0.15, 0.18))
	MCBuild.box(self, Vector3(0.55, 0.6, 0.08), Vector3(0, 0.85, 1.22), Color(0.15, 0.15, 0.18))
	# sign
	MCBuild.label(self, p_title, Vector3(0, 1.98, -0.25), p_color, 56, 0.005)
	# light
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 1.9, 0.4)
	_light.omni_range = 3.5
	_light.light_color = p_color
	_light.light_energy = 0.8
	add_child(_light)


func set_alert(on: bool) -> void:
	alert = on
	if not on:
		_screen_mat.albedo_color = color.darkened(0.4)
		_screen_mat.emission = color.darkened(0.4)
		_light.light_color = color
		_light.light_energy = 0.8


func _process(delta: float) -> void:
	if not alert:
		return
	_t += delta
	var on := fmod(_t, 0.6) < 0.3
	var c := Color(1.0, 0.15, 0.1) if on else Color(0.35, 0.05, 0.05)
	_screen_mat.albedo_color = c
	_screen_mat.emission = c
	_light.light_color = Color(1, 0.2, 0.1)
	_light.light_energy = 2.5 if on else 0.6


## World-space point where the operator stands (in front of the desk).
func operator_point() -> Vector3:
	return global_transform * Vector3(0, 0, 1.1)
