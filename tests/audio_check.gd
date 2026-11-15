# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Checks every sound loads from res://audio and that music/hum loop.
extends Node

func _ready() -> void:
	var ok := true
	for n in Sfx.SOUNDS:
		var s: AudioStream = Sfx._streams.get(n)
		var src := "file" if s and s.resource_path != "" else "synth"
		print("%-9s %-22s %s  %.2fs" % [n, s.get_class() if s else "MISSING", src, s.get_length() if s else 0.0])
		if s == null:
			ok = false
	var m: AudioStream = Sfx._music.stream
	print("music loop: ", m.loop_mode if m is AudioStreamWAV else m.get("loop"), " playing=", Sfx._music.playing)
	var h := Sfx._looping(Sfx._streams["hum"])
	print("hum loop: ", h.get("loop"))
	Sfx.music_for("mission_control")
	for n in Sfx.SOUNDS:
		Sfx.play(n)
	await get_tree().create_timer(2.0).timeout
	print("music db after fade: ", Sfx._music.volume_db)
	print("RESULT: AUDIO OK" if ok else "RESULT: AUDIO FAIL")
	get_tree().quit()
