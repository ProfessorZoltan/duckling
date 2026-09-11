class_name AnimalModel
extends Node3D
## Wraps one of the imported animal glTFs so a scene can just ask for "a
## duckling this tall" (see `assets/models/NOTES.md`).
##
## It instantiates the model, measures it as posed (the glTF bounding boxes are
## bind-pose and wrong for the skinned models), scales it to [member height],
## sets it down so its feet rest on the node's origin, and recolours it by
## material name. The duck's seven flat materials mean one mesh serves the
## player, every sibling and Marra.
##
## It also drives the gait: the walk cycle plays at a speed that matches how
## fast the animal is actually moving, and stops when it stops.
##
## Wings are the one thing neither model does well, and both limits are in the
## assets rather than this script (see `assets/models/NOTES.md`). The duck
## cannot flap: its armature carries `fin.L` and `fin.R` bones, but they hold
## no meaningful vertex weight, so posing them moves nothing, while posing
## `neck_6` bends the neck right over. The swan flaps properly in flight, but
## its rest pose has its wings spread and no frame of its animation folds them.

const SPECIES := {
	"duck": "res://assets/models/duck/scene.gltf",
	"swan": "res://assets/models/swan/scene.gltf",
	"mouse": "res://assets/models/mouse/scene.gltf",
}

const WALK_ANIMATION := {"duck": "walkcycle_1", "swan": "", "mouse": ""}
## Degrees to turn each model so it faces -Z, which is the way everything in
## the game points. The swan model is modelled facing the other way, so
## steering it by heading would walk it backwards.
const FACING := {"duck": 0.0, "swan": 180.0, "mouse": 180.0}
## The swan's one animation is a wing beat, so it doubles as its flight cycle.
## The duck has no flight animation at all.
const FLIGHT_ANIMATION := {"duck": "", "swan": "Animation", "mouse": ""}

## Material name -> albedo. Anything not named keeps the model's own colour.
const PALETTES := {
	"duckling": {
		"duck_gray": Color(0.52, 0.47, 0.40), "duck_brown": Color(0.36, 0.32, 0.27),
		"duck_yellow": Color(0.60, 0.54, 0.44), "duck_orange": Color(0.52, 0.47, 0.40),
		"duck_green": Color(0.44, 0.41, 0.36), "duck_white": Color(0.66, 0.62, 0.55),
		"duck_black": Color(0.10, 0.09, 0.08),
	},
	"sibling": {
		"duck_gray": Color(0.97, 0.84, 0.32), "duck_brown": Color(0.88, 0.70, 0.20),
		"duck_yellow": Color(0.95, 0.78, 0.22), "duck_orange": Color(0.95, 0.58, 0.16),
		"duck_green": Color(0.93, 0.80, 0.28), "duck_white": Color(0.99, 0.93, 0.62),
		"duck_black": Color(0.12, 0.10, 0.08),
	},
	"marra": {
		"duck_gray": Color(0.55, 0.44, 0.31), "duck_brown": Color(0.31, 0.23, 0.16),
		"duck_yellow": Color(0.47, 0.36, 0.25), "duck_orange": Color(0.72, 0.52, 0.20),
		"duck_green": Color(0.40, 0.31, 0.22), "duck_white": Color(0.72, 0.64, 0.52),
		"duck_black": Color(0.12, 0.10, 0.08),
	},
	## The juvenile: greyer and lankier, still not white.
	"juvenile": {
		"duck_gray": Color(0.58, 0.55, 0.50), "duck_brown": Color(0.42, 0.39, 0.35),
		"duck_yellow": Color(0.66, 0.62, 0.55), "duck_orange": Color(0.58, 0.54, 0.48),
		"duck_green": Color(0.50, 0.48, 0.44), "duck_white": Color(0.78, 0.76, 0.72),
		"duck_black": Color(0.10, 0.09, 0.08),
	},
	"none": {},
}

## Prints what was found and measured, for tuning sizes.
@export var debug_build: bool = false
@export var species: String = "duck"
@export var palette: String = "duckling"
## Height in metres at this node's own scale of 1.
@export var height: float = 0.67
## Seconds of walk cycle per metre travelled, so the legs match the ground.
@export var stride: float = 0.42
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer

var _airborne: bool = false


func _ready() -> void:
	build()


