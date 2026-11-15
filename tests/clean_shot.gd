# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Title scene with every UI layer hidden (for store art). Run with --write-movie.
extends Node

func _ready() -> void:
	var t = load("res://scenes/title/title.tscn").instantiate()
	add_child(t)
	await get_tree().process_frame
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		n.visible = false
