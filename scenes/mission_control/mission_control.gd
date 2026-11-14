# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M4a: first-person 3D Mission Control room.
#  - Room with tiers of desks, a big wall screen (Daniel's space_view, or a placeholder) in a SubViewport
#  - 4 interactive consoles: POWER (engineer), SCIENCE, COMMS, DIRECTOR
#  - Walk up to a console, press E to open its panel (contents come in M4c)
# The live simulation (M4b) and events (M5) plug into: consoles, set_console_alert(), open_console().
# Owner: Member B (Emon).
extends Node3D

signal console_opened(key: String)
signal console_closed(key: String)

const SPACE_VIEW_PATH := "res://scenes/space/space_view.tscn"
const WallViewPlaceholder := preload("res://scripts/mission_control/wall_view_placeholder.gd")

## key, sign text, color, position, rotation (radians, Y)
const CONSOLES := [
	["engineer", "POWER", Color(1.0, 0.55, 0.2), Vector3(-5.0, 0, -3.0)],
	["science", "SCIENCE", Color(0.72, 0.48, 1.0), Vector3(0.0, 0, -3.0)],
	["comms", "COMMS", Color(0.3, 0.85, 1.0), Vector3(5.0, 0, -3.0)],
	["director", "DIRECTOR", Color(1.0, 0.82, 0.3), Vector3(6.0, 0, 2.5)],
]
const INTERACT_DIST := 1.7

var design: Dictionary
var mission: Dictionary
var consoles := {}          # key -> ConsoleStation
var wall_view: Node         # Daniel's space_view or the placeholder
var player: FPPlayer

var _focus := ""            # console the player is looking at
var _open := ""             # console whose panel is open
var _prompt: Label
var _start_hint: Label
var _panel: PanelContainer
var _panel_title: Label
var _panel_body: RichTextLabel
var _panel_buttons: HBoxContainer
var _hud_clock: Label


func _ready() -> void:
	design = MissionState.design
	if design.is_empty() or str(design.get("bus", "")) == "":
		design = Sim.make_test_design(MissionState.current_mission_id)
		MissionState.design = design
	mission = GameData.get_mission(design.get("mission_id", "mars"))
	_build_room()
	_build_wall_screen()
	_build_consoles()
	player = FPPlayer.new()
	player.position = Vector3(0, 0.1, 7.0)
	add_child(player)
	player.interact_pressed.connect(_on_interact)
	_build_ui()


# ============================================================== room

func _build_room() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

	var wall_c := Color(0.1, 0.12, 0.17)
	MCBuild.box(self, Vector3(24, 0.2, 20), Vector3(0, -0.1, 0), Color(0.12, 0.14, 0.2), true)      # floor
	MCBuild.box(self, Vector3(24, 0.2, 20), Vector3(0, 6.1, 0), Color(0.06, 0.07, 0.1))              # ceiling
	MCBuild.box(self, Vector3(24, 6.2, 0.3), Vector3(0, 3, -9.2), wall_c, true)                     # front wall
	MCBuild.box(self, Vector3(24, 6.2, 0.3), Vector3(0, 3, 9.2), wall_c, true)                      # back wall
	MCBuild.box(self, Vector3(0.3, 6.2, 20), Vector3(-11.2, 3, 0), wall_c, true)                    # left
	MCBuild.box(self, Vector3(0.3, 6.2, 20), Vector3(11.2, 3, 0), wall_c, true)                     # right
	for x in range(-10, 11, 4):   # wall ribs
		MCBuild.box(self, Vector3(0.25, 6, 0.25), Vector3(x, 3, 9.0), Color(0.16, 0.18, 0.24))
	for z in range(-8, 9, 4):
		MCBuild.box(self, Vector3(0.25, 6, 0.25), Vector3(-11.0, 3, z), Color(0.16, 0.18, 0.24))
		MCBuild.box(self, Vector3(0.25, 6, 0.25), Vector3(11.0, 3, z), Color(0.16, 0.18, 0.24))
	# ceiling light strips + lights
	for x in [-6.0, 0.0, 6.0]:
		MCBuild.box(self, Vector3(0.3, 0.05, 14), Vector3(x, 5.95, 0), Color(0.75, 0.85, 1.0), false, 2.0)
		var l := OmniLight3D.new()
		l.position = Vector3(x, 5.2, 1)
		l.omni_range = 11
		l.light_energy = 0.45
		l.light_color = Color(0.8, 0.88, 1.0)
		add_child(l)
	# floor guide strips
	for x in [-8.0, 8.0]:
		MCBuild.box(self, Vector3(0.08, 0.01, 16), Vector3(x, 0.01, 0), Color(0.2, 0.5, 1.0), false, 1.5)
	# side wall info panels (decoration)
	for z in [-5.0, 0.0, 5.0]:
		MCBuild.box(self, Vector3(0.05, 1.4, 2.4), Vector3(-10.95, 3.2, z), Color(0.1, 0.25, 0.45), false, 0.7)
		MCBuild.box(self, Vector3(0.05, 1.4, 2.4), Vector3(10.95, 3.2, z), Color(0.1, 0.25, 0.45), false, 0.7)
	# decorative desks (non-interactive)
	for p in [Vector3(-6, 0, 2.5), Vector3(-4, 0, 6.0), Vector3(4, 0, 6.0)]:
		MCBuild.box(self, Vector3(2.4, 0.85, 1.0), p + Vector3(0, 0.425, 0), Color(0.15, 0.17, 0.22), true)
		MCBuild.box(self, Vector3(1.3, 0.7, 0.06), p + Vector3(0, 1.25, -0.25), Color(0.08, 0.08, 0.1))
		MCBuild.box(self, Vector3(1.2, 0.6, 0.02), p + Vector3(0, 1.25, -0.21), Color(0.12, 0.3, 0.5), false, 0.6)


