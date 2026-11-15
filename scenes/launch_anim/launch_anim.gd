# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M6b: 3D launch & cruise — night pad, countdown, liftoff, stage separation,
# solar-wing deploy, cruise to the destination planet, then Mission Control.
# Skippable with the SKIP button or Space. Owner: Member C (Danial).
extends Node3D

const TOTAL := 23.6
const LIFTOFF_T := 3.0
const CUT_T := 7.0
const CUT_FADE_OUT := 0.8
const CUT_FADE_IN := 1.0
const CUT_HOLD := 0.15
const SEP_T := 7.7
const DEPLOY_T := 8.0
const DEPLOY_END := 9.0
const COCKPIT_IN_T := 8.2
const CONTROL_T := 11.0
const CONTROL_END := 19.6
const ARRIVE_T := 21.6
const FADE_OUT_T := 22.6
const STAGE2_T := 8.5
const EARTH_BELOW_POS := Vector3(0, -66.0, -30.0)   # Earth-orbit mission: big planet under the ship
const EARTH_BELOW_SCALE := 60.0
const RUMBLE_FILE := "res://audio/jerryblessed-space-rocket-launch-rumble-544846.wav"
const STARS_MAP := "res://art/planets/2k_stars.jpg"
const ASTEROID_MODELS := [
	preload("res://art/models/asteroids/rock_A.gltf"),
	preload("res://art/models/asteroids/rock_B.gltf"),
	preload("res://art/models/asteroids/rocks_A.gltf"),
	preload("res://art/models/asteroids/rocks_B.gltf"),
]

var design: Dictionary
var mission: Dictionary
var mid := "mars"
var _has_solar := false

var _t := 0.0
var _done := false
var _launched := false
var _space := false
var _last_count := 3
var _arrive_sfx := false
var _sep_fx_done := false
var _deploy_blip := false
var _s1_free := false
var _s2_free := false
var _s1_base: Vector3
var _s2_base: Vector3
var _rumble: AudioStreamPlayer
var _sep_puff: CPUParticles3D
var _sep_flash: OmniLight3D

var _pad_root: Node3D
var _space_root: Node3D
var _rocket: Node3D
var _flame: MeshInstance3D
var _flame_inner: MeshInstance3D
var _glow: OmniLight3D
var _smoke: CPUParticles3D
var _smoke_left: CPUParticles3D
var _smoke_right: CPUParticles3D
var _trail_smoke: CPUParticles3D
var _pad_cam: Camera3D
var _space_cam: Camera3D

var _ship: Node3D
var _craft: Node3D
var _stage1: Node3D
var _stage2: Node3D
var _dest: Node3D
var _env: Environment

var _mission_card: PanelContainer
var _phase_track: PanelContainer

var _frame_layer: CanvasLayer
var _frame_root: Control
var _cockpit_layer: CanvasLayer
var _cockpit_root: Control
var _co_dist: Label
var _co_msg: Label
var _co_auto: Label
var _co_hull: Array[Panel] = []
var _hit_flash: ColorRect
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect

var _asteroid_root: Node3D
var _asteroids: Array[Dictionary] = []
var _asteroid_timer := 0.0
var _ship_vel := Vector2.ZERO
var _mouse_steer := Vector2.ZERO
var _hull := 3
var _lost := false            # hull reached 0: spacecraft destroyed, flight stops
var _ui_root: Control
var _shake := 0.0
var _cockpit_on := false
var _autopilot := false
var _cockpit_vis := 0.0
var _letterbox_vis := 0.0
var _hud_swapped := false
var _engine_glow: OmniLight3D
var _engine_cone: MeshInstance3D

var _big: Label
var _sub: Label
var _skip: Button
var _fade: ColorRect
var _phase := -1
var _phase_dots: Array[Panel] = []
var _phase_labels: Array[Label] = []

const PHASES := ["COUNTDOWN", "LIFTOFF", "SEPARATION", "FLIGHT", "ARRIVAL"]


func _ready() -> void:
	design = MissionState.design
	if design.is_empty() or str(design.get("bus", "")) == "":
		design = Sim.make_test_design("mars")
		MissionState.design = design
		MissionState.current_mission_id = "mars"
	mid = str(design.get("mission_id", MissionState.current_mission_id))
	if mid == "":
		mid = "mars"
	mission = GameData.get_mission(mid)
	for p in design.get("power", []):
		if str(GameData.get_item("power", p).get("kind", "")) == "solar":
			_has_solar = true
	_build_world()
	_build_pad()
	_build_space()
	_build_ui()
	_build_rumble()
	MissionState.set_meta("launch_hits", 0)
	Sfx.play("beep", -8.0)


func _process(delta: float) -> void:
	if _lost:
		if _hit_flash:
			_hit_flash.modulate.a = maxf(0.0, _hit_flash.modulate.a - delta * 1.2)
		return
	if _done:
		return
	_t += delta
	if _t < LIFTOFF_T:
		_update_countdown()
	elif not _launched:
		_launch()
	if _t < CUT_T:
		_update_pad()
	else:
		if not _space:
			_enter_space()
		_update_space(delta)
	_update_fade()
	_update_timeline()
	if _t >= TOTAL:
		_finish()


func _update_countdown() -> void:
	var n := int(ceil(LIFTOFF_T - _t))
	_big.text = "T-%d" % maxi(n, 0)
	_sub.text = "COUNTDOWN NOMINAL  ·  ALL STATIONS GO"
	if n != _last_count:
		_last_count = n
		if n > 0:
			Sfx.play("beep", -8.0)


func _launch() -> void:
	_launched = true
	_big.text = "LIFTOFF!"
	_sub.text = "ASCENT  ·  STAGE 1 NOMINAL"
	_flame.visible = true
	_flame_inner.visible = true
	_glow.light_energy = 6.0
	_smoke.emitting = true
	if _smoke_left:
		_smoke_left.emitting = true
	if _smoke_right:
		_smoke_right.emitting = true
	if _trail_smoke:
		_trail_smoke.emitting = true
	Sfx.play("whoosh", -2.0)
	Sfx.play("go", -6.0)
	if _rumble:
		_rumble.play()


func _update_pad() -> void:
	var ft := maxf(_t - LIFTOFF_T, 0.0)
	_rocket.position.y = 1.3 + 0.5 * 9.0 * ft * ft
	_flame.scale = Vector3.ONE * (1.0 + sin(_t * 40.0) * 0.08)
	_flame_inner.scale = Vector3.ONE * (1.0 + sin(_t * 47.0) * 0.10)
	var shake := Vector3(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12), 0.0) * clampf(1.6 - ft, 0.0, 1.0)
	_pad_cam.position = Vector3(28, 7 + _rocket.position.y * 0.55, 40) + shake
	_pad_cam.look_at(_rocket.position + Vector3(0, 10, 0), Vector3.UP)
	if ft > 1.4:
		_big.text = ""
		_sub.text = "ASCENT  ·  STAGE 1 NOMINAL"
	if ft > 2.6:
		_sub.text = "MAX Q  ·  STAGE 1 NOMINAL"
	if ft > 3.6:
		_sub.text = "STAGE SEPARATION ARMED"


