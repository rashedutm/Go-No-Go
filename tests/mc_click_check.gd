# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Checks a console panel button can be clicked with the real mouse while the tutorial card is shown.
extends Node

func _ready() -> void:
	MissionState.current_mission_id = "earth"
	MissionState.design = Sim.make_test_design("earth")
	var mc = load("res://scenes/mission_control/mission_control.tscn").instantiate()
	add_child(mc)
	await get_tree().process_frame
	if mc.tutorial == null:   # tutorial already finished on this PC: add one for the test
		mc.tutorial = MCTutorial.new()
		mc.add_child(mc.tutorial)
		mc.tutorial.setup(mc, mc._ui_root)
	mc.open_console("engineer")
	await get_tree().process_frame
	await get_tree().process_frame
	print("mouse visible while panel open: ", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	var btn: Button = mc._panel_actions.get_child(0)
	var c := btn.get_global_rect().get_center()
	var hit := get_viewport().gui_get_hovered_control() if false else null
	var pressed := [false]
	btn.pressed.connect(func(): pressed[0] = true)
	for down in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = down
		ev.position = c
		ev.global_position = c
		Input.parse_input_event(ev)
		await get_tree().process_frame
	print("tutorial card y while panel open: ", mc.tutorial._panel.position.y)
	print("control under the click: ", get_viewport().gui_get_hovered_control())
	for n in get_tree().root.find_children("*", "Control", true, false):
		var ctl := n as Control
		if ctl.is_visible_in_tree() and ctl.mouse_filter != Control.MOUSE_FILTER_IGNORE and ctl.get_global_rect().has_point(c):
			print("  catches clicks here: ", ctl.get_path(), " filter=", ctl.mouse_filter)
	print("first action button '", btn.text, "' clicked: ", pressed[0])
	mc.close_console()
	print("mouse captured after close: ", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	get_tree().quit()
