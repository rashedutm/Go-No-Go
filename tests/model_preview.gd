# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Shows SpacecraftModel3D for each mission's test design + rockets (screenshot check).
# Run: godot --path . res://tests/model_preview.tscn
extends Node3D

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.05, 0.07, 0.14)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.55, 0.7)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	add_child(sun)
	var x := -12.0
	for m in ["earth", "moon", "mars", "jupiter", "saturn"]:
		var model := SpacecraftModel3D.build(Sim.make_test_design(m))
		model.position = Vector3(x, 0, 0)
		model.rotation.y = PI + 0.5
		add_child(model)
		x += 6.0
	var empty := SpacecraftModel3D.build({})
	empty.position = Vector3(-12, -5, 0)
	add_child(empty)
	var folded := SpacecraftModel3D.build(Sim.make_test_design("jupiter"))
	SpacecraftModel3D.deploy_wings(folded, 0.0)
	folded.position = Vector3(-4, -5, 0)
	add_child(folded)
	var rx := 4.0
	for lv in ["small", "medium", "heavy", "super"]:
		var r := SpacecraftModel3D.build_rocket(lv)
		r.scale = Vector3.ONE * 0.4
		r.position = Vector3(rx, -8, 0)
		add_child(r)
		rx += 3.0
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 22)
	add_child(cam)