func _enter_space() -> void:
	_space = true
	_pad_root.visible = false
	_space_root.visible = true
	_space_cam.current = true
	if _env:
		_env.fog_enabled = false
		_env.ambient_light_energy = 0.22
		_env.ambient_light_color = Color(0.5, 0.5, 0.52)   # neutral, so the Moon stays grey (not Earth-blue)
	MissionState.set_meta("launch_hits", 0)
	_ship.position = Vector3.ZERO
	_ship_vel = Vector2.ZERO
	_mouse_steer = Vector2.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hull = 3
	_shake = 0.0
	_cockpit_on = false
	_autopilot = false
	_cockpit_vis = 0.0
	_letterbox_vis = 0.0
	_hud_swapped = false
	_arrive_sfx = false
	_clear_asteroids()
	_asteroid_timer = 0.0
	_space_cam.fov = 55.0
	if _dest:
		_dest.scale = Vector3.ONE * (EARTH_BELOW_SCALE if mid == "earth" else 2.6)
	if _engine_glow:
		_engine_glow.light_energy = 0.0
	if _engine_cone:
		_engine_cone.visible = false
	if _mission_card:
		_mission_card.visible = true
	if _phase_track:
		_phase_track.visible = true
	_sub.visible = true
	_big.visible = true
	_big.text = ""
	_sub.text = "STAGE SEPARATION"
	if _co_msg:
		_co_msg.text = "STANDBY"
		_co_msg.add_theme_color_override("font_color", NeonUI.GREEN)
	if _hit_flash:
		_hit_flash.modulate.a = 0.0
	_apply_cockpit_vis()
	_apply_letterbox()
	_fade.color = Color.BLACK
	_fade.modulate.a = 1.0
	if _rumble:
		_rumble.stop()


func _update_space(delta: float) -> void:
	# --- booster: released into world space at SEP_T. It keeps its own inertia
	# (decaying push-off, then constant drift + tumble) while the spacecraft
	# accelerates away, so it leaves the frame on its own — never popped out.
	var sep := maxf(_t - SEP_T, 0.0)
	if sep > 0.0 and not _s1_free:
		_s1_free = true
		_s1_base = _stage1.global_position
		_ship.remove_child(_stage1)
		_space_root.add_child(_stage1)
		_stage1.global_position = _s1_base
		_sep_puff.restart()
		_sep_puff.emitting = true
		_sep_flash.light_energy = 3.0
		Sfx.play("snap", -5.0)
	if _s1_free:
		var d1 := _sep_motion(sep, 1.0, 3.0, 0.30) * Vector3(-0.68, -0.34, 0.28)
		_stage1.position = _s1_base + d1
		_stage1.rotation = Vector3(0.45, 0.10, 0.85) * sep
		_sep_flash.light_energy = maxf(_sep_flash.light_energy - delta * 9.0, 0.0)

	# --- upper stage: same treatment once the wings are open.
	var s2 := maxf(_t - STAGE2_T, 0.0)
	if s2 > 0.0 and not _s2_free:
		_s2_free = true
		_s2_base = _stage2.global_position
		_ship.remove_child(_stage2)
		_space_root.add_child(_stage2)
		_stage2.global_position = _s2_base
	if _s2_free:
		var d2 := _sep_motion(s2, 1.6, 1.5, 0.35) * Vector3(-0.40, -0.30, 0.86)
		_stage2.position = _s2_base + d2
		_stage2.rotation = Vector3(0.35, 0.12, 0.60) * s2

	var deploy := clampf((_t - DEPLOY_T) / (DEPLOY_END - DEPLOY_T), 0.0, 1.0)
	SpacecraftModel3D.deploy_wings(_craft, deploy)
	if deploy >= 1.0 and not _deploy_blip:
		_deploy_blip = true
		Sfx.play("fixed", -8.0)

	var flight := clampf((_t - CONTROL_T) / (CONTROL_END - CONTROL_T), 0.0, 1.0)
	var cine := clampf((_t - CONTROL_END) / (ARRIVE_T - CONTROL_END), 0.0, 1.0)
	if _t >= COCKPIT_IN_T and not _hud_swapped:
		_hud_swapped = true
		if _mission_card:
			_mission_card.visible = false
		if _phase_track:
			_phase_track.visible = false
		_sub.visible = false
		_big.visible = false
	if _dest and mid == "earth":
		# Earth-orbit mission: we launched FROM Earth, so it stays below us as a curved horizon
		# that slowly drops away while we climb to orbit (never a planet ahead to fly to).
		_dest.scale = Vector3.ONE * EARTH_BELOW_SCALE
		_dest.position = EARTH_BELOW_POS + Vector3(0, -2.0 * flight - 2.0 * cine, 0)
		if _dest.has_method("spin_by"):
			_dest.spin_by(delta * 0.01)
	elif _dest:
		var ds := 2.6
		if _t >= CONTROL_T and _t < CONTROL_END:
			ds = lerpf(2.6, 5.6, flight)
		elif _t >= CONTROL_END:
			ds = lerpf(5.6, 9.0, cine)
		_dest.scale = Vector3.ONE * ds
		if _dest.has_method("spin_by"):
			_dest.spin_by(delta * 0.02)
		else:
			_dest.rotate_y(delta * 0.02)

	if _hit_flash:
		_hit_flash.modulate.a = maxf(0.0, _hit_flash.modulate.a - delta * 1.6)

	if _t < COCKPIT_IN_T:
		# --- chase the upper stage through separation + wing deploy
		_cockpit_vis = 0.0
		_space_cam.fov = 55.0
		_space_cam.position = Vector3(6.0 + sin(_t * 0.25) * 0.6, 3.5, 16.0)
		_space_cam.look_at(Vector3(0, 0, -2.0), Vector3.UP)
	elif _t < CONTROL_T:
		# --- curved dolly around the nose into the cockpit
		var k := smoothstep(0.0, 1.0, (_t - COCKPIT_IN_T) / (CONTROL_T - COCKPIT_IN_T))
		_cockpit_vis = clampf((k - 0.55) / 0.40, 0.0, 1.0)
		var p0 := Vector3(6.0, 3.5, 16.0)
		var p1 := Vector3(7.0, 3.2, -7.0)
		var p2 := Vector3(3.0, 1.2, -7.0)
		var p3 := _ship.position + Vector3(0.0, 0.55, -2.8)
		_space_cam.position = _bezier3(p0, p1, p2, p3, k)
		_space_cam.look_at(Vector3(0, 0, -2.0).lerp(_ship.position + Vector3(0, 0.55, -25.0), k), Vector3.UP)
		_space_cam.fov = lerpf(55.0, 70.0, k)
	elif _t < CONTROL_END:
		if not _cockpit_on:
			_cockpit_on = true
			_mouse_steer = Vector2.ZERO
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if _mission_card:
				_mission_card.visible = false
			if _phase_track:
				_phase_track.visible = false
			_sub.visible = false
			_big.visible = false
			if _co_msg:
				_co_msg.text = "MANUAL CONTROL"
				_co_msg.add_theme_color_override("font_color", NeonUI.GREEN)
			Sfx.play("go", -8.0)
		_cockpit_vis = 1.0

		# --- player steering: captured mouse (self-centering) + keyboard
		_mouse_steer = _mouse_steer.lerp(Vector2.ZERO, 1.0 - exp(-delta * 2.6))
		var ix := _mouse_steer.x
		var iy := _mouse_steer.y
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			ix -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			ix += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			iy += 1.0      # W / up = climb
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			iy -= 1.0      # S / down = dive
		# fast, snappy response so a key press clearly moves the ship
		_ship_vel = _ship_vel.lerp(Vector2(clampf(ix, -1.0, 1.0), clampf(iy, -1.0, 1.0)) * Vector2(7.5, 5.0), 1.0 - exp(-delta * 10.0))
		_ship.position.x = clampf(_ship.position.x + _ship_vel.x * delta, -4.6, 4.6)
		_ship.position.y = clampf(_ship.position.y + _ship_vel.y * delta, -2.8, 2.8)
		_ship.position.z = 0.0

		# --- asteroid field
		_asteroid_timer -= delta
		if _asteroid_timer <= 0.0 and _t < CONTROL_END - 1.2:
			_spawn_asteroid()
			_asteroid_timer = randf_range(0.34, 0.62)
		_update_asteroids(delta)

		_shake = maxf(_shake - delta * 2.4, 0.0)
		var sh := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake
		_space_cam.fov = 70.0
		_space_cam.position = _ship.position + Vector3(0.0, 0.55, -2.8) + sh
		_space_cam.look_at(_ship.position + Vector3(0.0, 0.55, -25.0), Vector3.UP)
		# bank and nose into the turn so movement is easy to feel
		_space_cam.rotate_object_local(Vector3(0, 1, 0), -_ship_vel.x * 0.012)
		_space_cam.rotate_object_local(Vector3(1, 0, 0), _ship_vel.y * 0.012)
		_space_cam.rotate_object_local(Vector3(0, 0, 1), -_ship_vel.x * 0.035)
		_update_cockpit_hud()
	else:
		if not _autopilot:
			_autopilot = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_clear_asteroids()
			_letterbox_vis = 0.0
			_big.visible = true
			_sub.visible = true
			_big.add_theme_font_size_override("font_size", 52)
			_big.text = "AUTOPILOT ENGAGED"
			_sub.text = "ORBIT INSERTION  ·  %s" % str(mission.get("destination", "")).to_upper()
			if _engine_glow:
				_engine_glow.light_energy = 3.5
			if _engine_cone:
				_engine_cone.visible = true
			Sfx.play("fixed", -6.0)
		_cockpit_vis = move_toward(_cockpit_vis, 0.0, delta * 3.0)
		_letterbox_vis = move_toward(_letterbox_vis, 1.0, delta * 1.6)
		_ship.position.z = move_toward(_ship.position.z, -24.0, delta * 3.2)
		_ship.position.x = move_toward(_ship.position.x, 0.0, delta * 1.4)
		_ship.position.y = move_toward(_ship.position.y, 0.0, delta * 1.2)
		_space_cam.fov = 50.0
		_space_cam.position = _ship.position + Vector3(8.0, 3.6, 14.0)
		_space_cam.look_at(_ship.position + Vector3(0, 0, -8.0), Vector3.UP)
		if _t >= ARRIVE_T:
			_big.text = "ARRIVED AT %s" % str(mission.get("destination", "")).to_upper()
			_sub.text = "MISSION CONTROL HANDOFF"
			if not _arrive_sfx:
				_arrive_sfx = true
				Sfx.play("complete", -4.0)

	_apply_cockpit_vis()
	_apply_letterbox()


