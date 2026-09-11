class_name FamilyFlock
extends Node3D
## Marra and the siblings as a moving group (design doc §2 Act 1 "Keep Up").
## The mother follows a route of waypoints just faster than the player can
## manage, pausing at each until the player is close, so there is tension but
## never punishment. Siblings hold loose slots behind her. Waypoints below
## the waterline are swum, others walked.

signal waypoint_reached(index: int)
signal route_finished

@export var mother: Node3D
@export var siblings: Array[Node3D] = []
@export var player: Player
## Mother's speed as a multiple of the player's walk / swim speed.
@export var speed_factor: float = 1.15
## She waits at a waypoint until the player is this close (in metres at scale 1).
@export var catch_up_distance: float = 6.0
## ...or at most this long.
@export var max_wait: float = 8.0
@export var sibling_speed_factor: float = 1.5

const SLOTS: Array[Vector3] = [
	Vector3(-0.7, 0.0, 0.8), Vector3(0.7, 0.0, 0.9), Vector3(-0.4, 0.0, 1.7), Vector3(0.5, 0.0, 1.8),
]
const WATER_Y := -0.62

var moving: bool = false
var _route: Array[Vector3] = []
var _index: int = 0
var _waiting: float = -1.0
var _pause: bool = true
var _scatter_targets: Dictionary = {}
var _bob: float = 0.0


func start_route(points: Array[Vector3], pause_at_waypoints: bool = true) -> void:
	_route = points
	_index = 0
	_pause = pause_at_waypoints
	_waiting = -1.0
	_scatter_targets.clear()
	moving = not _route.is_empty()


func stop() -> void:
	moving = false


## Everyone dashes to the nearest of [param spots] (the hawk is coming).
func scatter(spots: Array[Vector3]) -> void:
	moving = false
	_scatter_targets.clear()
	for member in _members():
		var best := spots[0]
		for spot in spots:
			if spot.distance_to(member.global_position) < best.distance_to(member.global_position):
				best = spot
		_scatter_targets[member] = best + Vector3(randf_range(-0.6, 0.6), 0.0, randf_range(-0.6, 0.6))


func regroup(around: Vector3) -> void:
	_scatter_targets.clear()
	for i in siblings.size():
		_scatter_targets[siblings[i]] = around + SLOTS[i % SLOTS.size()] * 1.4
	_scatter_targets[mother] = around


func _members() -> Array[Node3D]:
	var all: Array[Node3D] = [mother]
	all.append_array(siblings)
	return all


func _physics_process(delta: float) -> void:
	_bob += delta * 4.0
	if not _scatter_targets.is_empty():
		for member in _scatter_targets:
			_step(member, _scatter_targets[member], _walk_speed() * sibling_speed_factor, delta)
		return
	if not moving:
		return
	var target := _route[_index]
	var swimming := target.y < -0.2
	var speed := (_swim_speed() if swimming else _walk_speed()) * speed_factor
	if _waiting >= 0.0:
		_waiting += delta
		var near := player and player.global_position.distance_to(mother.global_position) < catch_up_distance * Globals.player_scale
		if near or _waiting > max_wait:
			_waiting = -1.0
			_index += 1
			if _index >= _route.size():
				moving = false
				route_finished.emit()
			# Next frame walks toward the new target; stepping on the stale one
			# here would count as a second arrival and skip a waypoint.
			_follow_slots(delta)
			return
		_follow_slots(delta)
		return
	if _step(mother, target, speed, delta):
		waypoint_reached.emit(_index)
		if _pause:
			_waiting = 0.0
		else:
			_index += 1
			if _index >= _route.size():
				moving = false
				route_finished.emit()
	_follow_slots(delta)


func _follow_slots(delta: float) -> void:
	var basis := Basis(Vector3.UP, mother.rotation.y)
	for i in siblings.size():
		var slot := mother.global_position + basis * SLOTS[i % SLOTS.size()]
		_step(siblings[i], slot, _walk_speed() * sibling_speed_factor, delta, 0.15)


## Moves [param node] toward [param target]; returns true once it arrives.
## Height comes from the ground under the member, or the waterline where the
## ground dips below it, so nobody sinks into a bank or hovers over a slope.
func _step(node: Node3D, target: Vector3, speed: float, delta: float, arrive: float = 0.25) -> bool:
	var to := target - node.global_position
	var flat := Vector3(to.x, 0.0, to.z)
	var arrived := flat.length() <= arrive
	if not arrived:
		node.global_position += flat.normalized() * minf(speed * delta, flat.length())
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-flat.x, -flat.z), 8.0 * delta)
	var floor_y := _surface_height(node.global_position, target.y)
	var bob := 0.02 * sin(_bob + node.get_index()) if floor_y <= WATER_Y + 0.001 else 0.0
	node.global_position.y = lerpf(node.global_position.y, floor_y + bob, 8.0 * delta)
	return arrived


func _surface_height(at: Vector3, fallback: float) -> float:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 4.0, at + Vector3.DOWN * 6.0)
	query.collision_mask = 1
	if player:
		query.exclude = [player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return fallback
	var ground: float = hit.position.y
	return WATER_Y if ground < WATER_Y else ground


func _walk_speed() -> float:
	return (player.walk_speed if player else 2.0) * Globals.player_scale


func _swim_speed() -> float:
	return (player.swim_speed if player else 1.4) * Globals.player_scale
