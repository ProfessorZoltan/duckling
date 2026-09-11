class_name Player
extends CharacterBody3D
## Duckling controller: wobble walk, paddle swim, hop, and (P4) flight.
##
## States follow the design doc's state machine (§9). The CharacterBody3D root
## never rotates; only [member body] turns, wobbles, pitches and banks, so the
## camera pivot stays independent of facing.
##
## Flight (§7.4) is an A Short Hike style energy model: the bird has a scalar
## [member air_speed] along its heading and pitch. Nose down trades height for
## speed, nose up trades it back, a flap adds a decaying burst of lift and costs
## stamina, and a level glide settles at a trim speed. Water is always a safe
## landing; ground only accepts a landing below [member landing_speed].

enum State { WALK, SWIM, AIR, FLY }

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

@export_group("Flight at PlayerScale 1.0")
@export var min_air_speed: float = 3.0
@export var max_air_speed: float = 14.0
## Speed a hands-off glide settles toward.
@export var glide_trim_speed: float = 5.0
@export var air_drag: float = 0.6
## Hands-off nose angle. Negative sinks. Improves (gets shallower) with stage.
@export var glide_sink_degrees: float = -11.0
@export var juvenile_sink_degrees: float = -18.0
@export var pitch_up_degrees: float = 35.0
@export var pitch_down_degrees: float = -65.0
@export var pitch_rate: float = 2.5
@export var flight_turn_rate: float = 1.7
@export var bank_degrees: float = 35.0
## Upward burst from one flap, and how fast it decays (m/s per second).
@export var flap_lift: float = 4.5
@export var flap_boost: float = 1.0
@export var flap_lift_decay: float = 3.5
@export var flap_cost: float = 15.0
@export var max_stamina: float = 100.0
## Stamina regained per second while on the ground or water.
@export var stamina_regen: float = 30.0
## Touching ground below this speed lands; above it, you bounce off.
@export var landing_speed: float = 5.5
@export var bounce_damping: float = 0.45

var state: State = State.WALK
var water_level: float = -INF
var stamina: float = 100.0
var air_speed: float = 0.0
## Flight yaw, using the same convention as Node3D.rotation.y (forward is -Z).
var heading: float = 0.0
## Flight pitch in radians, positive is nose up.
var pitch: float = 0.0

## While frozen (cutscenes) the body ignores input and physics.
var frozen: bool = false
## Number of HideSpot areas the player is inside. Above zero means hidden.
var in_cover: int = 0
## The one NPC E will talk to: the nearest of those in range.
var nearest_npc: NPC = null

var _npcs_in_range: Array[NPC] = []

var _water_volume_count: int = 0
var _thermal_lift: float = 0.0
var _flap_lift_vel: float = 0.0
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
	stamina = max_stamina
	Globals.player_scale_changed.connect(_apply_scale)
	_apply_scale(Globals.player_scale)


func _process(_delta: float) -> void:
	_update_nearest_npc()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action") and nearest_npc and not Globals.dialogue_active and not frozen:
		get_viewport().set_input_as_handled()
		nearest_npc.talk(self)


func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector3.ZERO
		return
	# Snapshot before the transition, so a landing can be heard and measured.
	var previous_state := state
	var entry_speed := absf(velocity.y)
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
		State.FLY:
			_fly(delta, raw_input, s)

	move_and_slide()
	_notify_gate_bumps()

	if state == State.FLY:
		_resolve_flight_contact(s)
	if state == State.WALK or state == State.SWIM:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)
	_watch_for_splash(previous_state, entry_speed)

	_animate(delta, raw_input)


# --- Ground and water -------------------------------------------------------

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

	# A fresh press flaps into flight; holding the button past the apex of a hop
	# spreads the wings into a glide (the doc's "flap-hop").
	var pressed := Input.is_action_just_pressed("jump")
	var held := Input.is_action_pressed("jump") and velocity.y < 0.0
	if can_glide() and (pressed or held):
		_start_flight(s)
		if pressed:
			_flap(s)


# --- Flight -----------------------------------------------------------------

