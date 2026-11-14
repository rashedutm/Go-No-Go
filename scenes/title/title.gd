# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M7 Title screen: Earth in 3D with a spacecraft orbiting it, logo, Play / How to play / Credits.
# Owner: Member A.
extends Node3D

var _earth: Node3D
var _orbit: Node3D
var _cam: Camera3D
var _t := 0.0
var _overlay: PanelContainer
var _overlay_text: RichTextLabel

const HOW_TO := """[b]How to play[/b]

[b]1. Pick a mission[/b] on the Solar System map, from Earth orbit all the way to Saturn.
[b]2. Build your spacecraft[/b] in the 3D hangar. Four stations (Director, Engineer, Science, Comms) choose the rocket, frame, power, battery, instruments and antenna. [i]Every part costs money, mass, power and data.[/i]
[b]3. Go/No-Go poll:[/b] the flight controllers check your design. Fix every NO-GO.
[b]4. Launch![/b]
[b]5. Fly it from Mission Control:[/b] walk to the consoles and handle solar storms, failing batteries and surprise discoveries.
[b]6. Debrief:[/b] get scored on science, survival and budget, and see which real NASA mission yours is like.

[i]There is no single perfect design. Every choice helps one thing and hurts another.[/i]"""

const CREDITS := """[b]Go/No-Go[/b]: made for the NASA Space Apps Challenge 2026 ("Space Mission Design Game").

[b]NASA resources used[/b]
• NASA CubeSat 101: Basic Concepts and Processes for First-Time CubeSat Developers
• NASA "Design and Develop Science Missions" (SmallSat Institute webinar, 2025)
• NASA Mission Design Lab, JPL Concept Maturity Levels
• Real missions in the debrief: Landsat 9, PACE, LRO, MRO, MAVEN, Juno, Europa Clipper, Cassini (science.nasa.gov)

[b]Built with[/b] Godot Engine 4.7 (MIT license).
[b]AI use[/b]: code, design text and documentation were written with the help of AI assistants (Claude by Anthropic). Each code file is marked.

Numbers are simplified for gameplay but kept in realistic proportion. Not an official NASA product."""


func _ready() -> void:
	MenuPlanet.add_space(self)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20, -60, 0)
	sun.light_energy = 1.3
	add_child(sun)

	_earth = MenuPlanet.make("earth")
	_earth.scale = Vector3.ONE * 3.2
	_earth.position = Vector3(5.8, -1.6, 0)
	add_child(_earth)

	_orbit = Node3D.new()
	_orbit.position = _earth.position
	_orbit.rotation_degrees = Vector3(12, 0, -14)
	add_child(_orbit)
	var craft := SpacecraftModel3D.build(Sim.make_test_design("mars"))
	craft.scale = Vector3.ONE * 0.35
	craft.position = Vector3(4.6, 0, 0)
	_orbit.add_child(craft)

	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0, 13)
	_cam.fov = 50
	add_child(_cam)
	_build_ui()


func _process(delta: float) -> void:
	_t += delta
	_earth.rotation.y += delta * 0.05
	_orbit.rotation.y += delta * 0.25
	_cam.position = Vector3(sin(_t * 0.1) * 0.6, cos(_t * 0.13) * 0.3, 13)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var box := VBoxContainer.new()
	box.position = Vector2(80, 120)
	box.add_theme_constant_override("separation", 14)
	root.add_child(box)

	var logo := Label.new()
	logo.text = "GO / NO-GO"
	logo.add_theme_font_size_override("font_size", 96)
	logo.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	logo.add_theme_constant_override("shadow_offset_x", 4)
	logo.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(logo)
	var tag := Label.new()
	tag.text = "Design it. Launch it. Fly it from Mission Control."
	tag.add_theme_font_size_override("font_size", 26)
	box.add_child(tag)
	var tag2 := Label.new()
	tag2.text = "\"Go/No-Go\" is the call every flight controller makes before launch.\nIn this game, you earn it."
	tag2.add_theme_font_size_override("font_size", 17)
	tag2.modulate = Color(0.7, 0.78, 0.95)
	box.add_child(tag2)
	var gap := Control.new()
	gap.custom_minimum_size.y = 20
	box.add_child(gap)

	var play := _button("PLAY", 30, Vector2(300, 72))
	play.pressed.connect(func(): MissionState.go_to("campaign_map"))
	box.add_child(play)
	var how := _button("How to play", 20, Vector2(300, 48))
	how.pressed.connect(func(): _show(HOW_TO))
	box.add_child(how)
	var cred := _button("Credits & NASA sources", 20, Vector2(300, 48))
	cred.pressed.connect(func(): _show(CREDITS))
	box.add_child(cred)

	var foot := Label.new()
	foot.text = "NASA Space Apps Challenge 2026  ·  Space Mission Design Game"
	foot.add_theme_font_size_override("font_size", 14)
	foot.modulate = Color(0.55, 0.62, 0.8)
	foot.position = Vector2(80, 680)
	root.add_child(foot)

	_overlay = PanelContainer.new()
	_overlay.custom_minimum_size = Vector2(760, 520)
	_overlay.position = Vector2(260, 100)
	_overlay.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.13, 0.96)
	sb.border_color = Color(0.3, 0.45, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(24)
	_overlay.add_theme_stylebox_override("panel", sb)
	root.add_child(_overlay)
	var ov := VBoxContainer.new()
	_overlay.add_child(ov)
	_overlay_text = RichTextLabel.new()
	_overlay_text.bbcode_enabled = true
	_overlay_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_overlay_text.add_theme_font_size_override("normal_font_size", 17)
	_overlay_text.add_theme_font_size_override("bold_font_size", 18)
	ov.add_child(_overlay_text)
	var close := _button("Close", 18, Vector2(140, 44))
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(func(): _overlay.visible = false)
	ov.add_child(close)

	var reset := _button("Reset progress", 13, Vector2(140, 30))
	reset.position = Vector2(1120, 670)
	reset.pressed.connect(func(): MissionState.reset_progress())
	root.add_child(reset)


func _show(text: String) -> void:
	_overlay_text.text = text
	_overlay.visible = true


func _button(text: String, size: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	return b
