class_name EggPrologue
extends Node3D
## The Prologue (design doc §2): first person inside the egg. Muffled sounds
## arrive as subtitles, mashing any button pecks the shell, light bleeds in
## with each crack, the cap pops off, and the camera pulls out to third person
## beside siblings who are smaller and yellower than you.
##
## Runs only when Globals.start_in_egg is true. Place at the nest, under World.

signal hatched

@export var player: Player
@export var pecks_to_hatch: int = 8
@export var pull_out_seconds: float = 2.2
@export var darkness_start: float = 0.9
@export var crack_color: Color = Color(1.0, 0.95, 0.8)

var active: bool = false
var cracks: int = 0

@onready var cap: Node3D = $Cap
@onready var cup: Node3D = $Cup
@onready var egg_camera: Camera3D = $EggCamera
@onready var crack_root: Node3D = $Cracks

var _overlay: ColorRect
var _cap_rest: Transform3D
var _hatching: bool = false
var _muffled_lines := [
	[1.0, "...peep. peep peep..."],
	[4.0, "(a warm voice, muffled)   ...there you are..."],
	[7.5, "...tap.   tap."],
]


func _ready() -> void:
	_cap_rest = cap.transform
	if not Globals.start_in_egg or player == null:
		Audio.set_muffle(0.0)
		queue_free()
		return
	# World is earlier in the tree than Player, so wait for its @onready fields.
	if not player.is_node_ready():
		await player.ready
	active = true
	player.frozen = true
	player.body.visible = false
	player.global_position = global_position + Vector3(0, 0.1, 0)
	_build_overlay()
	Audio.set_muffle(1.0)
	egg_camera.current = true
	_narrate()


func _narrate() -> void:
	var elapsed := 0.0
	for entry in _muffled_lines:
		var at: float = entry[0]
		await get_tree().create_timer(at - elapsed).timeout
		elapsed = at
		if not active or _hatching:
			return
		Globals.notify(entry[1])
		if entry[1].begins_with("(a warm voice"):
			Audio.play("muffled_call", 1.0)
		else:
			Audio.play("quack", 1.6, -14.0)
	await get_tree().create_timer(2.5).timeout
	if active and not _hatching and cracks == 0:
		Globals.show_prompt("Mash SPACE to peck")


func _unhandled_input(event: InputEvent) -> void:
	if not active or _hatching or event.is_echo():
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		peck()


func peck() -> void:
	cracks += 1
	Globals.show_prompt("")
	_add_crack()
	_nudge()
	Audio.play("peck", randf_range(0.94, 1.1))
	Input.start_joy_vibration(0, 0.25, 0.0, 0.08)
	var t := float(cracks) / float(pecks_to_hatch)
	_set_darkness(darkness_start * pow(1.0 - t, 0.7) + 0.05 * (1.0 - t))
	if cracks >= pecks_to_hatch:
		_hatch()


func _add_crack() -> void:
	# A bright sliver on the inside of the shell, somewhere in front of the eye.
	var yaw := randf_range(-1.1, 1.1)
	var pitch := randf_range(-0.6, 0.8)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var sliver := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.007, randf_range(0.09, 0.18), 0.003)
	sliver.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = crack_color
	material.emission_enabled = true
	material.emission = crack_color
	material.emission_energy_multiplier = 3.0
	sliver.material_override = material
	crack_root.add_child(sliver)
	sliver.position = egg_camera.position + dir * 0.24
	sliver.look_at(egg_camera.global_position + dir * 10.0, Vector3.UP)
	sliver.rotate_object_local(Vector3.FORWARD, randf_range(0.0, TAU))
	# Older cracks spread a little with every new peck.
	for child in crack_root.get_children():
		if child != sliver:
			(child as Node3D).scale *= Vector3(1.0, 1.12, 1.0)


func _nudge() -> void:
	var tween := create_tween()
	tween.tween_property(egg_camera, "rotation:x", -0.12, 0.05)
	tween.tween_property(egg_camera, "rotation:x", 0.0, 0.14)
	var wobble := create_tween()
	wobble.tween_property(cap, "rotation:z", 0.04, 0.05)
	wobble.tween_property(cap, "rotation:z", 0.0, 0.12)


func _hatch() -> void:
	_hatching = true
	Globals.notify("")
	Audio.play("shell_break")
	# The cap pops up and tumbles off beside the nest.
	var pop := create_tween()
	pop.tween_property(cap, "position:y", cap.position.y + 0.35, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.parallel().tween_property(cap, "rotation:x", 0.9, 0.18)
	pop.tween_property(cap, "position", Vector3(0.9, 0.02, 0.3), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pop.parallel().tween_property(cap, "rotation", Vector3(2.6, 0.4, 0.5), 0.55)
	# Light and sound flood in together.
	Audio.muffle_to(0.0, 0.9)
	var light := create_tween()
	light.tween_method(_set_darkness, _overlay.color.a, 0.0, 0.5)
	await light.finished
	for child in crack_root.get_children():
		child.queue_free()
	# Pull out to the third-person camera.
	var target: Camera3D = player.camera_pivot.get_node("SpringArm3D/Camera3D")
	var start := egg_camera.global_transform
	var pull := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pull.tween_method(func(t: float) -> void:
		egg_camera.global_transform = start.interpolate_with(target.global_transform, t)
		if t > 0.3:
			player.body.visible = true
	, 0.0, 1.0, pull_out_seconds)
	await pull.finished
	target.current = true
	player.body.visible = true
	player.frozen = false
	active = false
	Globals.start_in_egg = false
	_overlay.get_parent().queue_free()
	egg_camera.queue_free()
	hatched.emit()


func _set_darkness(alpha: float) -> void:
	if _overlay:
		_overlay.color.a = clampf(alpha, 0.0, 1.0)


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	_overlay = ColorRect.new()
	_overlay.color = Color(0.05, 0.03, 0.02, darkness_start)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_overlay)
	add_child(layer)
