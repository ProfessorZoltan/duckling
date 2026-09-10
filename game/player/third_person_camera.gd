extends Node3D
## Third-person orbit camera on a SpringArm3D.
##
## Mouse or right stick orbits; the arm shortens against walls; arm length and
## pivot height scale with PlayerScale so the world visibly "shrinks" as the
## duckling grows. In flight the camera drifts in behind the bird when the
## player isn't steering it, and pulls back further as speed rises.
## Esc releases the mouse; clicking recaptures it.

@export var mouse_sensitivity: float = 0.0025
@export var stick_sensitivity: float = 2.2
@export var min_pitch_degrees: float = -55.0
@export var max_pitch_degrees: float = 25.0
@export var default_pitch_degrees: float = -18.0
@export var base_arm_length: float = 3.0
@export var base_pivot_height: float = 0.45
## How quickly the camera swings behind the heading while flying.
@export var flight_follow_strength: float = 2.0
## Seconds after manual camera input before auto-follow resumes.
@export var flight_follow_delay: float = 0.8
## Extra arm length at top airspeed, as a fraction of the base length.
@export var flight_speed_zoom: float = 0.9
@export var flight_pitch_degrees: float = -8.0

@onready var arm: SpringArm3D = $SpringArm3D

var _player: Player
var _since_manual_input: float = 999.0
var _arm_scale: float = 1.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_player = get_parent() as Player
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
	_since_manual_input += delta
	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if stick.length_squared() > 0.0:
		_orbit(-stick.x * stick_sensitivity * delta, -stick.y * stick_sensitivity * delta)

	var zoom := 1.0
	if _player and _player.state == Player.State.FLY:
		var s := Globals.player_scale
		var speed_ratio := clampf(_player.air_speed / (_player.max_air_speed * s), 0.0, 1.0)
		zoom = 1.0 + flight_speed_zoom * speed_ratio
		if _since_manual_input > flight_follow_delay:
			var blend := clampf(flight_follow_strength * delta, 0.0, 1.0)
			rotation.y = lerp_angle(rotation.y, _player.heading, blend)
			arm.rotation.x = lerpf(arm.rotation.x, deg_to_rad(flight_pitch_degrees), blend * 0.5)
	_arm_scale = lerpf(_arm_scale, zoom, clampf(3.0 * delta, 0.0, 1.0))
	arm.spring_length = base_arm_length * Globals.player_scale * _arm_scale


func _orbit(yaw: float, pitch: float) -> void:
	_since_manual_input = 0.0
	rotation.y += yaw
	arm.rotation.x = clampf(
		arm.rotation.x + pitch,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)


func _apply_scale(s: float) -> void:
	arm.spring_length = base_arm_length * s * _arm_scale
	position.y = base_pivot_height * s
