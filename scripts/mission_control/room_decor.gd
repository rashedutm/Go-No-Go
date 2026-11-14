# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# RoomDecor: makes the Mission Control room feel alive.
#  - 4 live wall screens (power, science data, ground track, spacecraft health) fed by MissionSim
#  - 2 status boards beside the main screen (mission clock, data returned / status)
#  - a hologram of the destination planet with an orbiting spacecraft
#  - robot colleagues at the empty desks, scrolling telemetry on their monitors
#  - fact posters on the back wall, a glowing floor ring
# Built by Mission Control after the room; update() is called every frame. Owner: Member B (Emon).
class_name RoomDecor
extends Node3D

var mc: Node                  # mission_control.gd
var sim: MissionSim
var _graphs := {}             # key -> TelemetryGraph
var _sample := 0.0
var _clock: Label3D
var _status: Label3D
var _holo: Node3D
var _holo_orbit: Node3D
var _ring: MeshInstance3D
var _robots: Array = []
var _tele_labels: Array = []
var _tele_t := 0.0
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func build(p_mc: Node, p_sim: MissionSim) -> void:
	mc = p_mc
	sim = p_sim
	_rng.seed = 2026
	var m: Dictionary = sim.mission
	# ---- live wall screens (left wall faces +X, right wall faces -X)
	var g := _make_screen("power", "POWER", Color(1.0, 0.6, 0.25), Vector3(-10.9, 3.3, -3.0), PI / 2)
	g.add_series("Battery", Color(0.35, 0.95, 0.5))
	g.add_series("Power used", Color(1.0, 0.6, 0.25))
	g = _make_screen("data", "SCIENCE DATA", Color(0.75, 0.5, 1.0), Vector3(10.9, 3.3, -3.0), -PI / 2)
	g.add_series("Returned", Color(0.75, 0.5, 1.0))
	g.add_series("Plan", Color(0.6, 0.6, 0.7))
	g.add_series("Memory", Color(0.3, 0.85, 1.0))
	g = _make_screen("track", "GROUND TRACK", Color(0.35, 0.95, 0.6), Vector3(-10.9, 3.3, 3.5), PI / 2)
	g.mode = "track"
	g = _make_screen("health", "SPACECRAFT HEALTH", Color(1.0, 0.82, 0.3), Vector3(10.9, 3.3, 3.5), -PI / 2)
	g.add_series("Health", Color(1.0, 0.82, 0.3))
	g.add_series("Reserve", Color(0.35, 0.95, 0.5))

	# ---- status boards beside the main screen
	_clock = _board(Vector3(-8.3, 4.3, -8.95), Color(1.0, 0.82, 0.3))
	_status = _board(Vector3(8.3, 4.3, -8.95), Color(0.35, 0.95, 0.6))

	# ---- hologram of the destination planet
	var ped := Vector3(-2.8, 0, 1.2)
	MCBuild.box(self, Vector3(1.2, 0.8, 1.2), ped + Vector3(0, 0.4, 0), Color(0.15, 0.17, 0.22), true)
	MCBuild.box(self, Vector3(1.0, 0.04, 1.0), ped + Vector3(0, 0.82, 0), Color(0.3, 0.8, 1.0), false, 2.0)
	_holo = Node3D.new()
	_holo.position = ped + Vector3(0, 1.7, 0)
	add_child(_holo)
	var planet := MenuPlanet.make(m.get("id", "earth"))
	planet.scale = Vector3.ONE * 0.45
	_holo.add_child(planet)
	_holo_orbit = Node3D.new()
	_holo_orbit.rotation_degrees = Vector3(15, 0, 0)
	_holo.add_child(_holo_orbit)
	var dot := SpacecraftModel3D._sphere(0.06, Color(1, 0.85, 0.3), true)
	dot.position = Vector3(0.8, 0, 0)
	_holo_orbit.add_child(dot)
	var orbit_ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.78
	tm.outer_radius = 0.81
	tm.material = MCBuild.mat(Color(0.3, 0.8, 1.0), 2.0)
	orbit_ring.mesh = tm
	_holo_orbit.add_child(orbit_ring)
	var holo_light := OmniLight3D.new()
	holo_light.position = ped + Vector3(0, 1.6, 0)
	holo_light.light_color = Color(0.4, 0.8, 1.0)
	holo_light.omni_range = 4.0
	holo_light.light_energy = 0.8
	add_child(holo_light)

	# ---- glowing floor ring around the hologram
	_ring = MeshInstance3D.new()
	var rt := TorusMesh.new()
	rt.inner_radius = 1.6
	rt.outer_radius = 1.7
	rt.material = MCBuild.mat(Color(0.2, 0.6, 1.0), 1.5)
	_ring.mesh = rt
	_ring.scale = Vector3(1, 0.05, 1)
	_ring.position = ped + Vector3(0, 0.02, 0)
	add_child(_ring)

	# ---- robot colleagues + telemetry at the decorative desks
	for p in [Vector3(-6, 0, 2.5), Vector3(-4, 0, 6.0), Vector3(4, 0, 6.0)]:
		_robots.append(_robot(p + Vector3(0, 0, 0.95)))
		var lab := MCBuild.label(self, "", p + Vector3(0, 1.25, -0.18), Color(0.4, 1.0, 0.6), 22, 0.0028)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_tele_labels.append(lab)

	# ---- posters on the back wall (seen when you turn around)
	var facts := [
		["THE MISSION", "%s\n%s" % [m.get("name", ""), m.get("objective", "")]],
		["DID YOU KNOW?", str(m.get("fact", ""))],
		["SIGNAL DELAY", "Radio messages travel at the speed of light.\nFrom %s they take %s." % [m.get("destination", ""), _delay_text(float(m.get("signal_delay_min", 0)))]],
	]
	for i in facts.size():
		var x := -6.0 + i * 6.0
		MCBuild.box(self, Vector3(4.6, 2.6, 0.05), Vector3(x, 3.0, 9.0), Color(0.06, 0.1, 0.2), false, 0.4)
		MCBuild.box(self, Vector3(4.6, 0.08, 0.06), Vector3(x, 4.3, 8.98), Color(1.0, 0.82, 0.3), false, 1.5)
		var t1 := MCBuild.label(self, facts[i][0], Vector3(x, 4.0, 8.96), Color(1.0, 0.82, 0.3), 40, 0.005)
		t1.rotation.y = PI
		var t2 := MCBuild.label(self, _wrap(facts[i][1], 30), Vector3(x, 2.85, 8.96), Color(0.85, 0.9, 1.0), 40, 0.0055)
		t2.rotation.y = PI


