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
var _panel_actions: HFlowContainer
var _hud_clock: Label
var _hud_bars := {}         # key -> {bar, label}
var _end_banner: Label

# --- live simulation (M4b)
var sim: MissionSim
var days_per_second := 4.0  # base speed: the whole mission plays in about 3 minutes
var speed := 1.0            # 1, 2 or 4 (keys 1/2/3)
var paused := false
var _ending := false
var _panel_refresh := 0.0
const SPEEDS := [1.0, 2.0, 4.0]
var events: EventSystem
var decor: RoomDecor
var _alert_banner: Label
var _toast: Label
var _toast_time := 0.0
var _alarm_light: OmniLight3D
var _alarm_repeat := 0.0
var _status_reset := -1.0
var _acked := {}           # condition alerts the player already checked (cleared when the problem goes away)


func _ready() -> void:
	design = MissionState.design
	if design.is_empty() or str(design.get("bus", "")) == "":
		design = Sim.make_test_design(MissionState.current_mission_id)
		MissionState.design = design
	mission = GameData.get_mission(design.get("mission_id", "mars"))
	sim = MissionSim.new(design)
	days_per_second = sim.total_days / 180.0
	_build_room()
	_build_wall_screen()
	_build_consoles()
	player = FPPlayer.new()
	player.position = Vector3(0, 0.1, 7.0)
	add_child(player)
	player.interact_pressed.connect(_on_interact)
	_build_ui()
	sim.add_log("Arrived at %s. Science operations begin." % mission.get("destination", "the target"))
	_setup_events()
	decor = RoomDecor.new()
	add_child(decor)
	decor.build(self, sim)
	Sfx.start_loop("hum")


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
	_acked[key] = true
	var st: ConsoleStation = consoles[key]
	_panel_title.text = st.title + " CONSOLE"
	_panel_title.add_theme_color_override("font_color", st.color)
	_panel_body.text = _console_body(key)
	_build_actions(key)
	for b in _panel_buttons.get_children():
		b.queue_free()
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


## Live text for each console. M4c adds action buttons below it.
func _console_body(key: String) -> String:
	var card := ""
	if events and events.active.get("console", "") == key:
		card = "[color=#ff6b5e][b]ALERT: %s[/b][/color]\n%s\n[color=#ffb74d]Choose below.[/color]\n\n" % [events.active["title"], events.active["text"]]
	return card + _console_text(key)


func _console_text(key: String) -> String:
	var f := PartInfo.fmt
	match key:
		"engineer":
			return "[b]Power & spacecraft health[/b]\nPower made: %d W   ·   Power used: %d W\nBattery: %d%%  (%s / %s Wh)\nHealth: %d%%%s" % [
				sim.power_gen_w, sim.power_load_w, sim.battery_pct(), f.call(sim.battery_wh), f.call(sim.battery_max), sim.health,
				"   ·   [color=#ffb74d]SAFE MODE[/color]" if sim.safe_mode else ""]
		"science":
			return "[b]Instruments[/b]: click to switch each one on or off.\nOff saves power and memory, but makes no science.\n\nMaking %.1f Gb/day   ·   Returned %s / %s Gb (%d%%)%s" % [
				sim.data_rate_gb_day, f.call(sim.data_returned_gb), f.call(sim.mission.get("data_goal_gb", 0)),
				int(100.0 * sim.data_returned_gb / maxf(float(sim.mission.get("data_goal_gb", 1)), 1.0)),
				"\n[color=#ffb74d]SAFE MODE is on: instruments are off.[/color]" if sim.safe_mode else ""]
		"comms":
			return "[b]Communications[/b]\nSending %.1f Gb/day%s\nMemory: %d%% full  (%s / %s Gb)\nData lost: %s Gb   ·   Signal delay: %.1f min" % [
				sim.downlink_gb_day, "   ·   [color=#ff8a80]BLACKOUT[/color]" if sim.blackout_days > 0.0 else "", sim.storage_pct(),
				f.call(sim.storage_gb), f.call(sim.storage_max), f.call(sim.data_lost_gb), float(mission.get("signal_delay_min", 0))]
		"director":
			var recent: Array = []
			for i in range(maxi(sim.event_log.size() - 5, 0), sim.event_log.size()):
				recent.append("Day %d: %s" % [sim.event_log[i]["day"], sim.event_log[i]["text"]])
			return "[b]%s[/b]: %s\nDay %d of %d   ·   Reserve: $%s M\n\n[b]Mission log[/b]\n%s" % [
				mission.get("name", ""), mission.get("objective", ""), int(sim.day), int(sim.total_days), f.call(sim.reserve_musd), "\n".join(recent)]
	return ""