func _rock_color() -> Color:
	if randf() < 0.18:
		return Color(0.36, 0.44, 0.52)   # icy
	var g := randf_range(0.18, 0.34)
	return Color(g * randf_range(0.95, 1.08), g * randf_range(0.92, 1.0), g * randf_range(0.82, 0.95))


func _paint_rock(root: Node, col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0
	mat.metallic = 0.0
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh:
			mi.material_override = mat


func _rock_aabb(root: Node) -> AABB:
	var out := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var box := mi.transform * mi.get_aabb()
		if first:
			out = box
			first = false
		else:
			out = out.merge(box)
	return out


func _make_rock(radius: float) -> Node3D:
	var wrap := Node3D.new()
	var scene: PackedScene = ASTEROID_MODELS[randi() % ASTEROID_MODELS.size()]
	var model := scene.instantiate() as Node3D
	wrap.add_child(model)
	var box := _rock_aabb(model)
	var size := box.size
	var base := maxf(size.x, maxf(size.y, size.z)) * 0.5
	model.position = -box.get_center()
	var s := radius / maxf(base, 0.001)
	wrap.scale = Vector3(s, s * randf_range(1.0, 1.35), s)
	_paint_rock(wrap, _rock_color())
	return wrap


func _spawn_asteroid() -> void:
	if _asteroid_root == null:
		return
	var node := Node3D.new()
	node.name = "Asteroid"
	var r := randf_range(0.55, 1.15)
	node.add_child(_make_rock(r))

	# --- companion fragments: broken-off chunks that travel with the rock
	if randf() < 0.55:
		for i in randi_range(1, 2):
			var frag := _make_rock(r * randf_range(0.28, 0.48))
			frag.position = Vector3(randf_range(-1.2, 1.2), randf_range(-0.9, 0.9), randf_range(-1.2, 1.2))
			node.add_child(frag)

	node.position = Vector3(randf_range(-5.8, 5.8), randf_range(-3.6, 3.6), -randf_range(48.0, 68.0))
	node.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
	_asteroid_root.add_child(node)
	_asteroids.append({
		"node": node,
		"speed": randf_range(12.0, 20.0),
		"radius": r,
		"spin": Vector3(randf_range(-0.9, 0.9), randf_range(-0.9, 0.9), randf_range(-0.9, 0.9)),
	})


func _update_asteroids(delta: float) -> void:
	for i in range(_asteroids.size() - 1, -1, -1):
		var a: Dictionary = _asteroids[i]
		var node := a["node"] as Node3D
		if not is_instance_valid(node):
			_asteroids.remove_at(i)
			continue
		node.position.z += float(a["speed"]) * delta
		var spin: Vector3 = a["spin"]
		node.rotate_x(spin.x * delta)
		node.rotate_y(spin.y * delta)
		node.rotate_z(spin.z * delta)
		if node.position.z > _ship.position.z + 8.0:
			node.queue_free()
			_asteroids.remove_at(i)
			continue
		var d := node.position - _ship.position
		var r := float(a["radius"])
		if absf(d.z) < 1.1 + r and Vector2(d.x, d.y).length() < 0.9 + r:
			node.queue_free()
			_asteroids.remove_at(i)
			_handle_hit()
			if _lost:
				return


func _handle_hit() -> void:
	if _lost:
		return
	_hull = maxi(_hull - 1, 0)
	MissionState.set_meta("launch_hits", 3 - _hull)
	if _hull <= 0:
		_lose()
		return
	_shake = 0.55
	if _hit_flash:
		_hit_flash.modulate.a = 0.55
	Sfx.play("explode", -2.0, randf_range(0.85, 1.1))
	Sfx.play("alarm", -10.0)
	if _co_msg:
		_co_msg.text = ("IMPACT  ·  HULL %d/3  ·  -15%% HEALTH" % _hull) if _hull > 0 else "HULL CRITICAL"
		_co_msg.add_theme_color_override("font_color", NeonUI.GOLD if _hull > 0 else NeonUI.RED)


func _clear_asteroids() -> void:
	for a in _asteroids:
		var n := a["node"] as Node3D
		if is_instance_valid(n):
			n.queue_free()
	_asteroids.clear()


func _update_cockpit_hud() -> void:
	if _co_dist == null:
		return
	var p := clampf((_t - CONTROL_T) / (CONTROL_END - CONTROL_T), 0.0, 1.0)
	if mid == "earth":
		_co_dist.text = "CLIMBING TO ORBIT  ·  ALT %03d KM" % int(round(lerpf(180.0, 500.0, p)))
	else:
		_co_dist.text = "TO %s  ·  %05d KM" % [mid.to_upper(), int(round(lerpf(12000.0, 0.0, p)))]
	_co_auto.text = "AUTOPILOT IN  %0.1fs" % maxf(0.0, CONTROL_END - _t)
	for i in range(_co_hull.size()):
		_co_hull[i].modulate = Color(1, 1, 1, 1) if i < _hull else Color(1, 1, 1, 0.12)
	if _hull <= 0 and _co_msg:
		_co_msg.text = "HULL CRITICAL"
		_co_msg.add_theme_color_override("font_color", NeonUI.RED)


func _bezier3(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return p0 * (u * u * u) + p1 * (3.0 * u * u * t) + p2 * (3.0 * u * t * t) + p3 * (t * t * t)


func _apply_cockpit_vis() -> void:
	var on := _cockpit_vis > 0.01
	if _frame_root:
		_frame_root.visible = on
		_frame_root.modulate.a = _cockpit_vis
	if _cockpit_root:
		_cockpit_root.visible = on
		_cockpit_root.modulate.a = _cockpit_vis


func _apply_letterbox() -> void:
	var on := _letterbox_vis > 0.01
	if _letterbox_top:
		_letterbox_top.visible = on
		_letterbox_top.offset_bottom = 56.0 * _letterbox_vis
	if _letterbox_bottom:
		_letterbox_bottom.visible = on
		_letterbox_bottom.offset_top = -56.0 * _letterbox_vis


func _update_fade() -> void:
	var a := 0.0
	if not _space:
		# --- pad: ease down to black just before the cut to space
		a = smoothstep(0.0, 1.0, clampf((_t - (CUT_T - CUT_FADE_OUT)) / CUT_FADE_OUT, 0.0, 1.0))
	else:
		# --- space: hold black for a beat, then ease in; hold clear until the ending
		a = 1.0 - smoothstep(0.0, 1.0, clampf((_t - (CUT_T + CUT_HOLD)) / CUT_FADE_IN, 0.0, 1.0))
		if _t > FADE_OUT_T:
			_fade.color = Color.BLACK
			a = smoothstep(0.0, 1.0, clampf((_t - FADE_OUT_T) / 1.0, 0.0, 1.0))
	_fade.modulate.a = a


## Near Earth the danger is old satellites and rocket parts (space debris), farther out it's asteroids.
func _rock_word() -> String:
	return "space debris" if mid == "earth" else "asteroid"


## Third asteroid hit: the spacecraft is destroyed. The flight stops and the player retries.
func _lose() -> void:
	_lost = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_asteroids()
	if _craft:
		_craft.visible = false
	if _hit_flash:
		_hit_flash.modulate.a = 0.9
	if _rumble:
		_rumble.stop()
	Sfx.play("explode", 0.0, 0.7)
	Sfx.play("fail", -2.0)
	_cockpit_vis = 0.0
	_apply_cockpit_vis()
	_skip.visible = false
	_big.visible = true
	_sub.visible = true
	_big.add_theme_font_size_override("font_size", 56)
	_big.add_theme_color_override("font_color", NeonUI.RED)
	_big.text = "SPACECRAFT LOST"
	_sub.text = "Three %s impacts broke the hull before it reached %s.\nThe mission is over. Fly more carefully and try again." % [_rock_word(), str(mission.get("destination", "the target"))]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -300
	row.offset_right = 300
	row.offset_top = -190
	row.offset_bottom = -130
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_ui_root.add_child(row)
	var retry := Button.new()
	retry.text = "RETRY LAUNCH"
	retry.custom_minimum_size = Vector2(260, 56)
	NeonUI.primary(retry, 20)
	retry.pressed.connect(func(): MissionState.go_to("launch_anim"))
	row.add_child(retry)
	var back := Button.new()
	back.text = "BACK TO HANGAR"
	back.custom_minimum_size = Vector2(260, 56)
	NeonUI.ghost(back, 18)
	back.pressed.connect(func(): MissionState.go_to("hangar"))
	row.add_child(back)


func _finish() -> void:
	if _done or _lost:
		return
	_done = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MissionState.go_to("mission_control")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_finish()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if _cockpit_on and event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_mouse_steer.x = clampf(_mouse_steer.x + mm.relative.x * 0.0065, -1.0, 1.0)
		# mouse down = ship down (screen-space, not flight-stick pitch)
		_mouse_steer.y = clampf(_mouse_steer.y - mm.relative.y * 0.0065, -1.0, 1.0)


# ===================================================================== world

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var tex: Texture2D = null
	if ResourceLoader.exists(STARS_MAP):
		tex = load(STARS_MAP) as Texture2D
	if tex != null:
		var sky := Sky.new()
		var sm := PanoramaSkyMaterial.new()
		sm.panorama = tex
		sky.sky_material = sm
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.background_energy_multiplier = 0.9
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.015, 0.025, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.26, 0.33, 0.43)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.09, 0.14)
	env.fog_density = 0.011
	we.environment = env
	_env = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-32, 140, 0)
	moon.light_color = Color(0.60, 0.70, 1.0)
	moon.light_energy = 0.9
	moon.shadow_enabled = true
	add_child(moon)


