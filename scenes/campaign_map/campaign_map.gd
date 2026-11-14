# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M7 Campaign map: a 3D Solar System strip (Sun → Earth+Moon → Mars → Jupiter → Saturn).
# Click a planet (or a mission tile) to select it; locked missions are dimmed with a lock.
# The camera glides to the selected planet. Owner: Member A.
extends Node3D

# mission id -> [planet id, position, scale]
const LAYOUT := {
	"earth": ["earth", Vector3(-5.0, 0, 0), 0.9],
	"moon": ["moon", Vector3(-3.4, 0.9, 0.6), 0.28],
	"mars": ["mars", Vector3(0.5, 0, 0), 0.6],
	"jupiter": ["jupiter", Vector3(7.0, 0, 0), 2.0],
	"saturn": ["saturn", Vector3(14.5, 0, 0), 1.6],
}
const C_GOOD := Color(0.35, 0.9, 0.45)

var _selected := "earth"
var _planets := {}
var _cam: Camera3D
var _cam_target := Vector3.ZERO
var _t := 0.0

var _info_name: Label
var _info_dest: Label
var _info_obj: Label
var _info_meta: Label
var _brief_btn: Button
var _tiles := {}


func _ready() -> void:
	get_viewport().physics_object_picking = true
	MenuPlanet.add_space(self)
	var sun_light := OmniLight3D.new()
	sun_light.position = Vector3(-14, 0, 2)
	sun_light.omni_range = 60
	sun_light.omni_attenuation = 0.4
	sun_light.light_energy = 2.2
	add_child(sun_light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, -80, 0)
	fill.light_energy = 0.25
	add_child(fill)

	var sun := MenuPlanet.make("sun")
	sun.scale = Vector3.ONE * 5.0
	sun.position = Vector3(-16, 0, 0)
	add_child(sun)

	# orbit path line (thin flat ring segments look busy; a simple dashed line along the strip)
	for x in range(-10, 18):
		var dash := SpacecraftModel3D._box(Vector3(0.4, 0.02, 0.02), Color(0.3, 0.4, 0.7), 0.0, 1.0)
		dash.position = Vector3(x, -2.4, 0)
		add_child(dash)

	for mid in LAYOUT:
		var cfg: Array = LAYOUT[mid]
		var p := MenuPlanet.make(cfg[0])
		p.position = cfg[1]
		p.scale = Vector3.ONE * cfg[2]
		add_child(p)
		var area := Area3D.new()
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.3
		shape.shape = sphere
		area.add_child(shape)
		p.add_child(area)
		var id: String = mid
		area.input_event.connect(func(_c, ev, _p, _n, _i):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_select(id))
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 48
		label.pixel_size = 0.0045
		label.outline_size = 12
		label.position = cfg[1] + Vector3(0, cfg[2] * 1.15 + 0.45, 0)
		add_child(label)
		_planets[mid] = {"node": p, "label": label}

	_cam = Camera3D.new()
	_cam.fov = 50
	add_child(_cam)

	_build_ui()
	# start on the furthest unlocked mission
	for m in GameData.get_missions_in_order():
		if MissionState.is_unlocked(m["id"]):
			_selected = m["id"]
	if MissionState.is_unlocked(MissionState.current_mission_id) and MissionState.campaign["stars"].get(MissionState.current_mission_id, 0) == 0:
		_selected = MissionState.current_mission_id
	_select(_selected)
	_cam_target = _focus_point(_selected)


func _focus_point(mid: String) -> Vector3:
	var cfg: Array = LAYOUT[mid]
	return cfg[1]


func _process(delta: float) -> void:
	_t += delta
	for mid in _planets:
		_planets[mid]["node"].rotation.y += delta * 0.15
	var goal := _focus_point(_selected)
	_cam_target = _cam_target.lerp(goal, 1.0 - exp(-delta * 3.0))
	var dist := 13.0 + float(LAYOUT[_selected][2]) * 3.5
	_cam.position = _cam_target + Vector3(-2.5 + sin(_t * 0.2) * 0.4, 2.0, dist)
	_cam.look_at(_cam_target + Vector3(3.2, -0.6, 0), Vector3.UP)


