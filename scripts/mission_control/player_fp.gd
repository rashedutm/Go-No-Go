# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# First-person player for the Mission Control room.
# Click to capture the mouse (browsers require a click), WASD/arrows to walk, mouse to look,
# E to interact, Esc to free the mouse. Input actions are created at runtime (project.godot is
# Member A's file). Owner: Member B (Emon).
class_name FPPlayer
extends CharacterBody3D

signal interact_pressed

const ACTIONS := {
	"mc_forward": [KEY_W, KEY_UP], "mc_back": [KEY_S, KEY_DOWN],
	"mc_left": [KEY_A, KEY_LEFT], "mc_right": [KEY_D, KEY_RIGHT],
	"mc_interact": [KEY_E], "mc_release": [KEY_ESCAPE],
}

@export var speed := 4.0
@export var mouse_sensitivity := 0.0025

var cam: Camera3D
var controls_enabled := true
var _pitch := 0.0


func _ready() -> void:
	_ensure_actions()
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)
	cam = Camera3D.new()
	cam.position.y = 1.65
	cam.fov = 72
	cam.current = true
	add_child(cam)


static func _ensure_actions() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


## Pauses walking/looking (e.g. while a console panel is open). The mouse stays captured,
## so looking around works again the moment the panel closes, with no extra click.
func set_controls_enabled(on: bool) -> void:
	controls_enabled = on


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.3, 1.3)
		cam.rotation.x = _pitch
	if event.is_action_pressed("mc_release"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("mc_interact"):
		interact_pressed.emit()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("mc_left", "mc_right", "mc_forward", "mc_back")
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= 9.8 * delta
	move_and_slide()


## Point on the floor in front of the player's eyes (used for "which console am I facing").
func look_dir() -> Vector3:
	return -cam.global_transform.basis.z