func _delay_text(minutes: float) -> String:
	if minutes <= 0.0:
		return "a fraction of a second"
	if minutes < 1.0:
		return "%.1f seconds" % (minutes * 60.0)
	return "about %d minutes" % int(minutes)


func _wrap(text: String, width: int) -> String:
	var out := ""
	var line := ""
	for word in text.split(" "):
		if line.length() + word.length() + 1 > width and line != "":
			out += line + "\n"
			line = word
		else:
			line = word if line == "" else line + " " + word
	return out + line


func _make_screen(key: String, title: String, accent: Color, pos: Vector3, rot_y: float) -> TelemetryGraph:
	var sub := SubViewport.new()
	sub.size = Vector2i(768, 432)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)
	var graph := TelemetryGraph.new()
	graph.size = Vector2(768, 432)
	graph.title = title
	graph.accent = accent
	sub.add_child(graph)
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = rot_y
	add_child(holder)
	MCBuild.box(holder, Vector3(4.2, 2.5, 0.12), Vector3(0, 0, -0.04), Color(0.05, 0.05, 0.07))
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(4.0, 2.25)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = sub.get_texture()
	qm.material = mat
	quad.mesh = qm
	quad.position = Vector3(0, 0, 0.03)
	holder.add_child(quad)
	_graphs[key] = graph
	return graph


func _board(pos: Vector3, color: Color) -> Label3D:
	MCBuild.box(self, Vector3(4.6, 2.2, 0.1), pos + Vector3(0, 0, 0.0), Color(0.03, 0.04, 0.07))
	MCBuild.box(self, Vector3(4.6, 0.06, 0.12), pos + Vector3(0, 1.1, 0.01), color, false, 1.5)
	var l := MCBuild.label(self, "", pos + Vector3(0, -0.05, 0.08), color, 64, 0.0075)
	return l


