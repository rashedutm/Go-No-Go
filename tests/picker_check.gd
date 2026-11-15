# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Mission select: the difficulty buttons must stay at the same height for Easy / Normal / Hard.
extends Node

func _ready() -> void:
	MissionState.campaign = {"unlocked": ["earth", "moon", "mars", "jupiter"], "stars": {}, "best_score": {}}
	var map = load("res://scenes/campaign_map/campaign_map.tscn").instantiate()
	add_child(map)
	map._select("jupiter")
	var ys := []
	for lv in ["easy", "normal", "hard"]:
		map._difficulty._pick(lv)
		for i in 3:
			await get_tree().process_frame
		var b: Button = map._difficulty._buttons["easy"]
		ys.append("%s: buttons y=%d, brief button y=%d" % [lv, int(b.global_position.y), int(map._brief_btn.global_position.y)])
	for y in ys:
		print(y)
	get_tree().quit()