func can_glide() -> bool:
	return Globals.stage >= Globals.Stage.JUVENILE


func can_flap() -> bool:
	return Globals.stage >= Globals.Stage.FLEDGLING


func _start_flight(s: float) -> void:
	state = State.FLY
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	heading = atan2(-planar.x, -planar.z) if planar.length() > 0.5 else body.rotation.y
	air_speed = clampf(velocity.length(), min_air_speed * s, max_air_speed * s)
	pitch = 0.0
	if velocity.length() > 0.1:
		pitch = clampf(atan2(velocity.y, planar.length()),
				deg_to_rad(pitch_down_degrees), deg_to_rad(pitch_up_degrees))
	_flap_lift_vel = 0.0


func _flap(s: float) -> void:
	if not can_flap() or stamina < flap_cost:
		return
	Audio.play_at("flap", global_position, 1.0 / maxf(sqrt(s), 0.2))
	stamina -= flap_cost
	_flap_lift_vel = flap_lift * sqrt(s)
	air_speed += flap_boost * s


func _fly(delta: float, input: Vector2, s: float) -> void:
	# Pitch: W pulls up, S dives, hands-off settles at the stage's sink angle.
	var base_pitch := deg_to_rad(glide_sink_degrees if can_flap() else juvenile_sink_degrees)
	var target_pitch := base_pitch
	if input.y < 0.0:
		target_pitch = lerpf(base_pitch, deg_to_rad(pitch_up_degrees), -input.y)
	elif input.y > 0.0:
		target_pitch = lerpf(base_pitch, deg_to_rad(pitch_down_degrees), input.y)
	# Stall guard: no climbing without airspeed.
	if air_speed <= min_air_speed * s + 0.01 and target_pitch > 0.0:
		target_pitch = deg_to_rad(-20.0)
	pitch = move_toward(pitch, target_pitch, pitch_rate * delta)

	heading += -input.x * flight_turn_rate * delta

	# Energy: gravity along the flight path, drag only above trim speed.
	air_speed += -sin(pitch) * _gravity * delta
	var trim := glide_trim_speed * s
	if air_speed > trim:
		air_speed -= air_drag * (air_speed - trim) * delta
	air_speed = clampf(air_speed, min_air_speed * s, max_air_speed * s)

	if Input.is_action_just_pressed("jump"):
		_flap(s)
	_flap_lift_vel = move_toward(_flap_lift_vel, 0.0, flap_lift_decay * delta)

	var forward := Vector3(-sin(heading), 0.0, -cos(heading))
	velocity = forward * air_speed * cos(pitch)
	velocity.y = air_speed * sin(pitch) + _flap_lift_vel + _thermal_lift


func _resolve_flight_contact(s: float) -> void:
	if not (is_on_floor() or is_on_wall() or is_on_ceiling()):
		return
	if is_on_floor() and air_speed < landing_speed * s:
		state = State.WALK
		return
	# Too fast: bounce off with damping, keeping the flight state.
	var normal := Vector3.UP
	if get_slide_collision_count() > 0:
		normal = get_last_slide_collision().get_normal()
	var incoming := Vector3(-sin(heading), 0.0, -cos(heading)) * air_speed * cos(pitch)
	incoming.y = air_speed * sin(pitch)
	var bounced := incoming.bounce(normal) * bounce_damping
	if bounced.y < 1.0 * s:
		bounced.y = 1.0 * s
	var planar := Vector3(bounced.x, 0.0, bounced.z)
	if planar.length() > 0.3:
		heading = atan2(-planar.x, -planar.z)
	air_speed = clampf(bounced.length(), min_air_speed * s, max_air_speed * s)
	pitch = clampf(atan2(bounced.y, maxf(planar.length(), 0.01)),
			deg_to_rad(pitch_down_degrees), deg_to_rad(pitch_up_degrees))
	_flap_lift_vel = 0.0
	velocity = bounced


func _notify_gate_bumps() -> void:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is SizeGate:
			(collider as SizeGate).bump()


