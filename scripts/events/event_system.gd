# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# EventSystem (M5): picks random events from data/events.json that fit the mission, runs the
# countdown, and applies the chosen (or default, if time runs out) choice to the MissionSim.
# The countdown freezes while the player has the right console open. Owner: Member B (Emon).
class_name EventSystem
extends Node

signal event_started(ev: Dictionary)
signal event_resolved(ev: Dictionary, choice: Dictionary, outcome: String, timed_out: bool)

const FIRST_DELAY := 12.0     # real seconds before the first event
const GAP_MIN := 18.0
const GAP_MAX := 30.0

var sim: MissionSim
var rng := RandomNumberGenerator.new()
var active: Dictionary = {}
var time_left := 0.0
var _until_next := FIRST_DELAY
var _used: Array = []


func setup(p_sim: MissionSim, seed_value := 0) -> void:
	sim = p_sim
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	_until_next = FIRST_DELAY


func _has_power_kind(kind: String) -> bool:
	for p in sim.design.get("power", []):
		if GameData.get_item("power", p).get("kind", "") == kind:
			return true
	return false


func eligible() -> Array:
	var mid: String = sim.design.get("mission_id", "")
	var out: Array = []
	for ev in GameData.get_table("events"):
		if not mid in ev.get("destinations", []):
			continue
		var req: String = ev.get("requires", "")
		if req != "" and not _has_power_kind(req):
			continue
		out.append(ev)
	return out


func _pick() -> Dictionary:
	var pool := eligible().filter(func(e): return not e["id"] in _used)
	if pool.is_empty():
		_used.clear()
		pool = eligible()
	if pool.is_empty():
		return {}
	var total := 0.0
	for e in pool:
		total += float(e.get("weight", 1))
	var r := rng.randf() * total
	for e in pool:
		r -= float(e.get("weight", 1))
		if r <= 0.0:
			return e
	return pool[-1]


## Called every frame by Mission Control. `frozen` = the player is at the right console.
func update(real_dt: float, paused: bool, frozen: bool) -> void:
	if sim == null or sim.finished or paused:
		return
	if active.is_empty():
		_until_next -= real_dt
		if _until_next <= 0.0:
			var ev := _pick()
			if not ev.is_empty():
				start(ev)
	elif not frozen:
		time_left -= real_dt
		if time_left <= 0.0:
			choose(int(active.get("default", 0)), true)


func start(ev: Dictionary) -> void:
	active = ev
	time_left = float(ev.get("timer_s", 20))
	_used.append(ev["id"])
	sim.add_log("ALERT: %s" % ev["title"])
	event_started.emit(ev)


func start_by_id(id: String) -> void:
	for ev in GameData.get_table("events"):
		if ev["id"] == id:
			start(ev)
			return


func can_afford(choice: Dictionary) -> bool:
	return MissionSim.effects_cost(choice.get("effects", {})) <= sim.reserve_musd + 0.001


## Apply choice `idx` of the active event. Returns false if it can't be paid for.
func choose(idx: int, timed_out := false) -> bool:
	if active.is_empty():
		return false
	var choices: Array = active.get("choices", [])
	idx = clampi(idx, 0, choices.size() - 1)
	var ch: Dictionary = choices[idx]
	if not timed_out and not can_afford(ch):
		return false
	var ev := active
	active = {}
	var outcome := sim.apply_effects(ch.get("effects", {}), rng)
	var title: String = str(ev["title"]).capitalize()
	var text := "%s: %s%s." % [title, ch["label"], " (no answer in time)" if timed_out else ""]
	var effect: String = ch.get("effect", "")
	if outcome != "":
		effect += ". " + outcome
	sim.add_log(text, "%s: %s%s" % [title, ch["label"], ", because nobody answered in time" if timed_out else ""], effect)
	_until_next = rng.randf_range(GAP_MIN, GAP_MAX)
	event_resolved.emit(ev, ch, outcome, timed_out)
	return true


## A short two-tone alarm generated in code (used when no audio/alarm.* file exists).
static func make_beep() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.6)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var s := 0.0
		if t < 0.18:
			s = sin(TAU * 880.0 * t)
		elif t > 0.26 and t < 0.44:
			s = sin(TAU * 660.0 * t)
		data.encode_s16(i * 2, int(s * 32767.0 * 0.35))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