func _build_wall_screen() -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1280, 540)
	sub.own_world_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)
	if ResourceLoader.exists(SPACE_VIEW_PATH):
		wall_view = load(SPACE_VIEW_PATH).instantiate()
	else:
		wall_view = WallViewPlaceholder.new()
	sub.add_child(wall_view)
	if wall_view.has_method("setup"):
		wall_view.setup(design)

	MCBuild.box(self, Vector3(11.4, 4.95, 0.2), Vector3(0, 3.6, -8.95), Color(0.05, 0.05, 0.07))   # frame
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(11.0, 4.64)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = sub.get_texture()
	quad.material = m
	screen.mesh = quad
	screen.position = Vector3(0, 3.6, -8.83)
	add_child(screen)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 3, -7.5)
	glow.omni_range = 9
	glow.light_color = Color(0.5, 0.65, 1.0)
	glow.light_energy = 0.6
	add_child(glow)


func _build_consoles() -> void:
	for c in CONSOLES:
		var st := ConsoleStation.new()
		st.position = c[3]
		add_child(st)
		st.setup(c[0], c[1], c[2])
		consoles[c[0]] = st


# ============================================================== public API (for M4b / M5)

func set_console_alert(key: String, on: bool) -> void:
	if consoles.has(key):
		consoles[key].set_alert(on)


func open_console(key: String) -> void:
	_open = key
	var st: ConsoleStation = consoles[key]
	_panel_title.text = st.title + " CONSOLE"
	_panel_title.add_theme_color_override("font_color", st.color)
	_panel_body.text = _console_body(key)
	for b in _panel_buttons.get_children():
		b.queue_free()
	if key == "director":
		var end := Button.new()
		end.text = "End mission (test)"
		end.tooltip_text = "Temporary: finishes the mission using the design estimate (until the live simulation exists)."
		end.pressed.connect(_end_mission_test)
		_panel_buttons.add_child(end)
	var close := Button.new()
	close.text = "Close (E)"
	close.pressed.connect(close_console)
	_panel_buttons.add_child(close)
	_panel.visible = true
	_start_hint.visible = false
	_prompt.text = ""
	_focus = ""
	player.set_controls_enabled(false)
	console_opened.emit(key)


func close_console() -> void:
	if _open == "":
		return
	var key := _open
	_open = ""
	_panel.visible = false
	player.set_controls_enabled(true)
	console_closed.emit(key)


## Placeholder text for each console. M4c replaces this with real gauges + action buttons.
func _console_body(key: String) -> String:
	var s := Sim.summarize(design)
	match key:
		"engineer":
			return "[b]Power & spacecraft health[/b]\nPower made: %d W   ·   Power used: %d W\nBattery: %d Wh\n\n[i]Coming in M4c: live battery gauge, SAFE MODE button.[/i]" % [s["power_gen_w"], s["power_load_w"], s["battery_wh"]]
		"science":
			return "[b]Instruments[/b]\n%s\nData made: %.1f Gb/day   ·   Goal: %s Gb\n\n[i]Coming in M4c: switch each instrument on/off.[/i]" % [", ".join(design.get("instruments", [])), s["data_per_day_gb"], PartInfo.fmt(s["data_goal_gb"])]
		"comms":
			return "[b]Communications[/b]\nDownlink: %.2f Mbps   ·   %.1f Gb/day\nMemory: %s Gb   ·   Signal delay: %.1f min\n\n[i]Coming in M4c: downlink priority, buy extra antenna time.[/i]" % [s["downlink_rate_mbps"], s["downlink_per_day_gb"], PartInfo.fmt(s["storage_gb"]), s["signal_delay_min"]]
		"director":
			return "[b]Mission overview[/b]\n%s: %s\nReserve: $%s M   ·   Planned lifetime: %d years\n\n[i]Coming in M4c/M5: event log, spend reserve on repairs.[/i]" % [mission.get("name", ""), mission.get("objective", ""), PartInfo.fmt(s["reserve_musd"]), int(design.get("target_years", 1))]
	return ""


