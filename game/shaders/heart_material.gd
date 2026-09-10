class_name HeartMaterial
extends RefCounted
## Builds ShaderMaterials that mirror an imported StandardMaterial3D (albedo
## texture and color, normal map, roughness, cutout, culling) and add a
## `saturation` uniform, so textured kit assets can drain and regain color
## like the flat grey-box materials do (design doc §7.3).

static var _shaders: Dictionary = {}


static func convert(source: StandardMaterial3D) -> ShaderMaterial:
	var cutout := source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR \
		or source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA \
		or source.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	var double_sided := source.cull_mode == BaseMaterial3D.CULL_DISABLED
	var has_normal := source.normal_enabled and source.normal_texture != null
	var material := ShaderMaterial.new()
	material.shader = _shader_for(cutout, double_sided, has_normal)
	material.set_shader_parameter("albedo_color", source.albedo_color)
	material.set_shader_parameter("albedo_texture", source.albedo_texture)
	material.set_shader_parameter("has_texture", source.albedo_texture != null)
	material.set_shader_parameter("roughness", source.roughness)
	material.set_shader_parameter("metallic", source.metallic)
	material.set_shader_parameter("saturation", 1.0)
	if has_normal:
		material.set_shader_parameter("normal_texture", source.normal_texture)
		material.set_shader_parameter("normal_scale", source.normal_scale)
	material.resource_name = source.resource_name + " (heart)"
	return material


static func _shader_for(cutout: bool, double_sided: bool, has_normal: bool) -> Shader:
	var key := "%s%s%s" % [int(cutout), int(double_sided), int(has_normal)]
	if _shaders.has(key):
		return _shaders[key]
	var code := "shader_type spatial;\n"
	if double_sided:
		code += "render_mode cull_disabled;\n"
	code += """
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_texture = false;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 1.0) = 1.0;
"""
	if has_normal:
		code += "uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;\nuniform float normal_scale = 1.0;\n"
	code += """
void fragment() {
	vec4 base = albedo_color;
	if (has_texture) {
		base *= texture(albedo_texture, UV);
	}
	float gray = dot(base.rgb, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = mix(vec3(gray), base.rgb, saturation);
	ROUGHNESS = roughness;
	METALLIC = metallic;
"""
	if cutout:
		code += "\tALPHA = base.a;\n\tALPHA_SCISSOR_THRESHOLD = 0.5;\n"
	if has_normal:
		code += "\tNORMAL_MAP = texture(normal_texture, UV).rgb;\n\tNORMAL_MAP_DEPTH = normal_scale;\n"
	code += "}\n"
	var shader := Shader.new()
	shader.code = code
	_shaders[key] = shader
	return shader
