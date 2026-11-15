# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Shows the web "Thanks for playing" exit screen (without quitting) for a screenshot.
extends Node

func _ready() -> void:
	add_child(load("res://scenes/title/title.tscn").instantiate())
	await get_tree().create_timer(0.5).timeout
	Sfx.open_menu()
	await get_tree().create_timer(0.3).timeout
	Sfx._menu_open = false
	Sfx._menu_root.visible = false
	get_tree().paused = true
	AudioServer.set_bus_mute(0, true)
	Sfx._show_goodbye()