func _end_mission_test() -> void:
	var s := Sim.summarize(design)
	MissionState.last_result = {
		"mission_id": design.get("mission_id", ""),
		"end_reason": "completed",
		"data_returned_gb": s["est_total_data_gb"],
		"data_goal_gb": s["data_goal_gb"],
		"science_bonus": 0,
		"lifetime_years": float(design.get("target_years", 1.0)),
		"target_years": float(design.get("target_years", 1.0)),
		"reserve_left_musd": s["reserve_musd"],
		"budget_musd": s["budget_musd"],
		"log": [],
	}
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MissionState.go_to("debrief")


# ============================================================== interaction

func _physics_process(_delta: float) -> void:
	if _open != "":
		return
	var best := ""
	var best_d := INTERACT_DIST
	var ppos := player.global_position
	for key in consoles:
		var st: ConsoleStation = consoles[key]
		var op := st.operator_point()
		var d := Vector2(ppos.x - op.x, ppos.z - op.z).length()
		var to_console := (st.global_position - ppos)
		to_console.y = 0
		var facing := player.look_dir()
		facing.y = 0
		if d < best_d and facing.normalized().dot(to_console.normalized()) > 0.35:
			best = key
			best_d = d
	if best != _focus:
		_focus = best
		_prompt.text = ("Press E: %s console" % consoles[best].title) if best != "" else ""
	_start_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED


func _on_interact() -> void:
	if _open != "":
		close_console()
	elif _focus != "":
		open_console(_focus)


func _unhandled_key_input(event: InputEvent) -> void:
	# E / Esc also close the panel while the player's controls are disabled
	if _open != "" and event.pressed and (event.is_action("mc_interact") or event.is_action("mc_release")):
		close_console()
		get_viewport().set_input_as_handled()


# ============================================================== HUD

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.8)
	dot.size = Vector2(6, 6)
	dot.position = Vector2(637, 357)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dot)

	var info := PanelContainer.new()
	info.position = Vector2(16, 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.1, 0.75)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	info.add_theme_stylebox_override("panel", sb)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(info)
	_hud_clock = Label.new()
	_hud_clock.text = "%s\nMission clock: Day 0 (live simulation: M4b)" % mission.get("name", "")
	_hud_clock.add_theme_font_size_override("font_size", 16)
	info.add_child(_hud_clock)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 24)
	_prompt.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.position = Vector2(340, 420)
	_prompt.size = Vector2(600, 40)
	root.add_child(_prompt)

	var hint := Label.new()
	hint.text = "WASD walk  ·  mouse look  ·  E use console  ·  Esc free mouse"
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.7, 0.78, 0.95, 0.85)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(340, 690)
	hint.size = Vector2(600, 24)
	root.add_child(hint)

	_start_hint = Label.new()
	_start_hint.text = "Click to look around"
	_start_hint.add_theme_font_size_override("font_size", 30)
	_start_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_start_hint.add_theme_constant_override("outline_size", 8)
	_start_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_hint.position = Vector2(340, 300)
	_start_hint.size = Vector2(600, 50)
	_start_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_start_hint)

	_panel = PanelContainer.new()
	_panel.position = Vector2(290, 150)
	_panel.custom_minimum_size = Vector2(700, 400)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.03, 0.05, 0.11, 0.95)
	psb.border_color = Color(0.3, 0.45, 0.85)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(14)
	psb.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", psb)
	_panel.visible = false
	root.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_panel.add_child(v)
	_panel_title = Label.new()
	_panel_title.add_theme_font_size_override("font_size", 30)
	v.add_child(_panel_title)
	_panel_body = RichTextLabel.new()
	_panel_body.bbcode_enabled = true
	_panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_body.add_theme_font_size_override("normal_font_size", 18)
	_panel_body.add_theme_font_size_override("bold_font_size", 20)
	v.add_child(_panel_body)
	_panel_buttons = HBoxContainer.new()
	_panel_buttons.alignment = BoxContainer.ALIGNMENT_END
	_panel_buttons.add_theme_constant_override("separation", 10)
	v.add_child(_panel_buttons)
