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

	var panel := NeonUI.panel("cyan", 18)
	panel.position = Vector2(32, 24)
	panel.custom_minimum_size.x = 660
	root.add_child(panel)
	var backing := ColorRect.new()
	backing.color = Color(0.01, 0.02, 0.05, 0.55)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(backing)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var kicker := NeonUI.kicker("MISSION %d BRIEFING  ·  %s" % [int(mission.get("order", 0)), str(mission.get("destination", "")).to_upper()], NeonUI.CYAN, 11)
	v.add_child(kicker)
	var name_l := Label.new()
	name_l.text = str(mission.get("name", "")).to_upper()
	NeonUI.display(name_l, 48, NeonUI.GOLD)
	v.add_child(name_l)
	var obj := Label.new()
	obj.text = mission.get("objective", "")
	NeonUI.body(obj, 18, NeonUI.TEXT, true)
	obj.custom_minimum_size.x = 620
	v.add_child(obj)
	var desc := Label.new()
	desc.text = mission.get("description", "")
	NeonUI.body(desc, 14, NeonUI.MUTED, true)
	desc.custom_minimum_size.x = 620
	v.add_child(desc)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
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
	need.text = "MUST CARRY: " + ", ".join(names).to_upper()
	NeonUI.mono(need, 13, NeonUI.GREEN)
	v.add_child(need)

	var fact := NeonUI.panel("cyan", 12)
	fact.custom_minimum_size.x = 620
	v.add_child(fact)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 2)
	fact.add_child(fv)
	fv.add_child(NeonUI.kicker("DID YOU KNOW?", NeonUI.GOLD, 10))
	var fl := Label.new()
	fl.text = str(mission.get("fact", ""))
	NeonUI.body(fl, 13, NeonUI.TEXT, true)
	fv.add_child(fl)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	v.add_child(buttons)
	var back := Button.new()
	back.text = "‹  MAP"
	NeonUI.ghost(back, 16)
	back.pressed.connect(func(): MissionState.go_to("campaign_map"))
	buttons.add_child(back)
	var go := Button.new()
	go.text = "TO THE HANGAR  →"
	NeonUI.primary(go, 20)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(func(): MissionState.go_to("hangar"))
	buttons.add_child(go)


func _chip(label_text: String, value: String) -> Control:
	var p := NeonUI.panel("cyan", 9)
	p.custom_minimum_size.x = 145
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(NeonUI.kicker(label_text, NeonUI.MUTED, 9))
	v.add_child(NeonUI.mono(value, 14, NeonUI.TEXT))
	return p
