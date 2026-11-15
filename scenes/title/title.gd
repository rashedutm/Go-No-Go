# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# M7 Title screen: Earth in 3D with a spacecraft orbiting it, logo, Play / How to play / Credits.
# Owner: Member A.
extends Node3D

var _earth: Node3D
var _orbit: Node3D
var _hero: Node3D
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
	_earth.position = Vector3(4.8, -1.6, 0)
	add_child(_earth)

	_orbit = Node3D.new()
	_orbit.position = _earth.position
	_orbit.rotation_degrees = Vector3(12, 0, -14)
	add_child(_orbit)
	var craft := SpacecraftModel3D.build(Sim.make_test_design("mars"))
	craft.scale = Vector3.ONE * 0.5
	craft.position = Vector3(6.8, 2.6, 1.4)
	craft.rotation = Vector3(0.1, 2.35, 0.05)
	add_child(craft)
	_hero = craft

	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0, 13)
	_cam.fov = 50
	add_child(_cam)
	_build_ui()


func _process(delta: float) -> void:
	_t += delta
	_earth.rotation.y += delta * 0.05
	if _hero:
		_hero.rotate_y(delta * 0.12)
	_cam.position = Vector3(sin(_t * 0.1) * 0.6, cos(_t * 0.13) * 0.3, 13)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var box := VBoxContainer.new()
	box.position = Vector2(72, 88)
	box.add_theme_constant_override("separation", 10)
	root.add_child(box)

	var kick_row := HBoxContainer.new()
	kick_row.add_theme_constant_override("separation", 10)
	box.add_child(kick_row)
	kick_row.add_child(NeonUI.stripes(NeonUI.GOLD))
	var kick := NeonUI.kicker("SPACE MISSION DESIGN GAME", NeonUI.CYAN, 11)
	kick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kick_row.add_child(kick)

	var logo := Label.new()
	logo.text = "GO / NO-GO"
	NeonUI.display(logo, 88, NeonUI.TEXT)
	box.add_child(logo)

	var tag := Label.new()
	tag.text = "DESIGN IT.  LAUNCH IT.  FLY IT."
	NeonUI.heading(tag, 26, NeonUI.GOLD)
	box.add_child(tag)

	var tag2 := Label.new()
	tag2.text = "\"Go/No-Go\" is the call every flight controller makes before launch. In this game, you earn it."
	NeonUI.body(tag2, 15, NeonUI.MUTED, true)
	tag2.custom_minimum_size.x = 430
	box.add_child(tag2)

	var gap := Control.new()
	gap.custom_minimum_size.y = 16
	box.add_child(gap)

	var play := _button("PLAY", 24, Vector2(310, 62))
	NeonUI.primary(play, 24)
	play.pressed.connect(func(): MissionState.go_to("campaign_map"))
	box.add_child(play)
	var how := _button("HOW TO PLAY", 18, Vector2(310, 46))
	NeonUI.ghost(how, 18)
	how.pressed.connect(func(): _show(HOW_TO))
	box.add_child(how)
	var cred := _button("CREDITS & NASA SOURCES", 18, Vector2(310, 46))
	NeonUI.ghost(cred, 16)
	cred.pressed.connect(func(): _show(CREDITS))
	box.add_child(cred)

	var foot := Label.new()
	foot.text = "NASA SPACE APPS CHALLENGE 2026  ·  SPACE MISSION DESIGN GAME"
	NeonUI.mono_regular(foot, 10, NeonUI.DIM)
	foot.position = Vector2(72, 682)
	root.add_child(foot)

	_overlay = NeonUI.panel("cyan", 20)
	_overlay.custom_minimum_size = Vector2(760, 520)
	_overlay.position = Vector2(260, 100)
	_overlay.visible = false
	root.add_child(_overlay)
	var ov := VBoxContainer.new()
	_overlay.add_child(ov)
	ov.add_child(NeonUI.kicker("MISSION BRIEFING", NeonUI.GOLD, 11))
	_overlay_text = RichTextLabel.new()
	_overlay_text.bbcode_enabled = true
	_overlay_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_overlay_text.add_theme_font_override("normal_font", NeonUI.font("Barlow-Regular.ttf"))
	_overlay_text.add_theme_font_override("bold_font", NeonUI.font("Barlow-SemiBold.ttf"))
	_overlay_text.add_theme_font_size_override("normal_font_size", 15)
	_overlay_text.add_theme_font_size_override("bold_font_size", 15)
	ov.add_child(_overlay_text)
	var close := _button("CLOSE", 16, Vector2(140, 42))
	NeonUI.ghost(close, 16)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(func(): _overlay.visible = false)
	ov.add_child(close)

	var reset := _button("RESET PROGRESS", 12, Vector2(150, 30))
	NeonUI.ghost(reset, 12)
	reset.position = Vector2(1110, 670)
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