func _end_mission_test() -> void:
	sim.abort()


## Called once when the simulation finishes: show a banner, then go to the debrief.
func _finish_mission() -> void:
	if _ending:
		return
	_ending = true
	close_console()
	MissionState.last_result = sim.result()
	_end_banner.text = {"completed": "MISSION COMPLETE", "power_dead": "CONTACT LOST: POWER FAILURE",
		"destroyed": "CONTACT LOST: SPACECRAFT FAILED", "aborted": "MISSION ENDED"}.get(sim.end_reason, "MISSION OVER")
	_end_banner.modulate = Color(0.4, 1, 0.5) if sim.end_reason == "completed" else Color(1, 0.4, 0.35)
	_end_banner.visible = true
	Sfx.stop_loop("hum")
	Sfx.play("complete" if sim.end_reason == "completed" else "fail")
	await get_tree().create_timer(2.5).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MissionState.go_to("debrief")


# ============================================================== live loop

func _process(delta: float) -> void:
	if sim == null:
		return
	if events:
		events.update(delta, paused, _open != "" and _open == events.active.get("console", "-"))
		_update_event_fx(delta)
	if not paused and not sim.finished:
		sim.tick(delta * days_per_second * speed)
	if wall_view and wall_view.has_method("set_time_scale"):
		wall_view.set_time_scale(0.0 if paused else days_per_second * speed)
	_auto_alerts()
	_update_hud()
	if decor:
		decor.update(delta)
	if _open != "":
		_panel_refresh -= delta
		if _panel_refresh <= 0.0:
			_panel_refresh = 0.25
			_panel_body.text = _console_body(_open)
	if sim.finished:
		_finish_mission()


