extends Node3D
## Third-person orbit camera on a SpringArm3D.
##
## Mouse or right stick orbits; the arm shortens against walls; arm length and
## pivot height scale with PlayerScale so the world visibly "shrinks" as the
## duckling grows. Esc releases the mouse; clicking recaptures it.

@export var mouse_sensitivity: float = 0.0025
@export var stick_sensitivity: float = 2.2
@export var min_pitch_degrees: float = -55.0
@export var max_pitch_degrees: float = 25.0
@export var default_pitch_degrees: float = -18.0
@export var base_arm_length: float = 3.0
@export var base_pivot_height: float = 0.45

@onready var arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var owner_body := get_parent() as CollisionObject3D
	if owner_body:
		arm.add_excluded_object(owner_body.get_rid())
	arm.rotation.x = deg_to_rad(default_pitch_degrees)
	Globals.player_scale_changed.connect(_apply_scale)
	_apply_scale(Globals.player_scale)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_orbit(-motion.relative.x * mouse_sensitivity, -motion.relative.y * mouse_sensitivity)


func _process(delta: float) -> void:
	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if stick.length_squared() > 0.0:
		_orbit(-stick.x * stick_sensitivity * delta, -stick.y * stick_sensitivity * delta)


func _orbit(yaw: float, pitch: float) -> void:
	rotation.y += yaw
	arm.rotation.x = clampf(
		arm.rotation.x + pitch,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)


func _apply_scale(s: float) -> void:
	arm.spring_length = base_arm_length * s
	position.y = base_pivot_height * s
