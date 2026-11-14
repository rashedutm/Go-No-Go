# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# Checks that every generated sound exists and has audio data; plays each once.
# Run: godot --headless --path . res://tests/sfx_test.tscn
extends Node

func _ready() -> void:
	var bad := 0
	for s in Sfx.SOUNDS:
		var st: AudioStream = Sfx._streams.get(s)
		var length := st.get_length() if st else 0.0
		print("%-9s %s  %.2f s" % [s, "ok " if st else "MISSING", length])
		if st == null or length <= 0.0:
			bad += 1
		Sfx.play(s)
	Sfx.start_loop("hum")
	Sfx.stop_loop("hum")
	print("RESULT: ", "ALL SOUNDS OK" if bad == 0 else "%d sounds missing" % bad)
	get_tree().quit()