## Simple condition-based alerts (events in M5 add more).
func _auto_alerts() -> void:
	var cond := {
		"engineer": sim.battery_pct() < 25.0 or sim.health < 30.0 or sim.power_load_w > sim.power_gen_w,
		"comms": sim.storage_pct() > 85.0 or sim.blackout_days > 0.0,
		"science": false,
		"director": false,
	}
	var ev_key: String = events.active.get("console", "") if events else ""
	for key in cond:
		if not cond[key]:
			_acked.erase(key)
		set_console_alert(key, (cond[key] and not _acked.has(key)) or key == ev_key)


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
	if not event.pressed or event.is_echo():
		return
	# E / Esc also close the panel while the player's controls are disabled
	if _open != "" and (event.is_action("mc_interact") or event.is_action("mc_release")):
		close_console()
		get_viewport().set_input_as_handled()
		return
	var k: int = event.physical_keycode
	if k == KEY_SPACE or k == KEY_P:
		paused = not paused
	elif k >= KEY_1 and k <= KEY_3:
		speed = SPEEDS[k - KEY_1]
		paused = false


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
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	hv.custom_minimum_size.x = 250
	info.add_child(hv)
	_hud_clock = Label.new()
	_hud_clock.add_theme_font_size_override("font_size", 16)
	hv.add_child(_hud_clock)
	for g in [["battery", "Battery"], ["data", "Science returned"], ["health", "Health"], ["storage", "Memory"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		hv.add_child(row)
		var name_l := Label.new()
		name_l.text = g[1]
		name_l.custom_minimum_size.x = 120
		name_l.add_theme_font_size_override("font_size", 13)
		row.add_child(name_l)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(80, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = 100.0
		row.add_child(bar)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 13)
		row.add_child(val)
		_hud_bars[g[0]] = {"bar": bar, "label": val}

	_end_banner = Label.new()
	_end_banner.add_theme_font_size_override("font_size", 56)
	_end_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_end_banner.add_theme_constant_override("outline_size", 12)
	_end_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_banner.position = Vector2(140, 200)
	_end_banner.size = Vector2(1000, 80)
	_end_banner.visible = false
	root.add_child(_end_banner)

	_alert_banner = Label.new()
	_alert_banner.add_theme_font_size_override("font_size", 26)
	_alert_banner.add_theme_color_override("font_color", Color(1, 0.4, 0.33))
	_alert_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_alert_banner.add_theme_constant_override("outline_size", 8)
	_alert_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert_banner.position = Vector2(330, 14)
	_alert_banner.size = Vector2(620, 80)
	_alert_banner.visible = false
	root.add_child(_alert_banner)

	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(240, 600)
	_toast.size = Vector2(800, 80)
	_toast.visible = false
	root.add_child(_toast)

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
	hint.text = "WASD walk  ·  mouse look  ·  E use console  ·  Space pause  ·  1/2/3 speed  ·  Esc free mouse"
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.7, 0.78, 0.95, 0.85)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(140, 690)
	hint.size = Vector2(1000, 24)
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
	_panel.position = Vector2(270, 100)
	_panel.custom_minimum_size = Vector2(740, 500)
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
	_panel_actions = HFlowContainer.new()
	_panel_actions.add_theme_constant_override("h_separation", 10)
	_panel_actions.add_theme_constant_override("v_separation", 10)
	v.add_child(_panel_actions)
	_panel_buttons = HBoxContainer.new()
	_panel_buttons.alignment = BoxContainer.ALIGNMENT_END
	_panel_buttons.add_theme_constant_override("separation", 10)
	v.add_child(_panel_buttons)


func _hud_bar(key: String, pct: float, text: String, bad_low := true, color_pct := -1.0) -> void:
	var b: Dictionary = _hud_bars[key]
	var bar: ProgressBar = b["bar"]
	bar.value = clampf(pct, 0.0, 100.0)
	var col: Color
	if color_pct >= 0.0:
		pct = color_pct
	if bad_low:
		col = Color(1, 0.35, 0.3) if pct < 25.0 else (Color(1, 0.75, 0.2) if pct < 50.0 else Color(0.35, 0.9, 0.45))
	else:
		col = Color(1, 0.35, 0.3) if pct > 85.0 else (Color(1, 0.75, 0.2) if pct > 60.0 else Color(0.35, 0.9, 0.45))
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	b["label"].text = text
	b["label"].modulate = col.lightened(0.3)


func _update_hud() -> void:
	var state := "PAUSED" if paused else "x%d" % int(speed)
	_hud_clock.text = "%s  ·  Day %d / %d  ·  %s" % [mission.get("name", ""), int(sim.day), int(sim.total_days), state]
	_hud_bar("battery", sim.battery_pct(), "%d%%" % int(sim.battery_pct()))
	var goal := maxf(float(mission.get("data_goal_gb", 1)), 1.0)
	var dp := 100.0 * sim.data_returned_gb / goal
	# colour = on track? (returned vs. how far into the mission we are)
	var on_track := 100.0 if sim.progress() < 0.02 else clampf(dp / (sim.progress() * 100.0) * 100.0, 0.0, 100.0)
	_hud_bar("data", dp, "%d%%" % int(dp), true, on_track)
	_hud_bar("health", sim.health, "%d%%" % int(sim.health))
	_hud_bar("storage", sim.storage_pct(), "%d%%" % int(sim.storage_pct()), false)


# ============================================================== console actions (M4c)

func _action_button(text: String, tip: String, color: Color, enabled: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(200, 54)
	b.add_theme_font_size_override("font_size", 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color.darkened(0.35)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	sb.border_color = color
	sb.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate()
	hov.bg_color = color.darkened(0.15)
	b.add_theme_stylebox_override("hover", hov)
	b.pressed.connect(func():
		cb.call()
		_after_action())
	_panel_actions.add_child(b)
	return b


func _after_action() -> void:
	if _open == "":
		return
	_panel_body.text = _console_body(_open)
	_build_actions(_open)


func _build_actions(key: String) -> void:
	for c in _panel_actions.get_children():
		c.queue_free()
	var orange := Color(1.0, 0.55, 0.2)
	if events and events.active.get("console", "") == key:
		var choices: Array = events.active.get("choices", [])
		for i in choices.size():
			var ch: Dictionary = choices[i]
			var idx := i
			var cost := MissionSim.effects_cost(ch.get("effects", {}))
			_action_button(ch["label"], ch.get("effect", ""), Color(1.0, 0.35, 0.3) if i == 0 else Color(0.9, 0.6, 0.3),
				events.can_afford(ch), func(): events.choose(idx))
			if cost > 0.0 and not events.can_afford(ch):
				_panel_actions.get_child(_panel_actions.get_child_count() - 1).tooltip_text = "Not enough reserve money."
		return
	match key:
		"engineer":
			if sim.safe_mode:
				_action_button("Leave SAFE MODE", "Switch instruments back on and resume science.", Color(0.35, 0.9, 0.45), true,
					func(): sim.set_safe_mode(false))
			else:
				_action_button("Enter SAFE MODE", "Turn off all instruments: saves power and halves wear, but no science.",
					orange, true, func(): sim.set_safe_mode(true))
		"science":
			for id in sim.instruments_on:
				var it := GameData.get_item("instruments", id)
				var on: bool = sim.instruments_on[id]
				var iid: String = id
				_action_button("%s\n%s · %s W · %s Gb/day" % [it.get("name", id), "ON" if on else "OFF", PartInfo.fmt(it.get("power_w", 0)), PartInfo.fmt(it.get("data_gb_day", 0))],
					"Turn this instrument %s. Off saves power and memory; on makes science." % ("off" if on else "on"),
					Color(0.72, 0.48, 1.0) if on else Color(0.4, 0.4, 0.45), not sim.safe_mode, func(): sim.toggle_instrument(iid))
		"comms":
			_action_button("Buy +%d h/day antenna time\n$%d M (have $%s M)" % [int(MissionSim.CONTACT_STEP_H), int(MissionSim.CONTACT_COST), PartInfo.fmt(sim.reserve_musd)],
				"Rent more time on the ground antennas, so more data reaches Earth each day. Now: +%d h/day." % int(sim.extra_contact_hours),
				Color(0.3, 0.85, 1.0), sim.can_buy_contact(), func(): sim.buy_contact_time())
		"director":
			_action_button("Repair: software fix\n+%d%% health for $%d M" % [int(MissionSim.REPAIR_AMOUNT), int(MissionSim.REPAIR_COST)],
				"Engineers on Earth upload a fix. Costs reserve money (lowers the budget score).",
				Color(1.0, 0.82, 0.3), sim.can_repair(), func(): sim.repair())
			_action_button("End mission now", "Stop the mission early and go to the debrief.", Color(1.0, 0.35, 0.3), true,
				func(): sim.abort())


# ============================================================== events (M5)

func _setup_events() -> void:
	events = EventSystem.new()
	add_child(events)
	events.setup(sim)
	events.event_started.connect(_on_event_started)
	events.event_resolved.connect(_on_event_resolved)
	_alarm_light = OmniLight3D.new()
	_alarm_light.position = Vector3(0, 5.5, 0)
	_alarm_light.omni_range = 20
	_alarm_light.light_color = Color(1, 0.15, 0.1)
	_alarm_light.light_energy = 0.0
	add_child(_alarm_light)


func _on_event_started(ev: Dictionary) -> void:
	_acked.erase(ev.get("console", ""))
	if wall_view and wall_view.has_method("set_status") and ev.get("status", "normal") != "normal":
		wall_view.set_status(ev["status"])
	Sfx.play("alarm", -4.0)
	_alarm_repeat = 3.0
	if _open != "":
		_after_action()


func _on_event_resolved(ev: Dictionary, choice: Dictionary, outcome: String, timed_out: bool) -> void:
	var delay := float(mission.get("signal_delay_min", 0))
	var msg := ("No answer in time! " if timed_out else "") + "%s: %s." % [str(ev["title"]).capitalize(), choice["label"]]
	if outcome != "":
		msg += " " + outcome
	if delay >= 1.0:
		msg += "\n(Your command takes %d minutes to reach the spacecraft.)" % int(delay)
	_show_toast(msg, Color(1, 0.55, 0.45) if timed_out else Color(0.6, 1, 0.65))
	Sfx.play("fail" if timed_out else "fixed", -4.0)
	if wall_view and wall_view.has_method("set_status"):
		wall_view.set_status("safe_mode" if sim.safe_mode else "normal")
	if _open != "":
		_after_action()


func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.modulate = color
	_toast.visible = true
	_toast_time = 5.0


func _update_event_fx(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.visible = _toast_time > 0.0
	if events.active.is_empty():
		_alert_banner.visible = false
		_alarm_light.light_energy = 0.0
		return
	var st: ConsoleStation = consoles.get(events.active.get("console", ""), null)
	var where: String = st.title if st else "?"
	var at_console: bool = _open == events.active.get("console", "-")
	_alert_banner.visible = true
	_alert_banner.text = "ALERT: %s\n%s  ·  %d s" % [events.active["title"],
		"Choose an action on this console" if at_console else "Go to the %s console!" % where, int(ceil(events.time_left))]
	_alarm_light.light_energy = 0.0 if paused else (2.5 if fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.4 else 0.4)
	if not at_console and not paused:
		_alarm_repeat -= delta
		if _alarm_repeat <= 0.0:
			_alarm_repeat = 3.0
			Sfx.play("alarm", -4.0)


func _exit_tree() -> void:
	Sfx.stop_loop("hum")
