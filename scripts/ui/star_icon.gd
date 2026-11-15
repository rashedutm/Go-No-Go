# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# StarIcon: a 5-point star drawn as a shape (the ★/☆ characters aren't in our fonts, and
# web browsers have no system font to borrow them from, so text stars showed as boxes).
class_name StarIcon
extends Control

var filled := false:
	set(v):
		filled = v
		queue_redraw()
var color := Color(0.4, 0.45, 0.55):
	set(v):
		color = v
		queue_redraw()


func _init(p_size := 32.0) -> void:
	custom_minimum_size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r_out := minf(size.x, size.y) * 0.5
	var r_in := r_out * 0.45
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var r := r_out if i % 2 == 0 else r_in
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	if filled:
		draw_colored_polygon(pts, color)
	else:
		pts.append(pts[0])
		draw_polyline(pts, color, 2.0, true)
