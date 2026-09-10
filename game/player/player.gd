class_name Player
extends CharacterBody3D
## P1 duckling controller: wobble walk, paddle swim, hop.
##
## States follow the design doc's state machine (§9). Dive, Glide and Fly are
## added in P4. The CharacterBody3D root never rotates; only [member body]
## turns and wobbles, so the camera pivot stays independent of facing.

enum State { WALK, SWIM, AIR }

@export_group("Speeds at PlayerScale 1.0")
@export var walk_speed: float = 2.0
@export var swim_speed: float = 1.4
@export var hop_velocity: float = 3.5
@export var water_hop_velocity: float = 2.5
@export var acceleration: float = 12.0
@export var air_control: float = 0.4

@export_group("Feel")
## Seconds of input lag. The doc asks for 0.15s so a hatchling feels wobbly.
@export var input_smoothing: float = 0.15
@export var turn_speed: float = 9.0
@export var wobble_roll_degrees: float = 2.5
@export var wobble_frequency: float = 7.0
## How far below the surface the origin sits when floating, at scale 1.0.
@export var float_depth: float = 0.22
@export var buoyancy: float = 18.0
@export var water_drag: float = 6.0

var state: State = State.WALK
var water_level: float = -INF

var _water_volume_count: int = 0
var _smoothed_input: Vector2 = Vector2.ZERO
var _wobble_time: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var body: Node3D = $Body
@onready var camera_pivot: Node3D = $CameraPivot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _base_capsule_radius: float
var _base_capsule_height: float
var _base_collision_y: float


func _ready() -> void:
	# Own a copy of the shape so scaling never edits the shared resource.
	collision_shape.shape = collision_shape.shape.duplicate()
	var capsule := collision_shape.shape as CapsuleShape3D
	_base_capsule_radius = capsule.radius
	_base_capsule_height = capsule.height
	_base_collision_y = collision_shape.position.y
	Globals.player_scale_changed.connect(_apply_scale)
	_apply_scale(Globals.player_scale)


func _physics_process(delta: float) -> void:
	_update_state()

	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_smoothed_input = _smoothed_input.lerp(raw_input, clampf(delta / input_smoothing, 0.0, 1.0))
	var wish_dir := _camera_relative(_smoothed_input)
	var s := Globals.player_scale

	match state:
		State.WALK:
			_walk(delta, wish_dir, s)
		State.SWIM:
			_swim(delta, wish_dir, s)
		State.AIR:
			_air(delta, wish_dir, s)

	move_and_slide()
	_animate(delta)


func _walk(delta: float, wish_dir: Vector3, s: float) -> void:
	var target := wish_dir * walk_speed * s
	var accel := acceleration * s * delta
	velocity.x = move_toward(velocity.x, target.x, accel)
	velocity.z = move_toward(velocity.z, target.z, accel)
	velocity.y -= _gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = hop_velocity * sqrt(s)
		state = State.AIR


func _swim(delta: float, wish_dir: Vector3, s: float) -> void:
	var target := wish_dir * swim_speed * s
	var accel := acceleration * 0.6 * s * delta
	velocity.x = move_toward(velocity.x, target.x, accel)
	velocity.z = move_toward(velocity.z, target.z, accel)
	# Spring toward float height, damped so the duck bobs rather than oscillates.
	var target_y := water_level - float_depth * s
	velocity.y += (target_y - global_position.y) * buoyancy * delta
	velocity.y -= velocity.y * clampf(water_drag * delta, 0.0, 1.0)
	if Input.is_action_just_pressed("jump"):
		velocity.y = water_hop_velocity * sqrt(s)
		state = State.AIR


func _air(delta: float, wish_dir: Vector3, s: float) -> void:
	var target := wish_dir * walk_speed * s
	var accel := acceleration * air_control * s * delta
	velocity.x = move_toward(velocity.x, target.x, accel)
	velocity.z = move_toward(velocity.z, target.z, accel)
	velocity.y -= _gravity * delta


func _update_state() -> void:
	var s := Globals.player_scale
	var in_volume := _water_volume_count > 0 and is_finite(water_level)
	var depth := water_level - global_position.y if in_volume else -INF
	# Hysteresis: enter swim at full float depth, leave at half, so a duck on a
	# gently sloping shore doesn't flicker between states.
	var swim_enter := float_depth * s
	var swim_exit := float_depth * s * 0.5

	match state:
		State.WALK:
			if in_volume and depth > swim_enter:
				state = State.SWIM
			elif not is_on_floor():
				state = State.AIR
		State.AIR:
			if in_volume and depth > swim_enter and velocity.y <= 0.0:
				state = State.SWIM
			elif is_on_floor():
				state = State.WALK
		State.SWIM:
			if not in_volume or (is_on_floor() and depth < swim_exit):
				state = State.WALK


func _camera_relative(input: Vector2) -> Vector3:
	var forward := -camera_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera_pivot.global_basis.x
	right.y = 0.0
	right = right.normalized()
	# get_vector() gives -y for "forward", so negate it.
	return right * input.x + forward * -input.y


func _animate(delta: float) -> void:
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	var s := Globals.player_scale

	if planar.length() > 0.05:
		var target_yaw := atan2(-planar.x, -planar.z)
		body.rotation.y = lerp_angle(body.rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

	var speed_ratio := clampf(planar.length() / (walk_speed * s), 0.0, 1.0)
	if state == State.WALK and speed_ratio > 0.05:
		_wobble_time += delta * wobble_frequency * TAU * 0.5
		body.rotation.z = sin(_wobble_time) * deg_to_rad(wobble_roll_degrees) * speed_ratio
	else:
		body.rotation.z = lerpf(body.rotation.z, 0.0, clampf(8.0 * delta, 0.0, 1.0))

	# Nose dips a touch while paddling.
	var target_pitch := deg_to_rad(6.0) * speed_ratio if state == State.SWIM else 0.0
	body.rotation.x = lerpf(body.rotation.x, target_pitch, clampf(5.0 * delta, 0.0, 1.0))


func _apply_scale(s: float) -> void:
	body.scale = Vector3.ONE * s
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.radius = _base_capsule_radius * s
	capsule.height = _base_capsule_height * s
	collision_shape.position.y = _base_collision_y * s


## Called by [WaterVolume]. [param surface_y] is the water surface in world space.
func enter_water(surface_y: float) -> void:
	_water_volume_count += 1
	water_level = surface_y


## Called by [WaterVolume].
func exit_water() -> void:
	_water_volume_count = maxi(_water_volume_count - 1, 0)
	if _water_volume_count == 0:
		water_level = -INF


func state_name() -> String:
	return State.keys()[state]
