# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Sfx (autoload): sound effects generated in code (no audio files or licenses needed),
# a global main-menu button in the top-right corner (Esc) with Sound / Fullscreen /
# Home / Mission Select / Exit inside, and F11 / M shortcuts.
# If a real file exists at res://audio/<name>.wav|.ogg|.mp3 it is used instead (Daniel can drop
# files in without touching code). Every Button plays "click" automatically. Owner: Member A.
#
#   Sfx.play("snap")            # one-shot
#   Sfx.start_loop("hum")       # looping ambience; Sfx.stop_loop("hum")
#   Sfx.muted / Sfx.toggle_mute() / Sfx.toggle_fullscreen()
extends Node

const Neon := preload("res://scripts/ui/neon_ui.gd")
const SETTINGS_PATH := "user://settings.cfg"
const RATE := 22050
const SOUNDS := ["click", "snap", "beep", "go", "nogo", "alarm", "fixed", "complete", "fail", "hum", "whoosh"]

var muted := false
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _loops := {}
var _menu_btn: Button
var _menu_layer: CanvasLayer
var _menu_root: Control
var _menu_open := false
var _prev_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _menu_sound_btn: Button
var _menu_fs_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))
	AudioServer.set_bus_mute(0, muted)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for n in SOUNDS:
		_streams[n] = _load_or_make(n)
	get_tree().node_added.connect(_on_node_added)
	_build_buttons()
	_build_menu()
	if OS.has_feature("web"):
		# Browsers only allow fullscreen inside the real click/key event. Godot handles button
		# presses a frame later, so the page itself toggles fullscreen when the pointer is released
		# over our Fullscreen button (armed on hover) or when F11 is pressed.
		JavaScriptBridge.eval("""
			window.goNoGoFS = false;
			window.goNoGoToggleFS = function () {
				if (!document.fullscreenElement) {
					(document.documentElement.requestFullscreen ? document.documentElement.requestFullscreen() : Promise.resolve()).catch(function () {});
				} else if (document.exitFullscreen) { document.exitFullscreen(); }
			};
			document.addEventListener('pointerup', function () { if (window.goNoGoFS) { window.goNoGoToggleFS(); } }, true);
			document.addEventListener('keydown', function (e) { if (e.key === 'F11') { e.preventDefault(); window.goNoGoToggleFS(); } }, true);
		""", true)


var _fs_poll := 0.0


func _process(delta: float) -> void:
	_fs_poll -= delta
	if _fs_poll <= 0.0:
		_fs_poll = 0.5
		_update_buttons()


func is_fullscreen() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("!!document.fullscreenElement", true))
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


# ============================================================ playback

func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	var s: AudioStream = _streams.get(sound)
	if s == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	_players[0].stream = s
	_players[0].play()


func start_loop(sound: String, volume_db := -14.0) -> void:
	if _loops.has(sound):
		return
	var src: AudioStream = _streams.get(sound)
	if src == null:
		return
	var s: AudioStream = src
	if src is AudioStreamWAV:
		s = src.duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = volume_db
	add_child(p)
	p.play()
	_loops[sound] = p


func stop_loop(sound: String) -> void:
	if _loops.has(sound):
		_loops[sound].queue_free()
		_loops.erase(sound)


func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS_PATH)
	_update_buttons()


func toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		return   # handled by the page's own click/F11 listener (see _ready)
	var fs := is_fullscreen()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_buttons.call_deferred()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			toggle_menu()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F11:
			toggle_fullscreen()
		elif event.physical_keycode == KEY_M:
			toggle_mute()


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("no_click"):
		node.pressed.connect(func(): play("click", -8.0))


# ============================================================ corner menu

var _icon_menu: Texture2D


func _build_buttons() -> void:
	_icon_menu = load("res://ui/icons/menu.svg")
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -54
	box.offset_top = 6
	box.offset_right = -6
	box.offset_bottom = 40
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.grow_vertical = Control.GROW_DIRECTION_END
	box.alignment = BoxContainer.ALIGNMENT_END
	layer.add_child(box)
	_menu_btn = _corner_button(_icon_menu)
	_menu_btn.tooltip_text = "Main menu (Esc)"
	_menu_btn.pressed.connect(toggle_menu)
	box.add_child(_menu_btn)
	_update_buttons()


