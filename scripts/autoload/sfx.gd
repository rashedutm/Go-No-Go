# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Sfx (autoload): sound effects generated in code (no audio files or licenses needed),
# a global Fullscreen / Sound button pair in the top-right corner, and F11 / M shortcuts.
# If a real file exists at res://audio/<name>.wav|.ogg|.mp3 it is used instead (Daniel can drop
# files in without touching code). Every Button plays "click" automatically. Owner: Member A.
#
#   Sfx.play("snap")            # one-shot
#   Sfx.start_loop("hum")       # looping ambience; Sfx.stop_loop("hum")
#   Sfx.muted / Sfx.toggle_mute() / Sfx.toggle_fullscreen()
extends Node

const SETTINGS_PATH := "user://settings.cfg"
const RATE := 22050
const SOUNDS := ["click", "snap", "beep", "go", "nogo", "alarm", "fixed", "complete", "fail", "hum", "whoosh"]

var muted := false
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _loops := {}
var _fs_btn: Button
var _mute_btn: Button


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
	var fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_buttons.call_deferred()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F11:
			toggle_fullscreen()
		elif event.physical_keycode == KEY_M:
			toggle_mute()


func _on_node_added(node: Node) -> void:
	if node is BaseButton and node != _fs_btn and node != _mute_btn and not node.has_meta("no_click"):
		node.pressed.connect(func(): play("click", -8.0))


# ============================================================ corner buttons

func _build_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var box := HBoxContainer.new()
	box.position = Vector2(1086, 4)
	box.add_theme_constant_override("separation", 4)
	layer.add_child(box)
	_fs_btn = _corner_button("Fullscreen")
	_fs_btn.tooltip_text = "Fullscreen on/off (F11)"
	_fs_btn.pressed.connect(toggle_fullscreen)
	box.add_child(_fs_btn)
	_mute_btn = _corner_button("Sound: on")
	_mute_btn.tooltip_text = "Sound on/off (M)"
	_mute_btn.pressed.connect(toggle_mute)
	box.add_child(_mute_btn)
	_update_buttons()


func _corner_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(92, 24)
	b.add_theme_font_size_override("font_size", 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.16, 0.7)
	sb.border_color = Color(0.35, 0.5, 0.9, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(3)
	for st in ["normal", "hover", "pressed"]:
		var s2: StyleBoxFlat = sb.duplicate()
		if st == "hover":
			s2.bg_color = Color(0.12, 0.2, 0.4, 0.9)
		b.add_theme_stylebox_override(st, s2)
	return b


func _update_buttons() -> void:
	if _mute_btn:
		_mute_btn.text = "Sound: off" if muted else "Sound: on"
	if _fs_btn:
		var fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		_fs_btn.text = "Exit fullscreen" if fs else "Fullscreen"


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
		"click":
			return _synth(0.06, [[0.0, 0.05, 1800.0, 0.25, "sine"], [0.0, 0.02, 0.0, 0.15, "noise"]])
		"snap":
			return _synth(0.22, [[0.0, 0.08, 180.0, 0.6, "square"], [0.0, 0.05, 0.0, 0.35, "noise"], [0.06, 0.14, 520.0, 0.25, "sine"]])
		"whoosh":
			return _synth(0.35, [[0.0, 0.35, 0.0, 0.25, "noise"], [0.0, 0.35, 300.0, 0.1, "sine"]], 1.5)
		"beep":
			return _synth(0.12, [[0.0, 0.1, 1000.0, 0.3, "sine"]])
		"go":
			return _synth(0.4, [[0.0, 0.15, 660.0, 0.3, "sine"], [0.1, 0.3, 990.0, 0.3, "sine"]])
		"nogo":
			return _synth(0.45, [[0.0, 0.4, 140.0, 0.35, "square"], [0.0, 0.4, 147.0, 0.25, "square"]])
		"alarm":
			return _synth(0.6, [[0.0, 0.18, 880.0, 0.35, "square"], [0.26, 0.18, 660.0, 0.35, "square"]])
		"fixed":
			return _synth(0.5, [[0.0, 0.15, 523.0, 0.3, "tri"], [0.1, 0.15, 659.0, 0.3, "tri"], [0.2, 0.3, 784.0, 0.3, "tri"]])
		"complete":
			return _synth(1.4, [[0.0, 0.25, 523.0, 0.3, "tri"], [0.2, 0.25, 659.0, 0.3, "tri"], [0.4, 0.25, 784.0, 0.3, "tri"],
				[0.6, 0.8, 1047.0, 0.35, "tri"], [0.6, 0.8, 523.0, 0.15, "sine"]])
		"fail":
			return _synth(1.0, [[0.0, 0.3, 392.0, 0.3, "tri"], [0.25, 0.3, 330.0, 0.3, "tri"], [0.5, 0.5, 262.0, 0.3, "tri"]])
		"hum":
			# 2 s seamless control-room ambience: low hum + soft air noise (frequencies fit whole cycles in 2 s)
			return _synth(2.0, [[0.0, 2.0, 60.0, 0.12, "sine", true], [0.0, 2.0, 120.0, 0.05, "sine", true], [0.0, 2.0, 0.0, 0.03, "noise", true]])
	return null