# ================================================================ UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var title := Label.new()
	title.text = "MISSION CAMPAIGN"
	title.add_theme_font_size_override("font_size", 36)
	title.position = Vector2(32, 22)
	root.add_child(title)
	var sub := Label.new()
	sub.text = "From Earth orbit to Saturn. Earn at least 1 star to unlock the next mission."
	sub.modulate = Color(0.7, 0.78, 0.95)
	sub.position = Vector2(34, 72)
	root.add_child(sub)
	var back := Button.new()
	back.text = "< Title"
	back.position = Vector2(1150, 24)
	back.pressed.connect(func(): MissionState.go_to("title"))
	root.add_child(back)

	# right info card
	var card := PanelContainer.new()
	card.position = Vector2(860, 120)
	card.custom_minimum_size = Vector2(390, 360)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.13, 0.88)
	sb.border_color = Color(0.3, 0.45, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20)
	card.add_theme_stylebox_override("panel", sb)
	root.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	_info_name = Label.new()
	_info_name.add_theme_font_size_override("font_size", 30)
	_info_name.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
	v.add_child(_info_name)
	_info_dest = Label.new()
	_info_dest.modulate = Color(0.7, 0.8, 1.0)
	v.add_child(_info_dest)
	_info_obj = Label.new()
	_info_obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_obj.add_theme_font_size_override("font_size", 19)
	_info_obj.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_info_obj)
	_info_meta = Label.new()
	_info_meta.add_theme_font_size_override("font_size", 16)
	v.add_child(_info_meta)
	_brief_btn = Button.new()
	_brief_btn.custom_minimum_size.y = 60
	_brief_btn.add_theme_font_size_override("font_size", 24)
	_brief_btn.pressed.connect(func():
		MissionState.start_mission(_selected)
		MissionState.go_to("briefing"))
	v.add_child(_brief_btn)

	# bottom mission tiles
	var row := HBoxContainer.new()
	row.position = Vector2(32, 590)
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	for m in GameData.get_missions_in_order():
		var b := Button.new()
		b.custom_minimum_size = Vector2(230, 96)
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		var id: String = m["id"]
		b.pressed.connect(func(): _select(id))
		row.add_child(b)
		_tiles[id] = b


func _stars(n: int) -> String:
	return "%d/3 stars" % n   # the default font has no star glyph; Daniel's debrief draws real stars


func _select(mid: String) -> void:
	_selected = mid
	var m := GameData.get_mission(mid)
	var unlocked := MissionState.is_unlocked(mid)
	var stars := int(MissionState.campaign["stars"].get(mid, 0))
	var best := int(MissionState.campaign["best_score"].get(mid, 0))
	_info_name.text = "%d. %s" % [int(m.get("order", 0)), m.get("name", "")]
	_info_dest.text = "%s   ·   difficulty %d/5" % [m.get("destination", ""), int(m.get("difficulty", 1))]
	_info_obj.text = m.get("objective", "") if unlocked else "LOCKED. Earn at least 1 star on the previous mission to unlock it."
	_info_meta.text = ("Best: %s  (score %d)" % [_stars(stars), best]) if stars > 0 else ("Not flown yet" if unlocked else "")
	_brief_btn.text = "MISSION BRIEFING  >" if unlocked else "LOCKED"
	_brief_btn.disabled = not unlocked

	for id in _tiles:
		var mm := GameData.get_mission(id)
		var b: Button = _tiles[id]
		var un := MissionState.is_unlocked(id)
		var st := int(MissionState.campaign["stars"].get(id, 0))
		b.text = "%d. %s\n%s" % [int(mm.get("order", 0)), mm.get("name", ""), _stars(st) if un else "locked"]
		b.button_pressed = id == mid
		b.modulate = Color.WHITE if un else Color(0.6, 0.6, 0.65)
	for id in _planets:
		var label: Label3D = _planets[id]["label"]
		var un := MissionState.is_unlocked(id)
		var st := int(MissionState.campaign["stars"].get(id, 0))
		label.text = GameData.get_mission(id).get("name", "") + ("\n" + _stars(st) if un else "\nlocked")
		label.modulate = (Color(1, 0.85, 0.35) if id == mid else Color.WHITE) if un else Color(0.55, 0.55, 0.6)
