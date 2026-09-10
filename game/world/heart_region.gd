class_name HeartRegion
extends Node
## One region's Heart sub-value made visible (design doc §7.3). Everything
## under [member visuals_root] is desaturated toward gray as the region's
## Heart falls and restored as it recovers, blending over [member blend_time]
## so a change reads as the world draining or flooding with color.
##
## Flat materials (grey-box CSG, props) are recolored by tinting their albedo.
## Textured materials (imported kit assets) are swapped for a HeartMaterial
## shader copy with a saturation uniform, once, on the mesh's surface override
## so the imported resource itself is never edited. Materials outside the
## region (the player, the HUD) are untouched.

@export var region_name: String = "Home Pond"
@export var visuals_root: Node3D
@export var initial_heart: float = 70.0
@export var blend_time: float = 3.0
## Saturation kept at Heart 0, so gray is never dead flat.
@export var floor_saturation: float = 0.06

var displayed_heart: float

var _flat_materials: Dictionary = {}    # StandardMaterial3D -> original albedo
var _shader_materials: Dictionary = {}  # source material -> ShaderMaterial (shared per source)
var _target_heart: float


func _ready() -> void:
	Globals.register_region(region_name, initial_heart)
	_target_heart = Globals.get_region_heart(region_name)
	displayed_heart = _target_heart
	Globals.region_heart_changed.connect(_on_region_heart_changed)
	if visuals_root:
		_collect(visuals_root)
	_apply()


func _process(delta: float) -> void:
	if is_equal_approx(displayed_heart, _target_heart):
		return
	var step := 100.0 / maxf(blend_time, 0.01) * delta
	displayed_heart = move_toward(displayed_heart, _target_heart, step)
	_apply()


func _on_region_heart_changed(region: String, value: float) -> void:
	if region == region_name:
		_target_heart = value


## The untinted albedo the region remembered for a flat [param material].
func original_albedo(material: Material) -> Color:
	return _flat_materials.get(material, Color.WHITE)


func saturation() -> float:
	return lerpf(floor_saturation, 1.0, clampf(displayed_heart / 100.0, 0.0, 1.0))


## Register a node added after _ready (spawned props).
func adopt(node: Node) -> void:
	_collect(node)
	_apply()


func _collect(node: Node) -> void:
	if node is CSGPrimitive3D:
		_remember_flat((node as CSGPrimitive3D).material)
	elif node is MeshInstance3D:
		_convert_mesh(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child)


func _remember_flat(material: Material) -> void:
	if material is StandardMaterial3D and not _flat_materials.has(material):
		_flat_materials[material] = (material as StandardMaterial3D).albedo_color


func _convert_mesh(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var override := mi.get_surface_override_material(i)
		var source: Material = override if override else mi.mesh.surface_get_material(i)
		if source is ShaderMaterial:
			continue
		if not (source is StandardMaterial3D):
			continue
		var standard := source as StandardMaterial3D
		if standard.albedo_texture == null:
			# Flat color: tint in place (shared with CSG props of the same material).
			_remember_flat(standard)
			continue
		if not _shader_materials.has(standard):
			_shader_materials[standard] = HeartMaterial.convert(standard)
		mi.set_surface_override_material(i, _shader_materials[standard])


func _apply() -> void:
	var t := saturation()
	for material in _flat_materials:
		var original: Color = _flat_materials[material]
		var gray := original.get_luminance()
		(material as StandardMaterial3D).albedo_color = Color(gray, gray, gray, original.a).lerp(original, t)
	for source in _shader_materials:
		(_shader_materials[source] as ShaderMaterial).set_shader_parameter("saturation", t)