func build() -> void:
	if model:
		model.queue_free()
	var path: String = SPECIES.get(species, "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("AnimalModel: no model for species '%s'" % species)
		return
	model = (load(path) as PackedScene).instantiate()
	add_child(model)
	if not FACING.has(species):
		push_warning("AnimalModel: '%s' has no FACING entry; it may walk backwards." % species)
	model.rotation.y = deg_to_rad(FACING.get(species, 0.0))
	skeleton = null
	anim = null
	for child in _descendants(model):
		if child is Skeleton3D and skeleton == null:
			skeleton = child as Skeleton3D
		elif child is AnimationPlayer and anim == null:
			anim = child as AnimationPlayer
	for key in [WALK_ANIMATION, FLIGHT_ANIMATION]:
		var name: String = key.get(species, "")
		if anim and name != "" and anim.has_animation(name):
			anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	# The AnimationPlayer is not ready during our own _ready, so wait a frame
	# before measuring, and keep the model hidden until it has been scaled.
	model.visible = false
	await get_tree().process_frame
	if not is_instance_valid(model):
		return
	if skeleton:
		skeleton.force_update_all_bone_transforms()
	# Measure in this node's own space: a parent's scale (the player's growth,
	# a preview holder) must not change what the model thinks it measures.
	var box := posed_aabb(model, global_transform.affine_inverse())
	if debug_build:
		print("AnimalModel %s: measured %.3f m, scaled to %.3f m" % [species, box.size.y, height])
	if box.size.y > 0.0001:
		var factor := height / box.size.y
		model.scale = model.scale * factor
		model.position.y = -box.position.y * factor
	_recolour()
	model.visible = true


## How the animal is moving. [param speed] is metres per second in world terms;
## [param airborne] stops the legs and lets the wings take over.
func set_gait(speed: float, airborne: bool = false) -> void:
	if anim == null:
		return
	_airborne = airborne
	var flight: String = FLIGHT_ANIMATION.get(species, "")
	if airborne:
		if flight != "" and anim.has_animation(flight):
			if anim.current_animation != flight:
				anim.play(flight)
			anim.speed_scale = 1.0
		else:
			# No flight cycle: hold the legs still rather than walking mid-air.
			anim.speed_scale = 0.0
		return
	var walk: String = WALK_ANIMATION.get(species, "")
	if walk == "" or not anim.has_animation(walk):
		if anim.current_animation != "":
			anim.stop()
		return
	if anim.current_animation != walk:
		anim.play(walk)
	var local_speed := speed / maxf(scale_factor(), 0.001)
	# Freezing with speed_scale rather than pause(): pause() drops the
	# animation entirely in 4.7, which snaps the model back to its bind pose.
	anim.speed_scale = 0.0 if local_speed < 0.05 else clampf(local_speed * stride, 0.25, 3.0)


func scale_factor() -> float:
	return global_basis.get_scale().y


func _recolour() -> void:
	var colours: Dictionary = PALETTES.get(palette, {})
	if colours.is_empty():
		return
	for child in _descendants(model):
		if not (child is MeshInstance3D):
			continue
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var source := mi.mesh.surface_get_material(i)
			if not (source is StandardMaterial3D):
				continue
			var name := (source as StandardMaterial3D).resource_name
			if not colours.has(name):
				continue
			# Never edit the imported material: every instance shares it.
			var copy := (source as StandardMaterial3D).duplicate()
			copy.albedo_color = colours[name]
			mi.set_surface_override_material(i, copy)


## True bounds of a model as posed, expressed in [param into]'s space (pass the
## inverse of the frame you want them in). A skinned MeshInstance3D reports its
## bind-pose box, which on these exports is nothing like the rendered size, so
## walk the vertices through the skeleton instead.
static func posed_aabb(root: Node, into: Transform3D = Transform3D.IDENTITY) -> AABB:
	var out := AABB()
	var first := true
	for c in _descendants(root):
		if not (c is MeshInstance3D):
			continue
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var to_world := into * mi.global_transform
		var bones: Array[Transform3D] = []
		var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D
		if skel and mi.skin:
			to_world = into * skel.global_transform
			for b in skel.get_bone_count():
				bones.append(skel.get_bone_global_pose(b))
		for si in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(si)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bone_idx := PackedInt32Array()
			var weights := PackedFloat32Array()
			if arrays.size() > Mesh.ARRAY_BONES and arrays[Mesh.ARRAY_BONES] != null:
				bone_idx = arrays[Mesh.ARRAY_BONES]
				weights = arrays[Mesh.ARRAY_WEIGHTS]
			for vi in verts.size():
				var v := verts[vi]
				if not bones.is_empty() and bone_idx.size() >= (vi + 1) * 4:
					var acc := Vector3.ZERO
					var total := 0.0
					for k in 4:
						var w := weights[vi * 4 + k]
						if w <= 0.0:
							continue
						var b := bone_idx[vi * 4 + k]
						if b < bones.size():
							acc += (bones[b] * v) * w
							total += w
					if total > 0.0:
						v = acc / total
				var world := to_world * v
				if first:
					out = AABB(world, Vector3.ZERO)
					first = false
				else:
					out = out.expand(world)
	return out


static func _descendants(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_descendants(c))
	return out