func _build_pad() -> void:
	_pad_root = Node3D.new()
	_pad_root.name = "Pad"
	add_child(_pad_root)

	var ground := _box(Vector3(400, 0.2, 400), Color(0.10, 0.19, 0.11), 0.0, 1.0)
	var gm := ground.mesh.material as StandardMaterial3D
	gm.emission_enabled = true
	gm.emission = Color(0.015, 0.04, 0.015)
	_pad_root.add_child(_at(ground, Vector3(0, -0.1, 0)))
	var lawn := _box(Vector3(70, 0.08, 70), Color(0.11, 0.20, 0.11), 0.0, 1.0)
	var lm := lawn.mesh.material as StandardMaterial3D
	lm.emission_enabled = true
	lm.emission = Color(0.018, 0.045, 0.018)
	_pad_root.add_child(_at(lawn, Vector3(0, 0.04, 0)))
	_pad_root.add_child(_at(_box(Vector3(20, 1.0, 20), Color(0.36, 0.37, 0.41), 0.2, 0.8), Vector3(0, 0.5, 0)))
	_pad_root.add_child(_at(_box(Vector3(6, 0.3, 6), Color(0.18, 0.18, 0.2), 0.5, 0.6), Vector3(0, 1.15, 0)))
	_build_pad_surroundings()

	var pad_fill := OmniLight3D.new()
	pad_fill.position = Vector3(0, 6, 2)
	pad_fill.omni_range = 55
	pad_fill.light_energy = 1.8
	pad_fill.light_color = Color(1.0, 0.78, 0.55)
	_pad_root.add_child(pad_fill)
	var cool_fill := OmniLight3D.new()
	cool_fill.position = Vector3(12, 10, 14)
	cool_fill.omni_range = 38
	cool_fill.light_energy = 0.9
	cool_fill.light_color = Color(0.60, 0.70, 1.0)
	_pad_root.add_child(cool_fill)

	# Bright night-sky stars, independent of the panorama so the pad always reads as night.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1969
	for i in 90:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.04, 1.0), rng.randf_range(-1, 1)).normalized()
		var star := _star(rng.randf_range(0.15, 0.42), Color(0.88, 0.94, 1.0))
		star.position = dir * 150.0
		_pad_root.add_child(star)

	var red := Color(0.65, 0.16, 0.10)
	_pad_root.add_child(_at(_box(Vector3(2.2, 40, 2.2), red, 0.4, 0.6), Vector3(-8.5, 20, 0)))
	for y in range(4, 40, 5):
		_pad_root.add_child(_at(_box(Vector3(5.0, 0.35, 0.5), red, 0.4, 0.6), Vector3(-5.7, y, 0)))
	var beacon := _star(0.45, Color(1.0, 0.18, 0.12))
	beacon.position = Vector3(-8.5, 40.6, 0)
	_pad_root.add_child(beacon)

	for p in [Vector3(15, 3, 15), Vector3(-15, 3, 13), Vector3(13, 3, -15)]:
		var l := SpotLight3D.new()
		l.position = p
		l.look_at_from_position(p, Vector3(0, 14, 0), Vector3.UP)
		l.spot_range = 70
		l.spot_angle = 24
		l.light_energy = 6.0
		l.light_color = Color(1.0, 0.95, 0.85)
		_pad_root.add_child(l)
		_pad_root.add_child(_at(_box(Vector3(0.2, 3, 0.2), Color(0.14, 0.15, 0.17), 0.3, 0.7), Vector3(p.x, 1.5, p.z)))
		_pad_root.add_child(_at(_box(Vector3(1.0, 0.2, 1.0), Color(0.2, 0.2, 0.22), 0.2, 0.8), Vector3(p.x, 0.1, p.z)))
		_pad_root.add_child(_at(_box(Vector3(1.2, 1.2, 1.2), Color(1, 1, 0.9), 0.0, 0.3), p))

	var lv := str(design.get("launch_vehicle", ""))
	if lv == "":
		lv = "medium"
	_rocket = SpacecraftModel3D.build_rocket(lv)
	_rocket.scale = Vector3.ONE * 2.2
	_rocket.position = Vector3(0, 1.3, 0)
	_pad_root.add_child(_rocket)

	_flame = _flame_cone(1.2, 0.05, 6.0, Color(1.0, 0.55, 0.10))
	_flame.position = Vector3(0, -3.0, 0)
	_flame.visible = false
	_rocket.add_child(_flame)
	_flame_inner = _flame_cone(0.55, 0.02, 4.2, Color(1.0, 0.95, 0.60))
	_flame_inner.position = Vector3(0, -2.1, 0)
	_flame_inner.visible = false
	_rocket.add_child(_flame_inner)

	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = Color(1.0, 0.55, 0.15)
	_glow.omni_range = 30
	_glow.light_energy = 0.0
	_rocket.add_child(_glow)

	_smoke = CPUParticles3D.new()
	_smoke.name = "Smoke"
	_smoke.amount = 180
	_smoke.lifetime = 3.5
	_smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_smoke.emission_sphere_radius = 3.0
	_smoke.direction = Vector3(0, 1, 0)
	_smoke.spread = 70.0
	_smoke.initial_velocity_min = 1.0
	_smoke.initial_velocity_max = 3.0
	_smoke.gravity = Vector3(0, 0.6, 0)
	_smoke.scale_amount_min = 1.2
	_smoke.scale_amount_max = 3.2
	_smoke.mesh = _smoke_mesh()
	_smoke.position = Vector3(0, 1.3, 0)
	_smoke.emitting = false
	_pad_root.add_child(_smoke)

	# --- ground billows pushed out to either side of the pad
	_smoke_left = _smoke_particles(150, 4.6, Vector3(-1.0, 0.25, 0.35), 36.0,
		4.0, 8.5, 2.0, 4.8, Vector3(0, 1.3, 0))
	_smoke_left.name = "SmokeLeft"
	_smoke_left.position = Vector3(-4.2, 1.6, 1.2)
	_pad_root.add_child(_smoke_left)

	_smoke_right = _smoke_particles(150, 4.6, Vector3(1.0, 0.25, 0.35), 36.0,
		4.0, 8.5, 2.0, 4.8, Vector3(0, 1.3, 0))
	_smoke_right.name = "SmokeRight"
	_smoke_right.position = Vector3(4.2, 1.6, 1.2)
	_pad_root.add_child(_smoke_right)

	# --- exhaust trail left behind in world space as the rocket climbs
	_trail_smoke = _smoke_particles(190, 3.0, Vector3(0, -1, 0), 16.0,
		6.0, 10.0, 1.2, 2.8, Vector3(0, 0.15, 0))
	_trail_smoke.name = "TrailSmoke"
	_trail_smoke.local_coords = false
	_trail_smoke.position = Vector3(0, -3.2, 0)
	_rocket.add_child(_trail_smoke)

	_pad_cam = Camera3D.new()
	_pad_cam.fov = 52
	_pad_cam.position = Vector3(28, 7, 40)
	_pad_cam.current = true
	_pad_root.add_child(_pad_cam)
	_pad_cam.look_at(Vector3(0, 16, 0), Vector3.UP)


