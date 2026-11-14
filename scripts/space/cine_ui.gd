# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# CineUI: one shared design system for Member C's screens (launch_anim, debrief).
# Palette: deep-navy glass + gold hero + cyan data. One type scale, one card style,
# one button style — so the two screens read as the same game.
# Owner: Member C (Daniel).
class_name CineUI
extends RefCounted

const INK := Color(0.03, 0.05, 0.10, 0.88)
const INK_SOFT := Color(0.08, 0.12, 0.20, 0.92)
const GOLD := Color(1.0, 0.80, 0.30)
const GOLD_DEEP := Color(0.85, 0.62, 0.16)
const CYAN := Color(0.45, 0.85, 1.0)
const TEXT := Color(0.90, 0.93, 1.0)
const MUTED := Color(0.66, 0.73, 0.89)
const DIM := Color(0.38, 0.42, 0.52)
const GOOD := Color(0.38, 0.95, 0.52)
const BAD := Color(1.0, 0.45, 0.38)
const TRACK := Color(0.16, 0.19, 0.27)


static func panel_style(bg: Color = INK, radius := 16, border := Color(0, 0, 0, 0), bw := 0, pad := 20) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if bw > 0:
		sb.set_border_width_all(bw)
		sb.border_color = border
	sb.set_content_margin_all(pad)
	return sb


static func glass(pad := 20) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(INK, 16, Color(1, 1, 1, 0.07), 1, pad))
	return p


static func card(border := Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	var bw := 1 if border.a > 0.0 else 0
	p.add_theme_stylebox_override("panel", panel_style(INK_SOFT, 12, border, bw, 14))
	return p


static func kicker(text: String, color: Color = GOLD) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", color)
	return l


static func headline(text: String, size := 30, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func body(text: String, size := 16, color: Color = MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func rule() -> HSeparator:
	var s := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color(0.35, 0.42, 0.58, 0.45)
	line.thickness = 1
	s.add_theme_stylebox_override("separator", line)
	return s


static func meter(color: Color, width := 280.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.custom_minimum_size = Vector2(width, 20)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = TRACK
	bg.set_corner_radius_all(10)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(10)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func _btn_base(b: Button, font_size: int) -> void:
	b.add_theme_font_size_override("font_size", font_size)
	var focus := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("focus", focus)


static func primary(b: Button, font_size := 20) -> void:
	_btn_base(b, font_size)
	b.add_theme_color_override("font_color", Color(0.06, 0.07, 0.11))
	b.add_theme_color_override("font_hover_color", Color(0.06, 0.07, 0.11))
	b.add_theme_color_override("font_pressed_color", Color(0.03, 0.04, 0.07))
	b.add_theme_stylebox_override("normal", panel_style(GOLD, 12, Color(0, 0, 0, 0), 0, 14))
	b.add_theme_stylebox_override("hover", panel_style(Color(1.0, 0.87, 0.45), 12, Color(0, 0, 0, 0), 0, 14))
	b.add_theme_stylebox_override("pressed", panel_style(GOLD_DEEP, 12, Color(0, 0, 0, 0), 0, 14))


static func ghost(b: Button, font_size := 20) -> void:
	_btn_base(b, font_size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	var bg := Color(0.05, 0.08, 0.15, 0.75)
	b.add_theme_stylebox_override("normal", panel_style(bg, 12, Color(0.55, 0.65, 0.85, 0.5), 1, 14))
	b.add_theme_stylebox_override("hover", panel_style(Color(0.10, 0.15, 0.24, 0.9), 12, CYAN, 1, 14))
	b.add_theme_stylebox_override("pressed", panel_style(Color(0.03, 0.05, 0.09, 0.95), 12, CYAN, 1, 14))


static func dot(active: int) -> Panel:
	# active: 0 = todo, 1 = current, 2 = done
	var p := Panel.new()
	p.custom_minimum_size = Vector2(14, 14)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(7)
	if active == 1:
		sb.bg_color = GOLD
	elif active == 2:
		sb.bg_color = CYAN
	else:
		sb.bg_color = Color(0.25, 0.28, 0.36)
	p.add_theme_stylebox_override("panel", sb)
	return p