# --- State ------------------------------------------------------------------

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
		State.FLY:
			# Water is always a safe landing, at any speed.
			if in_volume and depth > swim_exit:
				state = State.SWIM
				velocity *= 0.3
		State.SWIM:
			if not in_volume or (is_on_floor() and depth < swim_exit):
				state = State.WALK


## A splash when the duck lands in water, louder the harder it hits.
func _watch_for_splash(previous_state: State, entry_speed: float) -> void:
	if state != State.SWIM or previous_state == State.SWIM:
		return
	var hardness := clampf(entry_speed / (6.0 * Globals.player_scale), 0.15, 1.0)
	var surface := Vector3(global_position.x, water_level, global_position.z)
	Audio.play_at("splash", surface, randf_range(0.92, 1.12) / maxf(sqrt(Globals.player_scale), 0.2),
			linear_to_db(hardness))


func _camera_relative(input: Vector2) -> Vector3:
	var forward := -camera_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera_pivot.global_basis.x
	right.y = 0.0
	right = right.normalized()
	# get_vector() gives -y for "forward", so negate it.
	return right * input.x + forward * -input.y


# --- Visuals ----------------------------------------------------------------

func _animate(delta: float, raw_input: Vector2) -> void:
	var s := Globals.player_scale
	var blend := clampf(turn_speed * delta, 0.0, 1.0)

	if state == State.FLY:
		body.rotation.y = lerp_angle(body.rotation.y, heading, blend)
		body.rotation.x = lerpf(body.rotation.x, pitch, blend)
		var bank := deg_to_rad(bank_degrees) * raw_input.x
		body.rotation.z = lerpf(body.rotation.z, bank, blend)
		return

	var planar := Vector3(velocity.x, 0.0, velocity.z)
	if planar.length() > 0.05:
		var target_yaw := atan2(-planar.x, -planar.z)
		body.rotation.y = lerp_angle(body.rotation.y, target_yaw, blend)

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


# --- Talking ----------------------------------------------------------------

## Called by [NPC] when the player enters its talk radius.
func enter_talk_range(npc: NPC) -> void:
	if not _npcs_in_range.has(npc):
		_npcs_in_range.append(npc)


## Called by [NPC].
func exit_talk_range(npc: NPC) -> void:
	_npcs_in_range.erase(npc)


func _update_nearest_npc() -> void:
	var best: NPC = null
	var best_d := INF
	for npc in _npcs_in_range:
		if not is_instance_valid(npc):
			continue
		var d := npc.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = npc
	if best != nearest_npc:
		nearest_npc = best
		_refresh_prompt()
	elif Globals.dialogue_active:
		_refresh_prompt()


func _refresh_prompt() -> void:
	if nearest_npc and not Globals.dialogue_active and not frozen:
		Globals.show_prompt("E   Talk to %s" % nearest_npc.npc_name)
	else:
		Globals.show_prompt("")


# --- Environment hooks ------------------------------------------------------

## Called by [WaterVolume]. [param surface_y] is the water surface in world space.
func enter_water(surface_y: float) -> void:
	_water_volume_count += 1
	water_level = surface_y


## Called by [WaterVolume].
func exit_water() -> void:
	_water_volume_count = maxi(_water_volume_count - 1, 0)
	if _water_volume_count == 0:
		water_level = -INF


## Called by [HideSpot].
func enter_cover() -> void:
	in_cover += 1


## Called by [HideSpot].
func exit_cover() -> void:
	in_cover = maxi(in_cover - 1, 0)


## Shove the duck (the hawk, a bump). Harmless: it just tumbles into the air.
func knock(impulse: Vector3) -> void:
	if state == State.FLY:
		return
	velocity = impulse
	state = State.AIR


## Called by [Thermal]. Adds free upward velocity while flying inside it.
func enter_thermal(lift: float) -> void:
	_thermal_lift += lift


## Called by [Thermal].
func exit_thermal(lift: float) -> void:
	_thermal_lift = maxf(_thermal_lift - lift, 0.0)


func state_name() -> String:
	return State.keys()[state]
