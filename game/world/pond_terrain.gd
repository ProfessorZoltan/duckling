@tool
class_name PondTerrain
extends MeshInstance3D
## Builds the Home Pond ground as a real mesh so it can be textured, and keeps
## its heights identical to the CSG shape that still provides the collision.
##
## The height function is the one every prop in the scene was placed against: a
## flat plain with a sphere subtracted out of it to make the pond bowl. Changing
## it would move the waterline, the gates and everything standing on the shore,
## so it is reproduced here exactly rather than re-invented.
##
## The material blends mud, wet sand and grass by height, breaking the joins up
## with a low-frequency noise texture so the shoreline is not a drawn circle.

@export var extent: float = 40.0
## Metres per quad. Smaller is smoother and heavier.
@export var cell: float = 0.5
## Sphere subtracted from the plain to make the bowl.
@export var basin_centre_y: float = 17.0
@export var basin_radius: float = 20.0
## Metres of ground per texture repeat.
@export var texture_scale: float = 2.6
@export var rebuild: bool = false:
	set(value):
		if value:
			build()

@export_group("Shoreline")
@export var water_y: float = -0.5
## How far below the water mud gives way to sand, and above it sand to grass.
@export var mud_depth: float = 0.55
@export var sand_height: float = 0.16
@export var edge_noise: float = 0.34


func _ready() -> void:
	build()
	if Engine.is_editor_hint():
		return
	# HeartRegion collects its materials in its own _ready, and it sits above
	# World in the scene so that runs before this one: there is nothing to find
	# yet. Hand the finished material over instead of waiting to be collected.
	var region := _heart_region()
	if region:
		region.adopt(self)


## The HeartRegion this terrain sits inside, if the scene has one.
func _heart_region() -> HeartRegion:
	var root: Node = owner if owner else get_parent()
	if root == null:
		return null
	for child in root.get_children():
		if child is HeartRegion:
			var region := child as HeartRegion
			if region.visuals_root and region.visuals_root.is_ancestor_of(self):
				return region
	return null


## The ground height at a point. Must match the CSG bowl in the scene.
func height_at(x: float, z: float) -> float:
	var inner := basin_radius * basin_radius - (x * x + z * z)
	if inner <= 0.0:
		return 0.0
	return minf(basin_centre_y - sqrt(inner), 0.0)


func build() -> void:
	var steps := int(round(extent * 2.0 / maxf(cell, 0.05)))
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var tangents := PackedFloat32Array()
	var indices := PackedInt32Array()
	verts.resize((steps + 1) * (steps + 1))
	normals.resize(verts.size())
	uvs.resize(verts.size())
	# Normal mapping needs tangents. UV.x runs along world X, so the tangent is
	# +X, made perpendicular to the surface normal.
	tangents.resize(verts.size() * 4)

	for j in steps + 1:
		for i in steps + 1:
			var x := -extent + float(i) / steps * extent * 2.0
			var z := -extent + float(j) / steps * extent * 2.0
			var index := j * (steps + 1) + i
			verts[index] = Vector3(x, height_at(x, z), z)
			uvs[index] = Vector2(x, z) / maxf(texture_scale, 0.01)
			# Analytic normal: the bowl is a sphere, everything else is flat.
			var r2 := x * x + z * z
			var inner := basin_radius * basin_radius - r2
			if inner > 0.0 and basin_centre_y - sqrt(inner) < 0.0:
				normals[index] = Vector3(x, sqrt(inner), z).normalized()
			else:
				normals[index] = Vector3.UP
			var tangent := (Vector3.RIGHT - normals[index] * normals[index].dot(Vector3.RIGHT)).normalized()
			tangents[index * 4 + 0] = tangent.x
			tangents[index * 4 + 1] = tangent.y
			tangents[index * 4 + 2] = tangent.z
			tangents[index * 4 + 3] = 1.0

	for j in steps:
		for i in steps:
			var a := j * (steps + 1) + i
			var b := a + 1
			var c := a + steps + 1
			var d := c + 1
			# Godot's front faces are wound clockwise as seen from the front. Wind
			# these the other way and the whole ground is back-face culled: you see
			# straight through it to the sky, with only the props left standing.
			indices.append_array([a, b, c, b, d, c])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_INDEX] = indices
	var built := ArrayMesh.new()
	built.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = built
	if material_override == null:
		material_override = _build_material()
	else:
		_apply_thresholds(material_override as ShaderMaterial)


func _build_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("grass_texture", load("res://assets/textures/ground_grass.png"))
	material.set_shader_parameter("sand_texture", load("res://assets/textures/ground_sand.png"))
	material.set_shader_parameter("mud_texture", load("res://assets/textures/ground_mud.png"))
	material.set_shader_parameter("normal_texture", load("res://assets/textures/ground_normal.png"))
	material.set_shader_parameter("blend_texture", load("res://assets/textures/ground_blend.png"))
	material.set_shader_parameter("saturation", 1.0)
	_apply_thresholds(material)
	return material


func _apply_thresholds(material: ShaderMaterial) -> void:
	if material == null:
		return
	material.set_shader_parameter("water_y", water_y)
	material.set_shader_parameter("mud_depth", mud_depth)
	material.set_shader_parameter("sand_height", sand_height)
	material.set_shader_parameter("edge_noise", edge_noise)
	material.set_shader_parameter("blend_scale", 1.0 / maxf(extent, 1.0))


const SHADER := """
shader_type spatial;

uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D blend_texture : filter_linear_mipmap, repeat_enable;
uniform float water_y = -0.5;
uniform float mud_depth = 0.55;
uniform float sand_height = 0.16;
uniform float edge_noise = 0.34;
uniform float blend_scale = 0.025;
uniform float saturation : hint_range(0.0, 1.0) = 1.0;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// NORMAL is view space by the time it reaches fragment(), so the slope test
	// has to carry its own world-space copy.
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// A big soft noise field pushes the boundaries around so they never read
	// as circles drawn on the ground.
	float wobble = (texture(blend_texture, world_position.xz * blend_scale).r - 0.5) * edge_noise;
	float h = world_position.y + wobble;

	vec3 grass = texture(grass_texture, UV).rgb;
	vec3 sand = texture(sand_texture, UV).rgb;
	vec3 mud = texture(mud_texture, UV).rgb;

	float to_sand = smoothstep(water_y - mud_depth, water_y - mud_depth * 0.25, h);
	float to_grass = smoothstep(water_y + sand_height * 0.2, water_y + sand_height + 0.28, h);
	vec3 base = mix(mud, sand, to_sand);
	base = mix(base, grass, to_grass);

	// A slow brightness drift at a scale far bigger than the tile, so a 2.6 m
	// repeat stops reading as wallpaper in the foreground.
	float macro = texture(blend_texture, world_position.xz * blend_scale * 2.7).r;
	base *= 0.86 + 0.28 * macro;

	// Steep ground keeps its bare look whatever the height says.
	float steep = 1.0 - smoothstep(0.55, 0.86, world_normal.y);
	base = mix(base, sand, steep * 0.65);

	float grey = dot(base, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = mix(vec3(grey), base, saturation);
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = 0.35;
	ROUGHNESS = mix(0.78, 1.0, to_grass);
	SPECULAR = 0.15;
}
"""
