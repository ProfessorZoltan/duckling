extends WorldEnvironment
## Drives sky, sun and post-process from the global Heart (design doc §7.3):
## saturation, a warm-to-cold shift, sky color and ambient light. Blends
## toward the current value over [member blend_time].

@export var sun: DirectionalLight3D
@export var blend_time: float = 3.0

@export_group("At Heart 0")
@export var cold_sky_top: Color = Color(0.45, 0.48, 0.52)
@export var cold_sky_horizon: Color = Color(0.66, 0.67, 0.68)
@export var cold_sun: Color = Color(0.85, 0.88, 0.95)
@export var cold_saturation: float = 0.55
@export var cold_ambient_energy: float = 0.55

@export_group("At Heart 100")
@export var warm_sky_top: Color = Color(0.36, 0.58, 0.88)
@export var warm_sky_horizon: Color = Color(0.85, 0.86, 0.8)
@export var warm_sun: Color = Color(1.0, 0.96, 0.88)
@export var warm_saturation: float = 1.05
@export var warm_ambient_energy: float = 0.85

var displayed_heart: float


func _ready() -> void:
	displayed_heart = Globals.heart
	# Own the environment and sky so edits never touch the shared resource.
	environment = environment.duplicate(true)
	_apply()


func _process(delta: float) -> void:
	if is_equal_approx(displayed_heart, Globals.heart):
		return
	displayed_heart = move_toward(displayed_heart, Globals.heart, 100.0 / maxf(blend_time, 0.01) * delta)
	_apply()


func _apply() -> void:
	var t := clampf(displayed_heart / 100.0, 0.0, 1.0)
	environment.adjustment_saturation = lerpf(cold_saturation, warm_saturation, t)
	environment.ambient_light_energy = lerpf(cold_ambient_energy, warm_ambient_energy, t)
	var sky_material := environment.sky.sky_material as ProceduralSkyMaterial
	if sky_material:
		sky_material.sky_top_color = cold_sky_top.lerp(warm_sky_top, t)
		sky_material.sky_horizon_color = cold_sky_horizon.lerp(warm_sky_horizon, t)
	if sun:
		sun.light_color = cold_sun.lerp(warm_sun, t)