func _build_menu() -> void:
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 120
	add_child(_menu_layer)
	_menu_root = Control.new()
	_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_root.visible = false
	_menu_layer.add_child(_menu_root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.005, 0.01, 0.025, 0.78)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_root.add_child(center)

	var panel := Neon.panel("cyan", 26)
	panel.custom_minimum_size = Vector2(400, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(Neon.kicker("GO / NO-GO", Neon.CYAN, 11))
	v.add_child(Neon.display("MISSION MENU", 38, Neon.TEXT))
	v.add_child(Neon.caption("FLIGHT OPERATIONS  ·  PAUSED", 13))
	v.add_child(Neon.rule(Neon.CYAN_DIM))

	var resume := Button.new()
	resume.text = "RESUME"
	resume.custom_minimum_size = Vector2(0, 46)
	Neon.primary(resume, 18)
	resume.pressed.connect(close_menu)
	v.add_child(resume)

	var missions := Button.new()
	missions.text = "MISSION SELECT"
	missions.custom_minimum_size = Vector2(0, 42)
	Neon.ghost(missions, 16)
	missions.pressed.connect(_menu_go.bind("campaign_map"))
	v.add_child(missions)

	var home := Button.new()
	home.text = "HOME SCREEN"
	home.custom_minimum_size = Vector2(0, 42)
	Neon.ghost(home, 16)
	home.pressed.connect(_menu_go.bind("title"))
	v.add_child(home)

	v.add_child(Neon.rule(Neon.CYAN_DIM))

	_menu_sound_btn = Button.new()
	_menu_sound_btn.custom_minimum_size = Vector2(0, 38)
	Neon.ghost(_menu_sound_btn, 14)
	_menu_sound_btn.pressed.connect(toggle_mute)
	v.add_child(_menu_sound_btn)

	_menu_fs_btn = Button.new()
	_menu_fs_btn.custom_minimum_size = Vector2(0, 38)
	Neon.ghost(_menu_fs_btn, 14)
	_menu_fs_btn.pressed.connect(toggle_fullscreen)
	if OS.has_feature("web"):
		_menu_fs_btn.mouse_entered.connect(func(): JavaScriptBridge.eval("window.goNoGoFS = true;", true))
		_menu_fs_btn.mouse_exited.connect(func(): JavaScriptBridge.eval("window.goNoGoFS = false;", true))
	v.add_child(_menu_fs_btn)

	if not OS.has_feature("web"):
		var quit := Button.new()
		quit.text = "EXIT GAME"
		quit.custom_minimum_size = Vector2(0, 40)
		Neon.danger(quit, 15)
		quit.pressed.connect(_exit_game)
		v.add_child(quit)

	var hint := Neon.caption("ESC TO RESUME", 11)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	_update_buttons()


func toggle_menu() -> void:
	if _menu_open:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	if _menu_open:
		return
	_menu_open = true
	_prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_menu_root.visible = true
	get_tree().paused = true
	_update_buttons()
	play("beep", -10.0)


func close_menu() -> void:
	if not _menu_open:
		return
	_menu_open = false
	_menu_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = _prev_mouse_mode
	_update_buttons()


func _menu_go(key: String) -> void:
	_menu_open = false
	_menu_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_buttons()
	MissionState.go_to(key)


func _exit_game() -> void:
	_menu_open = false
	_menu_root.visible = false
	get_tree().paused = false
	get_tree().quit()


func _corner_button(icon: Texture2D) -> Button:
	var b := Button.new()
	b.icon = icon
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.text = ""
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(44, 34)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	sb.border_color = Color(0.31, 0.84, 1.0, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(5)
	for st in ["normal", "hover", "pressed", "focus"]:
		var s2: StyleBoxFlat = sb.duplicate()
		if st == "hover":
			s2.bg_color = Color(0.08, 0.16, 0.28, 0.95)
			s2.border_color = Color(0.31, 0.84, 1.0)
		elif st == "pressed":
			s2.bg_color = Color(0.02, 0.06, 0.12, 0.7)
		b.add_theme_stylebox_override(st, s2)
	return b


func _update_buttons() -> void:
	if _menu_sound_btn:
		_menu_sound_btn.text = "SOUND: OFF" if muted else "SOUND: ON"
	if _menu_fs_btn:
		_menu_fs_btn.text = "FULLSCREEN: ON" if is_fullscreen() else "FULLSCREEN: OFF"
	if _menu_btn:
		_menu_btn.tooltip_text = "Close menu (Esc)" if _menu_open else "Main menu (Esc)"


# ============================================================ sound synthesis

func _load_or_make(sound: String) -> AudioStream:
	for ext in ["wav", "ogg", "mp3"]:
		var path := "res://audio/%s.%s" % [sound, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return _make(sound)


## notes: Array of [start_s, duration_s, freq_hz, amplitude, wave] ; wave: "sine" | "square" | "noise" | "tri"
func _synth(length_s: float, notes: Array, slide := 0.0) -> AudioStreamWAV:
	var n := int(RATE * length_s)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for note in notes:
		var start := int(float(note[0]) * RATE)
		var dur := int(float(note[1]) * RATE)
		var freq: float = note[2]
		var amp: float = note[3]
		var wave: String = note[4]
		var phase := 0.0
		for i in dur:
			var idx := start + i
			if idx >= n:
				break
			var t := float(i) / RATE
			var flat: bool = note.size() > 5 and note[5]
			var env := 1.0 if flat else minf(1.0, t / 0.008) * pow(1.0 - float(i) / dur, 1.5)   # quick attack, smooth decay
			var f := freq * (1.0 + slide * float(i) / dur)
			phase += TAU * f / RATE
			var v := 0.0
			match wave:
				"sine": v = sin(phase)
				"square": v = 1.0 if sin(phase) >= 0.0 else -1.0
				"tri": v = 2.0 / PI * asin(sin(phase))
				"noise": v = rng.randf_range(-1.0, 1.0)
			buf[idx] += v * amp * env
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


func _make(sound: String) -> AudioStream:
	match sound:
		"click":      # tiny soft tick
			return _synth(0.05, [[0.0, 0.04, 1250.0, 0.12, "sine"]])
		"whoosh":     # soft two-note slide (station change)
			return _synth(0.18, [[0.0, 0.09, 587.0, 0.12, "sine"], [0.06, 0.12, 784.0, 0.12, "sine"]])
		"snap":       # gentle "tock" when a part attaches
			return _synth(0.16, [[0.0, 0.07, 392.0, 0.22, "sine"], [0.03, 0.12, 784.0, 0.10, "sine"]])
		"beep":       # poll: station is checking
			return _synth(0.1, [[0.0, 0.08, 880.0, 0.12, "sine"]])
		"go":         # poll: GO
			return _synth(0.32, [[0.0, 0.12, 659.0, 0.16, "sine"], [0.09, 0.22, 988.0, 0.16, "sine"]])
		"nogo":       # poll: NO-GO (low, not harsh)
			return _synth(0.4, [[0.0, 0.36, 196.0, 0.22, "tri"], [0.0, 0.36, 185.0, 0.14, "tri"]])
		"alarm":      # mission-control alert: clear but not piercing
			return _synth(0.6, [[0.0, 0.2, 784.0, 0.2, "tri"], [0.25, 0.2, 587.0, 0.2, "tri"]])
		"fixed":      # problem solved
			return _synth(0.45, [[0.0, 0.14, 523.0, 0.15, "sine"], [0.09, 0.14, 659.0, 0.15, "sine"], [0.18, 0.26, 784.0, 0.15, "sine"]])
		"complete":   # mission complete / all GO
			return _synth(1.3, [[0.0, 0.25, 523.0, 0.15, "sine"], [0.18, 0.25, 659.0, 0.15, "sine"], [0.36, 0.25, 784.0, 0.15, "sine"],
				[0.54, 0.75, 1047.0, 0.17, "sine"], [0.54, 0.75, 523.0, 0.08, "tri"]])
		"fail":       # mission failed / no answer
			return _synth(0.9, [[0.0, 0.28, 392.0, 0.15, "tri"], [0.22, 0.28, 349.0, 0.15, "tri"], [0.44, 0.45, 294.0, 0.15, "tri"]])
		"hum":        # control-room ambience, very quiet, loops seamlessly every 2 s
			return _synth(2.0, [[0.0, 2.0, 60.0, 0.06, "sine", true], [0.0, 2.0, 120.0, 0.025, "sine", true]])
	return null