func _build_pad_surroundings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1969
	var concrete := Color(0.44, 0.45, 0.42)
	var dark_concrete := Color(0.30, 0.31, 0.29)

	# Light hardstand around the launch mount.
	_pad_root.add_child(_at(_box(Vector3(40, 0.05, 40), concrete, 0.0, 0.8), Vector3(0, 0.06, 0)))

	# Crawlerway: the wide diagonal concrete strip from the pad to the horizon.
	var way := _box(Vector3(14, 0.06, 130), dark_concrete, 0.0, 0.9)
	way.position = Vector3(-42, 0.035, -40)
	way.rotation.y = deg_to_rad(30)
	_pad_root.add_child(way)
	var across := Vector3(cos(way.rotation.y), 0, -sin(way.rotation.y))
	for side in [-1.0, 1.0]:
		var rail := _box(Vector3(0.9, 0.08, 130), Color(0.16, 0.17, 0.16), 0.1, 0.7)
		rail.position = way.position + across * (side * 4.6) + Vector3(0, 0.02, 0)
		rail.rotation.y = way.rotation.y
		_pad_root.add_child(rail)

	# Perimeter service roads.
	_pad_root.add_child(_at(_box(Vector3(120, 0.04, 3.5), dark_concrete, 0.0, 0.9), Vector3(0, 0.03, 47)))
	_pad_root.add_child(_at(_box(Vector3(120, 0.04, 3.5), dark_concrete, 0.0, 0.9), Vector3(0, 0.03, -47)))
	_pad_root.add_child(_at(_box(Vector3(3.5, 0.04, 94), dark_concrete, 0.0, 0.9), Vector3(-47, 0.03, 0)))
	_pad_root.add_child(_at(_box(Vector3(3.5, 0.04, 94), dark_concrete, 0.0, 0.9), Vector3(47, 0.03, 0)))

	# Scorched flame trench and its concrete lip.
	_pad_root.add_child(_at(_box(Vector3(18, 0.10, 9), Color(0.07, 0.07, 0.06), 0.0, 1.0), Vector3(17, 0.06, 0)))
	_pad_root.add_child(_at(_box(Vector3(1.2, 0.8, 10), concrete, 0.0, 0.8), Vector3(7.6, 0.4, 0)))

	# A river/water band in the distance, then a grass bank in front of it.
	var water := _box(Vector3(190, 0.04, 30), Color(0.02, 0.06, 0.10), 0.45, 0.25)
	water.position = Vector3(-35, 0.02, -88)
	var wm := water.mesh.material as StandardMaterial3D
	wm.emission_enabled = true
	wm.emission = Color(0.015, 0.045, 0.08)
	_pad_root.add_child(water)
	_pad_root.add_child(_at(_box(Vector3(200, 0.10, 8), Color(0.06, 0.12, 0.07), 0.0, 1.0), Vector3(-35, 0.04, -70)))

	# Irregular grass patches to break up the flat ground plane.
	for i in 12:
		var px := rng.randf_range(-150.0, 150.0)
		var pz := rng.randf_range(-120.0, 120.0)
		if absf(px) < 62.0 and absf(pz) < 62.0:
			continue
		var g := rng.randf_range(0.055, 0.10)
		var patch := _box(Vector3(rng.randf_range(26.0, 70.0), 0.02, rng.randf_range(22.0, 55.0)),
			Color(g * 0.6, g * 1.5, g * 0.8), 0.0, 1.0)
		patch.position = Vector3(px, 0.012, pz)
		_pad_root.add_child(patch)

	# Distant treeline. Fog takes over before the ring ends.
	for i in 52:
		var a := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(66.0, 150.0)
		var pos := Vector3(cos(a) * d, 0.0, sin(a) * d - 12.0)
		if absf(pos.x) < 58.0 and absf(pos.z) < 58.0:
			continue
		_pad_tree(pos, rng.randf_range(0.8, 1.7))

	# Low buildings and the pad water tower.
	_pad_building(Vector3(-58, 0, 8), Vector3(12, 5, 9), Color(0.34, 0.35, 0.36))
	_pad_building(Vector3(-72, 0, -18), Vector3(16, 6, 12), Color(0.30, 0.31, 0.33))
	_pad_building(Vector3(54, 0, -62), Vector3(20, 8, 16), Color(0.28, 0.29, 0.30))
	_pad_water_tower(Vector3(-28, 0, 24))

	# Lightning-protection masts with red beacons.
	for p in [Vector3(32, 0, 32), Vector3(-34, 0, 30), Vector3(30, 0, -30)]:
		_pad_root.add_child(_at(_box(Vector3(0.5, 34, 0.5), Color(0.17, 0.18, 0.18), 0.5, 0.5), p + Vector3(0, 17, 0)))
		var beacon := _star(0.28, Color(1.0, 0.15, 0.08))
		beacon.position = p + Vector3(0, 34.4, 0)
		_pad_root.add_child(beacon)

	# Warm perimeter lamps, kept low so the launch lights still own the scene.
	for p in [Vector3(28, 2, 30), Vector3(-28, 2, 28), Vector3(26, 2, -28)]:
		var l := OmniLight3D.new()
		l.position = p
		l.omni_range = 20
		l.light_energy = 0.55
		l.light_color = Color(1.0, 0.78, 0.52)
		_pad_root.add_child(l)


