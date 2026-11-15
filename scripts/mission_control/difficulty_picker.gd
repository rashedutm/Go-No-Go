# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# DifficultyPicker: EASY / NORMAL / HARD toggle row with a one-line explanation.
# Sets MissionState.set_difficulty(); read by EventSystem in Mission Control.
#  Easy   = pick from choices, recommended choice shown in green, more time
#  Normal = fix problems yourself with the right console tool (with a hint)
#  Hard   = no hints, the alarm doesn't say which console, less time, riskier
class_name DifficultyPicker
extends VBoxContainer

const LEVELS := [
	["easy", "EASY", "Pick from choices. The recommended answer is shown in green. More time."],
	["normal", "NORMAL", "Fix problems yourself with the right console tool. A hint tells you which."],
	["hard", "HARD", "No hints, the alarm doesn't say where to go, less time, more risk."],
]

var _buttons := {}
var _desc: Label
var compact := false   # narrow layout (mission select card): label above, buttons share the width


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var cap := NeonUI.kicker("DIFFICULTY", NeonUI.MUTED, 10)
	if compact:
		add_child(cap)
		add_child(row)
	else:
		add_child(row)
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cap.custom_minimum_size.x = 90
		row.add_child(cap)
	for lv in LEVELS:
		var b := Button.new()
		b.text = lv[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0 if compact else 110, 36)
		if compact:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = lv[2]
		NeonUI.ghost(b, 15)
		var level: String = lv[0]
		b.pressed.connect(func(): _pick(level))
		row.add_child(b)
		_buttons[level] = b
	_desc = Label.new()
	NeonUI.caption(_desc, 12, NeonUI.MUTED)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# always reserve two lines, so the buttons don't jump when a shorter description is shown
	var f := _desc.get_theme_font("font")
	var fs := _desc.get_theme_font_size("font_size")
	_desc.custom_minimum_size.y = ceilf(f.get_height(fs) * 2.0 + 4.0) if f else 40.0
	add_child(_desc)
	_refresh()


func _pick(level: String) -> void:
	MissionState.set_difficulty(level)
	_refresh()


func _refresh() -> void:
	var cur := MissionState.difficulty()
	for lv in LEVELS:
		var b: Button = _buttons[lv[0]]
		b.button_pressed = lv[0] == cur
		b.modulate = Color(1, 1, 1) if lv[0] == cur else Color(0.6, 0.65, 0.75)
		if lv[0] == cur:
			_desc.text = lv[2]
