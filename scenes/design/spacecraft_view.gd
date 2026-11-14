# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Draws a simple cartoon of the current spacecraft design (no image assets needed).
# Bus size, solar wings, RTGs, antenna, instruments and the radiation vault all show up.
# Owner: Member A.
extends Control

var design: Dictionary = {}

const TYPE_COLORS := {
	"imaging": Color(0.35, 0.8, 1.0), "spectro": Color(0.75, 0.5, 1.0), "radar": Color(1.0, 0.6, 0.3),
	"fields": Color(0.4, 1.0, 0.6), "interior": Color(1.0, 0.4, 0.5), "mapping": Color(1.0, 0.9, 0.3),
	"sampling": Color(0.9, 0.9, 0.9),
}


func _draw() -> void:
	var c := size / 2.0 + Vector2(0, 10)
	# starfield
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		draw_circle(Vector2(rng.randf() * size.x, rng.randf() * size.y), rng.randf_range(0.5, 1.5), Color(1, 1, 1, rng.randf_range(0.2, 0.7)))

	var bus := GameData.get_item("buses", design.get("bus", ""))
	if bus.is_empty():
		_label(Vector2(10, 22), "No spacecraft bus yet.\nThe Engineer picks one.")
		return
	var half: float = {"cube": 18.0, "small": 30.0, "medium": 42.0, "large": 54.0}.get(bus["id"], 36.0)
	var body := Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0)

	# solar wings (stacked pairs) and RTGs
	var wing_i := 0
	var rtg_i := 0
	for pid in design.get("power", []):
		var p := GameData.get_item("power", pid)
		if p.get("kind", "") == "solar":
			var length: float = {"solar_cube": 22.0, "solar_s": 40.0, "solar_m": 60.0, "solar_l": 80.0, "solar_xl": 100.0}.get(pid, 50.0)
			var y := c.y - half * 0.6 + wing_i * 16.0
			for dir in [-1.0, 1.0]:
				var x0: float = c.x + dir * half
				var x1: float = x0 + dir * length
				draw_line(Vector2(x0, y + 5), Vector2(x0 + dir * 6, y + 5), Color(0.8, 0.8, 0.85), 2.0)
				var r := Rect2(Vector2(minf(x0 + dir * 6, x1), y), Vector2(absf(x1 - x0) - 6, 11))
				draw_rect(r, Color(0.15, 0.3, 0.75))
				var k := 0.0
				while k < r.size.x:
					draw_line(Vector2(r.position.x + k, y), Vector2(r.position.x + k, y + 11), Color(0.4, 0.6, 1.0, 0.6), 1.0)
					k += 8.0
			wing_i += 1
		elif p.get("kind", "") == "rtg":
			var base := Vector2(c.x - half + 10 + rtg_i * 22, c.y + half)
			draw_line(base, base + Vector2(-6, 18), Color(0.7, 0.7, 0.7), 2.0)
			draw_rect(Rect2(base + Vector2(-14, 18), Vector2(14, 22)), Color(0.3, 0.3, 0.32))
			draw_circle(base + Vector2(-7, 29), 4, Color(1, 0.4, 0.2, 0.8))
			rtg_i += 1

	# body + vault
	var shield := int(GameData.get_item("power", design.get("shielding", "")).get("shield_level", 0))
	draw_rect(body, Color(0.85, 0.7, 0.3))   # gold foil
	draw_rect(body.grow(-4), Color(0.75, 0.6, 0.25))
	if shield > 0:
		draw_rect(body.grow(-half * 0.45), Color(0.55, 0.57, 0.62))
		draw_rect(body.grow(-half * 0.45), Color(0.3, 0.32, 0.36), false, 2.0 * shield)
	draw_rect(body, Color(0.45, 0.35, 0.1), false, 2.0)

	# antenna on top
	var top := Vector2(c.x, body.position.y)
	match design.get("antenna", ""):
		"hga":
			draw_line(top, top + Vector2(0, -14), Color(0.85, 0.85, 0.9), 3.0)
			draw_arc(top + Vector2(0, -6), 30, PI + 0.35, TAU - 0.35, 24, Color(0.92, 0.92, 0.96), 6.0)
		"mga":
			draw_line(top, top + Vector2(0, -12), Color(0.85, 0.85, 0.9), 3.0)
			draw_arc(top + Vector2(0, -6), 16, PI + 0.4, TAU - 0.4, 16, Color(0.92, 0.92, 0.96), 4.0)
		"lga":
			draw_line(top, top + Vector2(0, -22), Color(0.85, 0.85, 0.9), 2.0)
			draw_circle(top + Vector2(0, -22), 3, Color(0.92, 0.92, 0.96))

	# instruments along the bottom face
	var inst: Array = design.get("instruments", [])
	for i in inst.size():
		var it := GameData.get_item("instruments", inst[i])
		var col: Color = TYPE_COLORS.get(it.get("type", ""), Color.WHITE)
		var w := (body.size.x - 8) / maxf(inst.size(), 1)
		var r := Rect2(Vector2(body.position.x + 4 + i * w, body.end.y - 14), Vector2(w - 3, 10))
		draw_rect(r, col)

	var s := Sim.summarize(design)
	_label(Vector2(10, size.y - 10), "Launch mass %d kg  |  %d instruments" % [s["wet_mass_kg"], inst.size()])


func _label(pos: Vector2, text: String) -> void:
	var font := get_theme_default_font()
	var y := pos.y
	for line in text.split("\n"):
		draw_string(font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.9, 1.0))
		y += 18