func _pad_tree(pos: Vector3, s: float) -> void:
	var trunk := _box(Vector3(0.35 * s, 2.2 * s, 0.35 * s), Color(0.16, 0.12, 0.08), 0.0, 1.0)
	trunk.position = pos + Vector3(0, 1.1 * s, 0)
	_pad_root.add_child(trunk)
	var canopy := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.7 * s
	cone.height = 4.6 * s
	cone.radial_segments = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.13, 0.07)
	mat.roughness = 1.0
	mat.emission_enabled = true
	mat.emission = Color(0.02, 0.045, 0.025)
	cone.material = mat
	canopy.mesh = cone
	canopy.position = pos + Vector3(0, 3.6 * s, 0)
	_pad_root.add_child(canopy)


func _pad_building(pos: Vector3, size: Vector3, col: Color) -> void:
	var body := _box(size, col, 0.0, 0.85)
	body.position = pos + Vector3(0, size.y * 0.5, 0)
	_pad_root.add_child(body)
	var roof := _box(Vector3(size.x * 1.04, 0.35, size.z * 1.04), col.darkened(0.22), 0.0, 0.8)
	roof.position = pos + Vector3(0, size.y, 0)
	_pad_root.add_child(roof)
	var win := _box(Vector3(size.x * 0.7, 0.5, 0.05), Color(0.7, 0.82, 1.0), 0.0, 0.3)
	win.position = pos + Vector3(0, size.y * 0.55, size.z * 0.5 + 0.03)
	var wmat := win.mesh.material as StandardMaterial3D
	wmat.emission_enabled = true
	wmat.emission = Color(0.35, 0.55, 0.9)
	_pad_root.add_child(win)


func _pad_water_tower(pos: Vector3) -> void:
	_pad_root.add_child(_at(_box(Vector3(7, 0.6, 7), Color(0.32, 0.33, 0.31), 0, 0.9), pos + Vector3(0, 0.3, 0)))
	var column := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.8
	cyl.bottom_radius = 1.2
	cyl.height = 20
	cyl.radial_segments = 8
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.42, 0.44, 0.45)
	cm.metallic = 0.3
	cm.roughness = 0.6
	cyl.material = cm
	column.mesh = cyl
	column.position = pos + Vector3(0, 10, 0)
	_pad_root.add_child(column)
	var tank := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 3.2
	sph.height = 6.4
	sph.radial_segments = 12
	sph.rings = 6
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.5, 0.53, 0.55)
	sm.metallic = 0.3
	sm.roughness = 0.5
	sph.material = sm
	tank.mesh = sph
	tank.position = pos + Vector3(0, 22, 0)
	_pad_root.add_child(tank)
	var beacon := _star(0.35, Color(1.0, 0.15, 0.08))
	beacon.position = pos + Vector3(0, 25.4, 0)
	_pad_root.add_child(beacon)


