class_name HeartRegion
extends Node
## One region's Heart sub-value made visible (design doc §7.3). Every material
## under [member visuals_root] is desaturated toward gray as the region's
## Heart falls and restored as it recovers, blending over [member blend_time]
## so a change reads as the world draining or flooding with color.
##
## Materials are shared resources, so each unique material is recolored once.
## Materials outside the region (the player, the HUD) are untouched.

@export var region_name: String = "Home Pond"
@export var visuals_root: Node3D
@export var initial_heart: float = 70.0
@export var blend_time: float = 3.0
## Saturation kept at Heart 0, so gray is never dead flat.
@export var floor_saturation: float = 0.06

var displayed_heart: float

var _materials: Dictionary = {}  # material -> original albedo Color
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


## The untinted albedo the region remembered for [param material].
func original_albedo(material: Material) -> Color:
	return _materials.get(material, Color.WHITE)


func saturation() -> float:
	return lerpf(floor_saturation, 1.0, clampf(displayed_heart / 100.0, 0.0, 1.0))


func _collect(node: Node) -> void:
	if node is CSGPrimitive3D:
		_remember((node as CSGPrimitive3D).material)
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			_remember(mi.get_surface_override_material(i))
	for child in node.get_children():
		_collect(child)


func _remember(material: Material) -> void:
	if material is StandardMaterial3D and not _materials.has(material):
		_materials[material] = (material as StandardMaterial3D).albedo_color


func _apply() -> void:
	var t := saturation()
	for material in _materials:
		var original: Color = _materials[material]
		var gray := original.get_luminance()
		var tinted := Color(gray, gray, gray, original.a).lerp(original, t)
		(material as StandardMaterial3D).albedo_color = tinted
