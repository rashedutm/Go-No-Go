# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# 2D telemetry screens shown on the Mission Control walls (rendered inside SubViewports).
#  - mode "graph": scrolling line graph with several series (0..100 scale)
#  - mode "track": animated ground track (the spacecraft's path over the planet)
# Owner: Member B (Emon).
class_name TelemetryGraph
extends Control

var mode := "graph"
var title := ""
var series: Array = []      # [{name, color, values: Array[float]}]
var max_points := 160
var phase := 0.0            # track mode: 0..1 position along the orbit
var info := ""              # small text under the title
var accent := Color(0.3, 0.8, 1.0)

const BG := Color(0.02, 0.05, 0.1)
const GRID := Color(0.15, 0.3, 0.5, 0.5)


func add_series(series_name: String, color: Color) -> void:
	series.append({"name": series_name, "color": color, "values": []})


func push(index: int, value: float) -> void:
	var vals: Array = series[index]["values"]
	vals.append(clampf(value, 0.0, 100.0))
	if vals.size() > max_points:
		vals.pop_front()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, BG)
	var font := get_theme_default_font()
	var plot := Rect2(Vector2(40, 64), size - Vector2(60, 90))
	# grid
	for i in 6:
		var y := plot.position.y + plot.size.y * i / 5.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID, 1.0)
		draw_string(font, Vector2(4, y + 5), str(100 - i * 20), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GRID.lightened(0.4))
	for i in 9:
		var x := plot.position.x + plot.size.x * i / 8.0
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), GRID, 1.0)
	draw_rect(Rect2(0, 0, size.x, 4), accent)
	draw_string(font, Vector2(14, 34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, accent)
	draw_string(font, Vector2(14, 56), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.75, 0.85, 1.0))
	if mode == "track":
		_draw_track(plot)
	else:
		_draw_series(plot, font)


func _draw_series(plot: Rect2, font: Font) -> void:
	var lx := plot.end.x
	for s in series:
		var vals: Array = s["values"]
		if vals.size() >= 2:
			var pts := PackedVector2Array()
			for i in vals.size():
				var x := plot.position.x + plot.size.x * float(i) / float(max_points - 1)
				var y := plot.end.y - plot.size.y * float(vals[i]) / 100.0
				pts.append(Vector2(x, y))
			draw_polyline(pts, s["color"], 3.0, true)
			draw_circle(pts[-1], 5.0, s["color"])
		var txt := "%s %d%%" % [s["name"], int(vals[-1]) if vals.size() > 0 else 0]
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		lx -= w + 18
		draw_string(font, Vector2(lx, 56), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, s["color"])


func _draw_track(plot: Rect2) -> void:
	# stylised map: latitude bands + a sine-wave ground track that shifts each orbit
	for i in 4:
		var y := plot.position.y + plot.size.y * (i + 0.5) / 4.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(0.1, 0.35, 0.3, 0.6), 2.0)
	for k in 3:
		var pts := PackedVector2Array()
		var shift := float(k) * 0.33
		for i in 101:
			var u := float(i) / 100.0
			var x := plot.position.x + plot.size.x * u
			var y := plot.position.y + plot.size.y * (0.5 - 0.38 * sin(TAU * (u + shift)))
			pts.append(Vector2(x, y))
		draw_polyline(pts, Color(accent, 0.25 + 0.25 * k), 2.0, true)
	var u2 := fmod(phase, 1.0)
	var dot := Vector2(plot.position.x + plot.size.x * u2, plot.position.y + plot.size.y * (0.5 - 0.38 * sin(TAU * (u2 + 0.66))))
	draw_circle(dot, 9.0, Color(1, 0.85, 0.3))
	draw_arc(dot, 16.0 + 6.0 * sin(phase * 40.0), 0, TAU, 24, Color(1, 0.85, 0.3, 0.5), 2.0)
