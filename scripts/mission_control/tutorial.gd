# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# First-mission tutorial for Mission Control (Fire Watch only, shown once).
# Step-by-step hints that wait for the player to actually do each thing; the first event is a
# friendly science opportunity. Press T to skip. Saved in user://settings.cfg.
class_name MCTutorial
extends Node

const SETTINGS := "user://settings.cfg"

var mc: Node
var step := 0
var _t := 0.0
var _panel: PanelContainer
var _label: Label
var _event_done := false

const STEPS := [
	"Welcome to Mission Control!  Click anywhere to look around with the mouse.",
	"Walk with W A S D to the orange POWER console at the front left.",
	"Look at the console and press E to open it.",
	"Consoles show live data and action buttons (number keys pick them).  Press E to close.",
	"Top left: battery, science returned, health and memory. Keep the science bar growing!",
	"Time is fast: a whole mission takes about 3 minutes.  Keys 1 / 2 / 3 change speed, Space pauses.",
	"ALERT!  When the alarm sounds, go to the console it names and choose what to do.",
	"Great job, flight controller! Now fly the rest of the mission.",
]


static func should_run(mission_id: String) -> bool:
	if mission_id != "earth":
		return false
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	return not bool(cfg.get_value("tutorial", "done", false))


func setup(p_mc: Node, ui_root: Control) -> void:
	mc = p_mc
	mc.events._until_next = 99999.0   # no random events until the tutorial says so
	mc.events.event_resolved.connect(func(_e, _c, _o, _t2): _event_done = true)
	_panel = NeonUI.panel("cyan", 14)
	_panel.position = Vector2(290, 500)
	_panel.custom_minimum_size = Vector2(700, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(_panel)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE   # never catch clicks meant for console buttons
	_panel.add_child(v)
	var head := NeonUI.kicker("TUTORIAL  ·  STEP 1 / %d  ·  PRESS T TO SKIP" % STEPS.size(), NeonUI.GOLD, 10)
	head.name = "Head"
	v.add_child(head)
	_label = Label.new()
	NeonUI.body(_label, 17, NeonUI.TEXT, true)
	v.add_child(_label)
	_show()


## Moves the card below the console panel while one is open, so it never covers its buttons.
func set_panel_open(open: bool) -> void:
	if _panel:
		_panel.position.y = 612.0 if open else 500.0


func _show() -> void:
	_t = 0.0
	_label.text = STEPS[step]
	(_panel.get_child(0).get_node("Head") as Label).text = "TUTORIAL  ·  STEP %d / %d  ·  PRESS T TO SKIP" % [step + 1, STEPS.size()]
	if step == 6:
		mc.events.start_by_id("wildfire")
	Sfx.play("beep", -8.0)


func _next() -> void:
	step += 1
	if step >= STEPS.size():
		_finish()
	else:
		_show()


func _finish() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("tutorial", "done", true)
	cfg.save(SETTINGS)
	if mc.events._until_next > 9999.0:
		mc.events._until_next = 15.0
	_panel.queue_free()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and event.physical_keycode == KEY_T:
		_finish()


func _process(delta: float) -> void:
	_t += delta
	var done := false
	match step:
		0: done = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or _t > 12.0
		1: done = mc._focus == "engineer" or mc._open == "engineer"
		2: done = mc._open == "engineer"
		3: done = mc._open == ""
		4: done = _t > 6.0
		5: done = _t > 6.0
		6: done = _event_done
		7: done = _t > 4.0
	if done:
		_next()
