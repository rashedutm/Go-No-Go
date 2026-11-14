# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# NeonUI — the shared HUD kit: neon notched panels, Barlow Condensed display type,
# Barlow body type, IBM Plex Mono telemetry, and the hazard-stripe motif.
# Owner: Member C (UI pass approved by the team).
class_name NeonUI
extends RefCounted

const CYAN := Color(0.31, 0.84, 1.0)
const CYAN_DIM := Color(0.31, 0.84, 1.0, 0.35)
const GOLD := Color(0.98, 0.72, 0.25)
const GREEN := Color(0.38, 0.95, 0.52)
const RED := Color(1.0, 0.36, 0.31)
const TEXT := Color(0.88, 0.94, 1.0)
const MUTED := Color(0.58, 0.68, 0.82)
const DIM := Color(0.38, 0.44, 0.54)
const BG := Color(0.02, 0.04, 0.07, 0.86)

const FONT_DIR := "res://ui/fonts/"
const PANEL_DIR := "res://ui/panels/"

static var _fonts := {}
static var _spaced: FontVariation


static func font(name: String) -> Font:
	if not _fonts.has(name):
		_fonts[name] = load(FONT_DIR + name)
	return _fonts[name]


static func _apply(l: Label, f: Font, size: int, color: Color) -> Label:
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func _as_label(v) -> Label:
	if v is Label:
		return v as Label
	var l := Label.new()
	l.text = str(v)
	return l


static func display(v, size := 44, color := TEXT) -> Label:
	return _apply(_as_label(v), font("BarlowCondensed-ExtraBold.ttf"), size, color)


static func heading(v, size := 24, color := TEXT) -> Label:
	return _apply(_as_label(v), font("BarlowCondensed-Bold.ttf"), size, color)


static func section(v, size := 20, color := CYAN) -> Label:
	return _apply(_as_label(v), font("BarlowCondensed-Bold.ttf"), size, color)


static func body(v, size := 15, color := TEXT, wrap := false) -> Label:
	var r := _apply(_as_label(v), font("Barlow-Regular.ttf"), size, color)
	if wrap:
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return r


static func caption(v, size := 13, color := MUTED) -> Label:
	return _apply(_as_label(v), font("Barlow-Medium.ttf"), size, color)


static func mono(v, size := 15, color := CYAN) -> Label:
	return _apply(_as_label(v), font("IBMPlexMono-Medium.ttf"), size, color)


static func mono_regular(v, size := 14, color := MUTED) -> Label:
	return _apply(_as_label(v), font("IBMPlexMono-Regular.ttf"), size, color)


static func kicker(text: String, color := CYAN, size := 12) -> Label:
	if _spaced == null:
		_spaced = FontVariation.new()
		_spaced.base_font = font("IBMPlexMono-Medium.ttf")
		_spaced.spacing_glyph = 2
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", _spaced)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func panel(kind := "cyan", pad := 18) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(kind, pad))
	return p


static func panel_style(kind := "cyan", pad := 18) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(PANEL_DIR + "neon_" + kind + ".png")
	sb.texture_margin_left = 16
	sb.texture_margin_top = 16
	sb.texture_margin_right = 16
	sb.texture_margin_bottom = 16
	sb.content_margin_left = pad
	sb.content_margin_top = pad - 4
	sb.content_margin_right = pad
	sb.content_margin_bottom = pad - 4
	return sb


static func apply_panel(p: PanelContainer, kind := "cyan", pad := 18) -> void:
	p.add_theme_stylebox_override("panel", panel_style(kind, pad))


static func glass(pad := 20) -> PanelContainer:
	return panel("cyan", pad)


static func dot(active: int) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(12, 12)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	if active == 1:
		sb.bg_color = GOLD
	elif active == 2:
		sb.bg_color = CYAN
	else:
		sb.bg_color = Color(0.22, 0.26, 0.34)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func primary(b: Button, size := 20) -> void:
	b.theme_type_variation = "PrimaryButton"
	b.add_theme_font_size_override("font_size", size)


static func ghost(b: Button, size := 18) -> void:
	b.theme_type_variation = "GhostButton"
	b.add_theme_font_size_override("font_size", size)


static func danger(b: Button, size := 18) -> void:
	b.theme_type_variation = "DangerButton"
	b.add_theme_font_size_override("font_size", size)


static func rule(color := CYAN_DIM) -> HSeparator:
	var s := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = color
	line.thickness = 1
	s.add_theme_stylebox_override("separator", line)
	return s


static func pill(text: String, color := CYAN, size := 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", pill_style(color))
	var l := Label.new()
	l.name = "PillLabel"
	l.text = text.to_upper()
	l.add_theme_font_override("font", font("IBMPlexMono-Medium.ttf"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	p.add_child(l)
	return p


static func pill_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.14)
	sb.set_border_width_all(1)
	sb.border_color = Color(color.r, color.g, color.b, 0.55)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(6)
	return sb


class Stripes extends Control:
	var color := Color(0.98, 0.72, 0.25)

	func _draw() -> void:
		var h := size.y
		var step := 11.0
		var w := 7.0
		for i in 3:
			var x := i * step
			draw_line(Vector2(x, h), Vector2(x + h * 0.55, 0), color, 3.0, true)


static func stripes(color := GOLD) -> Control:
	var s := Stripes.new()
	s.color = color
	s.custom_minimum_size = Vector2(36, 18)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


## A tiny left-edge accent bar used beside verdicts and kickers.
static func accent(color := RED, width := 4.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(width, 0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
