# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M7 Mission briefing: the destination planet big in 3D, the objective, 4 key numbers,
# required instrument types and a "Did you know?" fact. Owner: Member A.
extends Node3D

const PLANET_FOR := {"earth": "earth", "moon": "moon", "mars": "mars", "jupiter": "jupiter", "saturn": "saturn"}
const TYPE_NAMES := {
	"imaging": "Camera", "spectro": "Spectrometer", "radar": "Radar", "fields": "Magnetic / particle sensor",
	"interior": "Microwave radiometer", "mapping": "Laser altimeter", "sampling": "Dust analyzer",
}

var _planet: Node3D
var _cam: Camera3D
var _t := 0.0
var mission: Dictionary


func _ready() -> void:
	mission = GameData.get_mission(MissionState.current_mission_id)
	MenuPlanet.add_space(self)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-15, -70, 0)
	sun.light_energy = 1.4
	add_child(sun)
	_planet = MenuPlanet.make(PLANET_FOR.get(mission.get("id", ""), "earth"))
	_planet.scale = Vector3.ONE * (3.2 if mission.get("id", "") != "saturn" else 2.4)
	_planet.position = Vector3(4.2, 0, 0)
	add_child(_planet)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0.5, 12)
	_cam.fov = 50
	add_child(_cam)
	_build_ui()


func _process(delta: float) -> void:
	_t += delta
	_planet.rotation.y += delta * 0.08
	_cam.position = Vector3(sin(_t * 0.12) * 0.5, 0.5 + cos(_t * 0.1) * 0.2, lerpf(14.0, 12.0, clampf(_t / 3.0, 0.0, 1.0)))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var v := VBoxContainer.new()
	v.position = Vector2(56, 40)
	v.custom_minimum_size.x = 600
	v.add_theme_constant_override("separation", 12)
	root.add_child(v)

	var kicker := Label.new()
	kicker.text = "MISSION %d BRIEFING  ·  %s" % [int(mission.get("order", 0)), str(mission.get("destination", "")).to_upper()]
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.modulate = Color(0.65, 0.75, 1.0)
	v.add_child(kicker)
	var name_l := Label.new()
	name_l.text = mission.get("name", "")
	name_l.add_theme_font_size_override("font_size", 56)
	name_l.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
	v.add_child(name_l)
	var obj := Label.new()
	obj.text = mission.get("objective", "")
	obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obj.custom_minimum_size.x = 600
	obj.add_theme_font_size_override("font_size", 24)
	v.add_child(obj)
	var desc := Label.new()
	desc.text = mission.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 600
	desc.add_theme_font_size_override("font_size", 17)
	desc.modulate = Color(0.8, 0.85, 0.95)
	v.add_child(desc)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	v.add_child(chips)
	var delay := float(mission.get("signal_delay_min", 0))
	var delay_txt := ("%.1f s" % (delay * 60.0)) if delay < 1.0 and delay > 0.0 else ("instant" if delay == 0.0 else "%d min" % int(delay))
	for c in [["BUDGET", "$%s M" % PartInfo.fmt(mission.get("budget_musd", 0))],
			["LIFETIME", "%d year%s" % [int(mission.get("min_years", 1)), "" if int(mission.get("min_years", 1)) == 1 else "s"]],
			["SCIENCE GOAL", "%s Gb" % PartInfo.fmt(mission.get("data_goal_gb", 0))],
			["SIGNAL DELAY", delay_txt]]:
		chips.add_child(_chip(c[0], c[1]))

	var need := Label.new()
	var names: Array = []
	for t in mission.get("required_types", []):
		names.append(TYPE_NAMES.get(t, t))
	need.text = "Must carry: " + ", ".join(names)
	need.add_theme_font_size_override("font_size", 18)
	need.modulate = Color(0.55, 1.0, 0.65)
	v.add_child(need)

	var fact := PanelContainer.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.08, 0.1, 0.2, 0.85)
	fsb.border_color = Color(1, 0.82, 0.3)
	fsb.border_width_left = 4
	fsb.set_corner_radius_all(8)
	fsb.set_content_margin_all(14)
	fact.add_theme_stylebox_override("panel", fsb)
	fact.custom_minimum_size.x = 600
	v.add_child(fact)
	var fl := Label.new()
	fl.text = "Did you know?  " + str(mission.get("fact", ""))
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fl.add_theme_font_size_override("font_size", 16)
	fact.add_child(fl)

	var buttons := HBoxContainer.new()
	buttons.position = Vector2(780, 630)
	buttons.add_theme_constant_override("separation", 12)
	root.add_child(buttons)
	var back := Button.new()
	back.text = "< Map"
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): MissionState.go_to("campaign_map"))
	buttons.add_child(back)
	var go := Button.new()
	go.text = "TO THE HANGAR  >"
	go.custom_minimum_size = Vector2(300, 64)
	go.add_theme_font_size_override("font_size", 24)
	go.pressed.connect(func(): MissionState.go_to("hangar"))
	buttons.add_child(go)


func _chip(label_text: String, value: String) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.16, 0.85)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.x = 140
	var v := VBoxContainer.new()
	p.add_child(v)
	var a := Label.new()
	a.text = label_text
	a.add_theme_font_size_override("font_size", 12)
	a.modulate = Color(0.6, 0.7, 0.9)
	v.add_child(a)
	var b := Label.new()
	b.text = value
	b.add_theme_font_size_override("font_size", 22)
	v.add_child(b)
	return p
