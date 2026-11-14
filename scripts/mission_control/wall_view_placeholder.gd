# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Stand-in for Daniel's space_view.tscn on the big wall screen: the mission's planet with the
# spacecraft orbiting it. Same API as the contract (setup / set_status / set_time_scale).
# Owner: Member B (Emon). Replaced automatically once scenes/space/space_view.tscn exists.
extends Node3D

const PLANET_SCALE := {"earth": 3.0, "moon": 2.2, "mars": 2.4, "jupiter": 3.4, "saturn": 2.8}

var _orbit: Node3D
var _planet: Node3D
var _status := "normal"
var _speed := 0.3
var _light: DirectionalLight3D


func setup(design: Dictionary) -> void:
	MenuPlanet.add_space(self, 200, 150.0)
	_light = DirectionalLight3D.new()
	_light.rotation_degrees = Vector3(-20, -60, 0)
	_light.light_energy = 1.3
	add_child(_light)
	var mid: String = design.get("mission_id", "earth")
	_planet = MenuPlanet.make(mid)
	_planet.scale = Vector3.ONE * PLANET_SCALE.get(mid, 2.5)
	add_child(_planet)
	_orbit = Node3D.new()
	_orbit.rotation_degrees = Vector3(14, 0, -8)
	add_child(_orbit)
	var craft := SpacecraftModel3D.build(design)
	craft.scale = Vector3.ONE * 0.45
	craft.position = Vector3(PLANET_SCALE.get(mid, 2.5) + 2.2, 0, 0)
	_orbit.add_child(craft)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.2, 8.5)
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)


func set_status(status: String) -> void:
	_status = status
	if _light:
		_light.light_color = Color(1, 0.6, 0.3) if status == "solar_storm" else Color.WHITE
		_light.light_energy = 0.5 if status == "safe_mode" else 1.3


func set_time_scale(days_per_second: float) -> void:
	_speed = clampf(0.1 + days_per_second * 0.05, 0.1, 2.0)


func _process(delta: float) -> void:
	if _orbit:
		_orbit.rotation.y += delta * _speed
	if _planet:
		_planet.rotation.y += delta * 0.05