func _build_space() -> void:
	_space_root = Node3D.new()
	_space_root.name = "Space"
	_space_root.visible = false
	add_child(_space_root)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20, 160, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.6
	sun.shadow_enabled = false
	_space_root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(15, -30, 0)
	fill.light_color = Color(0.80, 0.82, 0.88)
	fill.light_energy = 0.18
	fill.shadow_enabled = false
	_space_root.add_child(fill)

	_ship = Node3D.new()
	_ship.name = "Ship"
	_space_root.add_child(_ship)

	_dest = MenuPlanet.make(mid)
	if _dest:
		_dest.name = "Destination"
		_dest.position = Vector3(0, 0, -60)
		_dest.scale = Vector3.ONE * 2.6
		if mid == "earth":
			_dest.name = "EarthBelow"
			_dest.position = EARTH_BELOW_POS
			_dest.scale = Vector3.ONE * EARTH_BELOW_SCALE
		_space_root.add_child(_dest)

	_asteroid_root = Node3D.new()
	_asteroid_root.name = "Asteroids"
	_space_root.add_child(_asteroid_root)

	_craft = SpacecraftModel3D.build(design)
	_craft.name = "Spacecraft"
	_craft.scale = Vector3.ONE * 2.0
	_craft.rotation = Vector3(0.12, PI, 0.10)
	_ship.add_child(_craft)
	SpacecraftModel3D.deploy_wings(_craft, 0.0)

	# Engine glow for the autopilot cutaway (behind the ship, toward camera).
	_engine_cone = _flame_cone(0.28, 0.04, 2.6, Color(0.35, 0.85, 1.0))
	_engine_cone.rotation.x = PI / 2.0
	_engine_cone.position = Vector3(0, 0, 2.8)
	_engine_cone.visible = false
	_ship.add_child(_engine_cone)
	_engine_glow = OmniLight3D.new()
	_engine_glow.position = Vector3(0, 0, 2.4)
	_engine_glow.light_color = Color(0.35, 0.85, 1.0)
	_engine_glow.omni_range = 6.0
	_engine_glow.light_energy = 0.0
	_ship.add_child(_engine_glow)

	_stage2 = _space_stage(1.35, 1.55, 4.5, Color(0.92, 0.93, 0.96))
	_stage2.position = Vector3(0, 0, 4.6)
	_ship.add_child(_stage2)
	var truss := _cyl(0.35, 0.35, 2.2, Color(0.40, 0.42, 0.48), 0.6, 0.4)
	truss.rotation.x = -PI / 2.0
	truss.position = Vector3(0, 0, -2.4)
	_stage2.add_child(truss)

	_stage1 = _space_stage(1.65, 1.85, 6.0, Color(0.90, 0.91, 0.94))
	_stage1.position = Vector3(0, 0, 10.2)
	_ship.add_child(_stage1)
	var inter := _cyl(1.5, 1.5, 1.2, Color(0.55, 0.57, 0.62), 0.5, 0.5)
	inter.rotation.x = -PI / 2.0
	inter.position = Vector3(0, 0, -2.4)
	_stage1.add_child(inter)
	for k in 4:
		var fin := _box(Vector3(0.15, 2.2, 1.4), Color(0.20, 0.25, 0.40), 0.3, 0.5)
		var a := k * PI / 2.0
		fin.position = Vector3(cos(a) * 1.8, 0, sin(a) * 1.8)
		fin.rotation.y = -a
		_stage1.add_child(fin)

	_sep_puff = CPUParticles3D.new()
	_sep_puff.name = "SepPuff"
	_sep_puff.amount = 16
	_sep_puff.one_shot = true
	_sep_puff.explosiveness = 1.0
	_sep_puff.lifetime = 0.9
	_sep_puff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sep_puff.emission_sphere_radius = 0.6
	_sep_puff.direction = Vector3(0, 0, 1)
	_sep_puff.spread = 60.0
	_sep_puff.initial_velocity_min = 1.0
	_sep_puff.initial_velocity_max = 2.5
	_sep_puff.gravity = Vector3.ZERO
	_sep_puff.scale_amount_min = 0.6
	_sep_puff.scale_amount_max = 1.4
	_sep_puff.mesh = _smoke_mesh()
	_sep_puff.position = Vector3(0, 0, 8.5)
	_sep_puff.emitting = false
	_ship.add_child(_sep_puff)

	_sep_flash = OmniLight3D.new()
	_sep_flash.name = "SepFlash"
	_sep_flash.position = Vector3(0, 0, 8.5)
	_sep_flash.omni_range = 14.0
	_sep_flash.light_color = Color(1.0, 0.85, 0.6)
	_sep_flash.light_energy = 0.0
	_ship.add_child(_sep_flash)

	_space_cam = Camera3D.new()
	_space_cam.fov = 55
	_space_cam.position = Vector3(6, 3.5, 16)
	_space_cam.current = false
	_space_root.add_child(_space_cam)
	_space_cam.look_at(Vector3(0, 0, -2), Vector3.UP)


# ===================================================================== UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_ui_root = root

	# --- mission kicker card, top-left
	var card := NeonUI.glass(16)
	_mission_card = card
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.offset_left = 28
	card.offset_top = 24
	card.offset_right = 428
	card.offset_bottom = 118
	root.add_child(card)
	var kbox := VBoxContainer.new()
	kbox.add_theme_constant_override("separation", 2)
	card.add_child(kbox)
	var kick := NeonUI.kicker("// LAUNCH OPERATIONS")
	kbox.add_child(kick)
	var mname := NeonUI.heading(str(mission.get("name", "")).to_upper(), 24)
	kbox.add_child(mname)
	var dest := NeonUI.body("DESTINATION · " + str(mission.get("destination", "")).to_upper(), 14, NeonUI.CYAN)
	kbox.add_child(dest)

	# --- centre captions, lifted above mid-frame so the vehicle stays readable
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	center.add_child(vbox)

	_big = Label.new()
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	NeonUI.display(_big, 106, NeonUI.GOLD)
	_big.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_big.add_theme_constant_override("outline_size", 14)
	vbox.add_child(_big)

	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	NeonUI.body(_sub, 22, NeonUI.TEXT)
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_sub.add_theme_constant_override("outline_size", 7)
	vbox.add_child(_sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 150)
	vbox.add_child(spacer)

	# --- phase timeline, bottom-centre
	var track := NeonUI.glass(12)
	_phase_track = track
	track.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	track.offset_left = -330
	track.offset_right = 330
	track.offset_top = -96
	track.offset_bottom = -24
	root.add_child(track)
	var phases := HBoxContainer.new()
	phases.alignment = BoxContainer.ALIGNMENT_CENTER
	phases.add_theme_constant_override("separation", 22)
	track.add_child(phases)
	for pname in PHASES:
		var cell := VBoxContainer.new()
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_theme_constant_override("separation", 4)
		phases.add_child(cell)
		var dot := NeonUI.dot(0)
		var dwrap := CenterContainer.new()
		dwrap.add_child(dot)
		cell.add_child(dwrap)
		var pl := Label.new()
		pl.text = pname
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		NeonUI.mono(pl, 10, NeonUI.DIM)
		cell.add_child(pl)
		_phase_dots.append(dot)
		_phase_labels.append(pl)

	_skip = Button.new()
	_skip.text = "SKIP  →"
	NeonUI.ghost(_skip, 18)
	_skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip.offset_left = -178
	_skip.offset_top = -122
	_skip.offset_right = -28
	_skip.offset_bottom = -74
	_skip.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip.pressed.connect(_finish)
	root.add_child(_skip)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)

	_build_cockpit_ui()


