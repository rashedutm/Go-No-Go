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
		if event.physical_keycode == KEY_F11:
			toggle_fullscreen()
		elif event.physical_keycode == KEY_M:
			toggle_mute()


func _on_node_added(node: Node) -> void:
	if node is BaseButton and node != _fs_btn and node != _mute_btn and not node.has_meta("no_click"):
		node.pressed.connect(func(): play("click", -8.0))


# ============================================================ corner buttons

var _icon_fs: ImageTexture
var _icon_snd_on: ImageTexture
var _icon_snd_off: ImageTexture


func _build_buttons() -> void:
	_icon_fs = _make_icon("fs")
	_icon_snd_on = _make_icon("snd_on")
	_icon_snd_off = _make_icon("snd_off")
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -100
	box.offset_top = 6
	box.offset_right = -6
	box.offset_bottom = 40
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.grow_vertical = Control.GROW_DIRECTION_END
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 6)
	layer.add_child(box)
	_fs_btn = _corner_button(_icon_fs)
	_fs_btn.tooltip_text = "Fullscreen on/off (F11)"
	_fs_btn.pressed.connect(toggle_fullscreen)
	if OS.has_feature("web"):
		_fs_btn.mouse_entered.connect(func(): JavaScriptBridge.eval("window.goNoGoFS = true;", true))
		_fs_btn.mouse_exited.connect(func(): JavaScriptBridge.eval("window.goNoGoFS = false;", true))
	box.add_child(_fs_btn)
	_mute_btn = _corner_button(_icon_snd_on)
	_mute_btn.tooltip_text = "Sound on/off (M)"
	_mute_btn.pressed.connect(toggle_mute)
	box.add_child(_mute_btn)
	_update_buttons()


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


## Pixel-art HUD icons drawn in code (no font glyphs, so they render
## identically in desktop and web builds).
func _make_icon(kind: String) -> ImageTexture:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color(0.82, 0.93, 1.0)
	match kind:
		"fs":   # four corner brackets
			for cx in [3, 15]:
				for cy in [3, 15]:
					img.fill_rect(Rect2i(cx, cy, 6, 2), c)
					img.fill_rect(Rect2i(cx, cy, 2, 6), c)
		"snd_on", "snd_off":   # speaker + waves (or a mute cross)
			img.fill_rect(Rect2i(2, 9, 4, 7), c)
			for y in 24:
				var t := float(y - 5) / 14.0
				if t >= 0.0 and t <= 1.0:
					var x_end := int(6 + t * 7.0)
					for x in range(6, x_end + 1):
						img.set_pixel(x, y, c)
			if kind == "snd_on":
				_arc(img, 12, 12, 5, -52.0, 52.0, c)
				_arc(img, 12, 12, 8, -48.0, 48.0, c)
			else:
				_line(img, 15, 6, 22, 18, Color(1.0, 0.45, 0.4))
				_line(img, 22, 6, 15, 18, Color(1.0, 0.45, 0.4))
	return ImageTexture.create_from_image(img)


func _arc(img: Image, cx: int, cy: int, r: int, a0: float, a1: float, c: Color) -> void:
	var a := a0
	while a <= a1:
		var rad := deg_to_rad(a)
		var x := int(round(cx + cos(rad) * r))
		var y := int(round(cy + sin(rad) * r))
		if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
			img.set_pixel(x, y, c)
		a += 6.0


func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	while true:
		if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
			img.set_pixel(x, y, c)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


func _update_buttons() -> void:
	if _mute_btn:
		_mute_btn.icon = _icon_snd_off if muted else _icon_snd_on
		_mute_btn.tooltip_text = "Sound off (M) — click to unmute" if muted else "Sound on (M) — click to mute"
		_mute_btn.modulate = Color(1.0, 0.6, 0.55) if muted else Color.WHITE
	if _fs_btn:
		_fs_btn.tooltip_text = "Exit fullscreen (F11)" if is_fullscreen() else "Fullscreen (F11)"


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