func _robot(pos: Vector3) -> Node3D:
	var r := Node3D.new()
	r.position = pos
	add_child(r)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.25
	cap.height = 0.9
	cap.material = MCBuild.mat(Color(0.75, 0.78, 0.85), 0.0, 0.6, 0.3)
	body.mesh = cap
	body.position.y = 0.95
	r.add_child(body)
	var head := SpacecraftModel3D._sphere(0.2, Color(0.8, 0.82, 0.88))
	head.position.y = 1.6
	r.add_child(head)
	var visor := MCBuild.box(r, Vector3(0.28, 0.08, 0.05), Vector3(0, 1.62, -0.18), Color(0.3, 0.9, 1.0), false, 3.0)
	visor.name = "Visor"
	return r


func update(delta: float) -> void:
	_t += delta
	# ---- animations
	_holo.rotation.y += delta * 0.4
	_holo_orbit.rotation.y += delta * 1.2
	_holo.position.y = 1.7 + sin(_t * 1.5) * 0.05
	var rm: StandardMaterial3D = _ring.mesh.material
	rm.emission_energy_multiplier = 1.2 + sin(_t * 2.0) * 0.6
	for i in _robots.size():
		var r: Node3D = _robots[i]
		r.position.y = sin(_t * 2.0 + i) * 0.03
		r.rotation.y = sin(_t * 0.4 + i * 2.0) * 0.4
	_graphs["track"].phase = sim.day / 0.5 if sim.mission.get("eclipse_period_min", 0) else sim.day / 7.0
	_graphs["track"].info = "Orbit %d  ·  Day %d" % [int(_graphs["track"].phase), int(sim.day)]
	_graphs["track"].queue_redraw()

	# ---- boards
	var years := sim.day / 365.0
	_clock.text = "MISSION CLOCK\nDAY %d\n%.1f / %.1f yr" % [int(sim.day), years, sim.total_days / 365.0]
	var state := "NOMINAL"
	var col := Color(0.35, 0.95, 0.6)
	if sim.safe_mode:
		state = "SAFE MODE"
		col = Color(1, 0.7, 0.2)
	if sim.blackout_days > 0.0:
		state = "NO SIGNAL"
		col = Color(1, 0.4, 0.35)
	if mc.events and not mc.events.active.is_empty():
		state = "ALERT"
		col = Color(1, 0.35, 0.3) if fmod(_t, 0.8) < 0.4 else Color(0.6, 0.2, 0.2)
	var goal := maxf(float(sim.mission.get("data_goal_gb", 1)), 1.0)
	_status.text = "STATUS: %s\nDATA %d%%\nHEALTH %d%%" % [state, int(100.0 * sim.data_returned_gb / goal), int(sim.health)]
	_status.modulate = col

	# ---- telemetry scroll on the robots' monitors
	_tele_t -= delta
	if _tele_t <= 0.0:
		_tele_t = 0.35
		for lab in _tele_labels:
			var lines: PackedStringArray = lab.text.split("\n") if lab.text != "" else PackedStringArray()
			lines.append("%s %04X %+.2f" % [["PWR", "TMP", "ATT", "RX", "TX", "GYR"][_rng.randi() % 6], _rng.randi() % 65536, _rng.randf_range(-9, 9)])
			while lines.size() > 7:
				lines.remove_at(0)
			lab.text = "\n".join(lines)

	# ---- sample graphs
	_sample -= delta
	if _sample > 0.0:
		return
	_sample = 0.3
	var pw: TelemetryGraph = _graphs["power"]
	pw.push(0, sim.battery_pct())
	pw.push(1, 100.0 * sim.power_load_w / maxf(sim.power_gen_w, 1.0))
	pw.info = "Made %d W  ·  Used %d W" % [int(sim.power_gen_w), int(sim.power_load_w)]
	var dg: TelemetryGraph = _graphs["data"]
	dg.push(0, 100.0 * sim.data_returned_gb / goal)
	dg.push(1, 100.0 * sim.progress())
	dg.push(2, sim.storage_pct())
	dg.info = "Sending %.1f Gb/day  ·  goal %s Gb" % [sim.downlink_gb_day, PartInfo.fmt(goal)]
	var hg: TelemetryGraph = _graphs["health"]
	hg.push(0, sim.health)
	hg.push(1, 100.0 * sim.reserve_musd / maxf(float(sim.mission.get("budget_musd", 1)), 1.0))
	hg.info = "Reserve $%s M" % PartInfo.fmt(sim.reserve_musd)
	for k in ["power", "data", "health"]:
		_graphs[k].queue_redraw()