func _build_cockpit_ui() -> void:
	# --- cockpit visor frame (below the launch HUD, above the 3D)
	var frame_layer := CanvasLayer.new()
	frame_layer.layer = 4
	add_child(frame_layer)
	_frame_root = Control.new()
	_frame_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.visible = false
	_frame_root.modulate.a = 0.0
	frame_layer.add_child(_frame_root)

	var frame_col := Color(0.01, 0.015, 0.03, 0.94)
	var line_col := Color(0.31, 0.84, 1.0, 0.30)
	var top := ColorRect.new()
	top.color = frame_col
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 52
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.add_child(top)
	var bottom := ColorRect.new()
	bottom.color = frame_col
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -64
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.add_child(bottom)
	var left := ColorRect.new()
	left.color = frame_col
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_right = 46
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.add_child(left)
	var right := ColorRect.new()
	right.color = frame_col
	right.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right.offset_left = -46
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.add_child(right)
	for spec in [[Control.PRESET_TOP_WIDE, 52, -2, 0, 2], [Control.PRESET_BOTTOM_WIDE, -66, -2, 0, 2],
			[Control.PRESET_LEFT_WIDE, 46, 0, 2, 0], [Control.PRESET_RIGHT_WIDE, -48, 0, 2, 0]]:
		var ln := ColorRect.new()
		ln.color = line_col
		ln.set_anchors_preset(spec[0])
		if spec[0] == Control.PRESET_TOP_WIDE:
			ln.offset_top = spec[1]
			ln.offset_bottom = spec[1] + 2
		elif spec[0] == Control.PRESET_BOTTOM_WIDE:
			ln.offset_top = spec[1]
			ln.offset_bottom = spec[1] + 2
		elif spec[0] == Control.PRESET_LEFT_WIDE:
			ln.offset_left = spec[1]
			ln.offset_right = spec[1] + 2
		else:
			ln.offset_left = spec[1]
			ln.offset_right = spec[1] + 2
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame_root.add_child(ln)

	# --- cockpit HUD
	_cockpit_layer = CanvasLayer.new()
	_cockpit_layer.layer = 6
	add_child(_cockpit_layer)
	_cockpit_root = Control.new()
	_cockpit_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cockpit_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cockpit_root.visible = false
	_cockpit_root.modulate.a = 0.0
	_cockpit_layer.add_child(_cockpit_root)

	var card := NeonUI.panel("cyan", 10)
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.offset_left = 28
	card.offset_top = 70
	card.offset_right = 368
	card.offset_bottom = 168
	_cockpit_root.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 2)
	card.add_child(cv)
	cv.add_child(NeonUI.kicker("MANUAL FLIGHT", NeonUI.CYAN, 10))
	_co_msg = Label.new()
	NeonUI.heading(_co_msg, 18, NeonUI.GREEN)
	_co_msg.text = "STANDBY"
	cv.add_child(_co_msg)
	_co_dist = Label.new()
	NeonUI.mono(_co_dist, 12, NeonUI.TEXT)
	_co_dist.text = "DISTANCE  12000 KM"
	cv.add_child(_co_dist)

	var auto_card := NeonUI.panel("cyan", 8)
	auto_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	auto_card.offset_left = -240
	auto_card.offset_top = 70
	auto_card.offset_right = -28
	auto_card.offset_bottom = 132
	_cockpit_root.add_child(auto_card)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 1)
	auto_card.add_child(av)
	av.add_child(NeonUI.kicker("AUTOPILOT", NeonUI.MUTED, 9))
	_co_auto = Label.new()
	NeonUI.mono(_co_auto, 12, NeonUI.CYAN)
	_co_auto.text = "AUTOPILOT IN  8.6s"
	av.add_child(_co_auto)

	var bottom_card := NeonUI.panel("cyan", 10)
	bottom_card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_card.offset_left = -330
	bottom_card.offset_right = 330
	bottom_card.offset_top = -144
	bottom_card.offset_bottom = -92
	_cockpit_root.add_child(bottom_card)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	bottom_card.add_child(bh)
	bh.add_child(NeonUI.mono("MOUSE  ·  A/D  ·  W/S  ·  SPACE SKIP", 11, NeonUI.MUTED))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(sp)
	bh.add_child(NeonUI.caption("HULL", 10))
	for i in 3:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(14, 10)
		var psb := StyleBoxFlat.new()
		psb.bg_color = NeonUI.GREEN
		psb.set_corner_radius_all(2)
		pip.add_theme_stylebox_override("panel", psb)
		bh.add_child(pip)
		_co_hull.append(pip)

	# reticle
	var ret_col := Color(0.31, 0.84, 1.0, 0.55)
	for spec in [[-1, -34, 1, -18], [-1, 18, 1, 34], [-34, -1, -18, 1], [18, -1, 34, 1]]:
		var r := ColorRect.new()
		r.color = ret_col
		r.set_anchors_preset(Control.PRESET_CENTER)
		r.offset_left = spec[0]
		r.offset_top = spec[1]
		r.offset_right = spec[2]
		r.offset_bottom = spec[3]
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cockpit_root.add_child(r)

	# --- hit flash + cinematic letterbox (above the HUD)
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 7
	add_child(fx_layer)
	_hit_flash = ColorRect.new()
	_hit_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hit_flash.color = Color(1.0, 0.18, 0.12)
	_hit_flash.modulate.a = 0.0
	_hit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(_hit_flash)
	_letterbox_top = ColorRect.new()
	_letterbox_top.color = Color(0, 0, 0)
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.offset_bottom = 0
	_letterbox_top.visible = false
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(_letterbox_top)
	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.color = Color(0, 0, 0)
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.offset_top = 0
	_letterbox_bottom.visible = false
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(_letterbox_bottom)


func _phase_index() -> int:
	if _t >= ARRIVE_T:
		return 4
	if _t >= CONTROL_T:
		return 3
	if _t >= SEP_T:
		return 2
	if _t >= LIFTOFF_T:
		return 1
	return 0


func _update_timeline() -> void:
	var idx := _phase_index()
	if idx == _phase:
		return
	_phase = idx
	for i in PHASES.size():
		var dot := _phase_dots[i]
		var lab := _phase_labels[i]
		var sb := dot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i < idx:
			sb.bg_color = NeonUI.CYAN
			lab.add_theme_color_override("font_color", NeonUI.CYAN)
		elif i == idx:
			sb.bg_color = NeonUI.GOLD
			lab.add_theme_color_override("font_color", NeonUI.GOLD)
		else:
			sb.bg_color = Color(0.25, 0.28, 0.36)
			lab.add_theme_color_override("font_color", NeonUI.DIM)
		dot.add_theme_stylebox_override("panel", sb)


# ===================================================================== helpers

func _box(size: Vector3, color: Color, metallic := 0.2, roughness := 0.7) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	mesh.material = m
	mi.mesh = mesh
	return mi


func _cyl(top_r: float, bottom_r: float, height: float, color: Color, metallic := 0.2, roughness := 0.6) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 24
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	mesh.material = m
	mi.mesh = mesh
	return mi


func _flame_cone(top_r: float, bottom_r: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 4.0
	mesh.material = m
	mi.mesh = mesh
	return mi


func _smoke_particles(amount: int, lifetime: float, direction: Vector3, spread: float,
		vmin: float, vmax: float, smin: float, smax: float, gravity: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = gravity
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	p.mesh = _smoke_mesh()
	p.emitting = false
	return p


func _smoke_mesh() -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.55, 0.60, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = m
	return sm


func _star(radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.5
	m.disable_fog = true
	sm.material = m
	mi.mesh = sm
	return mi


func _space_stage(top_r: float, bottom_r: float, height: float, color: Color) -> Node3D:
	var root := Node3D.new()
	var body := _cyl(top_r, bottom_r, height, color, 0.2, 0.5)
	body.rotation.x = -PI / 2.0
	root.add_child(body)
	var nozzle := _cyl(bottom_r * 0.55, 0.02, 0.8, Color(0.25, 0.25, 0.30), 0.8, 0.3)
	nozzle.rotation.x = -PI / 2.0
	nozzle.position = Vector3(0, 0, height * 0.5 + 0.4)
	root.add_child(nozzle)
	return root


func _build_rumble() -> void:
	_rumble = AudioStreamPlayer.new()
	_rumble.name = "LaunchRumble"
	_rumble.volume_db = -4.0
	var stream: AudioStream = null
	if ResourceLoader.exists(RUMBLE_FILE):
		stream = load(RUMBLE_FILE) as AudioStream
	if stream == null:
		stream = _make_rumble()
	_rumble.stream = stream
	add_child(_rumble)


## Procedural launch rumble (Member C, README §C step 7): brown noise + low-pass +
## envelope. A real file at res://audio/jerryblessed-space-rocket-launch-rumble-544846.wav
## is used when present.
func _make_rumble() -> AudioStreamWAV:
	var rate := 22050
	var seconds := 4.0
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var brown := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(rate)
		brown = clampf(brown + rng.randf_range(-1.0, 1.0) * 0.02, -1.0, 1.0)
		lp = lerpf(lp, brown, 0.06)
		var env := 1.0
		if t < 0.25:
			env = t / 0.25
		elif t > 3.0:
			env = clampf(1.0 - (t - 3.0) / 1.0, 0.0, 1.0)
		var wob := 0.80 + 0.20 * sin(t * 2.3) * sin(t * 0.8)
		var v := clampf(lp * 5.0 * env * wob, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


## Inertial separation profile: an initial push-off (the release springs) that
## decays into a constant drift — what a real stage looks like after separation.
func _sep_motion(t: float, v_inf: float, d0: float, tau: float) -> float:
	return v_inf * t + d0 * tau * (1.0 - exp(-t / tau))


func _at(node: Node3D, pos: Vector3) -> Node3D:
	node.position = pos
	return node
