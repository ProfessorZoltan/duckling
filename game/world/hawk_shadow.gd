class_name HawkShadow
extends Node3D
## The Shadow (design doc §5 Hazards, quest M4). A hawk crosses high over the
## pond; its shadow slides across the ground. Be under cover when it reaches
## you and it counts as a hide; be caught in the open and you're knocked into
## the water, unhurt. Three hides complete the quest.

signal pass_started
signal hidden(count: int)
signal caught
signal all_hidden

@export var player: Player
@export var hides_needed: int = 3
@export var shadow_radius: float = 2.2
@export var warning_seconds: float = 2.5
@export var cross_seconds: float = 4.5
@export var seconds_between_passes: float = 6.0
@export var hawk_height: float = 26.0
## Half-length of the crossing line, from the pond centre.
@export var reach: float = 17.0

var active: bool = false
var hides: int = 0
var passes: int = 0

var _shadow: MeshInstance3D
var _hawk: Node3D
var _resolved: bool = false
var _crossing: bool = false


func _ready() -> void:
	_build_visuals()
	_shadow.visible = false
	_hawk.visible = false


func begin() -> void:
	if active:
		return
	active = true
	_schedule(2.0)


func _schedule(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if active:
		start_pass()


func start_pass() -> void:
	if _crossing:
		return
	_crossing = true
	_resolved = false
	passes += 1
	# The hawk hunts: its line crosses wherever the duckling is right now, so
	# hiding matters and standing in the open never goes unpunished.
	var angle := randf() * TAU
	var dir := Vector3(cos(angle), 0.0, sin(angle))
	var aim := Vector3.ZERO
	if player:
		aim = Vector3(player.global_position.x, 0.0, player.global_position.z)
	var from := aim + dir * reach
	var to := aim - dir * reach
	pass_started.emit()
	_shadow.visible = true
	_hawk.visible = true
	_place(from)
	# Warning: the shadow lingers at the edge before it sweeps.
	await get_tree().create_timer(warning_seconds).timeout
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: _place(from.lerp(to, t)), 0.0, 1.0, cross_seconds)
	await tween.finished
	_shadow.visible = false
	_hawk.visible = false
	_crossing = false
	if hides >= hides_needed:
		active = false
		all_hidden.emit()
	elif active:
		_schedule(seconds_between_passes)


func _place(flat: Vector3) -> void:
	var ground := -0.45 if flat.length() < 9.6 else 0.03
	_shadow.global_position = Vector3(flat.x, ground, flat.z)
	_hawk.global_position = Vector3(flat.x, hawk_height, flat.z)
	if not _resolved and player:
		var d := Vector2(flat.x, flat.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		if d < shadow_radius * maxf(Globals.player_scale, 1.0):
			_resolve()


func _resolve() -> void:
	_resolved = true
	if player.in_cover > 0:
		hides += 1
		hidden.emit(hides)
	else:
		var away := Vector3(-player.global_position.x, 0.0, -player.global_position.z).normalized()
		if away.length() < 0.5:
			away = Vector3.FORWARD
		player.knock(away * 4.5 * Globals.player_scale + Vector3.UP * 3.5 * sqrt(Globals.player_scale))
		caught.emit()


func _build_visuals() -> void:
	_shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = shadow_radius
	disc.bottom_radius = shadow_radius
	disc.height = 0.02
	_shadow.mesh = disc
	var shade := StandardMaterial3D.new()
	shade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shade.albedo_color = Color(0.05, 0.05, 0.08, 0.55)
	_shadow.material_override = shade
	_shadow.top_level = true
	add_child(_shadow)

	_hawk = Node3D.new()
	_hawk.top_level = true
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 2.2
	body.mesh = mesh
	body.rotation.x = PI / 2.0
	var wings := MeshInstance3D.new()
	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(4.2, 0.08, 0.9)
	wings.mesh = wing_mesh
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.1, 0.09)
	body.material_override = dark
	wings.material_override = dark
	_hawk.add_child(body)
	_hawk.add_child(wings)
	add_child(_hawk)
